---
name: spring-boot-conventions
description: Spring Boot conventions — project scaffolding, package-by-feature, service layer, DTOs, configuration, exception handling, testing, security, multi-tenancy
user-invocable: false
paths: "**/*.java,**/pom.xml,**/application.properties,**/application*.yml"
---

# Spring Boot Technical Standards

Spring Boot 4+ with Java 21+, Maven, and Keycloak for authentication. Builds on java-conventions. For detailed code examples see the reference files in this skill directory:

- [controller-patterns.md](controller-patterns.md) — CRUD controller, DTO patterns, mapper
- [testing-patterns.md](testing-patterns.md) — MockMvc, service tests, fixtures, integration tests
- [security-config.md](security-config.md) — OAuth2/JWT, actuator, multi-tenancy

---

## Project Scaffolding

### Minimal Start

A brand new project contains exactly four files:

```
.gitignore
pom.xml
src/main/java/com/example/app/Application.java
src/main/resources/application.properties
```

No `common/`, no `config/`, no `SecurityConfig`, no `ControllerExceptionHandler`, no `TenantInterceptor`. Add infrastructure only when the first feature that needs it is being implemented.

### When to Add More

- **Security config** (`SecurityConfig`, OAuth2/JWT) — when the first secured endpoint is added.
- **Exception hierarchy + `ControllerExceptionHandler`** — when the first feature needs consistent error responses.
- **Multi-tenancy** (`TenantContext`, `TenantInterceptor`) — when the first multi-tenant feature is added.
- **`common/` package** — when a third feature needs a type that already exists in two other features.
- **Additional dependencies** — when the feature that uses them is implemented, not before.

### pom.xml

Use `spring-boot-starter-parent` at the latest stable 4.x version. Java 21. Initial dependency: `spring-boot-starter-web` only.

### application.properties

One property only at project creation: `spring.application.name=my-app`. Add further properties only when needed.

### CLAUDE.md Project Setup Section

When scaffolding a new project, add a `## Project Setup` section documenting group ID, artifact ID, base package, Spring Boot version, Java version, common commands (build/run/test/package), and default port.

---

## Java Conventions (Spring Boot Specific)

### Type Declarations

Always use explicit types instead of `var`. This improves readability and makes types immediately clear.

### `final` Usage

Use `final` for `String` and primitives where the property is not mutated. Use `final` on method parameters when they should not be reassigned. Do not use `final` on non-primitive objects unless preventing reference change.

### Primitive Types

Use primitives where applicable. `boolean` over `Boolean`, `int` over `Integer`, etc., unless null is genuinely needed.

---

## Package-by-Feature Organisation

```
com.example.app/
├── Application.java
├── billing/
│   ├── api/
│   │   ├── BillingController.java
│   │   ├── CreateInvoiceRequest.java
│   │   ├── UpdateInvoiceRequest.java
│   │   ├── InvoiceResponse.java
│   │   ├── InvoiceSummaryResponse.java
│   │   └── InvoiceMapper.java
│   ├── service/
│   │   └── BillingService.java
│   ├── repository/
│   │   └── InvoiceRepository.java
│   ├── entity/
│   │   ├── Invoice.java
│   │   ├── InvoiceLineItem.java
│   │   └── InvoiceStatus.java
│   ├── InvoiceNotFoundException.java
│   └── InvoiceAlreadyPaidException.java
├── common/
│   ├── ErrorResponse.java
│   ├── ErrorDetail.java
│   ├── ControllerExceptionHandler.java
│   ├── PageResponse.java
│   ├── TenantContext.java
│   └── TenantInterceptor.java
└── config/
    ├── SecurityConfig.java
    ├── WebConfig.java
```

### Feature Package Rules

- **`api/`** — Controllers, request DTOs, response DTOs, mapper classes.
- **`service/`** — Service classes with business logic, transaction management, orchestration.
- **`repository/`** — Repository interfaces for data access.
- **`entity/`** — Domain model classes, enums, value objects.
- **Feature package root** — Feature-specific exceptions.
- A feature package never reaches into another feature's repository. Cross-feature communication goes through the other feature's service.

### Shared Code

`common` holds genuinely cross-cutting concerns used across 3+ features: `ControllerExceptionHandler`, `ErrorResponse`, `ErrorDetail`, `PageResponse`, `TenantContext`, `TenantInterceptor`.

`config` holds Spring configuration classes: security, web MVC.

Do not put business logic in `common` or `config`.

---

## Service Layer Patterns

```java
@Service
@Transactional(readOnly = true)
public class BillingService {

    private final InvoiceRepository invoiceRepository;
    private final CustomerService customerService;

    public BillingService(InvoiceRepository invoiceRepository,
                          CustomerService customerService) {
        this.invoiceRepository = invoiceRepository;
        this.customerService = customerService;
    }

    @Transactional
    public InvoiceResponse createInvoice(CreateInvoiceRequest request, String tenantId) {
        // ... business logic ...
        return InvoiceMapper.toResponse(saved);
    }

    public InvoiceResponse getInvoice(UUID invoiceId, String tenantId) {
        Invoice invoice = invoiceRepository.findByIdAndTenantId(invoiceId, tenantId)
                .orElseThrow(() -> new InvoiceNotFoundException(invoiceId));
        return InvoiceMapper.toResponse(invoice);
    }
}
```

**Rules:**
- Class-level `@Transactional(readOnly = true)`. Override with `@Transactional` on mutating methods.
- Constructor injection only. No `@Autowired` on fields. Final fields preferred.
- One service class per feature. If a service exceeds ~300 lines, the feature is too large — split it.
- Services return Response DTOs, never entities, to controllers.
- Services may expose a package-private method returning the entity for cross-feature use.

### Business Validation

- Input format validation (not blank, max length, valid email) — on Request DTOs via Bean Validation.
- Business rule validation (credit check, unique constraint, state machine) — in the service layer.
- Fail fast — validate before performing any mutations.

---

## Configuration Management

```properties
# application.properties
spring.application.name=my-service
server.port=8080
logging.level.root=INFO
```

**Rules:**
- Use `application.properties` only. No profile-specific properties files (`application-local.properties`, `application-prod.properties`).
- Externalise all secrets and environment-specific values via environment variables. Never commit secrets.
- Define configurable values in `application.properties`. Reference in `@Configuration` classes using `@Value` in constructors.
- Do not use static constants for configurable values.
- Environment variable defaults: `mysql.url=${DATASOURCE_URL:jdbc:mysql://localhost:3306/db}`
- Use `@ConfigurationProperties` for type-safe, reusable configuration groups.

---

## Exception Handling

### Custom Hierarchy

```java
public abstract class ApplicationException extends RuntimeException {
    private final String errorCode;
    protected ApplicationException(String errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }
    public String getErrorCode() { return errorCode; }
}

public class ResourceNotFoundException extends ApplicationException {
    public ResourceNotFoundException(String resourceType, Object id) {
        super(resourceType.toUpperCase() + "_NOT_FOUND",
              resourceType + " with ID '" + id + "' was not found");
    }
}

public class InvoiceNotFoundException extends ResourceNotFoundException {
    public InvoiceNotFoundException(UUID id) {
        super("Invoice", id);
    }
}
```

`ControllerExceptionHandler` maps each exception type to its HTTP status. Full implementation in [controller-patterns.md](controller-patterns.md).
