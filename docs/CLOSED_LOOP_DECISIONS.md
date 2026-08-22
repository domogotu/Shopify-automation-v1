# Closed-Loop Decisions

The system does not accept the first downward pass as final. Every major checkpoint can return the case to the stage capable of correcting it.

## Return paths

- **Supervisor → Specialists:** missing, stale, conflicting, or insufficient evidence.
- **Supervisor → Executive:** misunderstood request, incomplete scope, or missing alternatives.
- **Human approval → Executive:** requested changes, expired approval, or changed payload.
- **Verifier → Act runtime:** retryable failure or partial completion using the same idempotency envelope.
- **Verifier → Supervisor:** unexpected, unsafe, or non-retryable external result.
- **User feedback → Evidence and memory review:** incorrect answer, stale memory, missing context, or unsafe recommendation.

## Loop controls

- Each loop has a small retry limit.
- The complete decision has a total cycle ceiling.
- Every pass records its reason, inputs, new evidence, output, and elapsed time.
- The same unchanged failure cannot loop indefinitely.
- Changed action payloads invalidate prior approvals.
- A loop stops with a safe no-operation and owner review when data is unavailable, permission is denied, the user cancels, or continuing is unsafe.

## Final-output rule

A final answer is issued only when it is either:

1. a verified informational response;
2. a recommendation that clearly states uncertainty and approval status;
3. a verified external-action result; or
4. a safe stop explaining what remains unresolved.

No failed loop is hidden behind a confident final answer.
