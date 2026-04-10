# Controller Patterns, DTOs, and Mapper

## Controller Design

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

## Controller Rules

- **URL naming**: Plural nouns. `/api/v1/invoices`. Nested resources for strong ownership: `/api/v1/customers/{customerId}/invoices`.
- **API versioning**: URL path versioning (`/api/v1/`). Bump only for breaking changes.
- **HTTP methods**: `GET` reads, `POST` creates, `PUT` full updates, `PATCH` partial, `DELETE` deletes. `POST` for actions: `POST /api/v1/invoices/{id}/pay`.
- **Status codes**: `200` reads/updates, `201` creates, `204` deletes, `400` validation, `404` not found, `422` business rule violations.
- **No business logic in controllers.** Validate input (`@Valid`), extract tenant, call service, return response. Nothing else.
- **Pagination**: Default page 20, max 100. Return `PageResponse` wrapper.
- **Every endpoint** has `@Operation`, `@Tag`, `@ApiResponse`.
- **Do not use `@RequestMapping` above controller classes.** Full paths in each method annotation.

## ControllerExceptionHandler

```java
@ControllerAdvice
@Slf4j
public class ControllerExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ErrorResponse.of(ex.getErrorCode(), ex.getMessage()));
    }

    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidation(ValidationException ex) {
        log.warn("Validation failed: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ErrorResponse.of(ex.getErrorCode(), ex.getMessage(), ex.getDetails()));
    }

    @ExceptionHandler(BusinessRuleException.class)
    public ResponseEntity<ErrorResponse> handleBusinessRule(BusinessRuleException ex) {
        log.warn("Business rule violation: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ErrorResponse.of(ex.getErrorCode(), ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleBeanValidation(MethodArgumentNotValidException ex) {
        List<ErrorDetail> details = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> new ErrorDetail(fe.getField(), fe.getDefaultMessage()))
                .toList();
        log.warn("Bean validation failed: {} errors", details.size());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ErrorResponse.of("VALIDATION_FAILED", "Request validation failed", details));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ErrorResponse.of("INTERNAL_ERROR", "An unexpected error occurred"));
    }
}
```

---

## DTO Patterns

### Request DTOs

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
- **Java records** for all DTOs. Immutable, concise, auto equals/hashCode/toString.
- **`@Builder` on records with 3+ properties.** Records with 1-2 properties use canonical constructor directly. Exception: `@ConfigurationProperties` records.
- **Purpose-specific response DTOs.** List endpoints use `SummaryResponse` with fewer fields.
- **Never expose fields the client should not use** (e.g., `tenantId` in responses unless needed).
- **Every validation annotation has a `message` attribute.**

---

## Manual DTO Mapping

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
}
```

**Mapping rules:**
- No mapping frameworks (MapStruct, ModelMapper). Manual mapping is explicit and debuggable.
- Mapper classes are `final` with a private constructor. All methods are `static`.
- One mapper per feature: `{Feature}Mapper`.
- Methods named `toResponse`, `toSummaryResponse`, `toEntity`.
- If mapping requires service lookups or computed fields, do that in the service and pass pre-computed values.
