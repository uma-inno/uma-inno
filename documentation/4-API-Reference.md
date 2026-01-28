# 4. API Reference

## FHIR Server

**Base URL**: `http://localhost:8081/fhir`

### Protected Resources

| Resource | Endpoints |
|----------|-----------|
| Patient | GET, POST, PUT, DELETE, $everything |
| Condition | GET, POST, PUT, DELETE |
| AllergyIntolerance | GET, POST, PUT, DELETE |
| MedicationStatement | GET, POST, PUT, DELETE |

All require UMA authorization (RPT token).

### Public Endpoints

- `GET /fhir/metadata` - FHIR CapabilityStatement
- `GET /actuator/health` - Health check

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

## Complete UMA Flow Example

### Step 1: Request without token (get permission ticket)
```bash
curl -i http://localhost:8081/fhir/Patient/1
```

Response:
```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: UMA realm="FHIR-Auth", as_uri="http://localhost:8080/realms/FHIR-Auth", ticket="<TICKET>"
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
  "name": [{"family": "Smith", "given": ["Alice"]}],
  "gender": "female",
  "birthDate": "1985-03-15"
}
```

### Patient $everything
```bash
curl -H "Authorization: Bearer $RPT" http://localhost:8081/fhir/Patient/1/\$everything
```

Returns a Bundle with all resources related to the patient.

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

- **UMA 2.0**: Full 3-step flow with permission tickets and RPTs
- **FHIR R5**: Complete CRUD operations, $everything, OperationOutcome
- **OAuth 2.0**: Bearer tokens, token introspection
- **JWT**: RS256 signed tokens with permission claims
