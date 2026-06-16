# Setup-Anleitung: UMA-geschützter FHIR-Server auf einer neuen Maschine

Diese Anleitung beschreibt, wie der komplette Stack (HAPI FHIR + Keycloak + Demo-Frontend)
auf einer frischen Maschine eingerichtet wird, inkl. Keycloak-Realm und Demo-Daten.

> Plattform-Hinweis: Die Hilfsskripte liegen als **PowerShell** (`.ps1`) vor. Auf
> Linux/macOS lassen sie sich mit `pwsh` ausführen oder die enthaltenen `curl`-Aufrufe
> manuell nachvollziehen (siehe `keycloak-config/curl-testing-commands.md`).

---

## 1. Voraussetzungen

- **Docker** + **Docker Compose** (Daemon läuft)
- **PowerShell** (Windows) oder **pwsh** (Linux/macOS) für die Setup-/Seed-Skripte
- Freie Ports: `8080` (Keycloak), `8081` (HAPI FHIR), `3000` (Frontend),
  `5432`/`5433` (PostgreSQL)

---

## 2. Stack starten

Im Verzeichnis `hapi-jpa/`:

```bash
docker compose up -d --build
```

Das startet fünf Container:

| Service | Container | Port | Zugang |
|---|---|---|---|
| Keycloak | `keycloak-uma` | 8080 | admin / admin |
| HAPI FHIR | `hapi-fhir-jpaserver-start` | 8081 | — |
| Keycloak-DB | `keycloak-postgres` | 5433 | keycloak / keycloak |
| HAPI-DB | `hapi-fhir-postgres` | 5432 | admin / admin |
| Frontend | `uma-frontend` | 3000 | — |

Keycloak importiert beim ersten Start automatisch den Realm aus dem gemounteten Ordner
`keycloak-config/keycloak-files/` (`--import-realm`). Dort liegt genau eine Realm-Datei,
`fhir-auth-realm-export.json`, mit dem vollständigen Stand (SMART-v2-Scopes, alle Patienten,
Permissions, Decision Strategy AFFIRMATIVE). Der Realm ist damit nach dem Start **sofort
vollständig** — Schritt 3 ist nur ein Fallback und kann normalerweise übersprungen werden.

> Lege keine zweite Realm-Datei in diesen Ordner: `--import-realm` würde sonst beide
> importieren und es käme zu Konflikten.

Warten bis Keycloak bereit ist:

```bash
# Realm erreichbar?
curl -s http://localhost:8080/realms/FHIR-Auth/.well-known/uma2-configuration
# HAPI erreichbar? (kann 1-2 Minuten dauern)
curl -s http://localhost:8081/fhir/metadata
```

---

## 3. (Fallback) Konfiguration per Skript aufbauen

Nur nötig, wenn der Realm **ohne** die fertige Konfiguration importiert wurde (z.B. ein
nackter Realm ohne Authorization-Settings). Dieses Skript baut die SMART-v2-Konfiguration
idempotent nach (User bernd/clara, SMART-Scopes, Policies, Permissions, Decision Strategy):

```powershell
cd keycloak-config
.\setup-smart-v2-authz.ps1
```

Beim normalen Setup mit `fhir-auth-realm-export.json` ist dieser Schritt **nicht** nötig.

---

## 4. Demo-FHIR-Daten anlegen (Seed)

Die HAPI-Datenbank startet **leer**. Dieses Skript legt die drei Patienten (Alice, Bernd,
Clara) und ihre klinischen Ressourcen an. Es löst die Keycloak-UUIDs **zur Laufzeit** auf,
damit der `keycloak-uuid`-Identifier jedes Patienten zum echten User passt:

```powershell
cd keycloak-config
.\seed-fhir-data.ps1
```

Anschließend die Permissions auf die nun real registrierten Patient-Ressourcen legen:

```powershell
.\setup-smart-v2-authz.ps1
```

> **Reihenfolge-Logik:** `setup-smart-v2-authz.ps1` verarbeitet nur Patient-Ressourcen,
> die in Keycloak bereits registriert sind. Diese entstehen erst beim Anlegen der
> Patienten in HAPI (`seed-fhir-data.ps1`), da der `ResourceRegistrationInterceptor`
> jeden neuen Patienten automatisch als UMA-Ressource registriert. Deshalb: **seed →
> setup** (oder setup → seed → setup, wenn auch die User erst angelegt werden müssen).

> **Owner-Registrierung — bekannte Stolperfalle:** Die automatische Registrierung durch
> HAPI kann mit HTTP 500 fehlschlagen (`Owner must be a valid username or user
> identifier`), wenn der `keycloak-uuid` eines Patienten nicht zu einem existierenden
> Keycloak-User passt. Beim Import des **fertigen Exports** tritt das nicht auf, weil die
> UUIDs fixiert sind. Falls doch: betroffene Patient-Ressource per Admin-API mit korrekter
> Owner-UUID neu registrieren (siehe `setup-smart-v2-authz.ps1`, Abschnitt Permissions).

---

## 5. Verifikation

```powershell
cd keycloak-config
.\test-uma-flow.ps1 -Username dr.smith -Password smith123 -ResourcePath Patient/1   # 200
.\test-uma-flow.ps1 -Username dr.bob   -Password bob123   -ResourcePath Patient/1   # 401 (kein Patient-Scope)
.\test-uma-flow.ps1 -Username alice    -Password alice123 -ResourcePath Patient/1   # 200
```

Oder im Browser: **http://localhost:3000**
- `alice` / `alice123` (Patient) → sieht eigene Daten (Patient/1) vollständig
- `bernd` / `bernd123` (Patient) → sieht eigene Daten (Patient/7)
- `clara` / `clara123` (Patient) → sieht eigene Daten (Patient/11)
- `dr.smith` / `smith123` (Arzt) → darf Patient/1 lesen (auf Alices TrustList)
- `dr.bob` / `bob123` (Arzt) → darf nur Conditions von Patient/1, nicht die Stammdaten

---

## 6. Realm neu exportieren (nach Konfigurationsänderungen)

Wenn die Keycloak-Konfiguration geändert wurde und der Export aktualisiert werden soll:

```bash
docker exec keycloak-uma /opt/keycloak/bin/kc.sh export \
  --dir /tmp/realm-export --realm FHIR-Auth --users realm_file
docker cp keycloak-uma:/tmp/realm-export/FHIR-Auth-realm.json \
  ./keycloak-config/keycloak-files/fhir-auth-realm-export.json
```

> Der Export schlägt fehl, wenn eine **script-basierte Policy** (`script-owner-policy.js`)
> im Realm existiert (`providerFactory is null`). Diese ist eine Altlast und wird nicht
> mehr benötigt — vorher entfernen.

---

## 7. Zurücksetzen

```bash
cd hapi-jpa
docker compose down            # Container stoppen, Volumes bleiben
docker compose down -v         # Container UND Volumes löschen (kompletter Reset)
```

Nach `down -v` startet alles frisch: Keycloak importiert den Realm neu, die HAPI-DB ist
leer → Schritt 4 (Seed) erneut ausführen.
