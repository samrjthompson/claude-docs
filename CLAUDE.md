# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is a **Claude Code Starter Kit** — a collection of reusable configuration files, documentation layers, custom commands, MCP configurations, and prompt templates. It contains **no application code**. It is purely an AI development environment configuration kit that gets copied into real projects to eliminate the cold-start problem.

## Architecture

The kit has four main components:

### Layers (`layers/`)

Composable CLAUDE.md documentation modules assembled into a project-specific CLAUDE.md. Layers are split across three tiers:

- **`universal`** (`layers/base/universal.md`) — Stack-agnostic engineering standards (coding philosophy, naming, package-by-feature, git, testing, error handling, logging, security). Written to `~/.claude/CLAUDE.md` (user memory), so it applies to every project automatically without appearing in each project's CLAUDE.md.
- **Language layer** (`layers/tech/java/CLAUDE.md`) — JVM-specific naming, Java directory tree, Mockito/TestContainers, exception hierarchy, MDC logging, Javadoc, Spring Security/Keycloak conventions.
- **Tech/stack layers** (`layers/tech/`) — `spring-boot`, `react`, `kafka`, `spark-java` add framework-specific conventions. Database layers (`mysql`, `postgres`, `mongodb`, `dynamodb`) provide persistence patterns. The `domain/TEMPLATE.md` is copied and filled in per-project with business context (entities, workflows, terminology, roles).

Use `layers/compose.sh` to assemble layers:
```bash
cd layers/
./compose.sh /path/to/project/CLAUDE.md universal java spring-boot react
```

The `universal` layer is written to `~/.claude/CLAUDE.md` by default. All other layers are written to the project output file. Use `--no-user-memory` to inline all layers into the project file instead.

### Custom Commands (`commands/`)

Prompt files for Claude Code's `/command` feature, organised into three categories:
- **generation/** — Scaffold complete feature packages (entities, endpoints, migrations, Kafka topics, React pages/components)
- **analysis/** — Review code against standards (review, security, test gaps, dependencies, API consistency)
- **refactoring/** — Improve existing code (extract service, add validation, add tests, optimise queries)

Most commands are copied to a project's `.claude/commands/` directory to be used.

### Skills (`skills/`)

User-level skills in the modern Claude Code skills format (a directory containing `SKILL.md` with YAML frontmatter). Skills support tool restrictions, invocation control, and argument hints.

**`skills/promote/`** — operates on the claude-docs kit itself rather than on a project. Copy it to `~/.claude/skills/promote/` (user-level) so it is available in every project. Once installed, `/promote` can be run from any project to backport a convention discovered during development back to the appropriate source layer in claude-docs, committing the change and opening a PR for review.

### MCP Configuration (`mcp/`)

Template (`mcp-config-template.json`) and setup guide for Model Context Protocol servers (filesystem, git, PostgreSQL, MySQL, Docker, Brave Search, memory). Copied to a project's `.claude/mcp.json` and edited with project-specific connection details.

### Prompt Templates (`prompts/`)

Structured prompts for complex multi-step scenarios (system design, debugging, performance, migration planning, code archaeology, MVP scoping, domain discovery). Users copy the prompt, fill in bracketed placeholders, and paste into Claude Code.

## Key Conventions When Editing This Kit

- **Layers must not contradict each other.** All tech layers complement the universal layer. If a tech layer needs different behaviour, it should explicitly state the override.
- **Commands produce complete, runnable code.** No placeholders or TODOs. All generation commands output every file needed for a feature (entity, DTOs, service, controller, tests, migration).
- **Package-by-feature is non-negotiable** across all layers. Code is organised by business feature, not by technical layer.
- **Conventional Commits** format: `type(scope): description` — used in all layers' git conventions.
- The compose script (`layers/compose.sh`) concatenates layers with HTML comment separators. The generated output should not be edited directly; edit source layers and recompose.

## Common Layer Combinations

| Project Type | Layers |
|---|---|
| Spring Boot API (MySQL) | universal java spring-boot mysql domain |
| Spring Boot API (Postgres) | universal java spring-boot postgres domain |
| Spring Boot + React SaaS | universal java spring-boot mysql react domain |
| Spring Boot + Kafka | universal java spring-boot postgres kafka domain |
| Full stack with events | universal java spring-boot mysql react kafka domain |
| Spring Boot + MongoDB | universal java spring-boot mongodb domain |
| Spark data pipeline | universal java spark-java domain |
