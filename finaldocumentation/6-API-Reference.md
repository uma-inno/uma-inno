# 6. API Reference

**Complete API documentation and standards compliance**

---

## Table of Contents

1. [FHIR REST API](#fhir-rest-api)
2. [UMA Authorization Endpoints](#uma-authorization-endpoints)
3. [Request/Response Examples](#requestresponse-examples)
4. [Standards Compliance](#standards-compliance)
5. [Configuration Parameters](#configuration-parameters)

---

## FHIR REST API

### Base URL

```
http://localhost:8081/fhir
```

### Protected Resources

All resources require UMA authorization except public endpoints.

#### Patient Resource

**Endpoints**:
- `GET /fhir/Patient` - Search patients
- `GET /fhir/Patient/{id}` - Read specific patient
- `POST /fhir/Patient` - Create patient (Doctor/Admin only)
- `PUT /fhir/Patient/{id}` - Update patient
- `DELETE /fhir/Patient/{id}` - Delete patient (Admin only)
- `GET /fhir/Patient/{id}/$everything` - Get patient summary

**Example Request**:
```http
GET /fhir/Patient/552 HTTP/1.1
Host: localhost:8081
Authorization: Bearer <RPT_TOKEN>
Accept: application/fhir+json
```

**Example Response** (200 OK):
```json
{
  "resourceType": "Patient",
  "id": "552",
  "meta": {
    "versionId": "1",
    "lastUpdated": "2026-01-12T10:30:00Z"
  },
  "identifier": [{
    "system": "keycloak-uuid",
    "value": "5441cea9-fcf2-419e-bc20-948c3c283c98"
  }],
  "name": [{
    "family": "Smith",
    "given": ["Alice"]
  }],
  "gender": "female",
  "birthDate": "1990-05-15"
}
```

#### Condition Resource

**Endpoints**:
- `GET /fhir/Condition` - Search conditions
- `GET /fhir/Condition/{id}` - Read specific condition
- `POST /fhir/Condition` - Create condition (Doctor/Admin only)
- `PUT /fhir/Condition/{id}` - Update condition
- `DELETE /fhir/Condition/{id}` - Delete condition (Admin only)

**Example Create Request**:
```http
POST /fhir/Condition HTTP/1.1
Host: localhost:8081
Authorization: Bearer <DOCTOR_TOKEN>
Content-Type: application/fhir+json

{
  "resourceType": "Condition",
  "subject": {
    "reference": "Patient/552"
  },
  "clinicalStatus": {
    "coding": [{
      "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
      "code": "active"
    }]
  },
  "verificationStatus": {
    "coding": [{
      "system": "http://terminology.hl7.org/CodeSystem/condition-ver-status",
      "code": "confirmed"
    }]
  },
  "code": {
    "coding": [{
      "system": "http://snomed.info/sct",
      "code": "73211009",
      "display": "Diabetes mellitus"
    }]
  }
}
```

#### AllergyIntolerance Resource

**Endpoints**: Same pattern as Condition

#### MedicationStatement Resource

**Endpoints**: Same pattern as Condition

### Public Endpoints (No Authentication)

- `GET /fhir/metadata` - FHIR CapabilityStatement
- `GET /actuator/health` - Health check
- `GET /actuator/info` - Application info

---

## UMA Authorization Endpoints

### Keycloak Base URL

```
http://localhost:8080/realms/FHIR-Auth
```

### 1. Get User Access Token

**Endpoint**: `/protocol/openid-connect/token`

**Method**: POST

**Request**:
```http
POST /realms/FHIR-Auth/protocol/openid-connect/token HTTP/1.1
Host: localhost:8080
Content-Type: application/x-www-form-urlencoded

grant_type=password&
client_id=fhir-client&
client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP&
username=alice&
password=alice123
```

**Response** (200 OK):
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "not-before-policy": 0,
  "session_state": "abc-123-def",
  "scope": "profile email"
}
```

### 2. Exchange Permission Ticket for RPT

**Endpoint**: `/protocol/openid-connect/token`

**Method**: POST

**Request**:
```http
POST /realms/FHIR-Auth/protocol/openid-connect/token HTTP/1.1
Host: localhost:8080
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:uma-ticket&
ticket=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...&
client_id=fhir-client&
client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP&
subject_token=<USER_ACCESS_TOKEN>
```

**Response** (200 OK):
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 300,
  "upgraded": true
}
```

**Note**: The `access_token` is the RPT with embedded permissions.

### 3. Token Introspection

**Endpoint**: `/protocol/openid-connect/token/introspect`

**Method**: POST

**Request**:
```http
POST /realms/FHIR-Auth/protocol/openid-connect/token/introspect HTTP/1.1
Host: localhost:8080
Content-Type: application/x-www-form-urlencoded

token=<TOKEN>&
client_id=fhir-client&
client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP
```

**Response** (200 OK):
```json
{
  "active": true,
  "sub": "5441cea9-fcf2-419e-bc20-948c3c283c98",
  "exp": 1705239844,
  "iat": 1705239544,
  "client_id": "fhir-client",
  "username": "alice",
  "token_type": "Bearer"
}
```

---

## Request/Response Examples

### Example 1: Complete UMA Flow

**Step 1: Request without token**
```bash
curl -i http://localhost:8081/fhir/Patient/552
```

**Response**:
```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: UMA realm="FHIR-Auth",
                  as_uri="http://localhost:8080/realms/FHIR-Auth",
                  ticket="eyJhbGciOi..."
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [{
    "severity": "error",
    "code": "security",
    "diagnostics": "Access token required. Use permission ticket to obtain access token."
  }]
}
```

**Step 2: Get Alice's token**
```bash
ALICE_TOKEN=$(curl -s -X POST \
  http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "username=alice" \
  -d "password=alice123" \
  | jq -r '.access_token')
```

**Step 3: Exchange ticket for RPT**
```bash
RPT=$(curl -s -X POST \
  http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "ticket=<PERMISSION_TICKET>" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "subject_token=$ALICE_TOKEN" \
  | jq -r '.access_token')
```

**Step 4: Access resource with RPT**
```bash
curl -H "Authorization: Bearer $RPT" \
  http://localhost:8081/fhir/Patient/552
```

**Response**: 200 OK with Patient data

### Example 2: Patient Summary ($everything)

```bash
curl -H "Authorization: Bearer $RPT" \
  http://localhost:8081/fhir/Patient/552/\$everything
```

**Response**:
```json
{
  "resourceType": "Bundle",
  "type": "searchset",
  "total": 4,
  "entry": [
    {
      "resource": {
        "resourceType": "Patient",
        "id": "552",
        "name": [{"family": "Smith", "given": ["Alice"]}]
      }
    },
    {
      "resource": {
        "resourceType": "Condition",
        "id": "554",
        "subject": {"reference": "Patient/552"},
        "code": {"coding": [{"code": "73211009", "display": "Diabetes"}]}
      }
    },
    {
      "resource": {
        "resourceType": "AllergyIntolerance",
        "id": "556",
        "patient": {"reference": "Patient/552"}
      }
    },
    {
      "resource": {
        "resourceType": "AllergyIntolerance",
        "id": "557",
        "patient": {"reference": "Patient/552"}
      }
    }
  ]
}
```

---

## Standards Compliance

### UMA 2.0 (User-Managed Access)

**Specification**: https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-grant-2.0.html

**Compliance**:
- ✅ Permission Ticket Endpoint (UMA Step 1)
- ✅ RPT Token Issuance (UMA Step 2)
- ✅ RPT Validation (UMA Step 3)
- ✅ WWW-Authenticate header format
- ✅ Protection API integration
- ✅ Policy-based authorization
- ✅ Resource registration

### FHIR R5

**Specification**: https://hl7.org/fhir/R5/

**Compliance**:
- ✅ FHIR R5 resource structures
- ✅ RESTful API operations (CRUD)
- ✅ Search parameters
- ✅ CapabilityStatement
- ✅ OperationOutcome error responses
- ✅ $everything operation (Patient Summary)
- ✅ Bundle responses

### OAuth 2.0

**Specification**: https://tools.ietf.org/html/rfc6749

**Compliance**:
- ✅ Bearer token authentication
- ✅ Token introspection
- ✅ Client credentials grant
- ✅ Resource owner password credentials grant
- ✅ Token expiration

### JWT (JSON Web Token)

**Specification**: https://tools.ietf.org/html/rfc7519

**Compliance**:
- ✅ JWT structure (header.payload.signature)
- ✅ Base64URL encoding
- ✅ RSA signature verification
- ✅ Standard claims (sub, exp, iat, iss)
- ✅ Custom claims (authorization.permissions)

---

## Configuration Parameters

### FHIR Server (application.yaml)

```yaml
server:
  port: 8081                   # FHIR server port

spring:
  datasource:
    url: 'jdbc:postgresql://localhost:5432/hapi'
    username: admin
    password: admin

hapi:
  fhir:
    fhir_version: R5           # FHIR version (DSTU2, DSTU3, R4, R5)
    server_address: http://localhost:8081/fhir

keycloak:
  auth-server-url: "http://localhost:8080"
  realm: "FHIR-Auth"
  resource: "fhir-client"
  system-owner-id: "7fc0d4bd-40ca-483e-9530-6e1fe84bded3"
```

### Keycloak Client

```
Client ID: fhir-client
Client Secret: QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP
Authorization Services: Enabled
Service Accounts Enabled: Yes
```

### Protected Resources

- PatientResource (scopes: read, create, update, delete)
- ConditionResource (scopes: read, create, update, delete)
- AllergyIntoleranceResource (scopes: read, create, update, delete)
- MedicationStatementResource (scopes: read, create, update, delete)

---

## Summary

The API provides:

1. **FHIR R5 REST API**: Complete CRUD operations on healthcare resources
2. **UMA 2.0 Authorization**: 3-step flow with permission tickets and RPTs
3. **Standards Compliance**: UMA 2.0, FHIR R5, OAuth 2.0, JWT
4. **Instance-Level Permissions**: Fine-grained access control
5. **Patient Summary**: $everything operation for comprehensive patient data

---

**Next Steps**: Read **[7-Future-Work.md](7-Future-Work.md)** for known limitations and future enhancements.

---

**Last Updated**: January 2026
