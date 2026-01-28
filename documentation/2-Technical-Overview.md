# 2. Technical Overview

## System Components

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   HAPI FHIR     │     │    Keycloak     │     │   PostgreSQL    │
│   Server        │◄───►│  Authorization  │     │   (2 DBs)       │
│   :8081         │     │     :8080       │     │  :5432 / :5433  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

| Component | Purpose |
|-----------|---------|
| **HAPI FHIR Server** | FHIR R5 REST API with UMA protection |
| **Keycloak** | UMA 2.0 Authorization Server (tokens, policies) |
| **PostgreSQL** | Separate databases for FHIR resources and Keycloak |

---

## UMA 2.0 Flow

UMA (User-Managed Access) enables patients to control who accesses their data.

### 3-Step Flow

```
Client                    FHIR Server                 Keycloak
  │                            │                          │
  │  1. GET /Patient/1         │                          │
  ├───────────────────────────►│                          │
  │                            │  Request ticket          │
  │                            ├─────────────────────────►│
  │  401 + ticket              │◄─────────────────────────┤
  │◄───────────────────────────┤                          │
  │                            │                          │
  │  2. Exchange ticket + user token for RPT              │
  ├──────────────────────────────────────────────────────►│
  │                            │     Evaluate policies    │
  │  RPT (with permissions)    │                          │
  │◄──────────────────────────────────────────────────────┤
  │                            │                          │
  │  3. GET /Patient/1 + RPT   │                          │
  ├───────────────────────────►│                          │
  │                            │  Validate token          │
  │  200 OK + Patient data     │                          │
  │◄───────────────────────────┤                          │
```

1. **Permission Ticket**: Client requests resource → Server returns 401 with ticket
2. **RPT Exchange**: Client exchanges ticket + user token → Keycloak returns RPT
3. **Resource Access**: Client sends RPT → Server validates and returns data

---

## Core Java Components

```
ca.uhn.fhir.jpa.starter/
├── interceptors/
│   ├── UmaKeycloakAuthInterceptor.java   # Enforces UMA (issues tickets, validates RPTs)
│   └── ResourceRegistrationInterceptor.java  # Auto-registers resources in Keycloak
└── services/
    └── KeycloakResourceService.java      # Keycloak Admin API integration
```

### UmaKeycloakAuthInterceptor

Intercepts all FHIR requests at `SERVER_INCOMING_REQUEST_PRE_HANDLED`:

```
Request arrives
    │
    ├─► Public endpoint? → Allow
    │
    ├─► No token? → Issue permission ticket (401)
    │
    ├─► Has token? → Introspect with Keycloak
    │       │
    │       ├─► Invalid? → Issue permission ticket
    │       │
    │       └─► Valid? → Extract permissions from JWT
    │               │
    │               ├─► Has permission for resource? → Allow
    │               │
    │               └─► No permission? → Issue permission ticket
```

### ResourceRegistrationInterceptor

Automatically registers FHIR resources in Keycloak when created:

1. Determines owner (patient via `keycloak-uuid` identifier)
2. Registers resource in Keycloak with owner
3. Grants creator permissions if creator ≠ owner (e.g., doctor creates condition)

---

## Resource Ownership

| Resource Type | Owner Determined By |
|--------------|---------------------|
| Patient | `keycloak-uuid` identifier in Patient resource |
| Condition, AllergyIntolerance, etc. | Referenced patient's Keycloak UUID |

**Owner Policy**: Custom JavaScript policy in Keycloak automatically grants full access to resource owners. No explicit permissions needed.

```javascript
// owner-policy.js (deployed as JAR)
if (resource.getOwner().equals(identity.getId())) {
    $evaluation.grant();
}
```

---

## JWT Token Structure

### Access Token
Standard Keycloak token with user info and roles.

### RPT (Requesting Party Token)
Contains granted permissions:

```json
{
  "sub": "5441cea9-...",
  "authorization": {
    "permissions": [
      {
        "rsname": "Patient/1",
        "scopes": ["read", "update", "delete"]
      }
    ]
  }
}
```

The FHIR server extracts `authorization.permissions` and validates that the requested resource and scope are included.

---

## Role-Based Access Control

| Role | Can Create | Can Read | Can Delete |
|------|-----------|----------|------------|
| Patient | No | Own data only | No |
| Doctor | Patient, Condition, etc. | Granted resources | No |
| Administrator | All | All | All |

---

## Key Implementation Details

### Docker Networking
The FHIR server needs `extra_hosts: ["localhost:host-gateway"]` to reach Keycloak via `localhost:8080` (matching token issuer).

### Permission Ticket Format
Keycloak expects an array for permission requests:
```json
[{"resource_id": "uuid", "resource_scopes": ["read"]}]
```

### Instance-Level Matching
Permission validation requires exact resource name match:
- ✅ `Patient/1` permission → can access `Patient/1`
- ❌ `PatientResource` permission → cannot access `Patient/1`
