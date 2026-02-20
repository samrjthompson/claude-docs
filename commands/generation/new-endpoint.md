# Add New Endpoint to Existing Feature

Add a new REST endpoint to an existing feature package with all supporting code.

## Required Input

Provide the following:
- **Feature package**: Which existing feature this endpoint belongs to (e.g., `billing`)
- **HTTP method and path**: e.g., `POST /api/v1/invoices/{invoiceId}/send`
- **Purpose**: What this endpoint does (e.g., "Send an invoice to the customer via email")
- **Request body** (if applicable): Fields with types and validation rules
- **Response**: Expected response structure and HTTP status code

## Files to Create or Modify

### 1. Request DTO (new file, if endpoint accepts a body)

- Java record with Bean Validation annotations.
- Every validation annotation includes a `message` attribute.
- File name: `{ActionName}Request.java` (e.g., `SendInvoiceRequest.java`).

### 2. Response DTO (new file, if response differs from existing DTOs)

- Java record with fields matching the API response.
- Reuse an existing response DTO if the shape matches.

### 3. Controller Method (modify existing controller)

- Add new method to the existing controller class.
- Include `@Operation` OpenAPI annotation with summary.
- Use appropriate HTTP method annotation (`@PostMapping`, `@GetMapping`, etc.).
- Extract tenant ID from JWT.
- Apply `@Valid` on request body if present.
- Return appropriate HTTP status code.

### 4. Service Method (modify existing service)

- Add new method to the existing service class.
- Include `@Transactional` if the method mutates data.
- Implement business logic and validation.
- Log at INFO level with relevant entity IDs and tenant ID.
- Return Response DTO.

### 5. Mapper Methods (modify existing mapper, if new response DTO)

- Add static mapping method to the existing mapper.

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
