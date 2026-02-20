# Base Engineering Standards

This file defines universal engineering principles, conventions, and expectations that apply to every project regardless of technology stack. All technology-specific layers inherit from and must not contradict these standards.

---

## Coding Philosophy

Write code for humans first, machines second. Every line of code is read far more often than it is written. Optimise for readability, clarity, and maintainability above all else.

**Core principles:**

- **Readability over cleverness.** If a solution requires a comment to explain what it does, simplify the solution. Never use obscure language features, bitwise tricks, or dense one-liners to save a few lines. The clearest implementation wins, even if it is slightly longer.
- **Simplicity over abstraction.** Do not introduce abstractions until a concrete pattern has repeated at least three times. Premature abstraction creates more complexity than duplication. When you do abstract, prefer composition over inheritance.
- **Consistency over personal preference.** Follow established project conventions even when you disagree with them. Consistency across a codebase is more valuable than any individual stylistic improvement. If a convention needs changing, change it everywhere or not at all.
- **Explicit over implicit.** Make behaviour visible in the code. Avoid hidden side effects, magic strings, implicit type conversions, and convention-based wiring that requires tribal knowledge to understand.
- **Small, focused units.** Methods do one thing. Classes have one responsibility. Packages represent one feature or concern. If you struggle to name something, it probably does too much.

## Naming Conventions

Names are the most important form of documentation. A well-named variable, method, or class eliminates the need for comments.

### General Rules

- Use descriptive, unambiguous names. `remainingAttempts` not `cnt`. `customerEmailAddress` not `email`.
- Do not abbreviate unless the abbreviation is universally understood in the domain (e.g., `id`, `url`, `http`).
- Boolean variables and methods use affirmative prefixes: `isActive`, `hasPermission`, `canExecute`. Never use negated names like `isNotValid` — use `isValid` and negate at the call site.
- Collections use plural nouns: `customers`, `orderItems`, `activeSubscriptions`.
- Constants use `UPPER_SNAKE_CASE`.

### Variables and Parameters

- Use `camelCase`.
- Name after what the value represents, not its type: `customerName` not `nameString`.
- Loop variables may be single characters only for trivial iterations over indexes (`i`, `j`). For all other loops, use descriptive names: `for (Order order : pendingOrders)`.

### Methods and Functions

- Use `camelCase`.
- Start with a verb describing the action: `calculateTotal`, `findActiveCustomers`, `validateInput`, `sendNotification`.
- Query methods that return booleans start with `is`, `has`, `can`, `should`: `isEligible()`, `hasExpired()`.
- Factory methods use `create` or `of`: `createFromRequest()`, `Invoice.of(order)`.
- Avoid generic names like `process`, `handle`, `manage`, `doWork`. Be specific about what the method does.

### Classes and Types

- Use `PascalCase`.
- Name after what the class represents, not what it does internally: `InvoiceGenerator` not `InvoiceHelper`.
- Never suffix with `Manager`, `Helper`, `Util`, or `Handler` unless the class genuinely handles events. These suffixes indicate a class with unclear responsibility.
- Interfaces do not use `I` prefix. Name them after the capability: `Serializable`, `TenantAware`, `Auditable`.

### Packages and Modules

- Use `lowercase` with no separators.
- Organise by feature, not by layer. `com.example.app.billing` not `com.example.app.controllers`.

### Database

- Table names: `snake_case`, plural: `customers`, `order_items`, `subscription_plans`.
- Column names: `snake_case`, singular: `first_name`, `created_at`, `is_active`.
- Foreign keys: `referenced_table_singular_id`: `customer_id`, `order_id`.
- Indexes: `idx_tablename_columns`: `idx_customers_email`, `idx_order_items_order_id_product_id`.
- Constraints: `chk_tablename_description` for checks, `uq_tablename_columns` for unique constraints.
- Join tables: alphabetical combination of both table names: `customers_roles`, `orders_products`.

### Files and Directories

- Java files: `PascalCase` matching the class name.
- TypeScript/JavaScript files: `kebab-case` for utilities, `PascalCase` for React components.
- Configuration files: `kebab-case`.
- Migration files: follow Flyway convention `V{version}__{description}.sql`.

## Package-by-Feature Architecture

Every project uses package-by-feature as its primary organisational principle. This is non-negotiable.

### What Package-by-Feature Means

All code related to a single business feature lives together in one package. A feature package contains its controller, service, repository, DTOs, mapping logic, exceptions, and validation — everything needed to understand and modify that feature.

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
│   ├── CustomerController.java
│   ├── CustomerService.java
│   └── ...
├── common/                           # Shared cross-cutting code
│   ├── BaseEntity.java
│   ├── ErrorResponse.java
│   ├── GlobalExceptionHandler.java
│   └── TenantContext.java
└── config/                           # Application configuration
    ├── SecurityConfig.java
    ├── JpaConfig.java
    └── KafkaConfig.java
```

### Why Package-by-Feature

- **Feature locality.** When working on billing, every file you need is in one package. No jumping between `controllers/`, `services/`, `repositories/` directories.
- **Clear boundaries.** Features have explicit boundaries. Dependencies between features are visible as cross-package imports.
- **Safe deletion.** Removing a feature means deleting one package. No hunting through layer directories for scattered files.
- **Independent evolution.** Each feature can adopt different internal patterns as appropriate without forcing consistency across unrelated features.

### Boundaries Between Features

- Features communicate through their public service interfaces, never by reaching into another feature's repository or entities directly.
- If Feature A needs data from Feature B, Feature A calls Feature B's service. It does not inject Feature B's repository.
- Shared types that cross feature boundaries (e.g., `CustomerId`) live in the `common` package.
- If two features seem tightly coupled, consider whether they are actually one feature that should be merged.

### The `common` Package

Use `common` sparingly. Code belongs in `common` only if it is genuinely used across three or more features AND has no feature-specific logic. Typical residents: base entity class, global exception handler, shared configuration, cross-cutting DTOs like pagination and error responses.

If something is used by only two features, put it in the feature that owns the concept and let the other feature depend on it.

## Git Conventions

### Commit Messages

Use the Conventional Commits format:

```
type(scope): short description

Longer explanation if needed. Explain why, not what.
The diff shows what changed; the message explains the motivation.

Closes #123
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`, `build`.

**Scope:** The feature or area affected: `feat(billing): add invoice PDF generation`.

**Rules:**
- Subject line: imperative mood, lowercase, no period, max 72 characters.
- Body: wrap at 80 characters. Explain the reasoning behind the change.
- Reference issue numbers when applicable.
- One logical change per commit. Do not mix refactoring with feature work in the same commit.

### Branching Strategy

- `main` — always deployable, protected, no direct pushes.
- `feature/{ticket-id}-{short-description}` — feature branches from `main`.
- `fix/{ticket-id}-{short-description}` — bug fix branches from `main`.
- `release/{version}` — release preparation branches when needed.
- Rebase feature branches onto `main` before merging. Keep history linear.

### Pull Requests

- PRs should be reviewable in under 30 minutes. If a PR is too large, break it into smaller incremental PRs.
- PR title follows commit message format.
- PR description includes: what changed, why, how to test, and any migration steps.
- All PRs require passing CI before merge.

## Claude Code Behaviour Expectations

These rules define how Claude Code should operate when working on projects that use this configuration.

### Ask vs. Act

- **Act immediately** for: implementing a feature described in a command, fixing a bug with a clear reproduction, adding tests, formatting code, creating migrations, and any task with unambiguous requirements.
- **Ask before acting** for: architectural decisions that affect multiple features, choosing between two reasonable approaches, deleting or significantly restructuring existing code, adding new dependencies, and changes that would alter public API contracts.
- When in doubt, bias towards acting. Produce the implementation and explain your choices. It is faster to review and adjust working code than to discuss hypotheticals.

### Code Generation Standards

- Generate complete, compilable, runnable code. Never produce code with placeholder comments like `// TODO: implement this` or `// add logic here`. Every method has a real implementation.
- Include all necessary imports. Never assume the developer will add missing imports.
- Follow the conventions defined in these CLAUDE.md layers exactly. Do not introduce alternative patterns even if you consider them superior.
- When generating multiple related files (entity, DTOs, service, controller, tests), generate all of them. Never produce a partial feature.

### Explaining Work

- When generating code as part of a command, do not explain the code unless the code does something non-obvious or departs from established conventions.
- When asked to debug or analyse, explain your reasoning step by step.
- When making architectural recommendations, state the trade-offs explicitly. Do not present one option as obviously correct unless it genuinely is.
- Keep explanations concise. A two-sentence rationale is better than a five-paragraph essay.

### Handling Uncertainty

- If a convention is not explicitly covered in the CLAUDE.md layers, follow the most common pattern already established in the project codebase.
- If there is no existing pattern to follow, apply the principles in this base layer (readability, simplicity, consistency) and state your reasoning.
- Never silently make assumptions about business logic. If the requirements are ambiguous about business rules, ask.
- Technical implementation decisions (which data structure, which algorithm, which library API) do not require asking — use your best judgement and explain the choice if it is non-obvious.

## Testing Philosophy

Testing is not optional. Every feature ships with tests. Tests are the specification — they document what the code does and catch regressions when the code changes.

### What to Test

- **Every public service method.** Service methods contain business logic. Test the happy path, validation failures, edge cases, and error conditions.
- **Every controller endpoint.** Test request parsing, validation, response structure, HTTP status codes, and error responses. Use integration-style tests that exercise the full request/response cycle.
- **Every complex mapping or transformation.** If a mapping method does more than simple field-to-field assignment, test it.
- **Every database query that is not a simple findById.** Custom queries, specifications, and complex derived queries get their own tests.
- **Every Kafka producer and consumer.** Test serialisation, deserialisation, error handling, and retry behaviour.

### What Not to Test

- Do not test trivial getters and setters.
- Do not test framework behaviour (e.g., testing that Spring injects a dependency).
- Do not test private methods directly. They are tested through their public callers.
- Do not test generated code (Lombok, annotation processors) unless you have customised the generation.

### Testing Patterns

- **Arrange-Act-Assert.** Every test follows this structure with clear visual separation between the three sections.
- **One assertion per test concept.** A test can have multiple assertions only if they verify different aspects of the same result. If you are testing two different behaviours, write two tests.
- **Descriptive test names.** Use the pattern `methodName_scenario_expectedResult`: `calculateTotal_withDiscountCode_appliesPercentageDiscount`. The test name is the specification.
- **Test data builders.** Create builder classes or factory methods for constructing test entities and DTOs. Never construct complex objects inline in test methods. Place these in a `TestFixtures` class within the feature package.
- **No test interdependence.** Tests must not depend on execution order or shared mutable state. Each test sets up its own data and cleans up after itself (or uses transactional rollback).

### Mocking Approach

- **Mock external boundaries** — HTTP clients, message queues, external service calls, email senders, file systems. These are the edges of your system.
- **Do not mock repositories in service tests** when you can use an in-memory or containerised database. Real database tests catch real bugs (query syntax errors, constraint violations, transaction issues).
- **Use TestContainers** for integration tests that need real database, Kafka, or Redis instances. The slight slowdown is worth the confidence.
- **Prefer fakes over mocks** when the fake is simple to implement. A `FakeEmailSender` that stores sent emails in a list is clearer than a Mockito mock with argument captors.

## Error Handling Philosophy

Errors are a first-class concern, not an afterthought. Handle them explicitly, consistently, and informatively.

### When to Throw Exceptions

- Throw exceptions for conditions that the caller cannot reasonably be expected to handle inline: resource not found, validation failures, permission denied, infrastructure failures.
- Use specific exception types for specific conditions: `CustomerNotFoundException`, `InvoiceAlreadyPaidException`, `InsufficientPermissionException`.
- Never throw generic `RuntimeException` or `Exception`. Always use a specific type.
- Never use exceptions for flow control. If a condition is expected and normal (e.g., checking if a username is taken), use a return value, not an exception.

### Exception Hierarchy

Maintain a shallow exception hierarchy:

```
ApplicationException (abstract base)
├── ResourceNotFoundException
├── ValidationException
├── BusinessRuleException
├── AuthenticationException
├── AuthorisationException
└── IntegrationException
```

Each can be subclassed for specific cases: `CustomerNotFoundException extends ResourceNotFoundException`.

### Error Response Structure

Every API error response follows this structure:

```json
{
  "error": {
    "code": "CUSTOMER_NOT_FOUND",
    "message": "Customer with ID 'abc-123' was not found",
    "details": [],
    "timestamp": "2025-01-15T10:30:00Z",
    "traceId": "req-xyz-789"
  }
}
```

- `code`: machine-readable, `UPPER_SNAKE_CASE`, specific and actionable.
- `message`: human-readable, includes relevant context (the ID that was not found, the field that failed validation).
- `details`: array of field-level errors for validation failures. Empty array when not applicable.
- `timestamp`: ISO 8601 UTC.
- `traceId`: correlation ID for tracing through logs and distributed systems.

### Error Mapping

Map exceptions to HTTP status codes consistently:

- `ResourceNotFoundException` → 404
- `ValidationException` → 400
- `BusinessRuleException` → 422
- `AuthenticationException` → 401
- `AuthorisationException` → 403
- `IntegrationException` → 502
- Unhandled exceptions → 500 with a generic message (never expose stack traces or internal details)

## Logging Conventions

### What to Log

- **Log every entry and exit of significant operations** at INFO level: service method invocations, external API calls, message consumption. Include relevant identifiers (customerId, orderId).
- **Log all errors with context** at ERROR level: the operation that failed, the input that caused the failure, and the exception. Never log just the exception message without context.
- **Log warnings for recoverable but unexpected conditions** at WARN level: retry attempts, fallback activations, deprecated feature usage.
- **Log debug information for complex business logic** at DEBUG level: intermediate calculation steps, decision branch points, cache hits/misses.

### What Not to Log

- Never log sensitive data: passwords, tokens, API keys, credit card numbers, personal identification numbers.
- Never log entire request or response bodies at INFO level. Log them at DEBUG level if needed for troubleshooting.
- Never log in tight loops. If you need to log inside a loop, aggregate and log a summary after the loop.

### Log Format

Use structured logging (JSON format in production, human-readable in development):

```
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

Always include `tenantId` and `traceId` in every log entry via MDC (Mapped Diagnostic Context).

### Log Levels

- **ERROR**: Something failed and requires human attention. Pages, alerts.
- **WARN**: Something unexpected happened but the system recovered. Review periodically.
- **INFO**: Normal operational events. Useful for understanding system behaviour in production.
- **DEBUG**: Detailed diagnostic information. Disabled in production by default.
- **TRACE**: Extremely detailed. Framework-level internals. Almost never used in application code.

## Documentation Expectations

### Code Comments

- **Do not write comments that restate what the code does.** If the code is not self-explanatory, refactor it to be clearer.
- **Do write comments that explain why** — business reasons, non-obvious design decisions, workarounds for known issues, references to external documentation or tickets.
- **Do write comments for complex algorithms** — a brief explanation of the approach before a non-trivial algorithm is appropriate.
- Mark temporary workarounds with `// HACK:` and a ticket reference. Mark known issues with `// FIXME:` and a ticket reference. Mark future improvements with `// TODO:` and a ticket reference. Never use these markers without a ticket reference.

### Javadoc / JSDoc

- Write Javadoc for every public API class, interface, and method. Not for internal implementation classes.
- Document parameters, return values, and thrown exceptions.
- Include a brief usage example for non-obvious APIs.
- Do not write Javadoc that merely restates the method name: `/** Gets the customer. */ getCustomer()` is useless.

### README Files

- Every project has a README.md with: what it is, how to run it locally, how to run tests, how to deploy, and key architectural decisions.
- Feature packages do not need READMEs unless they contain non-obvious setup or configuration.
- Keep READMEs up to date. An outdated README is worse than no README.

## Security-First Defaults

Security is not a layer you add later. It is baked into every decision from the start.

### Input Validation

- Validate all input at the API boundary using Bean Validation annotations. Never trust client-provided data.
- Validate type, format, length, and range. A `name` field should have `@NotBlank`, `@Size(max = 255)`. A quantity field should have `@Positive`.
- Validate business rules in the service layer after input sanitisation.
- Reject unexpected fields. Do not silently ignore extra fields in request bodies — use strict deserialization.

### Output Encoding

- Encode all output appropriately for its context (HTML encoding for web pages, JSON encoding for API responses).
- Never construct SQL, HTML, XML, or JSON by string concatenation. Always use parameterised queries, template engines, and serialisation libraries.

### Authentication and Authorisation

- Every endpoint is authenticated by default. Explicitly mark the rare exceptions (health checks, public assets).
- Use role-based or permission-based access control. Check permissions at the controller level using Spring Security annotations.
- Never implement custom authentication. Use Keycloak and OAuth2/JWT.
- Validate JWT tokens on every request. Do not cache authentication decisions.

### Data Protection

- Encrypt sensitive data at rest.
- Use HTTPS everywhere. No exceptions.
- Apply the principle of least privilege — services and database users get only the permissions they need.
- Never log, return in error messages, or expose in URLs: passwords, tokens, keys, or PII beyond what the client explicitly requested.

### Dependency Security

- Keep dependencies up to date. Run dependency vulnerability scans in CI.
- Prefer well-maintained libraries with active security response teams.
- Pin dependency versions. Never use dynamic version ranges in production.
