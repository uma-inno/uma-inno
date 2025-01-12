package ca.uhn.example.servlet;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

import ca.uhn.example.provider.OrganizationResourceProvider;
import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.narrative.DefaultThymeleafNarrativeGenerator;
import ca.uhn.fhir.narrative.INarrativeGenerator;
import ca.uhn.fhir.rest.server.IResourceProvider;
import ca.uhn.fhir.rest.server.RestfulServer;
import ca.uhn.fhir.rest.server.interceptor.ResponseHighlighterInterceptor;

/**
 * This servlet is the actual FHIR server itself
 */
public class ExampleRestfulServlet extends RestfulServer {

	public static void main(String[] args) {
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
	}
}