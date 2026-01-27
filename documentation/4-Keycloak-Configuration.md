# 4. Keycloak Configuration

**Complete Keycloak setup and configuration guide for UMA 2.0 authorization**

---

## Table of Contents

1. [Keycloak Overview](#keycloak-overview)
2. [Realm Configuration](#realm-configuration)
3. [Client Configuration](#client-configuration)
4. [Roles Setup](#roles-setup)
5. [Policies Configuration](#policies-configuration)
6. [Permissions Setup](#permissions-setup)
7. [Test Users](#test-users)
8. [Owner Policy JAR](#owner-policy-jar)

---

## Keycloak Overview

**Keycloak** is an open-source Identity and Access Management (IAM) solution that provides:
- User authentication (OAuth 2.0, OpenID Connect)
- Authorization Services (UMA 2.0)
- Policy-based access control
- Single Sign-On (SSO)

**Our Configuration**:
- **URL**: http://localhost:8080
- **Admin Credentials**: admin / admin
- **Realm**: FHIR-Auth
- **Client**: fhir-client

---

## Realm Configuration

### What is a Realm?

A **realm** is an isolated administrative domain in Keycloak that manages:
- Users
- Applications (clients)
- Roles
- Authorization policies

### FHIR-Auth Realm

**Configuration Export**: `keycloak config/fhir-auth-config.json`

> **Note**: A full realm export exists at `keycloak-config/keycloak-files/fhir-auth-full.json`. However, due to conflicts with default clients (like `account-console`) and issues with importing user-specific UMA policies (which require the resource owner to exist first), we use the **Manual Setup** method below to ensure a reliable deployment.

**Key Settings**:
```json
{
  "realm": "FHIR-Auth",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": false,
  "loginWithEmailAllowed": true,
  "duplicateEmailsAllowed": false,
  "resetPasswordAllowed": true
}
```

### Creating the Realm (Manual Setup)

Since we have removed the automatic realm import to avoid conflicts, follow these steps to set up Keycloak:

#### Step 1: Create the Realm
1. **Open Keycloak Admin Console**: http://localhost:8080
2. **Login**: admin / admin
3. **Hover over "master"** dropdown (top-left)
4. **Click "Create Realm"**
5. **Configuration**:
   - Realm name: `FHIR-Auth`
   - Enabled: ON
6. **Click "Create"**

#### Step 2: Import Users
1. Ensure you are in the **FHIR-Auth** realm.
2. Go to **Realm Settings** (left menu). On the **General** tab (default), locate the **Action** dropdown menu (top right) and select **Partial Import**.
3. Click **Browse** and select `keycloak-config/users-import.json`.
4. **Select Resources to Import**:
   - Check **Import Users**
   - Check **Import Realm Roles**
5. **Import Strategy**: Select **Skip**.
6. Click **Import**.

#### Step 3: Import Client Configuration
1. Remain in **Realm Settings** -> **Action** (top right) -> **Partial Import**.
2. Click **Browse** and select `keycloak-config/fhir-client.json`.
3. **Select Resources to Import**:
   - Check **Import Clients**
   - Check **Import Client Roles**
4. **Import Strategy**: Select **Skip** (or Overwrite if updating).
5. Click **Import**.

Now you have the users (`alice`, `dr.bob`, etc.) and the `fhir-client` with most authorization settings.

#### Step 4: Manually Add User-Specific Permissions
The following policies must be recreated manually because they reference specific resource IDs that might change or need explicit linking:

1. **Dr. Bob read access Condition/554**
   - Resource: `Condition/554`
   - Scope: `read`
   - Policy: `Dr. Bob User Policy`

2. **Dr. Smith access to Patient/552**
   - Resource: `Patient/552`
   - Scope: `read`
   - Policy: `Dr Smith User Policy`

3. **Dr. Smith access to AllergyIntolerance/555**
   - Resource: `AllergyIntolerance/555`
   - Scope: `read`
   - Policy: `Dr Smith User Policy`

**Navigate**: Clients -> fhir-client -> Authorization -> policies

**1. Create Specific Scope Policies (if they don't exist):**

*   **Dr. Bob read access Condition/554**
    *   **Type**: Scope
    *   **Resources**: `Condition/554`
    *   **Scopes**: `read`
    *   **Apply Policy**: `Dr. Bob User Policy`

*   **Dr. Smith access to Patient/552**
    *   **Type**: Scope
    *   **Resources**: `Patient/552`
    *   **Scopes**: `read`
    *   **Apply Policy**: `Dr Smith User Policy`

*   **Dr. Smith access to AllergyIntolerance/555**
    *   **Type**: Scope
    *   **Resources**: `AllergyIntolerance/555`
    *   **Scopes**: `read`
    *   **Apply Policy**: `Dr Smith User Policy`

**Verify**: Go to the **Permissions** tab and ensure these new policies are listed and active.

---

## Client Configuration

### What is a Client?

A **client** represents an application that wants to use Keycloak for authentication and authorization.

### fhir-client Configuration

**Client Settings**:

| Setting | Value |
|---------|-------|
| **Client ID** | fhir-client |
| **Client Protocol** | openid-connect |
| **Access Type** | confidential |
| **Service Accounts Enabled** | ON |
| **Authorization Enabled** | ON |
| **Standard Flow Enabled** | ON |
| **Direct Access Grants Enabled** | ON |

**Client Secret**: `QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP`

**Authorization Settings**:
- **Policy Enforcement Mode**: ENFORCING
- **Decision Strategy**: Affirmative
- **Allow Remote Resource Management**: ON

### Service Account Roles

The `fhir-client` service account needs these roles for Protection API access:

**Realm Management Client Roles**:
- `view-users`
- `manage-users`
- `manage-authorization`
- `view-realm`

**Setup**:
1. Go to Clients → fhir-client → Service Account Roles
2. Select "realm-management" from Client Roles dropdown
3. Add the roles listed above

---

## Roles Setup

### Role Hierarchy

```
FHIR-Auth Realm
│
├── Patient (Standard user)
│   ├─→ Read own data
│   ├─→ Update own data
│   └─→ Cannot create/delete
│
├── Doctor (Healthcare provider)
│   ├─→ Create Patient/Clinical resources
│   ├─→ Read assigned data
│   ├─→ Update assigned data
│   └─→ Cannot delete patients
│
└── Administrator (System admin)
    ├─→ Full CRUD on all resources
    ├─→ Manage permissions
    └─→ System configuration
```

### Creating Roles

**Navigate**: Realm roles → Create role

#### 1. Patient Role

```
Name: Patient
Description: Standard patient user who can access their own health data
```

#### 2. Doctor Role

```
Name: Doctor
Description: Healthcare provider who can access patient data with permission
```

#### 3. Administrator Role

```
Name: Administrator
Description: System administrator with full access to all resources
```

**Verification**: You should see 3 roles in Realm roles list

---

## Policies Configuration

### Policy Types

**1. Role-Based Policies**
- Match users by their realm role
- Example: "User has Patient role"

**2. Aggregated Policies**
- Combine multiple policies
- Example: "Patient OR Admin"

**3. JavaScript Policies**
- Custom logic via JavaScript
- Example: Owner Policy (deployed as JAR)

**4. User-Based Policies**
- Match specific users
- Example: "User is Alice"

### Creating Policies

**Navigate**: Clients → fhir-client → Authorization → Policies

#### Role-Based Policies

**1. Patient Access Policy**
```
Type: Role
Name: Patient Access Policy
Description: Policy for users with Patient role
Realm Roles: [Patient]
Logic: Positive
```

**2. Doctor Access Policy**
```
Type: Role
Name: Doctor Access Policy
Description: Policy for users with Doctor role
Realm Roles: [Doctor]
Logic: Positive
```

**3. Administrator Access Policy**
```
Type: Role
Name: Administrator Access Policy
Description: Policy for administrators with full access
Realm Roles: [Administrator]
Logic: Positive
```

#### Aggregated Policies

**1. Patient or Admin Access**
```
Type: Aggregated
Name: Patient or Admin Access
Description: Allows patients to access their own data or admins to access all
Apply Policy: [Patient Access Policy, Administrator Access Policy]
Decision Strategy: Affirmative
```

**2. Doctor or Admin Access**
```
Type: Aggregated
Name: Doctor or Admin Access
Description: Allows doctors and admins to access patient data
Apply Policy: [Doctor Access Policy, Administrator Access Policy]
Decision Strategy: Affirmative
```

**Result**: 5 policies total (3 role-based + 2 aggregated)

---

## Permissions Setup

### Permission Types

**Scope-Based Permission**: Links policies to resource scopes (read, write, delete)

**Resource-Based Permission**: Links policies to specific resources

### Creating Permissions

**Navigate**: Clients → fhir-client → Authorization → Permissions

#### PatientResource Permissions

**1. Patient Read Own Data**
```
Type: Scope-based permission
Name: Patient Read Own Data
Description: Patients can read their own Patient resource
Resources: PatientResource
Scopes: read
Apply Policy: Patient or Admin Access
Decision Strategy: Affirmative
```

**2. Patient Write Own Data**
```
Name: Patient Write Own Data
Description: Patients can update their own Patient resource
Resources: PatientResource
Scopes: update
Apply Policy: Patient or Admin Access
```

**3. Doctor Read Patient Data**
```
Name: Doctor Read Patient Data
Description: Doctors can read Patient resources with permission
Resources: PatientResource
Scopes: read
Apply Policy: Doctor or Admin Access
```

**4. Admin Full Patient Access**
```
Name: Admin Full Patient Access
Description: Administrators have full access to Patient resources
Resources: PatientResource
Scopes: read, create, update, delete
Apply Policy: Administrator Access Policy
```

#### ConditionResource Permissions

**1. Patient Read Own Conditions**
```
Resources: ConditionResource
Scopes: read
Apply Policy: Patient or Admin Access
```

**2. Doctor Manage Conditions**
```
Resources: ConditionResource
Scopes: read, create, update
Apply Policy: Doctor or Admin Access
```

**3. Admin Full Condition Access**
```
Resources: ConditionResource
Scopes: read, create, update, delete
Apply Policy: Administrator Access Policy
```

#### AllergyIntoleranceResource Permissions

Same pattern as ConditionResource (3 permissions)

#### MedicationStatementResource Permissions

Same pattern as ConditionResource (3 permissions)

**Total Permissions**: 13+ (4 for Patient + 3 each for other resources)

---

## Test Users

### User Configuration

**Navigate**: Users → Create user

#### 1. Alice (Patient)

**User Details**:
```
Username: alice
Email: alice@example.com
First Name: Alice
Last Name: Smith
Enabled: ON
```

**Credentials**:
```
Password: alice123
Temporary: OFF
```

**Role Mapping**:
- Realm roles: Patient

**Keycloak UUID**: `5441cea9-fcf2-419e-bc20-948c3c283c98`

**Associated FHIR Resource**: Patient/552

#### 2. Dr. Bob (Doctor)

**User Details**:
```
Username: dr.bob
Email: bob@hospital.com
First Name: Bob
Last Name: Johnson
Enabled: ON
```

**Credentials**:
```
Password: bob123
Temporary: OFF
```

**Role Mapping**:
- Realm roles: Doctor

**Keycloak UUID**: `97503f80-1f4f-4ae6-8b58-eb50a082acf9`

#### 3. Jan (Administrator)

**User Details**:
```
Username: jan
Email: jan@admin.com
First Name: Jan
Last Name: Admin
Enabled: ON
```

**Credentials**:
```
Password: jan123
Temporary: OFF
```

**Role Mapping**:
- Realm roles: Administrator

**Keycloak UUID**: `df11bc00-e0e6-4924-941d-3627fdd16992`

#### 4. System Placeholder

**Purpose**: Owns resources for patients without Keycloak accounts

**Keycloak UUID**: `7fc0d4bd-40ca-483e-9530-6e1fe84bded3`

**Note**: This is not a real user, just a UUID configured in `application.yaml`

### Getting User Tokens

**Alice's Token**:
```bash
curl -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "username=alice" \
  -d "password=alice123"
```

**Response**:
```json
{
  "access_token": "eyJhbGciOi...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "token_type": "Bearer"
}
```

**Extract Token**: Copy `access_token` value

---

## Owner Policy JAR

### What is the Owner Policy?

Custom JavaScript policy that automatically grants full access to resource owners.

**JavaScript Code** (`keycloak-policies/owner-policy.js`):
```javascript
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

**How it Works**:
1. Policy evaluator receives permission request
2. Extract resource owner from Keycloak resource
3. Extract user ID from token
4. Compare: owner == user ID?
5. If yes → Grant access automatically

**Benefits**:
- No need to create explicit owner permissions
- Patients automatically access their own data
- Scales to thousands of resources without performance impact

### JAR Structure

```
keycloak-owner-policy.jar
├── META-INF/
│   ├── MANIFEST.MF
│   └── keycloak-scripts.json
└── owner-policy.js
```

**keycloak-scripts.json**:
```json
{
  "policies": [{
    "name": "Owner Policy",
    "fileName": "owner-policy.js",
    "description": "Grants access to resource owners automatically"
  }]
}
```

### Deployment

**Via Docker** (current method):
```yaml
# docker-compose.yml
keycloak:
  volumes:
    - ../keycloak-policies/keycloak-owner-policy.jar:/opt/keycloak/providers/keycloak-owner-policy.jar
```

### Method 1: Automated Full Import (Recommended)

This method uses the single `fhir-auth-full.json` file (exported from a working environment) which contains the entire realm configuration, including users, clients, and policies.

#### Prerequisite
1.  Copy the `fhir-auth-full.json` file to your `keycloak-config` folder on the new machine.

#### Steps

1.  **Configure Docker Compose**:
    Open `hapi-jpa/docker-compose.yml` and ensure the `keycloak` service has the import volume mounted and the `--import-realm` flag set:

    ```yaml
    keycloak:
      # ...
      command: start-dev --features=preview --import-realm
      volumes:
        - ../keycloak-config:/opt/keycloak/data/import
    ```
    *Note: Ensure the volume path matches your actual folder name (e.g., `../keycloak-config` or `../keycloak config`).*

2.  **Start the Container**:
    Run `docker-compose up -d`.

    Keycloak will detect the file in the import folder and automatically create the `FHIR-Auth` realm with all users and permissions fully restored.

---

### Method 2: Manual Setup (Fallback)
If you need to configure Keycloak from scratch without an export file, follow these manual steps:
1. Copy JAR to Keycloak providers directory:
   ```bash
   cp keycloak-owner-policy.jar /opt/keycloak/providers/
   ```
2. Restart Keycloak:
   ```bash
   docker-compose restart keycloak
   ```

**Verification**:
1. Go to Clients → fhir-client → Authorization → Policies
2. Click "Create policy" → Check if "JavaScript" type is available
3. If available, JAR loaded successfully

### Using Owner Policy

**Create JavaScript Policy in Keycloak**:
1. Go to Policies → Create policy → JavaScript
2. Configure:
   ```
   Name: Resource Owner Policy
   Code: (paste owner-policy.js content)
   ```
3. Click Save

**Link to Permission**:
1. Go to Permissions → Create permission
2. Select resource
3. Apply Policy: Resource Owner Policy
4. Save

**Result**: Resource owners automatically granted access without explicit permission entries

---

## Configuration Verification

### Checklist

- [ ] Realm "FHIR-Auth" exists
- [ ] Client "fhir-client" configured with Authorization enabled
- [ ] Service account has required roles (manage-authorization, etc.)
- [ ] 3 Realm roles created (Patient, Doctor, Administrator)
- [ ] 5 Policies created (3 role-based + 2 aggregated)
- [ ] 13+ Permissions created (4 for Patient + 3 each for others)
- [ ] 3 Test users created with correct roles
- [ ] Owner Policy JAR deployed and loaded
- [ ] Resources registered (PatientResource, ConditionResource, etc.)

### Testing Configuration

**Test 1: Get Alice's Token**
```bash
curl -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "username=alice" \
  -d "password=alice123"
```

**Expected**: Access token returned

**Test 2: Verify Roles in Token**
```bash
# Decode JWT payload (use jwt.io)
# Check: realm_access.roles contains ["Patient"]
```

**Test 3: Policy Evaluation**
1. Go to Clients → fhir-client → Authorization → Evaluate
2. Select User: alice
3. Select Resource: PatientResource
4. Select Scope: read
5. Click "Evaluate"
6. **Expected**: PERMIT (Patient Access Policy grants access)

---

## Summary

Keycloak configuration provides:

1. **Realm**: FHIR-Auth for all FHIR-related authentication/authorization
2. **Client**: fhir-client with Authorization Services enabled
3. **Roles**: Patient, Doctor, Administrator with different permission levels
4. **Policies**: 5 policies (role-based + aggregated) for flexible access control
5. **Permissions**: 13+ permissions linking policies to resources and scopes
6. **Test Users**: Alice (patient), Dr. Bob (doctor), Jan (admin)
7. **Owner Policy**: Custom JavaScript policy for automatic owner access

This configuration enables:
- Patient-centric access control
- Role-based authorization
- Dynamic permission evaluation
- Instance-level permissions
- UMA 2.0 compliance

---

**Next Steps**: Use the testing guide located at `hapi-jpa/testing/curl-testing-commands.md` to verify the complete system.

---

**Last Updated**: January 2026
