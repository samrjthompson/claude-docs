# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is a **Claude Code Starter Kit** — a collection of reusable configuration files, documentation layers, custom commands, MCP configurations, and prompt templates. It contains **no application code**. It is purely an AI development environment configuration kit that gets copied into real projects to eliminate the cold-start problem.

## Architecture

The kit has four main components:

### Layers (`layers/`)

Composable CLAUDE.md documentation modules that get assembled into a single project-specific CLAUDE.md. The `base/CLAUDE.md` layer defines universal engineering standards (naming, testing, errors, git, security) and should be included in every project. Technology layers under `tech/` (spring-boot, react, kafka, spark-java) add stack-specific conventions. Database layers (mysql, postgres, mongodb, dynamodb) provide persistence-specific patterns and are composed alongside the Spring Boot layer. The `domain/TEMPLATE.md` is copied and filled in per-project with business context (entities, workflows, terminology, roles).

Use `layers/compose.sh` to assemble layers:
```bash
cd layers/
./compose.sh /path/to/project/CLAUDE.md base spring-boot react
```

### Custom Commands (`commands/`)

Prompt files for Claude Code's `/command` feature, organised into three categories:
- **generation/** — Scaffold complete feature packages (entities, endpoints, migrations, Kafka topics, React pages/components)
- **analysis/** — Review code against standards (review, security, test gaps, dependencies, API consistency)
- **refactoring/** — Improve existing code (extract service, add validation, add tests, optimise queries)

Commands are copied to a project's `.claude/commands/` directory to be used.

### MCP Configuration (`mcp/`)

Template (`mcp-config-template.json`) and setup guide for Model Context Protocol servers (filesystem, git, PostgreSQL, MySQL, Docker, Brave Search, memory). Copied to a project's `.claude/mcp.json` and edited with project-specific connection details.

### Prompt Templates (`prompts/`)

Structured prompts for complex multi-step scenarios (system design, debugging, performance, migration planning, code archaeology, MVP scoping, domain discovery). Users copy the prompt, fill in bracketed placeholders, and paste into Claude Code.

## Key Conventions When Editing This Kit

- **Layers must not contradict each other.** All tech layers inherit from the base layer. If a tech layer needs different behaviour, it should explicitly state the override.
- **Commands produce complete, runnable code.** No placeholders or TODOs. All generation commands output every file needed for a feature (entity, DTOs, service, controller, tests, migration).
- **Package-by-feature is non-negotiable** across all layers. Code is organised by business feature, not by technical layer.
- **Conventional Commits** format: `type(scope): description` — used in all layers' git conventions.
- The compose script (`layers/compose.sh`) concatenates layers with HTML comment separators. The generated output should not be edited directly; edit source layers and recompose.

## Common Layer Combinations

| Project Type | Layers |
|---|---|
| Spring Boot API (MySQL) | base + spring-boot + mysql + domain |
| Spring Boot API (Postgres) | base + spring-boot + postgres + domain |
| Spring Boot + React SaaS | base + spring-boot + mysql + react + domain |
| Spring Boot + Kafka | base + spring-boot + postgres + kafka + domain |
| Full stack with events | base + spring-boot + mysql + react + kafka + domain |
| Spring Boot + MongoDB | base + spring-boot + mongodb + domain |
| Spark data pipeline | base + spark-java + domain |
