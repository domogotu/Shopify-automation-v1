# Shopify Multi-Agent System

## What is implemented

`workflows/00-multi-agent-orchestrator-v1.json` is an importable, credential-free n8n routing scaffold. It accepts a typed request, limits input fields, assigns a correlation ID, selects a specialist agent, performs an initial risk classification, and returns a safe agent contract.

The workflow is deliberately `PLAN_ONLY`. It performs no Shopify, CJ, email, refund, publishing, supplier-order, discount, or advertising writes.

## Agent network

1. Product Discovery
2. Supplier and CJ
3. Product Content
4. Pricing and Profit
5. Shopify Catalog
6. Order and Fulfillment
7. Customer Support
8. Marketing
9. Finance
10. Research
11. Analytics
12. Approval and Compliance fallback

The complete registry is in `config/agents.json`. Each definition lists intent routing, memory scopes, read tools, write tools, and approval types.

## Import and test

1. Import `workflows/00-multi-agent-orchestrator-v1.json` into n8n.
2. Keep the workflow inactive while reviewing it.
3. Run **Manual Trigger**.
4. Confirm the output has `status: ROUTED`, `execution_mode: PLAN_ONLY`, the expected `selected_agent`, and a correlation ID.
5. Change the Manual Test Input intent and confirm routing for each agent.
6. Do not connect live write credentials yet.

Example webhook request:

```json
{
  "store_domain": "c6w6yz-rz.myshopify.com",
  "actor_id": "owner",
  "channel": "admin",
  "message": "Create a draft listing for the approved candidate",
  "intent": "create_draft",
  "resource_type": "product_candidate",
  "resource_id": "replace-with-id"
}
```

Expected routing: `shopify_catalog`. The request remains plan-only until the shared Think–Authorize–Act workflow is connected.

## Activation sequence

1. Apply database migrations `001` and `002` to a non-production PostgreSQL database.
2. Seed `agent_definitions` and `tool_permissions` from `config/agents.json`.
3. Build workflow `00E Scoped Memory Retrieval`.
4. Build workflow `00D Memory Write and Contradiction Gate`.
5. Build workflow `00A Agent Think-Authorize-Act Core` using Claude primary and the structured plan/result schemas.
6. Replace each current No Operation specialist node with an Execute Sub-workflow node that calls the shared core using its agent contract.
7. Test every route with read-only tools.
8. Enable draft-only and review-queue writes.
9. Run a Shopify draft test and a CJ mapping test.
10. Keep publishing, supplier ordering, refunds, support sending, discounts, campaigns, and ad spend approval-gated.

## Required verification

- Unknown intents route to Approval and Compliance.
- Cross-store requests are rejected.
- Unapproved tools cannot be called.
- High-risk actions cannot proceed without a valid approval payload hash.
- Duplicate correlation or idempotency keys do not repeat external effects.
- Model output that fails the JSON schema does not reach a tool.
- Stale or contradictory memory stops the action.
- Every route creates an audit record before production activation.
