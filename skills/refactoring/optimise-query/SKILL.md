---
name: optimise-query
description: Analyse and optimise a slow database query — identify N+1 issues, missing indexes, inefficient joins, unbounded result sets, and generate index migrations
argument-hint: "[slow endpoint or repository method] [symptoms: 3s response time with 10k records] [data characteristics if known]"
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Glob
---

# Optimise Database Query

Analyse and optimise a slow or inefficient database query. Suggest indexes, query restructuring, caching, or schema changes.

## Required Input

Use `$ARGUMENTS` to determine:
- **The slow query or endpoint**: Which repository method, service call, or endpoint is slow.
- **Symptoms**: Response time, query execution time, or observation.
- **Data characteristics** (if known): Table size, typical query patterns, data distribution.

Read the relevant repository, service, and entity before analysing.

## Analysis Process

### 1. Identify the Query

Locate the actual SQL being executed:
- Derived queries — determine the generated SQL.
- `@Query` annotations — read the JPQL/SQL directly.
- Specifications — reconstruct the generated SQL.
- Check for N+1 queries by examining entity relationships.

### 2. Analyse Query Plan

Suggest running `EXPLAIN ANALYZE` on the query and look for:
- Full table scan
- Indexes not being used
- Unnecessary joins
- Sort on non-indexed column
- Estimated vs. actual row count discrepancy

### 3. Check for Common Issues

**N+1 Queries:**
- Entity relationship traversal triggering lazy-load queries in a loop.
- Fix: `JOIN FETCH` or `@EntityGraph`.

**Missing Indexes:**
- Queries filtering or sorting on non-indexed columns.
- Fix: Create indexes.

**Unnecessary Data Loading:**
- Loading entire entities when only a few fields are needed.
- Fix: Projections (DTO-based or interface-based).

**Inefficient Joins:**
- Cartesian products or joining large tables without selectivity.
- Fix: Add WHERE clauses, or restructure as subqueries.

**Pagination Without Efficient Counting:**
- `SELECT COUNT(*)` on the full dataset every page request.
- Fix: Keyset pagination, or cache the total count.

**Large Result Sets:**
- Returning thousands of records without pagination.
- Fix: Mandatory pagination with sensible defaults.

### 4. Propose Solutions

For each issue:
- **The problem**: What is causing slowness.
- **The fix**: Specific code or schema change.
- **Expected impact**: How much improvement to expect.
- **Trade-offs**: Any downsides (index write overhead, cache staleness, etc.).

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

## Solution Patterns

### Index recommendation
```sql
CREATE INDEX idx_invoices_tenant_status ON invoices (tenant_id, status);
-- Rationale: The list endpoint filters by tenant_id and status on every request.
```

### N+1 fix
```java
// Before: N+1 — loads customer for each invoice
List<Invoice> invoices = invoiceRepository.findByTenantId(tenantId);

// After: Single query with JOIN FETCH
@Query("SELECT i FROM Invoice i JOIN FETCH i.customer WHERE i.tenantId = :tenantId")
List<Invoice> findByTenantIdWithCustomer(@Param("tenantId") String tenantId);
```
