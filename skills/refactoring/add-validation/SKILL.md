---
name: add-validation
description: Add comprehensive input validation to a request DTO and service — Bean Validation annotations, controller @Valid, service business rules, entity invariants, and tests
argument-hint: "[endpoint or DTO class to add validation to] [any business rules not obvious from the code]"
disable-model-invocation: true
allowed-tools: Read, Edit, Glob
---

# Add Comprehensive Input Validation

Add thorough input validation covering request DTO validation and service-level business validation.

## Required Input

Use `$ARGUMENTS` to determine:
- **Target**: Which endpoint, request DTO, or entity to add validation to.
- **Business rules** (if not obvious): Domain-specific validation rules beyond format checking.

Read the current DTO, controller, and service before making changes.

## Validation Layers

### Layer 1: Request DTO Validation (Bean Validation)

**String fields:**
- `@NotBlank` for required strings (rejects null, empty, whitespace-only).
- `@Size(min = X, max = Y)` for length constraints.
- `@Email` for email format.
- `@Pattern(regexp = "...")` for specific formats.

**Numeric fields:**
- `@NotNull` for required numbers.
- `@Positive` or `@PositiveOrZero` for value constraints.
- `@Min` / `@Max` for range constraints.
- `@Digits(integer = X, fraction = Y)` for BigDecimal precision.

**Collections:**
- `@NotEmpty` for required non-empty collections.
- `@Size(min = X, max = Y)` for size limits.
- `@Valid` on collection elements to cascade validation.

**Nested objects:**
- `@Valid` to trigger validation on nested request DTOs.
- `@NotNull` in addition to `@Valid` if nested object is required.

**Temporal fields:**
- `@Future` or `@FutureOrPresent` for future dates.
- `@Past` or `@PastOrPresent` for past dates.

**Every annotation must have a `message` attribute:**
```java
@NotBlank(message = "Customer name is required")
@Size(max = 255, message = "Customer name must not exceed 255 characters")
String name
```

### Layer 2: Controller Validation

Ensure the controller:
- Uses `@Valid` on all `@RequestBody` parameters.
- Validates path variables where appropriate.
- Validates query parameters with constraints.

### Layer 3: Service Business Validation

Add business rule validation for rules that cannot be expressed as annotations:
- **Uniqueness checks**: `if (repository.existsByEmailAndTenantId(email, tenantId)) throw new DuplicateEmailException(email)`.
- **State-dependent rules**: "Cannot modify a paid invoice."
- **Cross-field validation**: "End date must be after start date."
- **External data validation**: "Customer ID must reference an existing customer."

### Layer 4: Entity Invariant Validation (if needed)

If the entity has invariants that must always hold:
- Validation in entity business methods (e.g., `addLineItem` validates before adding).
- JPA `@PrePersist` / `@PreUpdate` callbacks as a safety net.

## Output Format

Show:
1. Updated request DTO with all validation annotations.
2. Service method modifications with business validation.
3. Entity modifications if invariant validation added.
4. Updated tests covering each validation rule (valid and invalid inputs).
5. Summary table:

```
| Field | Validation | Layer | Rule |
|-------|-----------|-------|------|
| name | @NotBlank | DTO | Required |
| name | @Size(max=255) | DTO | Length limit |
| email | unique per tenant | Service | Business rule |
```
