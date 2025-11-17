#!/bin/bash
# Master test script - runs all RBAC tests

source "$(dirname "$0")/00-config.sh"
source "$(dirname "$0")/01-helper-functions.sh"

print_header "Sprint 3: Complete RBAC Test Suite"

echo ""
print_info "This script will test all user roles and permissions"
print_info "Tests will validate the UMA + RBAC configuration"
echo ""

# Check if servers are running
if ! check_servers; then
    print_error "Cannot proceed - servers not running"
    exit 1
fi

echo ""
print_info "Servers are ready. Starting tests..."
echo ""
read -p "Press Enter to continue..."

# Track results
TOTAL_SCRIPTS=5
PASSED_SCRIPTS=0

# Test 1: Anonymous access
echo ""
bash "$(dirname "$0")/02-test-anonymous.sh"
if [ $? -eq 0 ]; then ((PASSED_SCRIPTS++)); fi

echo ""
read -p "Press Enter to continue to Alice tests..."

# Test 2: Alice (Patient)
echo ""
bash "$(dirname "$0")/03-test-alice-patient.sh"
if [ $? -eq 0 ]; then ((PASSED_SCRIPTS++)); fi

echo ""
read -p "Press Enter to continue to Dr. Bob tests..."

# Test 3: Dr. Bob (Doctor)
echo ""
bash "$(dirname "$0")/04-test-doctor-bob.sh"
if [ $? -eq 0 ]; then ((PASSED_SCRIPTS++)); fi

echo ""
read -p "Press Enter to continue to Jan tests..."

# Test 4: Jan (Administrator)
echo ""
bash "$(dirname "$0")/05-test-admin-jan.sh"
if [ $? -eq 0 ]; then ((PASSED_SCRIPTS++)); fi

# Final summary
echo ""
print_header "Complete Test Suite Results"
echo ""
print_info "Test scripts passed: $PASSED_SCRIPTS/$TOTAL_SCRIPTS"
echo ""

if [ $PASSED_SCRIPTS -eq $TOTAL_SCRIPTS ]; then
    print_success "🎉 ALL TESTS PASSED!"
    print_success "Sprint 3 RBAC implementation is working correctly!"
    echo ""
    print_info "Next steps:"
    print_info "1. Take screenshots of test results for project diary"
    print_info "2. Export Keycloak configuration (Realm settings → Export)"
    print_info "3. Document the policies in Sprint 3 report"
    print_info "4. Update project diary with Sprint 3 completion"
    exit 0
elif [ $PASSED_SCRIPTS -ge 3 ]; then
    print_warning "Most tests passed, but some issues detected"
    print_info "Review failed tests and adjust Keycloak policies"
    exit 0
else
    print_error "Multiple test failures detected"
    print_info "Recommendations:"
    print_info "1. Check Keycloak policies are correctly configured"
    print_info "2. Verify all resources are registered in Keycloak"
    print_info "3. Ensure users have correct role assignments"
    print_info "4. Check FHIR server logs for errors"
    exit 1
fi
