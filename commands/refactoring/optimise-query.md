# Optimise Database Query

Analyse and optimise a slow or inefficient database query. Suggest indexes, query restructuring, caching, or schema changes.

## Required Input

- **The slow query or endpoint**: Which repository method, service call, or endpoint is slow.
- **Symptoms**: Response time, query execution time, or observation (e.g., "list endpoint takes 3 seconds with 10k records").
- **Data characteristics** (if known): Table size, typical query patterns, data distribution.

## Analysis Process

### 1. Identify the Query

Locate the actual SQL being executed:
- For derived queries, determine the generated SQL.
- For `@Query` annotations, read the JPQL/SQL directly.
- For Specifications, reconstruct the generated SQL.
- Check for N+1 queries by examining the entity relationships being traversed.

### 2. Analyse Query Plan

Suggest running `EXPLAIN ANALYZE` on the query and analyse:
- Is it doing a full table scan?
- Are indexes being used?
- Are there unnecessary joins?
- Is there a sort operation on a non-indexed column?
- What is the estimated vs. actual row count?

### 3. Check for Common Issues

**N+1 Queries:**
- Entity relationship traversal triggering lazy-load queries in a loop.
- Fix: Add `JOIN FETCH` or `@EntityGraph` to the query.

**Missing Indexes:**
- Queries filtering or sorting on columns without indexes.
- Fix: Create indexes on frequently queried columns.

**Unnecessary Data Loading:**
- Loading entire entities when only a few fields are needed.
- Fix: Use projections (DTO-based or interface-based) for read-only queries.

**Inefficient Joins:**
- Cartesian products or joining large tables without selectivity.
- Fix: Add WHERE clauses to reduce join input, or restructure as subqueries.

**Pagination Without Efficient Counting:**
- `SELECT COUNT(*)` on the full dataset for every page request.
- Fix: Use keyset pagination, or cache the total count.

**Large Result Sets:**
- Returning thousands of records without pagination.
- Fix: Add mandatory pagination with sensible defaults.

### 4. Propose Solutions

For each issue found, provide:
- **The problem**: What is causing the slowness.
- **The fix**: Specific code or schema change.
- **Expected impact**: How much improvement to expect.
- **Trade-offs**: Any downsides of the optimisation (e.g., index write overhead, cache staleness).

## Solution Categories

### Index Recommendations

```sql
-- Suggest specific indexes with rationale
CREATE INDEX idx_invoices_tenant_status ON invoices (tenant_id, status);
-- Rationale: The list endpoint filters by tenant_id and status on every request.
-- This composite index covers both columns and avoids a full table scan.
```

### Query Restructuring

Show the optimised query alongside the original:
```java
// Before: N+1 — loads customer for each invoice in the loop
List<Invoice> invoices = invoiceRepository.findByTenantId(tenantId);

// After: Single query with JOIN FETCH
@Query("SELECT i FROM Invoice i JOIN FETCH i.customer WHERE i.tenantId = :tenantId")
List<Invoice> findByTenantIdWithCustomer(@Param("tenantId") String tenantId);
```

### Caching

If appropriate, suggest caching at the service layer:
- What to cache and for how long.
- Cache invalidation strategy.
- Implementation with Spring Cache abstraction.

### Schema Changes

If the schema itself is problematic:
- Denormalization suggestions for read-heavy queries.
- Materialized views or summary tables for reporting queries.
- Flyway migration to implement the change.

## Output Format

```
## Query Optimisation Report

### Current Performance
- Query: [The query being analysed]
- Estimated execution time: [if known]
- Issues identified: [count]

### Issues Found

#### Issue 1: [Description]
**Impact:** [HIGH | MEDIUM | LOW]
**Root cause:** [Explanation]
**Fix:** [Specific code/SQL change]
**Expected improvement:** [Estimate]

### Recommended Index Changes
[SQL for new indexes with rationale]

### Migration File (if schema changes needed)
[Complete Flyway migration]

### Updated Code
[Complete updated repository/service code]
```
