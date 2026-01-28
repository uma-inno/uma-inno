#!/bin/bash
# Helper functions for UMA RBAC testing
# Source this file: source ./scripts/01-helper-functions.sh

# Source configuration
source "$(dirname "$0")/00-config.sh"

# Function to get access token using password grant
get_access_token() {
    local username=$1
    local password=$2

    local response=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=password" \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET" \
        -d "username=$username" \
        -d "password=$password")

    local token=$(echo $response | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

    if [ -z "$token" ]; then
        print_error "Failed to get access token for $username"
        echo "Response: $response" >&2
        return 1
    fi

    echo "$token"
    return 0
}

# Function to get permission ticket from FHIR server
get_permission_ticket() {
    local resource=$1
    local method=${2:-GET}

    # Make request and capture headers
    local temp_file=$(mktemp)
    curl -s -X $method "$FHIR_URL/fhir/$resource" \
        -D "$temp_file" \
        -o /dev/null 2>&1

    # Extract permission ticket from WWW-Authenticate header
    local ticket=$(grep -i "WWW-Authenticate" "$temp_file" | grep -o 'ticket="[^"]*' | cut -d'"' -f2)

    rm -f "$temp_file"

    if [ -z "$ticket" ]; then
        print_error "No permission ticket received for $resource"
        return 1
    fi

    echo "$ticket"
    return 0
}

# Function to exchange permission ticket for RPT
get_rpt_token() {
    local ticket=$1
    local claim_token=$2

    # Try with subject_token (instead of claim_token format)
    if [ ! -z "$claim_token" ]; then
        local response=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
            -d "ticket=$ticket" \
            -d "client_id=$CLIENT_ID" \
            -d "client_secret=$CLIENT_SECRET" \
            -d "subject_token=$claim_token")
    else
        # Try without token
        local response=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
            -d "ticket=$ticket" \
            -d "client_id=$CLIENT_ID" \
            -d "client_secret=$CLIENT_SECRET")
    fi

    local rpt=$(echo $response | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

    if [ -z "$rpt" ]; then
        # Check for error
        local error=$(echo $response | grep -o '"error":"[^"]*' | cut -d'"' -f4)
        if [ ! -z "$error" ]; then
            print_error "Failed to get RPT: $error"
            echo $response >&2
        fi
        return 1
    fi

    echo "$rpt"
    return 0
}

# Function to test access to a FHIR resource
test_resource_access() {
    local username=$1
    local password=$2
    local resource=$3
    local method=${4:-GET}
    local should_succeed=${5:-true}

    print_test "Testing $username access to $resource ($method)"

    # Step 1: Get access token
    local access_token=$(get_access_token "$username" "$password")
    if [ $? -ne 0 ]; then
        print_error "Could not authenticate $username"
        return 1
    fi
    print_info "Got access token for $username"

    # Step 2: Get permission ticket
    local ticket=$(get_permission_ticket "$resource" "$method")
    if [ $? -ne 0 ]; then
        print_error "Could not get permission ticket"
        return 1
    fi
    print_info "Got permission ticket"

    # Step 3: Exchange for RPT
    local rpt=$(get_rpt_token "$ticket" "$access_token")
    if [ $? -ne 0 ]; then
        if [ "$should_succeed" = "true" ]; then
            print_error "FAILED: $username should have access to $resource but was denied"
            return 1
        else
            print_success "PASSED: $username correctly denied access to $resource ($method)"
            return 0
        fi
    fi
    print_info "Got RPT token"

    # Step 4: Try to access resource with RPT
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" -X $method "$FHIR_URL/fhir/$resource" \
        -H "Authorization: Bearer $rpt" \
        -H "Content-Type: application/fhir+json")

    if [ "$response_code" = "200" ] || [ "$response_code" = "201" ]; then
        if [ "$should_succeed" = "true" ]; then
            print_success "PASSED: $username can access $resource ($method) - HTTP $response_code"
            return 0
        else
            print_error "FAILED: $username should NOT have access to $resource ($method) but succeeded - HTTP $response_code"
            return 1
        fi
    else
        if [ "$should_succeed" = "true" ]; then
            print_error "FAILED: $username should have access to $resource but got HTTP $response_code"
            return 1
        else
            print_success "PASSED: $username correctly denied access to $resource ($method) - HTTP $response_code"
            return 0
        fi
    fi
}

# Function to test UMA flow (permission ticket → RPT → access)
test_uma_flow() {
    local username=$1
    local password=$2
    local resource=$3

    print_header "Testing Complete UMA Flow: $username → $resource"

    # Step 1: Get access token
    print_info "Step 1: Getting access token for $username..."
    local access_token=$(get_access_token "$username" "$password")
    if [ $? -ne 0 ]; then
        print_error "Authentication failed"
        return 1
    fi
    print_success "Got access token (${access_token:0:30}...)"

    # Step 2: Get permission ticket
    print_info "Step 2: Requesting permission ticket for $resource..."
    local ticket=$(get_permission_ticket "$resource")
    if [ $? -ne 0 ]; then
        print_error "Failed to get permission ticket"
        return 1
    fi
    print_success "Got permission ticket (${ticket:0:30}...)"

    # Step 3: Exchange for RPT
    print_info "Step 3: Exchanging ticket for RPT..."
    local rpt=$(get_rpt_token "$ticket" "$access_token")
    if [ $? -ne 0 ]; then
        print_error "Failed to get RPT (access denied by policy)"
        return 1
    fi
    print_success "Got RPT token (${rpt:0:30}...)"

    # Step 4: Access resource with RPT
    print_info "Step 4: Accessing $resource with RPT..."
    local response=$(curl -s -X GET "$FHIR_URL/fhir/$resource" \
        -H "Authorization: Bearer $rpt" \
        -w "\nHTTP_CODE:%{http_code}")

    local http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d':' -f2)
    local body=$(echo "$response" | sed '/HTTP_CODE/d')

    if [ "$http_code" = "200" ]; then
        print_success "Access granted - HTTP 200 OK"

        # Try to parse and display resource count
        local count=$(echo "$body" | grep -o '"total":[0-9]*' | cut -d':' -f2)
        if [ ! -z "$count" ]; then
            print_info "Found $count $resource resource(s)"
        fi

        return 0
    else
        print_error "Access denied - HTTP $http_code"
        return 1
    fi
}

# Function to create test data
create_test_resource() {
    local resource_type=$1
    local data=$2
    local access_token=$3

    local response=$(curl -s -X POST "$FHIR_URL/fhir/$resource_type" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/fhir+json" \
        -d "$data" \
        -w "\nHTTP_CODE:%{http_code}")

    local http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d':' -f2)

    echo "$http_code"
}

# Function to check if servers are running
check_servers() {
    print_info "Checking if servers are running..."

    # Check FHIR server
    if ! curl -s -f "$FHIR_URL/fhir/metadata" > /dev/null; then
        print_error "FHIR server is not running at $FHIR_URL"
        print_info "Start it with: cd hapi-jpa && mvn spring-boot:run"
        return 1
    fi
    print_success "FHIR server is running"

    # Check Keycloak
    if ! curl -s -f "$KEYCLOAK_URL/realms/$REALM" > /dev/null; then
        print_error "Keycloak is not running at $KEYCLOAK_URL"
        print_info "Start it with Docker or your Keycloak installation"
        return 1
    fi
    print_success "Keycloak is running"

    return 0
}

# Export functions
export -f get_access_token
export -f get_permission_ticket
export -f get_rpt_token
export -f test_resource_access
export -f test_uma_flow
export -f create_test_resource
export -f check_servers
