# UMA 2.0 Protected FHIR Server

**Patient-Centric Authorization for Healthcare Data using UMA 2.0 and FHIR R5**

---

## Overview

This project implements **User-Managed Access (UMA) 2.0** authorization for a FHIR R5 healthcare data server. Patients own and control access to their medical records through fine-grained, instance-level permissions, expressed as **SMART on FHIR v2** scopes (`patient/<Type>.<interactions>`).

**Key Features:**
- Patient-centric access control (patients own their data)
- Instance-level permissions (e.g., `Patient/1`, not "all patients")
- SMART on FHIR v2 scopes + role-based create checks (Patient, Doctor, Administrator)
- Complete UMA 2.0 flow with Keycloak (permission ticket → RPT → access)
- Permission-filtered `$summary` (International Patient Summary) operation
- Dockerized demo frontend that performs the UMA dance server-side

**Technology Stack:** HAPI FHIR 8.0.0, Keycloak **26.6.3**, Spring Boot 3.x, PostgreSQL 15, Java 17, Node/Express (frontend), Docker

---

## Quick Start

```bash
# 1. Start services (Keycloak, HAPI FHIR, 2x PostgreSQL, frontend)
cd uma-inno/hapi-jpa
docker compose up -d --build

# 2. Once Keycloak is ready, restart HAPI so it can reach Keycloak, then seed:
cd ../keycloak-config
.\seed-fhir-data.ps1          # patients alice/bernd/clara + clinical resources
.\setup-smart-v2-authz.ps1    # scope permissions on the registered Patient resources
```

> The full, authoritative setup (incl. the Keycloak version pin and the HAPI/Keycloak
> startup-order caveat) is in **[../SETUP.md](../SETUP.md)**. The two PowerShell steps above
> are **mandatory** — the realm import alone does not create the Patient resources or
> permissions.

**Endpoints:**
- Frontend (demo UI): http://localhost:3000
- FHIR Server: http://localhost:8081/fhir/metadata
- Keycloak: http://localhost:8080 (admin/admin)

---

## Documentation

| Document | Description |
|----------|-------------|
| [../SETUP.md](../SETUP.md) | **Authoritative** setup guide (German) |
| [1-Setup-Guide.md](1-Setup-Guide.md) | Setup pointer / quick reference (English) |
| [2-Technical-Overview.md](2-Technical-Overview.md) | Architecture and UMA implementation |
| [3-Keycloak-Configuration.md](3-Keycloak-Configuration.md) | Keycloak setup and test users |
| [4-API-Reference.md](4-API-Reference.md) | API endpoints and examples |
| [5-Project-Structure.md](5-Project-Structure.md) | Important directories and files |
| [6-$summary-Operation.md](6-$summary-Operation.md) | `$summary` (IPS) operation |
| [curl-testing-commands.md](../keycloak-config/curl-testing-commands.md) | Testing guide |

---

## Test Users

| Username | Password | Role | FHIR Resource |
|----------|----------|------|---------------|
| alice | alice123 | Patient | Patient/1 (owner) |
| bernd | bernd123 | Patient | Patient/7 (owner) |
| clara | clara123 | Patient | Patient/11 (owner) |
| dr.smith | smith123 | Doctor + Patient | eigener Datensatz; Zugriff auf andere wird vom Patienten freigegeben |
| dr.bob | bob123 | Doctor + Patient | eigener Datensatz; Zugriff auf andere wird vom Patienten freigegeben |
| jan | _(from import)_ | Administrator | — |

---

**Last Updated**: June 2026
