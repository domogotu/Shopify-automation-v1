# Safe Agent Workflow Updates

## Core rule

A successful n8n execution does not prove that a tool returned correct or usable content. Every tool result passes through a deterministic content validator before an agent may use it as evidence or justify a workflow update.

## Required pattern

```text
Trigger
→ quick deterministic filter
→ structured change classifier
→ tool call
→ normalize result envelope
→ assert required content
→ retry timeout/transient failure
→ human inbox if unresolved
→ draft change
→ static/security/sandbox tests
→ approval if required
→ execute in allowed environment
→ read actual downstream state
→ compare intended vs actual content
→ log
→ keep or roll back
```

The classification decision is stored as structured data and enforced by workflow branches. It is not hidden only inside a model prompt.

## Tool-result envelope

Every tool adapter returns a status, structured data, errors, timestamp, attempt number, source reference, and tool-call ID. `SUCCESS` is accepted only when the operation-specific required fields and assertions pass. Empty, malformed, missing, timed-out, unauthorized, or error responses are withheld from the agent.

The agent receives either validated data or an explicit retry/human-review state. It never receives an ambiguous empty response that it could reinterpret as success.

## Workflow modification path

Agents may inspect actual workflow context and draft or edit workflow JSON using an approved MCP, n8n-as-code, or editor-integrated tool. Changes first land as versioned artifacts in source control or the draft registry—not directly in production.

Editor loop:

```text
Select workflow/node
→ explain current behavior
→ propose diff
→ validate JSON and expressions
→ run fixtures
→ review diff
→ deploy to sandbox
→ execute and inspect content
→ approve promotion
```

## Reversibility

- Low-risk reversible drafts and sandbox artifacts may be created automatically.
- Medium-risk reversible changes require approval and a tested rollback.
- Irreversible, financial, permission, database, credential, deletion, or production-write changes require human approval, independent review, content verification, and recovery planning.

All pending actions appear in one `SYSTEM_CHANGE_REVIEW` inbox with the proposal, evidence, diff, tests, risk, cost, approval requirement, and rollback plan.
