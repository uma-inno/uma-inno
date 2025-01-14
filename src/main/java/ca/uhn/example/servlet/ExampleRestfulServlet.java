package ca.uhn.example.servlet;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

import ca.uhn.example.provider.OrganizationResourceProvider;
import ca.uhn.example.provider.PatientJsonParser;
import ca.uhn.example.provider.PatientResourceProvider;
import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.narrative.DefaultThymeleafNarrativeGenerator;
import ca.uhn.fhir.narrative.INarrativeGenerator;
import ca.uhn.fhir.rest.server.IResourceProvider;
import ca.uhn.fhir.rest.server.RestfulServer;
import ca.uhn.fhir.rest.server.interceptor.ResponseHighlighterInterceptor;

import ca.uhn.example.service.PatientService;

/**
 * This servlet is the actual FHIR server itself
 */
public class ExampleRestfulServlet extends RestfulServer {

	public static void main(String[] args) {
		fetchPatientWithID(args);
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
			e.printStackTrace();
		}
	}

	private static final long serialVersionUID = 1L;

	/**
	 * Constructor
	 */
	public ExampleRestfulServlet() {
		super(FhirContext.forR5Cached()); // This is an R5 server
	}
	
	/**
	 * This method is called automatically when the
	 * servlet is initializing.
	 */
	@Override
	public void initialize() {
		/*
		 * Two resource providers are defined. Each one handles a specific
		 * type of resource.
		 */
		List<IResourceProvider> providers = new ArrayList<>();
		providers.add(new PatientResourceProvider());
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
		
	}

}
