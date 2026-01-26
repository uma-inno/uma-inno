package ca.uhn.fhir.jpa.starter.interceptors;

import ca.uhn.fhir.interceptor.api.Hook;
import ca.uhn.fhir.interceptor.api.Interceptor;
import ca.uhn.fhir.interceptor.api.Pointcut;
import ca.uhn.fhir.jpa.api.dao.IFhirResourceDao;
import ca.uhn.fhir.jpa.searchparam.SearchParameterMap;
import ca.uhn.fhir.rest.api.server.IBundleProvider;
import ca.uhn.fhir.rest.api.server.RequestDetails;
import ca.uhn.fhir.rest.param.TokenParam;
import ca.uhn.fhir.rest.server.exceptions.UnprocessableEntityException;
import ca.uhn.fhir.jpa.starter.services.KeycloakResourceService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.hl7.fhir.instance.model.api.IBaseResource;
import org.hl7.fhir.r5.model.Patient;
import org.hl7.fhir.r5.model.Condition;
import org.hl7.fhir.r5.model.AllergyIntolerance;
import org.hl7.fhir.r5.model.MedicationStatement;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Base64;

/**
 * Interceptor that registers FHIR resources in Keycloak after creation.
 * This enables instance-level UMA permissions.
 */
@Component
@Interceptor
public class ResourceRegistrationInterceptor {

    private static final Logger log = LoggerFactory.getLogger(ResourceRegistrationInterceptor.class);

    @Autowired
    private KeycloakResourceService keycloakResourceService;

    @Autowired(required = false)
    private IFhirResourceDao<Patient> patientDao;

    /**
     * Hook that fires BEFORE a resource is stored.
     * Validates that a Patient with the same keycloak-uuid doesn't already exist.
     */
    @Hook(Pointcut.STORAGE_PRESTORAGE_RESOURCE_CREATED)
    public void validatePatientUnique(IBaseResource theResource, RequestDetails theRequestDetails) {
        if (theResource == null || !"Patient".equals(theResource.fhirType())) {
            return;
        }

        Patient patient = (Patient) theResource;
        String keycloakId = extractKeycloakIdFromPatient(patient);

        if (keycloakId == null) {
            log.debug("Patient has no keycloak-uuid, skipping uniqueness check");
            return;
        }

        // Check if a Patient with this keycloak-uuid already exists
        Patient existingPatient = findPatientByKeycloakId(keycloakId);
        if (existingPatient != null) {
            String existingId = existingPatient.getIdElement().getIdPart();
            log.warn("Duplicate Patient creation attempt for keycloak-uuid: {}. Existing Patient: {}", 
                    keycloakId, existingId);
            throw new UnprocessableEntityException(
                "A Patient resource already exists for this Keycloak user. Existing Patient ID: " + existingId);
        }

        log.info("Patient uniqueness validated for keycloak-uuid: {}", keycloakId);
    }

    /**
     * Find a Patient by their keycloak-uuid identifier.
     */
    private Patient findPatientByKeycloakId(String keycloakId) {
        if (patientDao == null) {
            log.warn("Patient DAO not available, cannot check for existing patient");
            return null;
        }

        try {
            SearchParameterMap searchParams = new SearchParameterMap();
            searchParams.add(Patient.SP_IDENTIFIER, new TokenParam("keycloak-uuid", keycloakId));
            
            IBundleProvider results = patientDao.search(searchParams, null);
            if (results != null && !results.isEmpty()) {
                return (Patient) results.getResources(0, 1).get(0);
            }
        } catch (Exception e) {
            log.error("Error searching for existing Patient with keycloak-uuid {}: {}", keycloakId, e.getMessage());
        }
        return null;
    }

    /**
     * Hook that fires after a resource is created.
     * Registers the resource in Keycloak Authorization Services.
     */
    @Hook(Pointcut.STORAGE_PRECOMMIT_RESOURCE_CREATED)
    public void resourceCreated(IBaseResource theResource, RequestDetails theRequestDetails) {
        if (theResource == null) {
            return;
        }

        String resourceType = theResource.fhirType();
        String resourceId = theResource.getIdElement().getIdPart();

        // Only handle resources we care about
        if (!shouldRegisterResource(resourceType)) {
            log.debug("Skipping Keycloak registration for resource type: {}", resourceType);
            return;
        }

        log.info("Resource created: {}/{}", resourceType, resourceId);

        // Extract creator from token
        String creatorId = extractUserIdFromToken(theRequestDetails);
        if (creatorId == null) {
            log.warn("Could not extract creator ID from token for {}/{}", resourceType, resourceId);
            creatorId = keycloakResourceService.getSystemOwnerId();
        }

        // Determine owner based on resource type
        String ownerId = determineOwnerId(theResource, creatorId);

        log.info("Registering {}/{} in Keycloak - Owner: {}, Creator: {}",
                resourceType, resourceId, ownerId, creatorId);

        // Register resource in Keycloak
        keycloakResourceService.registerResource(resourceType, resourceId, ownerId);

        // Grant creator permissions if different from owner
        if (!creatorId.equals(ownerId)) {
            keycloakResourceService.grantCreatorPermissions(resourceType, resourceId, creatorId, ownerId);
        }
    }

    private boolean shouldRegisterResource(String resourceType) {
        switch (resourceType) {
            case "Patient":
            case "Condition":
            case "AllergyIntolerance":
            case "MedicationStatement":
                return true;
            default:
                return false;
        }
    }

    /**
     * Determine the owner of a resource.
     * - For Patient: the patient themselves (if linked to Keycloak) or system-owner
     * - For clinical resources: the subject patient (owner of the patient record)
     */
    private String determineOwnerId(IBaseResource theResource, String creatorId) {
        String resourceType = theResource.fhirType();

        if ("Patient".equals(resourceType)) {
            // For Patient resources, check if patient has Keycloak link
            Patient patient = (Patient) theResource;
            String keycloakId = extractKeycloakIdFromPatient(patient);
            if (keycloakId != null) {
                log.info("Patient linked to Keycloak user: {}", keycloakId);
                return keycloakId;
            }
            // Patient not linked - use system owner
            log.info("Patient not linked to Keycloak, using system owner");
            return keycloakResourceService.getSystemOwnerId();
        }

        // For clinical resources (Condition, AllergyIntolerance, etc.)
        // The owner is the patient's Keycloak ID
        String patientRef = extractPatientReference(theResource);
        if (patientRef != null) {
            log.info("Clinical resource references patient: {}", patientRef);
            
            // Extract patient ID from reference (e.g., "Patient/452" -> "452")
            String patientId = patientRef.contains("/") 
                ? patientRef.substring(patientRef.lastIndexOf("/") + 1)
                : patientRef;
            
            // Look up the patient's Keycloak ID
            String patientKeycloakId = keycloakResourceService.getPatientKeycloakId(patientId);
            if (patientKeycloakId != null) {
                log.info("Found patient's Keycloak ID: {}", patientKeycloakId);
                return patientKeycloakId;
            }
            log.warn("Could not find Keycloak ID for patient: {}", patientRef);
        }

        // Default to creator ID for clinical resources without patient link
        log.info("Using creator as owner for clinical resource");
        return creatorId;
    }

    /**
     * Extract Keycloak user ID from Patient resource identifier.
     * Expects an identifier with system "keycloak-uuid".
     */
    private String extractKeycloakIdFromPatient(Patient patient) {
        if (patient.getIdentifier() == null) {
            return null;
        }

        for (var identifier : patient.getIdentifier()) {
            if ("keycloak-uuid".equals(identifier.getSystem())) {
                return identifier.getValue();
            }
        }

        return null;
    }

    /**
     * Extract patient reference from clinical resources.
     */
    private String extractPatientReference(IBaseResource theResource) {
        try {
            if (theResource instanceof Condition) {
                Condition condition = (Condition) theResource;
                if (condition.getSubject() != null) {
                    return condition.getSubject().getReference();
                }
            } else if (theResource instanceof AllergyIntolerance) {
                AllergyIntolerance allergy = (AllergyIntolerance) theResource;
                if (allergy.getPatient() != null) {
                    return allergy.getPatient().getReference();
                }
            } else if (theResource instanceof MedicationStatement) {
                MedicationStatement med = (MedicationStatement) theResource;
                if (med.getSubject() != null) {
                    return med.getSubject().getReference();
                }
            }
        } catch (Exception e) {
            log.warn("Error extracting patient reference", e);
        }
        return null;
    }

    /**
     * Extract user ID (sub claim) from JWT token.
     */
    private String extractUserIdFromToken(RequestDetails theRequestDetails) {
        String authHeader = theRequestDetails.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return null;
        }

        String token = authHeader.substring(7);

        try {
            // JWT: header.payload.signature
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                return null;
            }

            // Decode payload
            String payload = new String(Base64.getUrlDecoder().decode(parts[1]));
            ObjectMapper mapper = new ObjectMapper();
            JsonNode payloadJson = mapper.readTree(payload);

            if (payloadJson.has("sub")) {
                return payloadJson.get("sub").asText();
            }
        } catch (Exception e) {
            log.error("Error extracting user ID from token", e);
        }

        return null;
    }
}
