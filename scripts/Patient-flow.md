## Step 1: Get Alice Access Token

```
POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=password
&client_id=fhir-client
&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP
&username=alice
&password=alice123
```

response
```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI...", ->(identity Alice)
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI...",
  "token_type": "Bearer",
  "scope": "profile email"
}
```


## Step 2: Try to Access Patient Resource (Get Permission Ticket)

```
GET http://localhost:8081/fhir/Patient
(No Authorization header)
```

response
```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: UMA realm="FHIR-Auth",
                  as_uri="http://keycloak:8080/realms/FHIR-Auth",
                  ticket="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwZXJtaXNzaW9ucyI6W3sicnNpZCI6IjEyMzQ1IiwicnNuYW1lIjoiUGF0aWVudFJlc291cmNlIiwic2NvcGVzIjpbInJlYWQiXX1dLCJpYXQiOjE2OTg3NTQzMjEsImV4cCI6MTY5ODc1NDYyMX0.abc123xyz"
Content-Type: application/json

{
  "error": "unauthorized",
  "message": "No authorization token provided"
}
```
-> Permission ticket (in the WWW-Authenticate header)


## Step 3: Exchange Permission Ticket + identity token(subject_token) for RPT

```
POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:uma-ticket
&ticket=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwZXJtaXNzaW9ucyI6W3sicnNpZCI6IjEyMzQ1IiwicnNuYW1lIjoiUGF0aWVudFJlc291cmNlIiwic2NvcGVzIjpbInJlYWQiXX1dLCJpYXQiOjE2OTg3NTQzMjEsImV4cCI6MTY5ODc1NDYyMX0.abc123xyz
&client_id=fhir-client
&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP
&subject_token=eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI... ->(identity Alice)
```

response
```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI4V...",
  "token_type": "Bearer",
  "expires_in": 300
}
```

inside RPT:
```
{
  "authorization": {
    "permissions": [
      {
        "rsid": "12345",
        "rsname": "PatientResource",
        "scopes": ["read"]
      }
    ]
  },
  "sub": "alice",
  "realm_access": {
    "roles": ["Patient"]
  }
}
```



## Step 4: Access Patient Resource with RPT

```
GET http://localhost:8081/fhir/Patient
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI4V...
```

response
```
HTTP/1.1 200 OK
Content-Type: application/fhir+json

{
  "resourceType": "Bundle",
  "type": "searchset",
  "total": 2,
  "entry": [
    {
      "resource": {
        "resourceType": "Patient",
        "id": "1",
        "name": [
          {
            "family": "Smith",
            "given": ["Alice"]
          }
        ],
        "gender": "female",
        "birthDate": "1990-05-15"
      }
    }
  ]
}
```

## Negative Test: (delete)

exchange ticket for delete permission:
```
POST http://localhost:8080/realms/FHIR-Auth/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:uma-ticket
&ticket=<permission_ticket_for_DELETE>
&client_id=fhir-client
&client_secret=QYYAosQ6jdouA5NaHp9f5nvE0gIXAIeP
&subject_token=<alice_access_token>
```

response
```
HTTP/1.1 403 Forbidden
Content-Type: application/json

{
  "error": "access_denied",
  "error_description": "not_authorized"
}
```