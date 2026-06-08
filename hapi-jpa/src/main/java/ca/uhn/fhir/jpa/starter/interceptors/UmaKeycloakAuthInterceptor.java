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
import org.apache.http.client.methods.HttpGet;
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
import java.util.Base64;
import java.util.List;
import java.util.ArrayList;

@Component
public class UmaKeycloakAuthInterceptor {
    private static final Logger logger = LoggerFactory.getLogger(UmaKeycloakAuthInterceptor.class);
    
    // Use localhost for both internal and external communication
    // Docker extra_hosts configuration maps localhost to the host machine (host-gateway)
    // This ensures the FHIR server uses the same URL that Keycloak uses for token issuance
    private static final String AUTHORIZATION_SERVER_URI = "http://keycloak:8080/realms/FHIR-Auth";

    private static final String INTROSPECTION_URL = AUTHORIZATION_SERVER_URI + "/protocol/openid-connect/token/introspect";
    private static final String PERMISSION_ENDPOINT = AUTHORIZATION_SERVER_URI + "/authz/protection/permission";
    private static final String TOKEN_URL = AUTHORIZATION_SERVER_URI + "/protocol/openid-connect/token";
    
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

            // FOURTH: For CREATE (POST) operations, check role-based access control (RBAC)
            // The resource doesn't exist yet, so we can't check instance-level permissions
            // Instead, we check if the user's role allows them to create this resource type
            String httpMethod = theRequestDetails.getRequestType() != null ? theRequestDetails.getRequestType().name() : "GET";
            if ("POST".equals(httpMethod)) {
                logger.info("CREATE operation (POST) detected - checking role-based access control");

                // Extract token
                String authHeader = theRequestDetails.getHeader("Authorization");
                if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                    logger.warn("No authorization token for CREATE operation");
                    throw new AuthenticationException("Authorization token required to create resources");
                }
                String token = authHeader.substring(7);

                // Extract roles from token
                List<String> roles = extractRolesFromToken(token);
                logger.info("User has {} roles: {}", roles.size(), roles);

                if (roles.isEmpty()) {
                    logger.warn("No roles found in token - denying resource creation");
                    throw new ForbiddenOperationException("No roles found. Cannot create resources without assigned roles.");
                }

                // Check if any role allows creating this resource type
                if (!canRoleCreateResource(roles, resourceType)) {
                    logger.warn("User roles {} do not have permission to create resource type: {}", roles, resourceType);
                    throw new ForbiddenOperationException("You do not have permission to create " + resourceType + " resources");
                }

                logger.info("✓ Role-based access check passed for creating {} with roles: {}", resourceType, roles);
                return; // Allow creation to proceed
            }

            logger.info("Applying UMA authentication to {} resource", resourceType);

            String authHeader = theRequestDetails.getHeader("Authorization");
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                logger.info("No authorization header found, handling tokenless access for: {}", requestPath);
                handleTokenlessAccess(theRequestDetails);
                return; // handleTokenlessAccess will throw an exception to abort processing
            }

            String token = authHeader.substring(7);

            // FIRST: Check if token is an RPT (has authorization.permissions) or a plain access token
            boolean isRpt = tokenHasPermissions(token);

            if (!isRpt) {
                // Plain access token — check it is active via introspection
                if (!isTokenValid(token)) {
                    logger.warn("Invalid or expired token for request: {}", requestPath);
                    handleTokenlessAccess(theRequestDetails);
                    return;
                }
                // Active plain token but no permissions yet — request permission ticket
                logger.info("Token is valid but has no UMA permissions — requesting permission ticket");
                handleTokenlessAccess(theRequestDetails);
                return;
            }

            // SECOND: Token is an RPT — check permissions directly from JWT (no introspection needed)

            String[] requiredScopes = mapHttpMethodToScopes(httpMethod);
            
            // Determine if this is instance-level (has ID) or type-level (no ID)
            String resourceId = theRequestDetails.getId() != null 
                ? theRequestDetails.getId().getIdPart() : null;
            String resourceName;
            if (resourceId != null) {
                // Instance-level: use "Patient/XX" format 
                resourceName = resourceType + "/" + resourceId;
                logger.info("Instance-level permission check for: {}", resourceName);
            } else {
                // Type-level: use "PatientResource" format
                resourceName = mapFhirResourceToKeycloakResource(resourceType);
                logger.info("Type-level permission check for: {}", resourceName);
            }

            logger.info("=== PERMISSION CHECK START ===");
            logger.info("HTTP Method: {}, Required Scopes: {}, Resource Name: {}",
                       httpMethod, String.join(",", requiredScopes), resourceName);

            // Validate that the token has at least one of the required scopes
            boolean hasPermission = false;
            for (String scope : requiredScopes) {
                logger.info("Checking if token has permission for scope: {}", scope);
                if (hasRequiredPermission(token, resourceName, scope)) {
                    hasPermission = true;
                    logger.info("✓ Token has permission for scope: {}", scope);
                    break;
                }
            }

            logger.info("=== PERMISSION CHECK END - Result: {} ===", hasPermission ? "GRANTED" : "DENIED");

            if (!hasPermission) {
                logger.warn("Token does not have required permissions for resource: {}, scopes: {}",
                           resourceName, String.join(",", requiredScopes));
                // Request new permission ticket with updated permissions
                handleTokenlessAccess(theRequestDetails);
                return;
            }

            logger.info("Successfully authenticated and authorized request to: {} with resource: {}",
                       requestPath, resourceName);
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
        return "Patient".equals(resourceType);
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
                // Build JSON manually to omit resource_scopes when empty
                String resourceId = permissionRequest.getResource_id();
                String requestBody;
                if (permissionRequest.getResource_scopes() == null || permissionRequest.getResource_scopes().length == 0) {
                    requestBody = "[{\"resource_id\":\"" + resourceId + "\"}]";
                } else {
                    PermissionRequest[] requestArray = new PermissionRequest[]{permissionRequest};
                    requestBody = mapper.writeValueAsString(requestArray);
                }
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

        // Use theRequestDetails.getId() for reliable resource ID extraction (same as handleRequest)
        String resourceId = theRequestDetails.getId() != null
            ? theRequestDetails.getId().getIdPart() : null;

        // Use instance-level resource identifier if ID present, otherwise type-level
        String resourceName;
        if (resourceId != null) {
            // Instance-level: use "Patient/XX" format (matches Keycloak UMA registration)
            resourceName = resourceType + "/" + resourceId;
            logger.info("PERMISSION REQUEST: Using INSTANCE-LEVEL resource: {}", resourceName);
        } else {
            // Type-level: use "PatientResource" format
            resourceName = mapFhirResourceToKeycloakResource(resourceType);
            logger.info("PERMISSION REQUEST: Using TYPE-LEVEL resource: {}", resourceName);
        }

        // Look up the resource UUID from Keycloak
        // Keycloak's Protection API requires the UUID, not the name
        String resourceUuid = lookupResourceUuid(resourceName);
        if (resourceUuid == null) {
            logger.warn("Could not find resource UUID for: {}", resourceName);
            // Fall back to using the resource name (will likely fail)
            resourceUuid = resourceName;
        }

        logger.info("Using resource UUID: {} for resource name: {}", resourceUuid, resourceName);
        logger.debug("Building permission request - Path: {}, Resource: {}, ID: {}, Method: {}",
                    resourcePath, resourceType, resourceId, httpMethod);

        // Send no scopes in the ticket request — Keycloak will include all scopes the user has
        return new PermissionRequest(resourceUuid, new String[0]);
    }

    private static final String ADMIN_BASE = "http://keycloak:8080/admin/realms/FHIR-Auth";
    private static final String MASTER_TOKEN_URL = "http://keycloak:8080/realms/master/protocol/openid-connect/token";

    /**
     * Look up the UUID of a resource in Keycloak by its name via Admin API
     */
    private String lookupResourceUuid(String resourceName) {
        try {
            String adminToken = getAdminToken();
            if (adminToken == null) {
                logger.error("Failed to obtain admin token for resource lookup");
                return null;
            }

            String clientUuid;
            try (CloseableHttpClient client = HttpClients.createDefault()) {
                HttpGet get = new HttpGet(ADMIN_BASE + "/clients?clientId=" + CLIENT_ID);
                get.setHeader("Authorization", "Bearer " + adminToken);
                try (CloseableHttpResponse response = client.execute(get)) {
                    String body = EntityUtils.toString(response.getEntity());
                    clientUuid = new ObjectMapper().readTree(body).get(0).get("id").asText();
                }
            }

            try (CloseableHttpClient client = HttpClients.createDefault()) {
                HttpGet get = new HttpGet(ADMIN_BASE + "/clients/" + clientUuid
                    + "/authz/resource-server/resource?name=" + resourceName);
                get.setHeader("Authorization", "Bearer " + adminToken);

                try (CloseableHttpResponse response = client.execute(get)) {
                    String responseBody = EntityUtils.toString(response.getEntity());
                    int statusCode = response.getStatusLine().getStatusCode();

                    if (statusCode == 200) {
                        JsonNode jsonResponse = new ObjectMapper().readTree(responseBody);
                        if (jsonResponse.isArray() && jsonResponse.size() > 0) {
                            String uuid = jsonResponse.get(0).get("_id").asText();
                            logger.info("Found resource UUID: {} for name: {}", uuid, resourceName);
                            return uuid;
                        } else {
                            logger.warn("No resource found with name: {}", resourceName);
                            return null;
                        }
                    } else {
                        logger.error("Resource lookup failed - Status: {}, Response: {}", statusCode, responseBody);
                        return null;
                    }
                }
            }
        } catch (Exception e) {
            logger.error("Error looking up resource UUID for: {}", resourceName, e);
            return null;
        }
    }

    private String getAdminToken() {
        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpPost post = new HttpPost(MASTER_TOKEN_URL);
            post.setHeader("Content-Type", "application/x-www-form-urlencoded");
            post.setEntity(new StringEntity(
                "grant_type=password&client_id=admin-cli&username=admin&password=admin"));
            try (CloseableHttpResponse response = client.execute(post)) {
                String body = EntityUtils.toString(response.getEntity());
                if (response.getStatusLine().getStatusCode() == 200) {
                    return new ObjectMapper().readTree(body).get("access_token").asText();
                }
            }
        } catch (Exception e) {
            logger.error("Error getting admin token", e);
        }
        return null;
    }

    private String mapFhirResourceToKeycloakResource(String fhirResourceType) {
        // Type-level requests without ID fall back to resource name without instance
        // In the new architecture only Patient/X is registered — type-level not supported
        return fhirResourceType;
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
            case "GET": return new String[]{"patient/Patient.r"};
            case "POST": return new String[]{"patient/Patient.r"};
            case "PUT": return new String[]{"patient/Patient.r"};
            case "DELETE": return new String[]{"patient/Patient.r"};
            default: return new String[]{"patient/Patient.r"};
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
                    AUTHORIZATION_SERVER_URI,
                    permissionTicket
                );
                response.setHeader("WWW-Authenticate", wwwAuthenticateHeader);
            }
        }

        logger.info("Responding with permission ticket - Ticket: {}, AS URI: {}",
                   permissionTicket, AUTHORIZATION_SERVER_URI);
                   
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

    private boolean tokenHasPermissions(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) return false;
            String payload = new String(Base64.getUrlDecoder().decode(parts[1]));
            JsonNode payloadJson = new ObjectMapper().readTree(payload);
            boolean hasAuth = payloadJson.has("authorization") &&
                              payloadJson.get("authorization").has("permissions") &&
                              payloadJson.get("authorization").get("permissions").size() > 0;
            logger.info("Token has UMA permissions: {}", hasAuth);
            return hasAuth;
        } catch (Exception e) {
            logger.warn("Could not check token permissions: {}", e.getMessage());
            return false;
        }
    }

    private boolean isTokenValid(String token) {
        logger.info("Starting token introspection for token: {}...", token.substring(0, Math.min(50, token.length())));
        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpPost post = new HttpPost(INTROSPECTION_URL);
            post.setHeader("Content-Type", "application/x-www-form-urlencoded");
            String body = "client_id=" + CLIENT_ID + "&client_secret=" + CLIENT_SECRET + "&token=" + token;
            post.setEntity(new StringEntity(body));

            logger.info("Sending introspection request to: {}", INTROSPECTION_URL);

            try (CloseableHttpResponse response = client.execute(post)) {
                String responseBody = EntityUtils.toString(response.getEntity());
                int statusCode = response.getStatusLine().getStatusCode();

                logger.info("Introspection response - Status: {}, Body: {}", statusCode, responseBody);

                ObjectMapper mapper = new ObjectMapper();
                JsonNode jsonNode = mapper.readTree(responseBody);

                if (!jsonNode.has("active")) {
                    logger.error("Introspection response missing 'active' field");
                    return false;
                }

                boolean isActive = jsonNode.get("active").asBoolean();

                if (isActive) {
                    logger.info("Token introspection successful - token is active");
                } else {
                    logger.warn("Token introspection indicates token is not active");
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

    /**
     * Extracts permissions from an RPT token by decoding the JWT payload
     *
     * @param token The RPT token (JWT)
     * @return List of permissions granted in the token
     */
    private List<RptPermission> extractPermissionsFromRPT(String token) {
        List<RptPermission> permissions = new ArrayList<>();

        try {
            // JWT structure: header.payload.signature
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                logger.warn("Invalid JWT format - expected 3 parts, got {}", parts.length);
                return permissions;
            }

            // Decode the payload (second part)
            String payload = new String(Base64.getUrlDecoder().decode(parts[1]));
            logger.info("=== DECODED JWT PAYLOAD START ===");
            logger.info("{}", payload);
            logger.info("=== DECODED JWT PAYLOAD END ===");

            // Parse JSON
            ObjectMapper mapper = new ObjectMapper();
            JsonNode payloadJson = mapper.readTree(payload);

            // Check if authorization field exists
            if (!payloadJson.has("authorization")) {
                logger.warn("JWT payload does NOT contain 'authorization' field!");
                logger.warn("Available fields: {}", payloadJson.fieldNames());
                return permissions;
            }

            // Extract authorization.permissions
            JsonNode authNode = payloadJson.get("authorization");
            logger.info("Found 'authorization' field: {}", authNode.toString());

            if (!authNode.has("permissions")) {
                logger.warn("'authorization' field does NOT contain 'permissions' array!");
                return permissions;
            }

            JsonNode permissionsNode = authNode.get("permissions");
            logger.info("Found 'permissions' array with {} entries", permissionsNode.size());

            for (JsonNode permNode : permissionsNode) {
                RptPermission permission = new RptPermission();

                if (permNode.has("rsid")) {
                    permission.setRsid(permNode.get("rsid").asText());
                }
                if (permNode.has("rsname")) {
                    permission.setRsname(permNode.get("rsname").asText());
                }
                if (permNode.has("scopes")) {
                    JsonNode scopesNode = permNode.get("scopes");
                    List<String> scopesList = new ArrayList<>();
                    for (JsonNode scopeNode : scopesNode) {
                        scopesList.add(scopeNode.asText());
                    }
                    permission.setScopes(scopesList);
                }

                permissions.add(permission);
                logger.info("Extracted permission: rsname={}, rsid={}, scopes={}",
                           permission.getRsname(), permission.getRsid(), permission.getScopes());
            }

            logger.info("Successfully extracted {} permissions from RPT", permissions.size());
        } catch (Exception e) {
            logger.error("Error extracting permissions from RPT", e);
            logger.error("Token preview: {}...", token.substring(0, Math.min(50, token.length())));
        }

        return permissions;
    }

    /**
     * Validates if the token has the required permission for the requested resource
     *
     * @param token The RPT token
     * @param resourceName The Keycloak resource name (e.g., "Patient/52" or "PatientResource")
     * @param requiredScope The required scope (e.g., "read")
     * @return true if the token has the required permission
     */
    private boolean hasRequiredPermission(String token, String resourceName, String requiredScope) {
        logger.info("Checking permission for resource: {}, scope: {}", resourceName, requiredScope);

        List<RptPermission> permissions = extractPermissionsFromRPT(token);

        logger.info("Total permissions extracted: {}", permissions.size());

        for (RptPermission permission : permissions) {
            logger.info("Checking permission - rsname: {}, scopes: {}",
                       permission.getRsname(), permission.getScopes());

            if (!resourceName.equals(permission.getRsname())) {
                logger.debug("Resource name mismatch: expected '{}', got '{}'",
                            resourceName, permission.getRsname());
                continue;
            }

            logger.info("Resource name matches! Checking scopes...");
            if (permission.getScopes() == null) {
                logger.warn("No scopes in permission for resource: {}", resourceName);
                continue;
            }

            // Accept if any scope in the RPT starts with "patient/" — token has access to this patient
            for (String grantedScope : permission.getScopes()) {
                if (grantedScope.startsWith("patient/")) {
                    logger.info("✓ Permission validated: resource={}, granted scope={}", resourceName, grantedScope);
                    return true;
                }
            }

            logger.warn("Resource matches but no patient/ scope found. Available scopes: {}",
                       permission.getScopes());
        }

        logger.warn("✗ Required permission NOT found: resource={}, scope={}", resourceName, requiredScope);
        return false;
    }

    /**
     * Represents a permission granted in an RPT token
     */
    public static class RptPermission {
        private String rsid;    // Resource ID
        private String rsname;  // Resource name
        private List<String> scopes; // Granted scopes

        public String getRsid() { return rsid; }
        public void setRsid(String rsid) { this.rsid = rsid; }

        public String getRsname() { return rsname; }
        public void setRsname(String rsname) { this.rsname = rsname; }

        public List<String> getScopes() { return scopes; }
        public void setScopes(List<String> scopes) { this.scopes = scopes; }
    }

    public static class PermissionRequest {
        // Keycloak expects the UUID in resource_id field
        private String resource_id;
        private String[] resource_scopes;

        public PermissionRequest(String resourceId, String[] scopes) {
            this.resource_id = resourceId;
            this.resource_scopes = scopes;
        }

        // Jackson serialization getters
        public String getResource_id() { return resource_id; }
        public String[] getResource_scopes() { return resource_scopes; }

        // Jackson deserialization setters (required for JSON parsing)
        public void setResource_id(String resource_id) { this.resource_id = resource_id; }
        public void setResource_scopes(String[] resource_scopes) { this.resource_scopes = resource_scopes; }
    }

    /**
     * Extract roles from JWT token.
     * Keycloak stores realm roles in: realm_access.roles
     *
     * @param token The JWT token
     * @return List of roles, or empty list if none found
     */
    private List<String> extractRolesFromToken(String token) {
        List<String> roles = new ArrayList<>();

        try {
            // JWT: header.payload.signature
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                logger.warn("Invalid JWT format - expected 3 parts, got {}", parts.length);
                return roles;
            }

            // Decode payload
            String payload = new String(Base64.getUrlDecoder().decode(parts[1]));
            ObjectMapper mapper = new ObjectMapper();
            JsonNode payloadJson = mapper.readTree(payload);

            // Extract realm_access.roles
            if (payloadJson.has("realm_access")) {
                JsonNode realmAccess = payloadJson.get("realm_access");
                if (realmAccess.has("roles")) {
                    JsonNode rolesNode = realmAccess.get("roles");
                    for (JsonNode roleNode : rolesNode) {
                        roles.add(roleNode.asText());
                    }
                    logger.info("Extracted {} roles from token: {}", roles.size(), roles);
                }
            } else {
                logger.debug("Token does not contain realm_access field");
            }
        } catch (Exception e) {
            logger.error("Error extracting roles from token", e);
        }

        return roles;
    }

    /**
     * Check if any of the user's roles allow creating the specified resource type.
     *
     * RBAC Rules:
     * - patient: Cannot create any resources
     * - practitioner/doctor: Can create Patient and clinical resources
     * - admin: Can create everything
     *
     * @param roles List of user's roles
     * @param resourceType The FHIR resource type to create
     * @return true if any role allows creation, false otherwise
     */
    private boolean canRoleCreateResource(List<String> roles, String resourceType) {
        for (String role : roles) {
            switch (role.toLowerCase()) {
                case "patient":
                    // Patients cannot create any resources
                    logger.debug("Role 'patient' cannot create resources");
                    continue;

                case "doctor":
                    // Practitioners can create Patient and clinical resources
                    boolean canCreate = "Patient".equals(resourceType) ||
                                      "Condition".equals(resourceType) ||
                                      "AllergyIntolerance".equals(resourceType) ||

                                      "MedicationStatement".equals(resourceType);
                    if (canCreate) {
                        logger.info("Role '{}' can create {}", role, resourceType);
                        return true;
                    }
                    break;

                case "admin":
                    // Admins can create everything
                    logger.info("Role 'admin' can create any resource");
                    return true;

                default:
                    logger.debug("Unknown role '{}' - no creation permission", role);
            }
        }

        logger.warn("No role found that allows creating {}", resourceType);
        return false;
    }
}