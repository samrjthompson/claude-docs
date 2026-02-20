# Spark / Scala Technical Standards

This layer defines conventions and patterns for Apache Spark data processing jobs written in Scala. It covers project structure, coding conventions, DataFrame vs Dataset API usage, testing, configuration, and common transformation patterns.

---

## Project Structure

```
my-spark-jobs/
├── src/
│   ├── main/
│   │   ├── scala/
│   │   │   └── com/example/jobs/
│   │   │       ├── common/
│   │   │       │   ├── SparkSessionBuilder.scala
│   │   │       │   ├── ConfigLoader.scala
│   │   │       │   ├── SchemaDefinitions.scala
│   │   │       │   └── DataQuality.scala
│   │   │       ├── ingestion/
│   │   │       │   ├── CustomerIngestionJob.scala
│   │   │       │   ├── CustomerTransformations.scala
│   │   │       │   └── CustomerSchema.scala
│   │   │       ├── aggregation/
│   │   │       │   ├── DailyRevenueJob.scala
│   │   │       │   ├── RevenueTransformations.scala
│   │   │       │   └── RevenueSchema.scala
│   │   │       └── export/
│   │   │           ├── ReportExportJob.scala
│   │   │           └── ReportTransformations.scala
│   │   └── resources/
│   │       ├── application.conf
│   │       ├── application-local.conf
│   │       └── application-prod.conf
│   └── test/
│       └── scala/
│           └── com/example/jobs/
│               ├── common/
│               │   └── SparkTestBase.scala
│               ├── ingestion/
│               │   ├── CustomerIngestionJobTest.scala
│               │   └── CustomerTransformationsTest.scala
│               └── aggregation/
│                   └── RevenueTransformationsTest.scala
├── build.sbt
└── project/
    ├── build.properties
    └── plugins.sbt
```

### Structure Rules

- **Organise by job type or domain.** Group related jobs and their transformations together: `ingestion/`, `aggregation/`, `export/`.
- **Separate job orchestration from transformation logic.** The `Job` class handles I/O (reading, writing, configuration). The `Transformations` object contains pure DataFrame → DataFrame functions.
- **Schema definitions in dedicated files.** Define `StructType` schemas explicitly rather than relying on schema inference.
- **Shared utilities in `common/`.** Spark session construction, configuration loading, data quality checks, and reusable UDFs.
- **Test structure mirrors main.** Each transformation file has a corresponding test file.

---

## Scala Coding Conventions

### General Style

- **Prefer immutability.** Use `val` over `var`. Use immutable collections by default.
- **Prefer expressions over statements.** Scala is expression-oriented. Prefer `val result = if (condition) x else y` over mutable variables with conditional assignment.
- **Use case classes for data.** All data-holding types are case classes. They provide immutability, pattern matching, equals/hashCode, and copy methods.
- **Use sealed traits for enumerations and ADTs.** Sealed traits enable exhaustive pattern matching:

```scala
sealed trait JobResult
case class Success(recordsProcessed: Long, duration: Duration) extends JobResult
case class Failure(error: String, cause: Option[Throwable]) extends JobResult
```

- **Pattern matching over if-else chains.** When branching on type or multiple conditions, use `match`:

```scala
result match {
  case Success(count, duration) =>
    logger.info(s"Processed $count records in ${duration.toSeconds}s")
  case Failure(error, Some(cause)) =>
    logger.error(s"Job failed: $error", cause)
  case Failure(error, None) =>
    logger.error(s"Job failed: $error")
}
```

### Naming Conventions

- **Classes and traits**: `PascalCase`. `CustomerIngestionJob`, `RevenueTransformations`.
- **Methods and values**: `camelCase`. `calculateRevenue`, `filterActiveCustomers`.
- **Constants**: `PascalCase` (Scala convention, not UPPER_SNAKE): `DefaultPartitionCount`, `MaxRetries`.
- **Packages**: `lowercase`. `com.example.jobs.ingestion`.
- **Type parameters**: Single uppercase letter or short descriptive name: `T`, `K`, `V`, `In`, `Out`.

### Functional Patterns

- **Prefer `Option` over null.** Never use null in Scala code. Use `Option[T]` and handle `Some` and `None` explicitly.
- **Use `Either` for operations that can fail.** `Either[ErrorType, SuccessType]` for business operations. `Try` for wrapping exceptions from Java libraries.
- **Chain transformations with `map`, `flatMap`, `filter`.** Avoid manual loops. Use for-comprehensions for complex chains:

```scala
for {
  config  <- loadConfig(args)
  spark   <- createSparkSession(config)
  input   <- readInput(spark, config)
  result  <- transform(input)
  _       <- writeOutput(result, config)
} yield result
```

- **Avoid implicit conversions.** They obscure code. Use explicit conversions or extension methods.
- **Limit implicit parameters to type class instances and Spark-provided implicits** (Encoder, SparkSession). Do not create custom implicit parameter chains.

---

## DataFrame vs Dataset API

### Decision Framework

- **Use DataFrames (untyped API) as the default.** DataFrames are more performant, more compatible with Spark's optimizer, and sufficient for most data processing.
- **Use Datasets (typed API) when:**
  - You need compile-time type safety for critical business logic.
  - You are performing complex transformations that benefit from case class destructuring.
  - The data pipeline is long and type errors would be expensive to debug at runtime.

### DataFrame Patterns

```scala
object RevenueTransformations {

  def calculateDailyRevenue(orders: DataFrame): DataFrame = {
    orders
      .filter(col("status") === "COMPLETED")
      .withColumn("order_date", to_date(col("created_at")))
      .groupBy(col("tenant_id"), col("order_date"))
      .agg(
        sum(col("total_amount")).as("daily_revenue"),
        count(col("id")).as("order_count"),
        avg(col("total_amount")).as("average_order_value")
      )
  }

  def enrichWithCustomerData(
      revenue: DataFrame,
      customers: DataFrame
  ): DataFrame = {
    revenue
      .join(
        customers.select(
          col("id").as("customer_id"),
          col("name").as("customer_name"),
          col("segment")
        ),
        Seq("customer_id"),
        "left"
      )
  }

  def filterHighValueOrders(
      orders: DataFrame,
      threshold: BigDecimal
  ): DataFrame = {
    orders.filter(col("total_amount") >= lit(threshold))
  }
}
```

### Dataset Patterns (When Justified)

```scala
case class Order(
    id: String,
    tenantId: String,
    customerId: String,
    totalAmount: BigDecimal,
    status: String,
    createdAt: Timestamp
)

case class DailyRevenue(
    tenantId: String,
    date: java.sql.Date,
    revenue: BigDecimal,
    orderCount: Long
)

object TypedRevenueTransformations {

  def calculateDailyRevenue(
      orders: Dataset[Order]
  )(implicit spark: SparkSession): Dataset[DailyRevenue] = {
    import spark.implicits._

    orders
      .filter(_.status == "COMPLETED")
      .groupByKey(o => (o.tenantId, o.createdAt.toLocalDateTime.toLocalDate))
      .mapGroups { case ((tenantId, date), orders) =>
        val orderList = orders.toList
        DailyRevenue(
          tenantId = tenantId,
          date = java.sql.Date.valueOf(date),
          revenue = orderList.map(_.totalAmount).sum,
          orderCount = orderList.size
        )
      }
  }
}
```

### API Rules

- **Never mix DataFrame and Dataset APIs in the same transformation chain** without an explicit conversion point. Pick one and stick with it for the entire pipeline segment.
- **Use column references consistently.** Use `col("name")` syntax. Do not mix `$"name"`, `'name`, and `col("name")` in the same codebase. Standardise on `col()`.
- **Avoid UDFs when possible.** UDFs prevent Catalyst optimisation. Use built-in Spark SQL functions. Write a UDF only when there is no built-in equivalent.
- **Register UDFs centrally** in the `common` package if they must exist. Document each UDF's purpose, input types, and output type.

---

## Job Orchestration Pattern

### Job Structure

```scala
object CustomerIngestionJob extends App {

  private val logger = LoggerFactory.getLogger(getClass)

  val config = ConfigLoader.load(args)

  val spark = SparkSessionBuilder.create(config)

  try {
    logger.info(s"Starting customer ingestion job: env=${config.environment}")

    val rawCustomers = spark.read
      .option("header", "true")
      .schema(CustomerSchema.raw)
      .csv(config.inputPath)

    logger.info(s"Read ${rawCustomers.count()} raw customer records")

    val transformed = CustomerTransformations.cleanAndValidate(rawCustomers)
    val deduplicated = CustomerTransformations.deduplicateByEmail(transformed)
    val enriched = CustomerTransformations.assignSegment(deduplicated)

    val qualityReport = DataQuality.check(enriched, CustomerSchema.qualityRules)
    if (qualityReport.hasFailures) {
      logger.error(s"Data quality check failed: ${qualityReport.summary}")
      sys.exit(1)
    }

    enriched.write
      .mode(SaveMode.Overwrite)
      .partitionBy("tenant_id")
      .parquet(config.outputPath)

    logger.info(s"Wrote ${enriched.count()} customer records to ${config.outputPath}")

  } catch {
    case e: Exception =>
      logger.error("Customer ingestion job failed", e)
      sys.exit(1)
  } finally {
    spark.stop()
  }
}
```

### Job Rules

- **Jobs are thin orchestrators.** They read config, create SparkSession, read data, call transformation functions, write results, and handle errors. All transformation logic lives in separate `Transformations` objects.
- **Always stop SparkSession in a finally block.** Prevents resource leaks.
- **Exit with non-zero code on failure.** Job schedulers (Airflow, cron) detect failures via exit codes.
- **Log at job boundaries.** Log job start, record counts after reads and writes, and job completion or failure.
- **Partition output by tenant_id.** For multi-tenant data, always partition output files by tenant to enable efficient per-tenant reads.

### Transformation Functions

Transformation functions are pure: they take DataFrames in and return DataFrames out. No side effects, no I/O.

```scala
object CustomerTransformations {

  def cleanAndValidate(raw: DataFrame): DataFrame = {
    raw
      .filter(col("email").isNotNull)
      .filter(col("email").rlike("^[\\w.+-]+@[\\w-]+\\.[\\w.]+$"))
      .withColumn("name", trim(col("name")))
      .withColumn("email", lower(trim(col("email"))))
      .withColumn("created_at", to_timestamp(col("created_at"), "yyyy-MM-dd'T'HH:mm:ss"))
  }

  def deduplicateByEmail(customers: DataFrame): DataFrame = {
    val window = Window
      .partitionBy("tenant_id", "email")
      .orderBy(col("created_at").desc)

    customers
      .withColumn("row_num", row_number().over(window))
      .filter(col("row_num") === 1)
      .drop("row_num")
  }

  def assignSegment(customers: DataFrame): DataFrame = {
    customers.withColumn("segment",
      when(col("total_spend") >= 10000, lit("ENTERPRISE"))
        .when(col("total_spend") >= 1000, lit("BUSINESS"))
        .otherwise(lit("STARTER"))
    )
  }
}
```

---

## Schema Definitions

Define schemas explicitly. Never rely on schema inference in production jobs.

```scala
object CustomerSchema {

  val raw: StructType = StructType(Seq(
    StructField("id", StringType, nullable = false),
    StructField("tenant_id", StringType, nullable = false),
    StructField("name", StringType, nullable = true),
    StructField("email", StringType, nullable = true),
    StructField("total_spend", DecimalType(19, 4), nullable = true),
    StructField("status", StringType, nullable = true),
    StructField("created_at", StringType, nullable = true)
  ))

  val processed: StructType = StructType(Seq(
    StructField("id", StringType, nullable = false),
    StructField("tenant_id", StringType, nullable = false),
    StructField("name", StringType, nullable = false),
    StructField("email", StringType, nullable = false),
    StructField("total_spend", DecimalType(19, 4), nullable = false),
    StructField("status", StringType, nullable = false),
    StructField("segment", StringType, nullable = false),
    StructField("created_at", TimestampType, nullable = false)
  ))

  val qualityRules: Seq[QualityRule] = Seq(
    QualityRule("email_not_null", col("email").isNotNull, threshold = 1.0),
    QualityRule("valid_segment", col("segment").isin("ENTERPRISE", "BUSINESS", "STARTER"), threshold = 1.0),
    QualityRule("positive_spend", col("total_spend") >= 0, threshold = 0.99)
  )
}
```

### Schema Rules

- **Define `StructType` for every input and output.** Schemas are documentation and validation in one.
- **Separate raw and processed schemas.** Raw schemas match the source data (nullable fields, string dates). Processed schemas match the cleaned, typed output.
- **Include data quality rules with schemas.** Define expected constraints (not null, valid ranges, referential integrity) alongside the schema.
- **Version schemas.** When input formats change, create new schema versions and handle backwards compatibility in the job.

---

## Configuration Management

### Typesafe Config

```
# application.conf
job {
  environment = "local"
  environment = ${?JOB_ENVIRONMENT}

  spark {
    app-name = "customer-ingestion"
    master = "local[*]"
    master = ${?SPARK_MASTER}
  }

  input {
    path = "/data/raw/customers"
    path = ${?INPUT_PATH}
    format = "csv"
  }

  output {
    path = "/data/processed/customers"
    path = ${?OUTPUT_PATH}
    format = "parquet"
  }
}
```

```scala
case class JobConfig(
    environment: String,
    sparkAppName: String,
    sparkMaster: String,
    inputPath: String,
    inputFormat: String,
    outputPath: String,
    outputFormat: String
)

object ConfigLoader {
  def load(args: Array[String]): JobConfig = {
    val config = ConfigFactory.load()
    val jobConfig = config.getConfig("job")

    JobConfig(
      environment = jobConfig.getString("environment"),
      sparkAppName = jobConfig.getString("spark.app-name"),
      sparkMaster = jobConfig.getString("spark.master"),
      inputPath = jobConfig.getString("input.path"),
      inputFormat = jobConfig.getString("input.format"),
      outputPath = jobConfig.getString("output.path"),
      outputFormat = jobConfig.getString("output.format")
    )
  }
}
```

### Configuration Rules

- **Use Typesafe Config (HOCON).** It supports environment variable overrides, includes, and hierarchical configuration.
- **Every config value has a default.** Override with environment variables for deployment.
- **Load configuration into a case class.** Type-safe, immutable, easy to pass around and test.
- **Separate config files per environment.** `application-local.conf`, `application-prod.conf`. Include the base config and override specific values.

---

## Testing Spark Jobs

### Test Base

```scala
trait SparkTestBase extends AnyFunSuite with Matchers with BeforeAndAfterAll {

  implicit lazy val spark: SparkSession = SparkSession.builder()
    .master("local[*]")
    .appName("test")
    .config("spark.sql.shuffle.partitions", "2")
    .config("spark.ui.enabled", "false")
    .getOrCreate()

  import spark.implicits._

  override def afterAll(): Unit = {
    spark.stop()
    super.afterAll()
  }

  // Helper to create DataFrames from case classes
  def toDF[T <: Product : TypeTag](data: T*): DataFrame = {
    spark.createDataFrame(spark.sparkContext.parallelize(data))
  }
}
```

### Transformation Tests

```scala
class CustomerTransformationsTest extends SparkTestBase {

  import spark.implicits._

  test("cleanAndValidate removes records with null emails") {
    // Arrange
    val input = Seq(
      ("1", "tenant-1", "Alice", "alice@example.com", "2024-01-01T00:00:00"),
      ("2", "tenant-1", "Bob", null, "2024-01-02T00:00:00"),
      ("3", "tenant-1", "Charlie", "invalid-email", "2024-01-03T00:00:00")
    ).toDF("id", "tenant_id", "name", "email", "created_at")

    // Act
    val result = CustomerTransformations.cleanAndValidate(input)

    // Assert
    result.count() shouldBe 1
    result.select("email").as[String].collect() shouldBe Array("alice@example.com")
  }

  test("deduplicateByEmail keeps the most recent record per email") {
    // Arrange
    val input = Seq(
      ("1", "tenant-1", "alice@example.com", Timestamp.valueOf("2024-01-01 00:00:00")),
      ("2", "tenant-1", "alice@example.com", Timestamp.valueOf("2024-06-01 00:00:00")),
      ("3", "tenant-1", "bob@example.com", Timestamp.valueOf("2024-03-01 00:00:00"))
    ).toDF("id", "tenant_id", "email", "created_at")

    // Act
    val result = CustomerTransformations.deduplicateByEmail(input)

    // Assert
    result.count() shouldBe 2
    result.filter(col("email") === "alice@example.com")
      .select("id").as[String].collect() shouldBe Array("2")
  }

  test("assignSegment categorises customers by total spend") {
    // Arrange
    val input = Seq(
      ("1", BigDecimal(15000)),
      ("2", BigDecimal(5000)),
      ("3", BigDecimal(500))
    ).toDF("id", "total_spend")

    // Act
    val result = CustomerTransformations.assignSegment(input)

    // Assert
    val segments = result.select("id", "segment").as[(String, String)].collect().toMap
    segments("1") shouldBe "ENTERPRISE"
    segments("2") shouldBe "BUSINESS"
    segments("3") shouldBe "STARTER"
  }
}
```

### Testing Rules

- **Share a single SparkSession across tests** in a test class. Creating a SparkSession is expensive. Use `beforeAll`/`afterAll`.
- **Set `spark.sql.shuffle.partitions` to 2** in tests. The default of 200 wastes resources for small test datasets.
- **Disable Spark UI in tests.** `spark.ui.enabled=false` avoids port binding issues.
- **Test transformations in isolation.** Each transformation function gets its own test with minimal input data that covers the edge cases.
- **Use case classes or tuples to create test DataFrames.** Keep test data inline and readable.
- **Assert on DataFrame contents, not just counts.** Verify specific values, not just record counts.
- **Test schema conformity.** After a transformation, assert that the output schema matches the expected `StructType`.
- **Test null handling explicitly.** Spark handles nulls differently from Scala. Test that null values in input produce the expected behaviour.

---

## Common Transformation Patterns

### Window Functions

```scala
// Running total per tenant
val window = Window
  .partitionBy("tenant_id")
  .orderBy("created_at")
  .rowsBetween(Window.unboundedPreceding, Window.currentRow)

df.withColumn("running_total", sum("amount").over(window))
```

### Slowly Changing Dimensions

```scala
// Type 2 SCD — detect changes and create new versions
def applySCD2(
    current: DataFrame,
    incoming: DataFrame,
    keyColumns: Seq[String],
    trackedColumns: Seq[String]
): DataFrame = {
  val changes = incoming.join(current, keyColumns, "left")
    .filter(trackedColumns.map(c =>
      incoming(c) =!= current(c) || current(c).isNull
    ).reduce(_ || _))

  // Close current records
  val closed = current.join(changes.select(keyColumns.map(col): _*), keyColumns, "inner")
    .withColumn("effective_end", current_timestamp())
    .withColumn("is_current", lit(false))

  // Open new records
  val opened = changes
    .withColumn("effective_start", current_timestamp())
    .withColumn("effective_end", lit(null).cast(TimestampType))
    .withColumn("is_current", lit(true))

  // Unchanged records
  val unchanged = current.join(changes.select(keyColumns.map(col): _*), keyColumns, "left_anti")

  unchanged.unionByName(closed).unionByName(opened)
}
```

### Data Quality Checks

```scala
case class QualityRule(
    name: String,
    condition: Column,
    threshold: Double // 0.0 to 1.0 — minimum percentage of rows that must pass
)

case class QualityReport(
    results: Seq[QualityResult],
    totalRows: Long
) {
  def hasFailures: Boolean = results.exists(!_.passed)
  def summary: String = results.filter(!_.passed)
    .map(r => s"${r.name}: ${r.passRate}% (threshold: ${r.threshold}%)")
    .mkString(", ")
}

object DataQuality {
  def check(df: DataFrame, rules: Seq[QualityRule]): QualityReport = {
    val totalRows = df.count()

    val results = rules.map { rule =>
      val passingRows = df.filter(rule.condition).count()
      val passRate = if (totalRows > 0) passingRows.toDouble / totalRows else 1.0
      QualityResult(
        name = rule.name,
        passRate = passRate,
        threshold = rule.threshold,
        passed = passRate >= rule.threshold
      )
    }

    QualityReport(results, totalRows)
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

### build.sbt

```scala
name := "my-spark-jobs"
version := "1.0.0"
scalaVersion := "2.13.12"

val sparkVersion = "3.5.0"

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % sparkVersion % Provided,
  "org.apache.spark" %% "spark-sql" % sparkVersion % Provided,
  "com.typesafe" % "config" % "1.4.3",

  // Test
  "org.scalatest" %% "scalatest" % "3.2.17" % Test,
  "org.apache.spark" %% "spark-core" % sparkVersion % Test,
  "org.apache.spark" %% "spark-sql" % sparkVersion % Test
)

// Assembly plugin for fat JAR
assembly / assemblyMergeStrategy := {
  case PathList("META-INF", _*) => MergeStrategy.discard
  case _ => MergeStrategy.first
}
```

### Build Rules

- **Mark Spark dependencies as `Provided`.** The Spark cluster provides these at runtime. Include them as test dependencies for local testing.
- **Use sbt-assembly for fat JARs.** Package the application with its dependencies (excluding Spark) for cluster submission.
- **Pin Scala and Spark versions.** Spark is sensitive to Scala version mismatches.
- **Use `MergeStrategy.discard` for META-INF.** Prevents assembly conflicts from shaded dependencies.
