# Java Conventions

Java/JVM naming and structural conventions. Complements the universal engineering standards in `~/.claude/CLAUDE.md`.

---

## Naming Conventions

### Variables and Parameters

- Use `camelCase`.
- Name after what the value represents, not its type: `customerName` not `nameString`.
- Loop variables may be single characters only for trivial index iterations (`i`, `j`). For all other loops, use descriptive names: `for (Order order : pendingOrders)`.

### Methods

- Use `camelCase`.
- Start with a verb: `calculateTotal`, `findActiveCustomers`, `validateInput`, `sendNotification`.
- Boolean queries: `isEligible()`, `hasExpired()`, `canExecute()`.
- Factory methods: `createFromRequest()`, `Invoice.of(order)`.
- Avoid generic names (`process`, `handle`, `manage`, `doWork`) — be specific about what the method does.

### Classes and Interfaces

- Use `PascalCase`.
- Name after what the class represents: `InvoiceGenerator` not `InvoiceHelper`.
- Never suffix with `Manager`, `Helper`, `Util`, or `Handler` unless the class genuinely handles events. These suffixes signal unclear responsibility.
- Interfaces do not use `I` prefix. Name them after the capability: `Serializable`, `TenantAware`, `Auditable`.

### Packages

- Use `lowercase` with no separators.
- Root: `com.example.app` — replace with actual organisation and application name.
- Organise by feature, not by layer: `com.example.app.billing` not `com.example.app.controllers`.

### Files

- Java source files: `PascalCase` matching the class name.
- TypeScript/JavaScript files: `kebab-case` for utilities, `PascalCase` for React components.
- Configuration files: `kebab-case`.
- Migration files: Flyway convention `V{version}__{description}.sql`.

## Package-by-Feature: Java Example

```
com.example.app/
├── billing/
│   ├── BillingController.java
│   ├── BillingService.java
│   ├── InvoiceRepository.java
│   ├── Invoice.java                  # Entity
│   ├── CreateInvoiceRequest.java     # Request DTO
│   ├── InvoiceResponse.java          # Response DTO
│   ├── InvoiceMapper.java            # Manual mapping methods
│   ├── InvoiceNotFoundException.java # Feature-specific exception
│   └── BillingTestFixtures.java      # Test data builders
├── customer/
│   └── ...
├── common/
│   ├── BaseEntity.java
│   ├── ErrorResponse.java
│   ├── ControllerExceptionHandler.java
│   └── TenantContext.java
└── config/
    ├── SecurityConfig.java
    ├── JpaConfig.java
    └── KafkaConfig.java
```

## Testing Patterns

### Test Naming

Use `methodName_scenario_expectedResult`:
`calculateTotal_withDiscountCode_appliesPercentageDiscount`.

### What Not to Test

In addition to the universal rules: do not test Lombok-generated methods (getters, setters, builders). Do not test that Spring injects a dependency — that is framework behaviour.

### Test Infrastructure

- Use **TestContainers** for integration tests that need real database, Kafka, or Redis instances. The slight slowdown is worth the confidence.
- Use **Mockito** for mocking. Prefer `@ExtendWith(MockitoExtension.class)` over `@SpringBootTest` for unit tests.
- Use `@SpringBootTest` with `MockMvc` for controller integration tests.

### Kafka Testing

Test every Kafka producer and consumer: serialisation, deserialisation, error handling, and retry behaviour. Use an embedded Kafka broker or TestContainers Kafka for integration tests.

## Exception Hierarchy

Maintain a shallow hierarchy rooted in `ApplicationException`:

```
ApplicationException (abstract, extends RuntimeException)
├── ResourceNotFoundException      → 404
├── ValidationException            → 400
├── BusinessRuleException          → 422
├── AuthenticationException        → 401
├── AuthorisationException         → 403
└── IntegrationException           → 502
```

Subclass for specifics: `CustomerNotFoundException extends ResourceNotFoundException`.

A single `ControllerExceptionHandler` (`@RestControllerAdvice`) maps each type to its HTTP status. Unhandled exceptions return 500 — never expose stack traces or internal details.

## Logging

Use the fully-qualified class name as the logger name. Always populate MDC (Mapped Diagnostic Context) with `tenantId` and `traceId` so every log entry carries correlation identifiers automatically:

```json
{
  "timestamp": "2025-01-15T10:30:00.123Z",
  "level": "INFO",
  "logger": "com.example.app.billing.BillingService",
  "message": "Invoice created successfully",
  "tenantId": "tenant-abc",
  "customerId": "cust-123",
  "invoiceId": "inv-456",
  "traceId": "req-xyz-789"
}
```

## Javadoc

Write Javadoc for every public API class, interface, and method. Not for internal implementation classes.

- Document parameters, return values, and thrown exceptions.
- Include a brief usage example for non-obvious APIs.
- Do not restate the method name: `/** Gets the customer. */ getCustomer()` adds no value.

## Security

### Bean Validation

Validate request DTOs with Bean Validation annotations at the controller boundary:

- `@NotBlank` and `@Size(max = 255)` for string fields.
- `@Positive` or `@Min`/`@Max` for numeric fields.
- `@Valid` on controller method parameters to trigger validation.
- Custom constraint annotations for domain-specific rules.

### Spring Security

- Use `@PreAuthorize` annotations on service methods for permission checks.
- Never bypass Spring Security filters.
- Configure method security with `@EnableMethodSecurity`.

### Identity and Tokens

Use Keycloak (or another OAuth2/OIDC-compliant provider) for authentication. Never implement custom authentication. Configure Spring Security as an OAuth2 resource server to validate JWT tokens on every request. Do not cache authentication decisions.
