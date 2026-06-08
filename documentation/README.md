# UMA 2.0 Protected FHIR Server

**Patient-Centric Authorization for Healthcare Data using UMA 2.0 and FHIR R5**

---

## Overview

This project implements **User-Managed Access (UMA) 2.0** authorization for a FHIR R5 healthcare data server. Patients own and control access to their medical records through fine-grained, instance-level permissions.

**Key Features:**
- Patient-centric access control (patients own their data)
- Instance-level permissions (e.g., Patient/1, not "all patients")
- Role-based authorization (Patient, Doctor roles)
- Complete UMA 2.0 flow with Keycloak

**Technology Stack:** HAPI FHIR 8.0.0, Keycloak 26.x, Spring Boot 3.x, PostgreSQL 15, Java 17, Docker

---

## Quick Start

```bash
# 1. Start services
cd uma-inno/hapi-jpa
docker-compose up -d

# 2. Wait ~60 seconds, then create test data
cd ../keycloak-config
./create-fhir-resources.sh
./create-test-permissions.sh
```

**Endpoints:**
- FHIR Server: http://localhost:8081/fhir/metadata
- Keycloak: http://localhost:8080 (admin/admin)

---

## Documentation

| Document | Description |
|----------|-------------|
| [1-Setup-Guide.md](1-Setup-Guide.md) | Installation and verification |
| [2-Technical-Overview.md](2-Technical-Overview.md) | Architecture and UMA implementation |
| [3-Keycloak-Configuration.md](3-Keycloak-Configuration.md) | Keycloak setup and test users |
| [4-API-Reference.md](4-API-Reference.md) | API endpoints and examples |
| [5-Project-Structure.md](5-Project-Structure.md) | Important directories and files |
| [6-$summary-Operation.md](6-$summary-Operation.md) | Proposed $summary operation (not implemented) |
| [curl-testing-commands.md](../keycloak-config/curl-testing-commands.md) | Testing guide |

---

## Test Users

| Username | Password | Role | FHIR Resource |
|----------|----------|------|---------------|
| alice | alice123 | Patient | Patient/1 |
| jan | jan123 | Patient | Patient/2 |
| dr.smith | smith123 | Doctor | - |
| dr.bob | bob123 | Doctor | - |

---

**Last Updated**: January 2026
