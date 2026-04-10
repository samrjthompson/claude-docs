---
name: extract-service
description: Refactor business logic out of a controller into a service class — identify logic to move, create/update service, simplify controller to 3-7 lines per method, update tests
argument-hint: "[ControllerClass] [method names to extract, or 'all']"
disable-model-invocation: true
allowed-tools: Read, Edit, Glob
---

# Extract Service from Controller

Refactor business logic out of a controller into a proper service class, following the project's package-by-feature architecture.

## When to Use

Use when a controller contains:
- Database queries or repository calls directly in controller methods.
- Business validation or computation in controller methods.
- Multiple sequential operations orchestrated in a controller method.
- Transaction management in controller code.

## Required Input

Use `$ARGUMENTS` to determine:
- **Controller class**: The controller that needs refactoring.
- **Methods to extract**: Which controller methods contain business logic to move (or "all").

Read the controller and any existing service before proceeding.

## Refactoring Steps

### 1. Identify Business Logic

In the controller, identify code that is NOT controller responsibility:
- **Controller responsibility**: parse request, validate input (`@Valid`), extract tenant ID, call service, return response.
- **Service responsibility**: business rules, orchestration, database operations, external calls, event publishing, logging business operations.

### 2. Create or Modify Service Class

If no service exists for this feature:
- Create `{Feature}Service.java` in the same feature package.
- Annotate with `@Service` and `@Transactional(readOnly = true)`.
- Constructor injection for all dependencies.

If a service already exists:
- Add new methods to the existing service.

### 3. Move Logic to Service Methods

For each extracted method:
- **Method signature**: Takes primitive parameters and request DTOs, returns response DTOs. Never takes `HttpServletRequest` or Spring MVC types.
- **Transaction annotation**: `@Transactional` on methods that mutate data.
- **Logging**: INFO-level logging for business operations with relevant IDs.
- **Exceptions**: Throw specific exceptions (`ResourceNotFoundException`, `BusinessRuleException`). Do not catch and re-wrap unless adding context.

### 4. Simplify Controller

After extraction, each controller method should be 3-7 lines:
1. Extract tenant ID from principal.
2. Call service method.
3. Return response.

### 5. Update Tests

- **Controller tests**: Mock the service. Test HTTP concerns only (status codes, request validation, response format).
- **Service tests**: Create or update service tests for the extracted business logic. Test happy paths, error conditions, and edge cases.

## Output Format

Show:
1. The refactored controller (complete file).
2. The new or modified service (complete file).
3. Updated or new controller tests.
4. New service tests.

Clearly mark what changed in existing files versus what is new.
