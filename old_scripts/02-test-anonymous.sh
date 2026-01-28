#!/bin/bash
# Test anonymous access (should always get permission ticket)

source "$(dirname "$0")/00-config.sh"
source "$(dirname "$0")/01-helper-functions.sh"

print_header "Test 1: Anonymous Access (No Token)"

print_test "Attempting to access FHIR resources without authentication"

for resource in "${RESOURCES[@]}"; do
    echo ""
    print_info "Testing anonymous access to $resource..."

    # Try to access without any token
    temp_file=$(mktemp)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -D "$temp_file" \
        "$FHIR_URL/fhir/$resource")

    # Check for 401 Unauthorized
    if [ "$http_code" = "401" ]; then
        # Check for WWW-Authenticate header
        if grep -q "WWW-Authenticate.*UMA" "$temp_file"; then
            ticket=$(grep "WWW-Authenticate" "$temp_file" | grep -o 'ticket="[^"]*' | cut -d'"' -f2)

            if [ ! -z "$ticket" ]; then
                print_success "PASSED: Got 401 with UMA permission ticket"
                print_info "Ticket preview: ${ticket:0:50}..."
            else
                print_warning "Got 401 but no permission ticket found"
            fi
        else
            print_warning "Got 401 but no UMA WWW-Authenticate header"
        fi
    else
        print_error "FAILED: Expected 401, got HTTP $http_code"
        print_warning "Resources might not be protected by UMA!"
    fi

    rm -f "$temp_file"
done

echo ""
print_header "Anonymous Access Test Complete"
