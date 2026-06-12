package ca.uhn.fhir.jpa.starter.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Stufe 4 des UMA-Enforcements: Instanz-Filterung ueber Blacklist-Policies.
 *
 * In Keycloak werden Ausschluesse als Marker-Policies mit strikter Naming
 * Convention gepflegt: Blacklist-{PatId}-{ResType}-{ResId}-{DocId}
 * (z.B. Blacklist-1-Condition-7-97503f80-...).
 *
 * Pro Cache-Intervall ist nur EIN Keycloak-Call noetig: alle Blacklist-Policies
 * werden per Admin API geladen, die Pruefung einzelner Ressourcen erfolgt lokal
 * gegen das gecachte Set.
 */
@Service
public class UmaBlacklistService {
    private static final Logger log = LoggerFactory.getLogger(UmaBlacklistService.class);

    private static final String ADMIN_BASE = "http://keycloak:8080/admin/realms/FHIR-Auth";
    private static final String MASTER_TOKEN_URL = "http://keycloak:8080/realms/master/protocol/openid-connect/token";
    private static final String CLIENT_ID = "fhir-client";
    private static final long CACHE_TTL_MS = 30_000;

    private final ObjectMapper mapper = new ObjectMapper();

    private volatile Set<String> blacklist = Collections.emptySet();
    private volatile long loadedAt = 0;
    private volatile String clientUuid;

    public boolean isBlacklisted(String patientId, String resourceType, String resourceId, String userId) {
        if (patientId == null || resourceType == null || resourceId == null || userId == null) {
            return false;
        }
        String key = "Blacklist-" + patientId + "-" + resourceType + "-" + resourceId + "-" + userId;
        boolean denied = currentBlacklist().contains(key);
        if (denied) {
            log.info("Blacklist DENY: {}", key);
        }
        return denied;
    }

    private Set<String> currentBlacklist() {
        if (System.currentTimeMillis() - loadedAt > CACHE_TTL_MS) {
            reload();
        }
        return blacklist;
    }

    private synchronized void reload() {
        if (System.currentTimeMillis() - loadedAt <= CACHE_TTL_MS) {
            return; // anderer Thread hat bereits aktualisiert
        }
        try {
            String adminToken = getAdminToken();
            if (adminToken == null) {
                log.error("Blacklist reload skipped: no admin token");
                return;
            }
            if (clientUuid == null) {
                clientUuid = lookupClientUuid(adminToken);
            }

            // Ein Call: Keycloak filtert per name-LIKE auf "Blacklist-"
            String url = ADMIN_BASE + "/clients/" + clientUuid
                + "/authz/resource-server/policy?name=Blacklist-&first=0&max=500";
            try (CloseableHttpClient client = HttpClients.createDefault()) {
                HttpGet get = new HttpGet(url);
                get.setHeader("Authorization", "Bearer " + adminToken);
                try (CloseableHttpResponse response = client.execute(get)) {
                    String body = EntityUtils.toString(response.getEntity());
                    if (response.getStatusLine().getStatusCode() != 200) {
                        log.error("Blacklist reload failed with status {}", response.getStatusLine().getStatusCode());
                        return;
                    }
                    Set<String> names = new HashSet<>();
                    for (JsonNode policy : mapper.readTree(body)) {
                        String name = policy.path("name").asText();
                        if (name.startsWith("Blacklist-")) {
                            names.add(name);
                        }
                    }
                    blacklist = names;
                    loadedAt = System.currentTimeMillis();
                    log.info("Blacklist reloaded: {} entries", names.size());
                }
            }
        } catch (Exception e) {
            // alten Cache behalten, damit ein Keycloak-Ausfall nicht alles freischaltet/sperrt
            log.error("Error reloading blacklist", e);
        }
    }

    private String lookupClientUuid(String adminToken) throws Exception {
        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpGet get = new HttpGet(ADMIN_BASE + "/clients?clientId=" + CLIENT_ID);
            get.setHeader("Authorization", "Bearer " + adminToken);
            try (CloseableHttpResponse response = client.execute(get)) {
                String body = EntityUtils.toString(response.getEntity());
                return mapper.readTree(body).get(0).get("id").asText();
            }
        }
    }

    private String getAdminToken() {
        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpPost post = new HttpPost(MASTER_TOKEN_URL);
            post.setHeader("Content-Type", "application/x-www-form-urlencoded");
            post.setEntity(new StringEntity(
                "grant_type=password&client_id=admin-cli&username=admin&password=admin"));
            try (CloseableHttpResponse response = client.execute(post)) {
                String body = EntityUtils.toString(response.getEntity());
                if (response.getStatusLine().getStatusCode() == 200) {
                    return mapper.readTree(body).get("access_token").asText();
                }
            }
        } catch (Exception e) {
            log.error("Error getting admin token for blacklist reload", e);
        }
        return null;
    }
}
