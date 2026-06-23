# 3. Keycloak Configuration

## Access

- **URL**: http://localhost:8080
- **Admin**: admin / admin
- **Image**: `quay.io/keycloak/keycloak:26.6.3` (pinned — must match the realm export's `keycloakVersion`)
- **Realm**: FHIR-Auth
- **Client**: fhir-client
- **Client Secret**: `QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP`
- **Decision Strategy**: AFFIRMATIVE
- **Default Client Scope**: `uma_protection` (required for the Protection API / ticket exchange)

---

## Test Users

| Username | Password | Role | FHIR Resource |
|----------|----------|------|---------------|
| alice | alice123 | Patient | Patient/1 (owner) |
| bernd | bernd123 | Patient | Patient/7 (owner) |
| clara | clara123 | Patient | Patient/11 (owner) |
| dr.smith | smith123 | Doctor + Patient | besitzt eigenen Datensatz; Zugriff auf fremde Patienten wird vom Patienten zur Laufzeit freigegeben (Standard: keiner) |
| dr.bob | bob123 | Doctor + Patient | besitzt eigenen Datensatz; Zugriff auf fremde Patienten wird vom Patienten zur Laufzeit freigegeben (Standard: keiner) |
| jan | _(from import)_ | Administrator | — |

### Get User Token
```bash
curl -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "username=alice" \
  -d "password=alice123"
```

---

## Roles

| Role | Permissions |
|------|-------------|
| **Patient** | Read own data only (via UMA); cannot create resources |
| **Doctor** | Create Patient/clinical resources; read resources granted via a patient's trust list |
| **Administrator** | Full access to all resources |

---

## SMART on FHIR v2 Authorization Scopes

```
patient/Patient.r       patient/Patient.rs
patient/Condition.rs    patient/MedicationStatement.rs    patient/AllergyIntolerance.rs
```

## Authorization Resources

All registered at runtime by HAPI (`ResourceRegistrationInterceptor`) when the patients are
seeded. Owner = the patient's Keycloak user; `ownerManagedAccess = false`.

| Resource | Owner |
|----------|-------|
| `Patient/1` | alice |
| `Patient/7` | bernd |
| `Patient/11` | clara |
| `Patient/<id>` | dr.smith (eigener Datensatz) |
| `Patient/<id>` | dr.bob (eigener Datensatz) |

## Policies

| Policy | Type | Description |
|--------|------|-------------|
| `RolePolicy-Doctor` | Role | Users with the Doctor role |
| `UserPolicy-Alice` | User | Alice (owner of Patient/1) |
| `UserPolicy-Owner-bernd` | User | Bernd (owner of Patient/7) |
| `UserPolicy-Owner-clara` | User | Clara (owner of Patient/11) |
| `UserPolicy-Owner-drsmith` / `-drbob` | User | dr.smith / dr.bob (eigener Datensatz) |

> Trust-List-Policies für Ärzte werden **nicht** mehr vorgeseedet — der Patient legt sie zur
> Laufzeit über das Frontend an: `TrustList-Patient<id>-<doctor>` (siehe „Patientengesteuerte Freigabe").

## Permissions (type: scope, AFFIRMATIVE)

Vorgeseedet werden **nur** die Owner-Full-Permissions (Eigenzugriff jedes Patienten auf sich selbst):

| Name | Resource | Scopes | Policies |
|------|----------|--------|----------|
| `Permission-Patient1-Alice-Full` | Patient/1 | all 5 | UserPolicy-Alice |
| `Permission-Patient7-Owner-Full` | Patient/7 | all 5 | UserPolicy-Owner-bernd |
| `Permission-Patient11-Owner-Full` | Patient/11 | all 5 | UserPolicy-Owner-clara |
| `Permission-Patient<id>-Owner-Full` | dr.smith / dr.bob | all 5 | UserPolicy-Owner-drsmith / -drbob |

**Arzt-Freigaben** sind **nicht** vorgeseedet — sie entstehen erst, wenn ein Patient sie im
Frontend vergibt (siehe „Patientengesteuerte Freigabe").

**Demo takeaway:** Zu Beginn hat **kein** Arzt Zugriff auf fremde Patienten (`access_denied`).
Der Patient gibt im Frontend gezielt frei — z.B. alice gibt dr.smith „Diagnosen"
(`patient/Condition.rs`) → dr.smith liest dann alices Conditions; sperrt alice eine einzelne
Condition für dr.smith (Blacklist), fällt genau diese aus dem Ergebnis. Das demonstriert die
patientengesteuerte Autorisierung.

> **Decision Strategy = AFFIRMATIVE (not Unanimous):** several permissions share the same scope;
> with Unanimous, a DENY from an unrelated permission would block access. "Unanimous" only applies
> *within* a single permission (e.g. trust list AND Doctor role).

---

## Patientengesteuerte Freigabe (Frontend)

Der Patient verwaltet die Arzt-Zugriffe selbst über das Demo-Frontend (Sicht „Als Patient", nur
auf den **eigenen** Datensatz). Der Proxy mutiert Keycloak per Admin-Token, **nachdem** er
serverseitig geprüft hat, dass der eingeloggte User Owner der Ziel-Ressource ist
(`session.ownPatientId` — die Patient-ID kommt nie aus dem Request).

| Aktion | Proxy-Endpoint | Keycloak-Objekt |
|--------|----------------|------------------|
| Lese-Scope je Typ freigeben/entziehen | `POST /api/access/grant` | `Permission-Patient<id>-<doctor>` (+ `TrustList-Patient<id>-<doctor>`, gebunden an `RolePolicy-Doctor`); leere Auswahl ⇒ Permission gelöscht |
| Einzelne Instanz sperren/entsperren | `POST /api/access/blacklist` | Marker-Policy `Blacklist-<patId>-<resType>-<resId>-<docId>` |
| aktuellen Freigabe-Stand lesen | `GET /api/access/state` | — |

**Wirkung:** Trust-List-/Scope-Änderungen greifen beim nächsten RPT-Tausch (der Proxy tauscht pro
Anfrage frisch → quasi sofort); Blacklist-Änderungen ≤ 30 s (Cache in `UmaBlacklistService`).

> **Sicherheits-/UMA-Limitation:** Die Mutationen laufen über das `admin/admin`-Token des Proxys
> (nach Owner-Prüfung). Produktiv wäre UMA-natives Owner-Managed-Access (`ownerManagedAccess=true`
> + Keycloak Account-API mit dem **eigenen** Token) der saubere Weg; hier bewusst vereinfacht.

---

## Setup Methods

### Method 1: Auto Import (Default)

The realm is automatically imported from
`keycloak-config/keycloak-files/fhir-auth-realm-export.json` when Keycloak starts
(`--import-realm`). This provides the base realm: users, roles, the `fhir-client` client,
the SMART-v2 scopes and the role/user policies. The **Patient resources and scope permissions
are not in the import** — they are created at runtime by the scripts:

```powershell
cd keycloak-config
.\seed-fhir-data.ps1          # creates patients -> HAPI registers them as UMA resources
.\setup-smart-v2-authz.ps1    # builds the scope permissions on those resources
```

### Method 2: Rebuild from a bare realm

If a realm **without** the authorization config is imported, `setup-smart-v2-authz.ps1` builds it
idempotently from scratch: it creates the patient users bernd/clara, the SMART-v2 scopes, the
role/user policies, the per-patient scope permissions, sets `uma_protection` as default client
scope and Decision Strategy to AFFIRMATIVE. Use `-CleanupLegacy` to also remove leftover objects
from older imports.

See [`../SETUP.md`](../SETUP.md) for the full sequence and troubleshooting.

---

## Owner Policy JAR (legacy / unused)

`keycloak-policies/keycloak-owner-policy.jar` is mounted into Keycloak via Compose:

```yaml
volumes:
  - ../keycloak-policies/keycloak-owner-policy.jar:/opt/keycloak/providers/keycloak-owner-policy.jar:ro
```

It is a remnant of an earlier script-based owner-policy approach. The **current realm does not use
it** — resource ownership is enforced through the `UserPolicy-*` user policies above. A
script-based policy also breaks realm export (`providerFactory is null`), which is why it was
dropped from the realm. The mount can be removed without affecting the demo.

---

## Service Account Roles

The fhir-client service account / admin-cli access needs these realm-management capabilities
(used by HAPI and the scripts to register resources and build permissions):
- `view-users`
- `manage-users`
- `manage-authorization`
- `view-realm`

(Configured in the realm export.)
