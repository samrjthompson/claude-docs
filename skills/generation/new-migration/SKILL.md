---
name: new-migration
description: Generate a Flyway database migration SQL file with rollback comment, following project naming and SQL conventions
argument-hint: "[description: add status column to invoices | create payment_methods table] [details about columns, indexes, constraints]"
disable-model-invocation: true
allowed-tools: Read, Write, Glob
---

# Create Flyway Migration

Generate a Flyway database migration following project conventions.

## Required Input

Use `$ARGUMENTS` to determine:
- **Description**: What this migration does (e.g., "add status column to invoices", "create payment_methods table")
- **Migration type**: Schema change, data migration, or index addition
- **Details**: Specific columns, constraints, indexes, or data transformations

Before generating, check `src/main/resources/db/migration/` to determine the next version number.

## Output

### Migration File

File name: `V{version}__{description}.sql`

- Next version number from existing migrations.
- Zero-padded three-digit: `V001`, `V002`, etc.
- Description in `snake_case`: `create_customers_table`, `add_status_to_invoices`.

### File Structure

```sql
-- Migration: V{version}__{description}.sql
-- Description: {Human-readable description}
-- Rollback: {SQL to reverse this migration}

{Migration SQL}
```

### SQL Conventions

- `IF NOT EXISTS` for CREATE TABLE and CREATE INDEX where possible.
- `NOT NULL` explicitly on all non-nullable columns.
- `DEFAULT` values where appropriate.
- UUID columns: `CHAR(36) NOT NULL`.
- Timestamp columns: `TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`.
- String columns: `VARCHAR(n)` with explicit length.
- Monetary columns: `DECIMAL(19,4)`.
- Boolean columns: `TINYINT(1) NOT NULL DEFAULT 0`.
- Always include `tenant_id VARCHAR(50) NOT NULL` on tenant-scoped tables.
- Audit columns: `created_at`, `updated_at`, `version BIGINT NOT NULL DEFAULT 0`.
- Index naming: `idx_{table}_{columns}`.
- Foreign key naming: `fk_{table}_{referenced_table}`.
- Unique constraint naming: `uq_{table}_{columns}`.
- Always create indexes on `tenant_id` and foreign keys.

## Output Format

Generate the complete SQL file with the rollback comment header. If the migration is complex, include explanatory comments within the SQL.
