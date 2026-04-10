---
name: performance
description: Systematically investigate and optimise a performance issue — measure first, then diagnose database, application, network, and caching layers
argument-hint: "[slow operation description, current performance, target, data scale, when it started]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob
---

# Performance Analysis

Systematic investigation and optimisation of a performance issue. Measure before optimising.

## Problem Description

$ARGUMENTS

(If the above is insufficient, ask for: the slow operation, current performance metric, target performance, data scale, when it started.)

## Investigation Process

**1. Measure First**

Before optimising anything, establish a baseline:
- What is the actual response time at p50, p95, p99?
- Where is time being spent? Break down by: database queries, application logic, serialisation, network.
- Are there multiple slow operations or one dominant bottleneck?

**2. Database Layer**

- List all queries executed during this operation.
- For each query:
  - What is the execution plan? (`EXPLAIN ANALYZE`)
  - Is it using indexes effectively?
  - Are there N+1 queries?
  - How many rows does it scan vs. return?
  - Is there unnecessary data being loaded?
- Check for lock contention or blocking queries.

**3. Application Layer**

- Is there expensive computation in the service layer?
- Are there sequential operations that could be parallelised?
- Is there unnecessary object creation or memory allocation?
- Are there redundant database calls (fetching the same data multiple times)?
- Is serialisation/deserialisation a bottleneck (large response payloads)?

**4. Network and I/O**

- Are there external service calls adding latency?
- Is response payload size contributing to slowness?
- Are there unnecessary round trips between services?

**5. Caching Opportunities**

- Is the same data being computed or fetched repeatedly?
- What data changes infrequently and could be cached?
- What is the acceptable staleness for cached data?

## Solution Proposals

For each issue found, provide:
1. The specific change (code, query, index, cache, schema).
2. Expected improvement with reasoning.
3. Implementation complexity (quick fix vs. significant refactor).
4. Trade-offs and risks.
5. How to verify the improvement.

## Output Format

1. **Findings**: What is causing the performance issue.
2. **Quick Wins**: Changes that can be made in under an hour with significant impact.
3. **Medium-Term**: Changes requiring a few hours and architectural consideration.
4. **Long-Term**: Fundamental changes requiring significant refactoring.

Rank all proposed changes by impact/effort ratio. Implement highest-impact, lowest-effort first.
