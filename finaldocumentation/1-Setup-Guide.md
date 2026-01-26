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

## Prerequisites

### System Requirements

| Component | Requirement |
|-----------|-------------|
| **Operating System** | Windows 10/11, macOS, or Linux |
| **RAM** | Minimum 8 GB, recommended 16 GB |
| **Disk Space** | ~5 GB for Docker images and data |
| **Available Ports** | 5432, 5433, 8080, 8081 |

### Required Software

#### 1. Docker Desktop

**Required for running the complete system** (Keycloak + PostgreSQL + FHIR Server)

- **Download**: https://www.docker.com/products/docker-desktop
- **Version**: 20.x or higher
- **Docker Compose**: Version 2.x or higher (included with Docker Desktop)

**Installation Verification:**
```bash
docker --version
# Expected: Docker version 20.x or higher

docker-compose --version
# Expected: Docker Compose version v2.x or higher
```

#### 2. Git (Optional but Recommended)

- **Download**: https://git-scm.com/downloads
- **Version**: Any recent version

**Installation Verification:**
```bash
git --version
# Expected: git version 2.x or higher
```

#### 3. For Development Only

The following are **only required** if you plan to modify the source code:

**Java Development Kit (JDK) 17+**
- **Download**: https://adoptium.net/ (Temurin)
- **Version**: 17 or higher

```bash
java -version
# Expected: openjdk version "17.x" or higher
```

**Maven 3.8+**
- **Download**: https://maven.apache.org/download.cgi
- **Version**: 3.8 or higher

```bash
mvn -version
# Expected: Apache Maven 3.8.x or higher
```

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

This command starts:
- Keycloak (Authorization Server) on port 8080
- PostgreSQL (Keycloak DB) on port 5433
- PostgreSQL (FHIR DB) on port 5432
- HAPI FHIR Server on port 8081

**Expected output:**
```
[+] Running 5/5
 ✔ Network hapi-jpa_default                    Created
 ✔ Container hapi-jpa-keycloak-postgres-1     Started
 ✔ Container hapi-jpa-hapi-fhir-postgres-1    Started
 ✔ Container hapi-jpa-keycloak-1              Started
 ✔ Container hapi-jpa-hapi-fhir-jpaserver-1   Started
```

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

### Architecture Overview

The system consists of 4 Docker containers:

```
┌─────────────────────────────────────────────────────┐
│                                                       │
│  ┌──────────────┐         ┌──────────────┐         │
│  │  Keycloak    │◄────────┤  Keycloak    │         │
│  │  (Auth       │         │  PostgreSQL  │         │
│  │   Server)    │         │  :5433       │         │
│  │  :8080       │         └──────────────┘         │
│  └──────┬───────┘                                   │
│         │                                           │
│         │ UMA Authorization                         │
│         │                                           │
│  ┌──────▼───────┐         ┌──────────────┐         │
│  │  HAPI FHIR   │◄────────┤  HAPI FHIR   │         │
│  │  Server      │         │  PostgreSQL  │         │
│  │  :8081       │         │  :5432       │         │
│  └──────────────┘         └──────────────┘         │
│                                                       │
└─────────────────────────────────────────────────────┘
```

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

**Expected output:**
```
[+] Building 45.2s (15/15) FINISHED
 => [internal] load build definition
 => [internal] load metadata for docker.io/library/maven:3.8-openjdk-17
 ...
 => => exporting layers
 => => writing image sha256:...
```

#### 5. Start Services

```bash
docker-compose up -d
```

The `-d` flag runs containers in detached mode (background).

#### 6. Monitor Startup

**View logs for all services:**
```bash
docker-compose logs -f
```

Press `Ctrl+C` to stop following logs (containers keep running).

**View logs for specific service:**
```bash
docker-compose logs -f hapi-fhir-jpaserver-start
```

**Wait for these messages:**
- **Keycloak**: `Keycloak 26.x started`
- **FHIR Server**: `Started Application in X.XXX seconds`

---

## First Run and Verification

### 1. Verify All Services are Running

```bash
docker-compose ps
```

**Expected output:**
```
NAME                               COMMAND                  STATUS
hapi-jpa-hapi-fhir-jpaserver-1    "catalina.sh run"        Up
hapi-jpa-hapi-fhir-postgres-1     "docker-entrypoint.s…"   Up (healthy)
hapi-jpa-keycloak-1               "/opt/keycloak/bin/k…"   Up
hapi-jpa-keycloak-postgres-1      "docker-entrypoint.s…"   Up (healthy)
```

### 2. Test FHIR Server

**Metadata Endpoint (Public):**
```bash
curl http://localhost:8081/fhir/metadata | jq '.fhirVersion'
```

**Expected output:**
```json
"5.0.0"
```

**Health Check:**
```bash
curl http://localhost:8081/actuator/health
```

**Expected output:**
```json
{"status":"UP"}
```

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
- Top-left dropdown should show "FHIR-Auth" realm
- If not, the realm import may have failed (see Troubleshooting)

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

### 5. Run Automated Test Suite

```bash
cd ../scripts
./06-test-all.sh
```

**Expected output:**
```
========================================
Complete Test Suite Results
========================================

Test scripts passed: 5/5

✓ All tests passed!
✓ Sprint 3 RBAC implementation is working correctly!

Test Categories:
- Anonymous Access: 4/4 tests passed
- Patient (Alice): 5/5 tests passed
- Doctor (Dr. Bob): 6/6 tests passed
- Administrator (Jan): 5/5 tests passed
TOTAL: 20/20 tests passed (100%)
```

---

## Development Setup

**For developers who want to modify the code:**

### Prerequisites

- Java JDK 17+
- Maven 3.8+
- IDE (IntelliJ IDEA or Eclipse recommended)

### 1. Import Project

**IntelliJ IDEA:**
1. File → Open
2. Select `uma-inno/hapi-jpa/pom.xml`
3. Choose "Open as Project"
4. Wait for Maven to download dependencies

**Eclipse:**
1. File → Import → Existing Maven Project
2. Select `uma-inno/hapi-jpa` directory
3. Click Finish

### 2. Configure Run Configuration

**IntelliJ IDEA:**
1. Run → Edit Configurations
2. Add New → Spring Boot
3. Main class: `ca.uhn.fhir.jpa.starter.Application`
4. Working directory: `uma-inno/hapi-jpa`
5. VM Options (optional): `-Xmx2g` (2 GB heap)

### 3. Run from IDE

Click the green "Run" button or press Shift+F10

**Expected console output:**
```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::               (v3.x.x)

...
Started Application in X.XXX seconds
```

### 4. Run from Command Line

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

## Troubleshooting

### Issue: Port Already in Use

**Symptom:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:8080: bind: address already in use
```

**Solution:**

**Option 1 - Stop conflicting service:**
```bash
# Find process using port
netstat -ano | findstr :8080  # Windows
lsof -i :8080                 # macOS/Linux

# Kill process (use PID from above)
taskkill /PID <PID> /F        # Windows
kill -9 <PID>                 # macOS/Linux
```

**Option 2 - Change port in docker-compose.yml:**
```yaml
keycloak:
  ports:
    - "8081:8080"  # Changed from 8080:8080
```

### Issue: Containers Not Starting

**Symptom:**
```bash
docker-compose ps
# Shows "Exit 1" or "Restarting"
```

**Solution:**

**Check logs:**
```bash
docker-compose logs keycloak
docker-compose logs hapi-fhir-jpaserver-start
```

**Common causes:**
- Database not ready (wait 30 seconds and try again)
- Port conflicts (see above)
- Insufficient memory (increase Docker memory to 8+ GB)

**Restart services:**
```bash
docker-compose down
docker-compose up -d
```

### Issue: Keycloak Realm Not Found

**Symptom:**
- Admin console doesn't show "FHIR-Auth" realm
- FHIR server logs show: "Realm not found"

**Solution:**

**Import realm manually:**
1. Open Keycloak Admin Console: http://localhost:8080
2. Login with admin/admin
3. Hover over "master" realm dropdown (top-left)
4. Click "Create Realm"
5. Click "Browse" and select `keycloak config/fhir-auth-config.json`
6. Click "Create"

### Issue: FHIR Server Returns 500 Error

**Symptom:**
```bash
curl http://localhost:8081/fhir/metadata
# Returns: HTTP 500 Internal Server Error
```

**Solution:**

**Check database connection:**
```bash
docker-compose logs hapi-fhir-postgres
docker-compose logs hapi-fhir-jpaserver-start
```

**Look for:**
- `Connection refused`
- `Unable to acquire JDBC Connection`

**Fix:**
```bash
# Restart all services
docker-compose down
docker-compose up -d

# Wait 60 seconds for database initialization
sleep 60

# Try again
curl http://localhost:8081/fhir/metadata
```

### Issue: UMA Flow Not Working

**Symptom:**
- Request to /fhir/Patient returns 500 instead of 401
- No permission ticket in response

**Solution:**

**Check Keycloak connectivity:**
```bash
# From inside FHIR container
docker-compose exec hapi-fhir-jpaserver-start curl http://localhost:8080/realms/FHIR-Auth/.well-known/uma2-configuration
```

**Expected:** JSON response with UMA configuration

**If fails:**
- Check `extra_hosts` in docker-compose.yml (must have `localhost:host-gateway`)
- Restart services

### Issue: Tests Failing

**Symptom:**
```bash
./06-test-all.sh
# Shows: X/20 tests passed
```

**Solution:**

**Check test user credentials:**
```bash
# Login to Keycloak Admin Console
# Go to: Users → Search for "alice"
# Reset password to "alice123"
```

**Verify test users exist:**
- alice (Patient role)
- dr.bob (Doctor role)
- jan (Administrator role)

**Recreate test users** if needed (see **[4-Keycloak-Configuration.md](4-Keycloak-Configuration.md)**)

### Issue: Docker Compose Command Not Found

**Symptom:**
```bash
docker-compose --version
# Command not found
```

**Solution:**

Docker Compose V2 uses `docker compose` (space instead of hyphen):

```bash
docker compose --version
docker compose up -d
```

Or install Docker Compose V1: https://docs.docker.com/compose/install/

### Issue: Permission Denied on Scripts

**Symptom:**
```bash
./06-test-all.sh
# Permission denied
```

**Solution:**

```bash
chmod +x scripts/*.sh
./06-test-all.sh
```

### Issue: Out of Memory

**Symptom:**
- Docker containers crashing
- System becomes slow

**Solution:**

**Increase Docker memory allocation:**

**Docker Desktop:**
1. Settings → Resources → Memory
2. Increase to 8+ GB
3. Click "Apply & Restart"

**Stop unused containers:**
```bash
docker ps -a
docker stop <container_id>
docker rm <container_id>
```

---

## Next Steps

Once the system is running successfully:

1. **Understand the Architecture**: Read **[2-Architecture.md](2-Architecture.md)**
2. **Learn UMA Implementation**: Read **[3-UMA-Implementation.md](3-UMA-Implementation.md)**
3. **Configure Keycloak**: Read **[4-Keycloak-Configuration.md](4-Keycloak-Configuration.md)**
4. **Run Tests**: Follow **[5-Testing-Guide.md](5-Testing-Guide.md)**
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
