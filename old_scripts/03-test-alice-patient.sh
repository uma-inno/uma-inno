#!/bin/bash
# Test Alice (Patient role) access permissions

source "$(dirname "$0")/00-config.sh"
source "$(dirname "$0")/01-helper-functions.sh"

print_header "Test 2: Alice (Patient Role) - Access Tests"

# Check servers
if ! check_servers; then
    exit 1
fi

echo ""
print_info "Testing Alice's permissions:"
print_info "- Should be able to READ Patient, AllergyIntolerance, Condition, MedicationStatement"
print_info "- Should NOT be able to DELETE any resources"
echo ""

# Test 1: Alice can read Patient resources
test_uma_flow "$ALICE_USERNAME" "$ALICE_PASSWORD" "Patient"
RESULT_1=$?

echo ""

# Test 2: Alice can read AllergyIntolerance
test_resource_access "$ALICE_USERNAME" "$ALICE_PASSWORD" "AllergyIntolerance" "GET" "true"
RESULT_2=$?

echo ""

# Test 3: Alice can read Condition
test_resource_access "$ALICE_USERNAME" "$ALICE_PASSWORD" "Condition" "GET" "true"
RESULT_3=$?

echo ""

# Test 4: Alice can read MedicationStatement
test_resource_access "$ALICE_USERNAME" "$ALICE_PASSWORD" "MedicationStatement" "GET" "true"
RESULT_4=$?

echo ""
print_header "Negative Tests: Alice Should Be Denied These"
echo ""

# Test 5: Alice should NOT be able to delete Patient
print_test "Testing Alice DELETE Patient (should be denied)"
access_token=$(get_access_token "$ALICE_USERNAME" "$ALICE_PASSWORD")
ticket=$(get_permission_ticket "Patient/1" "DELETE")
rpt=$(get_rpt_token "$ticket" "$access_token" 2>&1)

if [ $? -ne 0 ]; then
    print_success "PASSED: Alice correctly denied DELETE permission"
    RESULT_5=0
else
    # Try the delete
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$FHIR_URL/fhir/Patient/1" \
        -H "Authorization: Bearer $rpt")

    if [ "$http_code" = "403" ] || [ "$http_code" = "401" ]; then
        print_success "PASSED: Alice correctly denied DELETE - HTTP $http_code"
        RESULT_5=0
    else
        print_error "FAILED: Alice should not be able to DELETE - HTTP $http_code"
        RESULT_5=1
    fi
fi

echo ""
print_header "Alice Test Summary"

TOTAL=5
PASSED=$((5 - RESULT_1 - RESULT_2 - RESULT_3 - RESULT_4 - RESULT_5))

echo ""
print_info "Results: $PASSED/$TOTAL tests passed"
echo ""

if [ $PASSED -eq $TOTAL ]; then
    print_success "All tests passed! Alice's permissions are correctly configured."
    exit 0
else
    print_error "Some tests failed. Check Keycloak policies for Patient role."
    exit 1
fi
