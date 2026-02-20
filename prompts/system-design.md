# System Design Prompt

Use this prompt when starting a new feature and you want Claude Code to think through the architecture before writing code.

## How to Use

Provide this prompt along with a description of the feature you want to build. Include any requirements, constraints, and context about the existing system.

---

## Prompt

I need to design and implement a new feature. Before writing any code, I want you to think through the design systematically. Walk me through each of the following areas, and wait for my feedback before moving to implementation.

### Feature Description

[Describe the feature here. What should it do? Who uses it? What problem does it solve?]

### Design Checklist

Work through each section below. For each, explain your reasoning and any trade-offs.

**1. Data Model**
- What entities are involved? Are they new or modifications to existing entities?
- What are the relationships between entities?
- What are the key attributes, types, and constraints?
- Are there lifecycle states? Draw the state machine.
- What indexes will be needed for expected query patterns?
- How does this interact with multi-tenancy?

**2. API Design**
- What endpoints are needed? List each with HTTP method, path, request body, response body, and status codes.
- How do these endpoints relate to existing APIs? Are there consistency considerations?
- What pagination, filtering, or sorting is needed?
- Are there any long-running operations that need async handling?

**3. Service Layer**
- What business logic is required?
- What validations need to happen (input validation vs. business rules)?
- What are the transaction boundaries?
- Does this feature need to interact with other features' services? How?

**4. Event-Driven Aspects**
- Should any events be published when things happen in this feature?
- Does this feature need to react to events from other features?
- What event schemas are needed?
- What are the failure and retry scenarios?

**5. Security Considerations**
- What authorisation rules apply? Who can do what?
- Is there sensitive data that needs special handling?
- Are there rate limiting or abuse prevention needs?

**6. Edge Cases and Error Scenarios**
- What happens when the expected input is missing or malformed?
- What happens during concurrent modifications?
- What happens if a dependent service is unavailable?
- What are the failure modes and how should each be handled?

**7. Testing Strategy**
- What are the critical paths that need integration tests?
- What business logic needs thorough unit testing?
- Are there any scenarios that need end-to-end testing?

**8. Migration Plan**
- What database migrations are needed?
- Is there existing data that needs to be migrated or backfilled?
- Can this be deployed without downtime?
- What is the rollback strategy?

### Expected Output

After thinking through each area, provide:
1. A summary of key decisions and their rationale.
2. A list of files that will need to be created or modified.
3. The recommended implementation order (what to build first).
4. Any open questions you need me to answer before proceeding.
