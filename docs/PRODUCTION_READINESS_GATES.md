# Production Readiness Gates

## Assessment

The system is ready to begin foundation deployment and integration testing. It is not ready for autonomous production writes. Production authority is enabled capability by capability only after the following gates pass.

## Required before any live connection

- deploy n8n, PostgreSQL, queue storage, secret storage, and object storage;
- apply and verify database migrations;
- create least-privilege runtime, migration, read-only, and support roles;
- enable and test store-scoped row-level security;
- configure encrypted backups and complete a restore drill;
- configure OpenTelemetry-compatible traces, metrics, and logs;
- configure workflow timeouts, bounded retries, execution-data retention, and dead-letter handling;
- import workflows with all external writes disabled;
- attach credentials through encrypted credential storage only.

## Required before read-only production use

- verify Shopify and AgentMail webhook signatures;
- deduplicate Shopify webhooks by webhook ID and AgentMail webhooks by event ID;
- validate every tool response through the content assertion contract;
- run scheduled reconciliation between Shopify, suppliers, PostgreSQL, and Sheets;
- test rate limits, timeouts, empty responses, partial responses, and expired credentials;
- pass prompt-injection, attachment, cross-store, and sensitive-data tests;
- show sources and freshness for material claims.

## Required before each write capability

- idempotency key and payload hash;
- deterministic authorization and feature flag;
- exact payload-bound approval where required;
- operation-specific response schema and content assertions;
- read-after-write verification;
- unknown-outcome reconciliation path;
- safe retry classification;
- rollback, compensation, or human recovery plan;
- alerts and an owner kill switch;
- representative and adversarial regression tests.

## Deployment progression

```text
OFF
→ OBSERVE
→ DRAFT
→ APPROVAL_REQUIRED
→ CANARY
→ AUTOMATED
```

No feature skips a stage. Shopify publishing, supplier purchasing, refunds, customer-facing messages, discounts, campaigns, credentials, permissions, database migrations, and system changes remain approval-gated until their separate production evidence is accepted.

## Reliability patterns

- The transactional outbox prevents a database update and its follow-up event from silently diverging.
- The dead-letter queue preserves exhausted failures for review instead of losing or infinitely retrying them.
- Webhook receipts provide signature state, payload hash, deduplication, processing status, and correlation.
- Reconciliation detects missed, duplicated, delayed, or unknown outcomes.
- Feature flags and kill switches limit blast radius and support immediate disablement.
- Point-in-time recovery and tested restores protect durable memory and audit records.
- OpenTelemetry-compatible correlation connects user request, agent plan, tool call, workflow, approval, external action, and verification.

## Go-live decision

The owner receives a production-readiness report containing evidence for every gate. Any failed or unverified mandatory gate results in a no-go decision for that capability while unrelated verified read-only capabilities may continue.
