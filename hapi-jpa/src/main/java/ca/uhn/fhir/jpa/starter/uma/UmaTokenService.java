package ca.uhn.fhir.jpa.starter.uma;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;

/**
 * Service to handle UMA token operations
 */
@Service
public class UmaTokenService {

	private static final Logger logger = LoggerFactory.getLogger(UmaTokenService.class);

	// Use Keycloak service name for Docker internal communication (or localhost for local dev)
	private static final String AUTHORIZATION_SERVER_URI = "http://keycloak:8080/realms/FHIR-Auth";
	private static final String TOKEN_URL = AUTHORIZATION_SERVER_URI + "/protocol/openid-connect/token";

	private static final String CLIENT_ID = "fhir-client";
	private static final String CLIENT_SECRET = "QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP";

	/**
	 * Introspects a given token to determine its validity and associated permissions
	 *
	 * @param token The token to introspect
	 * @return Token introspection result
	 */
	public TokenIntrospectionResult introspectToken(String token) {
		// Implementation would validate the token against your authentication system
		// This is a placeholder implementation

		TokenIntrospectionResult result = new TokenIntrospectionResult();

		// In a real implementation, you would check if the token is valid
		// For demonstration, we're considering all tokens valid
		result.setActive(true);
		result.setExpiresAt(System.currentTimeMillis() + 3600 * 1000); // 1 hour from now
		// Set permissions based on token claims
		result.getPermissions().add("read");
		result.getPermissions().add("write");

		return result;
	}

	/**
	 * Issues an RPT (Requesting Party Token) by exchanging a permission ticket with Keycloak
	 *
	 * This implements UMA 2.0 Step 2: Client exchanges permission ticket for RPT
	 * See: https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-federated-authz-2.0.html#uma-grant-type
	 *
	 * @param grantType The grant type for the token request (should be urn:ietf:params:oauth:grant-type:uma-ticket)
	 * @param ticket Permission ticket received from authorization server
	 * @param claimToken Optional claim token for providing claims
	 * @param claimTokenFormat Format of the claim token (e.g., urn:ietf:params:oauth:token-type:jwt)
	 * @param clientId Client ID (uses default if null)
	 * @param clientSecret Client secret (uses default if null)
	 * @return Token result containing the RPT
	 */
	public TokenResult issueToken(
		String grantType,
		String ticket,
		String claimToken,
		String claimTokenFormat,
		String clientId,
		String clientSecret) {

		logger.info("Requesting RPT token from Keycloak with grant_type={}, ticket={}", grantType, ticket != null ? "present" : "null");

		// Use defaults if not provided
		String effectiveClientId = clientId != null ? clientId : CLIENT_ID;
		String effectiveClientSecret = clientSecret != null ? clientSecret : CLIENT_SECRET;

		try (CloseableHttpClient client = HttpClients.createDefault()) {
			HttpPost post = new HttpPost(TOKEN_URL);
			post.setHeader("Content-Type", "application/x-www-form-urlencoded");

			// Build request body for UMA token request
			StringBuilder bodyBuilder = new StringBuilder();
			bodyBuilder.append("grant_type=").append(grantType != null ? grantType : "urn:ietf:params:oauth:grant-type:uma-ticket");
			bodyBuilder.append("&ticket=").append(ticket);
			bodyBuilder.append("&client_id=").append(effectiveClientId);
			bodyBuilder.append("&client_secret=").append(effectiveClientSecret);

			// Add optional claim token if provided
			if (claimToken != null && !claimToken.isEmpty()) {
				bodyBuilder.append("&claim_token=").append(claimToken);
				if (claimTokenFormat != null && !claimTokenFormat.isEmpty()) {
					bodyBuilder.append("&claim_token_format=").append(claimTokenFormat);
				}
			}

			String body = bodyBuilder.toString();
			logger.debug("Sending RPT request to: {}", TOKEN_URL);
			post.setEntity(new StringEntity(body));

			try (CloseableHttpResponse response = client.execute(post)) {
				String responseBody = EntityUtils.toString(response.getEntity());
				int statusCode = response.getStatusLine().getStatusCode();

				logger.debug("RPT token response - Status: {}, Body: {}", statusCode, responseBody);

				if (statusCode == 200) {
					// Parse successful response
					ObjectMapper mapper = new ObjectMapper();
					JsonNode jsonResponse = mapper.readTree(responseBody);

					TokenResult result = new TokenResult();
					result.setAccessToken(jsonResponse.get("access_token").asText());
					result.setExpiresIn(jsonResponse.has("expires_in") ? jsonResponse.get("expires_in").asInt() : 3600);
					result.setUpgraded(jsonResponse.has("upgraded") ? jsonResponse.get("upgraded").asBoolean() : false);

					logger.info("Successfully obtained RPT token, expires_in: {}", result.getExpiresIn());
					return result;
				} else {
					// Handle error response
					logger.error("Failed to obtain RPT token. Status: {}, Response: {}", statusCode, responseBody);

					// Parse error response if available
					String errorMessage = "Failed to obtain RPT token";
					try {
						ObjectMapper mapper = new ObjectMapper();
						JsonNode jsonResponse = mapper.readTree(responseBody);
						if (jsonResponse.has("error")) {
							errorMessage = jsonResponse.get("error").asText();
							if (jsonResponse.has("error_description")) {
								errorMessage += ": " + jsonResponse.get("error_description").asText();
							}
						}
					} catch (Exception e) {
						logger.warn("Could not parse error response", e);
					}

					throw new RuntimeException(errorMessage);
				}
			}
		} catch (IOException e) {
			logger.error("Error requesting RPT token from Keycloak", e);
			throw new RuntimeException("Error communicating with authorization server: " + e.getMessage(), e);
		}
	}
}