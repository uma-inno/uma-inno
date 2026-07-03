# Setup Guide: UMA-Protected FHIR Server on a Fresh Machine

This guide describes how to bring up the complete stack (HAPI FHIR + Keycloak + demo frontend)
on a fresh machine, including the Keycloak realm and demo data.

> Platform note: the helper scripts are provided as **PowerShell** (`.ps1`). On Linux/macOS run
> them with `pwsh`, or reproduce the underlying `curl` calls manually (see the direct UMA flow
> example in [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md#7-api-reference)).

---

## 1. Prerequisites

- **Docker** + **Docker Compose** (daemon running)
- **PowerShell** (Windows) or **pwsh** (Linux/macOS) — only needed for the optional bare-realm fallback script
- Free ports: `8080` (Keycloak), `8081` (HAPI FHIR), `3000` (frontend),
  `5432`/`5433` (PostgreSQL)

> **Keycloak version (important):** the Compose file intentionally pins the image to
> `quay.io/keycloak/keycloak:26.6.3`. The realm export (`fhir-auth-realm-export.json`) was
> produced with this version (`"keycloakVersion": "26.6.3"`). An **older** Keycloak version
> aborts the import with `Unrecognized field "..."` (e.g. `scimApiEnabled`,
> `maxSecondaryAuthFailures`). If you bump the version, align the image tag with the
> `keycloakVersion` in the export — do **not** use `:latest`, because the `latest` build can be
> older than the export.

---

## 2. Start the Stack

In the `hapi-jpa/` directory:

```bash
docker compose up -d --build
```

This starts five containers:

| Service | Container | Port | Access |
|---|---|---|---|
| Keycloak | `keycloak-uma` | 8080 | admin / admin |
| HAPI FHIR | `hapi-fhir-jpaserver-start` | 8081 | — |
| Keycloak DB | `keycloak-postgres` | 5433 | keycloak / keycloak |
| HAPI DB | `hapi-fhir-postgres` | 5432 | admin / admin |
| Frontend | `uma-frontend` | 3000 | — |

On first start Keycloak automatically imports the realm from the mounted folder
`keycloak-config/keycloak-files/`. That folder must contain **exactly one** realm file
(`fhir-auth-realm-export.json`); otherwise `--import-realm` would import multiple realms and
cause conflicts.

> **What the import contains — and what it does not:** the export provides the base realm and a
> **single user, the administrator** (`admin` / `admin123`, role `Administrator`), the `fhir-client`
> client (secret, `uma_protection`), the 5 SMART-v2 scopes, `RolePolicy-Doctor`, and Decision
> Strategy AFFIRMATIVE. It **deliberately contains NO** patients, doctors, Patient resources, or
> scope permissions — those reference user-owned UMA resources that cannot be reliably restored via
> a realm import (Keycloak: *"Resource [Patient/1] … not owned by the resource server"*). Patients
> and doctors are instead created at runtime through the **admin panels** (step 4), which also
> registers the FHIR resources and their owner permissions automatically.

---

## 3. Wait for Readiness

```bash
# Keycloak realm reachable?
curl -s http://localhost:8080/realms/FHIR-Auth/.well-known/uma2-configuration
# HAPI reachable? (can take 1-2 minutes)
curl -s http://localhost:8081/fhir/metadata
```

> **Important — HAPI ↔ Keycloak ordering:** on startup HAPI builds its Keycloak admin client (so
> it can register Patient resources). `depends_on` only waits for the Keycloak **container** to
> run, **not** for Keycloak to have finished importing the realm and be ready. If HAPI starts
> before Keycloak answers, the client stays uninitialized and creating a patient later fails to
> register the FHIR resource in Keycloak (HAPI log: `Failed to register resource Patient/…: …
> templateValues entry was null`).
>
> **Workaround:** once Keycloak answers (`uma2-configuration` returns 200), restart HAPI once
> **before** creating any patients:
> ```bash
> docker compose restart hapi-fhir-jpaserver-start
> ```
> Verify success:
> ```bash
> docker logs hapi-fhir-jpaserver-start | grep "KeycloakResourceService initialized successfully"
> ```

---

## 4. Create & Manage Patients / Doctors (admin panel)

The HAPI database starts **empty** and the realm has only the administrator. You add patients,
doctors, and clinical data at runtime through the admin panels — no seed script. Logging in as a
pure administrator shows **only** the management panels (no patient data view):

1. Open **http://localhost:3000** and log in as **admin / admin123**.
2. **Add patient** — enter username, password, name (gender/birth date optional). This creates a
   Keycloak login (role `Patient`), a linked FHIR `Patient` record, and full owner access to that
   record.
3. **Add doctor** — same form; creates a login with roles `Doctor` + `Patient` and an own FHIR
   record, so the doctor also has a personal patient record.
4. **Add clinical data** — pick a patient and add a Condition, MedicationStatement, or
   AllergyIntolerance.

Under the hood each new patient/doctor is registered as a UMA resource in Keycloak by the
`ResourceRegistrationInterceptor` (owner = the user's Keycloak UUID), and the proxy sets
`ownerManagedAccess=false` plus the `Permission-Patient<id>-Owner-Full` scope permission so the
owner can immediately read their own data. FHIR IDs are assigned in creation order.

5. **Manage users** — the "Benutzer verwalten" panel lists every patient and doctor and lets you
   delete one (removing its login, FHIR record, clinical data, and all sharing grants in one step).
   Administrators and your own account are protected from deletion.

> **Prefer the API?** The same actions are available on the frontend proxy (admin session required):
> `POST /api/admin/users` (`role:'patient'|'doctor'`), `POST /api/admin/clinical`,
> `GET /api/admin/users`, and `DELETE /api/admin/users/:userId`. See
> [ARCHITECTURE.md](documentation/ARCHITECTURE.md#7-api-reference) for the request bodies.

> **Bare-realm fallback:** the SMART/UMA infrastructure (scopes, `RolePolicy-Doctor`,
> `uma_protection`, decision strategy) ships inside the realm export. Only if you import a bare
> realm without it, run `keycloak-config/setup-smart-v2-authz.ps1` once to rebuild it — it creates
> **no** users or patient permissions.

---

## 5. Verification

> Note: the `test-uma-flow.ps1` mentioned in earlier states is no longer present on this branch.
> The easiest way to check the full UMA flow is through the **frontend proxy**, which performs the
> UMA dance (access token → 401 + permission ticket → RPT → access) server-side.

First create a patient in the admin panel (step 4), e.g. `dora` / `dora123` → say it becomes
`Patient/153`. Then verify owner access through the proxy:

```bash
# Login (session cookie -> cj.txt), then FHIR access through the proxy (dora = owner):
curl -s -c cj.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" -d '{"username":"dora","password":"dora123"}'
curl -s -b cj.txt -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/fhir/Patient/153   # -> 200
```

**Owner access** (always available, every patient on their own record):

| User | Path | Status | Reason |
|---|---|---|---|
| dora | `Patient/153` (own) | **200** | owner, full access |
| dora | a foreign `Patient/<id>` | **403** | no access to another patient |

**Doctor access** is **empty by default** — it only appears once the patient grants it in the
frontend ("Als Patient" view → access management). After the patient grants "Diagnoses" to a
doctor, that doctor's `Condition?patient=<id>` goes from **403** to **200**, while the
demographics (`Patient/<id>`) stay denied until "Patient data" is granted too.

Or in the browser: **http://localhost:3000** — log in as a patient or doctor you created. In the
"Als Patient" view the **access management** panel appears, where the patient grants read scopes
per doctor and blocks individual records. The UMA steps / RPT scopes stay visible.

---

## 6. Known Issues & Fixes

| Problem | Cause | Fix |
|---|---|---|
| Keycloak crash loop, `Unrecognized field "..."` on import | image version older than the `keycloakVersion` in the export | align the image tag with the export (currently `26.6.3`), **not** `:latest` |
| Keycloak crash loop, `Resource … [Patient/1] … not owned by the resource server` | user-owned UMA resources + scope permissions in the realm export are not re-importable | keep them out of the export and build them at runtime via the admin panel (the shipped file is already trimmed this way) |
| Creating a patient fails to register in Keycloak, HAPI log `templateValues entry was null` | HAPI started before Keycloak was ready → Keycloak client uninitialized | restart HAPI after Keycloak is ready, **then** create patients (see step 3) |
| New patient sees "Kein Zugriff" on their own data | owner permission was not created (e.g. Keycloak unreachable during creation) | delete the half-created Keycloak user and re-create the patient via the admin panel |
| Multiple realm files in the import folder | `--import-realm` imports all JSONs → conflict / wrong realm wins | keep only `fhir-auth-realm-export.json` in the folder |
| `access_denied: request_submitted` | `ownerManagedAccess=true` on the resource | set it to `false` via the Admin API (the admin panel does this automatically when creating a patient/doctor) |

---

## 7. Re-Export the Realm (after config changes)

```bash
docker exec keycloak-uma /opt/keycloak/bin/kc.sh export \
  --dir /tmp/realm-export --realm FHIR-Auth --users realm_file
docker cp keycloak-uma:/tmp/realm-export/FHIR-Auth-realm.json \
  ./keycloak-config/keycloak-files/fhir-auth-realm-export.json
```

> **Caution — clean up before reusing it as an import file:** a fresh export again contains the
> runtime-created **user-owned Patient resources + scope permissions** — and exactly those cannot
> be re-imported (see step 6). So in the exported file, under the `fhir-client` client, clear
> `authorizationSettings.resources` and remove the policies of type `scope` (role/user policies
> and scopes stay). Those objects are recreated in step 4 anyway. A script-based policy
> (`script-owner-policy.js`) would additionally fail the export with `providerFactory is null` —
> remove that legacy artifact beforehand.

---

## 8. Reset

```bash
cd hapi-jpa
docker compose down            # stop containers, keep volumes
docker compose down -v         # delete containers AND volumes (full reset)
```

After `down -v` everything starts fresh: Keycloak re-imports the realm (only the `admin` user),
the HAPI DB is empty → run steps 3-4 again (HAPI restart once Keycloak is ready, then create
patients/doctors via the admin panel).

---

## 9. Run Locally (without Docker)

```bash
cd hapi-jpa
mvn clean spring-boot:run        # serves http://localhost:8081/fhir
```

For local runs, point `uma.authorization-server-uri` / `keycloak.auth-server-url` in
`application.yaml` at `http://localhost:8080` instead of `http://keycloak:8080`.
