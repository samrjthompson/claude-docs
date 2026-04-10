---
name: add-tests
description: Generate missing tests for existing code — controller, service, repository, mapper, and React component tests following project testing conventions
argument-hint: "[target: ClassName | feature-name | 'all'] [priority: controllers|services|repositories|all]"
disable-model-invocation: true
allowed-tools: Read, Write, Glob, Grep
---

# Generate Missing Tests

Generate tests for existing code that lacks test coverage, following the project's testing conventions.

## Required Input

Use `$ARGUMENTS` to determine:
- **Target**: Specific class, feature package, or "all" to analyse the entire project.
- **Priority** (optional): Focus on controllers, services, repositories, or all layers.

Read the implementation thoroughly before generating tests. Understand behaviour, not just method signatures.

## Analysis Phase

Before generating, analyse:
1. **What the code does**: Read the implementation to understand behaviour.
2. **Dependencies**: Identify what needs to be mocked vs. real implementations.
3. **Edge cases**: Boundary conditions, null handling, empty collections, error paths.
4. **Existing tests**: Check for partial tests to avoid duplication.

## Test Generation by Component Type

### Controller Tests (`@WebMvcTest`)

For each controller endpoint, test:
- Valid request → expected success response and status code
- Missing required fields → 400 with validation error details
- Invalid field values → 400 with specific field errors
- Entity not found → 404 with error response
- Business rule violation → 422 with error response
- Unauthenticated request → 401

Use `MockMvc`, `@MockitoBean` for the service, JWT test support, and `TestFixtures` pattern.

### Service Tests (`@ExtendWith(MockitoExtension.class)`)

For each public service method, test:
- Happy path with valid input → expected return value and side effects
- Not found scenarios → correct exception type
- Business rule violations → correct exception type
- Input edge cases → correct handling (empty lists, boundary values)
- Multi-tenancy → operations only affect the correct tenant

Use `@Mock`, `@InjectMocks`, and `TestFixtures`.

### Repository Tests

For each custom query method, test:
- Returns expected results for matching criteria
- Returns empty for non-matching criteria
- Filters by tenant correctly
- Handles null parameters gracefully
- Ordering and pagination correct

### Mapper Tests

For each mapping method, test:
- All fields are mapped correctly
- Null handling for optional fields
- Collection mapping (empty and populated)
- Nested object mapping

### React Component Tests

For each component, test:
- Renders with required props
- Displays correct content from data
- Loading, error, and empty states render correctly
- User interactions trigger expected callbacks
- Form validation displays error messages

## Test Quality Requirements

Every generated test must:
- Follow Arrange-Act-Assert structure with visual separation.
- Have a descriptive name: `methodName_scenario_expectedResult`.
- Test one concept per test.
- Use test fixtures, not inline object construction.
- Include all necessary imports.
- Be immediately runnable without modification.
- Use JUnit Jupiter assertions (`assertEquals`, `assertThrows`) for Java, not AssertJ.

## Output Format

Generate complete test files. If adding to an existing test class, show the complete updated file.
