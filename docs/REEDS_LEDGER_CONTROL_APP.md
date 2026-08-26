# Reeds Ledger Owner Control App

This repo contains a static owner UI at `control-app/index.html` and its secured server boundary in `control-api/`.

## Purpose

The control app gives Dominique Reed one place to review and operate the safe local parts of the system:

- the current production intake path;
- the Reeds Intelligence Core executive chain;
- current n8n workflow names and IDs;
- credential responsibility rules;
- security gates and failure behavior;
- the next build order for the governed backend.
- secured OpenAI chat with voice input, spoken replies, and a text transcript;
- non-secret local memory notes;
- read-only governed approvals, memory, and status from Postgres;
- governed action request drafts for future backend execution.

## Safety boundary

The public UI never receives database or provider credentials. It sends owner-authenticated requests to `reeds-ledger-control-api`, which reads limited non-secret records and proxies chat to OpenAI. The app must not directly execute restricted actions. Its action builder remains draft-only.

Do not place these values in browser JavaScript, Drive docs, Sheets, GitHub, emails, prompts, or customer-visible text:

- OpenAI API keys;
- Anthropic / Claude API keys;
- n8n API keys;
- Postgres connection strings or passwords;
- Gmail app passwords;
- Google OAuth client secrets;
- Shopify, CJdropshipping, DSers, payment, or supplier credentials.

## Live architecture

`reeds-ledger-control-app` (Render static site) calls `reeds-ledger-control-api` (Render Node web service). Render injects the database connection from `shopify-automation-postgres`. The owner enters a passphrase stored only in the current browser tab. The backend:

1. authenticate Dominique as owner;
2. load secrets only from Render environment variables;
3. currently calls Postgres and OpenAI server-side only;
4. check the destination allowlist before every write;
5. pass restricted actions through the policy gate;
6. require owner approval for customer replies, quotes, access changes, production deploys, spending, destructive actions, and credential changes;
7. verify each result before writing success memory;
8. log every action, denial, approval, and verification result.

## Required Render secrets

The API service has two `sync: false` values that must be entered directly in Render:

- `OPENAI_API_KEY`: use the same OpenAI project as n8n, but create a new project key if the original plaintext key is no longer available. n8n does not reveal saved secret values.
- `OWNER_PASSPHRASE`: a unique strong passphrase saved in Dominique's password manager.

Never paste either value into GitHub, Drive, Sheets, email, or chat.

## Known open gaps

- Transcript and local notes remain browser-local. The app reads governed Postgres memory but does not yet write chat transcripts into governed memory.
- The temporary shared passphrase gate should eventually be replaced with owner identity, short-lived sessions, and multi-factor authentication.
- Destination allowlisting still needs a real table and UI.
- The live intake workflow does not fully call every new governed workflow yet.
- The specialist agent list needs reconciliation with the latest target architecture.
- Approval decisions remain in the payload-bound n8n approval workflow; the UI is read-only.
- Redis queue mode should wait until the governed path passes repeated live tests.

## Render deployment

`render.yaml` includes:

- `reeds-ledger-control-app`: static owner UI.
- `reeds-ledger-control-api`: secured Node API with a Postgres connection and secret slots.

These services do not replace or disturb the existing n8n service.
