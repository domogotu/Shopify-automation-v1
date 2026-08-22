# ChatGPT Executive Brain

## Authority hierarchy

1. **ChatGPT Executive Orchestrator** understands the user request, retrieves allowed context, identifies uncertainty, and selects one or more specialist agents.
2. **Specialist agents** analyze their assigned portion and return a common evidence bundle. Claude may remain the primary specialist model where appropriate.
3. **ChatGPT Decision Supervisor** reviews the original request, executive plan, specialist evidence, competing options, financial effects, risk, policies, and missing information.
4. **Deterministic policy gate** checks permissions, store scope, current approval, risk limits, payload hash, tool allowlist, and idempotency. ChatGPT cannot bypass this gate.
5. **Human approval** remains mandatory for high-risk commerce actions.
6. **Act runtime** executes only the approved action envelope.
7. **Post-action verifier** confirms the external result and reports discrepancies before the case is closed.

## Decision standard

The supervisor does not merely ask whether an answer sounds reasonable. It verifies:

- the request was understood correctly;
- the right specialists were consulted;
- each material claim has current evidence;
- conflicting facts are visible;
- realistic alternatives were compared;
- margin, cost, delivery, customer, supplier, legal, and operational risks were considered when relevant;
- the proposed action follows active policy;
- approvals and tool permissions are correct;
- execution can be retried safely or recovered;
- the expected result can be measured afterward.

If evidence is weak, conflicting, stale, or incomplete, the correct decision is `NEEDS_INFORMATION` or `NEEDS_REVIEW`, not a confident guess.

## Model roles

- `OPENAI_ORCHESTRATOR_MODEL`: ChatGPT executive routing and planning.
- `OPENAI_SUPERVISOR_MODEL`: ChatGPT final comparison and review.
- `AI_SPECIALIST_PRIMARY_PROVIDER`: Anthropic by default.
- `AI_SPECIALIST_PRIMARY_MODEL`: approved Claude model.
- `AI_FALLBACK_PROVIDER` and `AI_FALLBACK_MODEL`: retryable provider fallback only.

The OpenAI implementation uses the Responses API. The executive and supervisor must return versioned structured JSON so invalid free-form output cannot reach authorization.

## Executive plan contract

Required fields:

- `request_summary`
- `selected_agents`
- `questions_to_answer`
- `required_memory_scopes`
- `required_tools`
- `known_facts`
- `assumptions`
- `missing_information`
- `candidate_actions`
- `risk_level`
- `requires_human_approval`
- `stop_conditions`

## Specialist evidence contract

Every specialist returns:

- `agent_key`
- `status`
- `facts`
- `findings`
- `options`
- `risks`
- `source_refs`
- `missing_information`
- `recommendation`

Specialists do not make the final decision and cannot authorize external writes.

## Supervisor review contract

Required fields:

- `decision_status`
- `evidence_quality`
- `confidence`
- `selected_option`
- `rationale`
- `rejected_options`
- `unresolved_conflicts`
- `missing_information`
- `policy_checks`
- `requires_human_approval`
- `safe_to_execute`
- `recommended_next_step`
- `post_action_verification`

## User-facing response

Before an action is taken, the chat response should show:

1. What you asked.
2. What the system verified.
3. Which agents were consulted.
4. Best option and why.
5. Other options considered.
6. Risks or missing information.
7. Whether approval is required.
8. What will happen next.

This keeps ChatGPT understandable and accountable instead of hiding the decision process.
