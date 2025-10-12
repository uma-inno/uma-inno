package ca.uhn.example.interceptor;

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
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class UmaKeycloakAuthInterceptor {
    private static final Logger logger = LoggerFactory.getLogger(UmaKeycloakAuthInterceptor.class);
    
    // Use localhost for internal server-to-server communication
    private static final String AUTHORIZATION_SERVER_URI_INTERNAL = "http://localhost:8080/realms/FHIR-Auth";
    // Use external IP for client-facing responses
    private static final String AUTHORIZATION_SERVER_URI_EXTERNAL = "http://172.29.16.64:8080/realms/FHIR-Auth";
    
    private static final String INTROSPECTION_URL = AUTHORIZATION_SERVER_URI_INTERNAL + "/protocol/openid-connect/token/introspect";
    private static final String PERMISSION_ENDPOINT = AUTHORIZATION_SERVER_URI_INTERNAL + "/authz/protection/permission";
    private static final String TOKEN_URL = AUTHORIZATION_SERVER_URI_INTERNAL + "/protocol/openid-connect/token";
    
    private static final String CLIENT_ID = "fhir-client";
    private static final String CLIENT_SECRET = "QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP";

    @Hook(Pointcut.SERVER_INCOMING_REQUEST_PRE_HANDLED)
    public void handleRequest(RequestDetails theRequestDetails) {
        String requestPath = theRequestDetails.getRequestPath();
        if (isPublicEndpoint(requestPath)) {
            logger.debug("Skipping authentication for public endpoint: {}", requestPath);
            return;
        }

        String authHeader = theRequestDetails.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            handleTokenlessAccess(theRequestDetails);
            return;
        }

        String token = authHeader.substring(7);
        if (!isTokenValid(token)) {
            logger.warn("Invalid or expired token for request: {}", requestPath);
            throw new AuthenticationException("Invalid or expired token");
        }
        logger.debug("Successfully authenticated request to: {}", requestPath);
    }

    private void handleTokenlessAccess(RequestDetails theRequestDetails) {
        logger.info("Handling tokenless access for: {}", theRequestDetails.getRequestPath());
        try {
            String permissionTicket = requestPermissionTicket(theRequestDetails);
            if (permissionTicket != null) {
                respondWithPermissionTicket(theRequestDetails, permissionTicket);
            } else {
                respondWithAuthServerUnreachable(theRequestDetails);
            }
        } catch (Exception e) {
            logger.error("Error handling tokenless access", e);
            respondWithAuthServerUnreachable(theRequestDetails);
        }
    }

    private String requestPermissionTicket(RequestDetails theRequestDetails) {
        try {
            PermissionRequest permissionRequest = buildPermissionRequest(theRequestDetails);
            try (CloseableHttpClient client = HttpClients.createDefault()) {
                HttpPost post = new HttpPost(PERMISSION_ENDPOINT);
                post.setHeader("Content-Type", "application/json");
                post.setHeader("Authorization", "Bearer " + getProtectionApiToken());
                
                ObjectMapper mapper = new ObjectMapper();
                String requestBody = mapper.writeValueAsString(permissionRequest);
                post.setEntity(new StringEntity(requestBody));
                
                try (CloseableHttpResponse response = client.execute(post)) {
                    String responseBody = EntityUtils.toString(response.getEntity());
                    if (response.getStatusLine().getStatusCode() == 201) {
                        JsonNode jsonResponse = mapper.readTree(responseBody);
                        String ticket = jsonResponse.get("ticket").asText();
                        logger.info("Successfully obtained permission ticket: {}", ticket);
                        return ticket;
                    } else {
                        logger.warn("Failed to obtain permission ticket. Status: {}, Response: {}", 
                                   response.getStatusLine().getStatusCode(), responseBody);
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
        String httpMethod = theRequestDetails.getRequestType().name();
        String resourceType = extractResourceType(resourcePath);
        String resourceId = extractResourceId(resourcePath);
        String[] scopes = mapHttpMethodToScopes(httpMethod);
        return new PermissionRequest(resourceType, resourceId, scopes);
    }

    private String extractResourceType(String path) {
        String[] parts = path.split("/");
        for (int i = 0; i < parts.length; i++) {
            if ("fhir".equals(parts[i]) && i + 1 < parts.length) {
                return parts[i + 1];
            }
        }
        return "Unknown";
    }

    private String extractResourceId(String path) {
        String[] parts = path.split("/");
        if (parts.length >= 4 && "fhir".equals(parts[parts.length - 3])) {
            return parts[parts.length - 1];
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
    }    private void respondWithPermissionTicket(RequestDetails theRequestDetails, String permissionTicket) {
        HttpServletResponse response = ((ServletRequestDetails) theRequestDetails).getServletResponse();
        String wwwAuthenticateHeader = String.format(
            "UMA realm=\"%s\", as_uri=\"%s\", ticket=\"%s\"",
            "FHIR-Auth", 
            AUTHORIZATION_SERVER_URI_EXTERNAL,  // Use external URI for client response
            permissionTicket
        );
        response.setHeader("WWW-Authenticate", wwwAuthenticateHeader);
        throw new AuthenticationException("Access token required. Use permission ticket to obtain access token.");
    }    private void respondWithAuthServerUnreachable(RequestDetails theRequestDetails) {
        HttpServletResponse response = ((ServletRequestDetails) theRequestDetails).getServletResponse();
        response.setHeader("Warning", "199 - \"UMA Authorization Server Unreachable\"");
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
                ObjectMapper mapper = new ObjectMapper();
                JsonNode jsonNode = mapper.readTree(responseBody);
                return jsonNode.get("access_token").asText();
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
        return requestPath != null && (
            requestPath.startsWith("/actuator/health") ||
            requestPath.startsWith("/metadata") ||
            requestPath.startsWith("/.well-known") ||
            requestPath.startsWith("/fhir/metadata")
        );
    }

    public static class PermissionRequest {
        private String resource_id;
        private String[] resource_scopes;
        
        public PermissionRequest(String resourceType, String resourceId, String[] scopes) {
            this.resource_id = resourceId != null ? resourceType + "/" + resourceId : resourceType;
            this.resource_scopes = scopes;
        }
        
        public String getResource_id() { return resource_id; }
        public String[] getResource_scopes() { return resource_scopes; }
    }
}