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
// Vollstaendiger SMART-v2-Scope-Satz an der Patient-Ressource (wie setup-smart-v2-authz.ps1).
// Der Owner bekommt darauf Vollzugriff, damit er seine eigenen Daten lesen kann.
const SMART_SCOPES = ['patient/Patient.r', 'patient/Patient.rs', 'patient/Condition.rs', 'patient/MedicationStatement.rs', 'patient/AllergyIntolerance.rs'];

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
      isAdmin: req.session.roles.includes('Administrator'),
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
    isAdmin: req.session.roles.includes('Administrator'),
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

// Fuehrt eine GET-FHIR-Anfrage inkl. vollem UMA-Dance aus und liefert
// { status, payload }. Wird vom Proxy-Endpoint UND von der
// Login-Patientenaufloesung verwendet.
async function umaFetch(session, fhirPath) {
  // Access Token bei Bedarf erneuern, bevor der UMA-Flow startet
  const fresh = await ensureFreshToken(session);
  if (!fresh) {
    return { status: 440, payload: { error: 'Sitzung abgelaufen. Bitte neu anmelden.' } };
  }
  // Schritt 1: Versuch mit dem Access Token (loest 401 + Permission Ticket aus)
  let response = await fhirRequest(session, 'GET', fhirPath, null);

  if (response.status === 401) {
    const wwwAuth = response.headers.get('www-authenticate') || '';
    const ticketMatch = wwwAuth.match(/ticket="([^"]+)"/);
    if (ticketMatch) {
      // Schritt 2/3: Permission Ticket gegen RPT tauschen
      const rpt = await exchangeTicket(session, ticketMatch[1]);
      if (!rpt) {
        return { status: 403, payload: { error: 'Keycloak verweigert RPT (access_denied)' } };
      }
      // Schritt 4: erneuter Zugriff mit RPT
      response = await fhirRequest(session, 'GET', fhirPath, rpt);
    }
  }

  const text = await response.text();
  let payload;
  try { payload = JSON.parse(text); } catch { payload = text; }
  return { status: response.status, payload };
}

// --- Generischer FHIR-Proxy mit UMA-Dance ---
// GET /api/fhir/<fhirPath>  (z.B. Patient/1, Condition?patient=1, Patient/1/$summary)
app.get('/api/fhir/*', async (req, res) => {
  if (!req.session.accessToken) return res.status(401).json({ error: 'nicht angemeldet' });

  const fhirPath = req.params[0] + (req._parsedUrl.search || '');
  try {
    const result = await umaFetch(req.session, fhirPath);
    res.status(result.status).json({ status: result.status, resource: result.payload });
  } catch (e) {
    res.status(502).json({ error: 'FHIR-Server nicht erreichbar: ' + e.message });
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
// Loescht Instanz-Sperren (Blacklist-Marker) fuer (patient, arzt), deren Typ NICHT in
// keepTypes steht. Wird beim Entziehen eines Scopes aufgerufen: ohne Lese-Freigabe ergibt
// eine Instanz-Sperre keinen Sinn, also raeumen wir die verwaisten Marker mit auf.
// Namensschema: Blacklist-{patId}-{ResType}-{ResId}-{DocId} (DocId ist eine UUID mit '-').
async function cleanupBlacklistForRevokedTypes(adminToken, patientId, docId, keepTypes) {
  const prefix = `Blacklist-${patientId}-`;
  const suffix = `-${docId}`;
  const names = await listBlacklistNames(adminToken);
  for (const name of names) {
    if (!name.startsWith(prefix) || !name.endsWith(suffix)) continue;
    const rest = name.slice(prefix.length);         // "{ResType}-{ResId}-{DocId}"
    const type = rest.slice(0, rest.indexOf('-'));  // "{ResType}"
    if (type && !keepTypes.includes(type)) {
      await deletePolicyByName(adminToken, name);
    }
  }
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
    // Verwaiste Instanz-Sperren fuer nicht mehr freigegebene Typen entfernen.
    await cleanupBlacklistForRevokedTypes(adminToken, patientId, doc.id, types);
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

// ============================================================================
// Admin: User & klinische Daten anlegen
// - Patient: KC-User (Rolle Patient) + verknuepfte FHIR-Patient-Ressource.
// - Arzt: KC-User (Rollen Doctor + Patient) + eigener FHIR-Patient-Datensatz
//   (wie dr.smith/dr.bob), damit die "Als Patient"-Sicht funktioniert.
// - Klinische Daten: Condition/MedicationStatement/AllergyIntolerance fuer einen
//   waehlbaren Patienten.
// Ein "Patient" besteht aus (a) einem Keycloak-User und (b) einer FHIR-Patient-
// Ressource, die per identifier[keycloak-uuid] mit dem User verknuepft ist. Der
// HAPI-Interceptor registriert die Patient/<id>-Ressource danach automatisch in
// Keycloak mit dem User als Owner. Nur Administratoren duerfen das (RBAC im Proxy
// + im FHIR-Interceptor).
// ============================================================================

// Richtet fuer eine frisch angelegte Patient-Ressource den Owner-Vollzugriff ein,
// analog zu setup-smart-v2-authz.ps1. Ohne das erhaelt der Patient kein RPT auf den
// eigenen Datensatz (Keycloak verweigert -> "Kein Zugriff" auf die eigenen Daten).
//   1. Ressource: ownerManagedAccess=false + alle SMART-Scopes anhaengen
//      (OMA=true fuehrt zu access_denied: request_submitted).
//   2. UserPolicy-Owner-<username> (verweist auf die User-UUID)
//   3. Permission-Patient<id>-Owner-Full (scope, alle SMART-Scopes, Owner-Policy)
async function grantOwnerFullAccess(adminToken, patientId, userId, username) {
  const cuid = await getClientUuid(adminToken);
  const resourceName = `Patient/${patientId}`;
  const found = (await adminJson(adminToken, `${AUTHZ(cuid)}/resource?name=${encodeURIComponent(resourceName)}&deep=true`)) || [];
  const resource = found.find((r) => r.name === resourceName);
  if (!resource) throw new Error(`Registrierte Ressource ${resourceName} nicht gefunden`);

  // 1. OMA=false + SMART-Scopes an der Ressource setzen
  await adminSend(adminToken, 'PUT', `${AUTHZ(cuid)}/resource/${resource._id}`, {
    _id: resource._id, name: resource.name, displayName: resource.name, type: resource.type,
    owner: { id: resource.owner?.id || userId }, ownerManagedAccess: false,
    scopes: SMART_SCOPES.map((name) => ({ name })),
  });

  // 2. Owner-Policy + 3. Owner-Vollzugriffs-Permission
  const ownerPolId = await ensureUserPolicy(adminToken, `UserPolicy-Owner-${username}`, userId);
  const scopeIdMap = await getScopeIds(adminToken);
  const scopeIds = SMART_SCOPES.map((s) => scopeIdMap[s]).filter(Boolean);
  await upsertScopePermission(adminToken, `Permission-Patient${patientId}-Owner-Full`, resource._id, scopeIds, [ownerPolId]);
}

// Stellt sicher, dass der eingeloggte User Administrator ist.
function requireAdmin(req, res) {
  if (!req.session.accessToken) { res.status(401).json({ error: 'nicht angemeldet' }); return false; }
  if (!req.session.roles?.includes('Administrator')) {
    res.status(403).json({ error: 'nur fuer Administratoren' }); return false;
  }
  return true;
}

// Legt einen Keycloak-User an, weist die angegebenen Realm-Rollen zu und liefert die UUID.
async function createKeycloakUser(adminToken, { username, password, firstName, lastName, email }, roles) {
  // 1. User anlegen
  const createRes = await adminSend(adminToken, 'POST', `${ADMIN_BASE}/users`, {
    username, enabled: true, firstName, lastName,
    email: email || `${username}@example.org`, emailVerified: true,
    credentials: [{ type: 'password', value: password, temporary: false }],
  });
  if (createRes.status === 409) {
    throw Object.assign(new Error(`Benutzername "${username}" existiert bereits`), { httpStatus: 409 });
  }
  if (!createRes.ok) {
    throw new Error(`Keycloak-User konnte nicht angelegt werden (${createRes.status})`);
  }
  // 2. UUID des neuen Users holen
  const found = await adminJson(adminToken, `${ADMIN_BASE}/users?username=${encodeURIComponent(username)}&exact=true`);
  const userId = found?.[0]?.id;
  if (!userId) throw new Error('Neuer User nicht auffindbar');
  // 3. Realm-Rollen zuweisen
  const roleReps = [];
  for (const roleName of roles) {
    const role = await adminJson(adminToken, `${ADMIN_BASE}/roles/${encodeURIComponent(roleName)}`);
    if (role?.id) roleReps.push({ id: role.id, name: roleName });
  }
  if (roleReps.length) {
    await adminSend(adminToken, 'POST', `${ADMIN_BASE}/users/${userId}/role-mappings/realm`, roleReps);
  }
  return userId;
}

// Legt fuer einen (frisch angelegten) User einen verknuepften FHIR-Patient-Datensatz an
// und richtet den Owner-Vollzugriff ein. Wirft bei FHIR-Fehler (Aufrufer raeumt den
// KC-User auf). Liefert die neue FHIR-Patient-ID. Nutzt das Admin-Access-Token der Session.
async function createLinkedPatientRecord(adminToken, session, userId, { firstName, lastName, gender, birthDate }) {
  const fresh = await ensureFreshToken(session);
  if (!fresh) throw Object.assign(new Error('Sitzung abgelaufen. Bitte neu anmelden.'), { httpStatus: 440 });

  const patientBody = {
    resourceType: 'Patient',
    identifier: [{ system: 'keycloak-uuid', value: userId }],
    name: [{ family: lastName, given: firstName ? [firstName] : [] }],
    ...(gender ? { gender } : {}),
    ...(birthDate ? { birthDate } : {}),
  };
  const fhirRes = await fetch(`${FHIR_BASE}/Patient`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${session.accessToken}`,
      'Content-Type': 'application/fhir+json',
      Accept: 'application/fhir+json',
    },
    body: JSON.stringify(patientBody),
  });
  const text = await fhirRes.text();
  let payload; try { payload = JSON.parse(text); } catch { payload = text; }
  if (!fhirRes.ok) {
    const diag = payload?.issue?.[0]?.diagnostics || `FHIR-Fehler (${fhirRes.status})`;
    throw Object.assign(new Error(diag), { httpStatus: fhirRes.status === 403 ? 403 : 502 });
  }
  return payload?.id || null;
}

// Gemeinsamer Ablauf fuer "User mit eigenem FHIR-Datensatz anlegen": KC-User mit den
// gewuenschten Rollen -> verknuepfter FHIR-Patient -> Owner-Vollzugriff. Bei jedem
// Fehler nach der User-Anlage wird der KC-User wieder entfernt (kein verwaister Login).
// Liefert das Response-JSON (inkl. optionalem warning) oder wirft mit httpStatus.
async function provisionUserWithRecord(req, roles, { username, password, firstName, lastName, gender, birthDate, email }) {
  const adminToken = await getAdminToken();
  if (!adminToken) throw Object.assign(new Error('Kein Admin-Token'), { httpStatus: 502 });

  let userId = null;
  try {
    // 1. Keycloak-User mit Rollen anlegen
    userId = await createKeycloakUser(adminToken, { username, password, firstName, lastName, email }, roles);

    // 2. FHIR-Patient mit keycloak-uuid anlegen (POST mit Admin-Access-Token; RBAC erlaubt).
    //    HAPI registriert die Patient/<id>-Ressource danach in Keycloak (Owner = userId).
    const newId = await createLinkedPatientRecord(adminToken, req.session, userId, { firstName, lastName, gender, birthDate });

    // 3. Owner-Vollzugriff einrichten, damit der neue User seine eigenen Daten lesen kann.
    const result = { ok: true, patientId: newId, userId, username };
    if (newId) {
      try {
        await grantOwnerFullAccess(adminToken, newId, userId, username);
      } catch (grantErr) {
        console.warn('Owner-Freigabe fehlgeschlagen fuer Patient/' + newId + ':', grantErr.message);
        result.warning = 'Angelegt, aber Owner-Freigabe fehlgeschlagen: ' + grantErr.message;
      }
    }
    return result;
  } catch (e) {
    // Bei Fehler nach User-Anlage aufraeumen (best effort).
    if (userId) {
      await adminSend(adminToken, 'DELETE', `${ADMIN_BASE}/users/${userId}`).catch(() => {});
    }
    throw e;
  }
}

// POST /api/admin/patients  { username, password, firstName, lastName, gender, birthDate, email? }
// Legt KC-User (Rolle Patient) + verknuepfte FHIR-Patient-Ressource an.
app.post('/api/admin/patients', async (req, res) => {
  if (!requireAdmin(req, res)) return;
  const { username, password, firstName, lastName, gender, birthDate, email } = req.body || {};
  if (!username || !password || !lastName) {
    return res.status(400).json({ error: 'username, password und lastName sind erforderlich' });
  }
  try {
    const result = await provisionUserWithRecord(req, ['Patient'], { username, password, firstName, lastName, gender, birthDate, email });
    res.status(201).json(result);
  } catch (e) {
    res.status(e.httpStatus || 502).json({ error: e.message });
  }
});

// POST /api/admin/doctors  { username, password, firstName, lastName, gender, birthDate, email? }
// Legt KC-User (Rollen Doctor + Patient) + eigenen FHIR-Patient-Datensatz an — wie dr.smith/dr.bob.
app.post('/api/admin/doctors', async (req, res) => {
  if (!requireAdmin(req, res)) return;
  const { username, password, firstName, lastName, gender, birthDate, email } = req.body || {};
  if (!username || !password || !lastName) {
    return res.status(400).json({ error: 'username, password und lastName sind erforderlich' });
  }
  try {
    // Doctor + Patient: eigener Datensatz, damit die "Als Patient"-Sicht funktioniert.
    const result = await provisionUserWithRecord(req, ['Doctor', 'Patient'], { username, password, firstName, lastName, gender, birthDate, email });
    res.status(201).json(result);
  } catch (e) {
    res.status(e.httpStatus || 502).json({ error: e.message });
  }
});

// GET /api/admin/patients — Liste aller Patienten (aus der Keycloak-Ressourcenliste),
// damit der Admin im Frontend einen Zielpatienten fuer klinische Daten waehlen kann.
app.get('/api/admin/patients', async (req, res) => {
  if (!requireAdmin(req, res)) return;
  try {
    const adminToken = await getAdminToken();
    if (!adminToken) return res.status(502).json({ error: 'Kein Admin-Token' });
    const all = await listKeycloakPatients(adminToken);
    const patients = all
      .sort((a, b) => Number(a.id) - Number(b.id))
      .map((p) => ({ id: p.id, label: `${p.ownerName || 'Patient'} (Patient/${p.id})` }));
    res.json({ patients });
  } catch (e) {
    res.status(502).json({ error: e.message });
  }
});

// Baut den FHIR-Body fuer eine klinische Ressource (subject = Patient/<id>).
function buildClinicalResource(resourceType, patientId, { text, category }) {
  const subjectRef = { reference: `Patient/${patientId}` };
  if (resourceType === 'Condition') {
    return {
      resourceType: 'Condition',
      subject: subjectRef,
      code: { text },
      category: [{ coding: [{ system: 'http://terminology.hl7.org/CodeSystem/condition-category', code: category || 'problem-list-item' }] }],
      clinicalStatus: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/condition-clinical', code: 'active' }] },
    };
  }
  if (resourceType === 'MedicationStatement') {
    return {
      resourceType: 'MedicationStatement',
      status: 'recorded',
      subject: subjectRef,
      medication: { concept: { text } },
    };
  }
  if (resourceType === 'AllergyIntolerance') {
    return {
      resourceType: 'AllergyIntolerance',
      patient: subjectRef,
      code: { text },
      clinicalStatus: { coding: [{ system: 'http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical', code: 'active' }] },
    };
  }
  return null;
}

// POST /api/admin/clinical  { patientId, resourceType, text, category? }
// Legt eine klinische Ressource (Condition/MedicationStatement/AllergyIntolerance) fuer
// einen Patienten an. POST mit Admin-Access-Token (RBAC erlaubt). Die Ressource wird ueber
// die Permissions des Ziel-Patienten autorisiert (nicht separat in Keycloak registriert).
app.post('/api/admin/clinical', async (req, res) => {
  if (!requireAdmin(req, res)) return;
  const { patientId, resourceType, text, category } = req.body || {};
  if (!patientId || !BLACKLISTABLE.includes(resourceType) || !text) {
    return res.status(400).json({ error: 'patientId, gueltiger resourceType (Condition/MedicationStatement/AllergyIntolerance) und text erforderlich' });
  }
  try {
    const fresh = await ensureFreshToken(req.session);
    if (!fresh) return res.status(440).json({ error: 'Sitzung abgelaufen. Bitte neu anmelden.' });

    const body = buildClinicalResource(resourceType, patientId, { text, category });
    const fhirRes = await fetch(`${FHIR_BASE}/${resourceType}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${req.session.accessToken}`,
        'Content-Type': 'application/fhir+json',
        Accept: 'application/fhir+json',
      },
      body: JSON.stringify(body),
    });
    const respText = await fhirRes.text();
    let payload; try { payload = JSON.parse(respText); } catch { payload = respText; }
    if (!fhirRes.ok) {
      const diag = payload?.issue?.[0]?.diagnostics || `FHIR-Fehler (${fhirRes.status})`;
      return res.status(fhirRes.status === 403 ? 403 : 502).json({ error: diag });
    }
    res.status(201).json({ ok: true, resourceType, id: payload?.id || null, patientId });
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
