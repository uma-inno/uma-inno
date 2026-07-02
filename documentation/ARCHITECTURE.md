# Technical Reference

Architecture, UMA implementation, Keycloak configuration, API reference and the `$summary`
operation for the UMA-protected FHIR server. For setup and troubleshooting see
[../SETUP.md](../SETUP.md); for the project overview and test users see [../README.md](../README.md).

## Contents

1. [System Components](#1-system-components)
2. [UMA 2.0 Flow](#2-uma-20-flow)
3. [Core Java Components](#3-core-java-components)
4. [Token Structure & Access Control](#4-token-structure--access-control)
5. [Keycloak Configuration](#5-keycloak-configuration)
6. [Patient-Controlled Sharing](#6-patient-controlled-sharing)
7. [API Reference](#7-api-reference)
8. [`$summary` Operation](#8-summary-operation)
9. [Further Reading](#9-further-reading)

---

## 1. System Components

```
┌──────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Demo Frontend│    │   HAPI FHIR     │    │    Keycloak     │    │   PostgreSQL    │
│ proxy :3000  │◄──►│   Server :8081  │◄──►│  Authorization  │    │   (2 DBs)       │
│ (UMA dance)  │    │ (Resource Srv)  │    │     :8080       │    │  :5432 / :5433  │
└──────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

| Component | Purpose |
|-----------|---------|
| **Demo Frontend** | Node/Express proxy + static UI; holds the `client_secret`, runs the UMA dance server-side, and provides the patient-controlled access management |
| **HAPI FHIR Server** | FHIR R5 REST API with UMA protection (resource server) |
| **Keycloak** | UMA 2.0 Authorization Server (realm `FHIR-Auth`, tokens, policies); pinned to **26.6.3** |
| **PostgreSQL** | Separate databases for FHIR resources and Keycloak |

---

## 2. UMA 2.0 Flow

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

## 3. Core Java Components

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

> Trust list, scopes and blacklist are **not** pre-seeded — the patient manages them at runtime
> through the frontend (`/api/access/*` in the proxy → Keycloak permissions / marker policies).
> See [Patient-Controlled Sharing](#6-patient-controlled-sharing).

---

## 4. Token Structure & Access Control

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

### Role-Based Access Control (create)

| Role | Can Create | Can Read | Can Delete |
|------|-----------|----------|------------|
| Patient | No | Own data only (via UMA) | No |
| Doctor | Patient, Condition, AllergyIntolerance, MedicationStatement | Granted resources (via UMA) | No |
| Administrator | All | All | All |

Read/update/delete are governed by the UMA scope check, not by role alone. Which doctors may read
which data is granted by each patient at runtime through the frontend.

### SMART on FHIR v2 scope semantics (`scopeCovers`)
A granted scope covers a required scope only when context and resource type match **and** the
granted interaction set contains every required interaction:
- ✅ `patient/Patient.rs` covers `patient/Patient.r`
- ❌ `patient/Condition.rs` does **not** cover `patient/Patient.r` (type mismatch)

### Instance-level matching
Permission validation requires an exact resource-name match:
- ✅ `Patient/1` permission → can access `Patient/1`
- ❌ permission on a different `Patient/<id>` → cannot access `Patient/1`

### Resource ownership

| Resource Type | Owner Determined By |
|--------------|---------------------|
| Patient | `keycloak-uuid` identifier in the Patient resource (resolved to the Keycloak user UUID) |
| Condition, AllergyIntolerance, MedicationStatement | the referenced patient's Keycloak UUID |

Ownership is expressed via Keycloak **user policies** (`UserPolicy-Alice`,
`UserPolicy-Owner-bernd`, `UserPolicy-Owner-clara`, …) attached to the per-patient Owner-Full
scope permission.

---

## 5. Keycloak Configuration

### Access

- **URL**: http://localhost:8080
- **Admin**: admin / admin
- **Image**: `quay.io/keycloak/keycloak:26.6.3` (pinned — must match the realm export's `keycloakVersion`)
- **Realm**: FHIR-Auth
- **Client**: fhir-client
- **Client Secret**: `QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP`
- **Decision Strategy**: AFFIRMATIVE
- **Default Client Scope**: `uma_protection` (required for the Protection API / ticket exchange)

Test users are listed in [../README.md](../README.md#test-users).

### Roles

| Role | Permissions |
|------|-------------|
| **Patient** | Read own data only (via UMA); cannot create resources |
| **Doctor** | Create Patient/clinical resources; read resources granted via a patient's trust list |
| **Administrator** | Full access to all resources |

### SMART on FHIR v2 authorization scopes

```
patient/Patient.r       patient/Patient.rs
patient/Condition.rs    patient/MedicationStatement.rs    patient/AllergyIntolerance.rs
```

### Authorization resources

All registered at runtime by HAPI (`ResourceRegistrationInterceptor`) when the patients are
seeded. Owner = the patient's Keycloak user; `ownerManagedAccess = false`.

| Resource | Owner |
|----------|-------|
| `Patient/1` | alice |
| `Patient/7` | bernd |
| `Patient/11` | clara |
| `Patient/<id>` | dr.smith (own record) |
| `Patient/<id>` | dr.bob (own record) |

### Policies

| Policy | Type | Description |
|--------|------|-------------|
| `RolePolicy-Doctor` | Role | Users with the Doctor role |
| `UserPolicy-Alice` | User | Alice (owner of Patient/1) |
| `UserPolicy-Owner-bernd` | User | Bernd (owner of Patient/7) |
| `UserPolicy-Owner-clara` | User | Clara (owner of Patient/11) |
| `UserPolicy-Owner-drsmith` / `-drbob` | User | dr.smith / dr.bob (own record) |

> Trust-list policies for doctors are **not** pre-seeded — the patient creates them at runtime
> through the frontend: `TrustList-Patient<id>-<doctor>` (see
> [Patient-Controlled Sharing](#6-patient-controlled-sharing)).

### Permissions (type: scope, AFFIRMATIVE)

Only the Owner-Full permissions are pre-seeded (each patient's self-access):

| Name | Resource | Scopes | Policies |
|------|----------|--------|----------|
| `Permission-Patient1-Alice-Full` | Patient/1 | all 5 | UserPolicy-Alice |
| `Permission-Patient7-Owner-Full` | Patient/7 | all 5 | UserPolicy-Owner-bernd |
| `Permission-Patient11-Owner-Full` | Patient/11 | all 5 | UserPolicy-Owner-clara |
| `Permission-Patient<id>-Owner-Full` | dr.smith / dr.bob | all 5 | UserPolicy-Owner-drsmith / -drbob |

**Doctor grants** are **not** pre-seeded — they appear only when a patient grants them in the
frontend (see [Patient-Controlled Sharing](#6-patient-controlled-sharing)).

**Demo takeaway:** initially **no** doctor has access to a foreign patient (`access_denied`). The
patient grants specifically in the frontend — e.g. alice grants dr.smith "Diagnoses"
(`patient/Condition.rs`) → dr.smith can then read alice's conditions; if alice blocks a single
condition for dr.smith (blacklist), exactly that one drops out of the result. This demonstrates
patient-controlled authorization.

> **Decision Strategy = AFFIRMATIVE (not Unanimous):** several permissions share the same scope;
> with Unanimous, a DENY from an unrelated permission would block access. "Unanimous" only applies
> *within* a single permission (e.g. trust list AND Doctor role).

### Owner Policy JAR (legacy / unused)

`keycloak-policies/keycloak-owner-policy.jar` is mounted into Keycloak via Compose:

```yaml
volumes:
  - ../keycloak-policies/keycloak-owner-policy.jar:/opt/keycloak/providers/keycloak-owner-policy.jar:ro
```

It is a remnant of an earlier script-based owner-policy approach. The **current realm does not use
it** — resource ownership is enforced through the `UserPolicy-*` user policies above. A
script-based policy also breaks realm export (`providerFactory is null`), which is why it was
dropped from the realm. The mount can be removed without affecting the demo.

### Service account roles

The fhir-client service account / admin-cli access needs these realm-management capabilities
(used by HAPI and the scripts to register resources and build permissions):
`view-users`, `manage-users`, `manage-authorization`, `view-realm`. (Configured in the realm
export.)

### Setup methods

- **Auto import (default):** the realm is imported from
  `keycloak-config/keycloak-files/fhir-auth-realm-export.json` on Keycloak startup
  (`--import-realm`). This provides the base realm; the Patient resources and scope permissions
  are created at runtime by `seed-fhir-data.ps1` + `setup-smart-v2-authz.ps1`.
- **Rebuild from a bare realm:** if a realm **without** the authorization config is imported,
  `setup-smart-v2-authz.ps1` builds it idempotently from scratch (patient users bernd/clara,
  SMART-v2 scopes, role/user policies, per-patient scope permissions, `uma_protection` default
  scope, Decision Strategy AFFIRMATIVE). Use `-CleanupLegacy` to remove leftover objects.

See [../SETUP.md](../SETUP.md) for the full sequence and troubleshooting.

---

## 6. Patient-Controlled Sharing

The patient manages doctor access through the demo frontend ("Als Patient" view, only on their
**own** record). The proxy mutates Keycloak with an admin token **after** it has verified
server-side that the logged-in user owns the target resource (`session.ownPatientId` — the patient
id never comes from the request).

| Action | Proxy endpoint | Keycloak object |
|--------|----------------|-----------------|
| Grant/revoke read scope per type | `POST /api/access/grant` | `Permission-Patient<id>-<doctor>` (+ `TrustList-Patient<id>-<doctor>`, bound to `RolePolicy-Doctor`); empty selection ⇒ permission deleted |
| Block/unblock a single instance | `POST /api/access/blacklist` | marker policy `Blacklist-<patId>-<resType>-<resId>-<docId>` |
| Read the current sharing state | `GET /api/access/state` | — |

**Effect:** trust-list / scope changes take effect on the next RPT exchange (the proxy exchanges
fresh per request → effectively immediate); blacklist changes within ≤ 30 s (cache in
`UmaBlacklistService`).

> **Security / UMA limitation:** the mutations run through the proxy's `admin/admin` token (after
> the owner check). In production the clean path would be UMA-native owner-managed access
> (`ownerManagedAccess=true` + Keycloak Account API with the user's **own** token); simplified
> here on purpose.

---

## 7. API Reference

### FHIR Server

**Base URL**: `http://localhost:8081/fhir`

#### Protected resources

| Resource | Endpoints |
|----------|-----------|
| Patient | GET, POST, PUT, DELETE, `$summary` |
| Condition | GET, POST, PUT, DELETE |
| AllergyIntolerance | GET, POST, PUT, DELETE |
| MedicationStatement | GET, POST, PUT, DELETE |

All require UMA authorization (RPT token), except create (POST) which uses a role-based check.
Reads of clinical resources must be patient-scoped (e.g. `Condition?patient=1`); type-level
`Patient` access (e.g. `GET /Patient`) is rejected.

#### Public endpoints

- `GET /fhir/metadata` — FHIR CapabilityStatement
- `GET /actuator/health` — health check
- `GET /.well-known/*`, static UI assets (`/`, `/css/`, `/js/`, `/img/`, `/favicon`)
- `GET /fhir/swagger-ui/index.html` — OpenAPI UI (`openapi_enabled: true`)

### Frontend proxy API (recommended for testing)

The demo frontend (`http://localhost:3000`) runs the UMA dance server-side. Useful for quick checks:

| Endpoint | Purpose |
|----------|---------|
| `POST /api/login` `{username,password}` | Password grant + resolves the patient context; sets a session cookie |
| `GET /api/fhir/<fhirPath>` | Generic FHIR proxy with full UMA dance → `{status, steps, resource}` |
| `GET /api/me` | Current session (roles, patient context) |
| `POST /api/logout` | Destroys the session |
| `GET /api/access/state` | Own sharing state: doctors + granted read scopes + blacklist per instance (owner only) |
| `POST /api/access/grant` `{doctorId, scopes[]}` | Set read scopes per type for a doctor; empty list = revoke (owner only) |
| `POST /api/access/blacklist` `{doctorId, resourceType, resourceId, blocked}` | Block/unblock a single instance for a doctor (owner only) |

> The `/api/access/*` endpoints are the **patient-controlled** sharing management: the proxy
> mutates Keycloak with an admin token after verifying the logged-in user owns their resource
> (patient id from the session, never from the request). Details:
> [Patient-Controlled Sharing](#6-patient-controlled-sharing).

```bash
curl -s -c cj.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" -d '{"username":"dr.smith","password":"smith123"}'
curl -s -b cj.txt http://localhost:3000/api/fhir/Patient/1            # -> {status:200, steps:[...], resource:{...}}
curl -s -b cj.txt http://localhost:3000/api/fhir/Patient/1/\$summary  # IPS document bundle
```

### Keycloak endpoints

**Base URL**: `http://localhost:8080/realms/FHIR-Auth`

Get an access token:
```bash
curl -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "username=alice" \
  -d "password=alice123"
```

Exchange a ticket for an RPT:
```bash
curl -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "ticket=<PERMISSION_TICKET>" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "subject_token=<USER_ACCESS_TOKEN>"
```

### Complete UMA flow example (direct, without the proxy)

```bash
# 1. Request with an access token → 401 + permission ticket
curl -i -H "Authorization: Bearer $ALICE_TOKEN" http://localhost:8081/fhir/Patient/1
# → HTTP 401, WWW-Authenticate: UMA realm="FHIR-Auth", as_uri="...", ticket="<TICKET>"

# 2. Get a user token
ALICE_TOKEN=$(curl -s -X POST \
  http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP&username=alice&password=alice123" \
  | jq -r '.access_token')

# 3. Exchange the ticket for an RPT
RPT=$(curl -s -X POST \
  http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket&ticket=<TICKET>&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP&subject_token=$ALICE_TOKEN" \
  | jq -r '.access_token')

# 4. Access the resource with the RPT
curl -H "Authorization: Bearer $RPT" http://localhost:8081/fhir/Patient/1
```

### Example responses

Patient resource:
```json
{
  "resourceType": "Patient",
  "id": "1",
  "identifier": [{"system": "keycloak-uuid", "value": "5441cea9-..."}],
  "name": [{"family": "Anderson", "given": ["Alice"]}],
  "gender": "female",
  "birthDate": "1990-01-01"
}
```

401 Unauthorized:
```json
{
  "resourceType": "OperationOutcome",
  "issue": [{
    "severity": "error",
    "code": "security",
    "diagnostics": "Access token required. Use permission ticket to obtain access token."
  }]
}
```

### Standards compliance

- **UMA 2.0**: permission tickets + RPTs via Keycloak's Protection API
- **SMART on FHIR v2**: `patient/<Type>.<interactions>` scopes
- **FHIR R5**: CRUD operations, `$summary` (IPS), OperationOutcome
- **OAuth 2.0 / JWT**: Bearer tokens; RS256-signed RPTs validated locally against the realm JWKS

---

## 8. `$summary` Operation

The `$summary` operation generates an **International Patient Summary (IPS)** — a standardized
FHIR `document` Bundle containing a patient's essential healthcare information. It is implemented
in `providers/PatientSummaryProvider.java` (registered via `hapi.fhir.custom-provider-classes`);
a custom provider that does not depend on HAPI's built-in IPS module.

### Endpoint

```
GET /fhir/Patient/[id]/$summary
Authorization: Bearer <RPT>
```

Access is gated by the UMA interceptor: the RPT must carry at least one read scope for the target
patient (`patient/Patient.r`, `patient/Condition.r`, `patient/MedicationStatement.r` or
`patient/AllergyIntolerance.r`).

### Response

A FHIR `Bundle` of type `document` containing a `Composition` (LOINC `60591-5`, "Patient summary
Document"), the `Patient`, and the permitted clinical resources grouped into sections:

| Section | LOINC | FHIR Resource |
|---------|-------|---------------|
| Problems | `11450-4` | Condition |
| Allergies and Intolerances | `48765-2` | AllergyIntolerance |
| Medication Summary | `10160-0` | MedicationStatement |

### UMA-aware behavior

The summary is **permission-filtered**, reusing the same enforcement stages as the interceptor:

- **Stage 2 (section scope):** a clinical section is included only if the RPT carries a read scope
  for that type (e.g. Problems needs `patient/Condition.r`/`.rs`). Sections without a scope are
  omitted entirely. The `Composition` and `Patient` are always present (the operation already
  required a read scope to be reached).
- **Stage 3 (granular categories):** if a scope carries a `?category=` filter, the section's search
  is narrowed to those categories.
- **Stage 4 (blacklist):** individual instances revoked by the patient are filtered out; a section
  left empty gets an `emptyReason` of `unavailable`.

### Example scenario (demo data)

**Alice's data (Patient/1):** Conditions (Hypertension, Diabetes, Migraine), MedicationStatement
(Metformin), AllergyIntolerance (Penicillin). Doctor access is **patient-controlled** — the
results below assume alice has granted the respective scopes in the frontend.

| Requester | Scopes on Patient/1 | `$summary` result |
|-----------|---------------------|-------------------|
| **alice** (owner) | all 5 | Composition + Patient + Problems + Allergies + Medications |
| **dr.smith** | `patient/Patient.r` | Composition + Patient demographics only (no clinical sections) |
| **dr.bob** | `patient/Condition.rs` | Composition + Patient + Problems (Conditions) only |
| **dr.bob** (no grant) | _none_ | `403` (no read scope → ticket/RPT denied) |

### Extending the summary

`PatientSummaryProvider` keeps the sections in a `SECTIONS` table (`SectionSpec`: title, LOINC,
FHIR type). Further IPS sections (e.g. Immunizations `11369-6`, Results `30954-2`, Procedures
`47519-4`) can be added there once the corresponding resource types are UMA-protected and have
their own scopes.

---

## 9. Further Reading

**FHIR (R5)**
- FHIR specification (good for looking up terminology): http://hl7.org/fhir/
- HAPI FHIR documentation: https://hapifhir.io/hapi-fhir/docs/
- Public FHIR R5 test server: https://hapi.fhir.org/baseR5

**OAuth 2.0 / OpenID Connect**
- Introduction to OpenID Connect and OAuth 2.0 (MIT 2014): https://www.slideshare.net/slideshow/mit-2014-introduction-to-open-id-connect-and-oauth-2/39539771
- HEART — Health Relationship Trust Profile for FHIR OAuth 2.0 Scopes: https://openid.net/specs/openid-heart-fhir-oauth2-1_0.html

**UMA 2.0**
- UMA 2.0 Grant for OAuth 2.0 Authorization (token flow spec): https://docs.kantarainitiative.org/uma/wg/oauth-uma-grant-2.0-09.html
- Federated Authorization for UMA 2.0 (endpoints spec): https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-federated-authz-2.0.html
- Patient-Centric Data Sharing with UMA (practical example): https://kantara.atlassian.net/wiki/x/BQBLCg

**International Patient Summary (IPS)**
- ISO/DIS 27269:2024 — International Patient Summary (standard specifying the IPS components)
