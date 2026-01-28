#!/bin/bash

# Script to create test UMA permissions for the auto-registered resources
# Run this after create-fhir-resources.sh

KEYCLOAK_URL="http://localhost:8080"
REALM="FHIR-Auth"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "=== Creating Test UMA Permissions ==="

# Get admin access token
echo "Getting admin access token..."
ACCESS_TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$ADMIN_USER" \
  -d "password=$ADMIN_PASSWORD" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "ERROR: Failed to get access token. Check admin credentials."
    exit 1
fi
echo "Got access token!"

# Get fhir-client ID
echo "Getting fhir-client ID..."
CLIENT_ID=$(curl -s "$KEYCLOAK_URL/admin/realms/$REALM/clients?clientId=fhir-client" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.[0].id')

if [ "$CLIENT_ID" == "null" ] || [ -z "$CLIENT_ID" ]; then
    echo "ERROR: Failed to get fhir-client ID."
    exit 1
fi
echo "fhir-client ID: $CLIENT_ID"

BASE_URL="$KEYCLOAK_URL/admin/realms/$REALM/clients/$CLIENT_ID/authz/resource-server"

# Function to get resource ID by name
get_resource_id() {
    local name=$1
    curl -s "$BASE_URL/resource" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.[] | select(.name=="'"$name"'") | ._id'
}

# Function to get scope ID by name
get_scope_id() {
    local name=$1
    curl -s "$BASE_URL/scope" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.[] | select(.name=="'"$name"'") | .id'
}

# Function to get policy ID by name
get_policy_id() {
    local name=$1
    curl -s "$BASE_URL/policy" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.[] | select(.name=="'"$name"'") | .id'
}

# Look up resource IDs (using actual FHIR resource IDs)
echo ""
echo "Looking up resource IDs..."
PATIENT_1_ID=$(get_resource_id "Patient/1")
CONDITION_3_ID=$(get_resource_id "Condition/3")
ALLERGY_4_ID=$(get_resource_id "AllergyIntolerance/4")

echo "  Patient/1: $PATIENT_1_ID"
echo "  Condition/3: $CONDITION_3_ID"
echo "  AllergyIntolerance/4: $ALLERGY_4_ID"

echo ""
echo "Looking up scope IDs..."
READ_SCOPE_ID=$(get_scope_id "read")
echo "  read: $READ_SCOPE_ID"

echo ""
echo "Looking up policy IDs..."
DR_SMITH_POLICY_ID=$(get_policy_id "Dr Smith User Policy")
DR_BOB_POLICY_ID=$(get_policy_id "Dr. Bob User Policy")

echo "  Dr Smith User Policy: $DR_SMITH_POLICY_ID"
echo "  Dr. Bob User Policy: $DR_BOB_POLICY_ID"

# Validate lookups
if [ "$PATIENT_1_ID" == "null" ] || [ -z "$PATIENT_1_ID" ]; then
    echo "ERROR: Patient/1 resource not found. Run create-fhir-resources.sh first."
    exit 1
fi

if [ "$DR_SMITH_POLICY_ID" == "null" ] || [ -z "$DR_SMITH_POLICY_ID" ]; then
    echo "ERROR: Dr Smith User Policy not found."
    exit 1
fi

if [ "$DR_BOB_POLICY_ID" == "null" ] || [ -z "$DR_BOB_POLICY_ID" ]; then
    echo "ERROR: Dr. Bob User Policy not found."
    exit 1
fi

# Function to create a scope permission
create_permission() {
    local name=$1
    local resource_ids=$2  # JSON array string
    local scope_ids=$3     # JSON array string
    local policy_ids=$4    # JSON array string

    echo "Creating permission: $name..."

    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/permission/scope" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"name\": \"$name\",
        \"type\": \"scope\",
        \"logic\": \"POSITIVE\",
        \"decisionStrategy\": \"AFFIRMATIVE\",
        \"resources\": $resource_ids,
        \"scopes\": $scope_ids,
        \"policies\": $policy_ids
      }")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" == "201" ]; then
        echo "  Created successfully!"
    elif [ "$http_code" == "409" ]; then
        echo "  Already exists (skipping)"
    else
        echo "  Failed with HTTP $http_code: $body"
    fi
}

echo ""
echo "=== Creating Dr. Smith's Permissions (Alice's data) ==="

# Dr. Smith read access to Patient/1
create_permission \
    "Dr. Smith read Patient/1" \
    "[\"$PATIENT_1_ID\"]" \
    "[\"$READ_SCOPE_ID\"]" \
    "[\"$DR_SMITH_POLICY_ID\"]"

# Dr. Smith read access to Condition/3
create_permission \
    "Dr. Smith read Condition/3" \
    "[\"$CONDITION_3_ID\"]" \
    "[\"$READ_SCOPE_ID\"]" \
    "[\"$DR_SMITH_POLICY_ID\"]"

echo ""
echo "=== Creating Dr. Bob's Permissions (Alice's data) ==="

# Dr. Bob read access to AllergyIntolerance/4
create_permission \
    "Dr. Bob read AllergyIntolerance/4" \
    "[\"$ALLERGY_4_ID\"]" \
    "[\"$READ_SCOPE_ID\"]" \
    "[\"$DR_BOB_POLICY_ID\"]"

echo ""
echo "=== Done! ==="
echo ""
echo "Permissions created:"
echo "  - Dr. Smith can read: Patient/1 (alice), Condition/3 (alice)"
echo "  - Dr. Bob can read: AllergyIntolerance/4 (alice)"
echo ""
echo "You can now test UMA authorization with curl-testing-commands.md"
