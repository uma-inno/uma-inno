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
  const avatar = $('#avatar');
  if (avatar) avatar.textContent = (me.username || '?').trim().slice(0, 2).toUpperCase();
  $('#roles').innerHTML = me.roles
    .map((r) => `<span class="badge badge-${r}">${r}</span>`)
    .join('');
  setupAdminPanel(me);
  setupPatientContext(me);
}

// Blendet die Admin-Panels (Patient/Arzt anlegen, klinische Daten) nur fuer
// Administratoren ein und laedt die Patientenauswahl fuer die klinischen Daten.
function setupAdminPanel(me) {
  for (const id of ['#admin-panel', '#admin-doctor-panel', '#admin-clinical-panel']) {
    $(id)?.classList.toggle('hidden', !me.isAdmin);
  }
  if (me.isAdmin) loadAdminPatientList();
}

// Laedt alle Patienten in das Zielpatient-Dropdown der klinischen Daten.
async function loadAdminPatientList() {
  const select = $('#nc-patient');
  if (!select) return;
  try {
    const res = await fetch('/api/admin/patients');
    if (!res.ok) return;
    const { patients } = await res.json();
    select.innerHTML = (patients || [])
      .map((p) => `<option value="${p.id}">${escapeHtml(p.label)}</option>`)
      .join('');
  } catch { /* ignore */ }
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
  updateAccessPanel(mode);
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

// ---------- Zugriffsverwaltung (nur Patient-Sicht auf eigenen Datensatz) ----------
function updateAccessPanel(mode) {
  const panel = $('#access-panel');
  if (!panel) return;
  if (mode === 'patient' && ownPatientId) {
    panel.classList.remove('hidden');
    loadAccessState();
  } else {
    panel.classList.add('hidden');
  }
}

async function loadAccessState() {
  const host = $('#access-doctors');
  host.innerHTML = accessSkeleton();
  try {
    const res = await fetch('/api/access/state');
    if (!res.ok) { host.innerHTML = '<div class="denied-box">Freigaben konnten nicht geladen werden.</div>'; return; }
    renderAccess(await res.json());
  } catch {
    host.innerHTML = '<div class="denied-box">Fehler beim Laden der Freigaben.</div>';
  }
}

// Platzhalter-Skelett, das die Struktur der Freigabe-Karten andeutet, waehrend
// /api/access/state laedt (Login-Aufloesung + UMA-Dance je Ressourcentyp dauern kurz).
function accessSkeleton(cards = 2) {
  const toggles = Array.from({ length: 4 }, () => '<span class="sk sk-toggle"></span>').join('');
  const card = `<div class="card access-doc sk-card" aria-hidden="true">
      <div class="sk sk-title"></div>
      <div class="scope-row">${toggles}</div>
      <div class="sk sk-line"></div>
    </div>`;
  return Array.from({ length: cards }, () => card).join('');
}

// Platzhalter-Skelett fuers Ergebnis-Panel (Patientendaten), waehrend der UMA-Dance
// laeuft (Access Token -> 401+Ticket -> RPT -> Zugriff). Deutet Statuszeile + Ergebniskarten an.
function resultSkeleton(label, cards = 3) {
  const card = `<div class="card sk-card" aria-hidden="true">
      <div class="sk sk-title"></div>
      <div class="sk sk-line"></div>
    </div>`;
  return `<h3>${escapeHtml(label)}</h3>
    <div class="sk-status" aria-hidden="true"><span class="sk sk-pill"></span><span class="sk sk-line" style="width:35%"></span></div>
    <div class="cards">${Array.from({ length: cards }, () => card).join('')}</div>`;
}

function renderAccess(state) {
  const host = $('#access-doctors');
  if (!state.doctors || state.doctors.length === 0) {
    host.innerHTML = '<div class="placeholder">Keine Ärzte im System.</div>';
    return;
  }
  // Typ-Label-Lookup aus state.types (key -> label)
  const typeLabel = {};
  for (const t of state.types) typeLabel[t.key] = t.label;

  host.innerHTML = state.doctors.map((d) => {
    const toggles = state.types.map((t) =>
      `<label class="scope-toggle"><input type="checkbox" data-doc="${d.id}" data-type="${t.key}" ${d.scopes.includes(t.key) ? 'checked' : ''}/> ${t.label}</label>`
    ).join('');
    // Sperrliste nur fuer Typen, die dem Arzt freigegeben wurden; ist nichts freigegeben,
    // entfaellt der ganze "Einzelne Einträge sperren"-Block.
    const blacklistTree = renderBlacklistTree(state.instances, d, typeLabel);
    return `<div class="card access-doc">
      <div class="card-title">${escapeHtml(d.name)} <span class="tag">${escapeHtml(d.username)}</span></div>
      <div class="scope-row">${toggles}</div>
      ${blacklistTree ? `<details><summary>Einzelne Einträge für ${escapeHtml(d.username)} sperren</summary>${blacklistTree}</details>` : ''}
    </div>`;
  }).join('');
}

// Baut den Blacklist-Baum Typ -> Category -> Instanzen fuer einen Arzt.
// Freigegebene Typen zeigen die Kategorien mit Instanz-Checkboxen. Nicht freigegebene
// Typen erscheinen ebenfalls, aber mit einem Hinweis: ohne Freigabe sind ohnehin ALLE
// Eintraege gesperrt — man muss erst freigeben, um einzelne Instanzen sperren zu koennen.
function renderBlacklistTree(instances, doctor, typeLabel) {
  if (instances.length === 0) return '';
  const granted = new Set(doctor.scopes || []);
  // nach Typ, dann nach Category gruppieren (alle Typen, auch nicht freigegebene)
  const byType = {};
  for (const i of instances) {
    (byType[i.type] ||= {});
    const cat = i.category || 'uncategorized';
    (byType[i.type][cat] ||= { label: i.categoryLabel || cat, items: [] }).items.push(i);
  }
  return Object.keys(byType).map((type) => {
    const cats = byType[type];
    const label = escapeHtml(typeLabel[type] || type);
    const total = Object.values(cats).reduce((n, g) => n + g.items.length, 0);

    // Typ nicht freigegeben -> Arzt sieht ohnehin nichts; kein gezieltes Einzel-Sperren.
    if (!granted.has(type)) {
      return `<details class="bl-type bl-type-locked"><summary class="bl-type-head">${label} <span class="tag">${total}</span> <span class="bl-locked-badge">nicht freigegeben</span></summary>
        <div class="bl-locked-note">„${label}" ist für diesen Arzt nicht freigegeben – <strong>alle ${total} Einträge sind gesperrt</strong>. Gib zuerst die Freigabe oben, um einzelne Einträge gezielt sperren zu können.</div>
      </details>`;
    }

    // freigegeben -> Kategorien mit Instanz-Checkboxen
    let blocked = 0;
    const catBlocks = Object.keys(cats).map((cat) => {
      const g = cats[cat];
      const rows = g.items.map((i) => {
        const key = `${i.type}/${i.id}`;
        const isBlocked = doctor.blacklist.includes(key);
        if (isBlocked) blocked++;
        return `<label class="bl-row"><input type="checkbox" data-doc="${doctor.id}" data-rt="${i.type}" data-rid="${i.id}" ${isBlocked ? 'checked' : ''}/> <span>${escapeHtml(i.label)}</span> <span class="tag">${key}</span></label>`;
      }).join('');
      return `<div class="bl-cat"><div class="bl-cat-head">${escapeHtml(g.label)}</div><div class="bl-list">${rows}</div></div>`;
    }).join('');
    const badge = blocked ? ` <span class="bl-count">${blocked} gesperrt</span>` : '';
    return `<details class="bl-type"><summary class="bl-type-head">${label} <span class="tag">${total}</span>${badge}</summary>${catBlocks}</details>`;
  }).join('');
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

  if (status === 440) {
    body = `<div class="denied-box"><strong>Sitzung abgelaufen.</strong><br/>${data.error || 'Bitte neu anmelden.'}</div>`;
  } else if (status !== 200) {
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
    body;
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
  let html = '';
  for (const sec of sections) {
    const loinc = sec.code?.coding?.[0]?.code || '';
    const entries = sec.entry || [];
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

  return html;
}

function escapeHtml(str) {
  return String(str).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}

// ---------- Events ----------
$('#login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  $('#login-error').textContent = '';
  const btn = e.target.querySelector('button[type="submit"]');
  const label = btn.textContent;
  btn.disabled = true;
  btn.textContent = 'Anmelden…';
  try {
    const me = await login($('#username').value, $('#password').value);
    showApp(me);
  } catch (err) {
    $('#login-error').textContent = err.message;
  } finally {
    btn.disabled = false;
    btn.textContent = label;
  }
});

$('#logout').addEventListener('click', async () => {
  await fetch('/api/logout', { method: 'POST' });
  showLogin();
});

// ---------- Theme (Hell/Dunkel) ----------
// Der Ausgangswert wird bereits im <head> gesetzt (kein Flackern); hier nur das Umschalten.
$('#theme-toggle')?.addEventListener('click', () => {
  const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  const next = isDark ? 'light' : 'dark';
  document.documentElement.setAttribute('data-theme', next);
  try { localStorage.setItem('theme', next); } catch { /* localStorage nicht verfuegbar */ }
});

$('#patient-select').addEventListener('change', (e) => {
  currentPatientId = e.target.value;
  updatePatientHeading('doctor');
});

$('#view-patient').addEventListener('click', () => setViewMode('patient'));
$('#view-doctor').addEventListener('click', () => setViewMode('doctor'));

// Freigaben/Sperren im Verwaltungs-Panel (Event-Delegation)
$('#access-doctors').addEventListener('change', async (e) => {
  const el = e.target;
  if (!(el instanceof HTMLInputElement)) return;
  el.disabled = true;
  try {
    if (el.dataset.type) {
      const doc = el.dataset.doc;
      const types = [...document.querySelectorAll(`#access-doctors input[data-type][data-doc="${doc}"]`)]
        .filter((c) => c.checked).map((c) => c.dataset.type);
      const res = await fetch('/api/access/grant', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ doctorId: doc, scopes: types }),
      });
      if (!res.ok) throw new Error('grant fehlgeschlagen');
      // Die Sperrliste haengt an den Freigaben: Panel neu laden, damit die Kategorie
      // sofort erscheint/verschwindet und serverseitig aufgeraeumte Sperren wegfallen.
      await loadAccessState();
      return;
    } else if (el.dataset.rt) {
      const res = await fetch('/api/access/blacklist', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ doctorId: el.dataset.doc, resourceType: el.dataset.rt, resourceId: el.dataset.rid, blocked: el.checked }),
      });
      if (!res.ok) throw new Error('blacklist fehlgeschlagen');
    }
  } catch {
    el.checked = !el.checked; // bei Fehler zuruecksetzen
  } finally {
    el.disabled = false;
  }
});

// Generischer Submit fuer die Admin-Formulare: POST an <url>, Button-/Status-Handling,
// Erfolgsmeldung via successMsg(data). Bei { warning } wird eine Warnung angezeigt.
async function submitAdminForm(form, msgEl, url, body, successMsg) {
  const btn = form.querySelector('button[type="submit"]');
  const label = btn.textContent;
  msgEl.textContent = '';
  msgEl.className = 'admin-msg';
  btn.disabled = true;
  btn.textContent = 'Anlegen…';
  try {
    const res = await fetch(url, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || 'Anlegen fehlgeschlagen');
    if (data.warning) {
      msgEl.textContent = `⚠ ${data.warning}`;
      msgEl.classList.add('err');
    } else {
      msgEl.textContent = successMsg(data);
      msgEl.classList.add('ok');
      form.reset();
    }
    return data;
  } catch (err) {
    msgEl.textContent = err.message;
    msgEl.classList.add('err');
  } finally {
    btn.disabled = false;
    btn.textContent = label;
  }
}

// Admin: neuen Patienten (KC-User + FHIR-Datensatz) anlegen
$('#admin-add-patient')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const body = {
    username: $('#np-username').value.trim(),
    password: $('#np-password').value,
    firstName: $('#np-firstname').value.trim(),
    lastName: $('#np-lastname').value.trim(),
    gender: $('#np-gender').value || undefined,
    birthDate: $('#np-birthdate').value || undefined,
  };
  await submitAdminForm(e.target, $('#np-msg'), '/api/admin/patients', body,
    (d) => `✓ Patient angelegt: ${body.username} → Patient/${d.patientId}`);
  loadAdminPatientList(); // neuer Patient in der Auswahlliste verfuegbar machen
});

// Admin: neuen Arzt (KC-User Doctor+Patient + eigener FHIR-Datensatz) anlegen
$('#admin-add-doctor')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const body = {
    username: $('#nd-username').value.trim(),
    password: $('#nd-password').value,
    firstName: $('#nd-firstname').value.trim(),
    lastName: $('#nd-lastname').value.trim(),
    gender: $('#nd-gender').value || undefined,
    birthDate: $('#nd-birthdate').value || undefined,
  };
  await submitAdminForm(e.target, $('#nd-msg'), '/api/admin/doctors', body,
    (d) => `✓ Arzt angelegt: ${body.username} → Patient/${d.patientId}`);
  loadAdminPatientList(); // Arzt hat eigenen Datensatz -> auch in der Auswahl
});

// Kategorie-Feld nur bei Diagnose (Condition) zeigen.
$('#nc-type')?.addEventListener('change', (e) => {
  $('#nc-cat-wrap')?.classList.toggle('hidden', e.target.value !== 'Condition');
});

// Admin: klinische Daten (Condition/MedicationStatement/AllergyIntolerance) anlegen
$('#admin-add-clinical')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const resourceType = $('#nc-type').value;
  const body = {
    patientId: $('#nc-patient').value,
    resourceType,
    text: $('#nc-text').value.trim(),
    ...(resourceType === 'Condition' ? { category: $('#nc-category').value } : {}),
  };
  await submitAdminForm(e.target, $('#nc-msg'), '/api/admin/clinical', body,
    (d) => `✓ ${resourceType}/${d.id} für Patient/${d.patientId} angelegt`);
});

document.querySelectorAll('.action').forEach((btn) => {
  btn.addEventListener('click', async () => {
    if (!currentPatientId) {
      $('#result-panel').innerHTML = '<div class="denied-box">Kein Patient ausgewählt.</div>';
      return;
    }
    const path = btn.dataset.tmpl.replace('{id}', currentPatientId);
    const label = btn.dataset.label;
    $('#result-panel').innerHTML = resultSkeleton(label);
    try {
      const data = await fhirGet(path);
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
