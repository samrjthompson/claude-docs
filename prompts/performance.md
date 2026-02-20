# Performance Analysis Prompt

Use this prompt when an endpoint, query, or feature is too slow and you need Claude Code to help diagnose and optimise it.

## How to Use

Provide this prompt along with the slow endpoint or operation, any available metrics, and what you have already tried.

---

## Prompt

I have a performance issue that needs analysis and optimisation. Walk me through a systematic investigation.

### Problem Description

**Slow operation:** [Endpoint, query, page load, background job, etc.]
**Current performance:** [Response time, throughput, or other metric]
**Target performance:** [What it should be]
**Data scale:** [How much data is involved — table sizes, result set sizes, concurrent users]
**When it started:** [Always been slow, or recently degraded?]

### Investigation Process

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
  - Is there unnecessary data being loaded (selecting * when only a few columns needed)?
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

### Solution Proposals

For each issue found, provide:
1. The specific change (code, query, index, cache, schema).
2. Expected improvement with reasoning.
3. Implementation complexity (quick fix vs. significant refactor).
4. Trade-offs and risks.
5. How to verify the improvement.

### Prioritisation

Rank all proposed changes by impact/effort ratio. Implement the highest-impact, lowest-effort changes first.

### Output Format

1. **Findings**: What is causing the performance issue.
2. **Quick Wins**: Changes that can be made in under an hour with significant impact.
3. **Medium-Term**: Changes that require a few hours and architectural consideration.
4. **Long-Term**: Fundamental changes that would require significant refactoring.
