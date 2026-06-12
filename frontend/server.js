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
    res.json({ username: req.session.username, roles: req.session.roles });
  } catch (e) {
    res.status(502).json({ error: 'Keycloak nicht erreichbar: ' + e.message });
  }
});

app.post('/api/logout', (req, res) => {
  req.session.destroy(() => res.json({ ok: true }));
});

app.get('/api/me', (req, res) => {
  if (!req.session.accessToken) return res.status(401).json({ error: 'nicht angemeldet' });
  res.json({ username: req.session.username, roles: req.session.roles });
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

// Fuehrt eine FHIR-Anfrage inkl. vollem UMA-Flow aus.
async function fhirRequest(session, method, fhirPath, rpt) {
  const headers = { Accept: 'application/fhir+json' };
  if (rpt) headers.Authorization = `Bearer ${rpt}`;
  else if (session.accessToken) headers.Authorization = `Bearer ${session.accessToken}`;
  return fetch(`${FHIR_BASE}/${fhirPath}`, { method, headers });
}

// --- Generischer FHIR-Proxy mit UMA-Dance ---
// GET /api/fhir/<fhirPath>  (z.B. Patient/1, Condition?patient=1, Patient/1/$summary)
app.get('/api/fhir/*', async (req, res) => {
  if (!req.session.accessToken) return res.status(401).json({ error: 'nicht angemeldet' });

  const fhirPath = req.params[0] + (req._parsedUrl.search || '');
  const steps = [];
  try {
    // Schritt 1: Versuch mit dem Access Token (loest 401 + Permission Ticket aus)
    let response = await fhirRequest(req.session, 'GET', fhirPath, null);
    steps.push({ step: 'Access Token', status: response.status });

    if (response.status === 401) {
      const wwwAuth = response.headers.get('www-authenticate') || '';
      const ticketMatch = wwwAuth.match(/ticket="([^"]+)"/);
      if (ticketMatch) {
        steps.push({ step: 'Permission Ticket erhalten', status: 401 });
        const rpt = await exchangeTicket(req.session, ticketMatch[1]);
        if (!rpt) {
          steps.push({ step: 'RPT-Austausch', status: 'access_denied' });
          return res.status(403).json({ error: 'Keycloak verweigert RPT (access_denied)', steps });
        }
        const rptClaims = decodeJwt(rpt);
        const rptScopes = (rptClaims.authorization?.permissions || [])
          .flatMap((p) => (p.scopes || []).map((s) => `${p.rsname}: ${s}`));
        steps.push({ step: 'RPT erhalten', status: 200, scopes: rptScopes });

        // Schritt 4: erneuter Zugriff mit RPT
        response = await fhirRequest(req.session, 'GET', fhirPath, rpt);
        steps.push({ step: 'Zugriff mit RPT', status: response.status });
      }
    }

    const text = await response.text();
    let payload;
    try { payload = JSON.parse(text); } catch { payload = text; }
    res.status(response.status).json({ status: response.status, steps, resource: payload });
  } catch (e) {
    res.status(502).json({ error: 'FHIR-Server nicht erreichbar: ' + e.message, steps });
  }
});

app.use(express.static(path.join(__dirname, 'public')));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`UMA FHIR Frontend laeuft auf http://localhost:${PORT}`);
  console.log(`  Keycloak: ${KEYCLOAK}`);
  console.log(`  FHIR:     ${FHIR_BASE}`);
});
