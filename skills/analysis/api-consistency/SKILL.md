---
name: api-consistency
description: Audit all REST endpoints for consistency — URL naming, HTTP methods, response structure, status codes, validation, and tenant handling
disable-model-invocation: true
allowed-tools: Read, Grep, Glob
---

# API Consistency Check

Analyse all REST endpoints for consistency in naming, response format, error handling, HTTP methods, and documentation.

## Analysis Process

### 1. Endpoint Inventory

Scan all `@RestController` classes and build a complete inventory:
- HTTP method
- URL path
- Request body type (if any)
- Response type
- HTTP status codes

### 2. URL Naming Consistency

- **Plural nouns**: `/invoices` not `/invoice`.
- **Consistent versioning**: All endpoints use `/api/v1/` prefix.
- **Kebab-case for multi-word resources**: `/payment-methods` not `/paymentMethods`.
- **Consistent nesting depth**: No deeper than two levels.
- **Action endpoints use POST**: Non-CRUD actions use `POST /resource/{id}/action`.
- **No verbs in resource URLs**: `/invoices` not `/getInvoices`.

### 3. HTTP Method Usage

- `GET` for reads (no side effects).
- `POST` for creates and actions.
- `PUT` for full updates.
- `PATCH` for partial updates.
- `DELETE` for deletions.
- No `GET` endpoints that mutate data.

### 4. Response Structure Consistency

- All single-entity responses use `{Entity}Response` DTO.
- All list endpoints return `PageResponse<T>` with consistent pagination metadata.
- All error responses follow the `ErrorResponse` structure.
- Response field naming is `camelCase` throughout.

### 5. HTTP Status Code Consistency

- `200` for reads and updates.
- `201` for creates.
- `204` for deletes.
- `400` for validation errors.
- `404` for not found.
- `422` for business rule violations.
- `500` for internal server errors.
- `502` for external server errors.

### 6. Input Validation Consistency

- All `@RequestBody` parameters annotated with `@Valid`.
- All request DTOs use Bean Validation annotations.
- Validation messages are human-readable and consistent in tone.
- Path variables and query parameters validated where appropriate.

### 7. Documentation

- No javadocs.

### 8. Authentication and Tenant Handling

- Every endpoint extracts tenant ID from JWT (not request params).
- Tenant extraction is consistent (same helper method or pattern).
- Endpoints that should be public are explicitly marked.

## Output Format

```
## API Consistency Report

**Overall Consistency:** [CONSISTENT | MOSTLY CONSISTENT | INCONSISTENT]

### Endpoint Inventory
| Method | Path | Controller | Status Codes |
|--------|------|-----------|-------------|
| GET | /api/v1/invoices | BillingController | 200 |
| POST | /api/v1/invoices | BillingController | 201 |

### Inconsistencies Found

#### URL Naming
- [Inconsistency and affected endpoints]

#### Response Structure
- [Inconsistency and affected endpoints]

#### Status Codes
- [Inconsistency and affected endpoints]

### Recommendations
1. [Most impactful consistency fix]
2. [Second priority]
```
