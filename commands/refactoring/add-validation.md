# Add Comprehensive Input Validation

Add thorough input validation to an existing endpoint or entity, covering both request DTO validation and service-level business validation.

## Required Input

- **Target**: Which endpoint, request DTO, or entity to add validation to.
- **Business rules** (if not obvious): Any domain-specific validation rules that go beyond format checking.

## Validation Layers

### Layer 1: Request DTO Validation (Bean Validation)

Add or improve Bean Validation annotations on the request DTO:

**String fields:**
- `@NotBlank` for required strings (rejects null, empty, and whitespace-only).
- `@Size(min = X, max = Y)` for length constraints.
- `@Email` for email format.
- `@Pattern(regexp = "...")` for specific formats (phone numbers, codes).

**Numeric fields:**
- `@NotNull` for required numbers.
- `@Positive` or `@PositiveOrZero` for value constraints.
- `@Min` / `@Max` for range constraints.
- `@Digits(integer = X, fraction = Y)` for precision constraints on BigDecimal.

**Collections:**
- `@NotEmpty` for required non-empty collections.
- `@Size(min = X, max = Y)` for collection size limits.
- `@Valid` on collection elements to cascade validation.

**Nested objects:**
- `@Valid` to trigger validation on nested request DTOs.
- `@NotNull` in addition to `@Valid` if the nested object is required.

**Temporal fields:**
- `@NotNull` for required dates.
- `@Future` or `@FutureOrPresent` for dates that must be in the future.
- `@Past` or `@PastOrPresent` for dates that must be in the past.

**Every annotation must include a `message` attribute** with a human-readable error description:
```java
@NotBlank(message = "Customer name is required")
@Size(max = 255, message = "Customer name must not exceed 255 characters")
String name
```

### Layer 2: Controller Validation

Ensure the controller:
- Uses `@Valid` on all `@RequestBody` parameters.
- Validates path variables where appropriate (`@Positive`, UUID format).
- Validates query parameters with `@RequestParam` constraints.

### Layer 3: Service Business Validation

Add business rule validation in the service layer for rules that cannot be expressed as annotations:

- **Uniqueness checks**: `if (repository.existsByEmailAndTenantId(email, tenantId)) throw new DuplicateEmailException(email)`.
- **State-dependent rules**: "Cannot modify a paid invoice."
- **Cross-field validation**: "End date must be after start date."
- **External data validation**: "Customer ID must reference an existing customer."
- **Authorisation-adjacent rules**: "Users can only modify their own resources."

### Layer 4: Entity Invariant Validation

If the entity has invariants that must always hold:
- Add validation in entity business methods (e.g., `addLineItem` validates the item before adding).
- Use JPA `@PrePersist` / `@PreUpdate` callbacks for database-level invariant checks as a safety net.

## Output Format

Show:
1. The updated request DTO with all validation annotations.
2. Service method modifications with business validation.
3. Entity modifications if invariant validation is added.
4. Updated tests covering each validation rule (both valid and invalid inputs).
5. A summary table of all validation rules added:

```
| Field | Validation | Layer | Rule |
|-------|-----------|-------|------|
| name | @NotBlank | DTO | Required |
| name | @Size(max=255) | DTO | Length limit |
| email | unique per tenant | Service | Business rule |
```
