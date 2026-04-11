# Claude Code Starter Kit

A repository of reusable skills, documentation layers, and MCP configurations for Claude Code. Pull from this kit every time you start a new software project to eliminate the cold-start problem.

**This is NOT an application template or code scaffolding tool.** It contains no application code. It is purely an AI development environment configuration kit — everything Claude Code needs to understand how you work, what your standards are, and how to produce code that matches your expectations.

---

## What Is in This Kit

```
claude-code-starter-kit/
├── skills/                             # Claude Code skills (SKILL.md format)
│   ├── conventions/                    # Auto-triggered background knowledge (project-level)
│   │   ├── java/SKILL.md               # Java/JVM naming and structural conventions
│   │   ├── spring-boot/                # Spring Boot conventions (split across files)
│   │   │   ├── SKILL.md
│   │   │   ├── controller-patterns.md
│   │   │   ├── testing-patterns.md
│   │   │   └── security-config.md
│   │   ├── react/                      # React/TypeScript conventions
│   │   │   ├── SKILL.md
│   │   │   ├── component-patterns.md
│   │   │   └── testing-and-auth.md
│   │   └── kafka/                      # Kafka conventions
│   │       ├── SKILL.md
│   │       └── producer-consumer.md
│   ├── generation/                     # Code scaffolding skills (project-level)
│   │   ├── new-entity/SKILL.md         # Complete JPA entity package
│   │   ├── new-endpoint/SKILL.md       # Add endpoint to existing feature
│   │   ├── new-migration/SKILL.md      # Flyway SQL migration
│   │   ├── new-kafka-topic/SKILL.md    # Kafka topic + producer/consumer/tests
│   │   ├── new-react-page/SKILL.md     # Page with routing and API integration
│   │   └── new-react-component/SKILL.md  # Reusable React component
│   ├── analysis/                       # Code review skills (user-level)
│   │   ├── review/SKILL.md             # Full code review against standards
│   │   ├── security-check/SKILL.md     # Security vulnerability scan
│   │   ├── test-gaps/SKILL.md          # Missing test coverage analysis
│   │   ├── dependency-check/SKILL.md   # Dependency health check
│   │   └── api-consistency/SKILL.md    # REST API consistency audit
│   ├── refactoring/                    # Code improvement skills (project-level)
│   │   ├── extract-service/SKILL.md    # Move logic from controller to service
│   │   ├── add-validation/SKILL.md     # Add comprehensive input validation
│   │   ├── add-tests/SKILL.md          # Generate missing tests
│   │   └── optimise-query/SKILL.md     # Database query analysis and optimisation
│   ├── workflows/                      # Complex multi-step skills (user-level)
│   │   ├── system-design/SKILL.md      # Design before coding
│   │   ├── debugging/SKILL.md          # Systematic bug investigation
│   │   ├── performance/SKILL.md        # Performance diagnosis and optimisation
│   │   ├── migration-planning/SKILL.md # Migration strategy and execution plan
│   │   ├── code-archaeology/SKILL.md   # Explore an unfamiliar codebase
│   │   ├── mvp-scoping/SKILL.md        # Scope a minimum viable product
│   │   └── domain-discovery/SKILL.md   # Extract domain knowledge
│   └── promote/SKILL.md                # /promote — backport conventions to this kit
├── layers/
│   └── base/
│       └── universal.md                # Stack-agnostic standards (→ ~/.claude/CLAUDE.md)
├── templates/
│   └── domain.md                       # Domain context template (fill per project)
├── mcp/                                # MCP server configuration
│   ├── mcp-config-template.json
│   └── setup-guide.md
├── quickstart/
│   └── spring-react-saas.md            # Step-by-step guide for the common stack
├── install.sh                          # Install skills to user or project
└── README.md                           # This file
```

---

## Installation

### One-Time Setup

Install user-level skills and the universal `CLAUDE.md` to your home directory:

```bash
./install.sh setup
```

This:
- Writes `layers/base/universal.md` to `~/.claude/CLAUDE.md` — stack-agnostic engineering standards that apply to every project automatically
- Copies `skills/analysis/`, `skills/workflows/`, and `skills/promote/` to `~/.claude/skills/`

### Per-Project Setup

Install stack-specific skills into a project:

```bash
./install.sh /path/to/your/project java spring-boot react
```

This copies the matching convention, generation, and refactoring skills to `/path/to/your/project/.claude/skills/`.

**Supported stacks:**

| Argument | Skills installed |
|---|---|
| `java` | `conventions/java` |
| `spring-boot` | `conventions/java`, `conventions/spring-boot`, all generation and refactoring skills |
| `react` | `conventions/react`, `new-react-page`, `new-react-component` |
| `kafka` | `conventions/kafka`, `new-kafka-topic` |

### Common Combinations

| Project Type | Command |
|---|---|
| Spring Boot API | `./install.sh /path/to/project java spring-boot` |
| Spring Boot + React SaaS | `./install.sh /path/to/project java spring-boot react` |
| Spring Boot + Kafka | `./install.sh /path/to/project java spring-boot kafka` |
| Full stack with events | `./install.sh /path/to/project java spring-boot react kafka` |

---

## Skills

Skills are Claude Code's native format for reusable prompts. Each skill lives in a directory containing a `SKILL.md` file with YAML frontmatter.

### Convention Skills (auto-triggered, no invocation needed)

Convention skills have `user-invocable: false` — they load automatically when you open matching files. They provide background knowledge Claude Code uses to produce consistent code.

```
skills/conventions/java/          → loads when editing *.java files
skills/conventions/spring-boot/   → loads when editing *.java files
skills/conventions/react/         → loads when editing *.tsx, *.ts files
skills/conventions/kafka/         → loads when editing *kafka*, *event* files
```

Large convention skills are split across multiple files in the same directory. The `SKILL.md` holds the core rules; companion `.md` files contain detailed code examples linked from the main file.

### Generation Skills (user-invocable, project-level)

```
/new-entity Product name:String price:BigDecimal status:ProductStatus
/new-endpoint GET /products/{id}/reviews
/new-migration add_index_to_products_sku
/new-kafka-topic order.placed OrderPlacedEvent
/new-react-page ProductList
/new-react-component DataTable
```

### Analysis Skills (user-invocable, user-level)

```
/review
/security-check
/test-gaps
/dependency-check
/api-consistency
```

### Refactoring Skills (user-invocable, project-level)

```
/extract-service OrderController
/add-validation CreateOrderRequest
/add-tests OrderService
/optimise-query GET /orders - 3s response with 50k records
```

### Workflow Skills (user-invocable, user-level)

```
/system-design "payment processing with recurring billing"
/debugging "NPE in OrderService.calculateTax() on checkout"
/performance "GET /orders - 3s at p95 with 50k rows"
/migration-planning "extract billing into a separate service"
/code-archaeology "I'm inheriting this codebase, need to understand it"
/mvp-scoping "a tool that helps developers track time spent per PR"
/domain-discovery "here are my notes from a stakeholder interview..."
```

---

## Domain Context Template

Each project needs a domain context document that describes its business entities, workflows, rules, and terminology. Copy the template and fill it in:

```bash
cp templates/domain.md /path/to/your/project/DOMAIN.md
# Edit DOMAIN.md with your project's specifics
# Then add it to your project CLAUDE.md:
echo "" >> /path/to/your/project/CLAUDE.md
cat /path/to/your/project/DOMAIN.md >> /path/to/your/project/CLAUDE.md
```

---

## The /promote Skill

The `/promote` skill lets you backport a convention discovered during a project back into this kit. It is installed at user level by `./install.sh setup` and is available in every project.

From any project, run `/promote` and describe the convention. Claude Code will locate the correct skill file in claude-docs, update it, commit the change, and open a PR for review.

---

## MCP Servers

MCP servers give Claude Code access to external tools: databases, Docker, web search, and more.

1. Copy the template: `cp mcp/mcp-config-template.json /path/to/your/project/.claude/mcp.json`
2. Edit the configuration with your project's connection details.
3. Remove servers you do not need.
4. Follow `mcp/setup-guide.md` for detailed setup and verification.

---

## Quick Start

For a step-by-step walkthrough of starting a new Spring Boot + React SaaS project using this kit, see `quickstart/spring-react-saas.md`.

---

## Contributing Back to the Kit

When you discover a useful pattern during a project, promote it back into the kit.

**From inside a project:** Run `/promote` — the skill handles locating the right convention file, editing it, committing, and opening a PR.

**Manually:**
- New convention → edit the appropriate `skills/conventions/*/SKILL.md` or companion file
- New generation/refactoring pattern → edit the appropriate `skills/generation/` or `skills/refactoring/` skill
- New workflow → add a skill to `skills/workflows/`
- New MCP server → add it to `mcp/mcp-config-template.json` and `mcp/setup-guide.md`

Keep the kit evolving. Every project should leave this repository a little better than it found it.
