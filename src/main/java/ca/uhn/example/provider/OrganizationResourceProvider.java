package ca.uhn.example.provider;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.parser.IParser;
import ca.uhn.fhir.rest.annotation.IdParam;
import ca.uhn.fhir.rest.annotation.Read;
import ca.uhn.fhir.rest.server.IResourceProvider;
import ca.uhn.fhir.rest.server.exceptions.ResourceNotFoundException;
import org.hl7.fhir.instance.model.api.IBaseOperationOutcome;
import org.hl7.fhir.r5.model.IdType;
import org.hl7.fhir.r5.model.Organization;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Scanner;

public class OrganizationResourceProvider implements IResourceProvider {

   private static final String BASE_URL = "https://hapi.fhir.org/baseR5/Organization";

   private final FhirContext fhirContext;

   public OrganizationResourceProvider() {
      this.fhirContext = FhirContext.forR5();
   }

   @Override
   public Class<Organization> getResourceType() {
      return Organization.class;
   }

   /**
    * Fetch an Organization by ID from a remote HAPI FHIR server
    */
   @Read
   public Organization getResourceById(@IdParam IdType theId) {
      String resourceId = theId.getValue();
      String url = BASE_URL + "/" + resourceId;

      try {
         // HTTP GET request to fetch the organization
         String response = fetchResourceFromRemote(url);

         // Parse the JSON response into an Organization resource
         IParser parser = fhirContext.newJsonParser();
         Organization organization = parser.parseResource(Organization.class, response);

         // Add additional logging or transformations if needed
         System.out.println("Fetched Organization: " + organization.getName());
         return organization;

      } catch (IOException e) {
         throw new ResourceNotFoundException("Could not fetch Organization with ID: " + resourceId, (IBaseOperationOutcome) e);
      }
   }

   /**
    * Fetch resource from the remote HAPI FHIR server
    *
    * @param url The URL to the resource
    * @return The response body as a String
    * @throws IOException If an error occurs during the HTTP request
    */
   private String fetchResourceFromRemote(String url) throws IOException {
      HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
      connection.setRequestMethod("GET");
      connection.setRequestProperty("Accept", "application/fhir+json");

      int responseCode = connection.getResponseCode();
      if (responseCode != 200) {
         throw new IOException("Failed to fetch resource. HTTP error code: " + responseCode);
      }

      try (Scanner scanner = new Scanner(connection.getInputStream())) {
         StringBuilder response = new StringBuilder();
         while (scanner.hasNext()) {
            response.append(scanner.nextLine());
         }
         return response.toString();
      }
   }
}
