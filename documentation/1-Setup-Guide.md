# 1. Setup Guide

## Prerequisites

- **Docker Desktop** (with Docker Compose)
- **Available ports**: 5432, 5433, 8080, 8081

---

## Installation

### Step 1: Start Services

```bash
cd uma-inno/hapi-jpa
docker-compose up -d
```

This starts:
- **Keycloak** on port 8080 (Authorization Server)
- **HAPI FHIR Server** on port 8081
- **PostgreSQL** on ports 5432 (FHIR) and 5433 (Keycloak)

### Step 2: Wait for Startup

Services need ~60 seconds to fully start. Check status:

```bash
docker-compose ps
```

All services should show "Up" or "healthy".

### Step 3: Create Test Data

```bash
cd ../keycloak-config
./create-fhir-resources.sh
./create-test-permissions.sh
```

This creates test patients (Alice, Jan) with clinical data and grants doctors access permissions.

---

## Verification

### Check FHIR Server
```bash
curl http://localhost:8081/fhir/metadata
```
**Expected:** JSON CapabilityStatement response

### Check Keycloak
Open http://localhost:8080 and login with `admin` / `admin`

### Test UMA Flow
```bash
curl -i http://localhost:8081/fhir/Patient
```
**Expected:** 401 response with `WWW-Authenticate: UMA` header containing a permission ticket

---

## Development

### Run Locally (without Docker)
```bash
cd hapi-jpa
mvn clean spring-boot:run
```

### Build WAR
```bash
mvn clean package -DskipTests
```

### View Logs
```bash
docker-compose logs -f hapi-fhir-jpaserver-start
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `hapi-jpa/docker-compose.yml` | Docker service definitions |
| `hapi-jpa/src/main/resources/application.yaml` | FHIR server configuration |
| `keycloak-config/keycloak-files/fhir-auth-full.json` | Keycloak realm export |

---

## Next Steps

1. Read [2-Technical-Overview.md](2-Technical-Overview.md) to understand the architecture
2. Use [curl-testing-commands.md](../keycloak-config/curl-testing-commands.md) to test the UMA flow
3. Refer to [4-API-Reference.md](4-API-Reference.md) for API details
