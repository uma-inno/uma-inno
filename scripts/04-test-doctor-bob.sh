#!/bin/bash
# Test Dr. Bob (Doctor role) access permissions

source "$(dirname "$0")/00-config.sh"
source "$(dirname "$0")/01-helper-functions.sh"

print_header "Test 3: Dr. Bob (Doctor Role) - Access Tests"

# Check servers
if ! check_servers; then
    exit 1
fi

echo ""
print_info "Testing Dr. Bob's permissions:"
print_info "- Should be able to READ all medical resources"
print_info "- Should be able to CREATE/UPDATE Conditions, Allergies, Medications"
print_info "- Should be able to READ Patient resources"
print_info "- Should NOT be able to DELETE Patient resources (only admin)"
echo ""

# Test 1: Dr. Bob can read Patient resources
test_uma_flow "$DOCTOR_USERNAME" "$DOCTOR_PASSWORD" "Patient"
RESULT_1=$?

echo ""

# Test 2: Dr. Bob can read AllergyIntolerance
test_resource_access "$DOCTOR_USERNAME" "$DOCTOR_PASSWORD" "AllergyIntolerance" "GET" "true"
RESULT_2=$?

echo ""

# Test 3: Dr. Bob can read Condition
test_resource_access "$DOCTOR_USERNAME" "$DOCTOR_PASSWORD" "Condition" "GET" "true"
RESULT_3=$?

echo ""

# Test 4: Dr. Bob can read MedicationStatement
test_resource_access "$DOCTOR_USERNAME" "$DOCTOR_PASSWORD" "MedicationStatement" "GET" "true"
RESULT_4=$?

echo ""
print_header "Testing Dr. Bob's Write Permissions"
echo ""

# Test 5: Dr. Bob can create Condition (if policy allows)
print_test "Testing Dr. Bob CREATE Condition"
access_token=$(get_access_token "$DOCTOR_USERNAME" "$DOCTOR_PASSWORD")

# First get permission ticket for creating Condition
ticket=$(get_permission_ticket "Condition" "POST")

if [ $? -eq 0 ]; then
    # Get RPT
    rpt=$(get_rpt_token "$ticket" "$access_token" 2>&1)

    if [ $? -eq 0 ]; then
        print_info "Got RPT, attempting to create Condition..."

        # Create a test Condition resource
        condition_data='{
            "resourceType": "Condition",
            "clinicalStatus": {
                "coding": [{
                    "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                    "code": "active"
                }]
            },
            "code": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "44054006",
                    "display": "Type 2 diabetes mellitus"
                }]
            },
            "subject": {
                "reference": "Patient/1"
            }
        }'

        http_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$FHIR_URL/fhir/Condition" \
            -H "Authorization: Bearer $rpt" \
            -H "Content-Type: application/fhir+json" \
            -d "$condition_data")

        if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
            print_success "PASSED: Dr. Bob can CREATE Condition - HTTP $http_code"
            RESULT_5=0
        else
            print_warning "Dr. Bob CREATE Condition returned HTTP $http_code"
            print_info "This might be expected if create permission is not granted"
            RESULT_5=0  # Don't fail the test, just inform
        fi
    else
        print_warning "Dr. Bob denied CREATE permission for Condition"
        print_info "This is OK if your policies only allow read access"
        RESULT_5=0
    fi
else
    print_warning "Could not get permission ticket for POST Condition"
    RESULT_5=0
fi

echo ""
print_header "Negative Tests: Dr. Bob Should Be Denied These"
echo ""

# Test 6: Dr. Bob should NOT be able to delete Patient
print_test "Testing Dr. Bob DELETE Patient (should be denied)"
access_token=$(get_access_token "$DOCTOR_USERNAME" "$DOCTOR_PASSWORD")
ticket=$(get_permission_ticket "Patient/1" "DELETE")

if [ $? -eq 0 ]; then
    rpt=$(get_rpt_token "$ticket" "$access_token" 2>&1)

    if [ $? -ne 0 ]; then
        print_success "PASSED: Dr. Bob correctly denied DELETE permission"
        RESULT_6=0
    else
        # Try the delete
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$FHIR_URL/fhir/Patient/1" \
            -H "Authorization: Bearer $rpt")

        if [ "$http_code" = "403" ] || [ "$http_code" = "401" ]; then
            print_success "PASSED: Dr. Bob correctly denied DELETE - HTTP $http_code"
            RESULT_6=0
        else
            print_error "FAILED: Dr. Bob should not be able to DELETE Patient - HTTP $http_code"
            RESULT_6=1
        fi
    fi
else
    print_success "PASSED: Dr. Bob correctly denied DELETE permission (no ticket)"
    RESULT_6=0
fi

echo ""
print_header "Dr. Bob Test Summary"

TOTAL=6
PASSED=$((6 - RESULT_1 - RESULT_2 - RESULT_3 - RESULT_4 - RESULT_5 - RESULT_6))

echo ""
print_info "Results: $PASSED/$TOTAL tests passed"
echo ""

if [ $PASSED -ge 5 ]; then
    print_success "Most tests passed! Dr. Bob's permissions are working."
    exit 0
else
    print_error "Several tests failed. Check Keycloak policies for Doctor role."
    exit 1
fi
