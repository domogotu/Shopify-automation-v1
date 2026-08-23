# n8n Workflow Pack

## Naming

`NN-domain-action-v1.json`

Workflow IDs remain stable after import. Version changes are tracked in the filename, workflow metadata, and changelog.

## Shared Contract

Every workflow must:

1. Generate or accept a `correlation_id`.
2. Resolve `store_id` before processing store-owned data.
3. Validate input against a documented contract.
4. Persist a started `automation_runs` record.
5. Use idempotency keys before external writes.
6. Record auditable decisions and external results.
7. Route errors to `18-central-error-handler-v1`.
8. Return a structured result with `status`, `correlation_id`, `resource_type`, `resource_id`, and `next_action`.

## Credential Policy

- Workflow JSON contains credential names only when necessary, never credential IDs or secrets.
- Credentials are attached after import through n8n's encrypted credential store.
- Shopify uses the Admin GraphQL API.
- PostgreSQL uses TLS in production.
- AI credentials are provider-specific and selected through the routing sub-workflow.

## Safety Defaults

- Products: draft only.
- Publishing: approval required.
- Supplier submission: approval required.
- Refunds and reships: approval required.
- Customer-facing messages: approval required at launch.
- Discounts and campaigns: approval required.

## Workflow Inventory

See `docs/SHOPIFY_AUTOMATION_OS_BLUEPRINT.md` for the complete 18-workflow plan.

## Implemented Foundation

- `00-environment-health-check-v1.json` validates required configuration and launch safety defaults.
- `00-multi-agent-orchestrator-v1.json` routes typed requests to twelve Shopify specialist paths and returns a plan-only agent contract.
- `00-realtime-question-gateway-v1.json` provides synchronous Claude answers through a typed webhook and refuses to claim live store data without cited tool results.
- `00-chatgpt-executive-supervisor-v1.json` makes ChatGPT the executive orchestrator and independent decision supervisor before deterministic authorization or human approval.
- `00D-memory-write-gate-v1.json` stores redacted conversations and governed memory candidates in PostgreSQL.
- `00E-scoped-memory-retrieval-v1.json` retrieves recent conversation context and verified store-scoped memory for later decisions.
- `00J-system-architect-intake-v1.json` opens governed improvement cases from failures, feedback, stale knowledge, missing capabilities, API changes, or repeated manual work without changing production.
- `00K-tool-result-content-validator-v1.json` validates the content of every tool response, records the assertion, and returns either safe data, an explicit retry, or human review.
- `13A-agentmail-inbound-webhook-v1.json` verifies AgentMail's signed raw webhook, extracts `thread_id` and `message_id`, and returns a deduplicatable inbound-email envelope for storage and triage.
- `13B-agentmail-approved-reply-v1.json` sends a payload-bound approved reply to the specific AgentMail `message_id`, then validates that the response returns a message ID in the expected thread.

The specialist nodes in the orchestrator are intentionally No Operation nodes until the shared Think–Authorize–Act sub-workflow, memory retrieval, memory write gate, and approval router are connected and tested. See `docs/MULTI_AGENT_SYSTEM.md`.

## Phase 0 — Reeds Technology Architecture

The eleven `NN-architecture-*-phase0.json` workflows make the complete owner-governed ecosystem visible in n8n without claiming unavailable capabilities. They are architectural maps, not production dispatchers. Every component is explicitly marked `OPERATIONAL`, `PLANNED`, `REQUIRES CREDENTIALS`, `REQUIRES HARDWARE`, or `FUTURE RESEARCH`.

Each architecture workflow contains:

- a manual inspection trigger;
- an architecture manifest that returns expected inputs, outputs, permissions, risk, approval requirements, verification method, and implementation status;
- inert No Operation component nodes;
- an architecture safety notice explaining that the map performs no external action.

Phase 0 workflows contain no credentials, HTTP requests, database operations, or sub-workflow execution. Existing operational workflows remain separate and unchanged.
