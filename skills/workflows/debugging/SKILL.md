---
name: debugging
description: Debug a bug methodically — reproduce, isolate, hypothesise, test hypotheses, find root cause, fix, verify. Does NOT jump to a fix.
argument-hint: "[bug description: expected behaviour, actual behaviour, error messages, reproduction steps, environment, frequency]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git log *) Bash(git diff *)
---

# Systematic Debugging

Do NOT jump to a fix. Walk through the structured debugging process below.

## Bug Description

$ARGUMENTS

(If the above is insufficient, ask the user for: expected behaviour, actual behaviour, error messages or logs, reproduction steps, environment, and frequency before proceeding.)

## Debugging Process

Follow these steps in order. Do not skip ahead.

**Step 1: Reproduce**
- Can you identify the exact conditions to reproduce this bug?
- What is the minimum set of inputs or actions that trigger it?
- Is the bug deterministic or intermittent?

**Step 2: Isolate**
- Where in the system does the failure occur? Narrow to a specific layer (controller, service, repository, database, frontend, external service).
- What was the last change before this bug appeared? Check recent commits.
- Is the issue in our code or in a dependency?

**Step 3: Hypothesise**
- Based on the symptoms, what are the most likely causes? List at least 3 hypotheses, ranked by probability.
- For each hypothesis, what evidence would confirm or rule it out?

**Step 4: Test Hypotheses**
- For each hypothesis, describe a specific test to verify it.
- Start with the highest-probability hypothesis.
- What data should I check? (database state, request/response payloads, environment variables, etc.)

**Step 5: Root Cause**
Once you identify the root cause, explain:
- Why does this bug exist?
- When was it introduced?
- Why was it not caught by existing tests?

**Step 6: Fix**
- Propose a fix. Explain why it addresses the root cause.
- Are there risks or side effects?
- What tests should be added to prevent regression?

**Step 7: Verify**
- How do we verify the fix works?
- Are there related areas with the same bug?
- Should we do a broader audit?

At each step, show your reasoning. Do not provide a fix until Steps 1–5 are complete.
