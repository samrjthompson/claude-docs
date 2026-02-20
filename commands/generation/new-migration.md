# Create Flyway Migration

Generate a Flyway database migration following project conventions.

## Required Input

Provide the following:
- **Description**: What this migration does (e.g., "add status column to invoices", "create payment_methods table")
- **Migration type**: Schema change, data migration, or index addition
- **Details**: Specific columns, constraints, indexes, or data transformations

## Output

### Migration File

File name: `V{version}__{description}.sql`

- Determine the next version number by examining existing migrations in `src/main/resources/db/migration/`.
- Use zero-padded three-digit version numbers: `V001`, `V002`, etc.
- Description in `snake_case`: `create_customers_table`, `add_status_to_invoices`.

### File Structure

```sql
-- Migration: V{version}__{description}.sql
-- Description: {Human-readable description of what this migration does}
-- Rollback: {SQL statement(s) to reverse this migration}

{Migration SQL}
```

### SQL Conventions

- Use `IF NOT EXISTS` for CREATE TABLE and CREATE INDEX when possible.
- Specify `NOT NULL` explicitly on all columns that should not be null.
- Include `DEFAULT` values where appropriate.
- UUID columns: `CHAR(36) NOT NULL`.
- Timestamp columns: `TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`.
- String columns: `VARCHAR(n)` with explicit length.
- Monetary columns: `DECIMAL(19,4)`.
- Boolean columns: `TINYINT(1) NOT NULL DEFAULT 0`.
- Always include `tenant_id VARCHAR(50) NOT NULL` on tenant-scoped tables.
- Always include audit columns: `created_at`, `updated_at`, `version`.
- Create indexes on: `tenant_id`, foreign keys, frequently queried columns.
- Name indexes: `idx_{table}_{columns}`.
- Name foreign keys: `fk_{table}_{referenced_table}`.
- Name unique constraints: `uq_{table}_{columns}`.

### Output Format

Generate the complete SQL file with the rollback comment header. If the migration is complex, include explanatory comments within the SQL.
