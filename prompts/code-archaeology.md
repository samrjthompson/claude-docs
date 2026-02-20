# Code Archaeology Prompt

Use this prompt when you are inheriting, returning to, or trying to understand an unfamiliar codebase. Claude Code will systematically explore and document the codebase.

## How to Use

Point Claude Code at the repository and provide any context you have (what the project does, why you are looking at it).

---

## Prompt

I need to understand this codebase. Explore it systematically and build me a mental model of how it works. Do NOT try to read every file — be strategic about what you examine.

### Context

**What this project does** (if known): [Brief description or "unknown — please figure it out"]
**Why I am looking at it:** [Inheriting it, debugging an issue, evaluating for acquisition, planning a refactor, etc.]
**What I specifically need to understand:** [Everything, a specific feature, the data model, the deployment process, etc.]

### Exploration Process

**Phase 1: Orientation (5 minutes)**
Start with the birds-eye view:
- Read `README.md` if it exists.
- Examine the project structure (top-level directories and files).
- Identify the technology stack from build files (`pom.xml`, `package.json`, `build.sbt`, `Dockerfile`, etc.).
- Check for configuration files that reveal infrastructure (Docker Compose, CI/CD, deployment configs).
- Read `CLAUDE.md` or any AI-assistant configuration if present.

Report: Project type, technology stack, rough size (files, packages), and apparent purpose.

**Phase 2: Architecture (10 minutes)**
Understand the high-level architecture:
- How is the code organised? (Package-by-feature, package-by-layer, monolith, microservices)
- What are the main entry points? (Application class, main function, route definitions)
- What are the major packages/modules and what does each seem responsible for?
- How does data flow through the system? (Request → Controller → Service → Repository → Database)
- What external systems does it integrate with? (Check for HTTP clients, message queues, third-party SDKs)
- What is the authentication/authorisation approach?

Report: Architecture diagram (text-based), package map with responsibilities, key integration points.

**Phase 3: Data Model (10 minutes)**
Understand what data the system manages:
- Examine entity/model classes.
- Map the relationships between entities.
- Check database migrations for the schema evolution.
- Identify the primary database and any secondary data stores.
- How is multi-tenancy handled (if applicable)?

Report: Entity list with key attributes and relationships, schema overview.

**Phase 4: Key Workflows (15 minutes)**
Trace the most important user-facing workflows:
- Identify the main features from controllers/routes.
- Pick the 3-5 most important features and trace each from HTTP request to database and back.
- Note any background jobs, scheduled tasks, or event-driven workflows.
- Identify where business logic lives (services, entities, controllers — is it well-separated?).

Report: For each traced workflow: endpoint → service method → repository calls → database tables → response.

**Phase 5: Code Quality Assessment (10 minutes)**
Evaluate the overall health:
- Is there a test suite? What is the approximate coverage (count test files vs. source files)?
- Are there consistent patterns or is the codebase a mix of styles?
- Are there obvious code smells (god classes, circular dependencies, copy-pasted code)?
- How old are the dependencies? Are they maintained?
- Is there documentation beyond the README?

Report: Quality assessment with specific examples, tech debt hotspots, areas of concern.

**Phase 6: Unknowns and Risks (5 minutes)**
Identify what you could not determine:
- What parts of the codebase are confusing or poorly documented?
- What looks fragile or risky?
- What questions would you ask the original developers?

### Output Format

Provide a structured report with sections for each phase. Keep it concise — this is a reference document, not a novel. Use bullet points and code references (file paths) liberally.

At the end, provide:
1. **One-paragraph summary** of what this codebase does and how it works.
2. **Architecture diagram** (text-based).
3. **Top 5 things to know** before making changes.
4. **Top 5 risks or concerns** about the codebase.
5. **Recommended next steps** based on why I am looking at this code.
