package ca.uhn.fhir.jpa.starter.interceptors;

import ca.uhn.fhir.jpa.starter.services.UmaBlacklistService;
import ca.uhn.fhir.rest.api.server.RequestDetails;
import ca.uhn.fhir.rest.server.interceptor.consent.ConsentOutcome;
import ca.uhn.fhir.rest.server.interceptor.consent.IConsentContextServices;
import ca.uhn.fhir.rest.server.interceptor.consent.IConsentService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.hl7.fhir.instance.model.api.IBaseResource;
import org.hl7.fhir.r5.model.AllergyIntolerance;
import org.hl7.fhir.r5.model.Condition;
import org.hl7.fhir.r5.model.MedicationStatement;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Base64;

/**
 * Stufe 4 fuer Suchergebnisse: einzelne klinische Ressourcen, die fuer den
 * anfragenden Benutzer auf der Blacklist stehen, werden aus Response-Bundles
 * herausgefiltert (canSeeResource -> REJECT). Instanz-Reads blockiert bereits
 * der UmaKeycloakAuthInterceptor mit 403; dies hier ist die zweite Verteidigungslinie
 * und greift insbesondere bei Searches wie GET /fhir/Condition?patient=1.
 */
public class UmaConsentService implements IConsentService {
    private static final Logger log = LoggerFactory.getLogger(UmaConsentService.class);

    private final UmaBlacklistService blacklistService;
    private final ObjectMapper mapper = new ObjectMapper();

    public UmaConsentService(UmaBlacklistService blacklistService) {
        this.blacklistService = blacklistService;
    }

    @Override
    public ConsentOutcome canSeeResource(RequestDetails theRequestDetails, IBaseResource theResource,
                                         IConsentContextServices theContextServices) {
        String resourceType = theResource.fhirType();
        String patientId = extractPatientId(theResource);
        if (patientId == null) {
            return ConsentOutcome.PROCEED; // keine klinische Ressource mit Patientenbezug
        }

        String userId = extractSubFromToken(theRequestDetails);
        String resourceId = theResource.getIdElement().getIdPart();

        if (blacklistService.isBlacklisted(patientId, resourceType, resourceId, userId)) {
            log.info("Filtering blacklisted {}/{} for user {}", resourceType, resourceId, userId);
            return ConsentOutcome.REJECT;
        }
        return ConsentOutcome.PROCEED;
    }

    private String extractPatientId(IBaseResource theResource) {
        String reference = null;
        if (theResource instanceof Condition) {
            reference = ((Condition) theResource).getSubject().getReference();
        } else if (theResource instanceof AllergyIntolerance) {
            reference = ((AllergyIntolerance) theResource).getPatient().getReference();
        } else if (theResource instanceof MedicationStatement) {
            reference = ((MedicationStatement) theResource).getSubject().getReference();
        }
        if (reference != null && reference.startsWith("Patient/")) {
            return reference.substring("Patient/".length());
        }
        return null;
    }

    private String extractSubFromToken(RequestDetails theRequestDetails) {
        try {
            String authHeader = theRequestDetails.getHeader("Authorization");
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return null;
            }
            String[] parts = authHeader.substring(7).split("\\.");
            if (parts.length != 3) {
                return null;
            }
            // Signatur wurde bereits in Stufe 1 (UmaTokenValidator) geprueft
            return mapper.readTree(Base64.getUrlDecoder().decode(parts[1])).path("sub").asText(null);
        } catch (Exception e) {
            return null;
        }
    }
}
