package ca.uhn.example.service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class AllergyService {
    private static final String BASE_URL = "https://hapi.fhir.org/baseR5/AllergyIntolerance/";

    public String fetchAllergyById(int allergyId) {
        // Baue die URL dynamisch
        String url = BASE_URL + allergyId;

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
