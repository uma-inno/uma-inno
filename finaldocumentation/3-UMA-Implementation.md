# 3. UMA Implementation

**Detailed explanation of the UMA 2.0 implementation in the FHIR server**

---

## Table of Contents

1. [UMA 2.0 Protocol Overview](#uma-20-protocol-overview)
2. [Implementation Architecture](#implementation-architecture)
3. [Core Components](#core-components)
4. [JWT Token Structure](#jwt-token-structure)
5. [Permission Extraction and Validation](#permission-extraction-and-validation)
6. [Implementation Highlights](#implementation-highlights)

---

## UMA 2.0 Protocol Overview

### What is UMA?

**User-Managed Access (UMA)** is an OAuth 2.0 profile that enables a resource owner (patient) to control access to their protected resources (medical records) hosted at a resource server (FHIR server), independent of where those resources are located.

**Key Characteristics**:
- **Asynchronous Authorization**: Access decisions are made independently of authentication
- **Party-to-Party Authorization**: Enables sharing between different parties (patient → doctor)
- **Policy-Based**: Authorization decisions based on configurable policies
- **Decoupled**: Resource server and authorization server are separate

### UMA vs Traditional OAuth 2.0

| Feature | OAuth 2.0 | UMA 2.0 |
|---------|-----------|---------|
| **Authorization** | Client-centric | Resource owner-centric |
| **Token Issuance** | Immediate (sync) | Deferred (async) |
| **Permission Management** | Fixed scopes | Dynamic permissions |
| **Resource Protection** | Type-level | Instance-level |
| **Use Case** | API access | Resource sharing |

**Example**:
- **OAuth 2.0**: "This app can read all your contacts"
- **UMA 2.0**: "Alice allows Dr. Bob to read Patient/552 for 30 days"

### UMA 2.0 Roles

```
┌─────────────────┐
│  Resource Owner │  ← Patient (Alice)
│    (RO)         │    Owns medical data
└────────┬────────┘
         │ owns
         │
┌────────▼────────┐
│  Resource Server│  ← FHIR Server
│      (RS)       │    Stores medical data, enforces policies
└────────┬────────┘
         │ protects
         │
┌────────▼────────┐
│  Authorization  │  ← Keycloak
│    Server (AS)  │    Issues tokens, evaluates policies
└────────┬────────┘
         │ authorizes
         │
┌────────▼────────┐
│ Requesting Party│  ← Dr. Bob
│      (RP)       │    Requests access to Alice's data
└─────────────────┘
```

---

## Implementation Architecture

### Component Overview

Our UMA implementation consists of three main Java components:

```
UMA Implementation
│
├── UmaKeycloakAuthInterceptor.java      (822 lines)
│   ├─→ Intercepts all FHIR requests
│   ├─→ Implements UMA Steps 1 & 3
│   ├─→ Issues permission tickets
│   ├─→ Validates RPT tokens
│   └─→ Extracts and checks permissions
│
├── ResourceRegistrationInterceptor.java  (276 lines)
│   ├─→ Automatically registers resources in Keycloak
│   ├─→ Determines resource ownership
│   ├─→ Grants creator permissions
│   └─→ Prevents duplicate patients
│
└── KeycloakResourceService.java         (260 lines)
    ├─→ Interfaces with Keycloak Admin API
    ├─→ Registers UMA resources
    ├─→ Creates policies and permissions
    └─→ Manages resource ownership
```

### Integration Points

```
┌──────────────────────────────────────────────────────────────┐
│                  HAPI FHIR Request Pipeline                   │
└──────────────────────────────────────────────────────────────┘
                              │
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        │            SERVER_INCOMING_REQUEST_       │
        │            PRE_HANDLED                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌──────────────────┐   ┌───────────────┐
│ Other         │   │ UmaKeycloakAuth  │   │ Other         │
│ Interceptors  │   │ Interceptor      │   │ Interceptors  │
└───────────────┘   └──────────────────┘   └───────────────┘
                              │
                              │ Continue or Abort
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    │ STORAGE_          │
                    │ PRESTORAGE_       │
                    │ RESOURCE_CREATED  │
                    │                   │
                    ▼                   ▼
            ┌───────────────┐   ┌───────────────┐
            │ Resource      │   │ Other         │
            │ Registration  │   │ Interceptors  │
            │ Interceptor   │   │               │
            └───────────────┘   └───────────────┘
                    │
                    │
                    │ STORAGE_PRECOMMIT_
                    │ RESOURCE_CREATED
                    │
                    ▼
            ┌───────────────┐
            │ Register in   │
            │ Keycloak      │
            └───────────────┘
                    │
                    ▼
            ┌───────────────┐
            │ Save to DB    │
            └───────────────┘
```

---

## Core Components

### 1. UmaKeycloakAuthInterceptor

**Purpose**: Main UMA authorization enforcement

**Key Responsibilities**:
1. Intercept all incoming FHIR requests
2. Issue permission tickets (UMA Step 1)
3. Validate RPT tokens (UMA Step 3)
4. Extract permissions from JWT
5. Enforce instance-level access control

**Hook**: `@Hook(Pointcut.SERVER_INCOMING_REQUEST_PRE_HANDLED)`

**Main Methods**:

#### `handleRequest(RequestDetails theRequestDetails)`
Entry point for all requests. Decision tree:

```
Is public endpoint? (metadata, health)
├─→ Yes: Allow without authentication
└─→ No: Continue

Is POST (CREATE)?
├─→ Yes: Check RBAC
│   ├─→ Extract roles from token
│   ├─→ Check if role can create resource
│   └─→ Allow or Deny
└─→ No: Continue

Has Authorization header?
├─→ No: Issue permission ticket (UMA Step 1)
└─→ Yes: Validate token

Is token valid? (introspect with Keycloak)
├─→ No: Issue permission ticket
└─→ Yes: Extract permissions

Has required permission?
├─→ Yes: Allow request
└─→ No: Issue permission ticket
```

#### `requestPermissionTicket(RequestDetails theRequestDetails)`
Implements UMA Step 1 - Permission Ticket Issuance

**Process**:
1. Build permission request (resource ID + scopes)
2. Get Protection API token (client credentials)
3. POST to Keycloak Protection API:
   ```http
   POST /realms/FHIR-Auth/authz/protection/permission
   Authorization: Bearer <PROTECTION_TOKEN>
   Content-Type: application/json

   [{
     "resource_id": "abc-123-def",
     "resource_scopes": ["read"]
   }]
   ```
4. Extract permission ticket from response
5. Return ticket to caller

**Key Logic**:
```java
// Lookup resource UUID by name (e.g., "Patient/552")
String resourceUuid = lookupResourceUuid(resourceName);

// Build permission request
PermissionRequest request = new PermissionRequest(resourceUuid, scopes);

// Send to Keycloak
HttpPost post = new HttpPost(PERMISSION_ENDPOINT);
post.setHeader("Authorization", "Bearer " + protectionToken);
post.setEntity(new StringEntity(mapper.writeValueAsString([request])));

// Extract ticket
JsonNode response = mapper.readTree(responseBody);
String ticket = response.get("ticket").asText();
```

#### `isTokenValid(String token)`
Token introspection with Keycloak

**Process**:
```http
POST /realms/FHIR-Auth/protocol/openid-connect/token/introspect
Content-Type: application/x-www-form-urlencoded

client_id=fhir-client&
client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP&
token=<TOKEN>
```

**Response**:
```json
{
  "active": true,
  "sub": "5441cea9-...",
  "exp": 1705239844,
  "client_id": "fhir-client"
}
```

#### `extractPermissionsFromRPT(String token)`
Decodes JWT and extracts permissions (UMA Step 3)

**Process**:
1. Split JWT into parts: `header.payload.signature`
2. Base64URL decode payload
3. Parse JSON
4. Extract `authorization.permissions` array
5. Convert to RptPermission objects

**Example JWT Payload**:
```json
{
  "sub": "5441cea9-fcf2-419e-bc20-948c3c283c98",
  "exp": 1705239844,
  "iat": 1705239544,
  "authorization": {
    "permissions": [{
      "rsname": "Patient/552",
      "rsid": "abc-123-def-456",
      "scopes": ["read", "update"]
    }]
  }
}
```

**Key Code**:
```java
// Decode JWT payload (second part)
String[] parts = token.split("\\.");
String payload = new String(Base64.getUrlDecoder().decode(parts[1]));

// Parse JSON
ObjectMapper mapper = new ObjectMapper();
JsonNode payloadJson = mapper.readTree(payload);

// Extract permissions
JsonNode permissionsNode = payloadJson
    .get("authorization")
    .get("permissions");

// Convert to objects
for (JsonNode permNode : permissionsNode) {
    RptPermission permission = new RptPermission();
    permission.setRsname(permNode.get("rsname").asText());
    permission.setScopes(/* extract scopes array */);
    permissions.add(permission);
}
```

#### `hasRequiredPermission(String token, String resourceName, String requiredScope)`
Validates that token has permission for specific resource and scope

**Logic**:
```java
List<RptPermission> permissions = extractPermissionsFromRPT(token);

for (RptPermission permission : permissions) {
    // STRICT instance-level check
    if (resourceName.equals(permission.getRsname()) &&
        permission.getScopes().contains(requiredScope)) {
        return true;  // Match found
    }
}

return false;  // No matching permission
```

**Important**: Resource name must match **exactly**:
- ✅ Request: Patient/552, Permission: Patient/552 → Match
- ❌ Request: Patient/552, Permission: PatientResource → No match

This enforces **instance-level** permissions.

---

### 2. ResourceRegistrationInterceptor

**Purpose**: Automatically register FHIR resources in Keycloak on creation

**Key Responsibilities**:
1. Validate Patient uniqueness (one per Keycloak user)
2. Determine resource ownership
3. Register resource in Keycloak with owner
4. Grant creator permissions (if creator ≠ owner)

**Hooks**:
- `@Hook(Pointcut.STORAGE_PRESTORAGE_RESOURCE_CREATED)` - Validation
- `@Hook(Pointcut.STORAGE_PRECOMMIT_RESOURCE_CREATED)` - Registration

**Main Methods**:

#### `validatePatientUnique(IBaseResource theResource, RequestDetails theRequestDetails)`
Prevents duplicate Patient resources for same user

**Process**:
1. Extract keycloak-uuid from Patient.identifier
2. Search database for existing Patient with same UUID
3. If found → throw UnprocessableEntityException (422)
4. If not found → allow creation

**Why Important**: One patient cannot have multiple Patient resources - breaks ownership model

#### `resourceCreated(IBaseResource theResource, RequestDetails theRequestDetails)`
Main registration logic

**Process**:
```
1. Extract resource type and ID (e.g., "Patient", "552")
2. Extract creator ID from JWT token
3. Determine owner ID:
   ├─→ Patient: keycloak-uuid or system-placeholder
   └─→ Clinical resource: referenced patient's UUID
4. Register in Keycloak:
   keycloakResourceService.registerResource(type, id, ownerId)
5. Grant creator permissions (if creator ≠ owner):
   keycloakResourceService.grantCreatorPermissions(...)
```

#### `determineOwnerId(IBaseResource theResource, String creatorId)`
Determines who owns the resource

**Patient Resources**:
```java
if ("Patient".equals(resourceType)) {
    Patient patient = (Patient) theResource;

    // Check for keycloak-uuid identifier
    for (Identifier id : patient.getIdentifier()) {
        if ("keycloak-uuid".equals(id.getSystem())) {
            return id.getValue();  // Patient owns themselves
        }
    }

    // No Keycloak link → system owner
    return keycloakResourceService.getSystemOwnerId();
}
```

**Clinical Resources**:
```java
if ("Condition".equals(resourceType)) {
    Condition condition = (Condition) theResource;

    // Extract patient reference (e.g., "Patient/552")
    String patientRef = condition.getSubject().getReference();
    String patientId = extractIdFromReference(patientRef);

    // Look up patient's Keycloak ID from database
    String patientKeycloakId = keycloakResourceService
        .getPatientKeycloakId(patientId);

    return patientKeycloakId;  // Owner is the patient
}
```

---

### 3. KeycloakResourceService

**Purpose**: Interface with Keycloak Admin API for resource management

**Key Responsibilities**:
1. Register UMA resources
2. Create and manage policies
3. Grant permissions to users
4. Look up patient Keycloak IDs

**Dependencies**:
- Keycloak Admin Client (`org.keycloak:keycloak-admin-client`)
- RESTEasy Client for HTTP communication

**Main Methods**:

#### `registerResource(String resourceType, String resourceId, String ownerId)`
Registers a FHIR resource in Keycloak

**Process**:
```java
// 1. Create ResourceRepresentation
ResourceRepresentation resource = new ResourceRepresentation();
resource.setName(resourceType + "/" + resourceId);  // "Patient/552"
resource.setType(resourceType);
resource.setOwner(new ResourceOwnerRepresentation(ownerId));
resource.setOwnerManagedAccess(true);  // Enable UMA

// 2. Define scopes
Set<ScopeRepresentation> scopes = Set.of(
    new ScopeRepresentation("read"),
    new ScopeRepresentation("write"),
    new ScopeRepresentation("delete")
);
resource.setScopes(scopes);

// 3. Register via Admin API
AuthzClient authzClient = getAuthzClient();
ResourceResource resourceEndpoint = authzClient
    .protection()
    .resource();

resourceEndpoint.create(resource);
```

**Result**: Resource registered in Keycloak with:
- Name: Patient/552
- Owner: 5441cea9-fcf2-419e-bc20-948c3c283c98 (Alice)
- Scopes: read, write, delete
- Owner-managed access: enabled

#### `grantCreatorPermissions(String resourceType, String resourceId, String creatorId, String ownerId)`
Grants read/write permissions to resource creator

**Why Needed**: Doctor creates Condition for Alice. Alice is owner (via Owner Policy), but doctor needs access too.

**Process**:
```java
// 1. Create user-based policy for creator
PolicyRepresentation policy = new PolicyRepresentation();
policy.setName(resourceType + "_" + resourceId + "_creator");
policy.setType("user");
policy.setUsers(Set.of(creatorId));

// 2. Create permission linking policy to resource
PermissionRepresentation permission = new PermissionRepresentation();
permission.setName(resourceType + "_" + resourceId + "_creator_perm");
permission.setResources(Set.of(resourceId));
permission.setScopes(Set.of("read", "write"));  // Not delete!
permission.addPolicy(policy.getName());

// 3. Register via Admin API
authzClient.authorization().policies().create(policy);
authzClient.authorization().permissions().create(permission);
```

**Result**: Dr. Bob can read and write Condition/554, but cannot delete it (only Alice can delete).

#### `getPatientKeycloakId(String patientId)`
Looks up patient's Keycloak UUID from FHIR database

**Process**:
```java
// 1. Query FHIR database for Patient resource
Patient patient = patientDao.read(new IdType("Patient", patientId));

// 2. Extract keycloak-uuid identifier
for (Identifier id : patient.getIdentifier()) {
    if ("keycloak-uuid".equals(id.getSystem())) {
        return id.getValue();
    }
}

return null;  // Patient not linked to Keycloak
```

**Why Needed**: When registering Condition/554 → need to find Patient/552 → extract Alice's UUID → set as owner

---

## JWT Token Structure

### Access Token (User Token)

Issued by Keycloak for authenticated users.

**Structure**:
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "abc123"
  },
  "payload": {
    "sub": "5441cea9-fcf2-419e-bc20-948c3c283c98",
    "preferred_username": "alice",
    "email": "alice@example.com",
    "realm_access": {
      "roles": ["Patient", "offline_access"]
    },
    "exp": 1705239844,
    "iat": 1705239544,
    "iss": "http://localhost:8080/realms/FHIR-Auth"
  },
  "signature": "..."
}
```

**Used For**:
- Authentication
- Subject token in RPT exchange (UMA Step 2)
- Extracting user roles (RBAC)

### RPT (Requesting Party Token)

Issued by Keycloak after UMA policy evaluation.

**Structure**:
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "abc123"
  },
  "payload": {
    "sub": "5441cea9-fcf2-419e-bc20-948c3c283c98",
    "authorization": {
      "permissions": [
        {
          "rsname": "Patient/552",
          "rsid": "abc-123-def-456",
          "scopes": ["read", "update", "delete"]
        },
        {
          "rsname": "Condition/554",
          "rsid": "def-456-ghi-789",
          "scopes": ["read", "update"]
        }
      ]
    },
    "exp": 1705239844,
    "iat": 1705239544,
    "iss": "http://localhost:8080/realms/FHIR-Auth"
  },
  "signature": "..."
}
```

**Key Difference**: Contains `authorization.permissions` array with granted permissions.

**Used For**:
- Accessing protected FHIR resources
- Instance-level permission validation

---

## Permission Extraction and Validation

### Extraction Process

```java
// 1. Decode JWT
String[] parts = token.split("\\.");  // Split header.payload.signature
String payload = new String(Base64.getUrlDecoder().decode(parts[1]));

// 2. Parse JSON
JsonNode payloadJson = new ObjectMapper().readTree(payload);

// 3. Navigate to permissions
JsonNode permissionsNode = payloadJson
    .get("authorization")
    .get("permissions");

// 4. Extract each permission
List<RptPermission> permissions = new ArrayList<>();
for (JsonNode permNode : permissionsNode) {
    RptPermission perm = new RptPermission();
    perm.setRsname(permNode.get("rsname").asText());
    perm.setRsid(permNode.get("rsid").asText());

    // Extract scopes array
    List<String> scopes = new ArrayList<>();
    for (JsonNode scopeNode : permNode.get("scopes")) {
        scopes.add(scopeNode.asText());
    }
    perm.setScopes(scopes);

    permissions.add(perm);
}
```

### Validation Logic

**Request**: GET /fhir/Patient/552

**Required**:
- Resource name: "Patient/552"
- Scope: "read"

**Validation**:
```java
boolean hasPermission = false;

for (RptPermission permission : permissions) {
    // Check resource name (exact match)
    if ("Patient/552".equals(permission.getRsname())) {
        // Check scope
        if (permission.getScopes().contains("read")) {
            hasPermission = true;
            break;
        }
    }
}

if (!hasPermission) {
    // Issue new permission ticket
    handleTokenlessAccess(theRequestDetails);
}
```

**Why Strict Matching**: Enforces instance-level permissions
- Token with "PatientResource" permission → Cannot access "Patient/552"
- Token must explicitly have "Patient/552" permission

---

## Implementation Highlights

### 1. Extra Hosts Configuration

**Problem**: Keycloak issues tokens with `iss: localhost:8080`, but FHIR server runs in Docker and connects via `keycloak:8080`.

**Impact**: Token introspection fails because issuer doesn't match.

**Solution**: Add `extra_hosts` in docker-compose.yml
```yaml
hapi-fhir-jpaserver:
  extra_hosts:
    - "localhost:host-gateway"
```

**Result**: FHIR server can reach Keycloak via `localhost:8080`, matching token issuer.

### 2. Permission Ticket Format

**Standard UMA**: Single resource per ticket
```json
{
  "resource_id": "abc-123",
  "resource_scopes": ["read"]
}
```

**Keycloak**: Expects array
```json
[{
  "resource_id": "abc-123",
  "resource_scopes": ["read"]
}]
```

**Solution**: Wrap single request in array
```java
PermissionRequest request = new PermissionRequest(resourceUuid, scopes);
PermissionRequest[] requestArray = new PermissionRequest[]{request};
String requestBody = mapper.writeValueAsString(requestArray);
```

### 3. Resource UUID Lookup

**Problem**: Permission ticket requires resource UUID, not name

**Example**:
- Resource name: "Patient/552"
- Resource UUID: "abc-123-def-456"

**Solution**: Lookup UUID before requesting ticket
```java
String resourceUuid = lookupResourceUuid("Patient/552");

// HTTP GET to Keycloak
GET /authz/protection/resource_set?name=Patient/552

// Response: ["abc-123-def-456"]
String uuid = jsonResponse.get(0).asText();
```

### 4. Owner Policy JAR Deployment

**Challenge**: Custom JavaScript policies must be packaged as JAR and deployed to Keycloak

**Solution**:
1. Create JavaScript file: `owner-policy.js`
2. Create JAR structure:
   ```
   keycloak-owner-policy.jar
   └── META-INF/
       └── keycloak-scripts.json
   ```
3. keycloak-scripts.json:
   ```json
   {
     "policies": [{
       "name": "Owner Policy",
       "fileName": "owner-policy.js",
       "description": "Grants access to resource owners"
     }]
   }
   ```
4. Package with Maven or manually
5. Mount in Docker: `/opt/keycloak/providers/keycloak-owner-policy.jar`
6. Keycloak auto-loads on startup

### 5. RBAC Token Extraction

**Challenge**: Roles are in JWT payload, not introspection response

**Solution**: Decode JWT and extract `realm_access.roles`
```java
JsonNode payloadJson = /* decode JWT */;
JsonNode realmAccess = payloadJson.get("realm_access");
JsonNode rolesNode = realmAccess.get("roles");

List<String> roles = new ArrayList<>();
for (JsonNode roleNode : rolesNode) {
    roles.add(roleNode.asText());
}
```

### 6. Duplicate Prevention

**Challenge**: Prevent multiple Patient resources for same Keycloak user

**Solution**: PRESTORAGE hook validates uniqueness
```java
@Hook(Pointcut.STORAGE_PRESTORAGE_RESOURCE_CREATED)
public void validatePatientUnique(IBaseResource theResource, ...) {
    if (!"Patient".equals(theResource.fhirType())) return;

    String keycloakId = extractKeycloakIdFromPatient((Patient) theResource);
    if (keycloakId == null) return;

    Patient existing = findPatientByKeycloakId(keycloakId);
    if (existing != null) {
        throw new UnprocessableEntityException(
            "Patient already exists for this user"
        );
    }
}
```

---

## Summary

The UMA implementation provides:

1. **Complete UMA 2.0 Flow**: 3-step flow with permission tickets and RPTs
2. **Instance-Level Permissions**: Fine-grained access control (Patient/552)
3. **Automatic Registration**: Resources registered in Keycloak on creation
4. **Owner Policy**: Patients automatically own their data
5. **Creator Permissions**: Doctors get access to records they create
6. **RBAC Integration**: Role-based creation authorization
7. **JWT-Based**: Permissions embedded in tokens, no database lookups

This implementation demonstrates mastery of:
- UMA 2.0 protocol
- OAuth 2.0 and JWT
- Keycloak Administration
- HAPI FHIR interceptors
- Spring Boot integration
- Policy-based authorization

---

**Next Steps**: Read **[4-Keycloak-Configuration.md](4-Keycloak-Configuration.md)** for Keycloak setup and configuration details.

---

**Last Updated**: January 2026
