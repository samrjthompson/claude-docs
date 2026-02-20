# MVP Scoping Prompt

Use this prompt when you have a product idea and want Claude Code to help you scope the minimum viable implementation.

## How to Use

Provide this prompt along with your product idea. Include as much or as little detail as you have — the exercise works at any level of definition.

---

## Prompt

I have a product idea that I want to build. Help me scope the minimum viable product (MVP) — the smallest implementation that delivers value and validates the core hypothesis.

### Product Idea

**What it does:** [Describe the product]
**Who it is for:** [Target users]
**Core hypothesis:** [What you are trying to validate — "We believe that [users] will [action] because [reason]"]
**Existing alternatives:** [How do users solve this problem today?]

### Scoping Process

**1. Feature Brainstorm**
List every feature you can think of that this product could have. Do not filter yet — capture everything.

**2. User Journey Mapping**
Map the core user journey from first touch to value delivery:
- How does the user discover and access the product?
- What is the absolute minimum they need to do to get value?
- What is the "aha moment" — when do they realise this product is useful?
- What brings them back?

**3. Feature Classification**
Categorise every feature from the brainstorm into:
- **MUST HAVE (MVP)**: Without this, the product does not function or deliver its core value. Be ruthless here — if users can get by without it for the first month, it is not MVP.
- **SHOULD HAVE (V1.1)**: Important for a good experience but not required to validate the hypothesis. Build these in the weeks after launch.
- **COULD HAVE (V2)**: Nice to have. Build these once you have validated product-market fit.
- **WON'T HAVE (Backlog)**: Interesting ideas for the future. Park them.

For each MUST HAVE feature, justify why it cannot be deferred.

**4. Technical Scoping**
For the MVP feature set:
- What entities and data model are needed?
- What API endpoints are required?
- What UI pages or screens are needed?
- What integrations are required?
- What can be done manually instead of automated for the MVP? (e.g., manual email instead of automated notifications)
- What can use a simpler implementation for now? (e.g., basic search instead of full-text search)

**5. Simplification Passes**
Go through the MVP feature list three times, each time asking:
- Can this feature be simplified further?
- Can the scope of this feature be reduced?
- Can this be replaced with a manual process for now?
- Can we use a third-party service instead of building this?
- What is the simplest version of this that still delivers value?

**6. Effort Estimation**
For each MVP feature:
- Estimate backend effort (days).
- Estimate frontend effort (days).
- Identify dependencies between features.
- What is the critical path?
- What is the total estimated time to MVP?

**7. Risk Assessment**
- What is the biggest technical risk in the MVP?
- What is the biggest product risk?
- What do we learn from launching the MVP that we cannot learn any other way?
- What would make us decide the hypothesis is wrong?

### Output

1. **MVP Feature List**: Ordered list of MUST HAVE features with justification.
2. **Deferred Features**: Categorised list of everything we are NOT building yet.
3. **Technical Spec**: Entities, endpoints, pages, and integrations for the MVP.
4. **Implementation Order**: Which features to build first, based on dependencies and risk.
5. **Timeline Estimate**: Total effort and calendar time to MVP.
6. **Success Criteria**: How we know the MVP succeeded (metrics, user actions, feedback signals).
