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
async function listKeycloakPatients(adminToken) {
  if (!clientUuidCache) {
    const cr = await fetch(`${ADMIN_BASE}/clients?clientId=${CLIENT_ID}`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    clientUuidCache = (await cr.json())[0].id;
  }
  const rr = await fetch(
    `${ADMIN_BASE}/clients/${clientUuidCache}/authz/resource-server/resource?first=0&max=200&deep=true`,
    { headers: { Authorization: `Bearer ${adminToken}` } }
  );
  const resources = await rr.json();
  return resources
    .filter((r) => /^Patient\/\d+$/.test(r.name))
    .map((r) => ({
      id: r.name.replace('Patient/', ''),
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
    req.session.username = claims.preferred_username || username;
    req.session.roles = (claims.realm_access?.roles || []).filter(
      (role) => ['Doctor', 'Patient', 'Administrator'].includes(role)
    );
    req.session.rptCache = {};

    await resolvePatientContext(req.session, claims.sub);
    res.json({
      username: req.session.username,
      roles: req.session.roles,
      patientId: req.session.patientId,
      patients: req.session.patients,
    });
  } catch (e) {
    res.status(502).json({ error: 'Keycloak nicht erreichbar: ' + e.message });
  }
});

// Bestimmt den Patientenkontext nach dem Login (Quelle: Keycloak-Authorization-Config):
//  - Patient-User: der Patient, dessen Owner die eigene Keycloak-UUID (sub) ist.
//    patientId gesetzt, patients enthaelt nur den eigenen Patienten.
//  - Aerzte/Admin: kein eigener Patient (patientId = null); patients = alle Patienten
//    zur Auswahl. Welche davon zugaenglich sind, entscheidet erst die UMA-Durchsetzung.
async function resolvePatientContext(session, sub) {
  session.patientId = null;
  session.patients = [];
  const isPatient = session.roles.includes('Patient') && !session.roles.includes('Doctor');
  try {
    const adminToken = await getAdminToken();
    if (!adminToken) {
      console.warn('Patientenkontext: kein Admin-Token');
      return;
    }
    const all = await listKeycloakPatients(adminToken);
    const toEntry = (p) => ({ id: p.id, label: `${p.ownerName || 'Patient'} (Patient/${p.id})` });

    if (isPatient) {
      const own = all.find((p) => p.ownerId === sub);
      if (own) {
        session.patientId = own.id;
        session.patients = [toEntry(own)];
      }
    } else {
      // numerisch sortiert fuer stabile Reihenfolge
      session.patients = all
        .sort((a, b) => Number(a.id) - Number(b.id))
        .map(toEntry);
    }
  } catch (e) {
    console.warn('Patientenkontext konnte nicht aufgeloest werden:', e.message);
  }
}

app.post('/api/logout', (req, res) => {
  req.session.destroy(() => res.json({ ok: true }));
});

app.get('/api/me', (req, res) => {
  if (!req.session.accessToken) return res.status(401).json({ error: 'nicht angemeldet' });
  res.json({
    username: req.session.username,
    roles: req.session.roles,
    patientId: req.session.patientId,
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

app.use(express.static(path.join(__dirname, 'public')));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`UMA FHIR Frontend laeuft auf http://localhost:${PORT}`);
  console.log(`  Keycloak: ${KEYCLOAK}`);
  console.log(`  FHIR:     ${FHIR_BASE}`);
});
