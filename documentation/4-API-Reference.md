# 4. API Reference

## FHIR Server

**Base URL**: `http://localhost:8081/fhir`

### Protected Resources

| Resource | Endpoints |
|----------|-----------|
| Patient | GET, POST, PUT, DELETE, `$summary` |
| Condition | GET, POST, PUT, DELETE |
| AllergyIntolerance | GET, POST, PUT, DELETE |
| MedicationStatement | GET, POST, PUT, DELETE |

All require UMA authorization (RPT token), except create (POST) which uses a role-based check.
Reads of clinical resources must be patient-scoped (e.g. `Condition?patient=1`); type-level
`Patient` access (e.g. `GET /Patient`) is rejected.

### Public Endpoints

- `GET /fhir/metadata` — FHIR CapabilityStatement
- `GET /actuator/health` — health check
- `GET /.well-known/*`, static UI assets (`/`, `/css/`, `/js/`, `/img/`, `/favicon`)
- `GET /fhir/swagger-ui/index.html` — OpenAPI UI (`openapi_enabled: true`)

---

## Frontend Proxy API (recommended for testing)

The demo frontend (`http://localhost:3000`) runs the UMA dance server-side. Useful for quick checks:

| Endpoint | Purpose |
|----------|---------|
| `POST /api/login` `{username,password}` | Password grant + resolves the patient context; sets a session cookie |
| `GET /api/fhir/<fhirPath>` | Generic FHIR proxy with full UMA dance → `{status, steps, resource}` |
| `GET /api/me` | Current session (roles, patient context) |
| `POST /api/logout` | Destroys the session |
| `GET /api/access/state` | Eigener Freigabe-Stand: Ärzte + gewährte Lese-Scopes + Blacklist je Instanz (nur Owner) |
| `POST /api/access/grant` `{doctorId, scopes[]}` | Lese-Scopes pro Typ für einen Arzt setzen; leere Liste = entziehen (nur Owner) |
| `POST /api/access/blacklist` `{doctorId, resourceType, resourceId, blocked}` | Einzelne Instanz für einen Arzt sperren/entsperren (nur Owner) |

> Die `/api/access/*`-Endpunkte sind die **patientengesteuerte** Freigabeverwaltung: Der Proxy
> mutiert Keycloak per Admin-Token, nachdem er geprüft hat, dass der eingeloggte User Owner der
> eigenen Ressource ist (Patient-ID aus der Session, nie aus dem Request). Details:
> [3-Keycloak-Configuration.md](3-Keycloak-Configuration.md#patientengesteuerte-freigabe-frontend).

```bash
curl -s -c cj.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" -d '{"username":"dr.smith","password":"smith123"}'
curl -s -b cj.txt http://localhost:3000/api/fhir/Patient/1            # -> {status:200, steps:[...], resource:{...}}
curl -s -b cj.txt http://localhost:3000/api/fhir/Patient/1/\$summary  # IPS document bundle
```

---

## Keycloak Endpoints

**Base URL**: `http://localhost:8080/realms/FHIR-Auth`

### Get Access Token
```bash
curl -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "username=alice" \
  -d "password=alice123"
```

### Exchange Ticket for RPT
```bash
curl -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "ticket=<PERMISSION_TICKET>" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "subject_token=<USER_ACCESS_TOKEN>"
```

---

## Complete UMA Flow Example (direct, without the proxy)

### Step 1: Request with an access token (get permission ticket)
```bash
curl -i -H "Authorization: Bearer $ALICE_TOKEN" http://localhost:8081/fhir/Patient/1
```

Response:
```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: UMA realm="FHIR-Auth", as_uri="http://keycloak:8080/realms/FHIR-Auth", ticket="<TICKET>"
```

### Step 2: Get user token
```bash
ALICE_TOKEN=$(curl -s -X POST \
  http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP&username=alice&password=alice123" \
  | jq -r '.access_token')
```

### Step 3: Exchange ticket for RPT
```bash
RPT=$(curl -s -X POST \
  http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket&ticket=<TICKET>&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP&subject_token=$ALICE_TOKEN" \
  | jq -r '.access_token')
```

### Step 4: Access resource with RPT
```bash
curl -H "Authorization: Bearer $RPT" http://localhost:8081/fhir/Patient/1
```

---

## Example Responses

### Patient Resource
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

### Patient `$summary` (International Patient Summary)
```bash
curl -H "Authorization: Bearer $RPT" http://localhost:8081/fhir/Patient/1/\$summary
```

Returns a FHIR `Bundle` of type `document` with a `Composition` plus the patient and the
permitted clinical resources. Sections are included only if the RPT carries the matching scope
and individual instances pass the blacklist filter — see
[6-$summary-Operation.md](6-$summary-Operation.md).

### 401 Unauthorized
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

---

## Standards Compliance

- **UMA 2.0**: permission tickets + RPTs via Keycloak's Protection API
- **SMART on FHIR v2**: `patient/<Type>.<interactions>` scopes
- **FHIR R5**: CRUD operations, `$summary` (IPS), OperationOutcome
- **OAuth 2.0 / JWT**: Bearer tokens; RS256-signed RPTs validated locally against the realm JWKS
