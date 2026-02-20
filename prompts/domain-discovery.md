# Domain Discovery Prompt

Use this prompt when exploring a new business domain — identifying entities, workflows, rules, and terminology from informal descriptions, interview notes, or documentation.

## How to Use

Provide this prompt along with whatever raw material you have about the domain: interview transcripts, business documents, process descriptions, existing software documentation, or just a verbal explanation.

---

## Prompt

I am exploring a new business domain and need to build a structured understanding that I can use for software design. Help me extract and organise domain knowledge from the raw material I provide.

### Raw Material

[Paste interview notes, business process descriptions, existing documentation, or provide a verbal explanation of the domain here.]

### Discovery Process

**1. Entity Extraction**
From the raw material, identify all nouns that represent significant business concepts:
- What are the core entities in this domain?
- For each entity: What is it? What attributes describe it? What states can it be in?
- Which entities are primary (independently meaningful) vs. secondary (dependent on a primary)?
- Are there entities that seem important but are not well-defined in the raw material? Flag these as needing clarification.

**2. Relationship Mapping**
How do the entities relate to each other?
- One-to-one, one-to-many, many-to-many relationships.
- Ownership and lifecycle dependencies (if A is deleted, what happens to B?).
- Draw an entity relationship diagram (text-based).

**3. Workflow Identification**
What are the key business processes?
- What triggers each workflow?
- What steps are involved?
- What decisions or branches exist?
- Who is involved at each step?
- What is the outcome?
- Draw a sequence or flow diagram (text-based).

**4. Business Rule Extraction**
What rules govern this domain?
- Constraints: "An invoice cannot exceed $1M without CFO approval."
- Calculations: "Late payment fee is 1.5% per month on the outstanding balance."
- Conditions: "A subscription can only be cancelled if there are no pending invoices."
- Defaults: "New customers are assigned to the STARTER segment."
- Document each rule clearly and note where you inferred it vs. where it was explicitly stated.

**5. Terminology Glossary**
Build a glossary of domain terms:
- What does each term mean in this specific business context?
- Are there terms that mean different things to different stakeholders?
- Are there synonyms that should be standardised?
- What terms are overloaded (same word, different meanings in different contexts)?

**6. User Roles and Permissions**
Who interacts with this domain?
- What roles exist?
- What can each role do?
- What can each role see?
- Are there hierarchical relationships between roles?

**7. Gaps and Ambiguities**
What is unclear or contradictory in the raw material?
- List every assumption you made.
- List every question that needs to be answered by a domain expert.
- Identify areas where the raw material is incomplete or contradictory.
- Prioritise the gaps by impact on software design.

### Output Format

1. **Domain Summary**: One paragraph explaining this domain in plain language.
2. **Entity Catalogue**: Table of entities with attributes, states, and relationships.
3. **Relationship Diagram**: Text-based ER diagram.
4. **Workflow Catalogue**: Numbered workflows with triggers, steps, and outcomes.
5. **Business Rules Register**: Numbered rules with conditions and actions.
6. **Glossary**: Alphabetical list of domain terms with definitions.
7. **Roles Matrix**: Table of roles and their permissions.
8. **Open Questions**: Prioritised list of gaps and ambiguities.
9. **Recommended Domain Model**: A proposed package-by-feature structure mapping entities to feature packages, ready for software implementation.
