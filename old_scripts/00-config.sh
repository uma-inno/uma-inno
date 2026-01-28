#!/bin/bash
# Configuration file for UMA RBAC testing
# Source this file in other scripts: source ./scripts/00-config.sh

# Server URLs
export KEYCLOAK_URL="http://localhost:8080"
export FHIR_URL="http://localhost:8081"
export REALM="FHIR-Auth"

# Client credentials
export CLIENT_ID="fhir-client"
export CLIENT_SECRET="QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP"

# Test users
export ALICE_USERNAME="alice"
export ALICE_PASSWORD="alice123"
export DOCTOR_USERNAME="dr.bob"
export DOCTOR_PASSWORD="bob123"
export ADMIN_USERNAME="jan"
export ADMIN_PASSWORD="jan123"

# FHIR Resources to test
export RESOURCES=("Patient" "AllergyIntolerance" "Condition" "MedicationStatement")

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Helper function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${CYAN}TEST: $1${NC}"
}
