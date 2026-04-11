# Quick Start: Spring Boot + React SaaS Project

This guide walks you through setting up a new Spring Boot API + React frontend + MySQL + Keycloak SaaS application using the Claude Code Starter Kit.

---

## Step 1: Create Your Project Repository

```bash
mkdir my-saas-app
cd my-saas-app
git init
```

## Step 2: Install User-Level Skills (once, not per project)

If you have not already done this:

```bash
# From the starter kit directory
./install.sh setup
```

This installs universal standards to `~/.claude/CLAUDE.md` and user-level skills (analysis, workflows, promote) to `~/.claude/skills/`.

## Step 3: Install Project-Level Skills

```bash
./install.sh /path/to/my-saas-app java spring-boot react
```

This installs to `/path/to/my-saas-app/.claude/skills/`:
- `java` and `spring-boot` convention skills (auto-triggered when editing `.java` files)
- `react` convention skill (auto-triggered when editing `.tsx`/`.ts` files)
- All generation skills: `new-entity`, `new-endpoint`, `new-migration`, `new-react-page`, `new-react-component`
- All refactoring skills: `extract-service`, `add-validation`, `add-tests`, `optimise-query`

## Step 4: Add Domain Context

Copy the domain template and fill it in:

```bash
cp /path/to/claude-code-starter-kit/templates/domain.md /path/to/my-saas-app/DOMAIN.md
```

Edit `DOMAIN.md` with your project's specifics:
- Business domain description
- Core entities and relationships
- Key workflows and business rules
- User roles and permissions
- Terminology glossary

Once filled in, create a `CLAUDE.md` in your project with the domain context:

```bash
echo "# Project Context" > /path/to/my-saas-app/CLAUDE.md
cat /path/to/my-saas-app/DOMAIN.md >> /path/to/my-saas-app/CLAUDE.md
```

Alternatively, use `/domain-discovery` in Claude Code if you have interview notes or a verbal domain description to start from.

## Step 5: Configure MCP Servers

```bash
mkdir -p /path/to/my-saas-app/.claude
cp /path/to/claude-code-starter-kit/mcp/mcp-config-template.json \
   /path/to/my-saas-app/.claude/mcp.json
```

Edit `.claude/mcp.json`:
- Update the MySQL connection details to match your local database.
- Update the filesystem server path to your project root.
- Remove servers you do not need.

Refer to `mcp/setup-guide.md` for detailed server setup instructions.

## Step 6: Set Up Local Infrastructure

Create a `docker-compose.yml` for local development:

```
"Create a docker-compose.yml for local development with:
- MySQL 8.0 on port 3306
- Keycloak latest on port 8180 with a realm pre-configured for local development
- Kafka (KRaft mode, no ZooKeeper) on port 9092
- Kafka UI on port 8090
Follow the conventions in the CLAUDE.md."
```

## Step 7: Scaffold the Spring Boot Backend

With Claude Code and your skills in place, start building:

```
"Create the Spring Boot project structure with:
- Maven pom.xml with Spring Boot 4, Spring Data JPA, Spring Security (OAuth2 Resource Server), Flyway, MySQL connector, and TestContainers
- Application.java main class
- application.yml with local and prod profiles (following project conventions)
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
- Project structure following project conventions (app/, features/, shared/)
- HTTP client with auth interceptor
- Auth provider and context with Keycloak integration
- Protected route component
- Route configuration with lazy loading
- Shared components: Button, Input, LoadingSpinner, ErrorDisplay, EmptyState, PageHeader
- Test setup with Vitest, Testing Library, and MSW"
```

## Step 9: Create Your First Feature

Use the `new-entity` skill to generate a complete feature:

```
/new-entity Customer name:String:required email:String:required:unique company:String status:CustomerStatus:ACTIVE,SUSPENDED,CANCELLED
```

Then generate the corresponding React pages:

```
/new-react-page CustomerList
/new-react-page CustomerDetail
```

This generates the full vertical slice: entity, repository, service, controller, DTOs, mapper, migration, tests on the backend, and list/detail pages on the frontend.

## Step 10: Verify Everything Works

```
"Run the following checks:
1. Start Docker Compose infrastructure
2. Run the Spring Boot backend and verify it starts without errors
3. Run the backend tests
4. Run the React frontend and verify it starts without errors
5. Run the frontend tests
6. Verify the Customer CRUD endpoints work via curl"
```

---

## What You Now Have

After completing this quickstart, your project has:

- Universal engineering standards in `~/.claude/CLAUDE.md` applied automatically.
- Convention skills in `.claude/skills/` that auto-trigger when editing Java or TypeScript files.
- Generation and refactoring skills available as slash commands.
- Analysis and workflow skills available from user-level installation.
- MCP servers connecting Claude Code to your database and infrastructure.
- A running Spring Boot API + React frontend with authentication, multi-tenancy, and a complete first feature.

---

## Tips for Working with Claude Code Using This Kit

- **Start every feature with `/new-entity`.** It produces the full vertical slice. Modify from there rather than writing from scratch.
- **Run `/review` before every PR.** Catches convention deviations before code review.
- **Use `/system-design` for non-trivial features.** Spend 10 minutes on design to save hours on rework.
- **Keep your domain context up to date.** As the project evolves, update `DOMAIN.md` and your project `CLAUDE.md` so Claude Code stays aligned with current business rules.
- **Contribute patterns back.** When you write a good prompt or discover a useful convention, run `/promote` to add it to the starter kit for next time.
