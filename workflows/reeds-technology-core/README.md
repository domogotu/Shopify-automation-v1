# Reeds Technology Core Artifacts

This folder contains import-safe source artifacts for the owner-governed intelligence ecosystem build. These are not secrets and are safe to keep in the public repository.

## Files

- database/migrations/013_policy_approval_tables.sql - policy decisions and human approval requests.
- database/migrations/014_core_contracts.sql - owner, identity, event, memory, tool execution, and verification tables.
- workflows/reeds-technology-core/reeds-policy-gate-and-approval-v1.json - deterministic policy gate plus approval wait.
- workflows/reeds-technology-core/reeds-identity-and-context-v1.json - scoped identity lookup and minimum-access fallback.
- workflows/reeds-technology-core/reeds-scoped-memory-retrieval-v1.json - scoped Postgres full-text memory retrieval.
- workflows/reeds-technology-core/reeds-model-router-v1.json - deterministic model routing contract.
- workflows/reeds-technology-core/reeds-governed-action-executor-v1.json - policy, approved execution, verification, and memory-write chain.

## Required before live import

Replace these n8n placeholders after importing, inside n8n only:

- REPLACE_WITH_EXISTING_POSTGRES_CREDENTIAL
- REPLACE_WITH_EXISTING_GMAIL_CREDENTIAL
- REPLACE_WITH_EXISTING_SHEETS_CREDENTIAL
- REPLACE_WITH_POLICY_GATE_WORKFLOW_ID

Do not replace these values in the public repository.

## Import order

1. Run database/migrations/013_policy_approval_tables.sql.
2. Run database/migrations/014_core_contracts.sql.
3. Import the five workflow JSON files from workflows/reeds-technology-core into n8n.
4. In n8n, connect each placeholder credential to the existing real credential.
5. In Reeds - Governed Action Executor v1, set REPLACE_WITH_POLICY_GATE_WORKFLOW_ID to the imported Policy Gate workflow ID.
6. Test with manual execution before wiring this executor into production workflows.

## Notes

The import copies intentionally omit top-level n8n tags/shared metadata because this deployment has already shown n8n v2 workflow import compatibility issues with relationship metadata.
