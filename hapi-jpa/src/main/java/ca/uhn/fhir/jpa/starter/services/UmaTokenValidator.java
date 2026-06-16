package ca.uhn.fhir.jpa.starter.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.RSAPublicKeySpec;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Stufe 1 des UMA-Enforcements: lokale Validierung von RPTs ohne Introspection-Call.
 * Prueft die RS256-Signatur gegen das JWKS des Realms (Keys werden pro kid gecacht)
 * und die Ablaufzeit (exp). Introspection ist hier keine Option, weil Keycloak fuer
 * RPTs mit iss=localhost "active: false" liefert, wenn der Server intern ueber
 * keycloak:8080 kommuniziert.
 */
@Service
public class UmaTokenValidator {
    private static final Logger log = LoggerFactory.getLogger(UmaTokenValidator.class);

    private static final String JWKS_URL =
        "http://keycloak:8080/realms/FHIR-Auth/protocol/openid-connect/certs";

    private final Map<String, PublicKey> keysByKid = new ConcurrentHashMap<>();
    private final ObjectMapper mapper = new ObjectMapper();

    /**
     * @return true wenn Signatur gueltig und Token nicht abgelaufen ist
     */
    public boolean isValid(String jwt) {
        try {
            String[] parts = jwt.split("\\.");
            if (parts.length != 3) {
                return false;
            }

            JsonNode header = mapper.readTree(Base64.getUrlDecoder().decode(parts[0]));
            String alg = header.path("alg").asText();
            if (!"RS256".equals(alg)) {
                log.warn("Token rejected: unsupported algorithm '{}'", alg);
                return false;
            }

            String kid = header.path("kid").asText();
            PublicKey key = keysByKid.get(kid);
            if (key == null) {
                refreshKeys();
                key = keysByKid.get(kid);
            }
            if (key == null) {
                log.warn("Token rejected: no JWKS key for kid '{}'", kid);
                return false;
            }

            Signature verifier = Signature.getInstance("SHA256withRSA");
            verifier.initVerify(key);
            verifier.update((parts[0] + "." + parts[1]).getBytes(StandardCharsets.US_ASCII));
            if (!verifier.verify(Base64.getUrlDecoder().decode(parts[2]))) {
                log.warn("Token rejected: invalid signature");
                return false;
            }

            JsonNode payload = mapper.readTree(Base64.getUrlDecoder().decode(parts[1]));
            long exp = payload.path("exp").asLong(0);
            if (exp > 0 && exp < System.currentTimeMillis() / 1000) {
                log.warn("Token rejected: expired at {}", exp);
                return false;
            }

            return true;
        } catch (Exception e) {
            log.warn("Token rejected: validation error: {}", e.getMessage());
            return false;
        }
    }

    private synchronized void refreshKeys() {
        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpGet get = new HttpGet(JWKS_URL);
            try (CloseableHttpResponse response = client.execute(get)) {
                if (response.getStatusLine().getStatusCode() != 200) {
                    log.error("JWKS fetch failed with status {}", response.getStatusLine().getStatusCode());
                    return;
                }
                JsonNode jwks = mapper.readTree(EntityUtils.toString(response.getEntity()));
                KeyFactory factory = KeyFactory.getInstance("RSA");
                for (JsonNode jwk : jwks.path("keys")) {
                    if (!"RSA".equals(jwk.path("kty").asText()) || !"sig".equals(jwk.path("use").asText())) {
                        continue;
                    }
                    BigInteger modulus = new BigInteger(1, Base64.getUrlDecoder().decode(jwk.path("n").asText()));
                    BigInteger exponent = new BigInteger(1, Base64.getUrlDecoder().decode(jwk.path("e").asText()));
                    PublicKey key = factory.generatePublic(new RSAPublicKeySpec(modulus, exponent));
                    keysByKid.put(jwk.path("kid").asText(), key);
                }
                log.info("JWKS refreshed, {} signing key(s) cached", keysByKid.size());
            }
        } catch (Exception e) {
            log.error("Error refreshing JWKS keys", e);
        }
    }
}
