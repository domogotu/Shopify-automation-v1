# Realtime Question and Results Assistant

## Implemented fast path

`workflows/00-realtime-question-gateway-v1.json` accepts a question through a webhook or manual test, validates and scopes it, selects a specialist agent, classifies potential write requests, sends a synchronous request to Claude, and returns structured JSON within the webhook response.

The workflow does not pretend it has live store data. Until read-only tools are connected, it returns `live_data_used: false` and Claude is instructed to name the tool required for a current result.

## Request

```json
{
  "store_domain": "c6w6yz-rz.myshopify.com",
  "actor_id": "owner",
  "session_id": "phone-session-1",
  "channel": "web",
  "message": "Which of my products has the lowest margin?"
}
```

## Response

```json
{
  "status": "ANSWERED",
  "correlation_id": "question-...",
  "session_id": "phone-session-1",
  "selected_agent": "pricing_profit",
  "answer": "...",
  "sources": [],
  "live_data_used": false,
  "approval_required": false,
  "latency_ms": 0
}
```

## Credential setup

1. Import the workflow into n8n.
2. Create an n8n **Header Auth** credential containing header name `x-api-key` and the Anthropic API key as its value.
3. Attach that credential to **Claude Realtime Answer**.
4. Set `AI_PRIMARY_MODEL` to the approved Claude model identifier.
5. Run **Manual Trigger** before activating the webhook.

No Anthropic key is stored in the workflow JSON or repository.

## Live-results connections still required

Add read-only sub-workflows to the shared execution core:

- Shopify catalog, inventory, orders, fulfillment, customers, finance, and analytics reads.
- CJ catalog, supplier-order, shipping quote, inventory, and tracking reads.
- PostgreSQL operational state, memory, approvals, metrics, and audit reads.
- Google Sheets review and configuration reads.

Every tool response must include `source_type`, `source_id`, `observed_at`, and the fields used in the answer. The final response sets `live_data_used: true` only when at least one verified tool result is cited.

## Longer jobs

Questions expected to exceed the synchronous response window use `response_jobs` from migration `003`. The immediate response returns a job ID and status. Progress updates and the completed answer are stored against the same conversation and correlation ID. This path must be implemented before deep multi-source research is presented as realtime.

## Write requests

Questions may be answered immediately, but requests such as publish, refund, submit supplier order, send message, create discount, cancel, or change price are never executed through the fast path. They return `approval_required: true` and route to the Think–Authorize–Act core.
