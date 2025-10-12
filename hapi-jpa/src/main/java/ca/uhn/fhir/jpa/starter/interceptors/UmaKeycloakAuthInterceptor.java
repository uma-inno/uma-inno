package ca.uhn.fhir.jpa.starter.interceptors;

import ca.uhn.fhir.interceptor.api.Hook;
import ca.uhn.fhir.interceptor.api.Pointcut;
import ca.uhn.fhir.rest.api.server.RequestDetails;
import ca.uhn.fhir.rest.server.exceptions.AuthenticationException;
import ca.uhn.fhir.rest.server.exceptions.ForbiddenOperationException;
import ca.uhn.fhir.rest.server.servlet.ServletRequestDetails;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@Component
public class UmaKeycloakAuthInterceptor {
    private static final Logger logger = LoggerFactory.getLogger(UmaKeycloakAuthInterceptor.class);
    
    // Use server IP for internal server-to-server communication
    private static final String AUTHORIZATION_SERVER_URI_INTERNAL = "http://172.29.16.64:8080/realms/FHIR-Auth";
    // Use external IP for client-facing responses
    private static final String AUTHORIZATION_SERVER_URI_EXTERNAL = "http://172.29.16.64:8080/realms/FHIR-Auth";
    
    private static final String INTROSPECTION_URL = AUTHORIZATION_SERVER_URI_INTERNAL + "/protocol/openid-connect/token/introspect";
    private static final String PERMISSION_ENDPOINT = AUTHORIZATION_SERVER_URI_INTERNAL + "/authz/protection/permission";
    private static final String TOKEN_URL = AUTHORIZATION_SERVER_URI_INTERNAL + "/protocol/openid-connect/token";
    
    private static final String CLIENT_ID = "fhir-client";
    private static final String CLIENT_SECRET = "QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP";

    @Hook(Pointcut.SERVER_INCOMING_REQUEST_PRE_HANDLED)
    public void handleRequest(RequestDetails theRequestDetails) {
        try {
            String requestPath = theRequestDetails.getRequestPath();
            logger.debug("Processing request to: {}", requestPath);
            
            // FIRST: Check if this is a public endpoint - this must come before any other logic
            if (isPublicEndpoint(requestPath)) {
                logger.debug("Allowing access to public endpoint: {}", requestPath);
                return; // Continue processing without authentication
            }

            // SECOND: Extract resource type to see if we should handle this request
            String resourceType = extractResourceType(requestPath);
            
            // THIRD: Only handle resources that exist in Keycloak (for now, only Patient)
            if (!shouldHandleResource(resourceType)) {
                logger.debug("Resource type '{}' not configured for UMA authentication, allowing access", resourceType);
                return; // Let unconfigured resources pass through
            }

            logger.info("Applying UMA authentication to {} resource", resourceType);

            String authHeader = theRequestDetails.getHeader("Authorization");
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                logger.info("No authorization header found, handling tokenless access for: {}", requestPath);
                handleTokenlessAccess(theRequestDetails);
                return; // handleTokenlessAccess will throw an exception to abort processing
            }

            String token = authHeader.substring(7);
            if (!isTokenValid(token)) {
                logger.warn("Invalid or expired token for request: {}", requestPath);
                // Handle invalid token the same way as tokenless access - request new permission ticket
                handleTokenlessAccess(theRequestDetails);
                return; // handleTokenlessAccess will throw an exception to abort processing
            }
            logger.debug("Successfully authenticated request to: {}", requestPath);
            // Continue processing by returning normally
        } catch (AuthenticationException | ForbiddenOperationException e) {
            // Re-throw expected UMA exceptions
            throw e;
        } catch (Exception e) {
            logger.error("Unexpected error in UMA interceptor for path: {}", 
                        theRequestDetails != null ? theRequestDetails.getRequestPath() : "unknown", e);
            // For unexpected errors, let the request continue but log the issue
        }
    }

    private boolean shouldHandleResource(String resourceType) {
        // Only handle resources that are configured in Keycloak
        // For now, only Patient is configured
        switch (resourceType) {
            case "Patient":
                return true;
            // Uncomment these as you add them to Keycloak:
            // case "Observation":
            // case "Practitioner":
            // case "Organization":
            // case "Encounter":
            // case "Condition":
            // case "Medication":
            // case "MedicationRequest":
            // case "DiagnosticReport":
            // case "ServiceRequest":
            //     return true;
            default:
                return false;
        }
    }

    private void handleTokenlessAccess(RequestDetails theRequestDetails) {
        logger.info("Handling tokenless access for: {}", theRequestDetails.getRequestPath());
        try {
            String permissionTicket = requestPermissionTicket(theRequestDetails);
            if (permissionTicket != null) {
                respondWithPermissionTicket(theRequestDetails, permissionTicket);
                // respondWithPermissionTicket throws AuthenticationException
            } else {
                respondWithAuthServerUnreachable(theRequestDetails);
            }
        } catch (AuthenticationException | ForbiddenOperationException e) {
            // Re-throw expected exceptions
            throw e;
        } catch (Exception e) {
            // Only catch unexpected errors
            logger.error("Unexpected error handling tokenless access", e);
            respondWithAuthServerUnreachable(theRequestDetails);
        }
    }

    private String requestPermissionTicket(RequestDetails theRequestDetails) {
        try {
            PermissionRequest permissionRequest = buildPermissionRequest(theRequestDetails);
            logger.debug("Built permission request: resourceId={}, scopes={}", 
                        permissionRequest.getResource_id(), 
                        String.join(",", permissionRequest.getResource_scopes()));
            
            try (CloseableHttpClient client = HttpClients.createDefault()) {
                HttpPost post = new HttpPost(PERMISSION_ENDPOINT);
                post.setHeader("Content-Type", "application/json");
                
                String protectionToken = getProtectionApiToken();
                if (protectionToken == null) {
                    logger.error("Failed to obtain protection API token");
                    return null;
                }
                
                post.setHeader("Authorization", "Bearer " + protectionToken);
                
                ObjectMapper mapper = new ObjectMapper();
                // Keycloak expects an array of permission requests, not a single object
                PermissionRequest[] requestArray = new PermissionRequest[]{permissionRequest};
                String requestBody = mapper.writeValueAsString(requestArray);
                logger.debug("Sending permission request: {}", requestBody);
                post.setEntity(new StringEntity(requestBody));
                
                try (CloseableHttpResponse response = client.execute(post)) {
                    String responseBody = EntityUtils.toString(response.getEntity());
                    int statusCode = response.getStatusLine().getStatusCode();
                    logger.debug("Permission endpoint response - Status: {}, Body: {}", statusCode, responseBody);
                    
                    if (statusCode == 201) {
                        JsonNode jsonResponse = mapper.readTree(responseBody);
                        String ticket = jsonResponse.get("ticket").asText();
                        logger.info("Successfully obtained permission ticket: {}", ticket);
                        return ticket;
                    } else {
                        logger.warn("Failed to obtain permission ticket. Status: {}, Response: {}", 
                                   statusCode, responseBody);
                        return null;
                    }
                }
            }
        } catch (Exception e) {
            logger.error("Error requesting permission ticket", e);
            return null;
        }
    }

    private PermissionRequest buildPermissionRequest(RequestDetails theRequestDetails) {
        String resourcePath = theRequestDetails.getRequestPath();
        String httpMethod = theRequestDetails.getRequestType() != null ? theRequestDetails.getRequestType().name() : "GET";
        String resourceType = extractResourceType(resourcePath);
        String resourceId = extractResourceId(resourcePath);
        
        // Map FHIR resource to Keycloak resource
        String resourceIdentifier = mapFhirResourceToKeycloakResource(resourceType);
        
        // Map HTTP method to scopes
        String[] scopes = mapHttpMethodToScopes(httpMethod);
        
        logger.info("Created resource identifier for UMA: {} (mapped from FHIR resource: {})", resourceIdentifier, resourceType);
        logger.debug("Building permission request - Path: {}, Resource: {}, ID: {}, Method: {}, Scopes: {}", 
                    resourcePath, resourceType, resourceId, httpMethod, String.join(",", scopes));
        
        // Use the scopes based on HTTP method
        return new PermissionRequest(resourceIdentifier, scopes);
    }

    private String mapFhirResourceToKeycloakResource(String fhirResourceType) {
        // Map FHIR resource types to Keycloak UMA resource names
        // Based on the existing Keycloak configuration we found
        switch (fhirResourceType) {
            case "Patient":
                return "PatientResource";
            case "Observation":
                return "ObservationResource";
            case "Practitioner":
                return "PractitionerResource";
            case "Organization":
                return "OrganizationResource";
            case "Encounter":
                return "EncounterResource";
            case "Condition":
                return "ConditionResource";
            case "Medication":
                return "MedicationResource";
            case "MedicationRequest":
                return "MedicationRequestResource";
            case "DiagnosticReport":
                return "DiagnosticReportResource";
            case "ServiceRequest":
                return "ServiceRequestResource";
            default:
                // For unknown resources, use the pattern: ResourceTypeResource
                return fhirResourceType + "Resource";
        }
    }

    private String extractResourceType(String path) {
        if (path == null) return "Unknown";
        
        logger.debug("Extracting resource type from path: {}", path);
        
        // Handle the case where path is just the resource type (e.g., "Patient")
        // This is what HAPI FHIR passes to the interceptor
        if (!path.contains("/")) {
            // Simple case: path is just "Patient", "Observation", etc.
            if (path.length() > 0 && Character.isUpperCase(path.charAt(0))) {
                logger.debug("Direct resource type found: {}", path);
                return path;
            }
        }
        
        String[] parts = path.split("/");
        // Log the path parts for debugging
        logger.debug("Path parts: {}", String.join(", ", parts));
        
        // For HAPI FHIR, the path structure is typically /fhir/ResourceType or just /ResourceType
        for (int i = 0; i < parts.length; i++) {
            if ("fhir".equals(parts[i]) && i + 1 < parts.length) {
                String resourceType = parts[i + 1];
                logger.debug("Found resource type after 'fhir': {}", resourceType);
                return resourceType;
            }
        }
        
        // If no 'fhir' segment found, try to find the first non-empty segment that looks like a resource type
        for (String part : parts) {
            if (!part.isEmpty() && part.length() > 0 && Character.isUpperCase(part.charAt(0))) {
                logger.debug("Found potential resource type: {}", part);
                return part;
            }
        }
        
        logger.warn("Could not extract resource type from path: {}", path);
        return "Unknown";
    }

    private String extractResourceId(String path) {
        if (path == null) return null;
        
        String[] parts = path.split("/");
        // Look for pattern: .../fhir/ResourceType/id
        for (int i = 0; i < parts.length - 2; i++) {
            if ("fhir".equals(parts[i]) && i + 2 < parts.length) {
                // parts[i+1] is resource type, parts[i+2] is resource id
                String potentialId = parts[i + 2];
                // Basic validation - resource IDs shouldn't contain certain characters
                if (!potentialId.contains("?") && !potentialId.contains("&")) {
                    return potentialId;
                }
            }
        }
        return null;
    }

    private String[] mapHttpMethodToScopes(String httpMethod) {
        switch (httpMethod.toUpperCase()) {
            case "GET": return new String[]{"read"};
            case "POST": return new String[]{"create"};
            case "PUT": return new String[]{"update"};
            case "DELETE": return new String[]{"delete"};
            default: return new String[]{"read"};
        }
    }

    private void respondWithPermissionTicket(RequestDetails theRequestDetails, String permissionTicket) {
        // Set the WWW-Authenticate header for UMA compliance
        if (theRequestDetails instanceof ServletRequestDetails) {
            HttpServletResponse response = ((ServletRequestDetails) theRequestDetails).getServletResponse();
            if (response != null) {
                String wwwAuthenticateHeader = String.format(
                    "UMA realm=\"%s\", as_uri=\"%s\", ticket=\"%s\"",
                    "FHIR-Auth", 
                    AUTHORIZATION_SERVER_URI_EXTERNAL,  // Use external URI for client response
                    permissionTicket
                );
                response.setHeader("WWW-Authenticate", wwwAuthenticateHeader);
            }
        }
        
        logger.info("Responding with permission ticket - Ticket: {}, AS URI: {}", 
                   permissionTicket, AUTHORIZATION_SERVER_URI_EXTERNAL);
                   
        // Throw AuthenticationException with 401 status - HAPI FHIR will handle the response
        throw new AuthenticationException("Access token required. Use permission ticket to obtain access token.");
    }

    private void respondWithAuthServerUnreachable(RequestDetails theRequestDetails) {
        // Set the Warning header for UMA compliance  
        if (theRequestDetails instanceof ServletRequestDetails) {
            HttpServletResponse response = ((ServletRequestDetails) theRequestDetails).getServletResponse();
            if (response != null) {
                response.setHeader("Warning", "199 - \"UMA Authorization Server Unreachable\"");
            }
        }
        
        logger.warn("Authorization server unreachable, responding with 403");
        
        // Throw ForbiddenOperationException with 403 status - HAPI FHIR will handle the response
        throw new ForbiddenOperationException("Authorization server unreachable. Cannot process request.");
    }

    private String getProtectionApiToken() {
        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpPost post = new HttpPost(TOKEN_URL);
            post.setHeader("Content-Type", "application/x-www-form-urlencoded");
            String body = "grant_type=client_credentials&client_id=" + CLIENT_ID + "&client_secret=" + CLIENT_SECRET;
            post.setEntity(new StringEntity(body));
            
            try (CloseableHttpResponse response = client.execute(post)) {
                String responseBody = EntityUtils.toString(response.getEntity());
                int statusCode = response.getStatusLine().getStatusCode();
                
                if (statusCode == 200) {
                    ObjectMapper mapper = new ObjectMapper();
                    JsonNode jsonNode = mapper.readTree(responseBody);
                    String accessToken = jsonNode.get("access_token").asText();
                    logger.debug("Successfully obtained protection API token");
                    return accessToken;
                } else {
                    logger.error("Failed to obtain protection API token. Status: {}, Response: {}", 
                               statusCode, responseBody);
                    return null;
                }
            }
        } catch (Exception e) {
            logger.error("Error getting protection API token", e);
            return null;
        }
    }

    private boolean isTokenValid(String token) {
        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpPost post = new HttpPost(INTROSPECTION_URL);
            post.setHeader("Content-Type", "application/x-www-form-urlencoded");
            String body = "client_id=" + CLIENT_ID + "&client_secret=" + CLIENT_SECRET + "&token=" + token;
            post.setEntity(new StringEntity(body));
            
            try (CloseableHttpResponse response = client.execute(post)) {
                String responseBody = EntityUtils.toString(response.getEntity());
                ObjectMapper mapper = new ObjectMapper();
                JsonNode jsonNode = mapper.readTree(responseBody);
                boolean isActive = jsonNode.get("active").asBoolean();
                
                if (isActive) {
                    logger.debug("Token introspection successful - token is active");
                } else {
                    logger.debug("Token introspection indicates token is not active");
                }
                return isActive;
            }
        } catch (IOException e) {
            logger.error("Error during token introspection", e);
            return false;
        }
    }

    private boolean isPublicEndpoint(String requestPath) {
        if (requestPath == null) return false;
        
        boolean isPublic = requestPath.equals("metadata") ||
                          requestPath.equals("/metadata") ||
                          requestPath.equals("fhir/metadata") ||
                          requestPath.equals("/fhir/metadata") ||
                          requestPath.startsWith("/actuator/health") ||
                          requestPath.startsWith("/actuator/") ||
                          requestPath.startsWith("/.well-known") ||
                          requestPath.equals("/") ||
                          requestPath.startsWith("/css/") ||
                          requestPath.startsWith("/js/") ||
                          requestPath.startsWith("/img/") ||
                          requestPath.startsWith("/favicon");
        
        if (isPublic) {
            logger.debug("Identified as public endpoint: {}", requestPath);
        }
        
        return isPublic;
    }

    public static class PermissionRequest {
        private String resource_id;
        private String[] resource_scopes;
        
        public PermissionRequest(String resourceIdentifier, String[] scopes) {
            this.resource_id = resourceIdentifier;
            this.resource_scopes = scopes;
        }
        
        // Jackson serialization getters
        public String getResource_id() { return resource_id; }
        public String[] getResource_scopes() { return resource_scopes; }
        
        // Jackson deserialization setters (required for JSON parsing)
        public void setResource_id(String resource_id) { this.resource_id = resource_id; }
        public void setResource_scopes(String[] resource_scopes) { this.resource_scopes = resource_scopes; }
    }
}