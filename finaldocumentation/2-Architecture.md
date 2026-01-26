# 2. System Architecture

**Comprehensive overview of the UMA 2.0 Protected FHIR Server architecture**

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Component Architecture](#component-architecture)
3. [Request Flow](#request-flow)
4. [UMA Authorization Flow](#uma-authorization-flow)
5. [Resource Ownership Model](#resource-ownership-model)
6. [Role-Based Access Control (RBAC)](#role-based-access-control-rbac)
7. [Data Flow and Persistence](#data-flow-and-persistence)

---

## System Overview

### High-Level Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                           Client Application                            │
│                      (Browser, Mobile App, cURL)                        │
└──────────────────────────────┬─────────────────────────────────────────┘
                               │
                               │ HTTPS / HTTP
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                       │
        │ (1) FHIR Request     │ (3) Token Request    │
        ▼                      │                       ▼
┌───────────────────┐          │              ┌─────────────────────┐
│                   │          │              │                     │
│   HAPI FHIR       │◄─────────┼──────────────┤    Keycloak         │
│   JPA Server      │ (2) UMA  │              │    Authorization    │
│                   │ Protocol │              │    Server           │
│   Port: 8081      │          │              │    Port: 8080       │
│                   │          │              │                     │
└─────────┬─────────┘          │              └──────────┬──────────┘
          │                    │                         │
          │                    │                         │
          │ JPA/Hibernate      │                         │ JDBC
          │                    │                         │
          ▼                    │                         ▼
┌─────────────────────┐        │              ┌─────────────────────┐
│  HAPI FHIR          │        │              │  Keycloak           │
│  PostgreSQL         │        │              │  PostgreSQL         │
│  Port: 5432         │        │              │  Port: 5433         │
│                     │        │              │                     │
│  Database: hapi     │        │              │  Database: keycloak │
└─────────────────────┘        │              └─────────────────────┘
                               │
                               │
                    Docker Network (bridge)
```

### Key Design Principles

1. **Separation of Concerns**:
   - **Resource Server** (HAPI FHIR): Manages FHIR resources
   - **Authorization Server** (Keycloak): Manages authentication and authorization
   - **Databases**: Separate data stores for resources and authorization

2. **UMA 2.0 Compliance**:
   - Implements complete 3-step UMA flow
   - Decouples resource access from authorization
   - Enables patient-controlled access

3. **Instance-Level Permissions**:
   - Fine-grained access control (Patient/552 vs PatientResource)
   - Resource ownership model
   - Dynamic permission evaluation

4. **Role-Based Access Control**:
   - Three primary roles: Patient, Doctor, Administrator
   - Policy-based authorization
   - Flexible permission assignment

---

## Component Architecture

### 1. HAPI FHIR JPA Server

**Purpose**: FHIR R5-compliant REST API server with UMA protection

**Technology Stack**:
- HAPI FHIR 8.0.0
- Spring Boot 3.x
- Java 17
- Hibernate/JPA

**Key Responsibilities**:
- Expose FHIR REST API endpoints
- Validate FHIR resources
- Persist resources to PostgreSQL
- Enforce UMA authorization via interceptors
- Register resources in Keycloak on creation

**Core Components**:

```
ca.uhn.fhir.jpa.starter/
├── Application.java                      # Spring Boot entry point
├── interceptors/
│   ├── UmaKeycloakAuthInterceptor.java  # UMA authorization enforcement
│   ├── ResourceRegistrationInterceptor.java  # Auto-register resources
│   └── JpaEntityTrackingInterceptor.java     # Resource lifecycle tracking
├── services/
│   └── KeycloakResourceService.java     # Keycloak integration
└── uma/
    ├── UmaProvider.java                 # UMA FHIR operations
    ├── UmaTokenService.java             # Token management
    └── UmaAuthenticationService.java    # Authentication logic
```

**Configuration**:
- **Location**: `hapi-jpa/src/main/resources/application.yaml`
- **FHIR Version**: R5
- **Database**: PostgreSQL (hapi database)
- **Port**: 8081

### 2. Keycloak Authorization Server

**Purpose**: UMA 2.0 compliant authorization server

**Technology Stack**:
- Keycloak (latest version, 26.x)
- PostgreSQL for persistence
- Docker container deployment

**Key Responsibilities**:
- User authentication (OAuth 2.0)
- Issue access tokens and RPTs
- Manage authorization policies
- Evaluate permissions dynamically
- Store resource registrations
- Execute custom policies (JavaScript)

**Configuration**:
- **Realm**: FHIR-Auth
- **Client ID**: fhir-client
- **Client Secret**: QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP
- **Port**: 8080

**Authorization Services**:
- ✅ Enabled
- Resources: PatientResource, ConditionResource, etc.
- Scopes: read, create, update, delete
- Policies: Role-based, owner-based (custom JavaScript)
- Permissions: Scope-based permissions linking policies to resources

### 3. PostgreSQL Databases

**Two separate databases for isolation:**

#### HAPI FHIR Database
- **Port**: 5432
- **Database**: hapi
- **User**: admin / admin
- **Purpose**: Store FHIR resources (Patient, Condition, etc.)
- **Schema**: Generated by HAPI FHIR JPA

**Key Tables**:
- `hfj_resource` - Main resource table
- `hfj_res_ver` - Resource versions
- `hfj_res_link` - Resource references
- `hfj_spidx_*` - Search parameter indexes

#### Keycloak Database
- **Port**: 5433 (mapped to 5432 internally)
- **Database**: keycloak
- **User**: keycloak / keycloak
- **Purpose**: Store users, roles, policies, resources

**Key Tables**:
- `user_entity` - User accounts
- `role_entity` - Roles (Patient, Doctor, Admin)
- `resource_server_*` - UMA resources and policies
- `policy_entity` - Authorization policies

### 4. Custom Keycloak Policy (JavaScript JAR)

**Location**: `keycloak-policies/owner-policy.js`

**Purpose**: Automatically grant full permissions to resource owners

**Implementation**:
```javascript
// owner-policy.js
var context = $evaluation.getContext();
var identity = context.getIdentity();
var permission = $evaluation.getPermission();
var resource = permission.getResource();

if (resource) {
    var owner = resource.getOwner();
    var userId = identity.getId();

    if (owner != null && owner.equals(userId)) {
        $evaluation.grant();  // Owner gets automatic access
    }
}
```

**Deployment**:
- Compiled to JAR: `keycloak-owner-policy.jar`
- Mounted in Docker: `/opt/keycloak/providers/keycloak-owner-policy.jar`
- Auto-loaded by Keycloak on startup

**Usage**: Eliminates need for explicit owner permissions - patients automatically access their own data

---

## Request Flow

### Complete Request Processing Pipeline

```
1. Client Request
   ↓
2. Docker Network Routing
   ↓
3. Spring Boot Filter Chain
   ↓
4. HAPI FHIR Servlet
   ↓
5. UmaKeycloakAuthInterceptor (PRE_HANDLED)
   │
   ├─→ Public endpoint? → Allow (skip auth)
   ├─→ No token? → Issue permission ticket (UMA Step 1)
   ├─→ Has token? → Introspect with Keycloak
   │   ├─→ Invalid? → Issue permission ticket
   │   └─→ Valid? → Extract permissions
   │       ├─→ Has permission? → Continue
   │       └─→ No permission? → Issue permission ticket
   ↓
6. ResourceRegistrationInterceptor (on CREATE)
   ├─→ Validate uniqueness (Patient)
   ├─→ Determine owner
   └─→ Register in Keycloak
   ↓
7. HAPI FHIR Resource Provider
   ↓
8. JPA Repository / Database Query
   ↓
9. FHIR Resource Response
   ↓
10. Client receives data
```

### Example: GET /fhir/Patient/552

**Scenario**: Alice requests her own patient record

**Step 1: Initial Request (No Token)**
```http
GET /fhir/Patient/552 HTTP/1.1
Host: localhost:8081
```

**Step 2: UmaKeycloakAuthInterceptor Processing**
- Check if endpoint is public → No
- Check for bearer token → No token found
- Request permission ticket from Keycloak Protection API

**Step 3: Permission Ticket Issued**
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

**Step 4: Client Exchanges Ticket for RPT**
```http
POST /realms/FHIR-Auth/protocol/openid-connect/token HTTP/1.1
Host: localhost:8080
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:uma-ticket
ticket=eyJhbGciOi...
client_id=fhir-client
client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP
subject_token=<alice_access_token>
```

**Step 5: Keycloak Evaluates Policies**
- Check if Alice has permission for Patient/552
- Owner Policy evaluates: Alice owns Patient/552 → Grant
- Issue RPT with embedded permissions

**Step 6: Client Retries with RPT**
```http
GET /fhir/Patient/552 HTTP/1.1
Host: localhost:8081
Authorization: Bearer <RPT_TOKEN>
```

**Step 7: UmaKeycloakAuthInterceptor Validates RPT**
- Introspect token with Keycloak → Active
- Decode JWT and extract permissions
- Check if permission includes Patient/552 with "read" scope → Yes
- Allow request to proceed

**Step 8: FHIR Server Returns Data**
```http
HTTP/1.1 200 OK
Content-Type: application/fhir+json

{
  "resourceType": "Patient",
  "id": "552",
  "identifier": [{
    "system": "keycloak-uuid",
    "value": "5441cea9-fcf2-419e-bc20-948c3c283c98"
  }],
  "name": [{
    "family": "Smith",
    "given": ["Alice"]
  }]
}
```

---

## UMA Authorization Flow

### UMA 2.0 Three-Step Flow

```
┌────────────┐         ┌─────────────────┐         ┌──────────────────┐
│            │         │   FHIR Server   │         │    Keycloak      │
│   Client   │         │  (Resource      │         │  (Authorization  │
│            │         │   Server)       │         │   Server)        │
└──────┬─────┘         └────────┬────────┘         └────────┬─────────┘
       │                        │                           │
       │                        │                           │
       │  STEP 1: Permission Ticket Request                 │
       │                        │                           │
       │  GET /fhir/Patient/552 │                           │
       │  (no token)            │                           │
       ├───────────────────────►│                           │
       │                        │                           │
       │                        │  Request Permission       │
       │                        │  Ticket                   │
       │                        ├──────────────────────────►│
       │                        │                           │
       │                        │  ◄─────────────────────── │
       │                        │  Return Ticket            │
       │                        │  (ticket=XYZ)             │
       │                        │                           │
       │  ◄───────────────────── │                           │
       │  401 Unauthorized       │                           │
       │  WWW-Authenticate:      │                           │
       │    ticket=XYZ           │                           │
       │                        │                           │
       │                        │                           │
       │  STEP 2: RPT Token Exchange                        │
       │                        │                           │
       │  POST /token                                       │
       │  (ticket + user token)                             │
       ├──────────────────────────────────────────────────►│
       │                        │                           │
       │                        │  Evaluate Policies        │
       │                        │  (Owner Policy, RBAC)     │
       │                        │                           │
       │  ◄────────────────────────────────────────────────│
       │  RPT Token (JWT with permissions)                  │
       │                        │                           │
       │                        │                           │
       │  STEP 3: Resource Access with RPT                  │
       │                        │                           │
       │  GET /fhir/Patient/552 │                           │
       │  Authorization: Bearer │                           │
       │    <RPT>               │                           │
       ├───────────────────────►│                           │
       │                        │                           │
       │                        │  Introspect Token         │
       │                        ├──────────────────────────►│
       │                        │                           │
       │                        │  ◄─────────────────────── │
       │                        │  Token Active + Perms     │
       │                        │                           │
       │                        │  Extract Permissions      │
       │                        │  from JWT                 │
       │                        │                           │
       │                        │  Validate: Patient/552,   │
       │                        │  scope=read               │
       │                        │                           │
       │  ◄───────────────────── │                           │
       │  200 OK                │                           │
       │  Patient Data          │                           │
       │                        │                           │
```

### Step-by-Step Explanation

#### Step 1: Permission Ticket Request

**Trigger**: Client attempts to access protected resource without valid token

**Process**:
1. Client sends GET /fhir/Patient/552 (no Authorization header)
2. `UmaKeycloakAuthInterceptor` intercepts request
3. No token found → Call `handleTokenlessAccess()`
4. `buildPermissionRequest()` creates request:
   - Resource ID: UUID of Patient/552 (from Keycloak)
   - Scopes: ["read"]
5. `requestPermissionTicket()` calls Keycloak Protection API:
   ```http
   POST /realms/FHIR-Auth/authz/protection/permission
   Authorization: Bearer <PROTECTION_API_TOKEN>
   Content-Type: application/json

   [{
     "resource_id": "abc-123-def-456",
     "resource_scopes": ["read"]
   }]
   ```
6. Keycloak returns permission ticket
7. FHIR server responds with 401 + WWW-Authenticate header

**Key Code**: `UmaKeycloakAuthInterceptor.java:183-230`

#### Step 2: RPT Token Exchange

**Trigger**: Client receives permission ticket and wants to obtain access

**Process**:
1. Client sends POST to Keycloak token endpoint:
   ```http
   POST /realms/FHIR-Auth/protocol/openid-connect/token
   Content-Type: application/x-www-form-urlencoded

   grant_type=urn:ietf:params:oauth:grant-type:uma-ticket
   ticket=<PERMISSION_TICKET>
   client_id=fhir-client
   client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP
   subject_token=<USER_ACCESS_TOKEN>
   ```
2. Keycloak evaluates authorization policies:
   - Check Owner Policy: Is user the owner?
   - Check Role-based policies: Does user have required role?
   - Check other policies (ABAC, etc.)
3. If authorized, Keycloak issues RPT (Requesting Party Token)
4. RPT is a JWT containing:
   ```json
   {
     "sub": "5441cea9-...",
     "authorization": {
       "permissions": [{
         "rsname": "Patient/552",
         "rsid": "abc-123-def-456",
         "scopes": ["read", "update"]
       }]
     }
   }
   ```

**Key Implementation**: Handled natively by Keycloak (no custom code needed)

#### Step 3: Resource Access with RPT

**Trigger**: Client has RPT and retries resource access

**Process**:
1. Client sends GET /fhir/Patient/552 with RPT:
   ```http
   GET /fhir/Patient/552
   Authorization: Bearer <RPT>
   ```
2. `UmaKeycloakAuthInterceptor` intercepts request
3. `isTokenValid()` introspects token with Keycloak:
   ```http
   POST /realms/FHIR-Auth/protocol/openid-connect/token/introspect
   Content-Type: application/x-www-form-urlencoded

   token=<RPT>
   client_id=fhir-client
   client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP
   ```
4. Keycloak responds: `{"active": true}`
5. `extractPermissionsFromRPT()` decodes JWT:
   - Split token into header.payload.signature
   - Base64URL decode payload
   - Parse JSON and extract `authorization.permissions`
6. `hasRequiredPermission()` validates:
   - Check if permission list contains Patient/552
   - Check if scopes include "read"
7. If valid → Allow request to proceed
8. HAPI FHIR fetches resource from database
9. Return 200 OK with FHIR data

**Key Code**: `UmaKeycloakAuthInterceptor.java:489-669`

---

## Resource Ownership Model

### Ownership Rules

**1. Patient Resources**

A Patient resource can be owned by:
- **The patient themselves** (self-owned): Patient has Keycloak account and identifier
- **System placeholder**: Patient doesn't have Keycloak account yet

**Determination Logic**:
```java
// ResourceRegistrationInterceptor.java
private String determineOwnerId(Patient patient, String creatorId) {
    // Check if patient has keycloak-uuid identifier
    String keycloakId = extractKeycloakIdFromPatient(patient);

    if (keycloakId != null) {
        return keycloakId;  // Patient owns themselves
    }

    // No Keycloak link → use system owner
    return "7fc0d4bd-40ca-483e-9530-6e1fe84bded3";
}
```

**Example**:
```json
{
  "resourceType": "Patient",
  "id": "552",
  "identifier": [{
    "system": "keycloak-uuid",
    "value": "5441cea9-fcf2-419e-bc20-948c3c283c98"
  }],
  "name": [{"family": "Smith", "given": ["Alice"]}]
}
```
**Owner**: 5441cea9-fcf2-419e-bc20-948c3c283c98 (Alice)

**2. Clinical Resources**

Resources like Condition, AllergyIntolerance, MedicationStatement are owned by the **referenced patient**.

**Determination Logic**:
```java
// ResourceRegistrationInterceptor.java
private String determineOwnerId(IBaseResource resource, String creatorId) {
    if ("Condition".equals(resourceType)) {
        // Extract patient reference (e.g., "Patient/552")
        String patientRef = extractPatientReference(resource);

        // Look up patient's Keycloak ID
        String patientKeycloakId = keycloakResourceService.getPatientKeycloakId("552");
        return patientKeycloakId;  // Owner is the patient
    }
}
```

**Example**:
```json
{
  "resourceType": "Condition",
  "id": "554",
  "subject": {"reference": "Patient/552"},
  "code": {"coding": [{"code": "73211009", "display": "Diabetes"}]}
}
```
**Owner**: 5441cea9-... (Alice, because Condition references Patient/552)

### Creator Permissions

**Problem**: Doctor creates a Condition for Alice. Alice is the owner, but doctor needs access to view/edit.

**Solution**: Automatic creator permissions

**Implementation**:
```java
// ResourceRegistrationInterceptor.java
public void resourceCreated(IBaseResource resource, RequestDetails request) {
    String creatorId = extractUserIdFromToken(request);
    String ownerId = determineOwnerId(resource, creatorId);

    // Register resource in Keycloak
    keycloakResourceService.registerResource(resourceType, resourceId, ownerId);

    // Grant creator permissions if different from owner
    if (!creatorId.equals(ownerId)) {
        keycloakResourceService.grantCreatorPermissions(
            resourceType, resourceId, creatorId, ownerId
        );
    }
}
```

**Result**:
- Alice (owner): read, write, delete (via Owner Policy)
- Dr. Bob (creator): read, write (explicit permission)

### Owner Policy Advantage

**Traditional Approach**: Create explicit permission for every resource owner
- Resource created → Create policy → Create permission → Link to resource
- 3 Keycloak API calls per resource

**Owner Policy Approach**: Automatic permission for owners
- Resource created → Set owner field
- Owner Policy automatically grants access
- 1 Keycloak API call per resource

**Benefits**:
- Faster resource creation
- Fewer Keycloak objects (policies, permissions)
- Simpler permission model
- Automatic patient access

---

## Role-Based Access Control (RBAC)

### Role Definitions

**1. Patient Role**

**Permissions**:
- ✅ Read own Patient resource
- ✅ Read own clinical resources (Condition, AllergyIntolerance, etc.)
- ✅ Update own Patient data
- ❌ Create any resources
- ❌ Delete any resources
- ❌ Access other patients' data

**Use Case**: Alice (patient) can view and update her own medical records

**2. Doctor Role**

**Permissions**:
- ✅ Create Patient resources (for patients without accounts)
- ✅ Create clinical resources (Condition, AllergyIntolerance, MedicationStatement)
- ✅ Read resources they created or have been granted access to
- ✅ Update resources they created
- ❌ Delete Patient resources
- ❌ Access resources without explicit permission

**Use Case**: Dr. Bob creates a Condition for Alice and can view/edit it

**3. Administrator Role**

**Permissions**:
- ✅ Full access to all resources
- ✅ Create, read, update, delete any resource
- ✅ Bypass ownership checks
- ✅ Manage permissions

**Use Case**: System administrator Jan can access all data for maintenance

### RBAC Implementation

**Phase 1: Keycloak Role Configuration**

1. Realm roles created: Patient, Doctor, Administrator
2. Users assigned roles
3. Role-based policies created:
   - Patient Access Policy (matches Patient role)
   - Doctor Access Policy (matches Doctor role)
   - Administrator Access Policy (matches Administrator role)

**Phase 2: Creation Authorization (Code-Level)**

```java
// UmaKeycloakAuthInterceptor.java
if ("POST".equals(httpMethod)) {
    // Extract roles from token
    List<String> roles = extractRolesFromToken(token);

    // Check if any role allows creating this resource type
    if (!canRoleCreateResource(roles, resourceType)) {
        throw new ForbiddenOperationException(
            "You do not have permission to create " + resourceType + " resources"
        );
    }
}

private boolean canRoleCreateResource(List<String> roles, String resourceType) {
    for (String role : roles) {
        if ("patient".equals(role.toLowerCase())) {
            return false;  // Patients can't create anything
        }
        if ("doctor".equals(role.toLowerCase())) {
            // Doctors can create Patient and clinical resources
            return "Patient".equals(resourceType) ||
                   "Condition".equals(resourceType) ||
                   "AllergyIntolerance".equals(resourceType) ||
                   "MedicationStatement".equals(resourceType);
        }
        if ("admin".equals(role.toLowerCase())) {
            return true;  // Admins can create everything
        }
    }
    return false;
}
```

**Phase 3: Access Authorization (Policy-Level)**

Once a resource exists, Keycloak policies determine who can access it:
- Owner Policy: Owner always has access
- Role-based Policy: Role determines type-level access
- Instance-level Permissions: Explicit grants for specific resources

### RBAC Decision Matrix

| Action | Patient | Doctor | Administrator |
|--------|---------|--------|---------------|
| **Create Patient** | ❌ | ✅ | ✅ |
| **Read own Patient** | ✅ (owner) | ✅ (if granted) | ✅ |
| **Read other Patient** | ❌ | ❌ (unless granted) | ✅ |
| **Update own Patient** | ✅ (owner) | ✅ (if granted) | ✅ |
| **Delete Patient** | ❌ | ❌ | ✅ |
| **Create Condition** | ❌ | ✅ | ✅ |
| **Read own Condition** | ✅ (owner) | ✅ (if creator) | ✅ |
| **Update Condition** | ❌ | ✅ (if creator) | ✅ |
| **Delete Condition** | ❌ | ❌ | ✅ |

---

## Data Flow and Persistence

### Resource Creation Flow

```
1. Client sends POST /fhir/Patient
   ↓
2. UmaKeycloakAuthInterceptor
   ├─→ Extract roles from token
   ├─→ Check if role can create Patient
   └─→ If yes, continue; if no, throw 403
   ↓
3. ResourceRegistrationInterceptor (PRESTORAGE)
   ├─→ Extract keycloak-uuid from Patient.identifier
   ├─→ Search database for existing Patient with same UUID
   └─→ If duplicate found, throw 422
   ↓
4. HAPI FHIR JPA Provider
   ├─→ Validate FHIR resource
   └─→ Save to database (hfj_resource table)
   ↓
5. ResourceRegistrationInterceptor (PRECOMMIT)
   ├─→ Determine owner (patient themselves or system)
   ├─→ Extract creator from token
   ├─→ Register resource in Keycloak:
   │   - POST /authz/protection/resource_set
   │   - Set name: "Patient/552"
   │   - Set owner: "5441cea9-..."
   │   - Set scopes: ["read", "write", "delete"]
   └─→ Grant creator permissions (if creator ≠ owner)
   ↓
6. Return 201 Created + Location header
```

### Database Schema (Simplified)

**HAPI FHIR Database (hapi)**:

```sql
-- Main resource table
CREATE TABLE hfj_resource (
    res_id BIGINT PRIMARY KEY,
    res_type VARCHAR(40),        -- e.g., "Patient", "Condition"
    res_version VARCHAR(7),
    has_tags BOOLEAN,
    res_text CLOB,               -- FHIR resource as JSON
    res_updated TIMESTAMP,
    ...
);

-- Resource versions (for history)
CREATE TABLE hfj_res_ver (
    pid BIGINT PRIMARY KEY,
    res_id BIGINT,              -- FK to hfj_resource
    res_text CLOB,
    res_version VARCHAR(7),
    ...
);

-- Search indexes (for queries)
CREATE TABLE hfj_spidx_token (
    sp_id BIGINT PRIMARY KEY,
    res_id BIGINT,              -- FK to hfj_resource
    sp_name VARCHAR(100),        -- e.g., "identifier"
    sp_system VARCHAR(200),      -- e.g., "keycloak-uuid"
    sp_value VARCHAR(200),       -- e.g., "5441cea9-..."
    ...
);
```

**Keycloak Database (keycloak)**:

```sql
-- Users
CREATE TABLE user_entity (
    id VARCHAR(36) PRIMARY KEY,
    username VARCHAR(255),
    ...
);

-- Roles
CREATE TABLE keycloak_role (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255),          -- e.g., "Patient", "Doctor"
    realm_id VARCHAR(36),
    ...
);

-- UMA Resources
CREATE TABLE resource_server_resource (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255),          -- e.g., "Patient/552"
    owner VARCHAR(255),         -- e.g., "5441cea9-..."
    resource_server_id VARCHAR(36),
    ...
);

-- Policies
CREATE TABLE resource_server_policy (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255),
    type VARCHAR(255),          -- e.g., "role", "js"
    config TEXT,                -- JSON configuration
    ...
);
```

---

## Summary

The system implements a **sophisticated, multi-layered architecture** combining:

1. **FHIR R5 Compliance**: Standard healthcare data API
2. **UMA 2.0 Authorization**: Patient-controlled access
3. **Instance-Level Permissions**: Fine-grained access control
4. **Role-Based Access Control**: Flexible permission model
5. **Owner Policy**: Automatic patient access
6. **Creator Permissions**: Doctor access to created records

This architecture enables:
- Patients own and control their medical data
- Doctors can create and access records with permission
- Administrators have full access for system management
- Dynamic, policy-based authorization
- Scalable and maintainable design

---

**Next Steps**: Read **[3-UMA-Implementation.md](3-UMA-Implementation.md)** for detailed code-level explanation of UMA implementation.

---

**Last Updated**: January 2026
