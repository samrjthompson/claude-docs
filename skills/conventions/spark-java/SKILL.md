---
name: spark-java-conventions
description: Apache Spark / Java data pipeline conventions — project structure, job orchestration, Spring Boot integration, DataFrame API, schema definitions, testing patterns
user-invocable: false
paths: "**/*.java,**/pom.xml,**/application*.yml,**/application*.yaml"
---

# Spark / Java Technical Standards

Apache Spark data processing jobs written in Java with Spring Boot as the application framework. See [pipeline-patterns.md](pipeline-patterns.md) for DataFrame examples, schema definitions, and common transformation patterns.

---

## Project Structure

```
my-spark-jobs/
├── src/main/java/com/example/jobs/
│   ├── Application.java
│   ├── config/
│   │   ├── SparkConfig.java           # SparkSession bean
│   │   └── SparkProperties.java       # @ConfigurationProperties
│   ├── common/
│   │   ├── SchemaDefinitions.java
│   │   └── DataQuality.java
│   ├── ingestion/
│   │   ├── CustomerIngestionJob.java  # CommandLineRunner
│   │   ├── CustomerTransformations.java  # Pure static methods
│   │   └── CustomerSchema.java
│   └── aggregation/
│       ├── DailyRevenueJob.java
│       └── RevenueTransformations.java
└── src/test/java/com/example/jobs/
    ├── common/SparkTestBase.java
    └── ingestion/
        ├── CustomerIngestionJobTest.java
        └── CustomerTransformationsTest.java
```

### Structure Rules

- **Organise by job type or domain.** `ingestion/`, `aggregation/`, `export/`.
- **Separate job orchestration from transformation logic.** `Job` handles I/O and configuration. `Transformations` contains pure static methods.
- **Schema definitions in dedicated files.** Explicit `StructType`, never inferred.
- **Shared utilities in `common/`.** Data quality checks, reusable UDFs.
- **Test structure mirrors main.** Each transformation file has a corresponding test.

---

## Java Coding Conventions

- **Java 21+ features.** Records, sealed interfaces, pattern matching, text blocks.
- **`var` for local variables where type is obvious.** `var config = loadConfig()` is fine. `var x = process(data)` — spell out the type.
- **Records for data classes.** `public record JobResult(long recordsProcessed, Duration duration) {}`
- **Sealed interfaces for ADTs.**

---

## Spring Boot Integration

### SparkSession as Spring Bean

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

### @ConfigurationProperties

```java
@ConfigurationProperties(prefix = "spark")
public record SparkProperties(String appName, String master, int shufflePartitions) {}

@ConfigurationProperties(prefix = "job.input")
public record InputProperties(String path, String format) {}

@ConfigurationProperties(prefix = "job.output")
public record OutputProperties(String path, String format) {}
```

Enable with `@EnableConfigurationProperties({SparkProperties.class, ...})` on `Application`.

### Configuration Rules

- **`application.yml` not `application.properties`.** YAML is more readable for nested config.
- **`@ConfigurationProperties` with records.** Type-safe, immutable, validated at startup.
- **`spring.main.web-application-type: none`.** Spark jobs are batch applications.
- **Every config value has a default.** Override via environment variables or profile files.
- **Profile-specific files**: `application-local.yml`, `application-prod.yml`.

---

## Job Orchestration Pattern

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

- **`@Component` + `CommandLineRunner`.** Spring manages lifecycle and dependency injection.
- **`@Profile` to select which job runs.** Activate with `--spring.profiles.active=ingestion`.
- **Jobs are thin orchestrators.** Read config, read data, call transformation methods, write results, handle errors.
- **Constructor injection only.** All dependencies are `final`.
- **Let exceptions propagate.** Spring Boot logs and exits with non-zero code. Do not catch just to `System.exit(1)`.
- **Log at job boundaries.** Start, record counts after reads/writes, completion or failure.
- **Partition output by `tenant_id`** for multi-tenant data.
- **Do not call `spark.stop()` manually.** Spring's shutdown hooks handle it.

### Transformation Classes

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
}
```

Pure static methods. No side effects, no I/O. No Spring annotations.

---

## Testing Rules

- **Test transformations without Spring.** Use `SparkTestBase` directly. No `@SpringBootTest` overhead.
- **Test jobs with `@SpringBootTest`.** Verify full wiring: config binding, SparkSession injection, end-to-end.
- **Share a single SparkSession across tests.** `@BeforeAll`/`@AfterAll`. Creating a session is expensive.
- **`spark.sql.shuffle.partitions=2` in tests.** Default 200 wastes resources.
- **`spark.ui.enabled=false` in tests.**
- **Test transformations in isolation.** Each method gets its own test with minimal data covering edge cases.
- **Use `RowFactory.create()` and explicit schemas.** Keep test data inline.
- **Assert on DataFrame contents, not just counts.**
- **Test null handling explicitly.** Spark handles nulls differently from Java.
- **JUnit 5 and AssertJ** for readable tests.
