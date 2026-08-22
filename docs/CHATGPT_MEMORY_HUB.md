# ChatGPT Memory Hub

## Required flow for every interaction

1. Accept and sanitize the user message.
2. Store the message in `conversation_messages` under the correct store and session.
3. Pass proposed durable memories through the governed memory write gate.
4. Retrieve recent conversation history and relevant verified memory before executive planning.
5. Retrieve current authoritative Shopify, CJ, PostgreSQL, policy, and approval records required for the decision.
6. Give ChatGPT a compact cited context package.
7. Store the executive plan, specialist reports, supervisor review, user-facing answer, approval decision, execution result, and verification outcome.
8. Convert repeated history into summaries while retaining required audit records.
9. Classify durable memory into one primary and optional secondary governed categories.
10. Route unmatched subjects to category review and propose new categories when repeated evidence justifies them.

## What is remembered

- conversations and assistant answers;
- store preferences and approved business rules;
- verified product and supplier facts;
- Shopify/CJ identifier mappings;
- pricing assumptions and approved thresholds;
- orders, tracking exceptions, and resolutions;
- specialist evidence and source references;
- executive plans and supervisor reviews;
- approvals, denials, and reviewer reasons;
- tool outcomes, errors, retries, and recoveries;
- measured results and approved lessons.

## What is not remembered as ordinary memory

- API keys, passwords, access tokens, or security answers;
- complete payment-card numbers;
- customer personal data not required for the authorized operation;
- model guesses presented as facts;
- expired information presented as current;
- permissions or approvals inferred from conversation.

## Implemented workflows

- `00D-memory-write-gate-v1.json` redacts common secret patterns, stores messages, and writes governed memory candidates to PostgreSQL.
- `00E-scoped-memory-retrieval-v1.json` retrieves recent messages and verified, unexpired, sensitivity-permitted memory only within the selected store.

Both workflows require the production PostgreSQL credential to be attached after import. The ChatGPT Executive workflow must call retrieval before planning and the write gate after every user, assistant, specialist, supervisor, approval, tool, and verification event.

## Important distinction

Memory helps ChatGPT remember context, but it is not automatically current. Before making a decision about inventory, price, order status, tracking, supplier availability, approval, or policy, the system checks the authoritative live record. A remembered fact that conflicts with current data is marked stale and cannot authorize an action.

## Expandable category system

`config/memory-taxonomy.json` and migration `007_dynamic_memory_taxonomy.sql` add an expandable hierarchy over governed memories. A memory can be found through multiple categories without copying the underlying record. The system can propose new categories, aliases, merges, splits, moves, and archives, while high-impact structural changes require review. See `docs/DYNAMIC_MEMORY_CATEGORIES.md`.
