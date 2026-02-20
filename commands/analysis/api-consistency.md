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
- OpenAPI annotations present

### 2. URL Naming Consistency

Check all endpoint URLs for:
- **Plural nouns for resources**: `/invoices` not `/invoice`.
- **Consistent versioning**: All endpoints use `/api/v1/` prefix.
- **Kebab-case for multi-word resources**: `/payment-methods` not `/paymentMethods`.
- **Consistent nesting depth**: No deeper than two levels (`/customers/{id}/invoices`).
- **Action endpoints use POST**: Non-CRUD actions use `POST /resource/{id}/action`.
- **No verbs in resource URLs**: `/invoices` not `/getInvoices`.

### 3. HTTP Method Usage

Verify:
- `GET` for all reads (no side effects).
- `POST` for creates and actions.
- `PUT` for full updates.
- `PATCH` for partial updates (if used).
- `DELETE` for deletions.
- No `GET` endpoints that mutate data.

### 4. Response Structure Consistency

Check that:
- All single-entity responses use the same DTO pattern (`{Entity}Response`).
- All list endpoints return `PageResponse<T>` with consistent pagination metadata.
- All error responses follow the standard `ErrorResponse` structure.
- Response field naming is consistent across endpoints (camelCase throughout).

### 5. HTTP Status Code Consistency

Verify:
- `200` for successful reads and updates.
- `201` for successful creates (with `@ResponseStatus(HttpStatus.CREATED)`).
- `204` for successful deletes (with `@ResponseStatus(HttpStatus.NO_CONTENT)`).
- `400` for validation errors.
- `404` for not found.
- `422` for business rule violations.
- No inconsistent status codes for the same type of operation.

### 6. Input Validation Consistency

Check that:
- All `@RequestBody` parameters are annotated with `@Valid`.
- All request DTOs use Bean Validation annotations.
- Validation messages are human-readable and consistent in tone.
- Path variables and query parameters are validated where appropriate.

### 7. Documentation Completeness

Verify:
- Every controller has `@Tag` annotation.
- Every endpoint has `@Operation` with `summary`.
- Response types are documented with `@ApiResponse` annotations.
- Error responses are documented.

### 8. Authentication and Tenant Handling

Check that:
- Every endpoint extracts tenant ID from JWT (not request params).
- Tenant extraction is consistent (same helper method or pattern).
- Endpoints that should be public are explicitly marked.

## Output Format

```
## API Consistency Report

**Overall Consistency:** [CONSISTENT | MOSTLY CONSISTENT | INCONSISTENT]

### Endpoint Inventory
| Method | Path | Controller | Status Codes | Documented |
|--------|------|-----------|-------------|-----------|
| GET | /api/v1/invoices | BillingController | 200 | Yes |
| POST | /api/v1/invoices | BillingController | 201 | Yes |

### Inconsistencies Found

#### URL Naming
- [Inconsistency description and affected endpoints]

#### Response Structure
- [Inconsistency description and affected endpoints]

#### Status Codes
- [Inconsistency description and affected endpoints]

#### Missing Documentation
- [Endpoints missing @Operation or other annotations]

### Recommendations
1. [Most impactful consistency fix]
2. [Second priority]
```
