# UMA Authorization Demo Commands

## 1. Setup - Get Tokens

```bash
# Alice (Patient) token
ALICE_TOKEN=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "username=alice&password=alice123&grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" | jq -r '.access_token')
echo "ALICE_TOKEN: $ALICE_TOKEN"

# Dr. Smith (has Patient/552 access) token
TOKEN_SMITH=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "username=dr.smith&password=smith123&grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" | jq -r '.access_token')
echo "TOKEN_SMITH: $TOKEN_SMITH"

# Dr. Bob (only has Condition/554 access) token
TOKEN_BOB=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "username=dr.bob&password=bob123&grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" | jq -r '.access_token')
echo "TOKEN_BOB: $TOKEN_BOB"
```

---

## 2. Owner Access - Alice Accessing Her Own Data

### Full UMA Flow
```bash
# Step 1: Request resource (get ticket)
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Patient/552 -H "Authorization: Bearer $ALICE_TOKEN")
echo "RESPONSE Headers:"
echo "$RESPONSE" | head -20
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')
echo "TICKET: $TICKET"

# Step 2: Exchange ticket for RPT
RPT=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$ALICE_TOKEN" | jq -r '.access_token')
echo "RPT: $RPT"

# Step 3: Access with RPT
curl -s http://localhost:8081/fhir/Patient/552 -H "Authorization: Bearer $RPT" | jq
```

### Alice's $everything (all her data)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Patient/552/\$everything -H "Authorization: Bearer $ALICE_TOKEN")
echo "RESPONSE Headers:"
echo "$RESPONSE" | head -20
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')
echo "TICKET: $TICKET"

RPT=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$ALICE_TOKEN" | jq -r '.access_token')
echo "RPT: $RPT"

curl -s http://localhost:8081/fhir/Patient/552/\$everything -H "Authorization: Bearer $RPT" | jq
```

---

## 3. Delegated Access - Dr. Smith (Has Patient/552 Permission)

### Dr. Smith's $everything (works - has Patient access)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Patient/552/\$everything -H "Authorization: Bearer $TOKEN_SMITH")
echo "RESPONSE Headers:"
echo "$RESPONSE" | head -20
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')
echo "TICKET: $TICKET"

RPT_SMITH=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_SMITH" | jq -r '.access_token')
echo "RPT_SMITH: $RPT_SMITH"

curl -s http://localhost:8081/fhir/Patient/552/\$everything -H "Authorization: Bearer $RPT_SMITH" | jq
```

---

## 4. Access Denied - Dr. Bob (Only Has Condition/554 Access)

### Bob tries $everything (DENIED - no Patient access)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Patient/552/\$everything -H "Authorization: Bearer $TOKEN_BOB")
echo "RESPONSE Headers:"
echo "$RESPONSE" | head -20
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')
echo "TICKET: $TICKET"

# This will return access_denied!
echo "Attempting RPT exchange (should fail):"
curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_BOB" | jq
```

### Bob accesses Condition/554 directly (works - has explicit permission)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Condition/554 -H "Authorization: Bearer $TOKEN_BOB")
echo "RESPONSE Headers:"
echo "$RESPONSE" | head -20
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')
echo "TICKET: $TICKET"

RPT_BOB=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_BOB" | jq -r '.access_token')
echo "RPT_BOB: $RPT_BOB"

curl -s http://localhost:8081/fhir/Condition/554 -H "Authorization: Bearer $RPT_BOB" | jq
```

---

## 5. Duplicate Prevention - Only One Patient Per Keycloak User

```bash
# Try to create duplicate Patient for Alice (FAILS)
curl -s -X POST http://localhost:8081/fhir/Patient \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/fhir+json" \
  -d '{"resourceType":"Patient","identifier":[{"system":"keycloak-uuid","value":"5441cea9-fcf2-419e-bc20-948c3c283c98"}],"name":[{"family":"Duplicate","given":["Alice"]}]}' | jq
```

---

## 6. Doctor Creates Patient for New Person (No Keycloak Account)

```bash
curl -s -X POST http://localhost:8081/fhir/Patient \
  -H "Authorization: Bearer $TOKEN_SMITH" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "identifier": [
      {
        "system": "http://hl7.org/fhir/sid/us-ssn",
        "value": "123-45-6789"
      }
    ],
    "name": [{"family": "NewPatient", "given": ["Test"]}],
    "gender": "male",
    "birthDate": "1990-01-01"
  }' | jq
```

---

## 7. Create Clinical Resources

### Create AllergyIntolerance for Alice
```bash
curl -s -X POST http://localhost:8081/fhir/AllergyIntolerance \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "AllergyIntolerance",
    "patient": {"reference": "Patient/552"},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical", "code": "active"}]},
    "verificationStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification", "code": "confirmed"}]},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "91935009", "display": "Allergy to peanuts"}]}
  }' | jq
```

### Create Condition for Alice
```bash
curl -s -X POST http://localhost:8081/fhir/Condition \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/552"},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]},
    "verificationStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-ver-status", "code": "confirmed"}]},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "73211009", "display": "Diabetes mellitus"}]}
  }' | jq
```

---

## Quick Reference - Resource IDs

| Resource | ID | Owner |
|----------|-----|-------|
| Alice's Patient | 552 | Alice |
| Peanut Allergy | 553 | Alice |
| Diabetes Condition | 554 | Alice |
| Penicillin Allergy | 555 | Alice |
| Michael Johnson | 602 | Dr. Smith |
