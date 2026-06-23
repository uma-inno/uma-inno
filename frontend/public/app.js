'use strict';

const $ = (sel) => document.querySelector(sel);

// Aktueller Patientenkontext (vom Login/Selektor gesetzt)
let currentPatientId = null;
let patientList = [];

// ---------- Auth ----------
async function login(username, password) {
  const res = await fetch('/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Login fehlgeschlagen');
  }
  return res.json();
}

function showApp(me) {
  $('#login-view').classList.add('hidden');
  $('#app-view').classList.remove('hidden');
  $('#who').textContent = me.username;
  $('#roles').innerHTML = me.roles
    .map((r) => `<span class="badge badge-${r}">${r}</span>`)
    .join('');
  setupPatientContext(me);
}

// Richtet den Patientenkontext ein. Rollenagnostisch:
//  - Doppelrolle (Arzt + eigener Datensatz): Umschalter sichtbar, Default = Patient-Sicht
//  - reiner Patient: keine Auswahl, fix eigener Datensatz
//  - reiner Arzt (kein eigener Datensatz): keine Patient-Sicht, fix Arzt-Auswahl
let ownPatientId = null;
let isDoctor = false;

function setupPatientContext(me) {
  patientList = me.patients || [];
  ownPatientId = me.ownPatientId || null;
  isDoctor = !!me.isDoctor;
  const canBeBoth = isDoctor && ownPatientId;

  $('#view-switch').classList.toggle('hidden', !canBeBoth);

  if (ownPatientId) {
    setViewMode('patient');        // hat eigene Daten -> startet in Patient-Sicht
  } else {
    setViewMode('doctor');         // reiner Arzt -> Auswahl
  }
}

// Wechselt zwischen Patient-Sicht (eigener Datensatz) und Arzt-Sicht (Auswahlliste).
function setViewMode(mode) {
  const wrap = $('#patient-select-wrap');
  const select = $('#patient-select');
  $('#view-patient')?.classList.toggle('active', mode === 'patient');
  $('#view-doctor')?.classList.toggle('active', mode === 'doctor');

  if (mode === 'patient' && ownPatientId) {
    wrap.classList.add('hidden');
    currentPatientId = ownPatientId;
  } else {
    // Arzt-Sicht: Auswahlliste anzeigen (sofern mehr als nur der eigene Patient)
    wrap.classList.toggle('hidden', patientList.length <= 1);
    select.innerHTML = patientList
      .map((p) => `<option value="${p.id}">${p.label}</option>`)
      .join('');
    currentPatientId = patientList[0] ? patientList[0].id : null;
    if (currentPatientId) select.value = currentPatientId;
  }
  updatePatientHeading(mode);
}

function updatePatientHeading(mode) {
  if (mode === 'patient' && ownPatientId) {
    const own = patientList.find((p) => p.id === ownPatientId);
    $('#patient-heading').textContent = own ? `Meine Daten — ${own.label}` : `Meine Daten (Patient/${ownPatientId})`;
    return;
  }
  const entry = patientList.find((p) => p.id === currentPatientId);
  $('#patient-heading').textContent = entry ? entry.label : (currentPatientId ? `Patient/${currentPatientId}` : 'Kein Patient');
}

function showLogin() {
  $('#app-view').classList.add('hidden');
  $('#login-view').classList.remove('hidden');
  $('#password').value = '';
}

// ---------- FHIR-Anfrage via Proxy ----------
async function fhirGet(fhirPath) {
  const res = await fetch('/api/fhir/' + fhirPath);
  return res.json();
}

// ---------- Flow-Anzeige ----------
function renderFlow(steps) {
  const flow = $('#flow');
  const list = $('#flow-steps');
  if (!steps || steps.length === 0) {
    flow.classList.add('hidden');
    return;
  }
  flow.classList.remove('hidden');
  list.innerHTML = steps
    .map((s) => {
      let cls = 'warn';
      if (s.status === 200) cls = 'ok';
      else if (s.status === 401 || s.status === 403 || s.status === 'access_denied') cls = 'deny';
      let html = `<li><span class="dot ${cls}"></span>${s.step} <strong>${s.status}</strong></li>`;
      if (s.scopes && s.scopes.length) {
        html += `<div class="flow-scopes">RPT-Scopes: ${s.scopes
          .map((sc) => `<code>${sc}</code>`)
          .join('')}</div>`;
      }
      return html;
    })
    .join('');
}

// ---------- Ergebnis-Rendering ----------
function statusPill(status) {
  const cls = status === 200 ? 'status-200' : (status === 401 || status === 403) ? `status-${status}` : 'status-other';
  const text = { 200: 'Zugriff erlaubt', 401: 'Authentifizierung erforderlich / verweigert', 403: 'Zugriff verweigert' }[status] || 'Antwort';
  return `<div class="status-line"><span class="status-pill ${cls}">${status}</span><span class="status-text">${text}</span></div>`;
}

function renderResource(label, data) {
  const panel = $('#result-panel');
  const status = data.status;
  let body = '';

  if (status !== 200) {
    const msg = data.error
      || data.resource?.issue?.[0]?.diagnostics
      || 'Die Patientenfreigabe deckt diese Ressource für deine Rolle nicht ab.';
    body = `<div class="denied-box"><strong>Kein Zugriff.</strong><br/>${msg}</div>`;
  } else if (data.resource?.resourceType === 'Bundle' && data.resource?.type === 'document') {
    body = renderSummary(data.resource);
  } else if (data.resource?.resourceType === 'Bundle') {
    body = renderBundle(data.resource);
  } else {
    body = renderSingle(data.resource);
  }

  panel.innerHTML =
    `<h3>${label}</h3>` +
    statusPill(status) +
    body +
    `<details><summary>Rohes FHIR-JSON anzeigen</summary><pre>${escapeHtml(
      JSON.stringify(data.resource, null, 2)
    )}</pre></details>`;
}

function renderSingle(r) {
  if (!r || !r.resourceType) return '<div class="placeholder">Keine Daten.</div>';
  if (r.resourceType === 'Patient') {
    const name = r.name?.[0];
    const full = name ? `${(name.given || []).join(' ')} ${name.family || ''}`.trim() : '(ohne Namen)';
    return `<div class="cards"><div class="card">
      <div class="card-title">${full}</div>
      <div class="card-meta">
        <span class="tag">Geschlecht: ${r.gender || '—'}</span>
        <span class="tag">Geboren: ${r.birthDate || '—'}</span>
        <span class="tag">ID: ${r.id}</span>
      </div></div></div>`;
  }
  return `<div class="cards">${renderCard(r)}</div>`;
}

function renderBundle(bundle) {
  const entries = bundle.entry || [];
  if (entries.length === 0) {
    return '<div class="placeholder">Keine Einträge — entweder keine Daten vorhanden oder durch die Patientenfreigabe gefiltert.</div>';
  }
  return `<div class="cards">${entries.map((e) => renderCard(e.resource)).join('')}</div>`;
}

function renderCard(r) {
  const type = r.resourceType;
  let title = r.code?.text || r.code?.coding?.[0]?.display || type;
  if (type === 'MedicationStatement') {
    title = r.medication?.concept?.text || r.medicationCodeableConcept?.text || 'Medikament';
  }
  const status = r.clinicalStatus?.coding?.[0]?.code || r.status || '';
  const category = r.category?.[0]?.coding?.[0]?.code || '';
  return `<div class="card">
    <div class="card-title">${escapeHtml(title)}</div>
    <div class="card-meta">
      <span class="tag">${type}/${r.id}</span>
      ${status ? `<span class="tag">Status: ${status}</span>` : ''}
      ${category ? `<span class="tag">Kategorie: ${category}</span>` : ''}
    </div>
  </div>`;
}

function renderSummary(bundle) {
  const comp = bundle.entry?.[0]?.resource;
  if (!comp || comp.resourceType !== 'Composition') {
    return '<div class="placeholder">Kein gültiges IPS-Dokument.</div>';
  }
  const byId = {};
  for (const e of bundle.entry || []) {
    const r = e.resource;
    if (r?.id) byId[`${r.resourceType}/${r.id}`] = r;
  }

  const sections = comp.section || [];
  const presentTypes = new Set();
  let html = '';
  for (const sec of sections) {
    const loinc = sec.code?.coding?.[0]?.code || '';
    const entries = sec.entry || [];
    presentTypes.add(sec.title);
    html += `<div class="ips-section"><h4>${escapeHtml(sec.title)} <span class="loinc">LOINC ${loinc}</span></h4>`;
    if (entries.length === 0) {
      html += '<div class="ips-empty">Keine Einträge.</div>';
    } else {
      html += '<div class="cards">';
      for (const ref of entries) {
        const target = byId[ref.reference];
        html += target ? renderCard(target) : `<div class="card"><div class="card-title">${ref.reference}</div></div>`;
      }
      html += '</div>';
    }
    html += '</div>';
  }

  const allSections = ['Problems', 'Allergies and Intolerances', 'Medication Summary'];
  const omitted = allSections.filter((s) => !presentTypes.has(s));
  if (omitted.length) {
    html += `<div class="omitted-note">Weggelassene Sections (kein Scope in der Freigabe): <strong>${omitted.join(', ')}</strong></div>`;
  }
  return html;
}

function escapeHtml(str) {
  return String(str).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}

// ---------- Events ----------
$('#login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  $('#login-error').textContent = '';
  try {
    const me = await login($('#username').value, $('#password').value);
    showApp(me);
  } catch (err) {
    $('#login-error').textContent = err.message;
  }
});

document.querySelectorAll('.quick .chip').forEach((chip) => {
  chip.addEventListener('click', () => {
    $('#username').value = chip.dataset.user;
    $('#password').value = chip.dataset.pass;
  });
});

$('#logout').addEventListener('click', async () => {
  await fetch('/api/logout', { method: 'POST' });
  showLogin();
});

$('#patient-select').addEventListener('change', (e) => {
  currentPatientId = e.target.value;
  updatePatientHeading('doctor');
});

$('#view-patient').addEventListener('click', () => setViewMode('patient'));
$('#view-doctor').addEventListener('click', () => setViewMode('doctor'));

document.querySelectorAll('.action').forEach((btn) => {
  btn.addEventListener('click', async () => {
    if (!currentPatientId) {
      $('#result-panel').innerHTML = '<div class="denied-box">Kein Patient ausgewählt.</div>';
      return;
    }
    const path = btn.dataset.tmpl.replace('{id}', currentPatientId);
    const label = btn.dataset.label;
    $('#result-panel').innerHTML = '<div class="placeholder">Lade…</div>';
    renderFlow([]);
    try {
      const data = await fhirGet(path);
      renderFlow(data.steps);
      renderResource(label, data);
    } catch (err) {
      $('#result-panel').innerHTML = `<div class="denied-box">Fehler: ${err.message}</div>`;
    }
  });
});

// Session pruefen (z.B. nach Reload)
(async () => {
  try {
    const res = await fetch('/api/me');
    if (res.ok) showApp(await res.json());
  } catch { /* nicht angemeldet */ }
})();
