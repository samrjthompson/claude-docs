# Migration Planning Prompt

Use this prompt when planning a significant refactoring, data migration, or system change that carries risk and needs a structured approach.

## How to Use

Provide this prompt along with a description of the change: what is moving from what to what, why, and any constraints.

---

## Prompt

I need to plan a migration that requires careful execution. Help me think through every aspect to minimise risk and ensure a safe rollout.

### Migration Description

**What is changing:** [Describe the change — schema migration, service decomposition, library upgrade, architecture change, etc.]
**Why:** [The motivation for this change]
**Scope:** [What systems, services, or data are affected]
**Constraints:** [Downtime budget, data volume, timeline, team size]

### Planning Checklist

Work through each section:

**1. Current State Analysis**
- Document exactly how the system works today.
- What are all the dependencies on the current implementation?
- What data exists and what format is it in?
- What integrations touch the affected components?

**2. Target State Design**
- What does the system look like after migration?
- What are the differences between current and target?
- Are there any new requirements or opportunities to address during migration?

**3. Migration Strategy**
Choose and justify a strategy:
- **Big bang**: Everything changes at once. When is this appropriate?
- **Incremental**: Gradual migration over multiple deployments. How do you handle the intermediate states?
- **Blue-green**: Run old and new in parallel. How do you keep them in sync?
- **Strangler fig**: Gradually route traffic to the new implementation. How do you handle the dual-write period?

**4. Step-by-Step Execution Plan**
Break the migration into discrete, deployable steps. For each step:
- What changes are made?
- What is the expected impact on running systems?
- How do you verify this step succeeded?
- How do you roll back if it fails?
- Can this step be done during normal operating hours?

**5. Data Migration**
If data needs to be transformed or moved:
- How much data?
- Can it be done online (while the system is running) or offline?
- How do you handle data created between migration start and completion?
- How do you validate data integrity after migration?
- What is the backup strategy?

**6. Rollback Plan**
For each step in the execution plan:
- What is the rollback procedure?
- How long does rollback take?
- Is there any data loss on rollback?
- What triggers a rollback decision?

**7. Testing Strategy**
- How do you test the migration before running it in production?
- Can you run it against a copy of production data?
- What automated checks verify the migration succeeded?
- What manual checks are needed?

**8. Communication Plan**
- Who needs to know about this migration?
- What is the expected impact on users?
- Is a maintenance window needed?
- How do you communicate progress and issues?

### Output

Provide:
1. A clear decision on migration strategy with rationale.
2. A numbered step-by-step execution plan.
3. Rollback procedures for each step.
4. A risk register (what could go wrong and how likely is it).
5. A checklist for go/no-go decision before starting.
