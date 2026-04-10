---
name: review
description: Review code against engineering standards — architecture, naming, errors, validation, testing, security, code quality, API design. Outputs PASS/WARN/FAIL per category.
argument-hint: "[optional: specific files or feature to review, or leave empty for staged/recent changes]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob
---

# Code Review Against Standards

Review the specified code against the engineering standards defined in the project's CLAUDE.md layers.

## Scope

If `$ARGUMENTS` specifies files or a feature, review those. Otherwise review staged files, specified files, or recent changes.

Read all relevant source files before evaluating.

## Review Checklist

For each category, report: **PASS** (no issues), **WARN** (minor issues or suggestions), **FAIL** (violations that should be fixed).

### 1. Architecture Compliance

- Does the code follow package-by-feature organisation?
- Are feature boundaries respected (no cross-feature repository access)?
- Is shared code in `common` genuinely cross-cutting?
- Are DTOs used at API boundaries (entities never exposed)?

### 2. Naming Conventions

- Do class, method, variable, and package names follow conventions?
- Are names descriptive and unambiguous?
- Do boolean methods use `is`/`has`/`can` prefixes?
- Do database columns follow `snake_case` conventions?

### 3. Error Handling

- Are exceptions specific (not generic `RuntimeException`)?
- Are errors mapped to correct HTTP status codes?
- Do error responses follow the standard structure?
- Are errors logged with sufficient context?

### 4. Input Validation

- Are all request DTOs validated with Bean Validation annotations?
- Do validation annotations include `message` attributes?
- Is business validation performed in the service layer?
- Are potential null values handled?

### 5. Testing

- Are tests present for controllers, services, and custom queries?
- Do tests follow Arrange-Act-Assert structure?
- Are test names descriptive (`method_scenario_expectedResult`)?
- Are test fixtures used (not inline object construction)?
- Are edge cases and error paths tested?

### 6. Security

- Does every query filter by `tenantId`?
- Is tenant ID extracted from JWT (not request parameters)?
- Are endpoints secured with proper authentication?
- Is sensitive data excluded from logs and error responses?

### 7. Code Quality

- Is the code readable without comments?
- Are methods focused (single responsibility)?
- Is there unnecessary duplication?
- Are there magic strings or numbers that should be constants?
- Is the complexity appropriate (no over-engineering)?

### 8. API Design

- Do endpoints follow REST conventions?
- Is pagination implemented for list endpoints?
- Are response structures consistent?
- Is OpenAPI documentation present on all endpoints?

## Output Format

```
## Code Review Summary

**Overall Assessment:** [PASS | NEEDS WORK | SIGNIFICANT ISSUES]

### Architecture Compliance: [PASS|WARN|FAIL]
- [Finding or "No issues found"]

### Naming Conventions: [PASS|WARN|FAIL]
- [Finding or "No issues found"]

[... repeat for each category ...]

### Priority Fixes
1. [Most critical issue]
2. [Second priority]
3. [Third priority]

### Suggestions (Non-Blocking)
- [Optional improvements that are not violations]
```
