# Claude Code Starter Kit

A repository of reusable configuration files, documentation layers, custom commands, MCP configurations, and prompt templates for Claude Code. Pull from this kit every time you start a new software project to eliminate the cold-start problem.

**This is NOT an application template or code scaffolding tool.** It contains no application code. It is purely an AI development environment configuration kit — everything Claude Code needs to understand how you work, what your standards are, and how to produce code that matches your expectations.

---

## What Is in This Kit

```
claude-code-starter-kit/
├── layers/                    # CLAUDE.md documentation layers
│   ├── base/CLAUDE.md         # Universal engineering standards
│   ├── tech/
│   │   ├── spring-boot/CLAUDE.md   # Spring Boot conventions
│   │   ├── react/CLAUDE.md         # React/TypeScript conventions
│   │   ├── kafka/CLAUDE.md         # Kafka messaging conventions
│   │   └── spark-java/CLAUDE.md   # Spark/Java conventions
│   ├── domain/TEMPLATE.md    # Domain context template (fill per project)
│   └── compose.sh            # Script to assemble layers into one CLAUDE.md
├── commands/                  # Claude Code custom commands
│   ├── generation/            # Code generation commands
│   │   ├── new-entity.md
│   │   ├── new-endpoint.md
│   │   ├── new-migration.md
│   │   ├── new-kafka-topic.md
│   │   ├── new-react-page.md
│   │   └── new-react-component.md
│   ├── analysis/              # Code analysis commands
│   │   ├── review.md
│   │   ├── security-check.md
│   │   ├── test-gaps.md
│   │   ├── dependency-check.md
│   │   └── api-consistency.md
│   └── refactoring/           # Refactoring commands
│       ├── extract-service.md
│       ├── add-validation.md
│       ├── add-tests.md
│       └── optimise-query.md
├── mcp/                       # MCP server configuration
│   ├── mcp-config-template.json
│   └── setup-guide.md
├── prompts/                   # Prompt templates for complex scenarios
│   ├── system-design.md
│   ├── debugging.md
│   ├── performance.md
│   ├── migration-planning.md
│   ├── code-archaeology.md
│   ├── mvp-scoping.md
│   └── domain-discovery.md
├── quickstart/
│   └── spring-react-saas.md   # Step-by-step guide for the common stack
└── README.md                  # This file
```

---

## How to Use the Layer System

The CLAUDE.md layer system lets you compose a project-specific `CLAUDE.md` from pre-written modules. Every project gets a tailored set of instructions without writing from scratch.

### Layers Available

| Layer | File | Purpose |
|-------|------|---------|
| Base | `layers/base/CLAUDE.md` | Universal principles: naming, testing, error handling, Git, security. Include in every project. |
| Spring Boot | `layers/tech/spring-boot/CLAUDE.md` | Entity patterns, repository conventions, service/controller design, DTOs, Flyway, testing, multi-tenancy. |
| React | `layers/tech/react/CLAUDE.md` | Project structure, components, state management, API integration, routing, forms, Tailwind, testing. |
| Kafka | `layers/tech/kafka/CLAUDE.md` | Producers, consumers, topic naming, error handling, dead letter topics, schema management, testing. |
| Spark/Java | `layers/tech/spark-java/CLAUDE.md` | Spring Boot integration, job structure, Java conventions, DataFrame patterns, schema definitions, testing. |
| Domain | `layers/domain/TEMPLATE.md` | Template for project-specific business context. Copy and fill in for each project. |

### Composing a CLAUDE.md

**Option 1: Use the compose script**

```bash
cd layers/
./compose.sh /path/to/your/project/CLAUDE.md base spring-boot react
```

This concatenates the selected layers with section headers into a single file.

**Option 2: Manual assembly**

Copy the contents of each layer you need into your project's `CLAUDE.md`, adding a header between each:

```markdown
<!-- === BASE LAYER === -->
[contents of layers/base/CLAUDE.md]

<!-- === SPRING BOOT LAYER === -->
[contents of layers/tech/spring-boot/CLAUDE.md]

<!-- === DOMAIN CONTEXT === -->
[contents of your filled-in domain template]
```

### Common Combinations

| Project Type | Layers |
|-------------|--------|
| Spring Boot API | base + spring-boot + domain |
| Spring Boot + React SaaS | base + spring-boot + react + domain |
| Spring Boot + Kafka | base + spring-boot + kafka + domain |
| Full stack with events | base + spring-boot + react + kafka + domain |
| Spark data pipeline | base + spark-java + domain |

### Customising Layers

After composing, review the CLAUDE.md and add project-specific overrides at the bottom. If a project needs different conventions for specific areas, add a "Project Overrides" section that takes precedence.

---

## How to Use Custom Commands

Custom commands are prompt files that Claude Code follows to generate, analyse, or refactor code.

### Setup

Copy the commands you need to your project's `.claude/commands/` directory:

```bash
mkdir -p /path/to/your/project/.claude/commands
cp commands/generation/new-entity.md /path/to/your/project/.claude/commands/
cp commands/analysis/review.md /path/to/your/project/.claude/commands/
# ... copy whichever commands you use
```

Or copy all commands at once:

```bash
cp -r commands/* /path/to/your/project/.claude/commands/
```

### Using Commands

In Claude Code, invoke a command by referencing it:

```
/new-entity Product
```

Or ask Claude Code to follow the command:

```
Follow the new-entity command to create a Product entity with fields:
- name (String, required, max 255)
- price (BigDecimal, required)
- sku (String, required, unique per tenant)
- status (ProductStatus: ACTIVE, DISCONTINUED)
```

### Available Commands

**Generation** — Create new code following project patterns:
- `new-entity` — Complete feature package (entity, repository, service, controller, DTOs, tests, migration)
- `new-endpoint` — Add endpoint to existing feature
- `new-migration` — Flyway migration with rollback
- `new-kafka-topic` — Full Kafka setup (producer, consumer, config, tests)
- `new-react-page` — Page with routing, API integration, and state handling
- `new-react-component` — Reusable component with typing and tests

**Analysis** — Review code for quality and consistency:
- `review` — Full code review against CLAUDE.md standards
- `security-check` — Security vulnerability scan
- `test-gaps` — Missing test coverage analysis
- `dependency-check` — Dependency health and vulnerability check
- `api-consistency` — REST API consistency audit

**Refactoring** — Improve existing code:
- `extract-service` — Move business logic from controller to service
- `add-validation` — Add comprehensive input validation
- `add-tests` — Generate missing tests for existing code
- `optimise-query` — Database query analysis and optimisation

---

## How to Set Up MCP Servers

MCP servers give Claude Code access to external tools: databases, Docker, web search, and more.

1. Copy the template: `cp mcp/mcp-config-template.json /path/to/your/project/.claude/mcp.json`
2. Edit the configuration with your project's connection details.
3. Remove servers you do not need.
4. Follow `mcp/setup-guide.md` for detailed setup and verification instructions.

---

## How to Use Prompt Templates

Prompt templates are for complex, multi-step scenarios that go beyond what a custom command covers.

Copy the relevant prompt, fill in the bracketed sections with your specific context, and paste it into Claude Code.

| Prompt | When to Use |
|--------|------------|
| `system-design` | Starting a new feature — think before coding |
| `debugging` | Stuck on a bug — systematic investigation |
| `performance` | Something is slow — diagnose and optimise |
| `migration-planning` | Big refactor or data migration — plan carefully |
| `code-archaeology` | Unfamiliar codebase — systematic exploration |
| `mvp-scoping` | New product idea — scope the minimum viable build |
| `domain-discovery` | New business domain — extract structured knowledge |

---

## Quick Start

For a step-by-step walkthrough of starting a new Spring Boot + React SaaS project using this kit, see `quickstart/spring-react-saas.md`.

---

## Contributing Back to the Kit

When you discover a useful pattern during a project, extract it back into the kit:

**New convention discovered?** Add it to the appropriate layer file under `layers/`.

**Wrote a good custom command?** Add it to `commands/` in the appropriate category.

**Found a useful prompt pattern?** Add it to `prompts/`.

**New MCP server useful?** Add it to the template and setup guide.

Keep the kit evolving. Every project should leave this repository a little better than it found it.
