# Generate Feature Package for New Entity

Generate a complete feature package for a new JPA entity following the project's package-by-feature architecture and conventions defined in the CLAUDE.md layers.

## Required Input

Provide the following:
- **Entity name** (PascalCase, singular): e.g., `Product`, `Subscription`, `PaymentMethod`
- **Package path**: e.g., `com.example.app.product`
- **Fields** (name, type, constraints): e.g., `name String required maxLength=255`, `price BigDecimal required`, `status ProductStatus required`
- **Relationships** (optional): e.g., `belongsTo Customer`, `hasMany OrderItem`

## Files to Generate

Generate ALL of the following files within the feature package. Do not skip any file.

### 1. Entity Class (`{EntityName}.java`)

- Extend `BaseEntity` from `common` package.
- Map all specified fields with appropriate JPA annotations.
- Use `@Column` with explicit `name`, `nullable`, and length/precision attributes.
- Use `@Enumerated(EnumType.STRING)` for enum fields.
- Use `@ManyToOne(fetch = FetchType.LAZY)` for relationships.
- Include business methods that encapsulate entity invariants.
- Initialise collection fields inline: `new ArrayList<>()`.
- No JSON annotations on entities.

### 2. Repository Interface (`{EntityName}Repository.java`)

- Extend `JpaRepository<{EntityName}, UUID>`.
- Include `findByIdAndTenantId` method.
- Include `findAllByTenantId` with `Pageable` parameter.
- Add any derived query methods implied by the entity's fields (e.g., `findByEmailAndTenantId` for entities with email).
- Every query method must include `tenantId` parameter.

### 3. Service Class (`{EntityName}Service.java`)

- Class-level `@Transactional(readOnly = true)`.
- Constructor injection only. No `@Autowired`.
- Methods: `create`, `getById`, `list` (paginated), `update`, `delete`.
- `create` and `update` methods annotated with `@Transactional`.
- Throw `{EntityName}NotFoundException` for missing entities.
- Validate business rules before mutations.
- Return Response DTOs, never entities.
- Log at INFO level for all mutations with entity ID and tenant ID.

### 4. Controller Class (`{EntityName}Controller.java`)

- `@RestController` with `@RequestMapping("/api/v1/{entity-plural-kebab}")`.
- OpenAPI annotations: `@Tag`, `@Operation` on every endpoint.
- Standard CRUD endpoints:
  - `POST /` → create (201)
  - `GET /{id}` → get by ID (200)
  - `GET /` → list with pagination (200)
  - `PUT /{id}` → update (200)
  - `DELETE /{id}` → delete (204)
- Extract tenant ID from `JwtAuthenticationToken`.
- Use `@Valid` on request body parameters.

### 5. Request DTOs

- `Create{EntityName}Request.java` — Java record with Bean Validation annotations. Every annotation has a `message` attribute.
- `Update{EntityName}Request.java` — Java record, may have fewer required fields than create.

### 6. Response DTOs

- `{EntityName}Response.java` — Full entity representation for detail endpoints.
- `{EntityName}SummaryResponse.java` — Reduced representation for list endpoints.

### 7. Mapper Class (`{EntityName}Mapper.java`)

- `final` class with private constructor.
- Static methods: `toResponse`, `toSummaryResponse`.
- Named `{EntityName}Mapper`.

### 8. Exception Class (`{EntityName}NotFoundException.java`)

- Extend `ResourceNotFoundException`.
- Constructor takes `UUID id`.

### 9. Enum Classes (if entity has enum fields)

- One file per enum.
- Values in `UPPER_SNAKE_CASE`.

### 10. Flyway Migration (`V{next_version}__create_{table_name}_table.sql`)

- Use the next available migration version number.
- Include rollback SQL as a comment at the top.
- `id CHAR(36) NOT NULL PRIMARY KEY`.
- `tenant_id VARCHAR(50) NOT NULL`.
- `created_at TIMESTAMP NOT NULL`.
- `updated_at TIMESTAMP NOT NULL`.
- `version BIGINT NOT NULL DEFAULT 0`.
- Create appropriate indexes (at minimum on `tenant_id`).
- Add foreign key constraints for relationships.

### 11. Test Fixtures (`{EntityName}TestFixtures.java`)

- `final` class with private constructor.
- Static factory methods for creating test entities, request DTOs, and response DTOs.

### 12. Controller Test (`{EntityName}ControllerTest.java`)

- `@WebMvcTest` with mocked service.
- Test each endpoint: valid request, validation failure, not found.
- Use JWT test support for authentication.

### 13. Service Test (`{EntityName}ServiceTest.java`)

- `@SpringBootTest` with `@Transactional`.
- Test create, get, list, update, delete.
- Test not-found scenarios.
- Test business rule violations.

## Output Format

Generate each file with its full path relative to `src/main/java/` or `src/test/java/`. Include complete, compilable code with all imports. Do not use placeholder comments or TODOs.
