// Demo-Frontend-Backend fuer den UMA-geschuetzten HAPI FHIR Server.
//
// Warum ein Proxy und keine reine Browser-SPA?
//  - das client_secret bleibt serverseitig (in einer SPA laege es offen im JS)
//  - der UMA-Tanz (Access Token -> 401 mit Permission Ticket -> RPT -> Retry)
//    laeuft serverseitig; der WWW-Authenticate-Header ist hier ohne CORS-Tricks lesbar
//  - der Browser spricht nur mit diesem einen Origin

import express from 'express';
import session from 'express-session';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const KEYCLOAK = process.env.KEYCLOAK_URL || 'http://localhost:8080';
const FHIR_BASE = process.env.FHIR_URL || 'http://localhost:8081/fhir';
const REALM = 'FHIR-Auth';
const CLIENT_ID = 'fhir-client';
const CLIENT_SECRET = process.env.CLIENT_SECRET || 'QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP';
const TOKEN_URL = `${KEYCLOAK}/realms/${REALM}/protocol/openid-connect/token`;
const MASTER_TOKEN_URL = `${KEYCLOAK}/realms/master/protocol/openid-connect/token`;
const ADMIN_BASE = `${KEYCLOAK}/admin/realms/${REALM}`;
const UMA_GRANT = 'urn:ietf:params:oauth:grant-type:uma-ticket';

// Lese-Scopes je FHIR-Typ (nur Lesen, .rs) fuer die patientengesteuerte Freigabe.
const READ_SCOPE_BY_TYPE = {
  Patient: 'patient/Patient.rs',
  Condition: 'patient/Condition.rs',
  MedicationStatement: 'patient/MedicationStatement.rs',
  AllergyIntolerance: 'patient/AllergyIntolerance.rs',
};
const TYPE_LABELS = { Patient: 'Stammdaten', Condition: 'Diagnosen', MedicationStatement: 'Medikation', AllergyIntolerance: 'Allergien' };
// Nur klinische Instanzen sind einzeln sperrbar (Stammdaten = der ganze Patient).
const BLACKLISTABLE = ['Condition', 'MedicationStatement', 'AllergyIntolerance'];

const app = express();
app.use(express.json());
app.use(session({
  secret: 'uma-demo-not-for-production',
  resave: false,
  saveUninitialized: false,
}));

function decodeJwt(token) {
  try {
    const payload = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    return JSON.parse(Buffer.from(payload, 'base64').toString('utf8'));
  } catch {
    return {};
  }
}

// Holt ein Keycloak-Admin-Token (admin-cli, master-Realm).
async function getAdminToken() {
  const body = new URLSearchParams({
    grant_type: 'password',
    client_id: 'admin-cli',
    username: 'admin',
    password: 'admin',
  });
  const r = await fetch(MASTER_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!r.ok) return null;
  return (await r.json()).access_token;
}

// Liest alle in Keycloak registrierten Patient-Ressourcen (name "Patient/<id>")
// inkl. ihres Owners aus. Quelle der Wahrheit fuer die User->Patient-Verknuepfung.
// Liefert [{ id, ownerId, ownerName }]. (Die FHIR-Patient-Suche ist UMA-gesperrt,
// daher kommen Liste und Eigentuemer aus der Authorization-Konfiguration.)
let clientUuidCache = null;
async function getClientUuid(adminToken) {
  if (!clientUuidCache) {
    const cr = await fetch(`${ADMIN_BASE}/clients?clientId=${CLIENT_ID}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    clientUuidCache = (await cr.json())[0].id;
  }
  return clientUuidCache;
}

async function listKeycloakPatients(adminToken) {
  const cuid = await getClientUuid(adminToken);
  const rr = await fetch(
    `${ADMIN_BASE}/clients/${cuid}/authz/resource-server/resource?first=0&max=200&deep=true`,
    { headers: { Authorization: `Bearer ${adminToken}` } }
  );
  const resources = await rr.json();
  return resources
    .filter((r) => /^Patient\/\d+$/.test(r.name))
    .map((r) => ({
      id: r.name.replace('Patient/', ''),
      rsid: r._id,
      ownerId: r.owner?.id || null,
      ownerName: r.owner?.name || null,
    }));
}

// --- Login: Password Grant gegen Keycloak ---
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password) {
    return res.status(400).json({ error: 'username und password erforderlich' });
  }
  try {
    const body = new URLSearchParams({
      grant_type: 'password',
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      username,
      password,
    });
    const r = await fetch(TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
    if (!r.ok) {
      return res.status(401).json({ error: 'Login fehlgeschlagen' });
    }
    const tokens = await r.json();
    const claims = decodeJwt(tokens.access_token);
    req.session.accessToken = tokens.access_token;
    req.session.refreshToken = tokens.refresh_token;
    req.session.username = claims.preferred_username || username;
    req.session.roles = (claims.realm_access?.roles || []).filter(
      (role) => ['Doctor', 'Patient', 'Administrator'].includes(role)
    );
    req.session.rptCache = {};

    await resolvePatientContext(req.session, claims.sub);
    res.json({
      username: req.session.username,
      roles: req.session.roles,
      ownPatientId: req.session.ownPatientId,
      isDoctor: req.session.isDoctor,
      isPatient: req.session.ownPatientId != null,
      patients: req.session.patients,
    });
  } catch (e) {
    res.status(502).json({ error: 'Keycloak nicht erreichbar: ' + e.message });
  }
});

// Liefert die Patient-IDs, fuer die dem Arzt <username> eine Freigabe erteilt wurde.
// Eine Freigabe existiert genau dann, wenn eine Permission "Permission-Patient<id>-<username>"
// vorhanden ist (angelegt/geloescht durch /api/access/grant).
async function grantedPatientIds(adminToken, username) {
  const cuid = await getClientUuid(adminToken);
  const list = (await adminJson(adminToken, `${AUTHZ(cuid)}/policy?name=Permission-Patient&max=500`)) || [];
  const suffix = `-${username}`;
  const ids = new Set();
  for (const p of list) {
    const m = /^Permission-Patient(\d+)-(.+)$/.exec(p.name);
    if (m && p.name.endsWith(suffix)) ids.add(m[1]);
  }
  return ids;
}

// Bestimmt den Patientenkontext nach dem Login (Quelle: Keycloak-Authorization-Config).
// Rollenagnostisch — ein User kann gleichzeitig Patient UND Arzt sein:
//  - ownPatientId: der Patient, dessen Owner die eigene Keycloak-UUID (sub) ist
//    (eigener Datensatz), sofern vorhanden. Wird IMMER ermittelt, egal welche Rollen.
//  - isDoctor: hat die Doctor-Rolle -> darf die Patientenauswahl sehen.
//  - patients: Auswahlliste. Fuer Aerzte NUR die freigegebenen (fremden) Patienten;
//    der eigene Datensatz erscheint hier NICHT (nur in der Patient-Sicht ueber ownPatientId).
//    Fuer reine Patienten nur der eigene.
async function resolvePatientContext(session, sub) {
  session.ownPatientId = null;
  session.isDoctor = session.roles.includes('Doctor');
  session.patients = [];
  try {
    const adminToken = await getAdminToken();
    if (!adminToken) {
      console.warn('Patientenkontext: kein Admin-Token');
      return;
    }
    const all = await listKeycloakPatients(adminToken);
    const toEntry = (p) => ({ id: p.id, label: `${p.ownerName || 'Patient'} (Patient/${p.id})` });

    // Eigenen Datensatz immer suchen (unabhaengig von Rollen)
    const own = all.find((p) => p.ownerId === sub);
    if (own) {
      session.ownPatientId = own.id;
    }

    if (session.isDoctor) {
      // Arzt-Sicht: nur (fremde) Patienten, die diesem Arzt Zugriff gegeben haben.
      // Der eigene Datensatz gehoert NICHT hierher (nur in die Patient-Sicht).
      const granted = await grantedPatientIds(adminToken, session.username);
      session.patients = all
        .filter((p) => granted.has(p.id) && !(own && p.id === own.id))
        .sort((a, b) => Number(a.id) - Number(b.id))
        .map(toEntry);
    } else if (own) {
      // reiner Patient: nur der eigene
      session.patients = [toEntry(own)];
    }
  } catch (e) {
    console.warn('Patientenkontext konnte nicht aufgeloest werden:', e.message);
  }
}

app.post('/api/logout', (req, res) => {
  req.session.destroy(() => res.json({ ok: true }));
});

app.get('/api/me', async (req, res) => {
  if (!req.session.accessToken) return res.status(401).json({ error: 'nicht angemeldet' });
  // Patientenliste frisch aufloesen, damit neu erteilte/entzogene Freigaben sofort
  // in der Arzt-Auswahl erscheinen (ohne erneutes Login).
  const claims = decodeJwt(req.session.accessToken);
  await resolvePatientContext(req.session, claims.sub);
  res.json({
    username: req.session.username,
    roles: req.session.roles,
    ownPatientId: req.session.ownPatientId,
    isDoctor: req.session.isDoctor,
    isPatient: req.session.ownPatientId != null,
    patients: req.session.patients,
  });
});

// Tauscht ein Permission Ticket gegen ein RPT (mit Cache pro Ticket-Resource).
async function exchangeTicket(session, ticket) {
  const body = new URLSearchParams({
    grant_type: UMA_GRANT,
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    ticket,
    subject_token: session.accessToken,
  });
  const r = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!r.ok) return null;
  const json = await r.json();
  return json.access_token;
}

// Stellt sicher, dass das Access Token der Session noch gueltig ist. Keycloak Access
// Tokens leben nur ~5 Min; laeuft es (binnen 30s) ab, wird es per refresh_token erneuert.
// Ohne das schlaegt der UMA-Ticket-Tausch nach Ablauf mit access_denied fehl (-> faelschlich 403).
async function ensureFreshToken(session) {
  if (!session.accessToken) return false;
  const claims = decodeJwt(session.accessToken);
  const exp = claims.exp || 0;
  const stillValid = exp * 1000 - Date.now() > 30_000; // 30s Puffer
  if (stillValid) return true;
  if (!session.refreshToken) return false;
  try {
    const body = new URLSearchParams({
      grant_type: 'refresh_token',
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: session.refreshToken,
    });
    const r = await fetch(TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
    if (!r.ok) {
      console.warn('Token-Refresh fehlgeschlagen (Refresh-Token abgelaufen?):', r.status);
      return false;
    }
    const tokens = await r.json();
    session.accessToken = tokens.access_token;
    if (tokens.refresh_token) session.refreshToken = tokens.refresh_token;
    return true;
  } catch (e) {
    console.warn('Token-Refresh-Fehler:', e.message);
    return false;
  }
}

// Einzelner HTTP-Aufruf gegen den FHIR-Server (optional mit RPT statt Access Token).
async function fhirRequest(session, method, fhirPath, rpt) {
  const headers = { Accept: 'application/fhir+json' };
  if (rpt) headers.Authorization = `Bearer ${rpt}`;
  else if (session.accessToken) headers.Authorization = `Bearer ${session.accessToken}`;
  return fetch(`${FHIR_BASE}/${fhirPath}`, { method, headers });
}

// Fuehrt eine GET-FHIR-Anfrage inkl. vollem UMA-Flow aus und liefert
// { status, steps, payload }. Wird vom Proxy-Endpoint UND von der
// Login-Patientenaufloesung verwendet.
async function umaFetch(session, fhirPath) {
  const steps = [];
  // Access Token bei Bedarf erneuern, bevor der UMA-Flow startet
  const fresh = await ensureFreshToken(session);
  if (!fresh) {
    return { status: 440, steps, payload: { error: 'Sitzung abgelaufen. Bitte neu anmelden.' } };
  }
  // Schritt 1: Versuch mit dem Access Token (loest 401 + Permission Ticket aus)
  let response = await fhirRequest(session, 'GET', fhirPath, null);
  steps.push({ step: 'Access Token', status: response.status });

  if (response.status === 401) {
    const wwwAuth = response.headers.get('www-authenticate') || '';
    const ticketMatch = wwwAuth.match(/ticket="([^"]+)"/);
    if (ticketMatch) {
      steps.push({ step: 'Permission Ticket erhalten', status: 401 });
      const rpt = await exchangeTicket(session, ticketMatch[1]);
      if (!rpt) {
        steps.push({ step: 'RPT-Austausch', status: 'access_denied' });
        return { status: 403, steps, payload: { error: 'Keycloak verweigert RPT (access_denied)' } };
      }
      const rptClaims = decodeJwt(rpt);
      const rptScopes = (rptClaims.authorization?.permissions || [])
        .flatMap((p) => (p.scopes || []).map((s) => `${p.rsname}: ${s}`));
      steps.push({ step: 'RPT erhalten', status: 200, scopes: rptScopes });

      // Schritt 4: erneuter Zugriff mit RPT
      response = await fhirRequest(session, 'GET', fhirPath, rpt);
      steps.push({ step: 'Zugriff mit RPT', status: response.status });
    }
  }

  const text = await response.text();
  let payload;
  try { payload = JSON.parse(text); } catch { payload = text; }
  return { status: response.status, steps, payload };
}

// --- Generischer FHIR-Proxy mit UMA-Dance ---
// GET /api/fhir/<fhirPath>  (z.B. Patient/1, Condition?patient=1, Patient/1/$summary)
app.get('/api/fhir/*', async (req, res) => {
  if (!req.session.accessToken) return res.status(401).json({ error: 'nicht angemeldet' });

  const fhirPath = req.params[0] + (req._parsedUrl.search || '');
  try {
    const result = await umaFetch(req.session, fhirPath);
    res.status(result.status).json({ status: result.status, steps: result.steps, resource: result.payload });
  } catch (e) {
    res.status(502).json({ error: 'FHIR-Server nicht erreichbar: ' + e.message, steps: [] });
  }
});

// ============================================================================
// Patientengesteuerte Zugriffsverwaltung
// Der Patient (Owner) gibt Aerzten pro Ressourcentyp Lesezugriff frei (Trust-List
// + SMART-Scopes) und sperrt einzelne Instanzen (Blacklist). Alles laeuft ueber den
// Admin-Token, NACHDEM der Proxy geprueft hat, dass der eingeloggte User Owner der
// Ziel-Ressource ist (sessionOwner). Naming: Permission/TrustList-Patient<id>-<arzt>,
// Blacklist-<patId>-<resType>-<resId>-<docId> (vgl. UmaBlacklistService).
// ============================================================================
const AUTHZ = (cuid) => `${ADMIN_BASE}/clients/${cuid}/authz/resource-server`;

function sessionOwner(req, res) {
  if (!req.session.accessToken) { res.status(401).json({ error: 'nicht angemeldet' }); return null; }
  if (!req.session.ownPatientId) { res.status(403).json({ error: 'kein eigener Patient-Datensatz' }); return null; }
  return String(req.session.ownPatientId);
}

async function adminJson(adminToken, url) {
  const r = await fetch(url, { headers: { Authorization: `Bearer ${adminToken}` } });
  return r.ok ? r.json() : null;
}
async function adminSend(adminToken, method, url, body) {
  const opts = { method, headers: { Authorization: `Bearer ${adminToken}` } };
  if (body !== undefined) { opts.headers['Content-Type'] = 'application/json'; opts.body = JSON.stringify(body); }
  return fetch(url, opts);
}
async function listDoctors(adminToken) {
  const users = (await adminJson(adminToken, `${ADMIN_BASE}/roles/Doctor/users?max=200`)) || [];
  return users.map((u) => ({ id: u.id, username: u.username, name: `${u.firstName || ''} ${u.lastName || ''}`.trim() || u.username }));
}
// Zieht den FHIR-category-Code + ein lesbares Label aus einer klinischen Ressource.
// Condition/AllergyIntolerance haben ein category-Array (CodeableConcept); MedicationStatement
// (R5) nicht -> Fallback. Ressourcen ohne Kategorie landen unter 'uncategorized'.
function extractCategory(resource) {
  const cc = Array.isArray(resource.category) ? resource.category[0] : null;
  const coding = cc?.coding?.[0];
  const code = coding?.code || (cc?.text ? cc.text : null);
  if (!code) return { code: 'uncategorized', label: 'Ohne Kategorie' };
  const label = coding?.display || cc?.text || code;
  return { code, label };
}
async function getScopeIds(adminToken) {
  const cuid = await getClientUuid(adminToken);
  const scopes = (await adminJson(adminToken, `${AUTHZ(cuid)}/scope?max=200`)) || [];
  const map = {};
  for (const s of scopes) map[s.name] = s.id;
  return map;
}
async function findPolicyByName(adminToken, name) {
  const cuid = await getClientUuid(adminToken);
  const list = (await adminJson(adminToken, `${AUTHZ(cuid)}/policy?name=${encodeURIComponent(name)}&max=100`)) || [];
  return list.find((p) => p.name === name) || null;
}
async function ensureUserPolicy(adminToken, name, userId) {
  const existing = await findPolicyByName(adminToken, name);
  if (existing) return existing.id;
  const cuid = await getClientUuid(adminToken);
  const r = await adminSend(adminToken, 'POST', `${AUTHZ(cuid)}/policy/user`,
    { name, type: 'user', logic: 'POSITIVE', decisionStrategy: 'UNANIMOUS', users: [userId] });
  return (await r.json()).id;
}
async function permissionScopeNames(adminToken, permId) {
  const cuid = await getClientUuid(adminToken);
  const scopes = (await adminJson(adminToken, `${AUTHZ(cuid)}/policy/${permId}/scopes`)) || [];
  return scopes.map((s) => s.name);
}
async function upsertScopePermission(adminToken, name, rsid, scopeIds, policyIds) {
  const cuid = await getClientUuid(adminToken);
  const body = { name, type: 'scope', logic: 'POSITIVE', decisionStrategy: 'UNANIMOUS', resources: [rsid], scopes: scopeIds, policies: policyIds };
  const existing = await findPolicyByName(adminToken, name);
  if (existing) {
    body.id = existing.id;
    await adminSend(adminToken, 'PUT', `${AUTHZ(cuid)}/permission/scope/${existing.id}`, body);
  } else {
    await adminSend(adminToken, 'POST', `${AUTHZ(cuid)}/permission/scope`, body);
  }
}
async function deletePolicyByName(adminToken, name) {
  const cuid = await getClientUuid(adminToken);
  const p = await findPolicyByName(adminToken, name);
  if (p) await adminSend(adminToken, 'DELETE', `${AUTHZ(cuid)}/policy/${p.id}`);
}
async function listBlacklistNames(adminToken) {
  const cuid = await getClientUuid(adminToken);
  const list = (await adminJson(adminToken, `${AUTHZ(cuid)}/policy?name=Blacklist-&max=500`)) || [];
  return new Set(list.filter((p) => p.name.startsWith('Blacklist-')).map((p) => p.name));
}

// --- Aktueller Freigabe-Zustand fuer den eigenen Patienten ---
app.get('/api/access/state', async (req, res) => {
  const patientId = sessionOwner(req, res);
  if (!patientId) return;
  try {
    const adminToken = await getAdminToken();
    if (!adminToken) return res.status(502).json({ error: 'Kein Admin-Token' });

    // Sich selbst nicht auflisten: ein Arzt verwaltet in seiner eigenen Patient-Sicht
    // keine Freigaben/Sperren fuer sich selbst.
    const doctors = (await listDoctors(adminToken)).filter((d) => d.username !== req.session.username);
    const blacklist = await listBlacklistNames(adminToken);

    // gewaehrte Scope-Typen je Arzt aus der (patient,arzt)-Permission
    const docState = [];
    for (const d of doctors) {
      const perm = await findPolicyByName(adminToken, `Permission-Patient${patientId}-${d.username}`);
      let scopes = [];
      if (perm) {
        const names = await permissionScopeNames(adminToken, perm.id);
        scopes = Object.keys(READ_SCOPE_BY_TYPE).filter((t) => names.includes(READ_SCOPE_BY_TYPE[t]));
      }
      docState.push({ id: d.id, username: d.username, name: d.name, scopes });
    }

    // eigene Instanzen via UMA-Dance als Owner holen (inkl. FHIR-category zur Gruppierung)
    const instances = [];
    for (const t of BLACKLISTABLE) {
      const r = await umaFetch(req.session, `${t}?patient=${patientId}`);
      for (const e of (r.status === 200 ? r.payload?.entry || [] : [])) {
        const r0 = e.resource;
        if (!r0?.id) continue;
        const label = r0.code?.text || r0.code?.coding?.[0]?.display || r0.medication?.concept?.text || t;
        const { code, label: catLabel } = extractCategory(r0);
        instances.push({ type: t, id: r0.id, label, category: code, categoryLabel: catLabel });
      }
    }
    // Blacklist je Arzt aufloesen
    for (const d of docState) {
      d.blacklist = instances
        .filter((i) => blacklist.has(`Blacklist-${patientId}-${i.type}-${i.id}-${d.id}`))
        .map((i) => `${i.type}/${i.id}`);
    }

    res.json({
      patientId,
      types: Object.keys(READ_SCOPE_BY_TYPE).map((k) => ({ key: k, label: TYPE_LABELS[k] })),
      doctors: docState,
      instances,
    });
  } catch (e) {
    res.status(502).json({ error: e.message });
  }
});

// --- Scopes fuer einen Arzt setzen (leere Liste = komplett entziehen) ---
app.post('/api/access/grant', async (req, res) => {
  const patientId = sessionOwner(req, res);
  if (!patientId) return;
  const { doctorId, scopes } = req.body || {};
  const types = Array.isArray(scopes) ? scopes.filter((t) => READ_SCOPE_BY_TYPE[t]) : [];
  try {
    const adminToken = await getAdminToken();
    const doc = (await listDoctors(adminToken)).find((d) => d.id === doctorId);
    if (!doc) return res.status(400).json({ error: 'Unbekannter Arzt' });
    if (doc.username === req.session.username) return res.status(400).json({ error: 'Selbstfreigabe nicht erlaubt' });

    const permName = `Permission-Patient${patientId}-${doc.username}`;
    const trustName = `TrustList-Patient${patientId}-${doc.username}`;
    if (types.length === 0) {
      await deletePolicyByName(adminToken, permName);
      await deletePolicyByName(adminToken, trustName);
      return res.json({ ok: true, scopes: [] });
    }
    const rsid = (await listKeycloakPatients(adminToken)).find((p) => p.id === patientId)?.rsid;
    if (!rsid) return res.status(404).json({ error: 'Eigene Ressource nicht gefunden' });

    const scopeIdMap = await getScopeIds(adminToken);
    const scopeIds = types.map((t) => scopeIdMap[READ_SCOPE_BY_TYPE[t]]).filter(Boolean);
    const trustPolId = await ensureUserPolicy(adminToken, trustName, doc.id);
    const rolePol = await findPolicyByName(adminToken, 'RolePolicy-Doctor');
    const policyIds = rolePol ? [trustPolId, rolePol.id] : [trustPolId];
    await upsertScopePermission(adminToken, permName, rsid, scopeIds, policyIds);
    res.json({ ok: true, scopes: types });
  } catch (e) {
    res.status(502).json({ error: e.message });
  }
});

// --- Einzelne Instanz fuer einen Arzt sperren/entsperren (Blacklist) ---
app.post('/api/access/blacklist', async (req, res) => {
  const patientId = sessionOwner(req, res);
  if (!patientId) return;
  const { doctorId, resourceType, resourceId, blocked } = req.body || {};
  if (!BLACKLISTABLE.includes(resourceType) || !resourceId) {
    return res.status(400).json({ error: 'Ungueltige Ressource' });
  }
  try {
    const adminToken = await getAdminToken();
    const doc = (await listDoctors(adminToken)).find((d) => d.id === doctorId);
    if (!doc) return res.status(400).json({ error: 'Unbekannter Arzt' });
    if (doc.username === req.session.username) return res.status(400).json({ error: 'Selbstsperre nicht erlaubt' });

    const name = `Blacklist-${patientId}-${resourceType}-${resourceId}-${doc.id}`;
    if (blocked) await ensureUserPolicy(adminToken, name, doc.id);
    else await deletePolicyByName(adminToken, name);
    res.json({ ok: true, blocked: !!blocked });
  } catch (e) {
    res.status(502).json({ error: e.message });
  }
});

app.use(express.static(path.join(__dirname, 'public')));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`UMA FHIR Frontend laeuft auf http://localhost:${PORT}`);
  console.log(`  Keycloak: ${KEYCLOAK}`);
  console.log(`  FHIR:     ${FHIR_BASE}`);
});
