package ca.uhn.fhir.jpa.starter.uma;

/**
 * Represents the result of a token issuance operation
 */
public class TokenResult {
	private String accessToken;
	private int expiresIn;
	private boolean upgraded;

	// Getters and setters
	public String getAccessToken() {
		return accessToken;
	}

	public void setAccessToken(String accessToken) {
		this.accessToken = accessToken;
	}

	public int getExpiresIn() {
		return expiresIn;
	}

	public void setExpiresIn(int expiresIn) {
		this.expiresIn = expiresIn;
	}

	public boolean isUpgraded() {
		return upgraded;
	}

	public void setUpgraded(boolean upgraded) {
		this.upgraded = upgraded;
	}
}