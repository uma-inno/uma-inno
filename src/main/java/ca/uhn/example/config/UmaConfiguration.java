package ca.uhn.example.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
@ConfigurationProperties(prefix = "uma")
public class UmaConfiguration {
    
    private String authorizationServerUri = "http://172.29.16.64:8080/realms/FHIR-Auth";
    private String clientId = "fhir-client";
    private String clientSecret = "QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP";
    private String realm = "FHIR-Auth";
    private boolean enabled = true;
    
    // Endpoints
    private Endpoints endpoints = new Endpoints();
    
    // Public endpoints that don't require authentication
    private List<String> publicEndpoints = List.of(
        "/actuator/health",
        "/metadata", 
        "/.well-known"
    );
    
    // Resource to scope mappings
    private ResourceMappings resourceMappings = new ResourceMappings();
    
    // Getters and setters
    public String getAuthorizationServerUri() { return authorizationServerUri; }
    public void setAuthorizationServerUri(String authorizationServerUri) { this.authorizationServerUri = authorizationServerUri; }
    
    public String getClientId() { return clientId; }
    public void setClientId(String clientId) { this.clientId = clientId; }
    
    public String getClientSecret() { return clientSecret; }
    public void setClientSecret(String clientSecret) { this.clientSecret = clientSecret; }
    
    public String getRealm() { return realm; }
    public void setRealm(String realm) { this.realm = realm; }
    
    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
    
    public Endpoints getEndpoints() { return endpoints; }
    public void setEndpoints(Endpoints endpoints) { this.endpoints = endpoints; }
    
    public List<String> getPublicEndpoints() { return publicEndpoints; }
    public void setPublicEndpoints(List<String> publicEndpoints) { this.publicEndpoints = publicEndpoints; }
    
    public ResourceMappings getResourceMappings() { return resourceMappings; }
    public void setResourceMappings(ResourceMappings resourceMappings) { this.resourceMappings = resourceMappings; }
    
    // Helper methods
    public String getIntrospectionUrl() {
        return authorizationServerUri + "/protocol/openid-connect/token/introspect";
    }
    
    public String getTokenUrl() {
        return authorizationServerUri + "/protocol/openid-connect/token";
    }
    
    public String getPermissionUrl() {
        return authorizationServerUri + "/authz/protection/permission";
    }
    
    public static class Endpoints {
        private String introspection = "/protocol/openid-connect/token/introspect";
        private String token = "/protocol/openid-connect/token";
        private String permission = "/authz/protection/permission";
        
        // Getters and setters
        public String getIntrospection() { return introspection; }
        public void setIntrospection(String introspection) { this.introspection = introspection; }
        
        public String getToken() { return token; }
        public void setToken(String token) { this.token = token; }
        
        public String getPermission() { return permission; }
        public void setPermission(String permission) { this.permission = permission; }
    }
    
    public static class ResourceMappings {
        // HTTP method to UMA scope mappings
        private String readScope = "read";
        private String createScope = "create";
        private String updateScope = "update";
        private String deleteScope = "delete";
        
        // Getters and setters
        public String getReadScope() { return readScope; }
        public void setReadScope(String readScope) { this.readScope = readScope; }
        
        public String getCreateScope() { return createScope; }
        public void setCreateScope(String createScope) { this.createScope = createScope; }
        
        public String getUpdateScope() { return updateScope; }
        public void setUpdateScope(String updateScope) { this.updateScope = updateScope; }
        
        public String getDeleteScope() { return deleteScope; }
        public void setDeleteScope(String deleteScope) { this.deleteScope = deleteScope; }
    }
}