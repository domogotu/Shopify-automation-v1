# Self-Governing System Architect

## Role

The System Architect is a governed meta-system above the executive, specialists, memory hub, and commerce workflows. It watches how the system performs and can design additional components when evidence shows that an existing component is missing, outdated, unreliable, inefficient, or too costly.

It can improve the system, but it cannot give itself production authority.

## Detection signals

- repeated workflow or verification failures;
- user corrections and poor answer-quality reviews;
- stale, conflicting, or repeatedly missing knowledge;
- uncategorized information that suggests a new subject library;
- repeated manual work that could become a workflow;
- requests the current agent registry cannot route;
- Shopify, supplier, model, or API changes;
- new laws, policies, risks, or business requirements;
- declining quality, rising latency, or excessive cost;
- an agent or workflow that is no longer used.

## Improvement cycle

```text
Observe
→ Open improvement case
→ Gather evidence
→ Check existing components
→ Design proposed change
→ Security and architecture review
→ Generate tests and rollback plan
→ Sandbox test
→ Human review and payload-bound approval
→ Shadow mode
→ Canary release
→ Production release
→ Monitor
→ Keep, revise, or roll back
```

Return loops send incomplete evidence back to research, weak designs back to the architect, failed tests back to design, and failed releases to automatic rollback plus owner review.

## What it may create

- a new specialist agent;
- a new n8n workflow or bounded sub-workflow;
- a new memory category or subject library;
- a source connector proposal;
- a document-ingestion or refresh rule;
- a revised prompt or structured output schema;
- a new deterministic validation rule;
- a dashboard or alert;
- a database migration;
- a proposal to retire or combine redundant components.

## Production boundary

The architect may autonomously investigate, draft artifacts, and run isolated tests. It may not activate a new production agent, workflow, integration, permission, migration, external write, spending limit, policy, or prompt without the required review and approval. Approval is bound to the exact artifact hash; changing the artifact invalidates the approval.

## Continuous correction

If a source becomes outdated, the architect opens a refresh case rather than silently treating the old fact as current. If a workflow repeatedly fails, it compares the intended and actual results, isolates the cause, proposes a fix, tests it, and recommends rollback when a safe fix is unavailable.

This produces controlled evolution rather than unrestricted AI self-modification.

## Tool failure protection and workflow editing

The architect may work from actual n8n workflow context through an approved MCP, n8n-as-code, or versioned workflow JSON. Generated changes go to the draft registry and editor review loop first. A green execution is never accepted as proof of success: every tool response is normalized, checked for required content, audited, and withheld from the agent when invalid. See `docs/SAFE_AGENT_WORKFLOW_UPDATES.md` and `config/tool-result-contract.json`.
