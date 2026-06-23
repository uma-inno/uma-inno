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

> **Keycloak-Version (wichtig):** Das Compose pinnt das Image bewusst auf
> `quay.io/keycloak/keycloak:26.6.3`. Der Realm-Export (`fhir-auth-realm-export.json`)
> wurde mit dieser Version erzeugt (`"keycloakVersion": "26.6.3"`). Eine **ältere**
> Keycloak-Version bricht den Import mit `Unrecognized field "..."` ab (z.B.
> `scimApiEnabled`, `maxSecondaryAuthFailures`). Wird die Version angehoben, den Image-Tag
> an die `keycloakVersion` im Export anpassen — **nicht** `:latest` verwenden, da der
> `latest`-Stand älter als der Export sein kann.

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
`keycloak-config/keycloak-files/`. Dort darf **genau eine** Realm-Datei liegen
(`fhir-auth-realm-export.json`); `--import-realm` würde sonst mehrere Realms importieren und
es käme zu Konflikten.

> **Was der Import enthält — und was nicht:** Der Export liefert den Grund-Realm: Users
> (alice, bernd, clara, dr.bob, dr.smith, jan), Rollen, den Client `fhir-client` (Secret,
> `uma_protection`), die 5 SMART-v2-Scopes, die Role-/User-Policies und Decision Strategy
> AFFIRMATIVE. Er enthält **bewusst KEINE** Patient-Ressourcen und **keine** scope-Permissions
> — diese referenzieren user-owned UMA-Ressourcen, die sich über den Realm-Import nicht
> zuverlässig wiederherstellen lassen (Keycloak: *"Resource [Patient/1] … not owned by the
> resource server"*). Sie entstehen stattdessen zur Laufzeit in Schritt 4. Die Schritte 3+4
> sind daher **Pflicht**, kein optionaler Fallback.

---

## 3. Auf Bereitschaft warten

```bash
# Keycloak-Realm erreichbar?
curl -s http://localhost:8080/realms/FHIR-Auth/.well-known/uma2-configuration
# HAPI erreichbar? (kann 1-2 Minuten dauern)
curl -s http://localhost:8081/fhir/metadata
```

> **Wichtig — Reihenfolge HAPI ↔ Keycloak:** HAPI baut beim Start seinen Keycloak-Admin-Client
> auf (um Patient-Ressourcen registrieren zu können). `depends_on` wartet nur darauf, dass der
> Keycloak-**Container** läuft, **nicht** darauf, dass Keycloak den Realm fertig importiert hat
> und bereit ist. Startet HAPI, bevor Keycloak antwortet, bleibt der Client uninitialisiert und
> das spätere Seeden registriert die Patienten **nicht** (HAPI-Log:
> `Failed to register resource Patient/1: … templateValues entry was null`).
>
> **Workaround:** Sobald Keycloak antwortet (`uma2-configuration` liefert 200), HAPI einmal
> neu starten, **bevor** geseedet wird:
> ```bash
> docker compose restart hapi-fhir-jpaserver-start
> ```
> Erfolg prüfen:
> ```bash
> docker logs hapi-fhir-jpaserver-start | grep "KeycloakResourceService initialized successfully"
> ```

---

## 4. Demo-Daten + Autorisierung aufbauen (Pflicht)

Die HAPI-Datenbank startet **leer**. Diese beiden Skripte legen die Patienten an und bauen die
Permissions auf den dabei registrierten Ressourcen auf:

```powershell
cd keycloak-config
.\seed-fhir-data.ps1          # Patienten alice/bernd/clara + klinische Ressourcen
.\setup-smart-v2-authz.ps1    # scope-Permissions auf die nun registrierten Patient/<id>
```

`seed-fhir-data.ps1` legt die drei Patienten (Alice → Patient/1, Bernd → Patient/7,
Clara → Patient/11) und ihre klinischen Ressourcen per FHIR-POST an. Die FHIR-IDs 1/7/11
ergeben sich aus der Anlagereihenfolge auf einer leeren DB. Jeder neue Patient wird vom
`ResourceRegistrationInterceptor` automatisch als UMA-Ressource in Keycloak registriert
(Owner = Keycloak-UUID des Patienten, zur Laufzeit aufgelöst — nicht hartkodiert).

`setup-smart-v2-authz.ps1` ist idempotent und legt auf den registrierten Patient-Ressourcen die
scope-Permissions an (Owner-Vollzugriff + die Arzt-Freigaben gemäß Demo-Szenario), setzt
`uma_protection` als Default-Scope und Decision Strategy AFFIRMATIVE. Mit `-CleanupLegacy`
entfernt es zusätzlich Altobjekte aus früheren Importen.

> **Reihenfolge seed → setup:** `setup-smart-v2-authz.ps1` verarbeitet nur Patient-Ressourcen,
> die bereits in Keycloak registriert sind — die entstehen erst beim Seeden. Läuft setup vor dem
> Seed, meldet es „Noch keine Patient/<id>-Ressourcen registriert" und legt keine Permissions an.
> (Die Patienten-User bernd/clara sind im Export bereits enthalten; das Skript legt sie nur an,
> falls sie fehlen.)

---

## 5. Verifikation

> Hinweis: Das in früheren Ständen erwähnte `test-uma-flow.ps1` ist auf diesem Branch nicht mehr
> vorhanden. Der volle UMA-Flow lässt sich am einfachsten über den **Frontend-Proxy** prüfen, der
> den UMA-Dance (Access Token → 401 + Permission Ticket → RPT → Zugriff) serverseitig durchführt.

```bash
# Login (Session-Cookie -> cj.txt), danach FHIR-Zugriff über den Proxy (alice = Owner):
curl -s -c cj.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" -d '{"username":"alice","password":"alice123"}'
curl -s -b cj.txt -o NUL -w "%{http_code}\n" http://localhost:3000/api/fhir/Patient/1   # -> 200
```

**Owner-Zugriff** (immer verfügbar, jeder Patient auf sich selbst):

| User | Pfad | Status | Grund |
|---|---|---|---|
| alice | `Patient/1` | **200** | Owner, Vollzugriff |
| bernd | `Patient/7` | **200** | Owner von Patient/7 |
| bernd | `Patient/1` | **403** | kein Zugriff auf fremden Patienten |
| clara | `Patient/11` | **200** | Owner von Patient/11 |

**Arzt-Zugriff** ist standardmäßig **leer** — er entsteht erst, wenn der Patient ihn im Frontend
freigibt (Sicht „Als Patient" → „Zugriffsverwaltung"). Beispiel nach Freigabe „Diagnosen" durch alice:

| User | Pfad | vor Freigabe | nach Freigabe |
|---|---|---|---|
| dr.smith | `Condition?patient=1` | **403** | **200** |
| dr.smith | `Patient/1` (Stammdaten) | **403** | weiterhin **401/403**, solange „Stammdaten" nicht freigegeben |

Oder im Browser: **http://localhost:3000** — Login als alice/bernd/clara oder dr.smith/dr.bob.
In der „Als Patient"-Sicht erscheint die **Zugriffsverwaltung**, in der der Patient pro Arzt
Lese-Scopes freigibt und einzelne Einträge sperrt. Die UMA-Schritte/RPT-Scopes bleiben sichtbar.

---

## 6. Bekannte Probleme & Lösungen

| Problem | Ursache | Lösung |
|---|---|---|
| Keycloak-Crashloop, `Unrecognized field "..."` beim Import | Image-Version älter als die `keycloakVersion` im Export | Image-Tag an den Export anpassen (aktuell `26.6.3`), **nicht** `:latest` |
| Keycloak-Crashloop, `Resource … [Patient/1] … not owned by the resource server` | user-owned UMA-Ressourcen + scope-Permissions im Realm-Export sind nicht re-importierbar | aus dem Export entfernen, zur Laufzeit über seed + `setup-smart-v2-authz.ps1` aufbauen (die mitgelieferte Datei ist bereits so zugeschnitten) |
| Seed registriert keine Patienten, HAPI-Log `templateValues entry was null` | HAPI startete, bevor Keycloak bereit war → Keycloak-Client uninitialisiert | HAPI nach Keycloak-Bereitschaft neu starten, **dann** seeden (siehe Schritt 3) |
| `setup-smart-v2-authz.ps1`: „Noch keine Patient/<id>-Ressourcen registriert" | Seed noch nicht gelaufen | zuerst `seed-fhir-data.ps1`, dann setup erneut |
| Mehrere Realm-Dateien im Import-Ordner | `--import-realm` importiert alle JSONs → Konflikt/falscher Realm gewinnt | nur `fhir-auth-realm-export.json` im Ordner lassen |
| `access_denied: request_submitted` | `ownerManagedAccess=true` auf der Ressource | per Admin-API auf `false` setzen (macht `setup-smart-v2-authz.ps1`) |

---

## 7. Realm neu exportieren (nach Konfigurationsänderungen)

```bash
docker exec keycloak-uma /opt/keycloak/bin/kc.sh export \
  --dir /tmp/realm-export --realm FHIR-Auth --users realm_file
docker cp keycloak-uma:/tmp/realm-export/FHIR-Auth-realm.json \
  ./keycloak-config/keycloak-files/fhir-auth-realm-export.json
```

> **Achtung — vor dem Wiederverwenden als Import-Datei aufräumen:** Ein frischer Export enthält
> die zur Laufzeit angelegten **user-owned Patient-Ressourcen + scope-Permissions** wieder — und
> genau die lassen sich nicht re-importieren (siehe Schritt 6). Daher in der exportierten Datei
> beim Client `fhir-client` die `authorizationSettings.resources` leeren und die Policies vom
> Typ `scope` entfernen (Role-/User-Policies und Scopes bleiben erhalten). Diese Objekte werden
> in Schritt 4 ohnehin neu erzeugt. Eine script-basierte Policy (`script-owner-policy.js`) würde
> den Export zudem mit `providerFactory is null` scheitern lassen — diese Altlast vorher entfernen.

---

## 8. Zurücksetzen

```bash
cd hapi-jpa
docker compose down            # Container stoppen, Volumes bleiben
docker compose down -v         # Container UND Volumes löschen (kompletter Reset)
```

Nach `down -v` startet alles frisch: Keycloak importiert den Realm neu, die HAPI-DB ist leer →
Schritte 3-4 erneut ausführen (inkl. HAPI-Neustart vor dem Seed).
