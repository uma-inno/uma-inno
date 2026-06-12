package ca.uhn.fhir.jpa.starter.providers;

import ca.uhn.fhir.jpa.api.dao.DaoRegistry;
import ca.uhn.fhir.jpa.searchparam.SearchParameterMap;
import ca.uhn.fhir.jpa.starter.services.UmaBlacklistService;
import ca.uhn.fhir.rest.annotation.IdParam;
import ca.uhn.fhir.rest.annotation.Operation;
import ca.uhn.fhir.rest.api.server.IBundleProvider;
import ca.uhn.fhir.rest.api.server.RequestDetails;
import ca.uhn.fhir.rest.param.ReferenceParam;
import ca.uhn.fhir.rest.param.TokenOrListParam;
import ca.uhn.fhir.rest.param.TokenParam;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.hl7.fhir.instance.model.api.IBaseResource;
import org.hl7.fhir.r5.model.Bundle;
import org.hl7.fhir.r5.model.CodeableConcept;
import org.hl7.fhir.r5.model.Coding;
import org.hl7.fhir.r5.model.Composition;
import org.hl7.fhir.r5.model.Enumerations;
import org.hl7.fhir.r5.model.IdType;
import org.hl7.fhir.r5.model.Identifier;
import org.hl7.fhir.r5.model.Patient;
import org.hl7.fhir.r5.model.Reference;
import org.hl7.fhir.r5.model.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Base64;
import java.util.Date;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;

/**
 * $summary-Operation: International Patient Summary (IPS) als Document Bundle.
 *
 * Der UmaKeycloakAuthInterceptor laesst die Operation nur durch, wenn das RPT
 * mindestens einen lesenden patient/*-Scope fuer den Ziel-Patienten enthaelt.
 * Hier passiert dann die Feinarbeit:
 *  - Stufe 2: pro IPS-Section wird der Typ-Scope geprueft — Sections ohne Scope
 *    werden komplett weggelassen
 *  - Stufe 3: granulare Scopes (?category=...) schraenken die Suche der Section ein
 *  - Stufe 4: einzelne Instanzen werden gegen die Blacklist gefiltert
 */
@Component
public class PatientSummaryProvider {
    private static final Logger log = LoggerFactory.getLogger(PatientSummaryProvider.class);

    private static final String LOINC = "http://loinc.org";

    /**
     * IPS-Sections: LOINC-Code -> FHIR-Typ. Weitere IPS-Sections (Immunizations 11369-6,
     * Results 30954-2, Procedures 47519-4, ...) hier ergaenzen, sobald die zugehoerigen
     * Typen UMA-geschuetzt sind und eigene Scopes haben.
     */
    private static final SectionSpec[] SECTIONS = {
        new SectionSpec("Problems", "11450-4", "Condition"),
        new SectionSpec("Allergies and Intolerances", "48765-2", "AllergyIntolerance"),
        new SectionSpec("Medication Summary", "10160-0", "MedicationStatement"),
    };

    @Autowired
    private DaoRegistry daoRegistry;

    @Autowired
    private UmaBlacklistService blacklistService;

    private final ObjectMapper mapper = new ObjectMapper();

    @Operation(name = "$summary", typeName = "Patient", idempotent = true)
    public Bundle patientSummary(@IdParam IdType theId, RequestDetails theRequestDetails) {
        String patientId = theId.getIdPart();
        String rsname = "Patient/" + patientId;

        Set<String> grantedScopes = grantedScopes(theRequestDetails, rsname);
        String userId = extractSubFromToken(theRequestDetails);
        log.info("$summary for {} — granted scopes: {}, user: {}", rsname, grantedScopes, userId);

        Patient patient = (Patient) daoRegistry.getResourceDao("Patient").read(theId, null);

        Composition composition = new Composition();
        composition.setStatus(Enumerations.CompositionStatus.FINAL);
        composition.setType(new CodeableConcept().addCoding(
            new Coding(LOINC, "60591-5", "Patient summary Document")));
        composition.addSubject(new Reference(rsname));
        composition.setDate(new Date());
        composition.setTitle("International Patient Summary");
        composition.addAuthor(new Reference().setDisplay("HAPI FHIR UMA Server"));

        Bundle bundle = new Bundle();
        bundle.setType(Bundle.BundleType.DOCUMENT);
        bundle.setIdentifier(new Identifier()
            .setSystem("urn:ietf:rfc:3986")
            .setValue("urn:uuid:" + UUID.randomUUID()));
        bundle.setTimestamp(new Date());

        String serverBase = theRequestDetails.getFhirServerBase();
        bundle.addEntry().setFullUrl("urn:uuid:" + UUID.randomUUID()).setResource(composition);
        bundle.addEntry().setFullUrl(serverBase + "/" + rsname).setResource(patient);

        for (SectionSpec spec : SECTIONS) {
            // Stufe 2: Typ-Scope der Section pruefen
            ScopeGrant grant = resolveGrant(grantedScopes, spec.resourceType);
            if (grant == null) {
                log.info("$summary: section '{}' omitted (no patient/{} scope)", spec.title, spec.resourceType);
                continue;
            }

            // Stufe 3: granulare Kategorien-Einschraenkung aus dem Scope uebernehmen
            SearchParameterMap params = new SearchParameterMap();
            params.setLoadSynchronous(true);
            params.add("patient", new ReferenceParam(rsname));
            if (!grant.unrestricted && !grant.categories.isEmpty()) {
                TokenOrListParam categories = new TokenOrListParam();
                for (String category : grant.categories) {
                    categories.add(new TokenParam(category));
                }
                params.add("category", categories);
                log.info("$summary: section '{}' restricted to categories {}", spec.title, grant.categories);
            }
            IBundleProvider results = daoRegistry.getResourceDao(spec.resourceType).search(params, null);

            Composition.SectionComponent section = composition.addSection();
            section.setTitle(spec.title);
            section.setCode(new CodeableConcept().addCoding(new Coding(LOINC, spec.loincCode, spec.title)));

            for (IBaseResource resource : results.getAllResources()) {
                String resourceId = resource.getIdElement().getIdPart();
                // Stufe 4: Blacklist-Filterung pro Instanz
                if (blacklistService.isBlacklisted(patientId, spec.resourceType, resourceId, userId)) {
                    log.info("$summary: {}/{} filtered (blacklist)", spec.resourceType, resourceId);
                    continue;
                }
                String relativeId = spec.resourceType + "/" + resourceId;
                section.addEntry(new Reference(relativeId));
                bundle.addEntry().setFullUrl(serverBase + "/" + relativeId).setResource((Resource) resource);
            }

            if (section.getEntry().isEmpty()) {
                section.setEmptyReason(new CodeableConcept().addCoding(new Coding(
                    "http://terminology.hl7.org/CodeSystem/list-empty-reason", "unavailable", "Unavailable")));
            }
        }

        return bundle;
    }

    /**
     * Liefert den Grant fuer einen Ressourcentyp oder null, wenn kein lesender Scope
     * vorhanden ist. Sammelt dabei granulare Kategorien-Filter aus den Scopes.
     */
    private ScopeGrant resolveGrant(Set<String> grantedScopes, String resourceType) {
        String prefix = "patient/" + resourceType + ".";
        ScopeGrant grant = null;
        for (String granted : grantedScopes) {
            int filterIdx = granted.indexOf('?');
            String base = filterIdx < 0 ? granted : granted.substring(0, filterIdx);
            if (!base.startsWith(prefix) || base.substring(prefix.length()).indexOf('r') < 0) {
                continue;
            }
            if (grant == null) {
                grant = new ScopeGrant();
            }
            if (filterIdx < 0) {
                grant.unrestricted = true;
            } else {
                for (String filter : granted.substring(filterIdx + 1).split("&")) {
                    String[] kv = filter.split("=", 2);
                    if (kv.length == 2 && "category".equals(kv[0])) {
                        grant.categories.add(kv[1]);
                    }
                }
            }
        }
        return grant;
    }

    private Set<String> grantedScopes(RequestDetails theRequestDetails, String rsname) {
        Set<String> scopes = new LinkedHashSet<>();
        try {
            String authHeader = theRequestDetails.getHeader("Authorization");
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return scopes;
            }
            String[] parts = authHeader.substring(7).split("\\.");
            if (parts.length != 3) {
                return scopes;
            }
            // Signatur wurde bereits in Stufe 1 (UmaTokenValidator) geprueft
            JsonNode payload = mapper.readTree(Base64.getUrlDecoder().decode(parts[1]));
            for (JsonNode permission : payload.path("authorization").path("permissions")) {
                if (!rsname.equals(permission.path("rsname").asText())) {
                    continue;
                }
                for (JsonNode scope : permission.path("scopes")) {
                    scopes.add(scope.asText());
                }
            }
        } catch (Exception e) {
            log.warn("Could not extract scopes from token: {}", e.getMessage());
        }
        return scopes;
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
            return mapper.readTree(Base64.getUrlDecoder().decode(parts[1])).path("sub").asText(null);
        } catch (Exception e) {
            return null;
        }
    }

    private static class SectionSpec {
        final String title;
        final String loincCode;
        final String resourceType;

        SectionSpec(String title, String loincCode, String resourceType) {
            this.title = title;
            this.loincCode = loincCode;
            this.resourceType = resourceType;
        }
    }

    private static class ScopeGrant {
        boolean unrestricted = false;
        final Set<String> categories = new LinkedHashSet<>();
    }
}
