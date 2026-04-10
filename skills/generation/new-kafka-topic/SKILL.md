---
name: new-kafka-topic
description: Set up a new Kafka topic — event DTO, producer, consumer, topic configuration bean, DLT, and integration tests
argument-hint: "[topic: billing.invoice.created] [producer-feature: billing] [consumer-feature: notification] [payload fields and processing logic]"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob
---

# Set Up New Kafka Topic

Create all code needed for a new Kafka topic: event DTO, producer, consumer, topic configuration, and tests.

## Required Input

Use `$ARGUMENTS` to determine:
- **Topic name**: Following the convention `{domain}.{entity}.{event-type}` (e.g., `billing.invoice.created`)
- **Event payload**: Fields with types for the event DTO
- **Producer location**: Which feature package produces this event
- **Consumer location**: Which feature package consumes this event
- **Processing logic**: What the consumer should do when it receives the event

Read the existing Kafka configuration to understand what already exists before generating.

## Files to Generate

### 1. Event DTO (`{EventName}Event.java`)

- Java record in the producing feature's package.
- Include all event payload fields.
- Static factory method `from({Entity} entity)` for constructing from the source entity.

### 2. Topic Configuration (modify `KafkaTopicConfig.java`)

- Add a `NewTopic` bean for the main topic.
- Add a `NewTopic` bean for the DLT topic (`{topic}.dlt`).
- Main topic: 6 partitions, 3 replicas, 30-day retention.
- DLT topic: 1 partition, 3 replicas, 90-day retention.

### 3. Producer (`{Entity}EventProducer.java`)

- In the producing feature's package.
- Inject `KafkaTemplate<String, String>` and `ObjectMapper`.
- Method named `publish{EventName}({Entity} entity, String tenantId)`.
- Use entity ID as message key.
- Wrap payload in `EventEnvelope`.
- Log success and failure callbacks with event ID, entity ID, and tenant ID.

### 4. Consumer (`{EventName}Consumer.java`)

- In the consuming feature's package.
- `@KafkaListener` with topic name and consumer group ID.
- Consumer group ID: `${spring.application.name}-{topic-description}`.
- Deserialise `EventEnvelope` from the record value.
- Call the appropriate service method with the event payload.
- Log at entry (key, partition, offset) and exit (event ID, entity IDs).
- Throw exceptions for unrecoverable errors to trigger DLT routing.

### 5. Producer Test

- Verify correct topic, key, and payload structure using `@SpyBean`.
- Verify the event envelope contains correct metadata.

### 6. Consumer Integration Test

- Use `@EmbeddedKafka`.
- Publish a test event and assert the business outcome.
- Use Awaitility for async assertions.
- Test error path: publish a malformed message, verify DLT routing.

### 7. Application Configuration

- Add topic to the relevant Spring profile configuration.
- Include consumer group ID configuration.

## Output Format

Generate each file completely. For modifications to existing files, show the additions with context for placement.
