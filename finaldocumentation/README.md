# UMA 2.0 Protected FHIR Server

**Patient-Centric Authorization for Healthcare Data using UMA 2.0 and FHIR R5**

---

## Project Overview

This project implements a production-grade **User-Managed Access (UMA) 2.0** authorization layer for a FHIR R5 healthcare data server. It enables patients to own and control access to their medical records through fine-grained, instance-level permissions.

### Key Achievement

This is a implementation of the UMA 2.0 protocol integrated with a HAPI FHIR JPA Server and Keycloak Authorization Services. The system provides:

- **Patient-centric access control**: Patients own their data and can grant/revoke access
- **Instance-level permissions**: Access control at individual resource level (e.g., Patient/552)
- **Role-based authorization**: Different permissions for Patients, Doctors, and Administrators
- **Full UMA 2.0 compliance**: Complete 3-step UMA flow with permission tickets and RPT tokens

---

## Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **FHIR Server** | HAPI FHIR JPA Server | 8.0.0 |
| **FHIR Standard** | FHIR R5 | R5 (2023) |
| **Authorization Server** | Keycloak | Latest (26.x) |
| **Application Framework** | Spring Boot | 3.x |
| **Database** | PostgreSQL | 15 |
| **Language** | Java | 17 |
| **Containerization** | Docker / Docker Compose | Latest |
| **Authorization Protocol** | UMA 2.0 | RFC 7230 |
| **Token Format** | JWT (JSON Web Token) | RFC 7519 |

---

## Project Status

- **UMA 2.0 Authorization Flow**: Complete 3-step UMA flow (permission ticket, RPT issuance, permission validation)
- **FHIR R5 Server**: Full CRUD operations on Patient, Condition, AllergyIntolerance, MedicationStatement
- **Instance-Level Permissions**: Fine-grained access control
- **Role-Based Access Control**: Patient, Doctor, Administrator roles with different permissions
- **Automatic Resource Registration**: FHIR resources automatically registered in Keycloak on creation
- **Owner Policy**: Patients automatically own their data

---

## Quick Start

```bash
# 1. Clone repository
git clone https://github.com/uma-inno/uma-inno.git
cd uma-inno/hapi-jpa

# 2. Start all services (Keycloak + PostgreSQL + FHIR Server)
docker-compose up -d

# 3. Wait for services to be ready (~30 seconds)
# Check: http://localhost:8080 (Keycloak) and http://localhost:8081/fhir/metadata (FHIR)
```

For detailed setup instructions, see **[1.Setup-Guide.md](1-Setup-Guide.md)**.

---

## Documentation Structure

### Complete Documentation

1. **[1-Setup-Guide.md](1-Setup-Guide.md)**
   - Prerequisites and installation
   - Docker setup and configuration
   - First run and verification
   - Troubleshooting common issues

2. **[2-Architecture.md](2-Architecture.md)**
   - System architecture overview
   - Component descriptions (HAPI FHIR, Keycloak, PostgreSQL)
   - Request flow through the system
   - UMA 2.0 authorization flow
   - Ownership model and RBAC implementation

3. **[3-UMA-Implementation.md](3-UMA-Implementation.md)**
   - UMA 2.0 protocol explanation
   - 3-step UMA flow in detail
   - Code overview (Interceptors, Services)
   - JWT token structure and permission extraction
   - Implementation highlights

4. **[4-Keycloak-Configuration.md](4-Keycloak-Configuration.md)**
   - Keycloak realm and client setup
   - Roles, policies, and permissions
   - Owner policy JAR deployment
   - Test users and their roles
   - Manual configuration guide

5. **[5-Testing-Guide.md](5-Testing-Guide.md)**
   - Automated test suite overview
   - Manual testing procedures
   - Demo scenarios (Alice, Bob, Jan)
   - Test results and validation
   - Troubleshooting test failures

6. **[6-API-Reference.md](6-API-Reference.md)**
   - FHIR REST API endpoints
   - UMA authorization endpoints
   - Request/Response examples
   - Standards compliance (UMA 2.0, FHIR R5, OAuth 2.0)
   - Configuration parameters

---

## Key Concepts

### UMA 2.0 (User-Managed Access)

UMA is an OAuth 2.0 profile that enables resource owners (patients) to control access to their protected resources (medical records). The 3-step flow:

1. **Permission Ticket Request**: Client requests access → Server issues permission ticket
2. **RPT Token Exchange**: Client exchanges ticket + user token → Authorization Server issues RPT (Requesting Party Token)
3. **Resource Access**: Client accesses resource with RPT → Server validates permissions

### Instance-Level Permissions

Unlike traditional role-based systems that grant access to all resources of a type (e.g., "read all patients"), this system provides **instance-level** control:

- Alice can read **Patient/552** (her own record) ✅
- Alice cannot read **Patient/602** (Bob's record) ❌
- Doctor can read **Patient/552** only if granted permission by Alice

### Resource Ownership

- **Patient resources**: Owned by the patient themselves (via keycloak-uuid identifier)
- **Clinical resources**: Owned by the referenced patient (e.g., Condition/554 → Patient/552 → Alice)
- **Owner Policy**: Automatically grants full permissions to resource owners (no explicit grants needed)

---

## Repository Structure

```
uma-inno/
├── hapi-jpa/                          # Main FHIR server application
│   ├── src/main/java/                 # Java source code
│   │   └── ca/uhn/fhir/jpa/starter/
│   │       ├── interceptors/          # UMA interceptors (core authorization logic)
│   │       ├── services/              # Keycloak integration services
│   │       └── uma/                   # UMA-specific components
│   ├── src/main/resources/            # Configuration files
│   │   └── application.yaml           # Main application configuration
│   ├── docker-compose.yml             # Docker services definition
│   └── pom.xml                        # Maven dependencies
│
├── keycloak-policies/                 # Custom Keycloak policies
│   ├── owner-policy.js                # Owner-based access policy (JavaScript)
│   └── keycloak-owner-policy.jar      # Compiled policy JAR
│
├── keycloak config/                   # Keycloak realm export
│   └── fhir-auth-config.json          # Complete realm configuration
│
├── scripts/                           # Testing and demo scripts
│   ├── 00-config.sh                   # Test configuration
│   ├── 01-helper-functions.sh         # Reusable bash functions
│   ├── 02-test-anonymous.sh           # Anonymous access tests
│   ├── 03-test-alice-patient.sh       # Patient role tests
│   ├── 04-test-doctor-bob.sh          # Doctor role tests
│   ├── 05-test-admin-jan.sh           # Admin role tests
│   ├── 06-test-all.sh                 # Master test runner
│   └── demo-commands.md               # Demo commands reference
│
├── docs/                              # Development documentation
│   ├── SPRINT3_COMPLETION_REPORT.md
│   ├── SPRINT3_KEYCLOAK_SETUP_GUIDE.md
│   ├── SPRINT3_TESTING_GUIDE.md
│   └── ...
│
└── finaldocumentation/                # Final comprehensive documentation (this folder)
    ├── README.md                      # This file
    ├── 1-Setup-Guide.md
    ├── 2-Architecture.md
    ├── 3-UMA-Implementation.md
    ├── 4-Keycloak-Configuration.md
    ├── 5-Testing-Guide.md
    ├── 6-API-Reference.md
    └── 7-Future-Work.md
```

---

## System Requirements

### For Running the System

- **Docker Desktop**: Version 20.x or higher
- **Docker Compose**: Version 2.x or higher
- **Available Ports**: 5432, 5433, 8080, 8081
- **RAM**: Minimum 8 GB (recommended 16 GB)
- **Disk Space**: ~5 GB for Docker images and data

### For Development

- **Java Development Kit (JDK)**: Version 17 or higher
- **Maven**: Version 3.8 or higher
- **Git**: For version control
- **IDE**: IntelliJ IDEA or Eclipse (optional)

---

## Endpoints Overview

### FHIR Server (http://localhost:8081)

- **Base URL**: http://localhost:8081/fhir/
- **Metadata**: http://localhost:8081/fhir/metadata
- **Health Check**: http://localhost:8081/actuator/health

### Keycloak (http://localhost:8080)

- **Admin Console**: http://localhost:8080 (admin / admin)
- **Realm**: FHIR-Auth
- **Token Endpoint**: http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token
- **Introspection Endpoint**: http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token/introspect

### Protected FHIR Resources

- **Patient**: GET/POST/PUT/DELETE /fhir/Patient
- **Condition**: GET/POST/PUT/DELETE /fhir/Condition
- **AllergyIntolerance**: GET/POST/PUT/DELETE /fhir/AllergyIntolerance
- **MedicationStatement**: GET/POST/PUT/DELETE /fhir/MedicationStatement

All endpoints require UMA 2.0 authorization (except public endpoints like /metadata).

---

## Test Users

| Username | Password | Role | Keycloak UUID |
|----------|----------|------|---------------|
| alice | alice123 | Patient | 5441cea9-fcf2-419e-bc20-948c3c283c98 |
| dr.bob | bob123 | Doctor | 97503f80-1f4f-4ae6-8b58-eb50a082acf9 |
| jan | jan123 | Administrator | df11bc00-e0e6-4924-941d-3627fdd16992 |

**Alice** owns Patient/552 and can access it. **Bob** (doctor) and **Jan** (admin) have different permission sets.

