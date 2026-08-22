# Shopify Automation OS

## Locked Architecture

- **Workflow engine:** Portable n8n workflows; compatible with n8n Cloud and self-hosted n8n.
- **Review surface:** Google Sheets for mobile-friendly product, pricing, content, support, and exception approvals.
- **System of record:** PostgreSQL for durable operational state, idempotency, audit events, retries, and analytics.
- **AI routing:** ChatGPT is the executive orchestrator and decision supervisor. Claude is the default specialist model, with a configurable retryable fallback. AI output is advisory until deterministic policy and required human approval authorize an action.
- **Commerce system:** Shopify Admin GraphQL API. Products are created as `DRAFT` by default.
- **Supplier system:** CJdropshipping first. Supplier product/variant mappings are preserved separately from public Shopify copy.
- **Safety model:** Human approval for publishing, supplier ordering, material price changes, refunds, discounts, customer-facing exception messages, and advertising spend.

## Shared Agent Orchestration Pattern

Every workflow that uses AI follows the same visible n8n sub-workflow. Business-specific workflows call this shared agent core rather than duplicating model and safety logic.

### Executive decision hierarchy

1. ChatGPT interprets the request and creates a structured executive plan.
   Before planning, the user message is stored and relevant store-scoped conversation and verified memory are retrieved.
2. ChatGPT selects one or more specialist agents and identifies the evidence each must return.
3. Specialists analyze only their assigned scope and return cited evidence bundles; they do not authorize actions.
4. ChatGPT independently reviews the combined reports, compares alternatives, identifies conflicts and missing information, and recommends the best supported option.
5. Deterministic code checks evidence quality, permissions, active policy, risk, approval, payload hash, tool allowlist, idempotency, and recoverability.
6. High-risk commerce actions require human approval even when ChatGPT recommends them.
7. The authorized action is executed through the constrained Act runtime and then independently verified.
8. The user answer, plan, specialist evidence, supervisor review, approval, action result, and verification outcome are returned to the memory write gate.

ChatGPT can recommend `NEEDS_INFORMATION`, `NEEDS_REVIEW`, `RECOMMEND`, or `REJECT`. It cannot grant permissions, approve high-risk actions, override store scope, invent evidence, or silently change policy.

### Closed-loop review and correction

- Supervisor sends cases back to specialists when evidence is missing, stale, conflicting, or incomplete.
- Supervisor sends cases back to the executive when the request was misunderstood, scope is incomplete, or alternatives were not compared.
- Human approval can return a case for revision; any payload change invalidates the previous approval.
- Post-action verification retries bounded transient failures through the same idempotent envelope and returns unexpected results to supervisor review.
- User feedback reopens evidence and memory review before a correction or lesson is promoted.
- Loops have per-route and total-cycle limits. Repeated unchanged failures end in a safe no-operation and owner review.

1. **Trigger and configuration**
   - A webhook, form, schedule, Shopify event, or internal workflow supplies a correlation ID and a typed task request.
   - A configuration node loads the store, environment, policies, risk thresholds, approved tools, model routing, prompt version, and output schema version.
   - Secrets remain in n8n credentials or environment variables and never enter prompts, workflow exports, Sheets, or logs.

2. **Think agent — read-only planning**
   - Claude is the primary reasoning model. The fallback runs only for retryable availability, timeout, or rate-limit failures.
   - The Think agent may retrieve verified context from Shopify, CJ, PostgreSQL, Google Sheets, and approved reference data, but it cannot perform external writes.
   - PostgreSQL memory is scoped by `store_id`, workflow, resource, and conversation. Retention, PII minimization, and deletion rules apply; memory is never shared across stores.
   - A structured-output parser requires a versioned JSON plan containing: `task`, `facts`, `assumptions`, `missing_information`, `risk_level`, `proposed_actions`, `required_tools`, `requires_approval`, and `evidence_refs`.

3. **Deterministic authorization and risk gate**
   - Code and database policy—not the model—decide whether a proposed action is permitted.
   - The gate verifies actor role, store scope, approval type, approval token, risk threshold, tool allowlist, action limits, payload hash, and idempotency key.
   - Allowed read-only or explicitly low-risk actions continue. Approval-required actions enter the Google Sheets/PostgreSQL approval queue. Denied, incomplete, stale, or unsafe plans end in a recorded no-operation state.

4. **Act agent — constrained execution**
   - The Act agent receives only the validated plan, minimum required context, approved tool set, and short-lived authorization envelope.
   - Tools are individually allowlisted: Shopify Admin GraphQL, CJ supplier API/assisted queue, PostgreSQL, Google Sheets, email/helpdesk, and owner notifications.
   - Each write uses an idempotency key, precondition checks, bounded retries, and a compensating or manual recovery path.
   - A second structured-output parser requires: `status`, `actions_attempted`, `actions_completed`, `external_ids`, `evidence_refs`, `errors`, `retryable`, `approval_id`, and `next_step`.

5. **Branching, notification, and recovery**
   - Success routes to the appropriate business workflow and audit log.
   - Approval-required routes to the mobile review queue and owner notification.
   - Denied or no-change routes to a safe No Operation node with a reason code.
   - Retryable errors route to bounded retry; terminal errors route to the central error handler.
   - Every canvas includes documentation notes for purpose, input contract, prompt version, output schema, permissions, owner, and recovery procedure.

### Shared Tool Connections

- **Claude primary + fallback:** model router with retry classification and cost/latency logging.
- **PostgreSQL memory and state:** durable context, approvals, idempotency, workflow runs, and audit events.
- **Google Sheets:** human review and configuration surface; never the authority for permissions.
- **Shopify GraphQL:** product, order, fulfillment, customer, publication, and refund tools with operation-specific scopes.
- **CJdropshipping:** catalog lookup, variant mapping, order submission, and tracking tools; writes remain approval-gated at launch.
- **Notifications:** owner alerts for approvals, high-risk cases, completion, and terminal failures.

## Memory and Learning Architecture

The system uses multiple memory types because a single chat-history table is not reliable enough for commerce automation.

### Memory Types

1. **Working memory**
   - Short-lived context for the current n8n execution, agent plan, tool results, and unresolved questions.
   - Expires automatically and is never treated as an approved business rule.

2. **Entity memory**
   - Durable facts about stores, Shopify products and variants, CJ products and variants, suppliers, customers, orders, shipments, tickets, campaigns, and external identifiers.
   - Facts link to their source record and effective date.

3. **Semantic memory**
   - Searchable product facts, supplier documentation, policies, approved product language, shipping rules, and operating knowledge.
   - PostgreSQL full-text search is the default; `pgvector` embeddings may supplement retrieval when enabled.

4. **Episodic memory**
   - Records what happened during a workflow: the plan, decision, tools used, outcome, error, recovery, cost, latency, and reviewer feedback.
   - Used to identify recurring failures and successful operating patterns without granting new permissions.

5. **Procedural memory**
   - Versioned prompts, schemas, playbooks, risk thresholds, approval policies, tool permissions, and workflow versions.
   - Only an authorized human or controlled deployment can change procedural memory.

6. **Approval and audit memory**
   - Immutable decisions showing who approved or denied an action, exactly what payload was reviewed, when it expires, and which external action consumed the approval.
   - Approval records are never inferred from conversational memory.

### Memory Write Gate

Every proposed memory write is validated before persistence:

- enforce `store_id` and resource scope;
- classify sensitivity and remove unnecessary PII;
- require a source reference and observed timestamp;
- assign confidence, status, effective date, and optional expiry;
- detect duplicates and contradictions with active facts;
- keep unverified claims in `PROPOSED` state until verified;
- create a new version instead of overwriting material history;
- prohibit model-generated permissions, approvals, secrets, or fabricated customer/product facts.

### Retrieval and Context Assembly

1. Parse the task into store, actor, resource, action, and time scope.
2. Retrieve exact relational facts first.
3. Retrieve relevant semantic memories only from the same store and permitted sensitivity class.
4. Rank by authority, source quality, freshness, confidence, and relevance.
5. Detect conflicting or expired facts and route uncertainty to review.
6. Build a compact context package with citations and token limits.
7. Send only the minimum context required to the Think agent.

The model must distinguish `verified_fact`, `policy`, `historical_outcome`, `unverified_claim`, and `recommendation`. Memory can improve recommendations but cannot override current Shopify/CJ state, active policies, or human approvals.

### Learning Loop

- Capture reviewer edits, approval/denial reasons, tool outcomes, delivery results, returns, refunds, support resolutions, and product performance.
- Produce proposed lessons and prompt/policy changes on a schedule.
- Test proposed changes against stored fixtures and recent workflows.
- Require human approval before promoting a lesson into procedural memory.
- Version every promoted prompt, schema, policy, and workflow so changes can be compared or rolled back.
- Track whether a promoted change actually reduces error rate, review time, cost, or customer exceptions.

## System Modules

1. **Supplier Product Intake**
   - Accept CJ product URL, SKU, variants, costs, images, warehouse, shipping routes, and delivery estimates.
   - Reject incomplete, out-of-stock, trademark-risk, unsafe, or unprofitable candidates.
   - Detect duplicates by supplier SKU and canonical URL.

2. **Product Research and Scoring**
   - Score demand evidence, competition, landed cost, gross margin, delivery speed, return risk, supplier reliability, regulatory risk, and IP risk.
   - Statuses: `DISCOVERED`, `REVIEW`, `SAMPLE_REQUIRED`, `APPROVED`, `REJECTED`, `PAUSED`, `RETIRED`.

3. **AI Content Factory**
   - Claude drafts title, description, benefits, specifications, tags, alt text, SEO title, and SEO description.
   - Prompts prohibit fabricated claims, reviews, scarcity, certifications, materials, performance, or shipping promises.
   - Fallback provider runs only after retryable Claude failures.

4. **Pricing and Margin Engine**
   - Landed cost = supplier cost + supplier shipping + duties + transaction allowance + refund reserve + variable app allocation.
   - Contribution profit = selling price - landed cost - discount allowance - advertising allowance.
   - Enforce configurable minimum dollar profit, gross margin, and contribution margin.
   - Material cost or margin changes create an approval request instead of silently repricing.

5. **Approval Queue**
   - Google Sheets provides phone-friendly review columns and approval controls.
   - PostgreSQL stores immutable approval history.
   - Approval types: product, content, price, publish, supplier order, refund, discount, support exception, and campaign.

6. **Shopify Draft Publisher**
   - Creates products as drafts through Shopify GraphQL.
   - Handles options, variants, SKUs, images, tags, metafields, inventory policy, and collections.
   - Idempotency prevents duplicate products during retries.
   - Publication is a separate workflow requiring approval.

7. **CJ Mapping and Supplier Operations**
   - Store Shopify product/variant IDs beside CJ SPU/SKU identifiers.
   - Validate every Shopify variant has exactly one approved supplier mapping.
   - Never mark a Shopify order fulfilled merely because an order was submitted to CJ.
   - Supplier submission remains approval-based until test orders prove end-to-end reliability.

8. **Order Intake and Fraud/Exception Routing**
   - Receive Shopify order webhooks and verify authenticity.
   - Create one internal order record per Shopify order.
   - Route high-risk, unmapped, address-error, stockout, cost-change, or duplicate cases to review.

9. **Fulfillment and Tracking Monitor**
   - States: `RECEIVED`, `REVIEW`, `SUPPLIER_SUBMITTED`, `SUPPLIER_ACCEPTED`, `TRACKING_RECEIVED`, `IN_TRANSIT`, `DELIVERED`, `EXCEPTION`, `CLOSED`.
   - Monitor missing tracking, stalled shipments, late delivery, lost packages, and delivery disputes.
   - Update Shopify fulfillment only from verified supplier/tracking events.

10. **AI Customer Support**
    - Classify order inquiry, tracking, cancellation, return, damage, missing item, wrong item, product question, complaint, or chargeback risk.
    - Low-risk replies may be drafted automatically; sending is approval-first at launch.
    - Refunds, reships, policy exceptions, threats, safety complaints, and legal claims always escalate.

11. **Marketing and Retention**
    - Draft welcome, cart recovery, post-purchase, review request, cross-sell, and win-back content.
    - Campaign creation, discounts, sending, and advertising spend remain approval-gated.

12. **Analytics and Daily Operations**
    - Daily metrics: orders, gross sales, net sales, refunds, landed cost, gross profit estimate, contribution profit estimate, AOV, fulfillment rate, delay rate, support volume, and supplier performance.
    - Weekly AI summary cites underlying metrics and separates facts from recommendations.

13. **Audit, Errors, and Recovery**
    - Every workflow execution receives a correlation ID.
    - Store attempts, results, errors, approvals, actor, timestamps, payload hashes, and external IDs.
    - Central error workflow classifies retryable versus terminal failures and notifies the owner.

## PostgreSQL Core Tables

- `stores`
- `suppliers`
- `supplier_products`
- `supplier_variants`
- `product_candidates`
- `product_scores`
- `shopify_products`
- `shopify_variants`
- `supplier_variant_mappings`
- `price_snapshots`
- `content_drafts`
- `approvals`
- `orders`
- `order_lines`
- `fulfillments`
- `shipments`
- `order_exceptions`
- `support_tickets`
- `support_messages`
- `campaign_drafts`
- `automation_runs`
- `audit_events`
- `alerts`
- `memory_items`
- `memory_links`
- `memory_embeddings`
- `memory_feedback`
- `context_snapshots`
- `prompt_versions`
- `policy_versions`
- `tool_permissions`

All operational tables include `store_id`, timestamps, and external identifiers where applicable. Unique constraints protect Shopify order IDs, supplier order IDs, product handles, SKUs, and webhook event IDs from duplicate processing.

## Google Sheets Workbook

Tabs:

1. `Product Intake`
2. `Research Scores`
3. `Pricing Review`
4. `Content Review`
5. `Publish Queue`
6. `Supplier Mapping`
7. `Order Exceptions`
8. `Support Review`
9. `Campaign Review`
10. `Daily Metrics`
11. `Workflow Errors`
12. `Configuration`

Sheets are a controlled review interface, not the authoritative database. Every approved Sheet change is validated and written to PostgreSQL before an external action occurs.

## Planned n8n Workflow Pack

### Current implementation status

- `00-environment-health-check-v1.json`: implemented foundation check.
- `00-multi-agent-orchestrator-v1.json`: implemented plan-only router with twelve specialist paths.
- `config/agents.json`: implemented versioned agent, memory-scope, tool, and approval registry.
- `database/migrations/002_agent_memory_and_registry.sql`: implemented agent sessions, governed memory, context snapshots, feedback, policies, and tool permissions.
- `database/migrations/003_realtime_conversations.sql`: implemented conversations, messages, response jobs, and realtime tool-event records.
- `00-realtime-question-gateway-v1.json`: implemented synchronous Claude question answering with specialist selection, action-risk detection, and grounded-response metadata.
- `00-chatgpt-executive-supervisor-v1.json`: implemented two-pass ChatGPT planning and independent decision review followed by a deterministic gate.
- `config/decision-policy.json`: implemented the decision sequence, mandatory approvals, supervisor checks, and prohibited AI authority.
- `database/migrations/004_executive_decisions.sql`: implemented decision cases, executive plans, specialist reports, supervisor reviews, and outcomes.
- `00D-memory-write-gate-v1.json`: implemented redaction, conversation persistence, governed memory-candidate persistence, and memory-write receipts.
- `00E-scoped-memory-retrieval-v1.json`: implemented recent-conversation and verified store-scoped memory retrieval with cited context packages.
- `config/memory-policy.json`: implemented retention, exclusions, memory write requirements, retrieval order, and cross-store denial.
- `database/migrations/005_memory_access_and_retention.sql`: implemented memory access logs, retention rules, and summaries.
- `config/chat-routing.json`: implemented ask, decide, view-memory, update-memory, feedback, and status routes.
- `database/migrations/006_feedback_and_corrections.sql`: implemented feedback cases, governed memory corrections, and answer-quality reviews.
- `config/memory-taxonomy.json`: implemented expandable category classification, retrieval, maintenance, and new-category governance.
- `database/migrations/007_dynamic_memory_taxonomy.sql`: implemented nested categories, aliases, many-to-many memory assignments, proposals, and category change auditing.
- `docs/DYNAMIC_MEMORY_CATEGORIES.md`: implemented the classification, improvement, retrieval, and human-review contract.
- `config/self-governance-policy.json`: implemented the System Architect's observation scope, autonomous draft authority, prohibited actions, promotion gates, and rollout rules.
- `database/migrations/008_self_governance_and_system_evolution.sql`: implemented improvement cases, change proposals, tests, approvals, component versions, and evolution audit records.
- `00J-system-architect-intake-v1.json`: implemented governed intake for detected system gaps and improvement signals.
- `docs/SELF_GOVERNING_SYSTEM_ARCHITECT.md`: implemented the controlled self-correction and system-expansion contract.
- `config/tool-result-contract.json`: implemented fail-closed normalized results, content assertions, retry rules, change classes, and downstream verification.
- `database/migrations/009_tool_result_assertions.sql`: implemented tool-content assertion records and intended-versus-actual change verification.
- `00K-tool-result-content-validator-v1.json`: implemented deterministic validation and auditing after every agent tool call.
- `docs/SAFE_AGENT_WORKFLOW_UPDATES.md`: implemented the safe MCP/n8n-as-code editor, testing, approval, deployment, verification, and rollback pattern.
- `config/agentmail-policy.json`: implemented verified inbound events, thread/message matching, outbound approvals, and post-send validation.
- `database/migrations/010_agentmail_threads_and_messages.sql`: implemented durable email threads, deduplicated messages, and auditable send attempts.
- `docs/AGENTMAIL_EMAIL_AGENT.md`: implemented the AgentMail webhook, thread-memory, reply, attachment, and failure-handling contract.
- `13A-agentmail-inbound-webhook-v1.json`: implemented the signed AgentMail webhook and durable thread/message extraction foundation.
- `13B-agentmail-approved-reply-v1.json`: implemented approval-gated AgentMail replies with payload hashing and response-content assertions.
- `config/production-reliability-policy.json`: implemented durable processing, data protection, observability, staged rollout, AI quality, and launch blockers.
- `database/migrations/011_reliability_control_plane.sql`: implemented webhook receipts, transactional outbox, dead letters, feature flags, reconciliation records, and service-level measurements.
- `docs/PRODUCTION_READINESS_GATES.md`: implemented the evidence-based progression from foundation deployment through capability-specific production activation.
- `docs/CHAT_ROUTING_AND_FEEDBACK.md`: implemented the user command and feedback-processing contract.
- `config/review-loops.json`: implemented bounded evidence, planning, approval, execution, recovery, and feedback return paths.
- `docs/CLOSED_LOOP_DECISIONS.md`: implemented loop reasons, controls, stop conditions, and final-output rules.
- Live model and commerce execution remains intentionally disconnected until the shared Think–Authorize–Act core and approval tests are implemented.

| ID | Workflow | Trigger | External writes |
|---|---|---|---|
| 00A | Agent Think/Authorize/Act Core | Internal sub-workflow | Policy-controlled tools + audit |
| 00B | Configuration and Tool Registry | Internal sub-workflow | PostgreSQL read + audit |
| 00C | Approval, No-Op, and Error Router | Internal sub-workflow | Sheets/PostgreSQL + notifications |
| 00D | Memory Write and Contradiction Gate | Internal sub-workflow | PostgreSQL |
| 00E | Scoped Memory Retrieval | Internal sub-workflow | PostgreSQL read + audit |
| 00F | Learning Review and Promotion | Schedule/manual | Sheets/PostgreSQL + version registry |
| 00G | Realtime Question Gateway | Webhook/manual | Claude response + conversation record |
| 00H | ChatGPT Executive and Supervisor | Webhook/internal | Decision records + approval routing |
| 01 | Supplier Product Intake | Form/Webhook | Sheets + PostgreSQL |
| 02 | Research and Risk Scoring | Intake event | Sheets + PostgreSQL |
| 03 | AI Content Draft | Approved candidate | Sheets + PostgreSQL |
| 04 | Pricing Engine | Cost/content update | Sheets + PostgreSQL |
| 05 | Approval Reconciler | Sheet change/schedule | PostgreSQL |
| 06 | Shopify Draft Creator | Product approval | Shopify draft + PostgreSQL |
| 07 | Shopify Publisher | Publish approval | Shopify publication |
| 08 | Supplier Mapping Validator | Mapping update | PostgreSQL + alerts |
| 09 | Shopify Order Intake | Shopify webhook | PostgreSQL + Sheets exceptions |
| 10 | Supplier Submission Queue | Order approval | CJ API/manual queue |
| 11 | Tracking Monitor | Schedule/webhook | Shopify fulfillment + PostgreSQL |
| 12 | Delayed Order Monitor | Daily schedule | Sheets + notifications |
| 13 | AI Support Triage | Support webhook | Drafts + Sheets review |
| 14 | Refund/Reship Approval | Approved support action | Shopify/CJ action |
| 15 | Marketing Draft Factory | Schedule/manual | Sheets drafts |
| 16 | Daily Metrics | Daily schedule | PostgreSQL + Sheets |
| 17 | Weekly Owner Brief | Weekly schedule | Email/approved channel |
| 18 | Central Error Handler | n8n error trigger | PostgreSQL + alerts |

## Build Order

### Milestone 1 — Foundation

- PostgreSQL schema and migrations
- Google Sheets workbook schema
- environment-variable contract
- shared n8n sub-workflows for configuration, database logging, AI routing, approvals, and errors
- shared Think/Authorize/Act agent core with structured JSON schemas and PostgreSQL memory
- scoped memory retrieval, governed memory writes, contradiction detection, and human-approved learning promotion

### Milestone 2 — Product Lifecycle

- supplier intake
- scoring and risk checks
- Claude content generation with fallback
- pricing engine
- approval queue
- Shopify draft creation and publication gate
- CJ variant mapping validation

### Milestone 3 — Order Lifecycle

- verified Shopify webhooks
- order and line-item persistence
- supplier approval/submission queue
- tracking and fulfillment synchronization
- delay and exception monitoring

### Milestone 4 — Support, Marketing, and Analytics

- AI support triage
- refund/reship approvals
- campaign drafts
- daily metrics
- weekly owner brief

### Milestone 5 — Deployment and Verification

- Docker deployment profile
- n8n Cloud import instructions
- credential setup checklist
- end-to-end test fixtures
- duplicate, retry, failure, and security tests
- production-readiness report

## Non-Negotiable Launch Gates

- No secret values embedded in workflow JSON.
- No automatic publication at launch.
- No automatic advertising spend.
- No automatic supplier purchase until a test order passes.
- No automatic refund or reship.
- No fabricated product facts, reviews, scarcity, or delivery promises.
- Every Shopify variant must have a valid supplier mapping before sale.
- Every webhook must be authenticated and idempotent.
- Every external write must be auditable and safely retryable.
- No memory may cross store boundaries or silently override an authoritative current record.
- No model-generated lesson becomes a prompt, policy, permission, or workflow change without review, tests, and versioning.
