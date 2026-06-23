# $summary Operation

## Overview

The `$summary` operation generates an **International Patient Summary (IPS)** — a standardized
FHIR `document` Bundle containing a patient's essential healthcare information.

**Status:** Implemented in `providers/PatientSummaryProvider.java` (registered via
`hapi.fhir.custom-provider-classes`). It is a custom provider and does not depend on HAPI's
built-in IPS module.

---

## How It Works

### Endpoint
```
GET /fhir/Patient/[id]/$summary
```

### Request Example
```http
GET /fhir/Patient/1/$summary
Authorization: Bearer <RPT>
```

Access is gated by the UMA interceptor: the RPT must carry at least one read scope for the target
patient (`patient/Patient.r`, `patient/Condition.r`, `patient/MedicationStatement.r` or
`patient/AllergyIntolerance.r`).

### Response
A FHIR `Bundle` of type `document` containing a `Composition` (LOINC `60591-5`, "Patient summary
Document"), the `Patient`, and the permitted clinical resources grouped into sections:

| Section | LOINC | FHIR Resource |
|---------|-------|---------------|
| Problems | `11450-4` | Condition |
| Allergies and Intolerances | `48765-2` | AllergyIntolerance |
| Medication Summary | `10160-0` | MedicationStatement |

### Response Example (simplified)
```json
{
  "resourceType": "Bundle",
  "type": "document",
  "entry": [
    {
      "resource": {
        "resourceType": "Composition",
        "type": { "coding": [{ "system": "http://loinc.org", "code": "60591-5" }] },
        "title": "International Patient Summary",
        "section": [
          { "title": "Problems", "entry": [...] },
          { "title": "Medication Summary", "entry": [...] }
        ]
      }
    },
    { "resource": { "resourceType": "Patient", ... } },
    { "resource": { "resourceType": "Condition", ... } },
    { "resource": { "resourceType": "MedicationStatement", ... } }
  ]
}
```

---

## UMA-Aware Behavior

The summary is **permission-filtered**, reusing the same enforcement stages as the interceptor:

- **Stage 2 (section scope):** a clinical section is included only if the RPT carries a read scope
  for that type (e.g. Problems needs `patient/Condition.r`/`.rs`). Sections without a scope are
  omitted entirely. The `Composition` and `Patient` are always present (the operation already
  required a read scope to be reached).
- **Stage 3 (granular categories):** if a scope carries a `?category=` filter, the section's search
  is narrowed to those categories.
- **Stage 4 (blacklist):** individual instances revoked by the patient are filtered out; a section
  left empty gets an `emptyReason` of `unavailable`.

### Example Scenario (demo data)

**Alice's data (Patient/1):** Conditions (Hypertension, Diabetes, Migraine), MedicationStatement
(Metformin), AllergyIntolerance (Penicillin). Doctor access is **patient-controlled** — the
results below assume alice has granted the respective scopes in the frontend.

| Requester | Scopes on Patient/1 | `$summary` result |
|-----------|---------------------|-------------------|
| **alice** (owner) | all 5 | Composition + Patient + Problems + Allergies + Medications |
| **dr.smith** | `patient/Patient.r` | Composition + Patient demographics only (no clinical sections) |
| **dr.bob** | `patient/Condition.rs` | Composition + Patient + Problems (Conditions) only |
| **dr.bob** (no grant) | _none_ | `403` (no read scope → ticket/RPT denied) |

This ensures patients keep control over which parts of their medical record each provider can see.

---

## Extending the Summary

`PatientSummaryProvider` keeps the sections in a `SECTIONS` table (`SectionSpec`: title, LOINC,
FHIR type). Further IPS sections (e.g. Immunizations `11369-6`, Results `30954-2`, Procedures
`47519-4`) can be added there once the corresponding resource types are UMA-protected and have
their own scopes.
