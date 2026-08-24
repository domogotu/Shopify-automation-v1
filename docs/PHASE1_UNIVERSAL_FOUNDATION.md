# Phase 1 Universal Foundation

## Purpose

Phase 1 turns the Phase 0 architecture map into a real front gate. Every request must become a universal event envelope before the system uses memory, calls a model, routes work to agents, executes tools, sends messages, spends money, changes production, or controls hardware.

## Route

```text
Raw request
-> 00A - Universal Event Envelope v1
-> Identity Resolver
-> Root Authority Check
-> Permission Scope
-> Policy Decision
-> Audit Record
-> Memory / Planning / Agent / Tool routes
```

Only the first workflow is implemented in this step. The later gates are reserved by schema and documented as the next build targets.

## Universal Event Envelope

Required input:

```text
store_domain
message
actor_id
source_type
request_type
```

Generated or normalized fields:

```text
event_id
correlation_id
received_at
source_id
session_id
resource_type
resource_id
risk_level
execution_mode
identity_status
policy_status
```

The envelope is stored in `automation_os.universal_event_envelopes`. The workflow is idempotent by `correlation_id`, so retries update the same envelope instead of creating uncontrolled duplicates.

## Why This Goes First

The existing executive workflow already works, but it accepts request fields directly. That makes every new input channel responsible for shaping data correctly. The universal envelope centralizes that contract so webhooks, manual tests, Shopify events, AgentMail, GitHub, Render, future phone inputs, and future Reeds devices all enter the system the same way.

## Current Status

Implemented:

- `00A-universal-event-envelope-v1.json`
- `012_universal_event_envelope.sql`
- validation test `test-phase1-event-envelope.mjs`

## Controlled Import Procedure

Keep `BOOTSTRAP_WORKFLOWS=false`. Do not use the broad workflow bootstrap for Phase 1.

Use the scoped Phase 1 switch for one deployment only:

1. Set `RUN_DATABASE_MIGRATIONS=true`.
2. Set `SYNC_PHASE1_ENVELOPE_ONCE=true`.
3. Deploy once.
4. Confirm the logs contain:
   - `Applying migration 012_universal_event_envelope.sql`
   - `Synchronizing Phase 1 universal event envelope workflow`
   - `Successfully imported 1 workflow.`
5. Set `RUN_DATABASE_MIGRATIONS=false`.
6. Set `SYNC_PHASE1_ENVELOPE_ONCE=false`.
7. Deploy again.
8. Confirm the cleanup logs contain:
   - `Database migrations disabled; preserving existing schemas`
   - `Workflow bootstrap disabled; preserving database workflows`

After import, assign the existing n8n Postgres credential to the `Persist Universal Event Envelope` node.

Planned next:

- Identity Resolver
- Dominique Root Authority Check
- Permission Scope
- Policy Decision
- Human Approval Gate integration
- Executive workflow front-door integration
