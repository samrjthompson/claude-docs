# Spring Boot Technical Standards

This layer defines conventions and patterns for Spring Boot applications. It builds on the base engineering standards and specifies how those principles apply to Spring Boot projects.

These standards target Spring Boot 4+ with Java 21+, Maven, and Keycloak for authentication. Database and persistence concerns are provided by a separate database layer (e.g., `mysql`, `postgres`, `mongodb`).

---

## Package-by-Feature Organisation

### Example Package Structure

```
com.example.app/
├── Application.java
├── billing/
│   ├── BillingController.java
│   ├── BillingService.java
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
│   ├── Customer.java
│   ├── CreateCustomerRequest.java
│   ├── UpdateCustomerRequest.java
│   ├── CustomerResponse.java
│   ├── CustomerMapper.java
│   └── CustomerNotFoundException.java
├── common/
│   ├── ErrorResponse.java
│   ├── ErrorDetail.java
│   ├── GlobalExceptionHandler.java
│   ├── PageResponse.java
│   ├── TenantContext.java
│   └── TenantInterceptor.java
└── config/
    ├── SecurityConfig.java
    ├── WebConfig.java
    └── OpenApiConfig.java
```

### Feature Package Rules

Each feature package is self-contained. It holds every class needed for that feature to function:

- **Domain model classes** — Classes representing the feature's domain objects. Persistence annotations are defined by the database layer.
- **Repository interfaces** — Data access for the feature's domain objects. Defined by the database layer.
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

- `GlobalExceptionHandler` mapping exceptions to error responses.
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

`@Transactional` rollback in service tests depends on the persistence layer supporting Spring-managed transactions. Repository-level tests (annotations, test containers, database setup) are defined by the database layer.

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
- Repository test patterns (annotations, test containers, database setup) are defined by the database layer.
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
