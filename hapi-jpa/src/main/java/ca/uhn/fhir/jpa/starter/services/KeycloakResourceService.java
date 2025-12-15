package ca.uhn.fhir.jpa.starter.services;

import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.KeycloakBuilder;
import org.keycloak.admin.client.resource.AuthorizationResource;
import org.keycloak.representations.idm.authorization.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import jakarta.ws.rs.core.Response;
import java.util.HashSet;
import java.util.Set;

/**
 * Service for managing FHIR resource registration in Keycloak Authorization Services
 */
@Service
public class KeycloakResourceService {

    private static final Logger log = LoggerFactory.getLogger(KeycloakResourceService.class);

    @Value("${keycloak.auth-server-url}")
    private String authServerUrl;

    @Value("${keycloak.realm}")
    private String realm;

    @Value("${keycloak.resource}")
    private String clientId;

    @Value("${keycloak.system-owner-id}")
    private String systemOwnerId;

    private Keycloak keycloakAdmin;
    private String clientUuid;

    @PostConstruct
    public void init() {
        try {
            // Initialize Keycloak Admin Client
            this.keycloakAdmin = KeycloakBuilder.builder()
                .serverUrl(authServerUrl)
                .realm("master")
                .username("admin")
                .password("admin")
                .clientId("admin-cli")
                .build();

            // Get client UUID for fhir-client
            this.clientUuid = keycloakAdmin.realm(realm)
                .clients()
                .findByClientId(clientId)
                .get(0)
                .getId();

            log.info("KeycloakResourceService initialized successfully");
            log.info("Server: {}, Realm: {}, Client: {} ({})",
                authServerUrl, realm, clientId, clientUuid);
            log.info("System Owner ID: {}", systemOwnerId);

        } catch (Exception e) {
            log.error("Failed to initialize KeycloakResourceService: {}", e.getMessage(), e);
        }
    }

    /**
     * Register a FHIR resource in Keycloak Authorization Service
     *
     * @param resourceType FHIR resource type (e.g., "Patient", "Condition")
     * @param resourceId FHIR resource ID
     * @param ownerId Keycloak user UUID who owns this resource
     */
    public void registerResource(String resourceType, String resourceId, String ownerId) {
        String resourceName = resourceType + "/" + resourceId;

        try {
            AuthorizationResource authz = getAuthorizationResource();

            // Create Resource Representation
            ResourceRepresentation resource = new ResourceRepresentation();
            resource.setName(resourceName);
            resource.setDisplayName(resourceName);  // Display name for Keycloak UI
            resource.setType(resourceType);

            // Set owner - must use setId() method
            ResourceOwnerRepresentation owner = new ResourceOwnerRepresentation();
            owner.setId(ownerId);
            resource.setOwner(owner);
            resource.setOwnerManagedAccess(true);  // Enable UMA for this resource

            // Define Scopes
            Set<ScopeRepresentation> scopes = new HashSet<>();
            scopes.add(createScope("read"));
            scopes.add(createScope("write"));
            scopes.add(createScope("delete"));
            resource.setScopes(scopes);

            // Create Resource in Keycloak
            Response response = authz.resources().create(resource);

            if (response.getStatus() == 201) {
                log.info("Registered resource: {} with owner: {}", resourceName, ownerId);
            } else {
                log.warn("Resource registration returned status {}: {}",
                    response.getStatus(), resourceName);
            }

            response.close();

        } catch (Exception e) {
            log.error("Failed to register resource {}: {}", resourceName, e.getMessage());
            // Don't throw - FHIR operation should continue even if Keycloak registration fails
        }
    }

    /**
     * Grant permissions to a creator (e.g., doctor who created a resource)
     *
     * @param resourceType FHIR resource type
     * @param resourceId FHIR resource ID
     * @param creatorId Keycloak user UUID of the creator
     * @param ownerId Keycloak user UUID of the owner
     */
    public void grantCreatorPermissions(String resourceType, String resourceId,
                                        String creatorId, String ownerId) {

        String resourceName = resourceType + "/" + resourceId;

        // If creator is owner, no additional permissions needed
        if (creatorId.equals(ownerId)) {
            log.debug("Creator is owner for {}, no additional permissions needed", resourceName);
            return;
        }

        try {
            AuthorizationResource authz = getAuthorizationResource();

            // 1. Create User Policy for Creator
            PolicyRepresentation policy = new PolicyRepresentation();
            policy.setName("Creator-" + creatorId + "-" + resourceName);
            policy.setType("user");
            policy.setLogic(Logic.POSITIVE);
            policy.setDecisionStrategy(DecisionStrategy.UNANIMOUS);

            // Set users config (JSON array format required by Keycloak)
            policy.getConfig().put("users", "[\"" + creatorId + "\"]");

            Response policyResponse = authz.policies().create(policy);

            if (policyResponse.getStatus() != 201) {
                log.error("Failed to create policy for creator {} (status {})",
                    creatorId, policyResponse.getStatus());
                policyResponse.close();
                return;
            }

            // Extract policy ID from Location header
            String location = policyResponse.getHeaderString("Location");
            String policyId = location.substring(location.lastIndexOf('/') + 1);
            policyResponse.close();

            log.debug("Created policy {} for creator {}", policyId, creatorId);

            // 2. Create Resource Permission
            ResourcePermissionRepresentation permission = new ResourcePermissionRepresentation();
            permission.setName(resourceName + "-CreatorAccess");
            permission.addResource(resourceName);
            permission.addPolicy(policyId);
            permission.setDecisionStrategy(DecisionStrategy.UNANIMOUS);

            // Grant read and write, but NOT delete
            Set<String> scopes = new HashSet<>();
            scopes.add("read");
            scopes.add("write");
            permission.setScopes(scopes);

            Response permResponse = authz.permissions().resource().create(permission);

            if (permResponse.getStatus() == 201) {
                log.info("Granted creator permissions to {} for {}", creatorId, resourceName);
            } else {
                log.error("Failed to create permission (status {})", permResponse.getStatus());
            }

            permResponse.close();

        } catch (Exception e) {
            log.error("Failed to grant creator permissions for {}: {}",
                resourceName, e.getMessage(), e);
        }
    }

    /**
     * Get system owner ID (placeholder for unregistered patients)
     */
    public String getSystemOwnerId() {
        return systemOwnerId;
    }

    private ScopeRepresentation createScope(String name) {
        ScopeRepresentation scope = new ScopeRepresentation();
        scope.setName(name);
        return scope;
    }

    private AuthorizationResource getAuthorizationResource() {
        return keycloakAdmin.realm(realm)
            .clients()
            .get(clientUuid)
            .authorization();
    }
}
