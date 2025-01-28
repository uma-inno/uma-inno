package ca.uhn.example.service;

import ca.uhn.example.provider.PatientResourceProvider;

public class PatientService {

    private final PatientResourceProvider provider;

    public PatientService() {
        this.provider = new PatientResourceProvider();
    }

    public String fetchPatientById(String patientId) {
        return provider.getPatientById(patientId);
    }
}
