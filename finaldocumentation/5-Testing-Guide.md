# 5. Testing Guide

**Comprehensive testing guide for the UMA 2.0 Protected FHIR Server**

---

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Automated Test Suite](#automated-test-suite)
3. [Manual Testing](#manual-testing)
4. [Demo Scenarios](#demo-scenarios)
5. [Test Results](#test-results)
6. [Troubleshooting Test Failures](#troubleshooting-test-failures)

---

## Testing Overview

The project includes comprehensive testing at multiple levels:

1. **Automated Tests**: Bash scripts covering 20 test scenarios
2. **Manual Testing**: cURL commands for interactive testing
3. **Demo Scenarios**: Pre-configured workflows for Alice, Bob, and Jan

**Test Coverage**:
- Anonymous access (4 tests)
- Patient role (Alice) (5 tests)
- Doctor role (Dr. Bob) (6 tests)
- Administrator (Jan) (5 tests)
- **Total**: 20/20 tests passing ✅

---

## Automated Test Suite

### Test Scripts Location

```
scripts/
├── 00-config.sh              # Configuration and test data
├── 01-helper-functions.sh    # Reusable functions
├── 02-test-anonymous.sh      # Anonymous access tests
├── 03-test-alice-patient.sh  # Patient role tests
├── 04-test-doctor-bob.sh      # Doctor role tests
├── 05-test-admin-jan.sh        # Administrator tests
└── 06-test-all.sh              # Master test runner
```

### Running All Tests

```bash
cd scripts
chmod +x *.sh
./06-test-all.sh
```

**Expected Output**:
```
========================================
Complete Test Suite Results
========================================

Test scripts passed: 5/5

✓ All tests passed!
✓ Sprint 3 RBAC implementation is working correctly!

Test Categories:
- Anonymous Access: 4/4 tests passed
- Patient (Alice): 5/5 tests passed
- Doctor (Dr. Bob): 6/6 tests passed
- Administrator (Jan): 5/5 tests passed
TOTAL: 20/20 tests passed (100%)
```

---

**Last Updated**: January 2026
