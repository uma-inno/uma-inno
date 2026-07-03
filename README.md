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
- Administrator can onboard new patients and doctors (creates the Keycloak user *and* the linked FHIR record in one step), add clinical data (Condition/MedicationStatement/AllergyIntolerance) to any patient, and delete any user (login + FHIR record + clinical data + sharing grants) from a management panel. A pure admin account sees only the management panels, no patient data view.
- Permission-filtered `$summary` (International Patient Summary) operation
- Dockerized demo frontend that performs the UMA dance server-side

**Technology Stack:** HAPI FHIR 8.0.0, Keycloak **26.6.3**, Spring Boot 3.x, PostgreSQL 15, Java 17, Node/Express (frontend), Docker

---

## Quick Start

```bash
# 1. Start services (Keycloak, HAPI FHIR, 2x PostgreSQL, frontend)
cd uma-inno/hapi-jpa
docker compose up -d --build
```

On a fresh install the realm import creates **only the administrator** (`admin` / `admin123`).
There are no demo patients or doctors — you create them at runtime:

1. Open the frontend at http://localhost:3000 and log in as **admin / admin123**.
2. Use the admin panels to add patients and doctors, and to add clinical data
   (Condition / MedicationStatement / AllergyIntolerance) for any patient. Each new
   patient/doctor gets a Keycloak login, a linked FHIR record, and full owner access
   to their own data automatically.

> The realm export already contains the required SMART/UMA infrastructure (scopes,
> `RolePolicy-Doctor`, `uma_protection`, decision strategy). If you ever import a bare
> realm instead, run `keycloak-config/setup-smart-v2-authz.ps1` once to rebuild that
> infrastructure. The full setup guide (Keycloak version pin, HAPI/Keycloak startup-order
> caveat, reset) is in **[SETUP.md](SETUP.md)**.

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
| [documentation/ROADMAP.md](documentation/ROADMAP.md) | Future work — known limitations, technical debt, and next steps for the next developer |

---

## Users

A fresh install ships with a **single** user — the administrator. All patients and
doctors are created at runtime through the admin panels (each gets a Keycloak login and
a linked FHIR record).

| Username | Password | Role | FHIR Resource |
|----------|----------|------|---------------|
| admin | admin123 | Administrator | — (admin panels: add/manage/delete users, add clinical data for any patient) |

Users created via the admin panels:
- **Patient** — Keycloak login (role `Patient`) + own FHIR `Patient` record with full owner access to their own data; grants/revokes doctor access at runtime.
- **Doctor** — Keycloak login (roles `Doctor` + `Patient`) + own FHIR record; access to other patients is granted at runtime by each patient.

---

## Project Structure

```
uma-inno/
├── hapi-jpa/            HAPI FHIR server (backend): interceptors, services, providers, Docker build
├── frontend/           Dockerized demo frontend (Node/Express proxy + static UI)
├── keycloak-config/    Realm export + PowerShell setup/seed scripts + curl testing guide
├── keycloak-policies/  Custom Keycloak owner-policy JAR (legacy / unused — kept as a mount fallback)
├── documentation/      ARCHITECTURE.md (technical reference) + ROADMAP.md (future work)
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

**Last Updated:** July 2026
