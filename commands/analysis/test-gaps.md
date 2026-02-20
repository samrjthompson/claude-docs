# Test Coverage Gap Analysis

Identify areas with insufficient test coverage relative to the project's testing standards.

## Analysis Process

### 1. Inventory Existing Tests

Scan the test directory and categorise all existing tests:
- Controller tests (`@WebMvcTest`)
- Service tests (`@SpringBootTest`)
- Repository tests (`@DataJpaTest`)
- Mapper tests
- Integration tests (Kafka, external services)
- React component tests

### 2. Check Against Required Coverage

For each feature package, verify the following tests exist:

**Backend (per feature package):**
- [ ] Controller test with: valid request, validation failure, not found, for each endpoint
- [ ] Service test with: happy path, business rule violations, edge cases, for each public method
- [ ] Repository test for each custom query (not derived simple queries)
- [ ] Mapper test for any non-trivial mapping logic
- [ ] Kafka producer test (if feature produces events)
- [ ] Kafka consumer integration test (if feature consumes events)

**Frontend (per feature):**
- [ ] Page component test with: data loaded, loading state, error state, empty state
- [ ] Form component test with: valid submission, validation errors, submission failure
- [ ] Critical shared component tests

### 3. Identify Missing Test Scenarios

For existing tests, check for missing scenarios:
- **Error paths**: Are error conditions tested, not just happy paths?
- **Boundary conditions**: Are edge cases tested (empty lists, max values, null handling)?
- **Multi-tenancy**: Do tests verify tenant isolation?
- **Concurrent operations**: Are race conditions or optimistic locking failures tested?
- **Idempotency**: For Kafka consumers, is duplicate message handling tested?

### 4. Assess Test Quality

Flag tests with quality issues:
- Tests without assertions (tests that run but do not verify anything)
- Tests with only `assertNotNull` (too weak)
- Tests that test implementation details rather than behaviour
- Tests with hardcoded sleep instead of Awaitility
- Tests without Arrange-Act-Assert structure
- Tests that share mutable state

## Output Format

```
## Test Coverage Gap Report

**Overall Coverage Assessment:** [GOOD | ADEQUATE | INSUFFICIENT | POOR]

### Missing Tests by Feature

#### {Feature Name}
| Component | Test Status | Missing Scenarios |
|-----------|------------|-------------------|
| Controller | Partial | Missing validation failure test for POST /endpoint |
| Service | Missing | No tests exist |
| Repository | Complete | — |

### Missing Test Scenarios in Existing Tests
- [{File}:{TestClass}] Missing error path test for {method}
- [{File}:{TestClass}] Missing tenant isolation test

### Test Quality Issues
- [{File}:{TestClass}:{method}] {Quality issue description}

### Priority Recommendations
1. [Most impactful test to add first]
2. [Second priority]
3. [Third priority]
```
