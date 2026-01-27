# 1. Setup Guide

**Complete installation and configuration guide for the UMA 2.0 Protected FHIR Server**

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start (Docker)](#quick-start-docker)
3. [Detailed Installation](#detailed-installation)
4. [First Run and Verification](#first-run-and-verification)
5. [Development Setup](#development-setup)
6. [Troubleshooting](#troubleshooting)

---


### Required Software

#### 1. Docker

**Required for running the complete system** (Keycloak + PostgreSQL + FHIR Server)


---

## Quick Start (Docker)

**Get the system running in 5 minutes:**

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd uma-inno/hapi-jpa
```

### Step 2: Start All Services

```bash
docker-compose up -d
```

This starts:
- Keycloak (Authorization Server) on port 8080
- PostgreSQL (Keycloak DB) on port 5433
- PostgreSQL (FHIR DB) on port 5432
- HAPI FHIR Server on port 8081


### Step 3: Wait for Services to be Ready

Services need ~30-60 seconds to fully start. Check status:

```bash
docker-compose ps
```

**All services should show "healthy" or "running":**
```
NAME                               STATUS
hapi-jpa-hapi-fhir-jpaserver-1    Up
hapi-jpa-hapi-fhir-postgres-1     Up (healthy)
hapi-jpa-keycloak-1               Up
hapi-jpa-keycloak-postgres-1      Up (healthy)
```

### Step 4: Verify Installation

**Check FHIR Server:**
```bash
curl http://localhost:8081/fhir/metadata
```

**Expected:** JSON response with CapabilityStatement (FHIR metadata)

**Check Keycloak:**

Open browser: http://localhost:8080

**Expected:** Keycloak login page

---

## Detailed Installation

### Configuration Files

#### docker-compose.yml

Location: `uma-inno/hapi-jpa/docker-compose.yml`

Key configurations:

**Keycloak PostgreSQL:**
```yaml
keycloak-postgres:
  image: postgres:15-alpine
  ports:
    - "5433:5432"
  environment:
    POSTGRES_DB: keycloak
    POSTGRES_USER: keycloak
    POSTGRES_PASSWORD: keycloak
```

**Keycloak:**
```yaml
keycloak:
  image: quay.io/keycloak/keycloak:latest
  ports:
    - "8080:8080"
  environment:
    KC_DB: postgres
    KC_DB_URL: jdbc:postgresql://keycloak-postgres:5432/keycloak
    KEYCLOAK_ADMIN: admin
    KEYCLOAK_ADMIN_PASSWORD: admin
  volumes:
    - ../keycloak config:/opt/keycloak/data/import
    - ../keycloak-policies/keycloak-owner-policy.jar:/opt/keycloak/providers/keycloak-owner-policy.jar
```

**HAPI FHIR PostgreSQL:**
```yaml
hapi-fhir-postgres:
  image: postgres:15-alpine
  ports:
    - "5432:5432"
  environment:
    POSTGRES_DB: hapi
    POSTGRES_USER: admin
    POSTGRES_PASSWORD: admin
```

**HAPI FHIR Server:**
```yaml
hapi-fhir-jpaserver-start:
  build: .
  ports:
    - "8081:8080"
  environment:
    spring.datasource.url: 'jdbc:postgresql://hapi-fhir-postgres:5432/hapi'
    spring.datasource.username: admin
    spring.datasource.password: admin
  extra_hosts:
    - "localhost:host-gateway"  # Critical for UMA token introspection
```

#### application.yaml

Location: `uma-inno/hapi-jpa/src/main/resources/application.yaml`

Key configurations:

```yaml
server:
  port: 8081

spring:
  datasource:
    url: 'jdbc:postgresql://localhost:5432/hapi'
    username: admin
    password: admin
    driverClassName: org.postgresql.Driver

hapi:
  fhir:
    fhir_version: R5
    custom-interceptor-classes:
      - ca.uhn.fhir.jpa.starter.interceptors.JpaEntityTrackingInterceptor
      - ca.uhn.fhir.jpa.starter.interceptors.UmaKeycloakAuthInterceptor
      - ca.uhn.fhir.jpa.starter.interceptors.ResourceRegistrationInterceptor

keycloak:
  auth-server-url: "http://localhost:8080"
  realm: "FHIR-Auth"
  resource: "fhir-client"
  system-owner-id: "7fc0d4bd-40ca-483e-9530-6e1fe84bded3"
```

### Step-by-Step Installation

#### 1. Clone Repository

```bash
git clone <repository-url>
cd uma-inno
```

#### 2. Verify Docker is Running

```bash
docker info
```

If this fails, start Docker Desktop and wait for it to be fully running.

#### 3. Navigate to hapi-jpa Directory

```bash
cd hapi-jpa
```

#### 4. Build Docker Images

**First time only** or after code changes:

```bash
docker-compose build
```


#### 5. Start Services

```bash
docker-compose up -d
```



#### 6. Monitor Startup

**View logs for all services:**
```bash
docker-compose logs -f
```


**View logs for specific service:**
```bash
docker-compose logs -f hapi-fhir-jpaserver-start
```



---



### 3. Test Keycloak Access

**Browser:**
Open http://localhost:8080

**Expected:** Keycloak welcome page

**Login to Admin Console:**
- Click "Administration Console"
- Username: `admin`
- Password: `admin`

**Expected:** Keycloak Admin Console dashboard

**Verify FHIR-Auth Realm:**
- Press "Manage realms" and select "FHIR-Auth"


### 4. Test UMA Flow

**Step 1: Request protected resource without token**
```bash
curl -i http://localhost:8081/fhir/Patient
```

**Expected response:**
```
HTTP/1.1 401
WWW-Authenticate: UMA realm="FHIR-Auth", as_uri="http://localhost:8080/realms/FHIR-Auth", ticket="<PERMISSION_TICKET>"
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

**✅ Success indicator:** You receive a 401 with a `WWW-Authenticate` header containing a permission ticket.


---

## Development Setup


### 1. Run from Command Line

```bash
cd hapi-jpa
mvn clean spring-boot:run
```

### 5. Build WAR File

```bash
cd hapi-jpa
mvn clean package -DskipTests
```

**Output:** `hapi-jpa/target/ROOT.war`

### 6. Run Tests

```bash
cd hapi-jpa
mvn test
```


---

## Next Steps

Once the system is running successfully:

1. **Understand the Architecture**: Read **[2-Architecture.md](2-Architecture.md)**
2. **Learn UMA Implementation**: Read **[3-UMA-Implementation.md](3-UMA-Implementation.md)**
3. **Configure Keycloak**: Read **[4-Keycloak-Configuration.md](4-Keycloak-Configuration.md)**
4. **Run Tests**: Use the testing guide at `hapi-jpa/testing/curl-testing-commands.md`
5. **Use the API**: Refer to **[6-API-Reference.md](6-API-Reference.md)**

---

## Additional Resources

- **Docker Documentation**: https://docs.docker.com/
- **Keycloak Documentation**: https://www.keycloak.org/documentation
- **HAPI FHIR Documentation**: https://hapifhir.io/hapi-fhir/docs/
- **UMA 2.0 Specification**: https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-grant-2.0.html
- **FHIR R5 Specification**: https://hl7.org/fhir/R5/

---

**Last Updated**: January 2026
