package ca.uhn.fhir.jpa.starter.uma;

import java.util.ArrayList;
import java.util.List;

/**
 * Represents the result of a token introspection operation
 */
public class TokenIntrospectionResult {
	private boolean active;
	private long expiresAt;
	private List<String> permissions = new ArrayList<>();

	// Getters and setters
	public boolean isActive() {
		return active;
	}

	public void setActive(boolean active) {
		this.active = active;
	}

	public long getExpiresAt() {
		return expiresAt;
	}

	public void setExpiresAt(long expiresAt) {
		this.expiresAt = expiresAt;
	}

	public List<String> getPermissions() {
		return permissions;
	}

	public void setPermissions(List<String> permissions) {
		this.permissions = permissions;
	}
}