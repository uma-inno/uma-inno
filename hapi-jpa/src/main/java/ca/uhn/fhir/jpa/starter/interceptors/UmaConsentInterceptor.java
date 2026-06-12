package ca.uhn.fhir.jpa.starter.interceptors;

import ca.uhn.fhir.jpa.starter.services.UmaBlacklistService;
import ca.uhn.fhir.rest.server.interceptor.consent.ConsentInterceptor;
import org.springframework.stereotype.Component;

/**
 * Registriert den UmaConsentService als HAPI ConsentInterceptor
 * (Eintrag in application.yaml unter custom-interceptor-classes).
 */
@Component
public class UmaConsentInterceptor extends ConsentInterceptor {

    public UmaConsentInterceptor(UmaBlacklistService blacklistService) {
        super(new UmaConsentService(blacklistService));
    }
}
