package ca.uhn.example.servlet;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;


import ca.uhn.example.provider.AllergyJsonParser;

import ca.uhn.example.interceptor.KeycloakAuthInterceptor;
import ca.uhn.example.provider.OrganizationResourceProvider;
import ca.uhn.example.provider.PatientJsonParser;
import ca.uhn.example.provider.PatientResourceProvider;
<<<<<<< HEAD
import ca.uhn.example.service.AllergyService;
=======
>>>>>>> origin/feature/UMA-37-Abfrage-von-Patienten-als-Ressource

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.narrative.DefaultThymeleafNarrativeGenerator;
import ca.uhn.fhir.narrative.INarrativeGenerator;
import ca.uhn.fhir.rest.server.IResourceProvider;
import ca.uhn.fhir.rest.server.RestfulServer;
import ca.uhn.fhir.rest.server.interceptor.ResponseHighlighterInterceptor;

import ca.uhn.example.service.PatientService;

private static final long serialVersionUID = 1L;

/**
 * This servlet is the actual FHIR server itself
 */



public class ExampleRestfulServlet extends RestfulServer {
  
  
  /**
	 * Constructor
	 */
	public ExampleRestfulServlet() {
		super(FhirContext.forR5Cached()); // This is an R5 server
	}

	public static void fetchAllergyById(String[] args) {
		AllergyService allergyService = new AllergyService();

		// Allergy-ID dynamisch eingeben
		String allergyId;
		if (args.length > 0) {
			// Verwende die Allergy-ID aus den Programargumenten
			allergyId = args[0];
		} else {
			// Frage die Allergy-ID über die Konsole ab
			Scanner scanner = new Scanner(System.in);
			System.out.print("Bitte geben Sie die Allergy-ID ein: ");
			allergyId = scanner.nextLine();
			scanner.close();
		}

		// Teste den Aufruf mit der angegebenen Allergy-ID
		String response = allergyService.fetchAllergyById(allergyId);

		System.out.println("FHIR Allergy Data:");
		AllergyJsonParser.parseAllergyData(response);
  }

	public static void main(String[] args) {
		fetchPatientWithID(args);
    fetchOrganizationByID(args);
    fetchAllergyById(args);
	}

	public static void fetchPatientWithID(String[] args) {
		PatientService patientService = new PatientService();

		// Patient-ID dynamisch eingeben
		String patientId;
		if (args.length > 0) {
			// Verwende die Patient-ID aus den Programargumenten
			patientId = args[0];
		} else {
			// Frage die Patient-ID über die Konsole ab
			Scanner scanner = new Scanner(System.in);
			System.out.print("Bitte geben Sie die Patient-ID ein: ");
			patientId = scanner.nextLine();
			scanner.close();
		}

		// Teste den Aufruf mit der angegebenen Patient-ID
		try {
    		String response = patientService.fetchPatientById(patientId);

			System.out.println("FHIR Patient Data:");
			PatientJsonParser.parsePatientData(response);
			System.out.println("DEBUG Json File:");
			System.out.println(response);
		} catch (Exception e) {
			System.err.println("An error occurred while fetching or processing the patient data: " + e.getMessage());
			e.printStackTrace(); }
  }


	public static void main(String[] args) {
		fetchPatientWithID(args);
    fetchOrganizationByID(args)
	}

	public static void fetchPatientWithID(String[] args) {
		PatientService patientService = new PatientService();

		// Patient-ID dynamisch eingeben
		String patientId;
		if (args.length > 0) {
			// Verwende die Patient-ID aus den Programargumenten
			patientId = args[0];
		} else {
			// Frage die Patient-ID über die Konsole ab
			Scanner scanner = new Scanner(System.in);
			System.out.print("Bitte geben Sie die Patient-ID ein: ");
			patientId = scanner.nextLine();
			scanner.close();
		}

		// Teste den Aufruf mit der angegebenen Patient-ID
		try {
    		String response = patientService.fetchPatientById(patientId);

			System.out.println("FHIR Patient Data:");
			PatientJsonParser.parsePatientData(response);
			System.out.println("DEBUG Json File:");
			System.out.println(response);
		} catch (Exception e) {
			System.err.println("An error occurred while fetching or processing the patient data: " + e.getMessage());
			e.printStackTrace(); }
  }

	public static void fetchOrganizationByID(String[] args) {
		OrganizationResourceProvider organizationProvider = new OrganizationResourceProvider();

		// Organisation-ID dynamisch eingeben
		String organizationId;
		if (args.length > 0) {
			// Verwende die Organisation-ID aus den Programargumenten
			organizationId = args[0];
		} else {
			// Frage die Organisation-ID über die Konsole ab
			Scanner scanner = new Scanner(System.in);
			System.out.print("Bitte geben Sie die Organisation-ID ein: ");
			organizationId = scanner.nextLine();
			scanner.close();
		}

		// Teste den Aufruf mit der angegebenen Organisation-ID
		try {
			String response = organizationProvider.getResourceById(new org.hl7.fhir.r5.model.IdType(organizationId)).toString();

			System.out.println("FHIR Organization Data:");
			System.out.println(response);
		} catch (Exception e) {
			System.err.println("Fehler beim Abrufen der Organisation: " + e.getMessage());

		}
	}

	

	

	/**
	 * This method is called automatically when the
	 * servlet is initializing.
	 */
	@Override
	public void initialize() {
		/*
		 * Define resource providers, including OrganizationResourceProvider.
		 */
		List<IResourceProvider> providers = new ArrayList<>();
		providers.add(new OrganizationResourceProvider());
		setResourceProviders(providers);

		/*
		 * Use a narrative generator. This is a completely optional step,
		 * but can be useful as it causes HAPI to generate narratives for
		 * resources which don't otherwise have one.
		 */
		INarrativeGenerator narrativeGen = new DefaultThymeleafNarrativeGenerator();
		getFhirContext().setNarrativeGenerator(narrativeGen);

		/*
		 * Use nice coloured HTML when a browser is used to request the content
		 */
		registerInterceptor(new ResponseHighlighterInterceptor());


		/*
		 * Register the Keycloak Authentication Interceptor
		 * This will validate incoming requests using Keycloak
		 */
		registerInterceptor(new KeycloakAuthInterceptor());
	}
}
