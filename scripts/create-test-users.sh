#!/bin/bash

# Get admin token
echo "Getting admin token..."
TOKEN=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "❌ Failed to get admin token!"
    exit 1
fi

echo "✅ Got admin token"

# Create alice
echo "Creating user: alice"
RESPONSE=$(curl -s -w "%{http_code}" -X POST http://localhost:8080/admin/realms/FHIR-Auth/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "firstName": "Alice",
    "lastName": "Anderson",
    "email": "alice@example.com",
    "emailVerified": true,
    "enabled": true,
    "credentials": [{
      "type": "password",
      "value": "alice123",
      "temporary": false
    }]
  }')

HTTP_CODE="${RESPONSE: -3}"
if [ "$HTTP_CODE" == "201" ] || [ "$HTTP_CODE" == "409" ]; then
    echo "✅ alice created/exists"
else
    echo "❌ Failed to create alice (HTTP $HTTP_CODE)"
fi

# Create dr.bob
echo "Creating user: dr.bob"
RESPONSE=$(curl -s -w "%{http_code}" -X POST http://localhost:8080/admin/realms/FHIR-Auth/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "dr.bob",
    "firstName": "Bob",
    "lastName": "Smith",
    "email": "dr.bob@example.com",
    "emailVerified": true,
    "enabled": true,
    "credentials": [{
      "type": "password",
      "value": "bob123",
      "temporary": false
    }]
  }')

HTTP_CODE="${RESPONSE: -3}"
if [ "$HTTP_CODE" == "201" ] || [ "$HTTP_CODE" == "409" ]; then
    echo "✅ dr.bob created/exists"
else
    echo "❌ Failed to create dr.bob (HTTP $HTTP_CODE)"
fi

# Create jan
echo "Creating user: jan"
RESPONSE=$(curl -s -w "%{http_code}" -X POST http://localhost:8080/admin/realms/FHIR-Auth/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "jan",
    "firstName": "Jan",
    "lastName": "Meyer",
    "email": "jan@example.com",
    "emailVerified": true,
    "enabled": true,
    "credentials": [{
      "type": "password",
      "value": "jan123",
      "temporary": false
    }]
  }')

HTTP_CODE="${RESPONSE: -3}"
if [ "$HTTP_CODE" == "201" ] || [ "$HTTP_CODE" == "409" ]; then
    echo "✅ jan created/exists"
else
    echo "❌ Failed to create jan (HTTP $HTTP_CODE)"
fi

# Create system-placeholder (DISABLED for Sprint 4!)
echo "Creating system-placeholder (disabled)"
RESPONSE=$(curl -s -w "%{http_code}" -X POST http://localhost:8080/admin/realms/FHIR-Auth/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "system-placeholder",
    "firstName": "System",
    "lastName": "Placeholder",
    "email": "system@hospital.org",
    "emailVerified": true,
    "enabled": false,
    "attributes": {
      "description": ["Placeholder owner for unregistered patients"]
    }
  }')

HTTP_CODE="${RESPONSE: -3}"
if [ "$HTTP_CODE" == "201" ] || [ "$HTTP_CODE" == "409" ]; then
    echo "✅ system-placeholder created/exists"
else
    echo "❌ Failed to create system-placeholder (HTTP $HTTP_CODE)"
fi

echo ""
echo "✅ All users created!"
echo ""
echo "Test with:"
echo "  alice / alice123 (Alice Anderson)"
echo "  dr.bob / bob123 (Bob Smith)"
echo "  jan / jan123 (Jan Meyer)"
