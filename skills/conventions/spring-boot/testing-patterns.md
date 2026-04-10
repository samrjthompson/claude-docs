# Spring Boot Testing Patterns

## Test Structure

```
src/test/java/com/example/app/
├── billing/
│   ├── BillingControllerTest.java      # MockMvc tests
│   ├── BillingServiceTest.java         # Service tests
│   ├── InvoiceMapperTest.java          # Mapper unit tests
│   └── BillingTestFixtures.java        # Test data builders
```

## Controller Tests (MockMvc)

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

## Service Tests

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

## Test Fixtures

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

## Testing Rules

- Use `@WebMvcTest` for controller tests — fast, focused, mock the service layer.
- `MockMvc` from `org.springframework.test.web.servlet.MockMvc` (Spring Boot 4+).
- Use `@ExtendWith(MockitoExtension.class)` with `@Mock` and `@InjectMocks` for service unit tests.
- Use JUnit Jupiter assertions (`assertEquals`, `assertThrows`) instead of AssertJ (`assertThat`).
- Use `TestFixtures` pattern for every feature — centralised, reusable test data construction.
- TDD where possible. Aim for 100% test coverage with unit tests in all packages except config.
- Do not run backend tests if no backend code changes.

## Integration Tests

- Do not use `application-test.properties`. Use `@DynamicPropertySource` in `AbstractIT`.
- Use only one `<Domain>ControllerIT.java` per domain. No separate `RepositoryIT` classes.
- `MainIT` should never extend `AbstractIT`. It tests application startup and health endpoints only.

## Database State Reset

- Reset before each test. Use `@Sql` on `AbstractIT` to run a truncation script.
- Place truncation script at `src/test/resources/truncate-tables.sql`.
- Disable foreign key checks during truncation, then re-enable.

## JSON Verification

- Use `.json` files for expected request/response bodies instead of inline strings.
- Place JSON files in `src/test/resources/` mirroring the test package structure.
