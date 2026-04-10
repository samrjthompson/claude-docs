# Producer and Consumer Implementation Examples

## Producer Implementation

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
                        log.error("Failed to publish invoice.created: invoiceId={}, tenantId={}",
                                invoice.getId(), tenantId, ex);
                    } else {
                        log.info("Published invoice.created: invoiceId={}, tenantId={}, offset={}",
                                invoice.getId(), tenantId, result.getRecordMetadata().offset());
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

## Producer Configuration

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
    public KafkaTemplate<String, String> kafkaTemplate(ProducerFactory<String, String> producerFactory) {
        return new KafkaTemplate<>(producerFactory);
    }
}
```

---

## Consumer Implementation

```java
@Component
@Slf4j
public class PaymentReceivedConsumer {

    private final BillingService billingService;
    private final ObjectMapper objectMapper;

    public PaymentReceivedConsumer(BillingService billingService, ObjectMapper objectMapper) {
        this.billingService = billingService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(
            topics = "payment.payment.received",
            groupId = "${spring.application.name}-payment-received",
            containerFactory = "kafkaListenerContainerFactory"
    )
    public void handlePaymentReceived(ConsumerRecord<String, String> record) {
        log.info("Received payment.received: key={}, partition={}, offset={}",
                record.key(), record.partition(), record.offset());

        try {
            EventEnvelope<PaymentReceivedEvent> envelope = objectMapper.readValue(
                    record.value(),
                    new TypeReference<EventEnvelope<PaymentReceivedEvent>>() {});

            billingService.processPayment(
                    envelope.payload().invoiceId(),
                    envelope.payload().amount(),
                    envelope.tenantId());

            log.info("Processed payment.received: eventId={}, invoiceId={}, tenantId={}",
                    envelope.eventId(), envelope.payload().invoiceId(), envelope.tenantId());

        } catch (Exception e) {
            log.error("Failed to process payment.received: key={}, offset={}",
                    record.key(), record.offset(), e);
            throw e;
        }
    }
}
```

## Consumer Configuration

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

---

## Error Handler and Dead Letter Publisher

```java
@Component
public class KafkaErrorHandler {

    @Bean
    public DefaultErrorHandler defaultErrorHandler(DeadLetterPublisher deadLetterPublisher) {
        DefaultErrorHandler errorHandler = new DefaultErrorHandler(
                deadLetterPublisher,
                new FixedBackOff(1000L, 3L) // 3 retries, 1s delay
        );
        errorHandler.addNotRetryableExceptions(
                JsonProcessingException.class,
                ValidationException.class,
                IllegalArgumentException.class
        );
        return errorHandler;
    }
}

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
        log.error("Sending to DLT: topic={}, dltTopic={}, key={}, offset={}, error={}",
                record.topic(), dltTopic, record.key(), record.offset(), exception.getMessage());

        ProducerRecord<String, String> dltRecord =
                new ProducerRecord<>(dltTopic, null, record.key().toString(), record.value().toString());
        dltRecord.headers().add("original-topic", record.topic().getBytes());
        dltRecord.headers().add("exception-message", exception.getMessage().getBytes());
        dltRecord.headers().add("exception-class", exception.getClass().getName().getBytes());

        kafkaTemplate.send(dltRecord);
    }
}
```

---

## Event DTO Schema

```java
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
                invoice.getId(), invoice.getInvoiceNumber(),
                invoice.getCustomer().getId(), invoice.getTotalAmount(),
                invoice.getStatus().name(), invoice.getCreatedAt());
    }
}
```

---

## Docker Compose for Local Kafka

```yaml
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
