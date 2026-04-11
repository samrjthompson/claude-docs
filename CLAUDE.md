# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is a **Claude Code Starter Kit** — a collection of reusable skills, documentation layers, and MCP configurations. It contains **no application code**. It is purely an AI development environment configuration kit that gets installed into real projects to eliminate the cold-start problem.

## Architecture

The kit has four main components:

### Skills (`skills/`)

The primary delivery mechanism. Skills are directories containing a `SKILL.md` file with YAML frontmatter. They are installed into projects or user-level `~/.claude/skills/` via `install.sh`.

Skills are organised into five categories:

- **`conventions/`** — Stack-specific background knowledge (auto-triggered, `user-invocable: false`). Installed at project level so they only load in relevant projects. Each convention skill uses the `paths` field to trigger on matching file types. Large conventions are split across SKILL.md (rules) and companion `.md` files (code examples).
  - `java/` — JVM naming, Java directory tree, Mockito/TestContainers, exception hierarchy, MDC logging
  - `spring-boot/` — Package-by-feature structure, service/controller/DTO patterns, testing, security, multi-tenancy
  - `react/` — Component structure, React Query, TypeScript conventions, testing, auth
  - `kafka/` — Topic naming, event envelope, producer/consumer, error handling, testing

- **`generation/`** — Code scaffolding commands (user-invocable, project-level). Produce complete, runnable code — no placeholders or TODOs.
  - `new-entity/` — Complete JPA entity package (entity, repository, service, controller, DTOs, mapper, tests, migration)
  - `new-endpoint/` — Add endpoint to an existing feature
  - `new-migration/` — Flyway SQL migration with rollback comment
  - `new-kafka-topic/` — Full Kafka setup (event DTO, producer, consumer, topic config, DLT, tests)
  - `new-react-page/` — Page component, API hooks, route registration, MSW tests
  - `new-react-component/` — Reusable component with props interface, Tailwind, test

- **`analysis/`** — Review and audit commands (user-invocable, user-level). General-purpose — useful in any project.
  - `review/` — 8-category code review (Architecture, Naming, Errors, Validation, Testing, Security, Quality, API)
  - `security-check/` — Injection, auth/authz, data exposure, config, deps, multi-tenancy
  - `test-gaps/` — Test inventory, required coverage, missing scenarios, quality assessment
  - `dependency-check/` — Outdated versions, CVEs, unnecessary deps, licence compliance
  - `api-consistency/` — URL naming, HTTP methods, response structure, status codes, docs

- **`refactoring/`** — Code improvement commands (user-invocable, project-level).
  - `extract-service/` — Move business logic from controller to service
  - `add-validation/` — 4-layer validation (DTO Bean Validation, controller @Valid, service business rules, entity invariants)
  - `add-tests/` — Generate missing tests for controllers, services, repositories, React
  - `optimise-query/` — N+1, missing indexes, inefficient joins, unbounded results, caching

- **`workflows/`** — Complex multi-step reasoning prompts (user-invocable, user-level).
  - `system-design/` — 8-section design checklist before writing code
  - `debugging/` — 7-step systematic debugging (does NOT jump to a fix)
  - `performance/` — Measure first, then diagnose db/app/network/caching layers
  - `migration-planning/` — 8-section migration plan with rollback at every step
  - `code-archaeology/` — 6-phase codebase exploration and documentation
  - `mvp-scoping/` — Feature classification (MUST/SHOULD/COULD/WON'T) + technical spec
  - `domain-discovery/` — Entity extraction, relationships, workflows, rules, glossary

- **`promote/`** — User-level skill for backporting conventions from a project back into this kit.

### Universal Layer (`layers/base/universal.md`)

Stack-agnostic engineering standards (coding philosophy, naming, package-by-feature, git, testing, error handling, logging, security). Installed to `~/.claude/CLAUDE.md` by `./install.sh setup` so it applies to every project automatically without appearing in each project's CLAUDE.md.

### Domain Template (`templates/domain.md`)

A fill-in template for project-specific business context (entities, workflows, terminology, roles). Users copy this to their project, fill it in, and append it to their project's CLAUDE.md.

### MCP Configuration (`mcp/`)

Template (`mcp-config-template.json`) and setup guide for Model Context Protocol servers (filesystem, git, PostgreSQL, MySQL, Docker, Brave Search, memory). Copied to a project's `.claude/mcp.json` and edited with project-specific connection details.

## Key Conventions When Editing This Kit

- **Convention skills must not contradict each other.** All tech skills complement the universal layer. If a skill needs different behaviour, it should explicitly state the override.
- **Generation skills produce complete, runnable code.** No placeholders or TODOs. All generation skills output every file needed for a feature.
- **Package-by-feature is non-negotiable** across all skills. Code is organised by business feature, not by technical layer.
- **Conventional Commits** format: `type(scope): description` — used in all skills' git conventions.
- **SKILL.md files stay under 500 lines.** Larger skills split into SKILL.md + companion `.md` files in the same directory.

## Installation

```bash
# One-time user setup
./install.sh setup

# Per-project
./install.sh /path/to/project java spring-boot react
```

See `README.md` for full installation options and skill descriptions.
