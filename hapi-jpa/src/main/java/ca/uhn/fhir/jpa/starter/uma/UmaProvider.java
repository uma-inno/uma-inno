package ca.uhn.fhir.jpa.starter.uma;

import ca.uhn.fhir.rest.annotation.Operation;
import ca.uhn.fhir.rest.annotation.OperationParam;
import ca.uhn.fhir.rest.api.server.RequestDetails;
import ca.uhn.fhir.rest.server.exceptions.InvalidRequestException;
import ca.uhn.fhir.rest.server.exceptions.AuthenticationException;
import org.hl7.fhir.r4.model.Parameters;
import org.hl7.fhir.r4.model.StringType;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

// Update these imports to jakarta.servlet
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.util.Date;

/**
 * Provider that implements the UMA endpoints required for User-Managed Access control
 * Based on UMA 2.0 specifications: https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-federated-authz-2.0.html
 */
@Component
public class UmaProvider {

	// Autowire any necessary services for authentication, token management, etc.
	@Autowired
	private UmaTokenService tokenService;

	@Autowired
	private UmaAuthenticationService authService;

	/**
	 * RPT Introspection Endpoint
	 * Used by resource servers to verify RPT (Requesting Party Token)
	 */
	@Operation(name = "$introspect", manualRequest = true)
	public Parameters introspectToken(
		HttpServletRequest theServletRequest,
		HttpServletResponse theServletResponse,
		@OperationParam(name = "token") StringType token,
		RequestDetails requestDetails) {

		// Validate the request
		if (token == null || token.isEmpty()) {
			throw new InvalidRequestException("Token is required");
		}

		// Perform token introspection
		TokenIntrospectionResult result = tokenService.introspectToken(token.getValue());

		// Build and return response
		Parameters resp = new Parameters();
		resp.addParameter("active", result.isActive());

		if (result.isActive()) {
			resp.addParameter("exp", String.valueOf(new Date(result.getExpiresAt())));

			// Add permissions if they exist
			if (result.getPermissions() != null && !result.getPermissions().isEmpty()) {
				Parameters.ParametersParameterComponent permissionsParam = resp.addParameter();

				for (String permission : result.getPermissions()) {
					permissionsParam.addPart().setValue(new StringType(permission));
				}
			}
		}

		return resp;
	}

	/**
	 * User Authentication Endpoint
	 * Authenticates users and provides access tokens
	 */
	@Operation(name = "$auth", manualRequest = true)
	public Parameters authenticateUser(
		HttpServletRequest theServletRequest,
		HttpServletResponse theServletResponse,
		@OperationParam(name = "username") StringType username,
		@OperationParam(name = "password") StringType password,
		@OperationParam(name = "client_id") StringType clientId,
		@OperationParam(name = "grant_type") StringType grantType,
		RequestDetails requestDetails) {

		// Validate the request
		if (username == null || password == null || clientId == null || grantType == null) {
			throw new InvalidRequestException("Missing required parameters");
		}

		// Perform authentication
		AuthenticationResult authResult = authService.authenticate(
			username.getValue(),
			password.getValue(),
			clientId.getValue(),
			grantType.getValue());

		if (!authResult.isSuccessful()) {
			throw new AuthenticationException("Authentication failed");
		}

		// Build and return response
		Parameters resp = new Parameters();
		resp.addParameter("access_token", authResult.getAccessToken());
		resp.addParameter("token_type", "Bearer");
		resp.addParameter("expires_in", authResult.getExpiresIn());
		resp.addParameter("refresh_token", authResult.getRefreshToken());

		return resp;
	}

	/**
	 * Token Endpoint
	 * Issues access tokens for UMA-protected resources
	 */
	@Operation(name = "$token", manualRequest = true)
	public Parameters issueToken(
		HttpServletRequest theServletRequest,
		HttpServletResponse theServletResponse,
		@OperationParam(name = "grant_type") StringType grantType,
		@OperationParam(name = "ticket") StringType ticket,
		@OperationParam(name = "claim_token") StringType claimToken,
		@OperationParam(name = "claim_token_format") StringType claimTokenFormat,
		@OperationParam(name = "client_id") StringType clientId,
		@OperationParam(name = "client_secret") StringType clientSecret,
		RequestDetails requestDetails) {

		// Validate the request
		if (grantType == null || ticket == null || clientId == null) {
			throw new InvalidRequestException("Missing required parameters");
		}

		// Process token request
		TokenResult tokenResult = tokenService.issueToken(
			grantType.getValue(),
			ticket.getValue(),
			claimToken != null ? claimToken.getValue() : null,
			claimTokenFormat != null ? claimTokenFormat.getValue() : null,
			clientId.getValue(),
			clientSecret != null ? clientSecret.getValue() : null);

		// Build and return response
		Parameters resp = new Parameters();
		resp.addParameter("access_token", tokenResult.getAccessToken());
		resp.addParameter("token_type", "Bearer");
		resp.addParameter("expires_in", tokenResult.getExpiresIn());
		resp.addParameter("upgraded", tokenResult.isUpgraded());

		return resp;
	}
}