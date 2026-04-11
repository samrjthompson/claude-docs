---
name: new-entity
description: Generate a complete JPA entity feature package — entity, repository, service, controller, DTOs, mapper, tests, and Flyway migration
argument-hint: "[EntityName] [package:com.example.app.feature] [fields: name:String:required price:BigDecimal:required status:EntityStatus:required] [relationships: belongsTo:Customer]"
disable-model-invocation: true
allowed-tools: Read, Write, Bash(mkdir *)
---

# Generate Feature Package for New Entity

Generate a complete feature package for a new JPA entity following the project's package-by-feature architecture and conventions defined in the CLAUDE.md layers.

## Required Input

Use `$ARGUMENTS` to determine:
- **Entity name** (PascalCase, singular): e.g., `Product`, `Subscription`, `PaymentMethod`
- **Package path**: e.g., `com.example.app.product`
- **Fields** (name, type, constraints): e.g., `name String required maxLength=255`, `price BigDecimal required`, `status ProductStatus required`
- **Relationships** (optional): e.g., `belongsTo Customer`, `hasMany OrderItem`

If any of these are missing from `$ARGUMENTS`, ask the user before proceeding.

## Files to Generate

Generate ALL of the following files. Do not skip any file.

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
- Add derived query methods implied by the entity's fields.
- Every query method must include `tenantId` parameter.

### 3. Service Class (`{EntityName}Service.java`)

- Class-level `@Transactional(readOnly = true)`.
- Constructor injection only. No `@Autowired`.
- Methods: `create`, `getById`, `list` (paginated), `update`, `delete`.
- `create` and `update` annotated with `@Transactional`.
- Throw `{EntityName}NotFoundException` for missing entities.
- Validate business rules before mutations.
- Return Response DTOs, never entities.
- Log at INFO level for all mutations with entity ID and tenant ID.

### 4. Controller Class (`{EntityName}Controller.java`)

- `@RestController` with no class-level `@RequestMapping`.
- Standard CRUD endpoints with full paths on each method:
  - `POST /api/v1/{entity-plural-kebab}` → create (201)
  - `GET /api/v1/{entity-plural-kebab}/{id}` → get by ID (200)
  - `GET /api/v1/{entity-plural-kebab}` → list with pagination (200)
  - `PUT /api/v1/{entity-plural-kebab}/{id}` → update (200)
  - `DELETE /api/v1/{entity-plural-kebab}/{id}` → delete (204)
- Extract tenant ID from `JwtAuthenticationToken`.
- Use `@Valid` on request body parameters.

### 5. Request DTOs

- `Create{EntityName}Request.java` — Java record with `@Builder` and Bean Validation annotations. Every annotation has a `message` attribute.
- `Update{EntityName}Request.java` — Java record, may have fewer required fields than create.

### 6. Response DTOs

- `{EntityName}Response.java` — Full entity representation for detail endpoints.
- `{EntityName}SummaryResponse.java` — Reduced representation for list endpoints.

### 7. Mapper Class (`{EntityName}Mapper.java`)

- `final` class with private constructor.
- Static methods: `toResponse`, `toSummaryResponse`.

### 8. Exception Class (`{EntityName}NotFoundException.java`)

- Extend `ResourceNotFoundException`.
- Constructor takes `UUID id`.

### 9. Enum Classes (if entity has enum fields)

- One file per enum.
- Values in `UPPER_SNAKE_CASE`.

### 10. Flyway Migration (`V{next_version}__create_{table_name}_table.sql`)

- Next available migration version number.
- Rollback SQL as a comment at the top.
- `id CHAR(36) NOT NULL PRIMARY KEY`.
- `tenant_id VARCHAR(50) NOT NULL`.
- `created_at TIMESTAMP NOT NULL`.
- `updated_at TIMESTAMP NOT NULL`.
- `version BIGINT NOT NULL DEFAULT 0`.
- Appropriate indexes (at minimum on `tenant_id`).
- Foreign key constraints for relationships.

### 11. Test Fixtures (`{EntityName}TestFixtures.java`)

- `final` class with private constructor.
- Static factory methods for creating test entities, request DTOs, and response DTOs.

### 12. Controller Test (`{EntityName}ControllerTest.java`)

- `@WebMvcTest` with mocked service.
- Test each endpoint: valid request, validation failure, not found.
- Use JWT test support for authentication.

### 13. Service Test (`{EntityName}ServiceTest.java`)

- `@ExtendWith(MockitoExtension.class)` with `@Mock` and `@InjectMocks`.
- Test create, get, list, update, delete.
- Test not-found scenarios.
- Test business rule violations.

## Output Format

Generate each file with its full path relative to `src/main/java/` or `src/test/java/`. Include complete, compilable code with all imports. Do not use placeholder comments or TODOs.
