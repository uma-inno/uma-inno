# Roadmap & Future Work

Notes for the next developer: known limitations, deliberate simplifications, technical debt, and
concrete next steps. This is a **demo / proof-of-concept** for patient-controlled UMA authorization
on FHIR — several things are simplified on purpose. Each item below says *what* is simplified, *why*
it was acceptable for the demo, and *what a production-grade version would do instead*.

For the current design see [ARCHITECTURE.md](ARCHITECTURE.md); for setup see [../SETUP.md](../SETUP.md).

---

## 1. Security & Authorization

### 1.1 The proxy mutates Keycloak with the `admin/admin` token
**Status:** deliberate simplification (see ARCHITECTURE §6).
Patient sharing actions (`/api/access/*`) and all admin actions (`/api/admin/*`) are executed by the
frontend proxy using a Keycloak **admin** token, *after* a server-side owner/role check.

- **Why acceptable now:** the proxy verifies ownership (`session.ownPatientId`, never the request
  body) and the admin role before every mutation, so the client cannot escalate.
- **Production path:** UMA-native **owner-managed access** — set `ownerManagedAccess=true` on each
  `Patient` resource and let the patient's **own** token drive the Keycloak Account API to grant /
  revoke. That removes the all-powerful admin token from the request path entirely.

### 1.2 Local RPT validation instead of introspection
**Status:** intentional workaround (see ARCHITECTURE §3).
HAPI validates the RPT locally against the realm JWKS (RS256 + `exp`) because Keycloak returned
`active:false` when introspecting RPTs whose `iss` is `localhost` while the server talks to it via
`keycloak:8080`.

- **Consequence:** **revocation is not immediate.** A leaked/So-revoked RPT stays valid until it
  expires. Trust-list changes take effect on the next RPT exchange (effectively immediate through the
  proxy, which exchanges per request), but a *directly held* RPT is not re-checked.
- **Next step:** either align issuer URLs (single hostname for browser + server, e.g. a shared
  `keycloak` host alias or a reverse proxy) so introspection works, or keep local validation but add
  short RPT lifetimes + a revocation list. Decide explicitly; don't leave it implicit.

### 1.3 Secrets are committed
The `client_secret` (`QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP`), Keycloak admin `admin/admin`, and the realm
admin `admin/admin123` are hard-coded in the repo and docs.

- **Fine for:** a local demo.
- **Before any shared/hosted deployment:** move to environment variables / a secret store, rotate the
  client secret, and force a password change on the seeded admin.

### 1.4 Blacklist cache staleness window
Instance-level blocks (`UmaBlacklistService`) are cached for ~30 s, so un/blocking a single record
takes up to 30 s to take effect (documented in ARCHITECTURE §6).

- **Next step:** if near-real-time revocation matters, add cache invalidation on the blacklist write
  path (the proxy already knows when it mutates a marker policy) instead of relying on TTL expiry.

---

## 2. Technical Debt

### 2.1 Legacy owner-policy JAR
`keycloak-policies/keycloak-owner-policy.jar` is mounted into Keycloak but **unused** — ownership is
enforced through runtime `UserPolicy-*` user policies (ARCHITECTURE §5). A script-based policy also
breaks realm export (`providerFactory is null`).

- **Action:** the Compose mount can be removed without affecting the demo. Left in place only as a
  fallback reference.

### 2.2 Realm re-export is a manual, error-prone chore
After Keycloak config changes, re-exporting the realm requires hand-editing the JSON to strip
runtime-created user-owned resources + scope policies, or the next import crash-loops (SETUP §6/§7).

- **Next step:** script the export + trim (a small `jq`/PowerShell post-processor that clears
  `authorizationSettings.resources` and removes `scope`-type policies) so re-export isn't a
  copy-paste-and-pray step.

### 2.3 HAPI ↔ Keycloak startup ordering
`depends_on` waits for the Keycloak *container*, not for the realm import to finish, so HAPI's admin
client can come up uninitialized and the first patient creation fails to register in Keycloak
(SETUP §3). The current workaround is a manual `docker compose restart hapi-fhir-jpaserver-start`.

- **Next step:** replace the manual restart with a real readiness gate — a healthcheck on Keycloak's
  `uma2-configuration` endpoint + `depends_on: condition: service_healthy`, or a retry/backoff loop
  in `KeycloakResourceService` initialization.

---

## 3. Feature Extensions

### 3.1 More IPS sections in `$summary`
`PatientSummaryProvider` currently emits Problems, Allergies, and Medication Summary. It keeps
sections in a `SECTIONS` table, so adding Immunizations (`11369-6`), Results (`30954-2`), Procedures
(`47519-4`), etc. is mechanical — **once** the corresponding resource types are UMA-protected and
have their own SMART scopes (ARCHITECTURE §8).

- **Order of work:** (1) add the resource type to the interceptor's protected set + scope map,
  (2) add the SMART scope to the realm, (3) add the `SectionSpec` row.

### 3.2 Granular `?category=` scopes not yet in the realm data
Stage 3 enforcement (category-narrowed scopes) exists in the interceptor and `$summary`, but the
seeded realm/scopes don't yet express granular category scopes (open item carried over from earlier
project state). Worth finishing so the category filtering is exercised end-to-end from real scopes,
not just code paths.

### 3.3 Per-patient `ownerManagedAccess`
Today the admin panel sets `ownerManagedAccess=false` on every new `Patient` so the proxy-admin flow
works (SETUP §6, item `access_denied: request_submitted`). This is coupled to §1.1 — flipping it to
`true` is the enabler for true owner-managed sharing, and should be done together with moving
mutations off the admin token.

### 3.4 Admin UX
The management panel deletes users but there is no edit (rename, reset password, change role) and no
pagination/search (`GET /api/admin/users` caps at 500 role members). Fine at demo scale; revisit if
the user list grows.

---

## 4. Testing

- There is no automated end-to-end test for the UMA dance on this branch (the old
  `test-uma-flow.ps1` was removed; SETUP §5 verifies manually via the proxy).
- **Next step:** add a scripted flow that (1) creates a patient + doctor via `POST /api/admin/users`,
  (2) asserts the doctor gets `403` on the patient's data, (3) grants a scope via
  `POST /api/access/grant`, (4) asserts `200`, (5) blacklists one instance and asserts it drops from
  the bundle, (6) deletes the users via `DELETE /api/admin/users/:id` and asserts cleanup. That
  single script would guard every moving part of the demo.

---

## 5. Quick Orientation for a New Developer

| You want to change… | Look at |
|---|---|
| UMA enforcement / scope rules / admin DELETE bypass | `hapi-jpa/.../interceptors/UmaKeycloakAuthInterceptor.java` |
| Resource registration in Keycloak on create | `hapi-jpa/.../interceptors/ResourceRegistrationInterceptor.java` |
| Search-result filtering (consent/blacklist) | `hapi-jpa/.../interceptors/UmaConsentService.java` |
| RPT validation / blacklist cache | `hapi-jpa/.../services/UmaTokenValidator.java`, `UmaBlacklistService.java` |
| `$summary` / IPS sections | `hapi-jpa/.../providers/PatientSummaryProvider.java` |
| Proxy, UMA dance, admin & sharing endpoints | `frontend/server.js` |
| UI (login, admin panels, sharing, admin-only mode) | `frontend/public/{index.html,app.js,style.css}` |
| Keycloak realm baseline (scopes, RolePolicy-Doctor) | `keycloak-config/keycloak-files/fhir-auth-realm-export.json` |
| Bare-realm rebuild script | `keycloak-config/setup-smart-v2-authz.ps1` |
