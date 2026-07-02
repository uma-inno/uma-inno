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
- Patient-controlled sharing: patients grant/revoke doctor access and block individual records at runtime
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
> startup-order caveat) is in **[SETUP.md](SETUP.md)**. The two PowerShell steps above are
> **mandatory** — the realm import alone does not create the Patient resources or permissions.

**Endpoints:**
- Frontend (demo UI): http://localhost:3000
- FHIR Server: http://localhost:8081/fhir/metadata
- Keycloak: http://localhost:8080 (admin/admin)

---

## Documentation

| Document | Description |
|----------|-------------|
| [SETUP.md](SETUP.md) | Full setup guide — prerequisites, startup, seed, verification, troubleshooting, reset |
| [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md) | Technical reference — architecture, UMA flow, Keycloak config, API reference, `$summary`, further reading |

---

## Test Users

| Username | Password | Role | FHIR Resource |
|----------|----------|------|---------------|
| alice | alice123 | Patient | Patient/1 (owner) |
| bernd | bernd123 | Patient | Patient/7 (owner) |
| clara | clara123 | Patient | Patient/11 (owner) |
| dr.smith | smith123 | Doctor + Patient | owns their own record; access to other patients is granted at runtime by each patient |
| dr.bob | bob123 | Doctor + Patient | owns their own record; access to other patients is granted at runtime by each patient |
| jan | _(from import)_ | Administrator | — |

---

## Project Structure

```
uma-inno/
├── hapi-jpa/            HAPI FHIR server (backend): interceptors, services, providers, Docker build
├── frontend/           Dockerized demo frontend (Node/Express proxy + static UI)
├── keycloak-config/    Realm export + PowerShell setup/seed scripts + curl testing guide
├── keycloak-policies/  Custom Keycloak owner-policy JAR (legacy / unused — kept as a mount fallback)
├── documentation/      ARCHITECTURE.md (technical reference)
├── README.md           This file
└── SETUP.md            Setup guide
```

**Key backend packages** (`hapi-jpa/src/main/java/ca/uhn/fhir/jpa/starter/`):

| Package | Purpose |
|---------|---------|
| `interceptors/` | UMA enforcement, resource registration, consent/search filtering, logging |
| `services/` | Keycloak integration, local JWKS token validation, instance blacklist |
| `providers/` | `$summary` operation (IPS Document Bundle) |
| `uma/` | UMA operations (`$introspect` / `$auth` / `$token`) and token services |

See [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md) for details on each component.

---

**Last Updated:** June 2026
