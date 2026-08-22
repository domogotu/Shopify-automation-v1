# Chat Routing, Memory Commands, and Feedback

## Routes added from the reference workflow

- `/ask` — answer a normal question through the realtime gateway.
- `/decide` or `/analyze` — use ChatGPT executive planning, specialists, supervisor review, policy checks, and approval routing.
- `/memory` — show relevant information remembered for the current store and session.
- `/remember` — propose information for governed memory storage.
- `/correct-memory` — propose a correction or superseding memory version.
- `/forget` — request redaction or deletion under the memory policy.
- `/feedback` or `/correct-answer` — rate and explain a previous answer.
- `/status` or `/progress` — retrieve automation, approval, or long-running job status.

Normal messages default to `/ask`; the executive may elevate them to `/decide` when the request requires comparison, specialist evidence, or an action.

## Feedback flow

1. Pause the affected decision or memory promotion when possible.
2. Link feedback to the conversation, answer, decision, sources, and selected agents.
3. Classify the issue as incorrect fact, stale data, missing evidence, bad routing, policy error, unsafe recommendation, unclear answer, or user preference.
4. Recheck authoritative data and source references.
5. Let ChatGPT propose a correction and lesson.
6. Require approval before correcting verified memory or promoting a procedural lesson.
7. Version the correction; never silently rewrite audit history.
8. Re-evaluate the affected answer or decision and notify the user of the result.

Feedback improves the system but never automatically changes permissions, approval rules, or production workflows.
