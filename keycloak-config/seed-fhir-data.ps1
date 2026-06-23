# Legt die Demo-FHIR-Daten an: Patienten (alice/bernd/clara) + klinische Ressourcen.
# Wird als dr.smith ausgefuehrt (Doctor-Rolle darf Ressourcen anlegen).
# Idempotent fuer Patienten: der keycloak-uuid-Identifier verhindert Duplikate
# (ResourceRegistrationInterceptor.validatePatientUnique). Klinische Ressourcen werden
# bei erneutem Lauf zusaetzlich angelegt -> Skript nur auf leerer HAPI-DB ausfuehren.
#
# Voraussetzung: Stack laeuft, Keycloak-Realm + User sind eingerichtet (siehe README).
# Die keycloak-uuid-Werte muessen zu den Usern im Realm passen -> bei frischem Realm-Import
# stimmen sie, weil sie aus demselben Export stammen.
#
# Aufruf:  .\seed-fhir-data.ps1
#          .\seed-fhir-data.ps1 -FhirUrl http://localhost:8081/fhir

param(
    [string]$KeycloakUrl = "http://localhost:8080",
    [string]$FhirUrl = "http://localhost:8081/fhir",
    [string]$ClientId = "fhir-client",
    [string]$ClientSecret = "QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP"
)

$ErrorActionPreference = 'Stop'

# Keycloak-UUIDs der Patienten-User ZUR LAUFZEIT holen (NICHT hartkodieren!).
# bernd/clara werden von setup-smart-v2-authz.ps1 per API angelegt und bekommen dabei
# bei jedem frischen Realm neue UUIDs. Der keycloak-uuid-Identifier am Patienten MUSS
# zur echten User-UUID passen, sonst schlaegt die Owner-Registrierung in Keycloak fehl.
Write-Host "[0] Keycloak-User-UUIDs aufloesen..."
$adminTok = (Invoke-RestMethod -Method Post -Uri "$KeycloakUrl/realms/master/protocol/openid-connect/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body "grant_type=password&client_id=admin-cli&username=admin&password=admin").access_token
$adminH = @{ Authorization = "Bearer $adminTok" }
$UUID = @{}
foreach ($u in @('alice','bernd','clara','dr.smith','dr.bob')) {
    $found = Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/FHIR-Auth/users?username=$u&exact=true" -Headers $adminH
    if ($found.Count -eq 0) { throw "User '$u' fehlt im Realm. Zuerst setup-smart-v2-authz.ps1 ausfuehren." }
    $UUID[$u] = $found[0].id
    Write-Host "    $u = $($UUID[$u])"
}

Write-Host "[1] Access Token (dr.smith) holen..."
$tok = (Invoke-RestMethod -Method Post -Uri "$KeycloakUrl/realms/FHIR-Auth/protocol/openid-connect/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body "grant_type=password&client_id=$ClientId&client_secret=$ClientSecret&username=dr.smith&password=smith123").access_token
$H = @{ Authorization = "Bearer $tok" }

function New-Resource($type, $body) {
    $r = Invoke-WebRequest -Method Post -Uri "$FhirUrl/$type" -Headers $H `
        -ContentType 'application/fhir+json' -Body ($body | ConvertTo-Json -Depth 6) -UseBasicParsing
    $loc = $r.Headers['Location']
    Write-Host "    $type -> $loc"
    # ID aus Location extrahieren: .../fhir/Patient/1/_history/1
    return ($loc -split '/')[-3]
}

function New-Patient($uuid, $family, $given, $gender, $birth) {
    return New-Resource 'Patient' @{
        resourceType = 'Patient'
        identifier   = @(@{ system = 'keycloak-uuid'; value = $uuid })
        name         = @(@{ family = $family; given = @($given) })
        gender       = $gender
        birthDate    = $birth
    }
}

function New-Condition($patientId, $text, $category) {
    New-Resource 'Condition' @{
        resourceType   = 'Condition'
        subject        = @{ reference = "Patient/$patientId" }
        code           = @{ text = $text }
        category       = @(@{ coding = @(@{ system = 'http://terminology.hl7.org/CodeSystem/condition-category'; code = $category }) })
        clinicalStatus = @{ coding = @(@{ system = 'http://terminology.hl7.org/CodeSystem/condition-clinical'; code = 'active' }) }
    } | Out-Null
}

function New-Medication($patientId, $text) {
    New-Resource 'MedicationStatement' @{
        resourceType = 'MedicationStatement'
        status       = 'recorded'
        subject      = @{ reference = "Patient/$patientId" }
        medication   = @{ concept = @{ text = $text } }
    } | Out-Null
}

function New-Allergy($patientId, $text) {
    New-Resource 'AllergyIntolerance' @{
        resourceType   = 'AllergyIntolerance'
        patient        = @{ reference = "Patient/$patientId" }
        code           = @{ text = $text }
        clinicalStatus = @{ coding = @(@{ system = 'http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical'; code = 'active' }) }
    } | Out-Null
}

Write-Host "[2] Patient Alice + klinische Daten..."
$alice = New-Patient $UUID.alice 'Anderson' 'Alice' 'female' '1990-01-01'
New-Condition $alice 'Hypertension'             'problem-list-item'
New-Condition $alice 'Diabetes mellitus Type 2' 'problem-list-item'
New-Condition $alice 'Migraine'                 'encounter-diagnosis'
New-Medication $alice 'Metformin 500mg'
New-Allergy   $alice 'Penicillin'

Write-Host "[3] Patient Bernd + klinische Daten..."
$bernd = New-Patient $UUID.bernd 'Brandt' 'Bernd' 'male' '1978-03-22'
New-Condition  $bernd 'Asthma bronchiale' 'problem-list-item'
New-Medication $bernd 'Salbutamol Inhalator'
New-Allergy    $bernd 'Pollen'

Write-Host "[4] Patient Clara + klinische Daten..."
$clara = New-Patient $UUID.clara 'Schulz' 'Clara' 'female' '1992-11-05'
New-Condition  $clara 'Hypothyreose' 'problem-list-item'
New-Medication $clara 'Levothyroxin 75ug'
New-Allergy    $clara 'Latex'

# Aerzte sind auch Patienten: eigener Datensatz, damit der "Als Patient"-Umschalter
# im Frontend Daten zeigt. Owner = Keycloak-UUID des jeweiligen Arztes.
Write-Host "[5] Patient dr.smith (Arzt mit eigenem Datensatz)..."
$drsmith = New-Patient $UUID['dr.smith'] 'Smith' 'John' 'male' '1980-05-14'
New-Condition  $drsmith 'Hypertension' 'problem-list-item'
New-Condition  $drsmith 'Migraine'     'encounter-diagnosis'
New-Medication $drsmith 'Ibuprofen 400mg'
New-Allergy    $drsmith 'Aspirin'

Write-Host "[6] Patient dr.bob (Arzt mit eigenem Datensatz)..."
$drbob = New-Patient $UUID['dr.bob'] 'Anderson' 'Bob' 'male' '1975-09-30'
New-Condition  $drbob 'Hypertension' 'problem-list-item'
New-Condition  $drbob 'Migraine'     'encounter-diagnosis'
New-Medication $drbob 'Ibuprofen 400mg'
New-Allergy    $drbob 'Aspirin'

Write-Host ""
Write-Host "Fertig. Patienten angelegt: alice=Patient/$alice, bernd=Patient/$bernd, clara=Patient/$clara, dr.smith=Patient/$drsmith, dr.bob=Patient/$drbob"
Write-Host "WICHTIG: Die FHIR-IDs sind NICHT zwingend 1/152/153 (haengen von der Anlagereihenfolge ab)."
Write-Host "Die Owner-Permissions in Keycloak referenzieren konkrete Patient/<id>-Ressourcennamen -"
Write-Host "ggf. die Keycloak-Permissions an die tatsaechlichen IDs anpassen (siehe README)."
