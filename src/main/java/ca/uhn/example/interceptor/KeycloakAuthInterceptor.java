package ca.uhn.example.interceptor;

import ca.uhn.fhir.interceptor.api.Hook;
import ca.uhn.fhir.interceptor.api.Pointcut;
import ca.uhn.fhir.rest.api.server.RequestDetails;
import ca.uhn.fhir.rest.server.exceptions.AuthenticationException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

import java.io.IOException;

public class KeycloakAuthInterceptor {

    private static final String INTROSPECTION_URL = "http://localhost:8081/realms/FHIR-Auth/protocol/openid-connect/token/introspect";
    private static final String CLIENT_ID = "fhir-client";
    private static final String CLIENT_SECRET = "QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP";

    @Hook(Pointcut.SERVER_INCOMING_REQUEST_PRE_HANDLED)
    public void handleRequest(RequestDetails theRequestDetails) {
        String authHeader = theRequestDetails.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new AuthenticationException("Authorization header missing or invalid");
        }

        String token = authHeader.substring(7); // "Bearer " entfernen
        if (!isTokenValid(token)) {
            throw new AuthenticationException("Invalid or expired token");
        }
    }

    private boolean isTokenValid(String token) {
        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpPost post = new HttpPost(INTROSPECTION_URL);
            post.setHeader("Content-Type", "application/x-www-form-urlencoded");

            String body = "client_id=" + CLIENT_ID +
                    "&client_secret=" + CLIENT_SECRET +
                    "&token=" + token;

            post.setEntity(new StringEntity(body));

            CloseableHttpResponse response = client.execute(post);
            String responseBody = EntityUtils.toString(response.getEntity());

            ObjectMapper mapper = new ObjectMapper();
            JsonNode jsonNode = mapper.readTree(responseBody);
            return jsonNode.get("active").asBoolean();
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }
}
