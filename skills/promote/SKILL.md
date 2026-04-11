---
name: promote
description: Promotes a convention from this project's CLAUDE.md to the claude-docs starter kit, creating a branch and PR for review.
argument-hint: "[optional: description of convention to promote]"
allowed-tools: Read, Edit, Bash
disable-model-invocation: true
---

# Promote Convention to Claude Docs

Promotes a convention or standard from the current project's CLAUDE.md to the appropriate
source layer in the claude-docs starter kit, so that future projects inherit it automatically.

**Installation:**
- Global use (recommended): copy `skills/promote/` to `~/.claude/skills/promote/`
- Team use: copy `skills/promote/` to `.claude/skills/promote/` in the project

**Invocation:** `/promote [optional description]`

---

## Process

Work through the following steps in order. Do not skip steps or merge them. At each
confirmation point, stop and wait for the user's response before continuing.

### Step 1 — Identify the convention to promote

If `$ARGUMENTS` is non-empty, treat it as the user's description of the convention they
want to promote. Ask them to confirm or paste the exact content they want added to the
layer file.

If `$ARGUMENTS` is empty:
1. Read the project's CLAUDE.md
2. Look for the PROJECT ADDITIONS section (marked with
   `<!-- PROJECT ADDITIONS -->` or similar)
3. Extract all content below that marker — this is the candidate content
4. If no PROJECT ADDITIONS marker exists, identify content that appears to have been
   hand-added: anything that falls outside the `<!-- LAYER: ... -->` blocks, or any
   section that looks like a new convention rather than boilerplate
5. Present the identified content to the user and ask: "Is this the convention you want
   to promote? Please confirm, edit, or paste the exact text you want added."

Wait for the user to confirm the content before proceeding.

### Step 2 — Validate reusability

Before proceeding, check the confirmed content for project-specific references that
would make it unsuitable for the shared kit:

- Named classes, services, or entities specific to this project
  (e.g., `CustomerController`, `OrderService`, `BillingJob`)
- Project-specific package names, URLs, or routes
- Business domain terminology specific to this project
  (e.g., "claims", "policies", "shipments" when those are this project's domain)
- References to specific internal tools, teams, or infrastructure

If any project-specific references are found, flag them to the user:
"The following content looks project-specific and should be generalised before
promoting: [list items]. Please provide a generalised version."

Wait for the user to provide a clean, generalised version before continuing.

### Step 3 — Determine the target layer

Based on the content, identify which layer file it belongs in:

| Content type | Target skill file |
|---|---|
| Universal principles: coding philosophy, testing, error handling, git, naming rules, logging, security | `layers/base/universal.md` |
| Java naming, JVM idioms, Mockito, Lombok, exception hierarchy, MDC, Javadoc | `skills/conventions/java/SKILL.md` |
| Spring Boot patterns: controllers, services, repositories, DTOs, config | `skills/conventions/spring-boot/SKILL.md` |
| Spring Boot controller/DTO/mapper examples | `skills/conventions/spring-boot/controller-patterns.md` |
| Spring Boot testing patterns (MockMvc, Mockito, fixtures) | `skills/conventions/spring-boot/testing-patterns.md` |
| Spring Boot security (OAuth2/JWT, TenantInterceptor) | `skills/conventions/spring-boot/security-config.md` |
| React/TypeScript: components, hooks, state, routing | `skills/conventions/react/SKILL.md` |
| React component/API/form patterns | `skills/conventions/react/component-patterns.md` |
| React testing and auth patterns | `skills/conventions/react/testing-and-auth.md` |
| Kafka: producers, consumers, serialisation, retry, DLQ patterns | `skills/conventions/kafka/SKILL.md` |
| Kafka producer/consumer implementation examples | `skills/conventions/kafka/producer-consumer.md` |

Present your recommendation to the user:
"I think this belongs in `[layer file]` because [one-sentence reason]. Does that sound
right, or should it go elsewhere?"

Wait for confirmation.

### Step 4 — Locate the claude-docs repository

Determine the path to the claude-docs repository using this priority order:

1. **Parse `Source:` lines from the project CLAUDE.md.** Each generated layer block
   contains a `Source:` line with the full path to the layer file:
   ```
   <!-- LAYER: spring-boot
        Source: /home/sam/dev/claude-docs/layers/tech/spring-boot/CLAUDE.md -->
   ```
   Extract the directory by stripping `/layers/tech/...` from the end of the first
   match. Verify the resulting directory exists and contains `skills/` or `layers/`.

2. **If no `Source:` lines are found** (hand-written CLAUDE.md), ask the user:
   "I couldn't determine the claude-docs path from this project's CLAUDE.md.
   Where is your claude-docs repository? (e.g., `~/dev/claude-docs`)"

Once the path is confirmed, set `CLAUDE_DOCS_ROOT` to the resolved absolute path for
use in subsequent steps.

### Step 5 — Check for duplicates

Read the target layer file at `$CLAUDE_DOCS_ROOT/[target layer path]`.

Search for content that is semantically similar to the convention being promoted. Look
for matching section headings, similar bullet points, or equivalent rules described in
different words.

If a close match is found, present both versions side by side:
"A similar convention already exists in this layer:

**Existing:**
[existing content]

**Proposed:**
[new content]

Should I: (a) update the existing entry, (b) add the new entry alongside it,
or (c) abandon — the existing version already covers it?"

Wait for the user's choice before continuing.

### Step 6 — Apply the change

Edit the target layer file to add (or update) the convention:

- Find the section heading it belongs under (e.g., "Testing Patterns", "Error Handling",
  "Naming Conventions"). If no appropriate section exists, add a new one.
- Insert the content following the existing Markdown style of that file:
  same heading level, bullet style, and code fence language.
- Do not alter any other content in the file.

Show the user a brief diff-style summary of the change:
"Adding to `[layer file]`:

```
[the added/changed content]
```

Proceeding with git workflow..."

### Step 7 — Git workflow in claude-docs

Run all git commands in the `$CLAUDE_DOCS_ROOT` directory. Before starting, verify:
- `git` is available
- `gh` is available (for creating the PR)
- The repository has a configured remote (`git remote -v`)

If `gh` is not available or no remote is configured, skip the push/PR steps and
instead print the manual steps at the end.

**Branch name:** derive a short slug from the convention description (lowercase,
hyphens, max 40 characters):
`promote/{layer-name}-{slug}` — e.g., `promote/spring-boot-uuid-id-strategy`

Run the following in sequence, stopping and reporting any error:

```
git -C "$CLAUDE_DOCS_ROOT" checkout -b promote/{skill}-{slug}
git -C "$CLAUDE_DOCS_ROOT" add {target-skill-path}
git -C "$CLAUDE_DOCS_ROOT" commit -m "feat({skill}): {one-line description}"
git -C "$CLAUDE_DOCS_ROOT" push -u origin promote/{skill}-{slug}
gh pr create \
  --repo {remote-repo} \
  --title "feat({skill}): {one-line description}" \
  --body "$(cat <<EOF
## Convention promoted from project

**Source project:** {project name or path}
**Target skill:** {skill file}

### Change

{the promoted content}

### Why

{user's description or inferred rationale}

🤖 Promoted via \`/promote\` from [Claude Code Starter Kit](https://github.com/...).
EOF
)"
```

The `--repo` flag value is derived from `git -C "$CLAUDE_DOCS_ROOT" remote get-url origin`,
stripping the protocol and `.git` suffix to produce `owner/repo` format.

### Step 8 — Report outcome

Output a clean summary:

```
Convention promoted successfully.

Skill updated:  {full path to skill file}
Branch:         promote/{skill}-{slug}
PR:             {PR URL}

To use the updated skill in this project:
  cp -r {claude-docs-root}/skills/{skill-dir} .claude/skills/
```

If the git/PR workflow was skipped due to missing tools, output the manual steps
instead:

```
Skill updated:  {full path to skill file}

Manual steps to open a PR:
  cd {claude-docs-root}
  git checkout -b promote/{skill}-{slug}
  git add {target-skill-path}
  git commit -m "feat({skill}): {description}"
  git push -u origin promote/{skill}-{slug}
  gh pr create --title "feat({skill}): {description}"
```
