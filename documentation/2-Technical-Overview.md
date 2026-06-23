# 2. Technical Overview

## System Components

```
┌──────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Demo Frontend│    │   HAPI FHIR     │    │    Keycloak     │    │   PostgreSQL    │
│ proxy :3000  │◄──►│   Server :8081  │◄──►│  Authorization  │    │   (2 DBs)       │
│ (UMA dance)  │    │ (Resource Srv)  │    │     :8080       │    │  :5432 / :5433  │
└──────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

| Component | Purpose |
|-----------|---------|
| **Demo Frontend** | Node/Express proxy + static UI; holds the `client_secret` and runs the UMA dance server-side; bietet die patientengesteuerte Zugriffsverwaltung |
| **HAPI FHIR Server** | FHIR R5 REST API with UMA protection (resource server) |
| **Keycloak** | UMA 2.0 Authorization Server (realm `FHIR-Auth`, tokens, policies); pinned to **26.6.3** |
| **PostgreSQL** | Separate databases for FHIR resources and Keycloak |

---

## UMA 2.0 Flow

UMA (User-Managed Access) enables patients to control who accesses their data. The flow is
performed server-side by the frontend proxy, but any client can drive it directly.

```
Client                    FHIR Server                 Keycloak
  │                            │                          │
  │  1. GET /Patient/1 (access token)                     │
  ├───────────────────────────►│   request permission     │
  │                            │   ticket (Protection API)│
  │                            ├─────────────────────────►│
  │  401 + WWW-Authenticate    │◄─────────────────────────┤
  │     (UMA …, ticket="…")    │                          │
  │◄───────────────────────────┤                          │
  │                            │                          │
  │  2. Exchange ticket + access token for RPT            │
  ├──────────────────────────────────────────────────────►│  (evaluate policies)
  │  RPT (authorization.permissions: rsname + scopes)     │
  │◄──────────────────────────────────────────────────────┤
  │                            │                          │
  │  3. GET /Patient/1 + RPT   │  validate locally        │
  ├───────────────────────────►│  (JWKS signature + scope)│
  │  200 OK + Patient data     │                          │
  │◄───────────────────────────┤                          │
```

Token roles:
- **Access token** = "who are you?" (identity + realm roles, no resource rights)
- **Permission ticket** = "what do you want to access?" (resource reference, no scopes)
- **RPT** = "what may you access?" (`authorization.permissions` with `rsname` + SMART-v2 scopes)
- **Keycloak decides, HAPI only verifies** — locally via JWKS, **no introspection call** (see below)

---

## Core Java Components

```
ca.uhn.fhir.jpa.starter/
├── interceptors/
│   ├── UmaKeycloakAuthInterceptor.java     # 4-stage UMA enforcement + RBAC on create
│   ├── ResourceRegistrationInterceptor.java# registers Patient resources in Keycloak on create
│   ├── UmaConsentInterceptor.java          # filters search-result bundles (IConsentService)
│   ├── UmaConsentService.java              # consent/blacklist filtering logic
│   └── JpaEntityTrackingInterceptor.java   # logging
├── services/
│   ├── KeycloakResourceService.java        # Keycloak Admin API integration (register resources)
│   ├── UmaTokenValidator.java              # stage 1: local JWKS RPT validation
│   └── UmaBlacklistService.java            # stage 4: instance blacklist (cached admin call)
├── providers/
│   └── PatientSummaryProvider.java         # $summary → IPS Document Bundle (permission-filtered)
└── uma/
    ├── UmaProvider.java                     # $introspect / $auth / $token operations
    ├── UmaTokenService.java
    └── UmaAuthenticationService.java
```

### UmaKeycloakAuthInterceptor — 4-stage enforcement

Hooks `SERVER_INCOMING_REQUEST_PRE_HANDLED` and protects `Patient`, `Condition`,
`AllergyIntolerance`, `MedicationStatement`. Each request is resolved to its **subject patient**
(Patient by URL id; clinical resources by the `patient=`/`subject=` search param or the instance's
`subject`); the UMA resource is always `Patient/<id>`.

```
Request arrives
    │
    ├─► Public endpoint (/fhir/metadata, /actuator/health, /.well-known, static)? → allow
    │
    ├─► Resource type not protected? → allow
    │
    ├─► POST (create)? → role-based check (Patient cannot create; Doctor can create
    │                     Patient + clinical; otherwise denied) → allow/deny
    │
    └─► Read/search/update/delete on a protected resource:
            ├─ No token / plain access token → request permission ticket → 401 + WWW-Authenticate
            └─ RPT present:
                 Stage 1  local JWKS validation (UmaTokenValidator): RS256 signature + exp
                 Stage 2  scope check (scopeCovers, SMART-v2 semantics)
                 Stage 3  granular ?category= scopes (search narrowing / 403 on mismatch)
                 Stage 4  instance blacklist check (UmaBlacklistService)
```

Required scope by HTTP method (stage 2): `GET` instance → `.r`, search → `.rs`, `PUT` → `.u`,
`DELETE` → `.d`, `POST` → `.c`. The `$summary` operation is allowed with any read scope on the
target patient; section filtering happens in `PatientSummaryProvider`.

> **Why local validation, not introspection?** Keycloak returned `active: false` when
> introspecting RPTs whose `iss` is `localhost` while the server talks to it internally via
> `keycloak:8080`. `UmaTokenValidator` therefore verifies the RS256 signature against the realm
> JWKS (keys cached per `kid`) and checks `exp` — no introspection round-trip.

### ResourceRegistrationInterceptor

Registers resources in Keycloak when created:

1. Validates Patient uniqueness by `keycloak-uuid` identifier (`STORAGE_PRESTORAGE_RESOURCE_CREATED`).
2. On create (`STORAGE_PRECOMMIT_RESOURCE_CREATED`), registers **only Patient** resources as UMA
   resources owned by the patient's Keycloak UUID. Clinical resources are authorized via their
   patient's permissions.
3. **No creator permissions are granted** — third-party access is given exclusively through the
   patient-controlled trust-list permissions (`grantCreatorPermissions` was removed).

> **Patientengesteuerte Freigabe:** Trust-List, Scopes und Blacklist werden **nicht** mehr
> vorgeseedet, sondern vom Patienten zur Laufzeit über das Frontend verwaltet
> (`/api/access/*` im Proxy → Keycloak-Permissions/Marker-Policies). Siehe
> [3-Keycloak-Configuration.md](3-Keycloak-Configuration.md#patientengesteuerte-freigabe-frontend).

---

## Resource Ownership

| Resource Type | Owner Determined By |
|--------------|---------------------|
| Patient | `keycloak-uuid` identifier in the Patient resource (resolved to the Keycloak user UUID) |
| Condition, AllergyIntolerance, MedicationStatement | the referenced patient's Keycloak UUID |

Ownership is expressed via Keycloak **user policies** (`UserPolicy-Alice`,
`UserPolicy-Owner-bernd`, `UserPolicy-Owner-clara`, …) attached to the per-patient Owner-Full
scope permission. (An earlier JavaScript "Owner Policy" provider JAR is still mounted in Compose
but is **not used** by the current realm.)

---

## JWT Token Structure

### Access Token
Standard Keycloak token with user info and realm roles (`realm_access.roles`).

### RPT (Requesting Party Token)
Contains the granted permissions; scopes use SMART-v2 syntax:

```json
{
  "sub": "5441cea9-...",
  "authorization": {
    "permissions": [
      {
        "rsname": "Patient/1",
        "scopes": ["patient/Patient.r"]
      }
    ]
  }
}
```

The FHIR server extracts `authorization.permissions` and checks that the requested resource
(`rsname`) and a covering scope are present.

---

## Role-Based Access Control (create)

| Role | Can Create | Can Read | Can Delete |
|------|-----------|----------|------------|
| Patient | No | Own data only (via UMA) | No |
| Doctor | Patient, Condition, AllergyIntolerance, MedicationStatement | Granted resources (via UMA) | No |
| Administrator | All | All | All |

Read/update/delete are governed by the UMA scope check, not by role alone. Welche Ärzte welche
Daten lesen dürfen, gibt der jeweilige Patient zur Laufzeit über das Frontend frei.

---

## Key Implementation Details

### SMART on FHIR v2 scope semantics (`scopeCovers`)
A granted scope covers a required scope only when context and resource type match **and** the
granted interaction set contains every required interaction:
- ✅ `patient/Patient.rs` covers `patient/Patient.r`
- ❌ `patient/Condition.rs` does **not** cover `patient/Patient.r` (type mismatch)

### Instance-Level Matching
Permission validation requires an exact resource-name match:
- ✅ `Patient/1` permission → can access `Patient/1`
- ❌ permission on a different `Patient/<id>` → cannot access `Patient/1`

### Permission Ticket Request
The interceptor requests the ticket from Keycloak's Protection API
(`/authz/protection/permission`) using the resource UUID and **no** scopes — Keycloak then
includes every scope the user is entitled to. The 401 carries
`WWW-Authenticate: UMA realm="FHIR-Auth", as_uri="…", ticket="…"`.
