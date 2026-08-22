# Shopify Automation OS

This repository contains the governed Shopify automation system: n8n workflows, PostgreSQL schemas, Redis-backed queue processing, memory and knowledge controls, ChatGPT executive supervision, Claude specialists, Shopify/CJ operations, AgentMail email handling, approvals, verification, and controlled system improvement.

## Current build state

Milestone 1 provides a staging foundation. External writes remain disabled. The stack includes:

- n8n main instance;
- n8n queue worker;
- PostgreSQL with the automation schema and n8n schema;
- Redis durable queue storage;
- ordered database migrations and idempotent store seed;
- local workflow and configuration mounts;
- safe launch defaults and a system kill switch.

Architecture JSON and workflow JSON are validated locally. Container startup cannot be executed in environments without Docker.

## Start locally

1. Install Docker Desktop.
2. Copy `config/.env.docker.example` to `config/.env`.
3. Replace every `replace-me` value with a unique secret.
4. Keep all `AUTO_*` values false and `SYSTEM_KILL_SWITCH=true`.
5. Start the stack:

```bash
docker compose --env-file config/.env up -d
```

6. Check services:

```bash
docker compose --env-file config/.env ps
docker compose --env-file config/.env logs migrate
docker compose --env-file config/.env logs n8n-main
```

7. Open `http://localhost:5678` and create the initial n8n owner account.

8. Import workflow definitions in their default deactivated state:

```bash
sh scripts/import-workflows.sh
```

CLI workflow imports are deactivated by default. Review every credential, environment value, tool schema, and approval branch before activating a trigger.

## Validate before startup

```bash
sh scripts/validate-foundation.sh
```

## Safety state

Do not add live Shopify, CJ, AgentMail, Google, OpenAI, or Anthropic credentials until migrations complete and the health-check workflow passes. Read-only credentials are connected first. Publishing, supplier purchases, refunds, customer emails, discounts, campaigns, database changes, permissions, and system releases remain approval-gated.

## Next milestone

Import shared workflows, attach the production PostgreSQL credential, enable read-only Shopify access, connect memory retrieval/write gates to the executive workflow, and run the first end-to-end question without external writes.

## Render cloud staging

`render.yaml` provisions a public n8n web service, a queue worker, an internal PostgreSQL database, and an internal Redis-compatible queue. Render generates the n8n encryption secrets. All commerce and customer-facing writes remain disabled and the global kill switch remains enabled.

After `render.yaml` is pushed to GitHub, open the repository Blueprint link in Render, review the free-plan resources, and apply the Blueprint. Create the initial n8n owner account only after the web service reports healthy.
