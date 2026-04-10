---
name: new-endpoint
description: Add a new REST endpoint to an existing Spring Boot feature — controller method, service method, DTOs, mapper updates, and tests
argument-hint: "[feature] [METHOD /api/v1/path] [purpose description]"
disable-model-invocation: true
allowed-tools: Read, Edit, Glob
---

# Add New Endpoint to Existing Feature

Add a new REST endpoint to an existing feature package with all supporting code.

## Required Input

Use `$ARGUMENTS` to determine:
- **Feature package**: Which existing feature this endpoint belongs to (e.g., `billing`)
- **HTTP method and path**: e.g., `POST /api/v1/invoices/{invoiceId}/send`
- **Purpose**: What this endpoint does (e.g., "Send an invoice to the customer via email")
- **Request body** (if applicable): Fields with types and validation rules
- **Response**: Expected response structure and HTTP status code

If anything is ambiguous, read the existing feature code first, then ask.

## Files to Create or Modify

### 1. Request DTO (new file, if endpoint accepts a body)

- Java record with Bean Validation annotations.
- Every annotation includes a `message` attribute.
- File name: `{ActionName}Request.java`.

### 2. Response DTO (new file, if response differs from existing DTOs)

- Java record with fields matching the API response.
- Reuse an existing response DTO if the shape matches.

### 3. Controller Method (modify existing controller)

- Add new method to the existing `{Feature}Controller.java`.
- Include `@Operation` OpenAPI annotation with summary.
- Use appropriate HTTP method annotation with full path.
- Extract tenant ID from `JwtAuthenticationToken`.
- Apply `@Valid` on request body if present.
- Return appropriate HTTP status code.

### 4. Service Method (modify existing service)

- Add new method to the existing `{Feature}Service.java`.
- Include `@Transactional` if the method mutates data.
- Implement business logic and validation.
- Log at INFO level with relevant entity IDs and tenant ID.
- Return Response DTO.

### 5. Mapper Methods (modify existing mapper, if new response DTO)

- Add static mapping method to the existing `{Feature}Mapper.java`.

### 6. Controller Test (modify existing test class)

- Add tests for the new endpoint:
  - Successful request with valid data.
  - Validation failure (if applicable).
  - Not found (if endpoint references an entity by ID).
  - Business rule violation (if applicable).

### 7. Service Test (modify existing test class)

- Add tests for the new service method:
  - Happy path.
  - Edge cases and error conditions.

## Output Format

Show the complete new files and the specific modifications to existing files. For modifications, show the full method to add with surrounding context for placement.
