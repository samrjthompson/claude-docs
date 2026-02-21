# Spark / Java Technical Standards

This layer defines conventions and patterns for Apache Spark data processing jobs written in Java, using Spring Boot as the application framework. It covers project structure, coding conventions, DataFrame API usage, Spring Boot integration, testing, configuration, and common transformation patterns.

---

## Project Structure

```
my-spark-jobs/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/jobs/
│   │   │       ├── Application.java
│   │   │       ├── config/
│   │   │       │   ├── SparkConfig.java
│   │   │       │   └── SparkProperties.java
│   │   │       ├── common/
│   │   │       │   ├── SchemaDefinitions.java
│   │   │       │   └── DataQuality.java
│   │   │       ├── ingestion/
│   │   │       │   ├── CustomerIngestionJob.java
│   │   │       │   ├── CustomerTransformations.java
│   │   │       │   └── CustomerSchema.java
│   │   │       ├── aggregation/
│   │   │       │   ├── DailyRevenueJob.java
│   │   │       │   ├── RevenueTransformations.java
│   │   │       │   └── RevenueSchema.java
│   │   │       └── export/
│   │   │           ├── ReportExportJob.java
│   │   │           └── ReportTransformations.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-local.yml
│   │       └── application-prod.yml
│   └── test/
│       └── java/
│           └── com/example/jobs/
│               ├── common/
│               │   └── SparkTestBase.java
│               ├── ingestion/
│               │   ├── CustomerIngestionJobTest.java
│               │   └── CustomerTransformationsTest.java
│               └── aggregation/
│                   └── RevenueTransformationsTest.java
├── pom.xml
└── .gitignore
```

### Structure Rules

- **Organise by job type or domain.** Group related jobs and their transformations together: `ingestion/`, `aggregation/`, `export/`.
- **Separate job orchestration from transformation logic.** The `Job` class is a Spring `@Component` that handles I/O (reading, writing, configuration). The `Transformations` class contains pure static methods that take DataFrames in and return DataFrames out.
- **Schema definitions in dedicated files.** Define `StructType` schemas explicitly rather than relying on schema inference.
- **Shared utilities in `common/`.** Data quality checks and reusable UDFs.
- **Spring configuration in `config/`.** `SparkConfig` defines the `SparkSession` bean. `SparkProperties` binds configuration from `application.yml`.
- **Test structure mirrors main.** Each transformation file has a corresponding test file.

---

## Java Coding Conventions

### General Style

- **Use Java 21+ features.** Records, sealed interfaces, pattern matching with `switch`, text blocks, and `var` for local variables where the type is obvious.
- **Prefer immutability.** Use `final` fields and local variables by default. Use `List.of()`, `Map.of()`, and other unmodifiable collection factories.
- **Use records for data classes.** Records provide immutability, equals/hashCode, and toString for free:

```java
public record JobResult(long recordsProcessed, Duration duration) {}
```

- **Use sealed interfaces for ADTs.** Sealed interfaces restrict implementations and enable exhaustive `switch` expressions:

```java
public sealed interface JobOutcome permits JobOutcome.Success, JobOutcome.Failure {
    record Success(long recordsProcessed, Duration duration) implements JobOutcome {}
    record Failure(String error, Optional<Throwable> cause) implements JobOutcome {}
}
```

- **Use `switch` expressions for multi-branch logic:**

```java
switch (outcome) {
    case JobOutcome.Success s ->
        logger.info("Processed {} records in {}s", s.recordsProcessed(), s.duration().toSeconds());
    case JobOutcome.Failure f when f.cause().isPresent() ->
        logger.error("Job failed: {}", f.error(), f.cause().get());
    case JobOutcome.Failure f ->
        logger.error("Job failed: {}", f.error());
}
```

### Naming Conventions

- **Classes and interfaces**: `PascalCase`. `CustomerIngestionJob`, `RevenueTransformations`.
- **Methods and variables**: `camelCase`. `calculateRevenue`, `filterActiveCustomers`.
- **Constants**: `UPPER_SNAKE_CASE`. `DEFAULT_PARTITION_COUNT`, `MAX_RETRIES`.
- **Packages**: `lowercase`. `com.example.jobs.ingestion`.
- **Type parameters**: Single uppercase letter or short descriptive name: `T`, `K`, `V`.

### Java Patterns

- **Prefer `Optional` over null.** Never return null from methods. Use `Optional<T>` and handle presence explicitly with `map`, `flatMap`, `orElse`, and `ifPresent`.
- **Use streams for collection processing.** Prefer `stream().map().filter().collect()` over manual loops.
- **Use `var` for local variables when the type is obvious.** `var config = loadConfig()` is fine. `var x = process(data)` is not — spell out the type when it is not immediately clear.

---

## Spring Boot Integration

### Application Entry Point

```java
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### SparkSession as a Spring Bean

Define `SparkSession` as a singleton bean managed by Spring. This ensures consistent configuration and clean lifecycle management.

```java
@Configuration
public class SparkConfig {

    @Bean
    public SparkSession sparkSession(SparkProperties properties) {
        return SparkSession.builder()
            .appName(properties.appName())
            .master(properties.master())
            .config("spark.sql.shuffle.partitions", String.valueOf(properties.shufflePartitions()))
            .getOrCreate();
    }
}
```

### Configuration with @ConfigurationProperties

Use Spring Boot's `application.yml` and `@ConfigurationProperties` for type-safe, profile-aware configuration. No Typesafe Config (HOCON).

```java
@ConfigurationProperties(prefix = "spark")
public record SparkProperties(
    String appName,
    String master,
    int shufflePartitions
) {}

@ConfigurationProperties(prefix = "job.input")
public record InputProperties(
    String path,
    String format
) {}

@ConfigurationProperties(prefix = "job.output")
public record OutputProperties(
    String path,
    String format
) {}
```

Enable property binding in the application class or a configuration class:

```java
@SpringBootApplication
@EnableConfigurationProperties({SparkProperties.class, InputProperties.class, OutputProperties.class})
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### Configuration Rules

- **Use `application.yml`, not `application.properties`.** YAML is more readable for nested configuration.
- **Use `@ConfigurationProperties` with records.** Type-safe, immutable, validated at startup.
- **Profile-specific configuration** via `application-{profile}.yml` files. Activate with `spring.profiles.active`.
- **Every config value has a default.** Override with environment variables or profile-specific files for deployment.
- **Never commit secrets to version control.** Use environment variables in production.

---

## Job Orchestration Pattern

### Jobs as Spring Components

Jobs are Spring `@Component` beans that implement `CommandLineRunner`. Spring manages their lifecycle and injects dependencies (SparkSession, configuration properties, other services).

```java
@Component
@Profile("ingestion")
public class CustomerIngestionJob implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(CustomerIngestionJob.class);

    private final SparkSession spark;
    private final InputProperties inputProperties;
    private final OutputProperties outputProperties;

    public CustomerIngestionJob(SparkSession spark,
                                InputProperties inputProperties,
                                OutputProperties outputProperties) {
        this.spark = spark;
        this.inputProperties = inputProperties;
        this.outputProperties = outputProperties;
    }

    @Override
    public void run(String... args) {
        logger.info("Starting customer ingestion job");

        var rawCustomers = spark.read()
            .option("header", "true")
            .schema(CustomerSchema.RAW)
            .csv(inputProperties.path());

        logger.info("Read {} raw customer records", rawCustomers.count());

        var transformed = CustomerTransformations.cleanAndValidate(rawCustomers);
        var deduplicated = CustomerTransformations.deduplicateByEmail(transformed);
        var enriched = CustomerTransformations.assignSegment(deduplicated);

        var qualityReport = DataQuality.check(enriched, CustomerSchema.QUALITY_RULES);
        if (qualityReport.hasFailures()) {
            throw new IllegalStateException("Data quality check failed: " + qualityReport.summary());
        }

        enriched.write()
            .mode(SaveMode.Overwrite)
            .partitionBy("tenant_id")
            .parquet(outputProperties.path());

        logger.info("Wrote {} customer records to {}", enriched.count(), outputProperties.path());
    }
}
```

### Job Rules

- **Jobs are Spring `@Component` beans implementing `CommandLineRunner`.** Spring manages their lifecycle, dependency injection, and error handling.
- **Use `@Profile` to select which job runs.** Activate with `--spring.profiles.active=ingestion` at launch. This prevents multiple jobs from running simultaneously in the same application.
- **Jobs are thin orchestrators.** They read config (injected via constructor), read data, call transformation methods, write results, and handle errors. All transformation logic lives in separate `Transformations` classes.
- **Constructor injection only.** No field injection. All dependencies are `final`.
- **Let exceptions propagate.** Spring Boot will log the error and exit with a non-zero code. Do not catch exceptions just to call `System.exit(1)`.
- **Log at job boundaries.** Log job start, record counts after reads and writes, and job completion or failure.
- **Partition output by tenant_id.** For multi-tenant data, always partition output files by tenant to enable efficient per-tenant reads.
- **SparkSession lifecycle is managed by Spring.** Do not call `spark.stop()` manually — Spring's shutdown hooks handle it. Register a `@PreDestroy` method in `SparkConfig` if custom cleanup is needed.

### Transformation Classes

Transformation methods are pure static methods: they take DataFrames in and return DataFrames out. No side effects, no I/O. No Spring annotations — these are plain utility classes.

```java
public final class CustomerTransformations {

    private CustomerTransformations() {}

    public static Dataset<Row> cleanAndValidate(Dataset<Row> raw) {
        return raw
            .filter(col("email").isNotNull())
            .filter(col("email").rlike("^[\\w.+-]+@[\\w-]+\\.[\\w.]+$"))
            .withColumn("name", trim(col("name")))
            .withColumn("email", lower(trim(col("email"))))
            .withColumn("created_at", to_timestamp(col("created_at"), "yyyy-MM-dd'T'HH:mm:ss"));
    }

    public static Dataset<Row> deduplicateByEmail(Dataset<Row> customers) {
        var window = Window
            .partitionBy("tenant_id", "email")
            .orderBy(col("created_at").desc());

        return customers
            .withColumn("row_num", row_number().over(window))
            .filter(col("row_num").equalTo(1))
            .drop("row_num");
    }

    public static Dataset<Row> assignSegment(Dataset<Row> customers) {
        return customers.withColumn("segment",
            when(col("total_spend").geq(10000), lit("ENTERPRISE"))
                .when(col("total_spend").geq(1000), lit("BUSINESS"))
                .otherwise(lit("STARTER"))
        );
    }
}
```

---

## DataFrame API

### Decision Framework

- **Use DataFrames (`Dataset<Row>`) as the default.** DataFrames are more performant, more compatible with Spark's Catalyst optimiser, and sufficient for most data processing.
- **Use typed `Dataset<T>` sparingly.** Java's Encoder support is more verbose than Scala's. Prefer the untyped DataFrame API unless compile-time type safety justifies the overhead.

### DataFrame Patterns

```java
public final class RevenueTransformations {

    private RevenueTransformations() {}

    public static Dataset<Row> calculateDailyRevenue(Dataset<Row> orders) {
        return orders
            .filter(col("status").equalTo("COMPLETED"))
            .withColumn("order_date", to_date(col("created_at")))
            .groupBy(col("tenant_id"), col("order_date"))
            .agg(
                sum(col("total_amount")).as("daily_revenue"),
                count(col("id")).as("order_count"),
                avg(col("total_amount")).as("average_order_value")
            );
    }

    public static Dataset<Row> enrichWithCustomerData(
            Dataset<Row> revenue,
            Dataset<Row> customers) {
        var customerSubset = customers.select(
            col("id").as("customer_id"),
            col("name").as("customer_name"),
            col("segment")
        );

        return revenue.join(customerSubset, seq("customer_id"), "left");
    }

    public static Dataset<Row> filterHighValueOrders(
            Dataset<Row> orders,
            BigDecimal threshold) {
        return orders.filter(col("total_amount").geq(lit(threshold)));
    }
}
```

### API Rules

- **Use `Dataset<Row>` for DataFrames.** This is the Java equivalent of Scala's `DataFrame` type alias.
- **Use column references consistently.** Use `col("name")` syntax everywhere. Do not mix styles.
- **Avoid UDFs when possible.** UDFs prevent Catalyst optimisation. Use built-in Spark SQL functions. Write a UDF only when there is no built-in equivalent.
- **Register UDFs centrally** in the `common` package if they must exist. Document each UDF's purpose, input types, and output type.
- **Use `functions.*` static imports.** Import `org.apache.spark.sql.functions.*` to keep transformation code concise.
- **Use `seq()` for join column lists.** Use `scala.collection.JavaConverters` or `scala.collection.immutable.Seq` helpers to pass column sequences to Spark's join API.

---

## Configuration

### application.yml

```yaml
spring:
  application:
    name: my-spark-jobs
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}
  main:
    web-application-type: none

spark:
  app-name: ${spring.application.name}
  master: "local[*]"
  shuffle-partitions: 200

job:
  input:
    path: /data/raw/customers
    format: csv
  output:
    path: /data/processed/customers
    format: parquet

logging:
  level:
    com.example.jobs: INFO
    org.apache.spark: WARN
```

```yaml
# application-local.yml
spark:
  master: "local[*]"
  shuffle-partitions: 4

job:
  input:
    path: ./data/raw/customers

logging:
  level:
    com.example.jobs: DEBUG
```

```yaml
# application-prod.yml
spark:
  master: ${SPARK_MASTER}
  shuffle-partitions: ${SPARK_SHUFFLE_PARTITIONS:200}

job:
  input:
    path: ${INPUT_PATH}
  output:
    path: ${OUTPUT_PATH}

logging:
  level:
    com.example.jobs: INFO
    root: WARN
```

### Configuration Rules

- **Set `spring.main.web-application-type: none`.** Spark jobs are batch applications — do not start a web server.
- **Use Spring profiles for environment-specific config.** `application-local.yml`, `application-prod.yml`. Activate with `--spring.profiles.active=prod`.
- **Override with environment variables in production.** Spring Boot's relaxed binding maps `SPARK_MASTER` to `spark.master` automatically.
- **Keep Spark tuning properties in `application.yml`.** Shuffle partitions, memory settings, and serialisation config all go here and can be overridden per environment.

---

## Schema Definitions

Define schemas explicitly. Never rely on schema inference in production jobs.

```java
public final class CustomerSchema {

    private CustomerSchema() {}

    public static final StructType RAW = new StructType(new StructField[]{
        new StructField("id", DataTypes.StringType, false, Metadata.empty()),
        new StructField("tenant_id", DataTypes.StringType, false, Metadata.empty()),
        new StructField("name", DataTypes.StringType, true, Metadata.empty()),
        new StructField("email", DataTypes.StringType, true, Metadata.empty()),
        new StructField("total_spend", new DecimalType(19, 4), true, Metadata.empty()),
        new StructField("status", DataTypes.StringType, true, Metadata.empty()),
        new StructField("created_at", DataTypes.StringType, true, Metadata.empty())
    });

    public static final StructType PROCESSED = new StructType(new StructField[]{
        new StructField("id", DataTypes.StringType, false, Metadata.empty()),
        new StructField("tenant_id", DataTypes.StringType, false, Metadata.empty()),
        new StructField("name", DataTypes.StringType, false, Metadata.empty()),
        new StructField("email", DataTypes.StringType, false, Metadata.empty()),
        new StructField("total_spend", new DecimalType(19, 4), false, Metadata.empty()),
        new StructField("status", DataTypes.StringType, false, Metadata.empty()),
        new StructField("segment", DataTypes.StringType, false, Metadata.empty()),
        new StructField("created_at", DataTypes.TimestampType, false, Metadata.empty())
    });

    public static final List<QualityRule> QUALITY_RULES = List.of(
        new QualityRule("email_not_null", col("email").isNotNull(), 1.0),
        new QualityRule("valid_segment", col("segment").isin("ENTERPRISE", "BUSINESS", "STARTER"), 1.0),
        new QualityRule("positive_spend", col("total_spend").geq(0), 0.99)
    );
}
```

### Schema Rules

- **Define `StructType` for every input and output.** Schemas are documentation and validation in one.
- **Separate raw and processed schemas.** Raw schemas match the source data (nullable fields, string dates). Processed schemas match the cleaned, typed output.
- **Include data quality rules with schemas.** Define expected constraints (not null, valid ranges, referential integrity) alongside the schema.
- **Version schemas.** When input formats change, create new schema versions and handle backwards compatibility in the job.

---

## Testing Spark Jobs

### Test Base for Pure Transformations

Use a plain JUnit base class with a shared `SparkSession` for testing transformations. No Spring context needed — transformations are pure static methods.

```java
abstract class SparkTestBase {

    protected static SparkSession spark;

    @BeforeAll
    static void setUpSpark() {
        spark = SparkSession.builder()
            .master("local[*]")
            .appName("test")
            .config("spark.sql.shuffle.partitions", "2")
            .config("spark.ui.enabled", "false")
            .getOrCreate();
    }

    @AfterAll
    static void tearDownSpark() {
        if (spark != null) {
            spark.stop();
        }
    }

    protected Dataset<Row> toDF(StructType schema, List<Row> rows) {
        return spark.createDataFrame(rows, schema);
    }
}
```

### Transformation Tests (No Spring Context)

```java
class CustomerTransformationsTest extends SparkTestBase {

    @Test
    void cleanAndValidate_removesRecordsWithNullEmails() {
        // Arrange
        var schema = new StructType(new StructField[]{
            new StructField("id", DataTypes.StringType, false, Metadata.empty()),
            new StructField("tenant_id", DataTypes.StringType, false, Metadata.empty()),
            new StructField("name", DataTypes.StringType, true, Metadata.empty()),
            new StructField("email", DataTypes.StringType, true, Metadata.empty()),
            new StructField("created_at", DataTypes.StringType, true, Metadata.empty())
        });

        var rows = List.of(
            RowFactory.create("1", "tenant-1", "Alice", "alice@example.com", "2024-01-01T00:00:00"),
            RowFactory.create("2", "tenant-1", "Bob", null, "2024-01-02T00:00:00"),
            RowFactory.create("3", "tenant-1", "Charlie", "invalid-email", "2024-01-03T00:00:00")
        );

        var input = toDF(schema, rows);

        // Act
        var result = CustomerTransformations.cleanAndValidate(input);

        // Assert
        assertThat(result.count()).isEqualTo(1);
        assertThat(result.select("email").as(Encoders.STRING()).collectAsList())
            .containsExactly("alice@example.com");
    }

    @Test
    void deduplicateByEmail_keepsMostRecentRecordPerEmail() {
        // Arrange
        var schema = new StructType(new StructField[]{
            new StructField("id", DataTypes.StringType, false, Metadata.empty()),
            new StructField("tenant_id", DataTypes.StringType, false, Metadata.empty()),
            new StructField("email", DataTypes.StringType, false, Metadata.empty()),
            new StructField("created_at", DataTypes.TimestampType, true, Metadata.empty())
        });

        var rows = List.of(
            RowFactory.create("1", "tenant-1", "alice@example.com", Timestamp.valueOf("2024-01-01 00:00:00")),
            RowFactory.create("2", "tenant-1", "alice@example.com", Timestamp.valueOf("2024-06-01 00:00:00")),
            RowFactory.create("3", "tenant-1", "bob@example.com", Timestamp.valueOf("2024-03-01 00:00:00"))
        );

        var input = toDF(schema, rows);

        // Act
        var result = CustomerTransformations.deduplicateByEmail(input);

        // Assert
        assertThat(result.count()).isEqualTo(2);
        assertThat(
            result.filter(col("email").equalTo("alice@example.com"))
                .select("id").as(Encoders.STRING()).collectAsList()
        ).containsExactly("2");
    }

    @Test
    void assignSegment_categorisesCustomersByTotalSpend() {
        // Arrange
        var schema = new StructType(new StructField[]{
            new StructField("id", DataTypes.StringType, false, Metadata.empty()),
            new StructField("total_spend", new DecimalType(19, 4), true, Metadata.empty())
        });

        var rows = List.of(
            RowFactory.create("1", new BigDecimal("15000")),
            RowFactory.create("2", new BigDecimal("5000")),
            RowFactory.create("3", new BigDecimal("500"))
        );

        var input = toDF(schema, rows);

        // Act
        var result = CustomerTransformations.assignSegment(input);

        // Assert
        var segments = result.select("id", "segment")
            .as(Encoders.tuple(Encoders.STRING(), Encoders.STRING()))
            .collectAsList().stream()
            .collect(Collectors.toMap(Tuple2::_1, Tuple2::_2));

        assertThat(segments).containsEntry("1", "ENTERPRISE");
        assertThat(segments).containsEntry("2", "BUSINESS");
        assertThat(segments).containsEntry("3", "STARTER");
    }
}
```

### Job Integration Tests (With Spring Context)

Use `@SpringBootTest` to test the full job wiring — configuration binding, SparkSession injection, and end-to-end execution.

```java
@SpringBootTest(properties = {
    "spring.profiles.active=ingestion",
    "job.input.path=src/test/resources/data/customers.csv",
    "job.output.path=target/test-output/customers",
    "spark.master=local[*]",
    "spark.shuffle-partitions=2"
})
class CustomerIngestionJobTest {

    @Autowired
    private SparkSession spark;

    @Test
    void job_processesInputAndWritesOutput(@TempDir Path outputDir) {
        // The job runs automatically via CommandLineRunner.
        // Verify the output was written correctly.
        var output = spark.read().parquet(outputDir.resolve("customers").toString());

        assertThat(output.count()).isGreaterThan(0);
        assertThat(output.schema().fieldNames())
            .contains("id", "tenant_id", "email", "segment");
    }
}
```

### Testing Rules

- **Test transformations without Spring.** Transformation classes are pure static methods — test them with `SparkTestBase` directly. No `@SpringBootTest` overhead.
- **Test jobs with `@SpringBootTest`.** Job-level tests verify the full wiring: configuration binding, SparkSession injection, and end-to-end execution.
- **Share a single SparkSession across tests** in a test class. Creating a SparkSession is expensive. Use `@BeforeAll`/`@AfterAll`.
- **Set `spark.sql.shuffle.partitions` to 2** in tests. The default of 200 wastes resources for small test datasets.
- **Disable Spark UI in tests.** `spark.ui.enabled=false` avoids port binding issues.
- **Test transformations in isolation.** Each transformation method gets its own test with minimal input data that covers the edge cases.
- **Use `RowFactory.create()` and explicit schemas to create test DataFrames.** Keep test data inline and readable.
- **Assert on DataFrame contents, not just counts.** Verify specific values, not just record counts.
- **Test schema conformity.** After a transformation, assert that the output schema matches the expected `StructType`.
- **Test null handling explicitly.** Spark handles nulls differently from Java. Test that null values in input produce the expected behaviour.
- **Use JUnit 5 and AssertJ.** `@Test`, `assertThat()`, and fluent assertions for readable tests.

---

## Common Transformation Patterns

### Window Functions

```java
// Running total per tenant
var window = Window
    .partitionBy("tenant_id")
    .orderBy("created_at")
    .rowsBetween(Window.unboundedPreceding(), Window.currentRow());

df.withColumn("running_total", sum("amount").over(window));
```

### Slowly Changing Dimensions

```java
// Type 2 SCD — detect changes and create new versions
public static Dataset<Row> applySCD2(
        Dataset<Row> current,
        Dataset<Row> incoming,
        List<String> keyColumns,
        List<String> trackedColumns) {

    var keyColumnArray = keyColumns.stream().map(functions::col).toArray(Column[]::new);

    var changeCondition = trackedColumns.stream()
        .map(c -> incoming.col(c).notEqual(current.col(c)).or(current.col(c).isNull()))
        .reduce(Column::or)
        .orElseThrow();

    var changes = incoming.join(current, seq(keyColumns), "left")
        .filter(changeCondition);

    // Close current records
    var closed = current.join(changes.select(keyColumnArray), seq(keyColumns), "inner")
        .withColumn("effective_end", current_timestamp())
        .withColumn("is_current", lit(false));

    // Open new records
    var opened = changes
        .withColumn("effective_start", current_timestamp())
        .withColumn("effective_end", lit(null).cast(DataTypes.TimestampType))
        .withColumn("is_current", lit(true));

    // Unchanged records
    var unchanged = current.join(changes.select(keyColumnArray), seq(keyColumns), "left_anti");

    return unchanged.unionByName(closed).unionByName(opened);
}
```

### Data Quality Checks

```java
public record QualityRule(String name, Column condition, double threshold) {}

public record QualityResult(String name, double passRate, double threshold, boolean passed) {}

public record QualityReport(List<QualityResult> results, long totalRows) {

    public boolean hasFailures() {
        return results.stream().anyMatch(r -> !r.passed());
    }

    public String summary() {
        return results.stream()
            .filter(r -> !r.passed())
            .map(r -> "%s: %.1f%% (threshold: %.1f%%)".formatted(r.name(), r.passRate() * 100, r.threshold() * 100))
            .collect(Collectors.joining(", "));
    }
}

public final class DataQuality {

    private DataQuality() {}

    public static QualityReport check(Dataset<Row> df, List<QualityRule> rules) {
        long totalRows = df.count();

        var results = rules.stream().map(rule -> {
            long passingRows = df.filter(rule.condition()).count();
            double passRate = totalRows > 0 ? (double) passingRows / totalRows : 1.0;
            return new QualityResult(
                rule.name(),
                passRate,
                rule.threshold(),
                passRate >= rule.threshold()
            );
        }).toList();

        return new QualityReport(results, totalRows);
    }
}
```

### Pattern Rules

- **Use window functions for running aggregations and ranking.** They are optimised by Catalyst and avoid expensive self-joins.
- **Build data quality checks into every pipeline.** Validate data before writing output. Fail the job if quality thresholds are not met.
- **Use `unionByName` over `union`.** It matches columns by name rather than position, preventing silent column misalignment.
- **Repartition before writing** when output partition count matters for downstream consumers. Use `coalesce` to reduce partitions (no shuffle), `repartition` to increase (shuffle).
- **Cache judiciously.** Cache a DataFrame only when it is used in multiple subsequent operations. Unpersist when no longer needed.

---

## Build Configuration

### pom.xml

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.4.2</version>
        <relativePath/>
    </parent>

    <groupId>com.example</groupId>
    <artifactId>my-spark-jobs</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <properties>
        <java.version>21</java.version>
        <spark.version>3.5.0</spark.version>
    </properties>

    <dependencies>
        <!-- Spring Boot (no web server) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <!-- Spark (provided at runtime by the cluster) -->
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-core_2.13</artifactId>
            <version>${spark.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-sql_2.13</artifactId>
            <version>${spark.version}</version>
            <scope>provided</scope>
        </dependency>

        <!-- Test -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-core_2.13</artifactId>
            <version>${spark.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-sql_2.13</artifactId>
            <version>${spark.version}</version>
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

### Build Rules

- **Use `spring-boot-starter-parent` as the parent POM.** It manages dependency versions and provides the Spring Boot Maven Plugin.
- **Use `spring-boot-starter` (not `spring-boot-starter-web`).** Spark jobs are batch applications — no embedded web server needed.
- **Mark Spark dependencies as `provided`.** The Spark cluster provides these at runtime. Include them as test dependencies for local testing.
- **Use Spring Boot Maven Plugin for fat JARs.** It packages the application as an executable JAR. No need for the Shade plugin.
- **Pin Java and Spark versions.** Spark is sensitive to version mismatches.
- **`spring-boot-starter-test` includes JUnit 5 and AssertJ.** No need to declare them separately.
