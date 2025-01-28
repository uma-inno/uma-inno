package ca.uhn.example.provider;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.parser.IParser;
import ca.uhn.fhir.rest.annotation.IdParam;
import ca.uhn.fhir.rest.annotation.Read;
import ca.uhn.fhir.rest.server.IResourceProvider;
import ca.uhn.fhir.rest.server.exceptions.ResourceNotFoundException;
import org.hl7.fhir.instance.model.api.IBaseOperationOutcome;
import org.hl7.fhir.r5.model.AllergyIntolerance;
import org.hl7.fhir.r5.model.IdType;
import org.hl7.fhir.r5.model.Organization;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Scanner;

public class OrganizationResourceProvider implements IResourceProvider {

   private static final String BASE_URL = "https://server.fire.ly/r5/Organization/";

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
      Organization newOrg;

      String idString = theId.toString();
      String[] split = idString.split("/", 2);


      String res = fetchOrganizationById(split[1]);

      if(res != null) {
         FhirContext ctx = FhirContext.forR5();
         IParser parser = ctx.newJsonParser();
         newOrg = parser.parseResource(Organization.class, res);
         return newOrg;
      } else {
         throw new ResourceNotFoundException(theId);
      }
   }

   /**
    * Fetch resource from the remote HAPI FHIR server
    *
    * @param url The URL to the resource
    * @return The response body as a String
    * @throws IOException If an error occurs during the HTTP request
    */
   public String fetchOrganizationById(String allergyId) {
      // Baue die URL dynamisch
      String url = BASE_URL + allergyId + "?_format=json";

      try {
         // Führe HTTP GET-Anfrage aus (z. B. mit HttpURLConnection oder einem HTTP-Client)
         HttpClient client = HttpClient.newHttpClient();
         HttpRequest request = HttpRequest.newBuilder()
                 .uri(URI.create(url))
                 .GET()
                 .build();
         HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
         return response.body();
      } catch (Exception e) {
         e.printStackTrace();
         return null;
      }
   }
}
