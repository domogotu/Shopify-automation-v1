# Reeds Ledger Control API

This private-boundary web service supports the public static owner console without exposing provider or database credentials to the browser.

## Routes

- `GET /api/health` reports configuration booleans only.
- `GET /api/status` returns safe aggregate counts.
- `GET /api/approvals` returns pending approval summaries.
- `GET /api/memory` returns recent non-secret governed memory.
- `GET /api/credentials` returns credential names and storage locations, never values.
- `POST /api/chat` proxies owner chat to OpenAI.

All routes except health require `X-Owner-Passphrase`. Render owns `DATABASE_URL`, `OPENAI_API_KEY`, and `OWNER_PASSPHRASE`; none belong in Git or browser storage beyond the passphrase's current tab session.
