package ca.uhn.fhir.jpa.starter.services;

import ca.uhn.fhir.jpa.api.dao.IFhirResourceDao;
import org.hl7.fhir.r5.model.Patient;
import org.hl7.fhir.r5.model.IdType;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.KeycloakBuilder;
import org.keycloak.admin.client.resource.AuthorizationResource;
import org.keycloak.representations.idm.authorization.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
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

    @Autowired(required = false)
    private IFhirResourceDao<Patient> patientDao;

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

            // Define Scopes (SMART on FHIR v2)
            Set<ScopeRepresentation> scopes = new HashSet<>();
            scopes.add(createScope("patient/Patient.r"));
            scopes.add(createScope("patient/Patient.rs"));
            scopes.add(createScope("patient/Condition.rs"));
            scopes.add(createScope("patient/MedicationStatement.rs"));
            scopes.add(createScope("patient/AllergyIntolerance.rs"));
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
     * Get system owner ID (placeholder for unregistered patients)
     */
    public String getSystemOwnerId() {
        return systemOwnerId;
    }

    /**
     * Look up a Patient's Keycloak UUID from the FHIR database.
     * Searches for an identifier with system "keycloak-uuid".
     *
     * @param patientId The FHIR Patient resource ID
     * @return The Keycloak user UUID, or null if not found
     */
    public String getPatientKeycloakId(String patientId) {
        if (patientDao == null) {
            log.warn("Patient DAO not available, cannot look up Keycloak ID");
            return null;
        }

        try {
            Patient patient = patientDao.read(new IdType("Patient", patientId), null);
            if (patient != null && patient.getIdentifier() != null) {
                for (var identifier : patient.getIdentifier()) {
                    if ("keycloak-uuid".equals(identifier.getSystem())) {
                        return identifier.getValue();
                    }
                }
            }
            log.warn("Patient {} does not have a keycloak-uuid identifier", patientId);
        } catch (Exception e) {
            log.error("Error looking up Patient {}: {}", patientId, e.getMessage());
        }
        return null;
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
