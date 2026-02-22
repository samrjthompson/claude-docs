# Spring Boot Technical Standards

This layer defines conventions and patterns for Spring Boot applications. It builds on the base engineering standards and specifies how those principles apply to Spring Boot projects.

These standards target Spring Boot 4+ with Java 21+, Maven, and Keycloak for authentication. Database and persistence concerns are provided by a separate database layer (e.g., `mysql`, `postgres`, `mongodb`).

---

## Project Scaffolding

### Principle

Start with the absolute minimum needed to compile and run. Do not scaffold security configuration, exception handling, multi-tenancy, common packages, OpenAPI config, or any feature code before a feature exists that needs them. Every file added to a project should be justified by a concrete, immediate requirement.

### Initial File Set

A brand new project contains exactly four files:

```
.gitignore
pom.xml
src/main/java/com/example/app/Application.java
src/main/resources/application.properties
```

Nothing else. No `common/` package, no `config/` package, no `SecurityConfig`, no `ControllerExceptionHandler`, no `TenantInterceptor`.

### pom.xml

Use `spring-boot-starter-parent` at the latest stable 4.x version. Java 21. A single dependency: `spring-boot-starter-web`. Include the Spring Boot Maven plugin.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>4.0.3</version>
    </parent>

    <groupId>com.example</groupId>
    <artifactId>my-app</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>my-app</name>

    <properties>
        <java.version>21</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

### Application.java

The main class is `@SpringBootApplication` only. No additional annotations, no bean definitions, no configuration.

```java
package com.example.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### application.properties

One property only at project creation:

```properties
spring.application.name=my-app
```

Add further properties only when they are needed by a feature being implemented.

### CLAUDE.md Project Setup Section

When scaffolding a new project, add a `## Project Setup` section to the project's `CLAUDE.md` that documents the project coordinates, technology versions, common commands, and default port. This gives Claude Code durable, session-independent context about the project. Example:

```markdown
## Project Setup

- **Group ID**: `com.example`
- **Artifact ID**: `my-app`
- **Base package**: `com.example.app`
- **Spring Boot**: 4.0.3
- **Java**: 21

### Common Commands

- **Build**: `mvn compile`
- **Run**: `mvn spring-boot:run`
- **Test**: `mvn test`
- **Package**: `mvn package`

### Default Port

The application runs on port **8080** by default.
```

### When to Add More

Add infrastructure only when the first feature that needs it is being implemented:

- **Security config** (`SecurityConfig`, OAuth2/JWT setup) — when the first secured endpoint is added.
- **Exception hierarchy and `ControllerExceptionHandler`** — when the first feature needs consistent error responses.
- **Multi-tenancy** (`TenantContext`, `TenantInterceptor`) — when the first multi-tenant feature is added.
- **`common/` package** — when a third feature needs a type that already exists in two other features.
- **`config/` package** — when a configuration class is actually needed.
- **Additional dependencies** (security, JPA, Kafka, etc.) — when the feature that uses them is implemented, not before.

Resist the urge to add "foundation" code speculatively. A project with one feature and minimal infrastructure is easier to understand and change than one pre-loaded with unused scaffolding.

---

## Java Conventions

### Type Declarations

Always use explicit types instead of `var`. This improves code readability and makes types immediately clear.

```java
// Good
String name = "example";
List<User> users = userService.findAll();
Optional<Invoice> invoice = invoiceRepository.findById(id);

// Bad
var name = "example";
var users = userService.findAll();
var invoice = invoiceRepository.findById(id);
```

### `final` Usage

For `String` and primitives, always use `final` where the property is not mutated.

```java
// Good
final String email = "frodo.baggins@email.com";
final int yearOfBirth = 2968;
final boolean isAHobbit = true;

// Also good
public void doSomething(final String something) {
    // Logic where "something" doesn't need to mutate...
}
```

While these values can change over time, if they do not change at runtime then they should be `final`. For example, an email address might change, but the email in the current request does not change, and so should be `final`.

Use `final` on method parameters when they should not be reassigned.

Do not use `final` on non-primitive objects unless there is a risk of altering the object's reference.

### Primitive Types

Use primitives where applicable. If a `Boolean` wrapper is not required, use `boolean`. Prefer `int` over `Integer`, `long` over `Long`, etc., unless the null case is genuinely needed.

---

## Package-by-Feature Organisation

### Example Package Structure

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
├── customer/
│   ├── api/
│   │   ├── CustomerController.java
│   │   ├── CreateCustomerRequest.java
│   │   ├── UpdateCustomerRequest.java
│   │   ├── CustomerResponse.java
│   │   └── CustomerMapper.java
│   ├── service/
│   │   └── CustomerService.java
│   ├── repository/
│   ├── entity/
│   │   └── Customer.java
│   └── CustomerNotFoundException.java
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
    └── OpenApiConfig.java
```

### Feature Package Rules

Each feature package is self-contained. It holds every class needed for that feature to function, organised into sub-packages by layer:

- **`api/` sub-package** — Controllers, request DTOs, response DTOs, and mapper classes.
- **`service/` sub-package** — Service classes containing business logic, transaction management, and orchestration.
- **`repository/` sub-package** — Repository interfaces for data access. Defined by the database layer.
- **`entity/` sub-package** — Domain model classes representing the feature's domain objects. Persistence annotations are defined by the database layer. Enums and value objects specific to domain entities also live here.
- **Feature package root** — Feature-specific exceptions and test fixtures.

A feature package never reaches into another feature's repository. Cross-feature communication goes through the other feature's service.

### Handling Shared Code

The `common` package holds genuinely cross-cutting concerns used across three or more features:

- `ControllerExceptionHandler` mapping exceptions to error responses.
- `ErrorResponse` and `ErrorDetail` DTOs for consistent error formatting.
- `PageResponse` wrapper for paginated results.
- `TenantContext` and `TenantInterceptor` for multi-tenancy.

The `config` package holds Spring configuration classes:

- Security configuration.
- Web MVC configuration.
- OpenAPI/Swagger configuration.

Database and persistence configuration classes are provided by the database layer.

Do not put business logic in `common` or `config`. If a utility class contains business rules, it belongs in a feature package.

---

## Service Layer Patterns

### Transaction Management

```java
@Service
@Transactional(readOnly = true)
public class BillingService {

    private final InvoiceRepository invoiceRepository;
    private final CustomerService customerService;

    // Constructor injection — always. No field injection.
    public BillingService(InvoiceRepository invoiceRepository,
                          CustomerService customerService) {
        this.invoiceRepository = invoiceRepository;
        this.customerService = customerService;
    }

    @Transactional
    public InvoiceResponse createInvoice(CreateInvoiceRequest request, String tenantId) {
        Customer customer = customerService.getCustomerEntity(request.customerId(), tenantId);

        Invoice invoice = new Invoice();
        invoice.setCustomer(customer);
        invoice.setTenantId(tenantId);
        invoice.setStatus(InvoiceStatus.DRAFT);
        invoice.setInvoiceNumber(generateInvoiceNumber(tenantId));

        request.lineItems().forEach(item -> {
            InvoiceLineItem lineItem = new InvoiceLineItem();
            lineItem.setDescription(item.description());
            lineItem.setQuantity(item.quantity());
            lineItem.setUnitPrice(item.unitPrice());
            lineItem.setAmount(item.unitPrice().multiply(BigDecimal.valueOf(item.quantity())));
            invoice.addLineItem(lineItem);
        });

        Invoice saved = invoiceRepository.save(invoice);

        log.info("Invoice created: invoiceId={}, customerId={}, tenantId={}",
                saved.getId(), customer.getId(), tenantId);

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
- Class-level `@Transactional(readOnly = true)` as default. Override with `@Transactional` on mutating methods. `@Transactional` applies when the persistence layer supports Spring-managed transactions. The database layer specifies transaction behaviour.
- Constructor injection only. No `@Autowired` on fields. Final fields preferred.
- One service class per feature. If a service exceeds ~300 lines, the feature is too large — split it.
- Services return Response DTOs, never entities, to the controller. Services may accept and return entities to other services within the same feature.
- Services that other features depend on may expose a package-private method returning the entity for internal cross-feature use (e.g., `getCustomerEntity`).

### Business Validation in Services

- Input format validation (not blank, max length, valid email format) goes on Request DTOs via Bean Validation.
- Business rule validation (customer has sufficient credit, invoice is not already paid, email is unique) goes in the service layer.
- Fail fast — validate before performing any mutations.

```java
@Transactional
public InvoiceResponse payInvoice(UUID invoiceId, String tenantId) {
    Invoice invoice = invoiceRepository.findByIdAndTenantId(invoiceId, tenantId)
            .orElseThrow(() -> new InvoiceNotFoundException(invoiceId));

    // Business validation — this throws if already paid
    invoice.markAsPaid();

    Invoice saved = invoiceRepository.save(invoice);

    log.info("Invoice paid: invoiceId={}, tenantId={}", saved.getId(), tenantId);

    return InvoiceMapper.toResponse(saved);
}
```

---

## Controller Patterns

### Endpoint Design

```java
@RestController
@Tag(name = "Invoices", description = "Invoice management endpoints")
public class BillingController {

    private final BillingService billingService;

    public BillingController(BillingService billingService) {
        this.billingService = billingService;
    }

    @PostMapping("/api/v1/invoices")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a new invoice")
    public InvoiceResponse createInvoice(
            @Valid @RequestBody CreateInvoiceRequest request,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.createInvoice(request, tenantId);
    }

    @GetMapping("/api/v1/invoices/{invoiceId}")
    @Operation(summary = "Get invoice by ID")
    public InvoiceResponse getInvoice(
            @PathVariable UUID invoiceId,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.getInvoice(invoiceId, tenantId);
    }

    @GetMapping("/api/v1/invoices")
    @Operation(summary = "List invoices with optional filters")
    public PageResponse<InvoiceSummaryResponse> listInvoices(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) InvoiceStatus status,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.listInvoices(page, size, status, tenantId);
    }

    @PutMapping("/api/v1/invoices/{invoiceId}")
    @Operation(summary = "Update an existing invoice")
    public InvoiceResponse updateInvoice(
            @PathVariable UUID invoiceId,
            @Valid @RequestBody UpdateInvoiceRequest request,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.updateInvoice(invoiceId, request, tenantId);
    }

    @PostMapping("/api/v1/invoices/{invoiceId}/pay")
    @Operation(summary = "Mark an invoice as paid")
    public InvoiceResponse payInvoice(
            @PathVariable UUID invoiceId,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.payInvoice(invoiceId, tenantId);
    }

    @DeleteMapping("/api/v1/invoices/{invoiceId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a draft invoice")
    public void deleteInvoice(
            @PathVariable UUID invoiceId,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        billingService.deleteInvoice(invoiceId, tenantId);
    }

    private String extractTenantId(JwtAuthenticationToken principal) {
        return principal.getToken().getClaimAsString("tenant_id");
    }
}
```

### Controller Rules

- **URL naming**: Plural nouns for resources. `/api/v1/invoices`, not `/api/v1/invoice`. Nested resources for strong ownership: `/api/v1/customers/{customerId}/invoices`.
- **API versioning**: Use URL path versioning (`/api/v1/`). Bump the version only for breaking changes.
- **HTTP methods**: `GET` for reads, `POST` for creates, `PUT` for full updates, `PATCH` for partial updates, `DELETE` for deletes. Use `POST` for actions that do not map to CRUD: `POST /api/v1/invoices/{id}/pay`.
- **Response status codes**: `200` for successful reads and updates, `201` for creates (with `Location` header), `204` for deletes, `400` for validation errors, `404` for not found, `422` for business rule violations.
- **No business logic in controllers.** Controllers validate input (via `@Valid`), extract the tenant, call the service, and return the response. Nothing else. Controllers must depend on service classes.
- **Pagination**: Default page size of 20, maximum of 100. Return pagination metadata in a `PageResponse` wrapper.
- **Annotate every endpoint** with OpenAPI `@Operation`, `@Tag`, `@ApiResponse` for documentation generation.
- **Do not use `@RequestMapping` annotations above controller classes.** Always write full paths in the mapping annotations on each method (e.g., `@GetMapping("/api/v1/invoices/{id}")`).

---

## DTO Patterns

### Request DTOs

Use Java records for immutability. Apply Bean Validation annotations directly.

```java
@Builder
public record CreateInvoiceRequest(
        @NotNull(message = "Customer ID is required")
        UUID customerId,

        @NotEmpty(message = "At least one line item is required")
        @Valid
        List<LineItemRequest> lineItems,

        @Size(max = 500, message = "Notes must not exceed 500 characters")
        String notes
) {}

@Builder
public record LineItemRequest(
        @NotBlank(message = "Description is required")
        @Size(max = 255, message = "Description must not exceed 255 characters")
        String description,

        @NotNull(message = "Quantity is required")
        @Positive(message = "Quantity must be positive")
        Integer quantity,

        @NotNull(message = "Unit price is required")
        @PositiveOrZero(message = "Unit price must not be negative")
        BigDecimal unitPrice
) {}
```

### Response DTOs

```java
@Builder
public record InvoiceResponse(
        UUID id,
        String invoiceNumber,
        UUID customerId,
        String customerName,
        InvoiceStatus status,
        BigDecimal totalAmount,
        List<LineItemResponse> lineItems,
        String notes,
        Instant createdAt,
        Instant updatedAt
) {}

@Builder
public record InvoiceSummaryResponse(
        UUID id,
        String invoiceNumber,
        String customerName,
        InvoiceStatus status,
        BigDecimal totalAmount,
        Instant createdAt
) {}
```

### DTO Rules

- **Request and response DTOs are always separate.** Never reuse a DTO for both input and output.
- **Use Java records** for DTOs. They are immutable, concise, and automatically generate equals/hashCode/toString.
- **Use Lombok `@Builder` on records with more than two properties.** Records with three or more components must be annotated with `@Builder` to improve readability at construction sites. Records with one or two properties use their canonical constructor directly. Exception: records annotated with `@ConfigurationProperties` do not require `@Builder` as Spring handles their instantiation.
- **Create purpose-specific response DTOs.** A list endpoint returning `InvoiceSummaryResponse` with fewer fields is better than returning the full `InvoiceResponse` with fields the caller does not need.
- **Never expose entity IDs that the client should not use.** If the client does not need `tenantId`, do not include it in the response.
- **Validation messages are explicit.** Every `@NotNull`, `@NotBlank`, `@Size` has a `message` attribute with a human-readable error description.

### Manual DTO Mapping

Mapping methods live in a `Mapper` class within the feature package. Use static methods.

```java
public final class InvoiceMapper {

    private InvoiceMapper() {}

    public static InvoiceResponse toResponse(Invoice invoice) {
        return InvoiceResponse.builder()
                .id(invoice.getId())
                .invoiceNumber(invoice.getInvoiceNumber())
                .customerId(invoice.getCustomer().getId())
                .customerName(invoice.getCustomer().getName())
                .status(invoice.getStatus())
                .totalAmount(invoice.getTotalAmount())
                .lineItems(invoice.getLineItems().stream()
                        .map(InvoiceMapper::toLineItemResponse)
                        .toList())
                .notes(invoice.getNotes())
                .createdAt(invoice.getCreatedAt())
                .updatedAt(invoice.getUpdatedAt())
                .build();
    }

    public static InvoiceSummaryResponse toSummaryResponse(Invoice invoice) {
        return InvoiceSummaryResponse.builder()
                .id(invoice.getId())
                .invoiceNumber(invoice.getInvoiceNumber())
                .customerName(invoice.getCustomer().getName())
                .status(invoice.getStatus())
                .totalAmount(invoice.getTotalAmount())
                .createdAt(invoice.getCreatedAt())
                .build();
    }

    public static LineItemResponse toLineItemResponse(InvoiceLineItem item) {
        return LineItemResponse.builder()
                .id(item.getId())
                .description(item.getDescription())
                .quantity(item.getQuantity())
                .unitPrice(item.getUnitPrice())
                .amount(item.getAmount())
                .build();
    }
}
```

**Mapping rules:**
- No mapping frameworks (MapStruct, ModelMapper, etc.). Manual mapping is explicit, debuggable, and has zero magic.
- Mapper classes are `final` with a private constructor. All methods are `static`.
- One mapper class per feature, named `{Feature}Mapper`.
- Mapping methods are named `toResponse`, `toSummaryResponse`, `toEntity` (when converting request DTOs to entities).
- When the target record has `@Builder`, prefer the builder pattern over the canonical constructor for readability.
- If mapping is complex (requires additional service lookups or computed fields), move that logic to the service layer and pass the pre-computed values to the mapper.

---

## Configuration Management

### application.properties Structure

```properties
# application.properties
spring.application.name=my-service
spring.profiles.active=${SPRING_PROFILES_ACTIVE:local}
```

```properties
# application-local.properties
server.port=8080
logging.level.com.example.app=DEBUG
```

```properties
# application-prod.properties
logging.level.com.example.app=INFO
logging.level.root=WARN
```

### Configuration Rules

- Use `application.properties`. Use profile-specific files (`application-local.properties`, `application-prod.properties`) for environment overrides.
- Externalise all secrets and environment-specific values. Use environment variables in production.
- Never commit secrets to version control. Use `.env` files locally (gitignored) and environment variables or secrets managers in production.
- Database-specific configuration (connection details, dialect, migration tools) is provided by the database layer.
- Define configurable values (URLs, credentials, paths) in `application.properties` and reference them in `@Configuration` classes using `@Value`.
- Use `@Value` in constructors with private final properties, not on class properties directly.
- Do not use static constants for configurable values. All configuration should flow through `application.properties`.
- Use environment variable defaults in `application.properties` where appropriate: `mysql.url=${DATASOURCE_URL:jdbc:mysql://localhost:3306/db}`
- Use `@EnableConfigurationProperties` for shared properties. Define a `@ConfigurationProperties` class for type-safe, reusable configuration.

---

## Exception Handling

### ControllerExceptionHandler

```java
@ControllerAdvice
@Slf4j
public class ControllerExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(ErrorResponse.of(ex.getErrorCode(), ex.getMessage()));
    }

    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidation(ValidationException ex) {
        log.warn("Validation failed: {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ErrorResponse.of(ex.getErrorCode(), ex.getMessage(), ex.getDetails()));
    }

    @ExceptionHandler(BusinessRuleException.class)
    public ResponseEntity<ErrorResponse> handleBusinessRule(BusinessRuleException ex) {
        log.warn("Business rule violation: {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ErrorResponse.of(ex.getErrorCode(), ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleBeanValidation(MethodArgumentNotValidException ex) {
        List<ErrorDetail> details = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> new ErrorDetail(fe.getField(), fe.getDefaultMessage()))
                .toList();
        log.warn("Bean validation failed: {} errors", details.size());
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ErrorResponse.of("VALIDATION_FAILED", "Request validation failed", details));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ErrorResponse.of("INTERNAL_ERROR", "An unexpected error occurred"));
    }
}
```

### Custom Exception Hierarchy

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

---

## Testing Patterns for Spring Boot

### Test Structure

```
src/test/java/com/example/app/
├── billing/
│   ├── BillingControllerTest.java      # MockMvc integration tests
│   ├── BillingServiceTest.java         # Service unit/integration tests
│   ├── InvoiceMapperTest.java          # Mapper unit tests
│   └── BillingTestFixtures.java        # Test data builders
├── customer/
│   └── ...
```

### Controller Tests (MockMvc)

```java
@WebMvcTest(BillingController.class)
@Import(SecurityTestConfig.class)
class BillingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private BillingService billingService;

    @Test
    void createInvoice_withValidRequest_returnsCreated() throws Exception {
        // given
        CreateInvoiceRequest request = BillingTestFixtures.createInvoiceRequest();
        InvoiceResponse response = BillingTestFixtures.invoiceResponse();
        when(billingService.createInvoice(any(), any())).thenReturn(response);

        // when // then
        mockMvc.perform(post("/api/v1/invoices")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .with(jwt().jwt(j -> j.claim("tenant_id", "tenant-1"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.invoiceNumber").value(response.invoiceNumber()))
                .andExpect(jsonPath("$.status").value("DRAFT"));
    }

    @Test
    void createInvoice_withMissingCustomerId_returnsBadRequest() throws Exception {
        // given
        String invalidRequest = """
                { "lineItems": [{ "description": "Item", "quantity": 1, "unitPrice": 10.00 }] }
                """;

        // when // then
        mockMvc.perform(post("/api/v1/invoices")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidRequest)
                        .with(jwt().jwt(j -> j.claim("tenant_id", "tenant-1"))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }
}
```

### Service Tests

```java
@ExtendWith(MockitoExtension.class)
class BillingServiceTest {

    @Mock
    private InvoiceRepository invoiceRepository;

    @Mock
    private CustomerService customerService;

    @InjectMocks
    private BillingService billingService;

    @Test
    void createInvoice_withValidData_persistsAndReturnsInvoice() {
        // given
        Customer customer = BillingTestFixtures.customer("tenant-1");
        CreateInvoiceRequest request = BillingTestFixtures.createInvoiceRequest(customer.getId());
        when(customerService.getCustomerEntity(any(), any())).thenReturn(customer);
        when(invoiceRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        // when
        InvoiceResponse result = billingService.createInvoice(request, "tenant-1");

        // then
        assertNotNull(result.invoiceNumber());
        assertEquals(InvoiceStatus.DRAFT, result.status());
        assertEquals(0, new BigDecimal("150.00").compareTo(result.totalAmount()));
    }

    @Test
    void payInvoice_whenAlreadyPaid_throwsBusinessRuleException() {
        // given
        Invoice invoice = BillingTestFixtures.paidInvoice("tenant-1");
        when(invoiceRepository.findByIdAndTenantId(any(), any())).thenReturn(Optional.of(invoice));

        // when // then
        assertThrows(InvoiceAlreadyPaidException.class,
                () -> billingService.payInvoice(invoice.getId(), "tenant-1"));
    }
}
```

### Test Fixtures

```java
public final class BillingTestFixtures {

    private BillingTestFixtures() {}

    public static Customer customer(String tenantId) {
        Customer customer = new Customer();
        customer.setName("Test Customer");
        customer.setEmail("test@example.com");
        customer.setTenantId(tenantId);
        return customer;
    }

    public static CreateInvoiceRequest createInvoiceRequest(UUID customerId) {
        return CreateInvoiceRequest.builder()
                .customerId(customerId)
                .lineItems(List.of(LineItemRequest.builder()
                        .description("Test Item")
                        .quantity(3)
                        .unitPrice(new BigDecimal("50.00"))
                        .build()))
                .notes("Test notes")
                .build();
    }

    public static CreateInvoiceRequest createInvoiceRequest() {
        return createInvoiceRequest(UUID.randomUUID());
    }

    public static InvoiceResponse invoiceResponse() {
        return InvoiceResponse.builder()
                .id(UUID.randomUUID())
                .invoiceNumber("INV-2025-001")
                .customerId(UUID.randomUUID())
                .customerName("Test Customer")
                .status(InvoiceStatus.DRAFT)
                .totalAmount(new BigDecimal("150.00"))
                .lineItems(List.of())
                .notes("Test notes")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }
}
```

### Testing Rules

- Use `@WebMvcTest` for controller tests — fast, focused, mock the service layer.
- `MockMvc` must be imported from `org.springframework.test.web.servlet.MockMvc` (Spring Boot 4+).
- Use `@ExtendWith(MockitoExtension.class)` with `@Mock` and `@InjectMocks` for service unit tests.
- Repository test patterns (annotations, test containers, database setup) are defined by the database layer.
- Use JUnit Jupiter assertions (`assertEquals`, `assertThrows`, etc.) instead of AssertJ (`assertThat`).
- Use the `BillingTestFixtures` pattern for every feature — centralised, reusable test data construction.
- Do not run backend tests if no backend code changes.
- TDD where possible. Write unit tests that build out production code incrementally. Aim for 100% test coverage with unit tests in all packages except config packages.

### Integration Tests

- Do not use `application-test.properties`. Use `@DynamicPropertySource` in an `AbstractIT` class that serves as the parent for all integration tests.
- Use only one `<Domain>ControllerIT.java` integration test class per domain. Do not create multiple integration test classes per package (e.g., no separate `RepositoryIT` classes).
- For anything other than the controller integration test, write unit tests with mocked dependencies.
- `MainIT` should never extend `AbstractIT`. It tests application startup and health endpoints, not database functionality.

### Database State

- Reset the database before each test to ensure test isolation. Use `@Sql` annotation on `AbstractIT` to run a truncation script before each test method.
- Place the truncation script at `src/test/resources/truncate-tables.sql`.
- Disable foreign key checks during truncation, then re-enable them afterward.

### JSON Verification

- Use `.json` files for expected request and response bodies instead of inline JSON strings.
- Place JSON files in `src/test/resources/` mirroring the test package structure.

---

## Spring Security with OAuth2/JWT

### Security Configuration

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                .requestMatchers("/api/v1/**").authenticated()
                .anyRequest().denyAll())
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthConverter())));

        return http.build();
    }

    private JwtAuthenticationConverter jwtAuthConverter() {
        JwtGrantedAuthoritiesConverter authoritiesConverter = new JwtGrantedAuthoritiesConverter();
        authoritiesConverter.setAuthoritiesClaimName("realm_access.roles");
        authoritiesConverter.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(authoritiesConverter);
        return converter;
    }
}
```

### Security Rules

- Stateless sessions only. No server-side session storage.
- CSRF disabled for stateless API (JWT in Authorization header).
- Default deny — explicit allow only for known endpoints.
- Health and info endpoints are public. Everything under `/api/` requires authentication.
- Extract tenant ID from the JWT token claims. Never accept tenant ID as a request parameter.
- Use `@PreAuthorize` for endpoint-level authorization when roles are needed.

---

## Actuator and Health Checks

```properties
management.endpoints.web.exposure.include=health, info, metrics, prometheus
management.endpoint.health.show-details=when-authorized
management.health.db.enabled=false
management.health.diskspace.enabled=true
```

- Expose only necessary actuator endpoints.
- Health check shows details only to authenticated users.
- Database health checks are disabled by default. Database layers override `management.health.db.enabled` to `true`.
- Add custom health indicators for critical dependencies (Kafka connectivity, external API availability).
- Expose Prometheus metrics endpoint for monitoring.

---

## Multi-Tenancy Implementation

### Tenant Resolution

```java
@Component
public class TenantInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken jwt) {
            String tenantId = jwt.getToken().getClaimAsString("tenant_id");
            TenantContext.setCurrentTenant(tenantId);
        }
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request,
                                HttpServletResponse response,
                                Object handler, Exception ex) {
        TenantContext.clear();
    }
}
```

### TenantContext

```java
public final class TenantContext {

    private static final ThreadLocal<String> CURRENT_TENANT = new ThreadLocal<>();

    private TenantContext() {}

    public static String getCurrentTenant() {
        return CURRENT_TENANT.get();
    }

    public static void setCurrentTenant(String tenantId) {
        CURRENT_TENANT.set(tenantId);
    }

    public static void clear() {
        CURRENT_TENANT.remove();
    }
}
```

### Multi-Tenancy Rules

- Tenant ID comes from the JWT token only. Never from request parameters, headers, or path variables.
- Every data access operation includes a tenant filter. The database layer specifies how tenant filtering is applied.
- Every domain object includes a `tenantId` field.
- Test with multiple tenants in integration tests to verify data isolation.
- Tenant context is set in an interceptor and cleared after the request completes. Always clear to prevent thread-local leakage.

