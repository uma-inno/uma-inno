#!/bin/bash

# Script to create FHIR resources in HAPI that trigger automatic Keycloak registration
# Only creates Patient resources linked to Keycloak users (with keycloak-uuid identifier)
# This ensures all resources have proper UMA owners

HAPI_URL="http://localhost:8081/fhir"
KEYCLOAK_URL="http://localhost:8080"
REALM="FHIR-Auth"

echo "=== Creating FHIR Resources in HAPI ==="
echo "(Only creating resources linked to Keycloak users)"

# Get admin token to look up user IDs
echo ""
echo "Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" == "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "ERROR: Failed to get admin token"
    exit 1
fi

# Get user UUIDs from Keycloak
echo "Looking up Keycloak user IDs..."
ALICE_KC_ID=$(curl -s "$KEYCLOAK_URL/admin/realms/$REALM/users?username=alice&exact=true" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')
DR_BOB_KC_ID=$(curl -s "$KEYCLOAK_URL/admin/realms/$REALM/users?username=dr.bob&exact=true" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')
DR_SMITH_KC_ID=$(curl -s "$KEYCLOAK_URL/admin/realms/$REALM/users?username=dr.smith&exact=true" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')
JAN_KC_ID=$(curl -s "$KEYCLOAK_URL/admin/realms/$REALM/users?username=jan&exact=true" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

echo "  alice: $ALICE_KC_ID"
echo "  dr.bob: $DR_BOB_KC_ID"
echo "  dr.smith: $DR_SMITH_KC_ID"
echo "  jan: $JAN_KC_ID"

# Get doctor tokens (doctors can create resources)
echo ""
echo "Getting doctor tokens..."
DR_BOB_TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -d "username=dr.bob&password=bob123&grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" | jq -r '.access_token')

DR_SMITH_TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -d "username=dr.smith&password=smith123&grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" | jq -r '.access_token')

if [ "$DR_BOB_TOKEN" == "null" ] || [ -z "$DR_BOB_TOKEN" ]; then
    echo "ERROR: Failed to get Dr. Bob's token"
    exit 1
fi
echo "  Got tokens for dr.bob and dr.smith"

echo ""
echo "=== Creating Patient Resources (linked to Keycloak users) ==="

# Alice's Patient (linked to her Keycloak account)
echo "Creating Patient for alice..."
ALICE_PATIENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$HAPI_URL/Patient" \
  -H "Authorization: Bearer $DR_SMITH_TOKEN" \
  -H "Content-Type: application/fhir+json" \
  -d '{"resourceType":"Patient","identifier":[{"system":"keycloak-uuid","value":"'"$ALICE_KC_ID"'"}],"name":[{"family":"Smith","given":["Alice"]}],"gender":"female","birthDate":"1985-03-15"}')
ALICE_HTTP=$(echo "$ALICE_PATIENT_RESPONSE" | tail -n1)
ALICE_BODY=$(echo "$ALICE_PATIENT_RESPONSE" | sed '$d')
if [ "$ALICE_HTTP" == "201" ]; then
    ALICE_PATIENT_ID=$(echo "$ALICE_BODY" | jq -r '.id')
    echo "  Created successfully! ID: $ALICE_PATIENT_ID (owner: alice)"
elif [ "$ALICE_HTTP" == "422" ]; then
    # Patient already exists, extract existing ID from error message
    ALICE_PATIENT_ID=$(echo "$ALICE_BODY" | jq -r '.issue[0].diagnostics' | grep -oE 'ID: [0-9]+' | grep -oE '[0-9]+')
    echo "  Already exists! ID: $ALICE_PATIENT_ID (owner: alice)"
else
    echo "  Failed with HTTP $ALICE_HTTP"
    echo "$ALICE_BODY" | jq -r '.issue[0].diagnostics' 2>/dev/null
    ALICE_PATIENT_ID=""
fi

# Jan's Patient (if jan user exists)
if [ -n "$JAN_KC_ID" ] && [ "$JAN_KC_ID" != "null" ]; then
    echo "Creating Patient for jan..."
    JAN_PATIENT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$HAPI_URL/Patient" \
      -H "Authorization: Bearer $DR_BOB_TOKEN" \
      -H "Content-Type: application/fhir+json" \
      -d '{"resourceType":"Patient","identifier":[{"system":"keycloak-uuid","value":"'"$JAN_KC_ID"'"}],"name":[{"family":"Meyer","given":["Jan"]}],"gender":"male","birthDate":"1990-06-20"}')
    JAN_HTTP=$(echo "$JAN_PATIENT_RESPONSE" | tail -n1)
    JAN_BODY=$(echo "$JAN_PATIENT_RESPONSE" | sed '$d')
    if [ "$JAN_HTTP" == "201" ]; then
        JAN_PATIENT_ID=$(echo "$JAN_BODY" | jq -r '.id')
        echo "  Created successfully! ID: $JAN_PATIENT_ID (owner: jan)"
    elif [ "$JAN_HTTP" == "422" ]; then
        JAN_PATIENT_ID=$(echo "$JAN_BODY" | jq -r '.issue[0].diagnostics' | grep -oE 'ID: [0-9]+' | grep -oE '[0-9]+')
        echo "  Already exists! ID: $JAN_PATIENT_ID (owner: jan)"
    else
        echo "  Failed with HTTP $JAN_HTTP"
        echo "$JAN_BODY" | jq -r '.issue[0].diagnostics' 2>/dev/null
        JAN_PATIENT_ID=""
    fi
else
    echo "  Skipping jan - user not found in Keycloak"
    JAN_PATIENT_ID=""
fi

echo ""
echo "=== Creating Clinical Resources for Alice ==="

if [ -n "$ALICE_PATIENT_ID" ] && [ "$ALICE_PATIENT_ID" != "null" ]; then
    # Condition - Diabetes
    echo "Creating Condition (Diabetes)..."
    curl -s -X POST "$HAPI_URL/Condition" \
      -H "Authorization: Bearer $DR_SMITH_TOKEN" \
      -H "Content-Type: application/fhir+json" \
      -d '{"resourceType":"Condition","subject":{"reference":"Patient/'"$ALICE_PATIENT_ID"'"},"clinicalStatus":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/condition-clinical","code":"active"}]},"verificationStatus":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/condition-ver-status","code":"confirmed"}]},"code":{"coding":[{"system":"http://snomed.info/sct","code":"73211009","display":"Diabetes mellitus"}]}}' | jq -r 'if .id then "  Created! ID: \(.id) (owner: alice)" else "  Failed: \(.issue[0].diagnostics)" end'

    # AllergyIntolerance - Peanuts
    echo "Creating AllergyIntolerance (Peanut allergy)..."
    curl -s -X POST "$HAPI_URL/AllergyIntolerance" \
      -H "Authorization: Bearer $DR_SMITH_TOKEN" \
      -H "Content-Type: application/fhir+json" \
      -d '{"resourceType":"AllergyIntolerance","patient":{"reference":"Patient/'"$ALICE_PATIENT_ID"'"},"clinicalStatus":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical","code":"active"}]},"verificationStatus":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/allergyintolerance-verification","code":"confirmed"}]},"code":{"coding":[{"system":"http://snomed.info/sct","code":"91935009","display":"Allergy to peanuts"}]}}' | jq -r 'if .id then "  Created! ID: \(.id) (owner: alice)" else "  Failed: \(.issue[0].diagnostics)" end'

    # MedicationStatement - Metformin
    echo "Creating MedicationStatement (Metformin)..."
    curl -s -X POST "$HAPI_URL/MedicationStatement" \
      -H "Authorization: Bearer $DR_SMITH_TOKEN" \
      -H "Content-Type: application/fhir+json" \
      -d '{"resourceType":"MedicationStatement","status":"recorded","subject":{"reference":"Patient/'"$ALICE_PATIENT_ID"'"},"medication":{"concept":{"coding":[{"system":"http://www.nlm.nih.gov/research/umls/rxnorm","code":"860975","display":"Metformin 500mg"}]}}}' | jq -r 'if .id then "  Created! ID: \(.id) (owner: alice)" else "  Failed: \(.issue[0].diagnostics)" end'
else
    echo "  Skipping - Alice's Patient was not created"
fi

echo ""
echo "=== Creating Clinical Resources for Jan ==="

if [ -n "$JAN_PATIENT_ID" ] && [ "$JAN_PATIENT_ID" != "null" ]; then
    # Condition - Asthma
    echo "Creating Condition (Asthma)..."
    curl -s -X POST "$HAPI_URL/Condition" \
      -H "Authorization: Bearer $DR_BOB_TOKEN" \
      -H "Content-Type: application/fhir+json" \
      -d '{"resourceType":"Condition","subject":{"reference":"Patient/'"$JAN_PATIENT_ID"'"},"clinicalStatus":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/condition-clinical","code":"active"}]},"verificationStatus":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/condition-ver-status","code":"confirmed"}]},"code":{"coding":[{"system":"http://snomed.info/sct","code":"195967001","display":"Asthma"}]}}' | jq -r 'if .id then "  Created! ID: \(.id) (owner: jan)" else "  Failed: \(.issue[0].diagnostics)" end'

    # AllergyIntolerance - Penicillin
    echo "Creating AllergyIntolerance (Penicillin allergy)..."
    curl -s -X POST "$HAPI_URL/AllergyIntolerance" \
      -H "Authorization: Bearer $DR_BOB_TOKEN" \
      -H "Content-Type: application/fhir+json" \
      -d '{"resourceType":"AllergyIntolerance","patient":{"reference":"Patient/'"$JAN_PATIENT_ID"'"},"clinicalStatus":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical","code":"active"}]},"verificationStatus":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/allergyintolerance-verification","code":"confirmed"}]},"code":{"coding":[{"system":"http://snomed.info/sct","code":"91936005","display":"Allergy to penicillin"}]}}' | jq -r 'if .id then "  Created! ID: \(.id) (owner: jan)" else "  Failed: \(.issue[0].diagnostics)" end'
else
    echo "  Skipping - Jan's Patient was not created"
fi

echo ""
echo "=== Done! ==="
echo ""
echo "Resources created (all linked to Keycloak users):"
echo "  Alice (Patient ID: $ALICE_PATIENT_ID):"
echo "    - Patient, Condition (Diabetes), AllergyIntolerance (Peanuts), MedicationStatement (Metformin)"
if [ -n "$JAN_PATIENT_ID" ] && [ "$JAN_PATIENT_ID" != "null" ]; then
echo "  Jan (Patient ID: $JAN_PATIENT_ID):"
echo "    - Patient, Condition (Asthma), AllergyIntolerance (Penicillin)"
fi
echo ""
echo "All resources have proper UMA owners based on keycloak-uuid identifiers."
echo "Check Keycloak: Clients -> fhir-client -> Authorization -> Resources"
