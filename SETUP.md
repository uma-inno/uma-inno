# Setup Guide: UMA-Protected FHIR Server on a Fresh Machine

This guide describes how to bring up the complete stack (HAPI FHIR + Keycloak + demo frontend)
on a fresh machine, including the Keycloak realm and demo data.

> Platform note: the helper scripts are provided as **PowerShell** (`.ps1`). On Linux/macOS run
> them with `pwsh`, or reproduce the underlying `curl` calls manually (see the direct UMA flow
> example in [documentation/ARCHITECTURE.md](documentation/ARCHITECTURE.md#7-api-reference)).

---

## 1. Prerequisites

- **Docker** + **Docker Compose** (daemon running)
- **PowerShell** (Windows) or **pwsh** (Linux/macOS) for the setup/seed scripts
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

> **What the import contains — and what it does not:** the export provides the base realm: users
> (alice, bernd, clara, dr.bob, dr.smith, jan), roles, the `fhir-client` client (secret,
> `uma_protection`), the 5 SMART-v2 scopes, the role/user policies, and Decision Strategy
> AFFIRMATIVE. It **deliberately contains NO** Patient resources and **no** scope permissions —
> those reference user-owned UMA resources that cannot be reliably restored via a realm import
> (Keycloak: *"Resource [Patient/1] … not owned by the resource server"*). They are instead
> created at runtime in step 4. Steps 3 and 4 are therefore **mandatory**, not an optional
> fallback.

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
> before Keycloak answers, the client stays uninitialized and the later seed does **not** register
> the patients (HAPI log: `Failed to register resource Patient/1: … templateValues entry was
> null`).
>
> **Workaround:** once Keycloak answers (`uma2-configuration` returns 200), restart HAPI once
> **before** seeding:
> ```bash
> docker compose restart hapi-fhir-jpaserver-start
> ```
> Verify success:
> ```bash
> docker logs hapi-fhir-jpaserver-start | grep "KeycloakResourceService initialized successfully"
> ```

---

## 4. Build Demo Data + Authorization (mandatory)

The HAPI database starts **empty**. These two scripts create the patients and build the
permissions on the resources that are registered in the process:

```powershell
cd keycloak-config
.\seed-fhir-data.ps1          # patients alice/bernd/clara + clinical resources
.\setup-smart-v2-authz.ps1    # scope permissions on the now-registered Patient/<id>
```

`seed-fhir-data.ps1` creates the three patients (Alice → Patient/1, Bernd → Patient/7,
Clara → Patient/11) and their clinical resources via FHIR POST. The FHIR IDs 1/7/11 result from
the creation order on an empty DB. Every new patient is automatically registered as a UMA
resource in Keycloak by the `ResourceRegistrationInterceptor` (owner = the patient's Keycloak
UUID, resolved at runtime — not hardcoded).

`setup-smart-v2-authz.ps1` is idempotent and creates the scope permissions on the registered
Patient resources (owner full access + the doctor grants for the demo scenario), sets
`uma_protection` as the default scope, and Decision Strategy AFFIRMATIVE. With `-CleanupLegacy`
it also removes leftover objects from older imports.

> **Order seed → setup:** `setup-smart-v2-authz.ps1` only processes Patient resources that are
> already registered in Keycloak — those appear only after seeding. If setup runs before the
> seed, it reports "No Patient/<id> resources registered yet" and creates no permissions. (The
> patient users bernd/clara are already in the export; the script only creates them if missing.)

---

## 5. Verification

> Note: the `test-uma-flow.ps1` mentioned in earlier states is no longer present on this branch.
> The easiest way to check the full UMA flow is through the **frontend proxy**, which performs the
> UMA dance (access token → 401 + permission ticket → RPT → access) server-side.

```bash
# Login (session cookie -> cj.txt), then FHIR access through the proxy (alice = owner):
curl -s -c cj.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" -d '{"username":"alice","password":"alice123"}'
curl -s -b cj.txt -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/fhir/Patient/1   # -> 200
```

**Owner access** (always available, every patient on themselves):

| User | Path | Status | Reason |
|---|---|---|---|
| alice | `Patient/1` | **200** | owner, full access |
| bernd | `Patient/7` | **200** | owner of Patient/7 |
| bernd | `Patient/1` | **403** | no access to a foreign patient |
| clara | `Patient/11` | **200** | owner of Patient/11 |

**Doctor access** is **empty by default** — it only appears once the patient grants it in the
frontend ("Als Patient" view → access management). Example after alice grants "Diagnoses":

| User | Path | before grant | after grant |
|---|---|---|---|
| dr.smith | `Condition?patient=1` | **403** | **200** |
| dr.smith | `Patient/1` (demographics) | **403** | still **401/403** until "Patient data" is granted |

Or in the browser: **http://localhost:3000** — log in as alice/bernd/clara or dr.smith/dr.bob.
In the "Als Patient" view the **access management** panel appears, where the patient grants read
scopes per doctor and blocks individual records. The UMA steps / RPT scopes stay visible.

---

## 6. Known Issues & Fixes

| Problem | Cause | Fix |
|---|---|---|
| Keycloak crash loop, `Unrecognized field "..."` on import | image version older than the `keycloakVersion` in the export | align the image tag with the export (currently `26.6.3`), **not** `:latest` |
| Keycloak crash loop, `Resource … [Patient/1] … not owned by the resource server` | user-owned UMA resources + scope permissions in the realm export are not re-importable | remove them from the export, build them at runtime via seed + `setup-smart-v2-authz.ps1` (the shipped file is already trimmed this way) |
| Seed registers no patients, HAPI log `templateValues entry was null` | HAPI started before Keycloak was ready → Keycloak client uninitialized | restart HAPI after Keycloak is ready, **then** seed (see step 3) |
| `setup-smart-v2-authz.ps1`: "No Patient/<id> resources registered yet" | seed has not run yet | run `seed-fhir-data.ps1` first, then setup again |
| Multiple realm files in the import folder | `--import-realm` imports all JSONs → conflict / wrong realm wins | keep only `fhir-auth-realm-export.json` in the folder |
| `access_denied: request_submitted` | `ownerManagedAccess=true` on the resource | set it to `false` via the Admin API (done by `setup-smart-v2-authz.ps1`) |

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

After `down -v` everything starts fresh: Keycloak re-imports the realm, the HAPI DB is empty →
run steps 3-4 again (including the HAPI restart before the seed).

---

## 9. Run Locally (without Docker)

```bash
cd hapi-jpa
mvn clean spring-boot:run        # serves http://localhost:8081/fhir
```

For local runs, point `uma.authorization-server-uri` / `keycloak.auth-server-url` in
`application.yaml` at `http://localhost:8080` instead of `http://keycloak:8080`.
