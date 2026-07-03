# Baut die SMART-on-FHIR-v2 / UMA-Grundkonfiguration im Realm FHIR-Auth auf.
# Idempotent: vorhandene Objekte werden erkannt und aktualisiert statt dupliziert.
#
# Normalfall: Der mitgelieferte Realm-Export (keycloak-files/fhir-auth-realm-export.json)
# enthaelt diesen Stand bereits -> dieses Skript ist dann nur Fallback/Reparatur.
# Wird stattdessen ein nackter Realm importiert, stellt dieses Skript die Infrastruktur her:
#   - uma_protection als Default Client Scope
#   - Decision Strategy AFFIRMATIVE (Resource-Server-Ebene)
#   - die SMART-v2 Authorization Scopes (patient/<Type>.<interactions>)
#   - RolePolicy-Doctor (Rollen-Policy, wird vom Proxy bei Arzt-Freigaben referenziert)
#
# WICHTIG (neues Onboarding-Modell): Es werden KEINE Demo-User (alice/bernd/clara/dr.*)
# und KEINE patientenspezifischen Owner-/TrustList-Policies mehr angelegt. Bei einer
# Neuinstallation existiert nur der Administrator (admin/admin123, aus dem Realm-Export).
# Patienten und Aerzte werden zur Laufzeit ueber das Admin-Panel im Frontend angelegt
# (POST /api/admin/users mit role='patient' bzw. role='doctor') - dabei entstehen die
# verknuepften FHIR-Ressourcen und die Owner-Vollzugriffs-Permissions automatisch.

param(
    [string]$KeycloakUrl = "http://localhost:8080",
    [string]$Realm = "FHIR-Auth",
    [string]$ClientId = "fhir-client"
)

$ErrorActionPreference = 'Stop'

# --- Admin Token ---
$tokenResp = Invoke-RestMethod -Method Post -Uri "$KeycloakUrl/realms/master/protocol/openid-connect/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body "grant_type=password&client_id=admin-cli&username=admin&password=admin"
$H = @{ Authorization = "Bearer $($tokenResp.access_token)" }
$base = "$KeycloakUrl/admin/realms/$Realm"
$cid = (Invoke-RestMethod -Uri "$base/clients?clientId=$ClientId" -Headers $H)[0].id
$authz = "$base/clients/$cid/authz/resource-server"
Write-Host "Client $ClientId = $cid"

# --- 1. uma_protection Client Scope (Default fuer fhir-client) ---
$umaCs = (Invoke-RestMethod -Uri "$base/client-scopes" -Headers $H) | Where-Object { $_.name -eq 'uma_protection' }
if (-not $umaCs) {
    $body = @{ name = 'uma_protection'; protocol = 'openid-connect'; attributes = @{ 'include.in.token.scope' = 'true' } } | ConvertTo-Json
    Invoke-RestMethod -Method Post -Uri "$base/client-scopes" -Headers $H -ContentType 'application/json' -Body $body | Out-Null
    $umaCs = (Invoke-RestMethod -Uri "$base/client-scopes" -Headers $H) | Where-Object { $_.name -eq 'uma_protection' }
    Write-Host "Client Scope uma_protection angelegt"
}
Invoke-RestMethod -Method Put -Uri "$base/clients/$cid/default-client-scopes/$($umaCs.id)" -Headers $H | Out-Null
Write-Host "uma_protection als Default Scope gesetzt"

# --- 2. Decision Strategy AFFIRMATIVE ---
# Muss AFFIRMATIVE sein: mehrere Permissions teilen sich denselben Scope. Bei UNANIMOUS
# wuerde das DENY einer fremden Permission den Zugriff blockieren. "Unanimous" gilt nur
# INNERHALB einer Permission (TrustList UND Doctor-Rolle).
$rs = Invoke-RestMethod -Uri $authz -Headers $H
if ($rs.decisionStrategy -ne 'AFFIRMATIVE') {
    $rs.decisionStrategy = 'AFFIRMATIVE'
    Invoke-RestMethod -Method Put -Uri $authz -Headers $H -ContentType 'application/json' -Body ($rs | ConvertTo-Json) | Out-Null
    Write-Host "Decision Strategy auf AFFIRMATIVE gesetzt"
}

# --- 3. SMART v2 Authorization Scopes ---
$smartScopes = @(
    'patient/Patient.r', 'patient/Patient.rs',
    'patient/Condition.rs', 'patient/MedicationStatement.rs', 'patient/AllergyIntolerance.rs'
)
foreach ($s in $smartScopes) {
    if (-not ((Invoke-RestMethod -Uri "$authz/scope?max=200" -Headers $H) | Where-Object { $_.name -eq $s })) {
        Invoke-RestMethod -Method Post -Uri "$authz/scope" -Headers $H -ContentType 'application/json' -Body (@{ name = $s } | ConvertTo-Json) | Out-Null
        Write-Host "Scope $s angelegt"
    }
}

# --- 4. RolePolicy-Doctor ---
# Rollen-Policy, die der Frontend-Proxy bei jeder patientengesteuerten Arzt-Freigabe
# zusammen mit der dynamisch erzeugten TrustList-Policy an die Permission haengt.
function Get-PolicyByName([string]$name) {
    (Invoke-RestMethod -Uri "$authz/policy?name=$([uri]::EscapeDataString($name))&max=100" -Headers $H) | Where-Object { $_.name -eq $name }
}
$doctorRole = Invoke-RestMethod -Uri "$base/roles/Doctor" -Headers $H
if (-not (Get-PolicyByName 'RolePolicy-Doctor')) {
    $body = @{ name='RolePolicy-Doctor'; type='role'; logic='POSITIVE'; decisionStrategy='UNANIMOUS'; roles=@(@{ id=$doctorRole.id; required=$true }) }
    Invoke-RestMethod -Method Post -Uri "$authz/policy/role" -Headers $H -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 5) | Out-Null
    Write-Host "Policy RolePolicy-Doctor angelegt"
}

Write-Host ""
Write-Host "Fertig. Grundkonfiguration steht."
Write-Host "Patienten/Aerzte ueber das Admin-Panel im Frontend anlegen (Login: admin / admin123)."
