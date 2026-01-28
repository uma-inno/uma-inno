# Project Structure

## Main Working Directory
`uma-inno/hapi-jpa/` - This is the main project directory.

> **Note:** These folders are **old/unused code** - ignore them:
> - `uma-inno/src/`
> - `uma-inno/INNO1_legacy/`
> - `uma-inno/old_scripts/`

---

## Key Directories

| Directory | Description |
|-----------|-------------|
| `hapi-jpa/src/main/java/ca/uhn/fhir/jpa/starter/interceptors/` | Custom interceptors (auth, resource registration) |
| `hapi-jpa/src/main/java/ca/uhn/fhir/jpa/starter/uma/` | UMA token operations & FHIR operations |
| `hapi-jpa/src/main/java/ca/uhn/fhir/jpa/starter/services/` | Keycloak integration service |
| `keycloak-config/keycloak-files/` | Keycloak realm export & config |
| `keycloak-policies/` | Custom Keycloak owner policy (JAR) |

---

## Key Files

### Interceptors
| File | Purpose |
|------|---------|
| `interceptors/UmaKeycloakAuthInterceptor.java` | Validates tokens & enforces UMA permissions |
| `interceptors/ResourceRegistrationInterceptor.java` | Registers FHIR resources in Keycloak |
| `interceptors/JpaEntityTrackingInterceptor.java` | Logging |

### UMA Operations
| File | Purpose |
|------|---------|
| `uma/UmaProvider.java` | Exposes `$introspect`, `$auth`, `$token` operations |
| `uma/UmaTokenService.java` | Token introspection & issuance |

### Services
| File | Purpose |
|------|---------|
| `services/KeycloakResourceService.java` | Creates UMA resources in Keycloak |

### Configuration
| File | Purpose |
|------|---------|
| `src/main/resources/application.yaml` | Main config (DB, Keycloak, interceptors) |
| `docker-compose.yml` | Docker services (Keycloak, HAPI FHIR, PostgreSQL) |

### Keycloak
| File | Purpose |
|------|---------|
| `keycloak-config/keycloak-files/fhir-auth-full.json` | Realm export |
| `keycloak-policies/keycloak-owner-policy.jar` | Owner policy JAR |
