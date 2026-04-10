---
name: test-gaps
description: Identify missing tests and test quality issues — checks coverage by feature package, missing scenarios, and Arrange-Act-Assert compliance
argument-hint: "[optional: specific feature or file to check]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob
---

# Test Coverage Gap Analysis

Identify areas with insufficient test coverage relative to the project's testing standards.

## Scope

If `$ARGUMENTS` specifies a feature or file, focus there. Otherwise scan the full project.

## Analysis Process

### 1. Inventory Existing Tests

Scan the test directory and categorise all existing tests:
- Controller tests (`@WebMvcTest`)
- Service tests (`@ExtendWith(MockitoExtension.class)`)
- Repository tests (`@DataJpaTest`)
- Mapper tests
- Integration tests (Kafka, external services)
- React component tests

### 2. Check Against Required Coverage

For each feature package, verify these tests exist:

**Backend (per feature):**
- [ ] Controller test: valid request, validation failure, not found, per endpoint
- [ ] Service test: happy path, business rule violations, edge cases, per public method
- [ ] Repository test for each custom query (not derived simple queries)
- [ ] Mapper test for non-trivial mapping logic
- [ ] Kafka producer test (if feature produces events)
- [ ] Kafka consumer integration test (if feature consumes events)

**Frontend (per feature):**
- [ ] Page component test: data loaded, loading state, error state, empty state
- [ ] Form component test: valid submission, validation errors, submission failure
- [ ] Critical shared component tests

### 3. Identify Missing Test Scenarios

For existing tests, check for:
- **Error paths**: Error conditions tested, not just happy paths?
- **Boundary conditions**: Empty lists, max values, null handling?
- **Multi-tenancy**: Tenant isolation verified?
- **Concurrent operations**: Race conditions or optimistic locking failures?
- **Idempotency**: For Kafka consumers, duplicate message handling?

### 4. Assess Test Quality

Flag tests with:
- No assertions (test runs but verifies nothing)
- Only `assertNotNull` (too weak)
- Testing implementation details rather than behaviour
- `Thread.sleep` instead of Awaitility
- No Arrange-Act-Assert structure
- Shared mutable state between tests

## Output Format

```
## Test Coverage Gap Report

**Overall Assessment:** [GOOD | ADEQUATE | INSUFFICIENT | POOR]

### Missing Tests by Feature

#### {Feature Name}
| Component | Test Status | Missing Scenarios |
|-----------|------------|-------------------|
| Controller | Partial | Missing validation failure test for POST /endpoint |
| Service | Missing | No tests exist |
| Repository | Complete | — |

### Missing Scenarios in Existing Tests
- [{File}:{TestClass}] Missing error path for {method}
- [{File}:{TestClass}] Missing tenant isolation test

### Test Quality Issues
- [{File}:{TestClass}:{method}] {Quality issue description}

### Priority Recommendations
1. [Most impactful test to add first]
2. [Second priority]
3. [Third priority]
```
