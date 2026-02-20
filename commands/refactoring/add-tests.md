# Generate Missing Tests

Generate tests for existing code that lacks test coverage, following the project's testing conventions.

## Required Input

- **Target**: Specific class, feature package, or "all" to analyse the entire project.
- **Priority** (optional): Focus on controllers, services, repositories, or all layers.

## Analysis Phase

Before generating tests, analyse the target code to understand:

1. **What the code does**: Read the implementation to understand behaviour, not just method signatures.
2. **Dependencies**: Identify what needs to be mocked vs. what uses real implementations.
3. **Edge cases**: Identify boundary conditions, null handling, empty collections, and error paths.
4. **Existing tests**: Check if partial tests exist to avoid duplication.

## Test Generation by Component Type

### Controller Tests

Generate `@WebMvcTest` tests for each controller endpoint:

```
For each endpoint, test:
- Valid request → expected success response and status code
- Missing required fields → 400 with validation error details
- Invalid field values → 400 with specific field errors
- Entity not found → 404 with error response
- Business rule violation → 422 with error response
- Unauthenticated request → 401
```

Use:
- `MockMvc` for HTTP requests.
- `@MockBean` for the service dependency.
- JWT test support for authentication.
- `BillingTestFixtures` pattern for test data.

### Service Tests

Generate `@SpringBootTest` tests with `@Transactional`:

```
For each public service method, test:
- Happy path with valid input → expected return value and side effects
- Not found scenarios → correct exception type
- Business rule violations → correct exception type
- Input edge cases → correct handling (empty lists, boundary values)
- Multi-tenancy → operations only affect the correct tenant
```

Use:
- Real repositories with TestContainers database.
- Test fixtures for entity construction.
- AssertJ for assertions.

### Repository Tests

Generate `@DataJpaTest` tests with TestContainers:

```
For each custom query method, test:
- Returns expected results for matching criteria
- Returns empty for non-matching criteria
- Filters by tenant correctly
- Handles null parameters gracefully
- Ordering is correct
- Pagination works correctly
```

### Mapper Tests

Generate unit tests for mapper methods:

```
For each mapping method, test:
- All fields are mapped correctly
- Null handling for optional fields
- Collection mapping (empty and populated)
- Nested object mapping
```

### React Component Tests

Generate tests using Testing Library:

```
For each component, test:
- Renders with required props
- Displays correct content from data
- Loading state renders correctly
- Error state renders correctly
- Empty state renders correctly
- User interactions trigger expected callbacks
- Form validation displays error messages
```

## Test Quality Requirements

Every generated test must:
- Follow Arrange-Act-Assert structure with visual separation.
- Have a descriptive name: `methodName_scenario_expectedResult`.
- Test one concept per test.
- Use test fixtures, not inline object construction.
- Include all necessary imports.
- Be immediately runnable without modification.

## Output Format

Generate complete test files. If adding tests to an existing test class, show the complete updated file.

For each test generated, briefly note what it verifies (one line above the test method as a comment is acceptable).
