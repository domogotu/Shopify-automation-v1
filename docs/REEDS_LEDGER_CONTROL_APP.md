# Reeds Ledger Owner Control App

This repo contains a safe static control UI at `control-app/index.html`.

## Purpose

The control app gives Dominique Reed one place to review:

- the current production intake path;
- the Reeds Intelligence Core executive chain;
- current n8n workflow names and IDs;
- credential responsibility rules;
- security gates and failure behavior;
- the next build order for the governed backend.

## Current safety boundary

The app is intentionally static. It can explain the saved architecture and use local browser speech recognition, but it must not directly execute restricted actions.

Do not place these values in browser JavaScript, Drive docs, Sheets, GitHub, emails, prompts, or customer-visible text:

- OpenAI API keys;
- Anthropic / Claude API keys;
- n8n API keys;
- Postgres connection strings or passwords;
- Gmail app passwords;
- Google OAuth client secrets;
- Shopify, CJdropshipping, DSers, payment, or supplier credentials.

## Correct live architecture

The static app should later call a secure backend service. That backend service should:

1. authenticate Dominique as owner;
2. load secrets only from Render environment variables;
3. call n8n, Postgres, OpenAI, Claude, Gmail, Sheets, Drive, Shopify, or supplier APIs server-side only;
4. check the destination allowlist before every write;
5. pass restricted actions through the policy gate;
6. require owner approval for customer replies, quotes, access changes, production deploys, spending, destructive actions, and credential changes;
7. verify each result before writing success memory;
8. log every action, denial, approval, and verification result.

## Known open gaps

- The static app is not a live database dashboard yet.
- Destination allowlisting still needs a real table and UI.
- The live intake workflow does not fully call every new governed workflow yet.
- The specialist agent list needs reconciliation with the latest target architecture.
- Redis queue mode should wait until the governed path passes repeated live tests.

## Render deployment

`render.yaml` includes a separate static service:

`reeds-ledger-control-app`

It publishes `control-app/` and does not disturb the existing n8n service.
