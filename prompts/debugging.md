# Systematic Debugging Prompt

Use this prompt when you encounter a bug and want Claude Code to help you debug it methodically rather than guessing at fixes.

## How to Use

Provide this prompt along with a description of the bug: what you expected, what actually happened, and any error messages or logs.

---

## Prompt

I have a bug that I need to debug systematically. Do NOT jump to a fix. Instead, walk me through a structured debugging process.

### Bug Description

**Expected behaviour:** [What should happen]
**Actual behaviour:** [What actually happens]
**Error messages or logs:** [Paste any relevant error output]
**Reproduction steps:** [How to trigger the bug, if known]
**Environment:** [Local dev, staging, production, specific browser, etc.]
**Frequency:** [Always, intermittent, only under specific conditions]

### Debugging Process

Follow these steps in order. Do not skip ahead.

**Step 1: Reproduce**
- Can you identify the exact conditions to reproduce this bug?
- What is the minimum set of inputs or actions that trigger it?
- Is the bug deterministic or intermittent?

**Step 2: Isolate**
- Where in the system does the failure occur? Narrow it down to a specific layer (controller, service, repository, database, frontend, external service).
- What was the last change made before this bug appeared? Check recent commits.
- Is the issue in our code or in a dependency?

**Step 3: Hypothesise**
- Based on the symptoms, what are the most likely causes? List at least 3 hypotheses, ranked by probability.
- For each hypothesis, what evidence would confirm or rule it out?

**Step 4: Test Hypotheses**
- For each hypothesis, describe a specific test to verify it.
- Start with the highest-probability hypothesis.
- Add logging, breakpoints, or test cases as needed to gather evidence.
- What data should I check? (database state, request/response payloads, environment variables, etc.)

**Step 5: Root Cause**
- Once you identify the root cause, explain:
  - Why does this bug exist?
  - When was it introduced?
  - Why was it not caught by existing tests?

**Step 6: Fix**
- Propose a fix. Explain why this fix addresses the root cause.
- Are there any risks or side effects of this fix?
- What tests should be added to prevent regression?

**Step 7: Verify**
- How do we verify the fix works?
- Are there related areas that might have the same bug?
- Should we do a broader audit?

### Output

At each step, show your reasoning. Do not provide a fix until you have completed Steps 1-5.
