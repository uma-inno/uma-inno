# Baut die komplette SMART-on-FHIR-v2 / UMA-Autorisierungskonfiguration im Realm FHIR-Auth auf.
# Idempotent: vorhandene Objekte werden erkannt und aktualisiert statt dupliziert.
#
# Normalfall: Der mitgelieferte Realm-Export (keycloak-files/fhir-auth-realm-export.json)
# enthaelt bereits den vollstaendigen Stand -> dieses Skript ist dann nur Fallback/Reparatur.
# Wird stattdessen ein nackter Realm importiert, baut dieses Skript die Konfiguration auf:
#   - die Patienten-User bernd + clara (Rolle Patient)
#   - die SMART-v2 Authorization Scopes
#   - Policies (RolePolicy-Doctor, TrustLists, Owner-Policies)
#   - die scope-basierten Permissions je Patient
#   - uma_protection als Default Client Scope, Decision Strategy AFFIRMATIVE
#
# REIHENFOLGE (siehe README):
#   1. .\setup-smart-v2-authz.ps1            # User + Scopes + Policies + Client-Config
#   2. .\seed-fhir-data.ps1                  # Patienten/klinische Ressourcen in HAPI anlegen
#                                            #   -> dabei registriert HAPI die Patient/<id>-Ressourcen in KC
#   3. .\setup-smart-v2-authz.ps1            # erneut: jetzt werden die Permissions auf die
#                                            #   real existierenden Patient/<id>-Ressourcen gelegt
#
# Mit -CleanupLegacy werden zusaetzlich die Altobjekte aus dem Import entfernt.

param(
    [string]$KeycloakUrl = "http://localhost:8080",
    [string]$Realm = "FHIR-Auth",
    [string]$ClientId = "fhir-client",
    [switch]$CleanupLegacy
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

# --- 0. Patienten-User bernd + clara anlegen (falls fehlen) ---
$patientRole = Invoke-RestMethod -Uri "$base/roles/Patient" -Headers $H
foreach ($u in @(
    @{ name='bernd'; first='Bernd'; last='Brandt'; pass='bernd123' },
    @{ name='clara'; first='Clara'; last='Schulz'; pass='clara123' }
)) {
    $existing = Invoke-RestMethod -Uri "$base/users?username=$($u.name)&exact=true" -Headers $H
    if ($existing.Count -gt 0) { Write-Host "User $($u.name) existiert bereits"; continue }
    $body = @{
        username = $u.name; enabled = $true; firstName = $u.first; lastName = $u.last
        email = "$($u.name)@example.org"; emailVerified = $true
        credentials = @(@{ type = 'password'; value = $u.pass; temporary = $false })
    } | ConvertTo-Json -Depth 4
    Invoke-RestMethod -Method Post -Uri "$base/users" -Headers $H -ContentType 'application/json' -Body $body | Out-Null
    $created = (Invoke-RestMethod -Uri "$base/users?username=$($u.name)&exact=true" -Headers $H)[0]
    $roleBody = ConvertTo-Json @(@{ id = $patientRole.id; name = 'Patient' })
    Invoke-RestMethod -Method Post -Uri "$base/users/$($created.id)/role-mappings/realm" -Headers $H -ContentType 'application/json' -Body $roleBody | Out-Null
    Write-Host "User $($u.name) angelegt (Rolle Patient)"
}

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
$scopeId = @{}; (Invoke-RestMethod -Uri "$authz/scope?max=200" -Headers $H) | ForEach-Object { $scopeId[$_.name] = $_.id }

# --- 4. User-/Rollen-IDs ---
function Get-UserId([string]$name) { (Invoke-RestMethod -Uri "$base/users?username=$name&exact=true" -Headers $H)[0].id }
$ids = @{ alice = Get-UserId 'alice'; bob = Get-UserId 'dr.bob'; smith = Get-UserId 'dr.smith'; bernd = Get-UserId 'bernd'; clara = Get-UserId 'clara' }
$doctorRole = Invoke-RestMethod -Uri "$base/roles/Doctor" -Headers $H

# --- 5. Policies ---
function Get-PolicyByName([string]$name) {
    (Invoke-RestMethod -Uri "$authz/policy?name=$([uri]::EscapeDataString($name))&max=100" -Headers $H) | Where-Object { $_.name -eq $name }
}
function Ensure-Policy([string]$name, [string]$type, [hashtable]$body) {
    $p = Get-PolicyByName $name
    if ($p) { return $p }
    Invoke-RestMethod -Method Post -Uri "$authz/policy/$type" -Headers $H -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 5) | Out-Null
    Write-Host "Policy $name angelegt"
    Get-PolicyByName $name
}

$polDoctor = Ensure-Policy 'RolePolicy-Doctor' 'role' @{ name='RolePolicy-Doctor'; type='role'; logic='POSITIVE'; decisionStrategy='UNANIMOUS'; roles=@(@{ id=$doctorRole.id; required=$true }) }
$polBob    = Ensure-Policy 'TrustList-Patient1-DrBob'   'user' @{ name='TrustList-Patient1-DrBob';   type='user'; logic='POSITIVE'; decisionStrategy='UNANIMOUS'; users=@($ids.bob) }
$polSmith  = Ensure-Policy 'TrustList-Patient1-DrSmith' 'user' @{ name='TrustList-Patient1-DrSmith'; type='user'; logic='POSITIVE'; decisionStrategy='UNANIMOUS'; users=@($ids.smith) }
$polAlice  = Ensure-Policy 'UserPolicy-Alice' 'user' @{ name='UserPolicy-Alice'; type='user'; logic='POSITIVE'; decisionStrategy='UNANIMOUS'; users=@($ids.alice) }
$ownerPolicies = @{
    bernd = Ensure-Policy 'UserPolicy-Owner-bernd' 'user' @{ name='UserPolicy-Owner-bernd'; type='user'; logic='POSITIVE'; decisionStrategy='UNANIMOUS'; users=@($ids.bernd) }
    clara = Ensure-Policy 'UserPolicy-Owner-clara' 'user' @{ name='UserPolicy-Owner-clara'; type='user'; logic='POSITIVE'; decisionStrategy='UNANIMOUS'; users=@($ids.clara) }
    alice = $polAlice
}

# --- 6. Permissions je Patient-Ressource ---
# Patient-Ressourcen existieren erst NACH dem FHIR-Seed. Dieses Skript verarbeitet alle
# vorhandenen Patient/<id>-Ressourcen anhand ihres Owners.
function Ensure-ScopePermission([string]$name, [string]$resId, [string[]]$scopeNames, [object[]]$policies) {
    $existing = Get-PolicyByName $name
    $bodyHash = @{
        name = $name; type = 'scope'; logic = 'POSITIVE'; decisionStrategy = 'UNANIMOUS'
        resources = @($resId); scopes = @($scopeNames | ForEach-Object { $scopeId[$_] }); policies = @($policies | ForEach-Object { $_.id })
    }
    if ($existing) {
        $bodyHash.id = $existing.id
        Invoke-RestMethod -Method Put -Uri "$authz/permission/scope/$($existing.id)" -Headers $H -ContentType 'application/json' -Body ($bodyHash | ConvertTo-Json -Depth 5) | Out-Null
        Write-Host "Permission $name aktualisiert"
    } else {
        Invoke-RestMethod -Method Post -Uri "$authz/permission/scope" -Headers $H -ContentType 'application/json' -Body ($bodyHash | ConvertTo-Json -Depth 5) | Out-Null
        Write-Host "Permission $name angelegt"
    }
}

$patientResources = (Invoke-RestMethod -Uri "$authz/resource?max=200" -Headers $H) | Where-Object { $_.name -match '^Patient/\d+$' }
if (-not $patientResources) {
    Write-Host ""
    Write-Host "HINWEIS: Noch keine Patient/<id>-Ressourcen in Keycloak registriert."
    Write-Host "-> Zuerst .\seed-fhir-data.ps1 ausfuehren, dann dieses Skript erneut starten."
} else {
    $ownerToUser = @{ "$($ids.alice)" = 'alice'; "$($ids.bernd)" = 'bernd'; "$($ids.clara)" = 'clara' }
    foreach ($pr in $patientResources) {
        $full = Invoke-RestMethod -Uri "$authz/resource/$($pr._id)" -Headers $H
        $num = $pr.name -replace '^Patient/', ''
        # OMA=false + alle SMART-Scopes an der Ressource (bekanntes Problem request_submitted bei OMA=true)
        $resBody = @{
            _id=$full._id; name=$full.name; displayName=$full.name; type=$full.type
            owner=@{ id=$full.owner.id }; ownerManagedAccess=$false
            scopes=@($smartScopes | ForEach-Object { @{ name=$_ } })
        } | ConvertTo-Json -Depth 5
        Invoke-RestMethod -Method Put -Uri "$authz/resource/$($full._id)" -Headers $H -ContentType 'application/json' -Body $resBody | Out-Null

        $ownerUser = $ownerToUser["$($full.owner.id)"]
        if ($ownerUser -eq 'alice') {
            # Alice (Owner von Patient/1): voller Zugriff auf alle Typen
            Ensure-ScopePermission "Permission-Patient$num-Alice-Full" $full._id $smartScopes @($polAlice)
            # plus die beiden Aerzte gemaess Demo-Szenario
            Ensure-ScopePermission "Permission-Patient$num-DrBob-Condition" $full._id @('patient/Condition.rs') @($polBob, $polDoctor)
            Ensure-ScopePermission "Permission-Patient$num-DrSmith-Full"    $full._id @('patient/Patient.r')    @($polSmith, $polDoctor)
        } elseif ($ownerUser) {
            # bernd/clara: nur Owner-Vollzugriff (keine Arzt-Freigaben -> Demo fuer access_denied)
            Ensure-ScopePermission "Permission-Patient$num-Owner-Full" $full._id $smartScopes @($ownerPolicies[$ownerUser])
        } else {
            Write-Host "Ressource $($full.name): Owner unbekannt ($($full.owner.name)), uebersprungen"
        }
    }
}

# --- 7. Optional: Alt-Konfiguration aus dem Import entfernen ---
if ($CleanupLegacy) {
    Write-Host "== Cleanup Alt-Konfiguration =="
    $keep = @('RolePolicy-Doctor','TrustList-Patient1-DrBob','TrustList-Patient1-DrSmith','UserPolicy-Alice',
              'UserPolicy-Owner-bernd','UserPolicy-Owner-clara') +
            ((Invoke-RestMethod -Uri "$authz/policy?max=300" -Headers $H) | Where-Object { $_.name -like 'Permission-Patient*' } | ForEach-Object { $_.name })
    $legacy = (Invoke-RestMethod -Uri "$authz/policy?max=300" -Headers $H) | Where-Object { $keep -notcontains $_.name }
    foreach ($p in ($legacy | Sort-Object { if ($_.type -in 'scope','resource') {0} elseif ($_.type -eq 'aggregate') {1} else {2} })) {
        Invoke-RestMethod -Method Delete -Uri "$authz/policy/$($p.id)" -Headers $H | Out-Null
        Write-Host "Geloescht: $($p.name) [$($p.type)]"
    }
    foreach ($r in ((Invoke-RestMethod -Uri "$authz/resource?max=200" -Headers $H) | Where-Object { $_.name -notmatch '^Patient/\d+$' -and $_.name -ne 'Default Resource' })) {
        Invoke-RestMethod -Method Delete -Uri "$authz/resource/$($r._id)" -Headers $H | Out-Null
        Write-Host "Geloescht: Ressource $($r.name)"
    }
    foreach ($s in ((Invoke-RestMethod -Uri "$authz/scope?max=200" -Headers $H) | Where-Object { $_.name -notlike 'patient/*' })) {
        Invoke-RestMethod -Method Delete -Uri "$authz/scope/$($s.id)" -Headers $H | Out-Null
        Write-Host "Geloescht: Scope $($s.name)"
    }
}

Write-Host ""
Write-Host "Fertig."
