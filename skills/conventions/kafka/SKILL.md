---
name: kafka-conventions
description: Apache Kafka integration conventions for Spring Boot — topic naming, event envelope, producer/consumer patterns, error handling, DLT, schema management, testing
user-invocable: false
paths: "**/*.java,**/pom.xml,**/application*.properties,**/application*.yml"
---

# Kafka Technical Standards

Apache Kafka integration in Spring Boot applications. See [producer-consumer.md](producer-consumer.md) for full code examples.

---

## Project Organisation

Kafka code lives within feature packages alongside the business logic it serves. Do not create a separate `kafka` or `messaging` top-level package.

```
com.example.app/
├── billing/
│   ├── BillingService.java
│   ├── InvoiceCreatedEvent.java        # Event DTO
│   ├── InvoiceEventProducer.java       # Produces billing events
│   └── PaymentReceivedConsumer.java    # Consumes payment events
├── common/
│   ├── kafka/
│   │   ├── KafkaErrorHandler.java
│   │   ├── DeadLetterPublisher.java
│   │   └── EventEnvelope.java
└── config/
    ├── KafkaProducerConfig.java
    ├── KafkaConsumerConfig.java
    └── KafkaTopicConfig.java
```

- **Producers live in the feature that owns the event.** `InvoiceEventProducer` in `billing/`.
- **Consumers live in the feature that acts on the event.**
- **Shared Kafka infrastructure** (error handlers, DLT publisher, base config) lives in `common/kafka/`.
- **Event DTOs live in the producing feature's package.** Consuming features import from there.

---

## Topic Naming

```
{domain}.{entity}.{event-type}

billing.invoice.created
billing.invoice.paid
payment.payment.received
customer.customer.registered
```

- **Three-part names**: domain, entity, event type. All lowercase, dot-separated.
- **Past tense** for event types: `created`, `updated`, `deleted`, `paid`, `failed`.
- **Dead letter**: Append `.dlt` — `billing.invoice.created.dlt`.
- **Retry**: Append `.retry.{n}` — `billing.invoice.created.retry.1`.
- Environment prefix in configuration, not in topic names.

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

- Default 6 partitions. 30-day retention for regular topics, 90-day for DLT.

---

## Event Envelope

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
                UUID.randomUUID().toString(), eventType, tenantId,
                Instant.now(), "my-service", payload);
    }
}
```

Every event includes `eventId` (UUID), `eventType`, `tenantId`, `timestamp`, `source`. `eventId` enables idempotent processing.

---

## Producer Rules

- **Use entity ID as message key.** Ensures all events for the same entity go to the same partition.
- **Enable idempotent producer** (`enable.idempotence=true`). Prevents duplicates on retry.
- **`acks=all`** for durability.
- **Serialize as JSON strings.** `StringSerializer` with Jackson `ObjectMapper`.
- **Log success and failure.** Always log event ID, entity ID, tenant ID.
- **Produce events after transaction commits.** Use `@TransactionalEventListener(phase = AFTER_COMMIT)`. Never produce inside a transaction that might roll back.

---

## Consumer Rules

- **Disable auto-commit.** `RECORD` ack mode for per-record acknowledgement.
- **`earliest` offset reset.** New consumer groups process from the beginning.
- **Consumer group ID format**: `{service-name}-{topic-description}`.
- **Make consumers idempotent.** Use `eventId` to detect and skip duplicates. Store processed IDs in the same transaction as the business operation.
- **Throw exceptions for unrecoverable errors.** Let the error handler route to DLT.
- **Log at entry and exit.** Key/partition/offset on receipt; eventId/entity IDs on completion.

---

## Error Handling Rules

- **Retry transient failures.** Network timeouts, DB connection issues — 3 retries with 1-second intervals.
- **Do not retry permanent failures.** Deserialization errors, validation errors route directly to DLT.
- **DLT headers.** Original topic, exception class, exception message, timestamp.
- **Monitor DLT topics.** Set up alerts for any DLT arrivals.

---

## Schema Management

- **Event DTOs are the schema.** Java records define structure. Jackson handles serialisation.
- **Events are immutable.** Never remove or rename fields from published events.
- **Additive changes only.** Add new optional fields. Configure Jackson with `FAIL_ON_UNKNOWN_PROPERTIES = false`.
- **Version for breaking changes.** Create `billing.invoice.created.v2`. Produce both during migration.

---

## Testing Rules

- **`@EmbeddedKafka`** for integration tests — in-process broker, no Docker needed.
- **TestContainers** for tests needing full Kafka features (schema registry, multiple brokers).
- **Test the full flow**: produce a message, let consumer process, assert on business outcome.
- **Awaitility for async assertions.** Never `Thread.sleep`.
- **Test error paths.** Publish malformed message, verify it lands in DLT.
- **Test idempotency.** Publish same event twice, verify business operation applied once.

---

## Local Development

Use KRaft mode Kafka (no ZooKeeper) with Kafka UI for topic inspection. Set replication factor to 1 locally. See [producer-consumer.md](producer-consumer.md) for Docker Compose configuration.
