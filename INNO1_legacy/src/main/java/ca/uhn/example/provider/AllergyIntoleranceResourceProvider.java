package ca.uhn.example.provider;

import ca.uhn.example.service.AllergyService;
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
import org.hl7.fhir.r5.model.Patient;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Deque;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;



public class AllergyIntoleranceResourceProvider implements IResourceProvider {

    private static final String BASE_URL = "https://server.fire.ly/r5/AllergyIntolerance/";

    private long myNextId = 1;


    private final FhirContext fhirContext;


    // Override getResourceType from IResourceProvider
    @Override
    public Class<AllergyIntolerance> getResourceType() {
        return AllergyIntolerance.class;
    }

    public AllergyIntoleranceResourceProvider() { this.fhirContext = FhirContext.forR5(); }

    @Read(version = true)
    public AllergyIntolerance getResourceById(@IdParam IdType theId) {


        AllergyIntolerance newAllergy;

        String idString = theId.toString();
        String[] split = idString.split("/", 2);


        String res = fetchAllergyById(split[1]);

        if(res != null) {
            FhirContext ctx = FhirContext.forR5();
            IParser parser = ctx.newJsonParser();
            newAllergy = parser.parseResource(AllergyIntolerance.class, res);
            return newAllergy;
        } else {
            throw new ResourceNotFoundException(theId);
        }
    }

    public String fetchAllergyById(String allergyId) {
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


