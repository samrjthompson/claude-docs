# Domain Context: [PROJECT NAME]

Fill in each section below with project-specific details. Remove placeholder text and examples before composing this into your project's CLAUDE.md. Sections marked [REQUIRED] must be completed. Sections marked [IF APPLICABLE] can be removed if they do not apply.

---

## Business Domain [REQUIRED]

### What This Product Does

<!-- One to three paragraphs describing the business problem this product solves, who it serves, and what value it provides. Write this as if explaining to a senior engineer joining the project for the first time. -->

**Product name:** [e.g., InvoiceFlow]
**Domain:** [e.g., accounts receivable automation]
**Target users:** [e.g., finance teams at mid-market B2B companies]
**Core value proposition:** [e.g., reduces invoice processing time from days to minutes by automating creation, delivery, and payment reconciliation]

### Business Model

<!-- How does this product generate revenue? What is the pricing model? -->

**Pricing model:** [e.g., subscription, usage-based, per-seat]
**Tiers:** [e.g., Starter ($49/mo, up to 100 invoices), Business ($199/mo, up to 1000 invoices), Enterprise (custom)]
**Key metrics:** [e.g., MRR, invoice volume, payment success rate, time-to-payment]

---

## Core Entities [REQUIRED]

<!-- List every significant entity in the domain. For each, provide: name, purpose, key attributes, and lifecycle states. -->

### [Entity Name]

**Purpose:** [What this entity represents in the business domain]
**Key attributes:**
- `attribute_name` (type) — description
- `attribute_name` (type) — description

**Lifecycle states:** [e.g., DRAFT → SENT → PAID → ARCHIVED, or ACTIVE → SUSPENDED → CANCELLED]
**Ownership:** [Which feature package owns this entity]
**Relationships:**
- [Relationship description, e.g., "belongs to one Customer", "has many LineItems"]

<!-- Repeat for each entity -->

### Entity Relationship Summary

<!-- A concise summary of how the core entities relate to each other. This can be prose or a simple list. -->

---

## Key Workflows [REQUIRED]

<!-- Describe the primary user workflows and the business rules that govern them. -->

### [Workflow Name]

**Trigger:** [What initiates this workflow — user action, scheduled job, external event]
**Steps:**
1. [Step description]
2. [Step description]
3. [Step description]

**Business rules:**
- [Rule description, e.g., "An invoice cannot be sent if total amount is zero"]
- [Rule description]

**Error scenarios:**
- [What happens when X fails]

**Outcomes:**
- **Success:** [Expected result]
- **Failure:** [Expected behaviour on failure]

<!-- Repeat for each workflow -->

---

## Regulatory and Compliance Requirements [IF APPLICABLE]

<!-- Any legal, regulatory, or compliance constraints that affect implementation. -->

### Data Residency

- [e.g., Customer data must remain within the EU for EU tenants]
- [e.g., Financial records must be retained for 7 years]

### Industry Regulations

- [e.g., SOC 2 Type II compliance required]
- [e.g., PCI DSS compliance for payment data handling]
- [e.g., GDPR requirements for personal data — right to deletion, data portability]

### Audit Requirements

- [e.g., All financial transactions must have an immutable audit trail]
- [e.g., User actions on sensitive data must be logged with actor, action, and timestamp]

---

## Integration Points [IF APPLICABLE]

<!-- External systems this product integrates with. -->

### [Integration Name]

**System:** [e.g., Stripe, QuickBooks, Salesforce]
**Direction:** [Inbound, Outbound, Bidirectional]
**Protocol:** [REST API, Webhook, SFTP, Kafka topic]
**Purpose:** [What data flows and why]
**Authentication:** [API key, OAuth2, mutual TLS]
**Error handling:** [Retry policy, fallback behaviour]
**Rate limits:** [If applicable]

<!-- Repeat for each integration -->

---

## Domain Terminology Glossary [REQUIRED]

<!-- Define domain-specific terms that appear in code, documentation, and conversations. Developers and Claude Code should use these terms consistently. -->

| Term | Definition | Code Representation |
|------|-----------|-------------------|
| [Term] | [Plain English definition] | [How it appears in code — class name, enum value, etc.] |
| [Term] | [Plain English definition] | [Code representation] |

<!-- Examples:
| Invoice | A request for payment sent to a customer for goods or services delivered | `Invoice` entity, `InvoiceStatus` enum |
| Line Item | An individual charge within an invoice, representing a specific product or service | `InvoiceLineItem` entity |
| Tenant | A customer organisation using the platform; all data is isolated per tenant | `tenantId` field on all entities |
| Dunning | The process of sending reminders for overdue invoices | `DunningService`, `DunningSchedule` |
-->

---

## User Roles and Access Patterns [REQUIRED]

### Roles

<!-- Define each user role, what they can do, and what they cannot do. -->

| Role | Description | Key Permissions |
|------|-----------|----------------|
| [Role name] | [Who this role represents] | [What they can do] |

<!-- Examples:
| Owner | Organisation administrator | Full access to all features, billing, user management |
| Accountant | Finance team member | Create/edit/send invoices, view reports, manage customers |
| Viewer | Read-only stakeholder | View invoices and reports, no create/edit/delete permissions |
-->

### Access Patterns

<!-- How do users typically interact with the system? What are the most common operations? This helps prioritise performance optimisation and API design. -->

- **Most frequent read operations:** [e.g., list invoices with filters, view invoice detail, dashboard metrics]
- **Most frequent write operations:** [e.g., create invoice, update invoice status, add line items]
- **Peak usage patterns:** [e.g., end-of-month invoice generation, beginning-of-day dashboard views]
- **Batch operations:** [e.g., bulk invoice sending, monthly report generation]

---

## Non-Functional Requirements [IF APPLICABLE]

### Performance Targets

- [e.g., Invoice list endpoint responds within 200ms at p95 for up to 10,000 invoices per tenant]
- [e.g., Invoice PDF generation completes within 5 seconds]
- [e.g., Dashboard aggregations refresh within 30 seconds of new data]

### Scalability Expectations

- [e.g., Support up to 500 tenants with up to 100,000 invoices each]
- [e.g., Handle 1,000 concurrent users across all tenants]

### Availability

- [e.g., 99.9% uptime SLA]
- [e.g., Planned maintenance windows on Sundays 02:00-06:00 UTC]
