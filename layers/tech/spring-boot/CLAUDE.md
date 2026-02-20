# Spring Boot Technical Standards

This layer defines conventions and patterns for Spring Boot applications. It builds on the base engineering standards and specifies how those principles apply to Spring Boot projects.

These standards target Spring Boot 4+ with Java 21+, Spring Data JPA, Flyway, Maven, and Keycloak for authentication.

---

## Package-by-Feature Organisation

### Example Package Structure

```
com.example.app/
├── Application.java
├── billing/
│   ├── BillingController.java
│   ├── BillingService.java
│   ├── InvoiceRepository.java
│   ├── Invoice.java
│   ├── InvoiceLineItem.java
│   ├── CreateInvoiceRequest.java
│   ├── UpdateInvoiceRequest.java
│   ├── InvoiceResponse.java
│   ├── InvoiceSummaryResponse.java
│   ├── InvoiceMapper.java
│   ├── InvoiceNotFoundException.java
│   ├── InvoiceAlreadyPaidException.java
│   └── InvoiceStatus.java
├── customer/
│   ├── CustomerController.java
│   ├── CustomerService.java
│   ├── CustomerRepository.java
│   ├── Customer.java
│   ├── CreateCustomerRequest.java
│   ├── UpdateCustomerRequest.java
│   ├── CustomerResponse.java
│   ├── CustomerMapper.java
│   └── CustomerNotFoundException.java
├── common/
│   ├── BaseEntity.java
│   ├── ErrorResponse.java
│   ├── ErrorDetail.java
│   ├── GlobalExceptionHandler.java
│   ├── PageResponse.java
│   ├── TenantContext.java
│   ├── TenantInterceptor.java
│   └── AuditingConfig.java
└── config/
    ├── SecurityConfig.java
    ├── JpaConfig.java
    ├── WebConfig.java
    ├── FlywayConfig.java
    └── OpenApiConfig.java
```

### Feature Package Rules

Each feature package is self-contained. It holds every class needed for that feature to function:

- **Entity classes** — JPA entities representing the feature's domain objects.
- **Repository interfaces** — Data access for the feature's entities.
- **Service class** — Business logic, transaction management, orchestration.
- **Controller class** — REST endpoints, request handling, response formatting.
- **Request DTOs** — Objects representing inbound API data, annotated with Bean Validation.
- **Response DTOs** — Objects representing outbound API data.
- **Mapper class** — Static methods converting between entities and DTOs.
- **Feature-specific exceptions** — Exceptions unique to this feature's error conditions.
- **Enums and value objects** — Feature-specific types.

A feature package never reaches into another feature's repository. Cross-feature communication goes through the other feature's service.

### Handling Shared Code

The `common` package holds genuinely cross-cutting concerns used across three or more features:

- `BaseEntity` with auditing fields.
- `GlobalExceptionHandler` mapping exceptions to error responses.
- `ErrorResponse` and `ErrorDetail` DTOs for consistent error formatting.
- `PageResponse` wrapper for paginated results.
- `TenantContext` and `TenantInterceptor` for multi-tenancy.

The `config` package holds Spring configuration classes:

- Security configuration.
- JPA/Hibernate configuration.
- Web MVC configuration.
- Flyway configuration.
- OpenAPI/Swagger configuration.

Do not put business logic in `common` or `config`. If a utility class contains business rules, it belongs in a feature package.

---

## Entity Design Patterns

### Base Entity

Every entity extends `BaseEntity`:

```java
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @CreatedDate
    @Column(name = "created_at", updatable = false, nullable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    @Column(name = "tenant_id", updatable = false, nullable = false)
    private String tenantId;

    // Getters only — no setters for id, createdAt, tenantId
}
```

**Rules:**
- Use UUID primary keys. Never use auto-increment integers. UUIDs are safe across distributed systems, prevent enumeration attacks, and simplify data migration.
- Use `Instant` for all timestamps. Never `LocalDateTime` — always store UTC.
- Use optimistic locking via `@Version` on every entity.
- Include `tenantId` on every entity for multi-tenancy filtering.
- Enable JPA auditing with `@EnableJpaAuditing` in configuration.

### Relationship Mapping

- **OneToMany/ManyToOne**: Always map the owning side (ManyToOne). Use `@ManyToOne(fetch = FetchType.LAZY)` — never `EAGER`. Define the inverse side only when you need to navigate the relationship from the parent.
- **ManyToMany**: Use a join table with an explicit entity when the relationship has attributes. Use `@ManyToMany` only for simple join tables with no additional columns.
- **Cascade**: Use `CascadeType.ALL` only for true parent-child compositions (e.g., Order → OrderLineItems where line items cannot exist without the order). Never cascade from child to parent.
- **Orphan removal**: Enable `orphanRemoval = true` on parent-side `@OneToMany` for composition relationships.

```java
@Entity
@Table(name = "invoices")
public class Invoice extends BaseEntity {

    @Column(name = "invoice_number", nullable = false, unique = true)
    private String invoiceNumber;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @OneToMany(mappedBy = "invoice", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<InvoiceLineItem> lineItems = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private InvoiceStatus status;

    @Column(name = "total_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal totalAmount;

    // Business methods on the entity for encapsulating invariants
    public void addLineItem(InvoiceLineItem item) {
        lineItems.add(item);
        item.setInvoice(this);
        recalculateTotal();
    }

    public void markAsPaid() {
        if (this.status == InvoiceStatus.PAID) {
            throw new InvoiceAlreadyPaidException(this.getId());
        }
        this.status = InvoiceStatus.PAID;
    }

    private void recalculateTotal() {
        this.totalAmount = lineItems.stream()
                .map(InvoiceLineItem::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
```

### Entity Rules

- Entities encapsulate their invariants. Validation that protects data integrity lives on the entity as business methods. The service layer calls these methods — it does not manipulate entity fields directly for complex operations.
- Use `@Enumerated(EnumType.STRING)` — never `EnumType.ORDINAL`. Ordinal breaks when enum values are reordered.
- Use `BigDecimal` for all monetary values. Specify `precision` and `scale` explicitly.
- Initialise collections inline: `private List<LineItem> lineItems = new ArrayList<>()`. Never leave collection fields null.
- Do not put JSON serialization annotations (`@JsonProperty`, `@JsonIgnore`) on entities. Entities never touch the API boundary.

---

## Repository Patterns

### When to Use Each Query Style

**Derived queries** — for simple queries with one or two conditions:
```java
public interface CustomerRepository extends JpaRepository<Customer, UUID> {
    Optional<Customer> findByEmailAndTenantId(String email, String tenantId);
    List<Customer> findByStatusAndTenantId(CustomerStatus status, String tenantId);
    boolean existsByEmailAndTenantId(String email, String tenantId);
}
```

**@Query annotation** — for queries with joins, aggregations, or complex WHERE clauses:
```java
@Query("""
    SELECT i FROM Invoice i
    JOIN FETCH i.customer
    WHERE i.tenantId = :tenantId
    AND i.status = :status
    AND i.createdAt >= :since
    ORDER BY i.createdAt DESC
    """)
List<Invoice> findRecentByStatus(
        @Param("tenantId") String tenantId,
        @Param("status") InvoiceStatus status,
        @Param("since") Instant since);
```

**Specifications** — for dynamic queries where the combination of filters varies at runtime (search endpoints, admin dashboards):
```java
public class InvoiceSpecifications {

    public static Specification<Invoice> withTenant(String tenantId) {
        return (root, query, cb) -> cb.equal(root.get("tenantId"), tenantId);
    }

    public static Specification<Invoice> withStatus(InvoiceStatus status) {
        return status == null ? null :
                (root, query, cb) -> cb.equal(root.get("status"), status);
    }

    public static Specification<Invoice> createdAfter(Instant since) {
        return since == null ? null :
                (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("createdAt"), since);
    }
}
```

### Repository Rules

- Every query method that returns entity data must filter by `tenantId`. No exceptions. This prevents cross-tenant data leakage.
- Return `Optional<T>` for single-entity lookups. Never return null.
- Use `@EntityGraph` or `JOIN FETCH` to prevent N+1 queries when you know the relationship will be accessed.
- Never return entities directly from repositories to controllers. Always pass through the service layer.
- Use `Page<T>` for list endpoints that could return large result sets.

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
- Class-level `@Transactional(readOnly = true)` as default. Override with `@Transactional` on mutating methods.
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
@RequestMapping("/api/v1/invoices")
@Tag(name = "Invoices", description = "Invoice management endpoints")
public class BillingController {

    private final BillingService billingService;

    public BillingController(BillingService billingService) {
        this.billingService = billingService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a new invoice")
    public InvoiceResponse createInvoice(
            @Valid @RequestBody CreateInvoiceRequest request,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.createInvoice(request, tenantId);
    }

    @GetMapping("/{invoiceId}")
    @Operation(summary = "Get invoice by ID")
    public InvoiceResponse getInvoice(
            @PathVariable UUID invoiceId,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.getInvoice(invoiceId, tenantId);
    }

    @GetMapping
    @Operation(summary = "List invoices with optional filters")
    public PageResponse<InvoiceSummaryResponse> listInvoices(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) InvoiceStatus status,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.listInvoices(page, size, status, tenantId);
    }

    @PutMapping("/{invoiceId}")
    @Operation(summary = "Update an existing invoice")
    public InvoiceResponse updateInvoice(
            @PathVariable UUID invoiceId,
            @Valid @RequestBody UpdateInvoiceRequest request,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.updateInvoice(invoiceId, request, tenantId);
    }

    @PostMapping("/{invoiceId}/pay")
    @Operation(summary = "Mark an invoice as paid")
    public InvoiceResponse payInvoice(
            @PathVariable UUID invoiceId,
            @AuthenticationPrincipal JwtAuthenticationToken principal) {
        String tenantId = extractTenantId(principal);
        return billingService.payInvoice(invoiceId, tenantId);
    }

    @DeleteMapping("/{invoiceId}")
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
- **No business logic in controllers.** Controllers validate input (via `@Valid`), extract the tenant, call the service, and return the response. Nothing else.
- **Pagination**: Default page size of 20, maximum of 100. Return pagination metadata in a `PageResponse` wrapper.
- **Annotate every endpoint** with OpenAPI `@Operation`, `@Tag`, `@ApiResponse` for documentation generation.

---

## DTO Patterns

### Request DTOs

Use Java records for immutability. Apply Bean Validation annotations directly.

```java
public record CreateInvoiceRequest(
        @NotNull(message = "Customer ID is required")
        UUID customerId,

        @NotEmpty(message = "At least one line item is required")
        @Valid
        List<LineItemRequest> lineItems,

        @Size(max = 500, message = "Notes must not exceed 500 characters")
        String notes
) {}

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
- **Create purpose-specific response DTOs.** A list endpoint returning `InvoiceSummaryResponse` with fewer fields is better than returning the full `InvoiceResponse` with fields the caller does not need.
- **Never expose entity IDs that the client should not use.** If the client does not need `tenantId`, do not include it in the response.
- **Validation messages are explicit.** Every `@NotNull`, `@NotBlank`, `@Size` has a `message` attribute with a human-readable error description.

### Manual DTO Mapping

Mapping methods live in a `Mapper` class within the feature package. Use static methods.

```java
public final class InvoiceMapper {

    private InvoiceMapper() {}

    public static InvoiceResponse toResponse(Invoice invoice) {
        return new InvoiceResponse(
                invoice.getId(),
                invoice.getInvoiceNumber(),
                invoice.getCustomer().getId(),
                invoice.getCustomer().getName(),
                invoice.getStatus(),
                invoice.getTotalAmount(),
                invoice.getLineItems().stream()
                        .map(InvoiceMapper::toLineItemResponse)
                        .toList(),
                invoice.getNotes(),
                invoice.getCreatedAt(),
                invoice.getUpdatedAt()
        );
    }

    public static InvoiceSummaryResponse toSummaryResponse(Invoice invoice) {
        return new InvoiceSummaryResponse(
                invoice.getId(),
                invoice.getInvoiceNumber(),
                invoice.getCustomer().getName(),
                invoice.getStatus(),
                invoice.getTotalAmount(),
                invoice.getCreatedAt()
        );
    }

    public static LineItemResponse toLineItemResponse(InvoiceLineItem item) {
        return new LineItemResponse(
                item.getId(),
                item.getDescription(),
                item.getQuantity(),
                item.getUnitPrice(),
                item.getAmount()
        );
    }
}
```

**Mapping rules:**
- No mapping frameworks (MapStruct, ModelMapper, etc.). Manual mapping is explicit, debuggable, and has zero magic.
- Mapper classes are `final` with a private constructor. All methods are `static`.
- One mapper class per feature, named `{Feature}Mapper`.
- Mapping methods are named `toResponse`, `toSummaryResponse`, `toEntity` (when converting request DTOs to entities).
- If mapping is complex (requires additional service lookups or computed fields), move that logic to the service layer and pass the pre-computed values to the mapper.

---

## Configuration Management

### application.yml Structure

```yaml
spring:
  application:
    name: my-service
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}

---
# Local development profile
spring:
  config:
    activate:
      on-profile: local
  datasource:
    url: jdbc:mysql://localhost:3306/mydb
    username: root
    password: local-password
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: validate
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  port: 8080

logging:
  level:
    com.example.app: DEBUG
    org.hibernate.SQL: DEBUG

---
# Production profile
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
  jpa:
    show-sql: false
    hibernate:
      ddl-auto: validate

logging:
  level:
    com.example.app: INFO
    root: WARN
```

### Configuration Rules

- Use `application.yml`, not `application.properties`. YAML is more readable for nested configuration.
- Profile-specific configuration in the same file using `---` separators and `spring.config.activate.on-profile`.
- Externalise all secrets and environment-specific values. Use environment variables in production: `${DATABASE_URL}`.
- Never commit secrets to version control. Use `.env` files locally (gitignored) and environment variables or secrets managers in production.
- Set `ddl-auto: validate` — always. Hibernate never creates or modifies schema. Flyway handles all schema changes.
- Use `@ConfigurationProperties` for custom configuration with type safety and validation.

---

## Exception Handling

### Global Exception Handler

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ErrorResponse handleNotFound(ResourceNotFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return ErrorResponse.of(ex.getErrorCode(), ex.getMessage());
    }

    @ExceptionHandler(ValidationException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleValidation(ValidationException ex) {
        log.warn("Validation failed: {}", ex.getMessage());
        return ErrorResponse.of(ex.getErrorCode(), ex.getMessage(), ex.getDetails());
    }

    @ExceptionHandler(BusinessRuleException.class)
    @ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
    public ErrorResponse handleBusinessRule(BusinessRuleException ex) {
        log.warn("Business rule violation: {}", ex.getMessage());
        return ErrorResponse.of(ex.getErrorCode(), ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleBeanValidation(MethodArgumentNotValidException ex) {
        List<ErrorDetail> details = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> new ErrorDetail(fe.getField(), fe.getDefaultMessage()))
                .toList();
        log.warn("Bean validation failed: {} errors", details.size());
        return ErrorResponse.of("VALIDATION_FAILED", "Request validation failed", details);
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ErrorResponse handleUnexpected(Exception ex) {
        log.error("Unexpected error", ex);
        return ErrorResponse.of("INTERNAL_ERROR", "An unexpected error occurred");
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

## Flyway Migration Conventions

### Naming

```
V{version}__{description}.sql

Examples:
V001__create_customers_table.sql
V002__create_invoices_table.sql
V003__add_status_column_to_invoices.sql
V004__create_invoice_line_items_table.sql
V005__seed_initial_roles.sql
```

- Version numbers: zero-padded three digits (`V001`, `V002`).
- Description: `snake_case`, descriptive of the change.
- Double underscore between version and description (Flyway convention).

### Migration Rules

- **Every schema change goes through Flyway.** No manual SQL, no Hibernate auto-DDL.
- **Migrations are immutable.** Once committed, never edit a migration. Create a new migration for corrections.
- **Separate schema migrations from data migrations.** Schema changes and data seeding are different migrations even if related.
- **Make migrations idempotent where possible.** Use `IF NOT EXISTS` for table and index creation.
- **Include rollback comments.** At the top of each migration, add a comment block showing the rollback SQL:

```sql
-- Migration: V003__add_status_column_to_invoices.sql
-- Rollback: ALTER TABLE invoices DROP COLUMN status;

ALTER TABLE invoices ADD COLUMN status VARCHAR(50) NOT NULL DEFAULT 'DRAFT';
CREATE INDEX idx_invoices_status ON invoices (status);
```

- **Foreign keys reference UUID columns:** `customer_id CHAR(36) NOT NULL`.
- **Always specify NOT NULL, defaults, and constraints** explicitly. Never rely on database defaults.

### Migration for Multi-Tenancy

When using schema-per-tenant, maintain two migration locations:

```yaml
spring:
  flyway:
    locations:
      - classpath:db/migration/common    # Shared schema (tenant registry)
      - classpath:db/migration/tenant    # Per-tenant schema
```

---

## Testing Patterns for Spring Boot

### Test Structure

```
src/test/java/com/example/app/
├── billing/
│   ├── BillingControllerTest.java      # MockMvc integration tests
│   ├── BillingServiceTest.java         # Service unit/integration tests
│   ├── InvoiceRepositoryTest.java      # Repository tests with TestContainers
│   ├── InvoiceMapperTest.java          # Mapper unit tests
│   └── BillingTestFixtures.java        # Test data builders
├── customer/
│   └── ...
└── TestContainersConfig.java           # Shared TestContainers configuration
```

### Controller Tests (MockMvc)

```java
@WebMvcTest(BillingController.class)
@Import(SecurityTestConfig.class)
class BillingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private BillingService billingService;

    @Test
    void createInvoice_withValidRequest_returnsCreated() throws Exception {
        // Arrange
        CreateInvoiceRequest request = BillingTestFixtures.createInvoiceRequest();
        InvoiceResponse response = BillingTestFixtures.invoiceResponse();
        when(billingService.createInvoice(any(), eq("tenant-1"))).thenReturn(response);

        // Act & Assert
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
        // Arrange
        String invalidRequest = """
                { "lineItems": [{ "description": "Item", "quantity": 1, "unitPrice": 10.00 }] }
                """;

        // Act & Assert
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
@SpringBootTest
@Transactional
class BillingServiceTest {

    @Autowired
    private BillingService billingService;

    @Autowired
    private CustomerRepository customerRepository;

    @Test
    void createInvoice_withValidData_persistsAndReturnsInvoice() {
        // Arrange
        Customer customer = BillingTestFixtures.customer("tenant-1");
        customerRepository.save(customer);

        CreateInvoiceRequest request = BillingTestFixtures.createInvoiceRequest(customer.getId());

        // Act
        InvoiceResponse result = billingService.createInvoice(request, "tenant-1");

        // Assert
        assertThat(result.invoiceNumber()).isNotBlank();
        assertThat(result.status()).isEqualTo(InvoiceStatus.DRAFT);
        assertThat(result.totalAmount()).isEqualByComparingTo("150.00");
    }

    @Test
    void payInvoice_whenAlreadyPaid_throwsBusinessRuleException() {
        // Arrange
        Invoice invoice = BillingTestFixtures.paidInvoice("tenant-1");
        // ... persist invoice

        // Act & Assert
        assertThatThrownBy(() -> billingService.payInvoice(invoice.getId(), "tenant-1"))
                .isInstanceOf(InvoiceAlreadyPaidException.class);
    }
}
```

### Repository Tests

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class InvoiceRepositoryTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("testdb");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
    }

    @Autowired
    private InvoiceRepository invoiceRepository;

    @Test
    void findRecentByStatus_returnsOnlyMatchingTenantAndStatus() {
        // Arrange — persist test data

        // Act
        List<Invoice> results = invoiceRepository.findRecentByStatus(
                "tenant-1", InvoiceStatus.DRAFT, Instant.now().minus(30, ChronoUnit.DAYS));

        // Assert
        assertThat(results).allSatisfy(invoice -> {
            assertThat(invoice.getTenantId()).isEqualTo("tenant-1");
            assertThat(invoice.getStatus()).isEqualTo(InvoiceStatus.DRAFT);
        });
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
        return new CreateInvoiceRequest(
                customerId,
                List.of(new LineItemRequest("Test Item", 3, new BigDecimal("50.00"))),
                "Test notes"
        );
    }

    public static CreateInvoiceRequest createInvoiceRequest() {
        return createInvoiceRequest(UUID.randomUUID());
    }

    public static InvoiceResponse invoiceResponse() {
        return new InvoiceResponse(
                UUID.randomUUID(),
                "INV-2025-001",
                UUID.randomUUID(),
                "Test Customer",
                InvoiceStatus.DRAFT,
                new BigDecimal("150.00"),
                List.of(),
                "Test notes",
                Instant.now(),
                Instant.now()
        );
    }
}
```

### Testing Rules

- Use `@WebMvcTest` for controller tests — fast, focused, mock the service layer.
- Use `@SpringBootTest` with `@Transactional` for service integration tests — test real service + repository interactions with automatic rollback.
- Use `@DataJpaTest` with TestContainers for repository tests — test real SQL against a real database.
- Use TestContainers for MySQL. Never use H2 for tests — dialect differences cause false positives.
- Use AssertJ for assertions. It is more readable and expressive than JUnit's built-in assertions.
- Use the `BillingTestFixtures` pattern for every feature — centralised, reusable test data construction.

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

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics, prometheus
  endpoint:
    health:
      show-details: when-authorized
  health:
    db:
      enabled: true
    diskspace:
      enabled: true
```

- Expose only necessary actuator endpoints.
- Health check shows details only to authenticated users.
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

### Schema-per-Tenant Routing

For schema-per-tenant architecture, implement a `TenantAwareDataSource` that routes to the correct schema based on `TenantContext`:

```java
public class TenantRoutingDataSource extends AbstractRoutingDataSource {

    @Override
    protected Object determineCurrentLookupKey() {
        return TenantContext.getCurrentTenant();
    }
}
```

### Multi-Tenancy Rules

- Tenant ID comes from the JWT token only. Never from request parameters, headers, or path variables.
- Every database query includes a tenant filter. Use a Hibernate filter or explicit WHERE clause.
- Every entity includes a `tenant_id` column.
- Test with multiple tenants in integration tests to verify data isolation.
- Tenant context is set in an interceptor and cleared after the request completes. Always clear to prevent thread-local leakage.
