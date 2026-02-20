# Quick Start: Spring Boot + React SaaS Project

This guide walks you through setting up a new Spring Boot API + React frontend + MySQL + Keycloak SaaS application using the Claude Code Starter Kit.

---

## Step 1: Create Your Project Repository

```bash
mkdir my-saas-app
cd my-saas-app
git init
```

## Step 2: Compose Your CLAUDE.md

Assemble the CLAUDE.md from the starter kit layers:

```bash
# From the starter kit directory
cd /path/to/claude-code-starter-kit/layers
./compose.sh /path/to/my-saas-app/CLAUDE.md base spring-boot react
```

This gives you a CLAUDE.md with universal standards, Spring Boot conventions, and React conventions.

## Step 3: Add Domain Context

Copy the domain template and fill it in:

```bash
cp /path/to/claude-code-starter-kit/layers/domain/TEMPLATE.md /path/to/my-saas-app/DOMAIN.md
```

Edit `DOMAIN.md` with your project's specifics:
- Business domain description
- Core entities and relationships
- Key workflows and business rules
- User roles and permissions
- Terminology glossary

Once filled in, append it to your CLAUDE.md:

```bash
echo -e "\n\n<!-- === DOMAIN CONTEXT === -->\n" >> /path/to/my-saas-app/CLAUDE.md
cat /path/to/my-saas-app/DOMAIN.md >> /path/to/my-saas-app/CLAUDE.md
```

## Step 4: Copy Custom Commands

```bash
mkdir -p /path/to/my-saas-app/.claude/commands

# Copy the commands you will use most
cp /path/to/claude-code-starter-kit/commands/generation/new-entity.md \
   /path/to/claude-code-starter-kit/commands/generation/new-endpoint.md \
   /path/to/claude-code-starter-kit/commands/generation/new-migration.md \
   /path/to/claude-code-starter-kit/commands/generation/new-react-page.md \
   /path/to/claude-code-starter-kit/commands/generation/new-react-component.md \
   /path/to/claude-code-starter-kit/commands/analysis/review.md \
   /path/to/claude-code-starter-kit/commands/analysis/security-check.md \
   /path/to/claude-code-starter-kit/commands/analysis/test-gaps.md \
   /path/to/claude-code-starter-kit/commands/refactoring/add-tests.md \
   /path/to/claude-code-starter-kit/commands/refactoring/add-validation.md \
   /path/to/my-saas-app/.claude/commands/
```

## Step 5: Configure MCP Servers

```bash
mkdir -p /path/to/my-saas-app/.claude
cp /path/to/claude-code-starter-kit/mcp/mcp-config-template.json \
   /path/to/my-saas-app/.claude/mcp.json
```

Edit `.claude/mcp.json`:
- Update the MySQL connection details to match your local database.
- Update the filesystem server path to your project root.
- Remove servers you do not need (PostgreSQL if using MySQL, etc.).

Refer to `mcp/setup-guide.md` for detailed server setup instructions.

## Step 6: Set Up Local Infrastructure

Create a `docker-compose.yml` for local development:

```bash
# Ask Claude Code to help
# Paste this into Claude Code:

"Create a docker-compose.yml for local development with:
- MySQL 8.0 on port 3306
- Keycloak latest on port 8180 with a realm pre-configured for local development
- Kafka (KRaft mode, no ZooKeeper) on port 9092
- Kafka UI on port 8090
Follow the conventions in the CLAUDE.md."
```

## Step 7: Scaffold the Spring Boot Backend

With Claude Code and your CLAUDE.md in place, start building:

```
"Create the Spring Boot project structure with:
- Maven pom.xml with Spring Boot 4, Spring Data JPA, Spring Security (OAuth2 Resource Server), Flyway, MySQL connector, and TestContainers
- Application.java main class
- application.yml with local and prod profiles (following CLAUDE.md conventions)
- SecurityConfig for JWT authentication with Keycloak
- BaseEntity with UUID, auditing, tenant ID, and optimistic locking
- GlobalExceptionHandler with the standard exception hierarchy
- Common DTOs: ErrorResponse, ErrorDetail, PageResponse
- TenantContext and TenantInterceptor
- The first Flyway migration creating any shared tables"
```

## Step 8: Scaffold the React Frontend

```
"Create the React project structure with:
- Vite + TypeScript configuration
- Tailwind CSS setup
- Path alias @ mapped to src/
- Project structure following CLAUDE.md React conventions (app/, features/, shared/)
- HTTP client with auth interceptor
- Auth provider and context with Keycloak integration
- Protected route component
- Route configuration with lazy loading
- Shared components: Button, Input, LoadingSpinner, ErrorDisplay, EmptyState, PageHeader
- Test setup with Vitest, Testing Library, and MSW"
```

## Step 9: Create Your First Feature

Use the `new-entity` command to generate a complete feature:

```
Follow the new-entity command to create a Customer entity with fields:
- name (String, required, max 255)
- email (String, required, unique per tenant, max 255)
- company (String, optional, max 255)
- status (CustomerStatus: ACTIVE, SUSPENDED, CANCELLED)

And create the corresponding React pages:
- Customer list page with status filter and search
- Customer detail page
- Create customer form
```

This generates the full vertical slice: entity, repository, service, controller, DTOs, mapper, migration, tests on the backend, and list/detail/form pages on the frontend.

## Step 10: Verify Everything Works

```
"Run the following checks:
1. Start Docker Compose infrastructure
2. Run the Spring Boot backend and verify it starts without errors
3. Run the backend tests
4. Run the React frontend and verify it starts without errors
5. Run the frontend tests
6. Verify the Customer CRUD endpoints work via curl or the Swagger UI"
```

---

## What You Now Have

After completing this quickstart, your project has:

- A comprehensive `CLAUDE.md` that guides Claude Code to produce consistent, high-quality code.
- Custom commands for rapidly generating new features, endpoints, and components.
- Analysis commands for ongoing code quality checks.
- MCP servers connecting Claude Code to your database and infrastructure.
- A running Spring Boot API + React frontend with authentication, multi-tenancy, and a complete first feature.

From here, use the `new-entity` and `new-react-page` commands to add features. Use `review` and `security-check` commands periodically. Use the prompt templates for complex design decisions.

---

## Tips for Working with Claude Code Using This Kit

- **Start every feature with `new-entity`.** It produces the full vertical slice. Modify from there rather than writing from scratch.
- **Run `review` before every PR.** Catches convention deviations before code review.
- **Use `system-design` for non-trivial features.** Spend 10 minutes on design to save hours on rework.
- **Keep your domain template up to date.** As the project evolves, update the domain context so Claude Code stays aligned with current business rules.
- **Contribute patterns back.** When you write a good prompt or discover a useful convention, add it to the starter kit for next time.
