# DataFrame API, Schema Definitions, Transformation Patterns, and Build

## DataFrame API

### Decision Framework

- **Use `Dataset<Row>` as the default.** More performant, Catalyst-compatible, sufficient for most processing.
- **Typed `Dataset<T>` sparingly.** Java Encoder support is verbose. Prefer untyped API unless compile-time type safety justifies overhead.

### Rules

- **`Dataset<Row>` for DataFrames.**
- **`col("name")` syntax everywhere.** Do not mix styles.
- **Avoid UDFs.** They prevent Catalyst optimisation. Use built-in Spark SQL functions.
- **Register UDFs centrally** in `common` if they must exist. Document purpose, input types, output type.
- **`functions.*` static imports** to keep transformation code concise.
- **`seq()` for join column lists.**

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

    public static Dataset<Row> enrichWithCustomerData(Dataset<Row> revenue, Dataset<Row> customers) {
        var customerSubset = customers.select(
            col("id").as("customer_id"),
            col("name").as("customer_name"),
            col("segment")
        );
        return revenue.join(customerSubset, seq("customer_id"), "left");
    }
}
```

---

## Schema Definitions

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
        new StructField("email", DataTypes.StringType, false, Metadata.empty()),
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

- **Define `StructType` for every input and output.** Never rely on inference in production.
- **Separate raw and processed schemas.** Raw: nullable fields, string dates. Processed: typed, non-nullable.
- **Include data quality rules alongside schemas.**
- **Version schemas** for input format changes.

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

### Data Quality Checks

```java
public record QualityRule(String name, Column condition, double threshold) {}

public final class DataQuality {

    private DataQuality() {}

    public static QualityReport check(Dataset<Row> df, List<QualityRule> rules) {
        long totalRows = df.count();
        var results = rules.stream().map(rule -> {
            long passingRows = df.filter(rule.condition()).count();
            double passRate = totalRows > 0 ? (double) passingRows / totalRows : 1.0;
            return new QualityResult(rule.name(), passRate, rule.threshold(), passRate >= rule.threshold());
        }).toList();
        return new QualityReport(results, totalRows);
    }
}
```

### Pattern Rules

- **Window functions for running aggregations.** Optimised by Catalyst.
- **Data quality checks in every pipeline.** Fail the job if thresholds not met.
- **`unionByName` over `union`.** Matches by name, not position.
- **Repartition before writing** when downstream consumers depend on partition count. `coalesce` to reduce (no shuffle), `repartition` to increase.
- **Cache judiciously.** Only when a DataFrame is used in multiple subsequent operations. Unpersist when done.

---

## Testing Patterns

### SparkTestBase

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
        if (spark != null) spark.stop();
    }

    protected Dataset<Row> toDF(StructType schema, List<Row> rows) {
        return spark.createDataFrame(rows, schema);
    }
}
```

### Transformation Test Example

```java
class CustomerTransformationsTest extends SparkTestBase {

    @Test
    void cleanAndValidate_removesRecordsWithNullEmails() {
        var schema = new StructType(new StructField[]{
            new StructField("id", DataTypes.StringType, false, Metadata.empty()),
            new StructField("tenant_id", DataTypes.StringType, false, Metadata.empty()),
            new StructField("email", DataTypes.StringType, true, Metadata.empty()),
            new StructField("created_at", DataTypes.StringType, true, Metadata.empty())
        });

        var rows = List.of(
            RowFactory.create("1", "tenant-1", "alice@example.com", "2024-01-01T00:00:00"),
            RowFactory.create("2", "tenant-1", null, "2024-01-02T00:00:00"),
            RowFactory.create("3", "tenant-1", "invalid-email", "2024-01-03T00:00:00")
        );

        var result = CustomerTransformations.cleanAndValidate(toDF(schema, rows));

        assertThat(result.count()).isEqualTo(1);
        assertThat(result.select("email").as(Encoders.STRING()).collectAsList())
            .containsExactly("alice@example.com");
    }
}
```

---

## Build Configuration

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.4.2</version>
</parent>

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

    <!-- Spark — provided at runtime by the cluster -->
    <dependency>
        <groupId>org.apache.spark</groupId>
        <artifactId>spark-sql_2.13</artifactId>
        <version>${spark.version}</version>
        <scope>provided</scope>
    </dependency>

    <!-- Test: Spark available on classpath -->
    <dependency>
        <groupId>org.apache.spark</groupId>
        <artifactId>spark-sql_2.13</artifactId>
        <version>${spark.version}</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### Build Rules

- **`spring-boot-starter` not `spring-boot-starter-web`.** No embedded server.
- **Spark as `provided`.** Cluster provides at runtime. Include as `test` scope for local testing.
- **Spring Boot Maven Plugin for fat JARs.** No Shade plugin needed.
- **Pin Java and Spark versions.** Spark is sensitive to version mismatches.
