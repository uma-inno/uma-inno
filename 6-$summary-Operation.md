# $summary Operation (Not Implemented)

## Overview

The `$summary` operation generates an **International Patient Summary (IPS)** - a standardized FHIR document containing a patient's essential healthcare information.

**Status:** Not implemented (IPS is disabled in `application.yaml`)

---

## How It Would Work

### Endpoint
```
GET /fhir/Patient/[id]/$summary
```

### Request Example
```http
GET /fhir/Patient/123/$summary
Authorization: Bearer <token>
```

### Response
Returns a FHIR **Bundle** of type `document` containing:

| Section | FHIR Resource | Description |
|---------|---------------|-------------|
| Patient | Patient | Demographics |
| Allergies | AllergyIntolerance | Known allergies |
| Medications | MedicationStatement | Current medications |
| Problems | Condition | Active medical conditions |

### Response Example (Simplified)
```json
{
  "resourceType": "Bundle",
  "type": "document",
  "entry": [
    {
      "resource": {
        "resourceType": "Composition",
        "title": "Patient Summary",
        "section": [
          { "title": "Allergies", "entry": [...] },
          { "title": "Medications", "entry": [...] },
          { "title": "Problems", "entry": [...] }
        ]
      }
    },
    { "resource": { "resourceType": "Patient", ... } },
    { "resource": { "resourceType": "AllergyIntolerance", ... } },
    { "resource": { "resourceType": "MedicationStatement", ... } },
    { "resource": { "resourceType": "Condition", ... } }
  ]
}
```

---

## UMA-Aware Behavior

The `$summary` operation should be **permission-filtered**: it only includes resources the requesting user has permission to access.

### Example Scenario

**Alice's data:**
- Patient/1 (owned by Alice)
- Condition/3 (diabetes)
- AllergyIntolerance/4 (penicillin)
- MedicationStatement/8 (insulin)

**Dr. Smith's permissions:**
- `read` on Patient/1 ✅
- `read` on Condition/3 ✅
- No permission on AllergyIntolerance/4 ❌
- No permission on MedicationStatement/8 ❌

### Expected Behavior

| Requester | `$summary` Result |
|-----------|-------------------|
| **Alice** (owner) | Full summary: Patient, Condition, Allergy, Medication |
| **Dr. Smith** | Partial summary: Patient, Condition only |
| **Dr. Bob** (no permissions) | Access denied (403) or empty summary |

### Implementation Approach

1. Intercept `$summary` request
2. Get all resources that would be included in the summary
3. For each resource, check if user has `read` permission in Keycloak
4. Filter out resources without permission
5. Return summary containing only permitted resources

This ensures patients maintain control over which parts of their medical record each provider can see.
