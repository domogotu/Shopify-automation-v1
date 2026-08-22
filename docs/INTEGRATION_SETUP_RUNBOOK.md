# Integration setup runbook

This runbook connects the imported workflows without activating commerce actions.

## Current safety state

- Keep every workflow inactive during setup.
- Keep `SYSTEM_KILL_SWITCH=true`.
- Keep all `AUTO_*` action flags `false`.
- Keep `CJ_API_ENABLED=false`.
- Keep `RUN_DATABASE_MIGRATIONS=false` until a separately approved database window.
- PostgreSQL remains unchanged by this runbook.

## Required secrets and settings

| Integration | Required setting | Used by | Setup state |
|---|---|---|---|
| OpenAI | `OPENAI_API_KEY` | Executive brain and decision supervisor | Add to Render environment group |
| OpenAI | `OPENAI_ORCHESTRATOR_MODEL` | First executive analysis | Choose approved model |
| OpenAI | `OPENAI_SUPERVISOR_MODEL` | Independent decision review | Choose approved model |
| Anthropic | `ANTHROPIC_API_KEY` | Realtime Claude specialist | Add to Render environment group |
| Anthropic | `AI_SPECIALIST_PRIMARY_MODEL` | Realtime Claude specialist | Choose approved Claude model |
| PostgreSQL | n8n Postgres credential | Memory write, retrieval, improvement, assertions | Create in n8n; do not paste into workflow JSON |
| AgentMail | `AGENTMAIL_WEBHOOK_SECRET` | Inbound signature validation | Add only when AgentMail testing begins |
| AgentMail | `AGENTMAIL_API_KEY` | Approved reply sender | Add only when AgentMail testing begins |
| Shopify | n8n Shopify credential | Future commerce tools | Do not connect to an active execution path yet |
| Google Sheets | n8n Google Sheets credential | Human review mirror | Configure after database approval |

Do not paste secret values into GitHub, workflow names, notes, screenshots, or chat.

## PostgreSQL credential

Create one n8n Postgres credential that uses the Render database connection values already wired to the service. Assign it to:

- `00D - Governed Memory Write Gate v1`
- `00E - Scoped Memory Retrieval v1`
- `00J - System Architect Improvement Intake v1`
- `00K - Tool Result Content Validator v1`

The workflow SQL is explicitly scoped to `automation_os`. These workflows will remain non-runnable until the database migrations are deliberately enabled and verified.

## Safe test order

1. Run `00 - Environment Health Check v1` manually.
2. Test `00K - Tool Result Content Validator v1` with a deliberately incomplete mock tool result; it must fail closed.
3. Test the ChatGPT supervisor using mock data only.
4. Test the realtime Claude workflow using a non-commerce question and mock store context.
5. Test the orchestrator in plan-only mode.
6. Test memory only after the database migration window is approved.
7. Test AgentMail inbound parsing without sending a reply.
8. Test approved replies only with a test inbox and explicit approval.

## Skip-until-end rule

During setup, record non-critical failures and continue with independent checks. Stop immediately only for:

- exposed or suspected leaked secrets;
- an external action executing unexpectedly;
- the kill switch becoming false;
- a workflow becoming active unexpectedly;
- data loss, destructive database changes, or an unauthorized payment/order/refund.

At the end of each setup pass, review every skipped item with its evidence, severity, owner, and next action.

## Activation gate

No workflow may be activated until all of the following are true:

- credentials are stored securely;
- mock tests pass;
- content assertions fail closed;
- human approval routes are verified;
- idempotency and post-action verification are demonstrated;
- database migrations are approved and verified where required;
- the global kill switch and per-action flags behave as designed.
