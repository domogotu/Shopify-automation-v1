# Shopify Automation OS

## Locked Architecture

- **Workflow engine:** Portable n8n workflows; compatible with n8n Cloud and self-hosted n8n.
- **Review surface:** Google Sheets for mobile-friendly product, pricing, content, support, and exception approvals.
- **System of record:** PostgreSQL for durable operational state, idempotency, audit events, retries, and analytics.
- **AI routing:** Claude primary; configurable fallback provider. AI output is draft-only unless a policy explicitly authorizes automatic action.
- **Commerce system:** Shopify Admin GraphQL API. Products are created as `DRAFT` by default.
- **Supplier system:** CJdropshipping first. Supplier product/variant mappings are preserved separately from public Shopify copy.
- **Safety model:** Human approval for publishing, supplier ordering, material price changes, refunds, discounts, customer-facing exception messages, and advertising spend.

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

| ID | Workflow | Trigger | External writes |
|---|---|---|---|
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

