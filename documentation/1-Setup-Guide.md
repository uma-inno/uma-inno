# 1. Setup Guide

> **The authoritative setup guide is [`../SETUP.md`](../SETUP.md)** (German). It covers the
> Keycloak version pin, the mandatory seed/authz steps, the HAPI ↔ Keycloak startup-order
> caveat, verification, re-export and reset. This page is only a short English pointer.

## Prerequisites

- **Docker** + **Docker Compose** (daemon running)
- **PowerShell** (Windows) or **pwsh** (Linux/macOS) for the setup/seed scripts
- Free ports: `8080` (Keycloak), `8081` (HAPI FHIR), `3000` (frontend), `5432`/`5433` (PostgreSQL)

> **Keycloak version:** the Compose file pins `quay.io/keycloak/keycloak:26.6.3` on purpose —
> it must match the `keycloakVersion` of `fhir-auth-realm-export.json`. An older image rejects
> the import (`Unrecognized field "..."`). Do **not** use `:latest`.

## Steps (summary)

```bash
# 1. Start the stack
cd uma-inno/hapi-jpa
docker compose up -d --build

# 2. Wait until Keycloak answers, then restart HAPI so it can initialise its Keycloak client
curl -s http://localhost:8080/realms/FHIR-Auth/.well-known/uma2-configuration
docker compose restart hapi-fhir-jpaserver-start

# 3. Seed demo data and build the authorization config (BOTH mandatory)
cd ../keycloak-config
.\seed-fhir-data.ps1          # alice/bernd/clara (Patient/1, /7, /11) + clinical resources
.\setup-smart-v2-authz.ps1    # scope permissions on the registered Patient resources
```

The realm import provides only the base realm (users, roles, client, SMART-v2 scopes,
role/user policies). The Patient resources and scope permissions are created at runtime by the
two scripts above — see [`../SETUP.md`](../SETUP.md) for the full rationale and troubleshooting.

## Verification

```bash
# Login through the frontend proxy (it performs the UMA dance), then access a resource:
curl -s -c cj.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" -d '{"username":"dr.smith","password":"smith123"}'
curl -s -b cj.txt -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/fhir/Patient/1   # 200
```

| User | Path | Status |
|------|------|--------|
| dr.smith | `Patient/1` | 200 |
| dr.bob | `Patient/1` | 401 (only `Condition.rs`) |
| dr.bob | `Condition?patient=1` | 200 |
| bernd | `Patient/7` | 200 |
| bernd | `Patient/1` | 403 |

Or open **http://localhost:3000** and log in as alice/bernd/clara (Patient) or dr.smith/dr.bob (Doctor).

## Run Locally (without Docker)

```bash
cd hapi-jpa
mvn clean spring-boot:run        # serves http://localhost:8081/fhir
```

For local runs, point `uma.authorization-server-uri` / `keycloak.auth-server-url` in
`application.yaml` at `http://localhost:8080` instead of `http://keycloak:8080`.
