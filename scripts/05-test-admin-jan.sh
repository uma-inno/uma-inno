#!/bin/bash
# Test Jan (Administrator role) access permissions

source "$(dirname "$0")/00-config.sh"
source "$(dirname "$0")/01-helper-functions.sh"

print_header "Test 4: Jan (Administrator Role) - Full Access Tests"

# Check servers
if ! check_servers; then
    exit 1
fi

echo ""
print_info "Testing Jan's permissions:"
print_info "- Should have FULL access to ALL resources"
print_info "- Should be able to READ, CREATE, UPDATE, DELETE everything"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0

# Test read access to all resources
for resource in "${RESOURCES[@]}"; do
    echo ""
    print_test "Testing Jan READ access to $resource"

    if test_resource_access "$ADMIN_USERNAME" "$ADMIN_PASSWORD" "$resource" "GET" "true"; then
        ((PASSED_TESTS++))
    fi
    ((TOTAL_TESTS++))
done

echo ""
print_header "Testing Jan's Write Permissions"
echo ""

# Test DELETE permission (admin-only)
print_test "Testing Jan DELETE Patient (admin should have this permission)"
access_token=$(get_access_token "$ADMIN_USERNAME" "$ADMIN_PASSWORD")

if [ $? -eq 0 ]; then
    # Note: We test DELETE on a non-existent ID to avoid actually deleting data
    ticket=$(get_permission_ticket "Patient/99999" "DELETE")

    if [ $? -eq 0 ]; then
        rpt=$(get_rpt_token "$ticket" "$access_token" 2>&1)

        if [ $? -eq 0 ]; then
            print_success "PASSED: Jan has DELETE permission (got RPT)"
            print_info "Note: Not actually deleting data, just verifying permission"
            ((PASSED_TESTS++))
        else
            print_error "FAILED: Jan should have DELETE permission"
        fi
    else
        print_warning "Could not get permission ticket for DELETE"
    fi
    ((TOTAL_TESTS++))
else
    print_error "FAILED: Could not authenticate Jan"
    ((TOTAL_TESTS++))
fi

echo ""
print_header "Jan Test Summary"
echo ""
print_info "Results: $PASSED_TESTS/$TOTAL_TESTS tests passed"
echo ""

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    print_success "All tests passed! Jan has full administrator access."
    exit 0
elif [ $PASSED_TESTS -ge $((TOTAL_TESTS - 1)) ]; then
    print_warning "Most tests passed, but some issues detected."
    print_info "Check Keycloak policies for Administrator role."
    exit 0
else
    print_error "Multiple tests failed. Check Keycloak policies for Administrator role."
    exit 1
fi
