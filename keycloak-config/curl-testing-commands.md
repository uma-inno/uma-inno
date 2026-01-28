# UMA Authorization Demo Commands

## 1. Setup - Get Tokens

```bash
# Alice (Patient) token
ALICE_TOKEN=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "username=alice&password=alice123&grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" | jq -r '.access_token')
echo "ALICE_TOKEN set"

# Jan (Patient) token
JAN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "username=jan&password=jan123&grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" | jq -r '.access_token')
echo "JAN_TOKEN set"

# Dr. Smith (has read access to Alice's Patient/1 and Condition/3) token
TOKEN_SMITH=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "username=dr.smith&password=smith123&grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" | jq -r '.access_token')
echo "TOKEN_SMITH set"

# Dr. Bob (has read access to Alice's AllergyIntolerance/4 only) token
TOKEN_BOB=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "username=dr.bob&password=bob123&grant_type=password&client_id=fhir-client&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" | jq -r '.access_token')
echo "TOKEN_BOB set"
```

---

## 2. Owner Access - Alice Accessing Her Own Data

### Full UMA Flow for Patient/1
```bash
# Step 1: Request resource (get ticket)
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Patient/1 -H "Authorization: Bearer $ALICE_TOKEN")
echo "Response headers:"
echo "$RESPONSE" | head -10
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')
echo "TICKET: ${TICKET:0:50}..."

# Step 2: Exchange ticket for RPT
RPT=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$ALICE_TOKEN" | jq -r '.access_token')
echo "RPT: ${RPT:0:50}..."

# Step 3: Access with RPT
curl -s http://localhost:8081/fhir/Patient/1 -H "Authorization: Bearer $RPT" | jq
```

### Alice accesses her Condition/3 (Diabetes)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Condition/3 -H "Authorization: Bearer $ALICE_TOKEN")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

RPT=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$ALICE_TOKEN" | jq -r '.access_token')

curl -s http://localhost:8081/fhir/Condition/3 -H "Authorization: Bearer $RPT" | jq
```

### Alice accesses her AllergyIntolerance/4 (Peanuts)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/AllergyIntolerance/4 -H "Authorization: Bearer $ALICE_TOKEN")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

RPT=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$ALICE_TOKEN" | jq -r '.access_token')

curl -s http://localhost:8081/fhir/AllergyIntolerance/4 -H "Authorization: Bearer $RPT" | jq
```

---

## 3. Owner Access - Jan Accessing His Own Data

### Jan accesses his Patient/2
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Patient/2 -H "Authorization: Bearer $JAN_TOKEN")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

RPT=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$JAN_TOKEN" | jq -r '.access_token')

curl -s http://localhost:8081/fhir/Patient/2 -H "Authorization: Bearer $RPT" | jq
```

### Jan accesses his Condition/5 (Asthma)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Condition/5 -H "Authorization: Bearer $JAN_TOKEN")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

RPT=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$JAN_TOKEN" | jq -r '.access_token')

curl -s http://localhost:8081/fhir/Condition/5 -H "Authorization: Bearer $RPT" | jq
```

---

## 4. Delegated Access - Dr. Smith (Has Permission for Alice's Resources)

### Dr. Smith reads Alice's Patient/1 (works - has explicit permission)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Patient/1 -H "Authorization: Bearer $TOKEN_SMITH")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

RPT_SMITH=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_SMITH" | jq -r '.access_token')

curl -s http://localhost:8081/fhir/Patient/1 -H "Authorization: Bearer $RPT_SMITH" | jq
```

### Dr. Smith reads Alice's Condition/3 (works - has explicit permission)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Condition/3 -H "Authorization: Bearer $TOKEN_SMITH")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

RPT_SMITH=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_SMITH" | jq -r '.access_token')

curl -s http://localhost:8081/fhir/Condition/3 -H "Authorization: Bearer $RPT_SMITH" | jq
```

---

## 5. Delegated Access - Dr. Bob (Has Permission for Alice's AllergyIntolerance Only)

### Dr. Bob reads Alice's AllergyIntolerance/4 (works - has explicit permission)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/AllergyIntolerance/4 -H "Authorization: Bearer $TOKEN_BOB")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

RPT_BOB=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_BOB" | jq -r '.access_token')

curl -s http://localhost:8081/fhir/AllergyIntolerance/4 -H "Authorization: Bearer $RPT_BOB" | jq
```

---

## 6. Access Denied - Testing Permission Boundaries

### Dr. Bob tries Alice's Patient/1 (DENIED - no Patient access)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Patient/1 -H "Authorization: Bearer $TOKEN_BOB")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

# This should return access_denied
echo "Attempting RPT exchange (should fail):"
curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_BOB" | jq
```

### Dr. Smith tries Jan's Patient/2 (DENIED - no permission on Jan's data)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Patient/2 -H "Authorization: Bearer $TOKEN_SMITH")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

# This should return access_denied
echo "Attempting RPT exchange (should fail):"
curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_SMITH" | jq
```

### Alice tries Jan's Condition/5 (DENIED - not her data)
```bash
RESPONSE=$(curl -s -i http://localhost:8081/fhir/Condition/5 -H "Authorization: Bearer $ALICE_TOKEN")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

# This should return access_denied
echo "Attempting RPT exchange (should fail):"
curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$ALICE_TOKEN" | jq
```

---

## 7. Patient $everything Operation

### Alice runs $everything on her own Patient/1 (works - owner)
```bash
RESPONSE=$(curl -s -i "http://localhost:8081/fhir/Patient/1/\$everything" -H "Authorization: Bearer $ALICE_TOKEN")
echo "Response headers:"
echo "$RESPONSE" | head -10
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')
echo "TICKET: ${TICKET:0:50}..."

RPT=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$ALICE_TOKEN" | jq -r '.access_token')
echo "RPT: ${RPT:0:50}..."

curl -s "http://localhost:8081/fhir/Patient/1/\$everything" -H "Authorization: Bearer $RPT" | jq
```

### Dr. Smith runs $everything on Alice's Patient/1 (works - has Patient/1 permission)
```bash
RESPONSE=$(curl -s -i "http://localhost:8081/fhir/Patient/1/\$everything" -H "Authorization: Bearer $TOKEN_SMITH")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

RPT_SMITH=$(curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_SMITH" | jq -r '.access_token')

curl -s "http://localhost:8081/fhir/Patient/1/\$everything" -H "Authorization: Bearer $RPT_SMITH" | jq
```

### Dr. Bob runs $everything on Alice's Patient/1 (DENIED - no Patient permission)
```bash
RESPONSE=$(curl -s -i "http://localhost:8081/fhir/Patient/1/\$everything" -H "Authorization: Bearer $TOKEN_BOB")
TICKET=$(echo "$RESPONSE" | grep -i "WWW-Authenticate" | sed -n 's/.*ticket="\([^"]*\)".*/\1/p')

# This should return access_denied - Dr. Bob only has AllergyIntolerance/4 permission
echo "Attempting RPT exchange (should fail):"
curl -s -X POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:uma-ticket" \
  -d "client_id=fhir-client" \
  -d "client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP" \
  -d "ticket=$TICKET" \
  -d "subject_token=$TOKEN_BOB" | jq
```

---

## Quick Reference - Resource IDs

| Resource | ID | Owner | Who Has Access |
|----------|-----|-------|----------------|
| Patient | 1 | alice | alice (owner), dr.smith (read) |
| Patient | 2 | jan | jan (owner) |
| Condition | 3 | alice | alice (owner), dr.smith (read) |
| AllergyIntolerance | 4 | alice | alice (owner), dr.bob (read) |
| Condition | 5 | jan | jan (owner) |
| AllergyIntolerance | 6 | jan | jan (owner) |
| MedicationStatement | 8 | alice | alice (owner) |

## Test Scenarios Summary

| Scenario | User | Resource | Expected Result |
|----------|------|----------|-----------------|
| Owner access | alice | Patient/1 | SUCCESS |
| Owner access | alice | Condition/3 | SUCCESS |
| Owner access | jan | Patient/2 | SUCCESS |
| Owner access | jan | Condition/5 | SUCCESS |
| Delegated read | dr.smith | Patient/1 | SUCCESS |
| Delegated read | dr.smith | Condition/3 | SUCCESS |
| Delegated read | dr.bob | AllergyIntolerance/4 | SUCCESS |
| No permission | dr.bob | Patient/1 | DENIED |
| No permission | dr.smith | Patient/2 | DENIED |
| No permission | alice | Condition/5 | DENIED |
