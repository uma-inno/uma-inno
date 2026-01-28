# 3. Keycloak Configuration

## Access

- **URL**: http://localhost:8080
- **Admin**: admin / admin
- **Realm**: FHIR-Auth
- **Client**: fhir-client
- **Client Secret**: `QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP`

---

## Test Users

| Username | Password | Role | FHIR Resource |
|----------|----------|------|---------------|
| alice | alice123 | Patient | Patient/1 |
| jan | jan123 | Patient | Patient/2 |
| dr.smith | smith123 | Doctor | - |
| dr.bob | bob123 | Doctor | - |

### Get User Token
```bash
curl -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "username=alice" \
  -d "password=alice123"
```

---

## Roles

| Role | Permissions |
|------|-------------|
| **Patient** | Read/update own data only |
| **Doctor** | Create resources, read granted resources |
| **Administrator** | Full access to all resources |

---

## Policies

The system uses these authorization policies:

| Policy | Type | Description |
|--------|------|-------------|
| Patient Access Policy | Role | Users with Patient role |
| Doctor Access Policy | Role | Users with Doctor role |
| Owner Policy | JavaScript | Auto-grants access to resource owners |

---

## Setup Methods

### Method 1: Auto Import (Default)

The realm is automatically imported from `keycloak-config/keycloak-files/fhir-auth-full.json` when Docker starts.

After startup, run the scripts to create test data:
```bash
cd keycloak-config
./create-fhir-resources.sh
./create-test-permissions.sh
```

### Method 2: Manual Setup

If you need to set up from scratch:

1. Create realm "FHIR-Auth"
2. Import `keycloak-config/users-import.json` (Users + Roles)
3. Import `keycloak-config/fhir-client.json` (Client configuration)
4. Run the test data scripts

---

## Owner Policy JAR

Custom JavaScript policy that grants owners automatic access to their resources.

**Deployment**: Mounted via Docker:
```yaml
volumes:
  - ../keycloak-policies/keycloak-owner-policy.jar:/opt/keycloak/providers/keycloak-owner-policy.jar
```

**Verification**: Go to Clients → fhir-client → Authorization → Policies and check if "Owner Policy" exists.

---

## Service Account Roles

The fhir-client service account needs these realm-management roles:
- `view-users`
- `manage-users`
- `manage-authorization`
- `view-realm`

(Already configured in the import files)
