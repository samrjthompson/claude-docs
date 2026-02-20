# Kafka Technical Standards

This layer defines conventions and patterns for Apache Kafka integration in Spring Boot applications. It covers producer and consumer patterns, topic naming, schema management, error handling, and testing.

---

## Project Organisation

Kafka-related code lives within feature packages alongside the business logic it serves. Do not create a separate `kafka` or `messaging` top-level package.

```
com.example.app/
├── billing/
│   ├── BillingService.java
│   ├── InvoiceCreatedEvent.java        # Event DTO
│   ├── InvoiceEventProducer.java       # Produces billing events
│   ├── PaymentReceivedConsumer.java    # Consumes payment events
│   └── ...
├── notification/
│   ├── NotificationConsumer.java       # Consumes events from multiple topics
│   ├── NotificationService.java
│   └── ...
├── common/
│   ├── kafka/
│   │   ├── KafkaErrorHandler.java      # Shared error handling
│   │   ├── DeadLetterPublisher.java    # Dead letter topic producer
│   │   └── EventEnvelope.java          # Standard event wrapper
│   └── ...
└── config/
    ├── KafkaProducerConfig.java
    ├── KafkaConsumerConfig.java
    └── KafkaTopicConfig.java
```

### Organisation Rules

- **Producers live in the feature that owns the event.** `InvoiceEventProducer` lives in `billing/` because billing owns the invoice lifecycle.
- **Consumers live in the feature that acts on the event.** `PaymentReceivedConsumer` lives in `billing/` if billing processes payments, or in `payment/` if payment owns that logic.
- **Shared Kafka infrastructure** (error handlers, dead letter publisher, base configuration) lives in `common/kafka/`.
- **Event DTOs live in the producing feature's package.** Consuming features import from the producer's package.

---

## Topic Naming Conventions

```
{domain}.{entity}.{event-type}

Examples:
billing.invoice.created
billing.invoice.paid
billing.invoice.overdue
payment.payment.received
payment.payment.failed
customer.customer.registered
customer.customer.updated
```

### Topic Naming Rules

- **Three-part names**: domain, entity, event type. All lowercase, dot-separated.
- **Past tense for event types**: `created`, `updated`, `deleted`, `paid`, `failed`. Events describe something that happened.
- **Prefix environment in configuration, not in topic names.** Use `${env}.billing.invoice.created` in configuration, not in code.
- **Dead letter topics**: Append `.dlt` suffix: `billing.invoice.created.dlt`.
- **Retry topics**: Append `.retry.{n}` suffix: `billing.invoice.created.retry.1`.

### Topic Configuration

```java
@Configuration
public class KafkaTopicConfig {

    @Bean
    public NewTopic invoiceCreatedTopic() {
        return TopicBuilder.name("billing.invoice.created")
                .partitions(6)
                .replicas(3)
                .config(TopicConfig.RETENTION_MS_CONFIG, String.valueOf(Duration.ofDays(30).toMillis()))
                .config(TopicConfig.CLEANUP_POLICY_CONFIG, TopicConfig.CLEANUP_POLICY_DELETE)
                .build();
    }

    @Bean
    public NewTopic invoiceCreatedDltTopic() {
        return TopicBuilder.name("billing.invoice.created.dlt")
                .partitions(1)
                .replicas(3)
                .config(TopicConfig.RETENTION_MS_CONFIG, String.valueOf(Duration.ofDays(90).toMillis()))
                .build();
    }
}
```

- **Define topics as Spring beans.** This ensures topics are created automatically in development and documents the expected configuration.
- **Set appropriate partition counts.** Default to 6 partitions for moderate throughput. Adjust based on consumer group parallelism needs.
- **Set retention explicitly.** Never rely on broker defaults. 30 days for regular topics, 90 days for DLT topics.

---

## Event Envelope

Wrap every event in a standard envelope:

```java
public record EventEnvelope<T>(
    String eventId,
    String eventType,
    String tenantId,
    Instant timestamp,
    String source,
    T payload
) {
    public static <T> EventEnvelope<T> of(String eventType, String tenantId, T payload) {
        return new EventEnvelope<>(
                UUID.randomUUID().toString(),
                eventType,
                tenantId,
                Instant.now(),
                "my-service",
                payload
        );
    }
}
```

### Envelope Rules

- Every event includes `eventId` (UUID), `eventType`, `tenantId`, `timestamp`, and `source` (producing service name).
- `eventId` enables idempotent processing. Consumers track processed event IDs to detect duplicates.
- `tenantId` is mandatory for multi-tenant filtering and routing.
- `source` identifies which service produced the event, critical for debugging in multi-service architectures.

---

## Producer Patterns

### Producer Implementation

```java
@Component
@Slf4j
public class InvoiceEventProducer {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    public InvoiceEventProducer(KafkaTemplate<String, String> kafkaTemplate,
                                 ObjectMapper objectMapper) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    public void publishInvoiceCreated(Invoice invoice, String tenantId) {
        InvoiceCreatedEvent event = InvoiceCreatedEvent.from(invoice);
        EventEnvelope<InvoiceCreatedEvent> envelope =
                EventEnvelope.of("billing.invoice.created", tenantId, event);

        String key = invoice.getId().toString();
        String value = serialize(envelope);

        kafkaTemplate.send("billing.invoice.created", key, value)
                .whenComplete((result, ex) -> {
                    if (ex != null) {
                        log.error("Failed to publish invoice.created event: invoiceId={}, tenantId={}",
                                invoice.getId(), tenantId, ex);
                    } else {
                        log.info("Published invoice.created event: invoiceId={}, tenantId={}, offset={}",
                                invoice.getId(), tenantId,
                                result.getRecordMetadata().offset());
                    }
                });
    }

    private String serialize(Object event) {
        try {
            return objectMapper.writeValueAsString(event);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Failed to serialize event", e);
        }
    }
}
```

### Producer Configuration

```java
@Configuration
public class KafkaProducerConfig {

    @Bean
    public ProducerFactory<String, String> producerFactory(KafkaProperties kafkaProperties) {
        Map<String, Object> props = new HashMap<>(kafkaProperties.buildProducerProperties());
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        props.put(ProducerConfig.RETRIES_CONFIG, 3);
        props.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 1);
        return new DefaultKafkaProducerFactory<>(props);
    }

    @Bean
    public KafkaTemplate<String, String> kafkaTemplate(
            ProducerFactory<String, String> producerFactory) {
        return new KafkaTemplate<>(producerFactory);
    }
}
```

### Producer Rules

- **Use entity ID as the message key.** This ensures all events for the same entity go to the same partition, preserving ordering per entity.
- **Enable idempotent producer** (`enable.idempotence=true`). This prevents duplicate messages on producer retries.
- **Use `acks=all`** for durability. The message is acknowledged only after all in-sync replicas have written it.
- **Serialize as JSON strings.** Use `StringSerializer` with Jackson `ObjectMapper`. This keeps the configuration simple and debugging easy.
- **Log success and failure callbacks.** Always log the event ID, entity ID, and tenant ID on both success and failure.
- **Produce events after the database transaction commits.** Use `@TransactionalEventListener(phase = AFTER_COMMIT)` or call the producer after the service method's transaction completes. Never produce events inside a transaction that might roll back.

---

## Consumer Patterns

### Consumer Implementation

```java
@Component
@Slf4j
public class PaymentReceivedConsumer {

    private final BillingService billingService;
    private final ObjectMapper objectMapper;

    public PaymentReceivedConsumer(BillingService billingService,
                                    ObjectMapper objectMapper) {
        this.billingService = billingService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(
            topics = "payment.payment.received",
            groupId = "${spring.application.name}-payment-received",
            containerFactory = "kafkaListenerContainerFactory"
    )
    public void handlePaymentReceived(ConsumerRecord<String, String> record) {
        log.info("Received payment.received event: key={}, partition={}, offset={}",
                record.key(), record.partition(), record.offset());

        try {
            EventEnvelope<PaymentReceivedEvent> envelope = objectMapper.readValue(
                    record.value(),
                    new TypeReference<EventEnvelope<PaymentReceivedEvent>>() {});

            billingService.processPayment(
                    envelope.payload().invoiceId(),
                    envelope.payload().amount(),
                    envelope.tenantId()
            );

            log.info("Processed payment.received event: eventId={}, invoiceId={}, tenantId={}",
                    envelope.eventId(),
                    envelope.payload().invoiceId(),
                    envelope.tenantId());

        } catch (Exception e) {
            log.error("Failed to process payment.received event: key={}, offset={}",
                    record.key(), record.offset(), e);
            throw e; // Let the error handler deal with it
        }
    }
}
```

### Consumer Configuration

```java
@Configuration
public class KafkaConsumerConfig {

    @Bean
    public ConsumerFactory<String, String> consumerFactory(KafkaProperties kafkaProperties) {
        Map<String, Object> props = new HashMap<>(kafkaProperties.buildConsumerProperties());
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);
        return new DefaultKafkaConsumerFactory<>(props);
    }

    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, String> kafkaListenerContainerFactory(
            ConsumerFactory<String, String> consumerFactory,
            KafkaErrorHandler errorHandler) {
        ConcurrentKafkaListenerContainerFactory<String, String> factory =
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory);
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.RECORD);
        factory.setCommonErrorHandler(errorHandler.defaultErrorHandler());
        return factory;
    }
}
```

### Consumer Rules

- **Disable auto-commit.** Use `RECORD` ack mode for per-record acknowledgement. This prevents data loss if the consumer crashes mid-batch.
- **Use `earliest` offset reset.** When a new consumer group starts, process from the beginning to avoid missing events.
- **Consumer group ID format**: `{service-name}-{topic-description}`. Example: `billing-service-payment-received`.
- **Make consumers idempotent.** Use the `eventId` from the envelope to detect and skip duplicates. Store processed event IDs in the database within the same transaction as the business operation.
- **Throw exceptions for unrecoverable errors.** Let the error handler route failed messages to the DLT. Do not swallow exceptions in consumers.
- **Log at entry and exit.** Log when a message is received (key, partition, offset) and when processing completes or fails (eventId, entity IDs).

---

## Error Handling and Dead Letter Topics

### Error Handler

```java
@Component
public class KafkaErrorHandler {

    @Bean
    public DefaultErrorHandler defaultErrorHandler(DeadLetterPublisher deadLetterPublisher) {
        DefaultErrorHandler errorHandler = new DefaultErrorHandler(
                deadLetterPublisher,
                new FixedBackOff(1000L, 3L) // 3 retries with 1s delay
        );

        // Do not retry on deserialization or validation errors
        errorHandler.addNotRetryableExceptions(
                JsonProcessingException.class,
                ValidationException.class,
                IllegalArgumentException.class
        );

        return errorHandler;
    }
}
```

### Dead Letter Publisher

```java
@Component
@Slf4j
public class DeadLetterPublisher implements ConsumerRecordRecoverer {

    private final KafkaTemplate<String, String> kafkaTemplate;

    public DeadLetterPublisher(KafkaTemplate<String, String> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    @Override
    public void accept(ConsumerRecord<?, ?> record, Exception exception) {
        String dltTopic = record.topic() + ".dlt";

        log.error("Sending record to DLT: topic={}, dltTopic={}, key={}, offset={}, error={}",
                record.topic(), dltTopic, record.key(), record.offset(),
                exception.getMessage());

        ProducerRecord<String, String> dltRecord = new ProducerRecord<>(
                dltTopic, null, record.key().toString(), record.value().toString());
        dltRecord.headers().add("original-topic", record.topic().getBytes());
        dltRecord.headers().add("exception-message", exception.getMessage().getBytes());
        dltRecord.headers().add("exception-class", exception.getClass().getName().getBytes());

        kafkaTemplate.send(dltRecord);
    }
}
```

### Error Handling Rules

- **Retry transient failures.** Network timeouts, database connection issues, and temporary unavailability warrant retries with backoff.
- **Do not retry permanent failures.** Deserialization errors, validation errors, and business rule violations will never succeed on retry. Route them directly to the DLT.
- **Fixed backoff for retries.** Use 3 retries with 1-second intervals for most consumers. Adjust for specific use cases.
- **Dead letter topics for unrecoverable failures.** After exhausting retries, publish to `{original-topic}.dlt` with original headers plus error context.
- **Include error metadata in DLT headers.** Original topic, exception class, exception message, and timestamp.
- **Monitor DLT topics.** Set up alerts for messages arriving in DLT topics. They represent processing failures that require investigation.

---

## Schema Management

### JSON Schema Approach

Use JSON as the serialisation format with documented schema contracts.

```java
// Event DTOs serve as the schema definition
public record InvoiceCreatedEvent(
    UUID invoiceId,
    String invoiceNumber,
    UUID customerId,
    BigDecimal totalAmount,
    String status,
    Instant createdAt
) {
    public static InvoiceCreatedEvent from(Invoice invoice) {
        return new InvoiceCreatedEvent(
                invoice.getId(),
                invoice.getInvoiceNumber(),
                invoice.getCustomer().getId(),
                invoice.getTotalAmount(),
                invoice.getStatus().name(),
                invoice.getCreatedAt()
        );
    }
}
```

### Schema Rules

- **Event DTOs are the schema.** Java records define the structure. Jackson handles serialisation.
- **Events are immutable.** Once published, the schema for a given event type is a contract. Never remove or rename fields.
- **Additive changes only.** Add new optional fields to events. Consumers ignore unknown fields (configure Jackson with `FAIL_ON_UNKNOWN_PROPERTIES = false`).
- **Version event types for breaking changes.** If you must make a breaking change, create a new event type: `billing.invoice.created.v2`. Produce both versions during a migration period.
- **Document events.** Maintain a catalogue of event types with their schemas, producers, and consumers. This can be a markdown file in the repository or a shared documentation site.

### Schema Registry (When Using Avro)

If the project uses Avro instead of JSON:

- Use Confluent Schema Registry.
- Register schemas automatically on producer startup.
- Use `BACKWARD` compatibility mode by default.
- Store `.avsc` files in `src/main/avro/` and generate Java classes with the Avro Maven plugin.

---

## Testing Kafka Producers and Consumers

### Producer Test

```java
@SpringBootTest
class InvoiceEventProducerTest {

    @Autowired
    private InvoiceEventProducer producer;

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @SpyBean
    private KafkaTemplate<String, String> spyKafkaTemplate;

    @Test
    void publishInvoiceCreated_sendsEventWithCorrectKeyAndTopic() {
        // Arrange
        Invoice invoice = BillingTestFixtures.invoice("tenant-1");

        // Act
        producer.publishInvoiceCreated(invoice, "tenant-1");

        // Assert
        verify(spyKafkaTemplate).send(
                eq("billing.invoice.created"),
                eq(invoice.getId().toString()),
                argThat(value -> {
                    EventEnvelope<?> envelope = objectMapper.readValue(value, EventEnvelope.class);
                    return envelope.tenantId().equals("tenant-1")
                            && envelope.eventType().equals("billing.invoice.created");
                })
        );
    }
}
```

### Consumer Test with Embedded Kafka

```java
@SpringBootTest
@EmbeddedKafka(
    partitions = 1,
    topics = {"payment.payment.received"},
    brokerProperties = {"listeners=PLAINTEXT://localhost:9092"}
)
class PaymentReceivedConsumerTest {

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @Autowired
    private InvoiceRepository invoiceRepository;

    @Test
    void handlePaymentReceived_updatesInvoiceStatus() throws Exception {
        // Arrange
        Invoice invoice = BillingTestFixtures.draftInvoice("tenant-1");
        invoiceRepository.save(invoice);

        PaymentReceivedEvent event = new PaymentReceivedEvent(
                invoice.getId(), invoice.getTotalAmount());
        EventEnvelope<PaymentReceivedEvent> envelope =
                EventEnvelope.of("payment.payment.received", "tenant-1", event);

        // Act
        kafkaTemplate.send("payment.payment.received",
                invoice.getId().toString(),
                objectMapper.writeValueAsString(envelope));

        // Assert — poll until the consumer processes the message
        await().atMost(Duration.ofSeconds(10)).untilAsserted(() -> {
            Invoice updated = invoiceRepository.findById(invoice.getId()).orElseThrow();
            assertThat(updated.getStatus()).isEqualTo(InvoiceStatus.PAID);
        });
    }
}
```

### Testing Rules

- **Use `@EmbeddedKafka` for integration tests.** It starts an in-process Kafka broker — no Docker needed for basic Kafka tests.
- **Use TestContainers for tests requiring full Kafka features** (schema registry, multiple brokers, specific broker configurations).
- **Test the full flow**: produce a message, let the consumer process it, and assert on the business outcome (database state change, outbound event produced).
- **Use Awaitility for async assertions.** Consumer processing is asynchronous. Poll with a timeout instead of using `Thread.sleep`.
- **Test error handling paths.** Publish a malformed message and verify it lands in the DLT.
- **Test idempotency.** Publish the same event twice and verify the business operation is applied only once.

---

## Local Development Setup

### Docker Compose for Kafka

```yaml
# docker-compose.yml
services:
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    ports:
      - "9092:9092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:29093
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:29093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      CLUSTER_ID: 'MkU3OEVBNTcwNTJENDM2Qk'

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    ports:
      - "8090:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092
    depends_on:
      - kafka
```

### Local Development Rules

- Use KRaft mode (no ZooKeeper) for Kafka 3.3+.
- Include Kafka UI for topic inspection and message browsing during development.
- Set replication factor to 1 in local development. Never in production.
- Application configuration for local development:

```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
    producer:
      acks: all
    consumer:
      auto-offset-reset: earliest
      enable-auto-commit: false
```
