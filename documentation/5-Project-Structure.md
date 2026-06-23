# Project Structure

## Main Working Directory
`uma-inno/hapi-jpa/` — the HAPI FHIR server (backend, interceptors, providers).
`uma-inno/frontend/` — the dockerized demo frontend (Node/Express proxy + static UI).
`uma-inno/keycloak-config/` — realm export and the PowerShell setup/seed scripts.

> **Note:** these folders are **old/unused code** — ignore them:
> - `uma-inno/src/`
> - `uma-inno/INNO1_legacy/`
> - `uma-inno/old_scripts/`

---

## Key Directories

| Directory | Description |
|-----------|-------------|
| `hapi-jpa/src/main/java/ca/uhn/fhir/jpa/starter/interceptors/` | UMA enforcement, resource registration, consent filtering, logging |
| `hapi-jpa/src/main/java/ca/uhn/fhir/jpa/starter/services/` | Keycloak integration, local token validation, blacklist |
| `hapi-jpa/src/main/java/ca/uhn/fhir/jpa/starter/providers/` | `$summary` operation provider |
| `hapi-jpa/src/main/java/ca/uhn/fhir/jpa/starter/uma/` | UMA operations (`$introspect`/`$auth`/`$token`) & token services |
| `keycloak-config/keycloak-files/` | Keycloak realm export (import source) |
| `keycloak-config/` | `seed-fhir-data.ps1`, `setup-smart-v2-authz.ps1` |
| `keycloak-policies/` | Custom Keycloak owner policy JAR (legacy / unused — see doc 3) |
| `frontend/` | Demo proxy (`server.js`) + static UI (`public/`) |

---

## Key Files

### Interceptors (`interceptors/`)
| File | Purpose |
|------|---------|
| `UmaKeycloakAuthInterceptor.java` | 4-stage UMA enforcement (JWKS validation, scope check, granular scopes, blacklist) + RBAC on create |
| `ResourceRegistrationInterceptor.java` | Registers Patient resources in Keycloak on create (owner = patient's Keycloak UUID) |
| `UmaConsentInterceptor.java` / `UmaConsentService.java` | Filters search-result bundles via HAPI `IConsentService` |
| `JpaEntityTrackingInterceptor.java` | Logging |

### Services (`services/`)
| File | Purpose |
|------|---------|
| `KeycloakResourceService.java` | Keycloak Admin API: create/register UMA resources |
| `UmaTokenValidator.java` | Stage 1: local RPT validation (RS256 against realm JWKS, `exp`) |
| `UmaBlacklistService.java` | Stage 4: instance blacklist via marker policies (cached admin call, ~30s TTL) |

### Providers (`providers/`)
| File | Purpose |
|------|---------|
| `PatientSummaryProvider.java` | `GET /fhir/Patient/<id>/$summary` → permission-filtered IPS Document Bundle |

### UMA Operations (`uma/`)
| File | Purpose |
|------|---------|
| `UmaProvider.java` | Exposes `$introspect`, `$auth`, `$token` operations |
| `UmaTokenService.java` / `UmaAuthenticationService.java` | Token introspection / issuance / authentication |

### Configuration
| File | Purpose |
|------|---------|
| `src/main/resources/application.yaml` | Main config (DB, custom interceptors/providers, UMA & Keycloak settings) |
| `docker-compose.yml` | Docker services (Keycloak 26.6.3, HAPI FHIR, 2× PostgreSQL, frontend) |

### Keycloak
| File | Purpose |
|------|---------|
| `keycloak-config/keycloak-files/fhir-auth-realm-export.json` | Realm export (import source) |
| `keycloak-policies/keycloak-owner-policy.jar` | Owner policy JAR (legacy / unused) |

### Frontend
| File | Purpose |
|------|---------|
| `frontend/server.js` | Express proxy; holds `client_secret`, runs the UMA dance (`umaFetch`); patient access-management endpoints (`/api/access/*`) |
| `frontend/public/` | Static demo UI (login, patient context toggle, UMA-step display, Zugriffsverwaltung) |
