# Governed Database Migration Runbook

## Safety defaults

- Custom Shopify Automation OS objects live in `automation_os`.
- n8n internal objects remain in `public`.
- `RUN_DATABASE_MIGRATIONS=false` is the normal runtime state.
- Migrations run under a PostgreSQL advisory lock.
- Each migration and its checksum are recorded in
  `automation_os.schema_migrations`.
- A changed migration that was already applied causes a hard failure.
- Store and CJ supplier seed operations are idempotent.

## One-time application procedure

1. Confirm the current n8n deployment is healthy and workflows are visible.
2. Confirm a database backup or export path is available.
3. Enable `RUN_DATABASE_MIGRATIONS=true` for one controlled deployment.
4. Require all eleven `Applying migration ...` or `Skipping verified ...`
   messages without errors.
5. Require `Database foundation verified` with:
   - `migration_count: 11`
   - `store_count: 1` or greater
   - a nonnegative `category_count`
6. Verify n8n starts and its workflows remain visible.
7. Return `RUN_DATABASE_MIGRATIONS=false` and redeploy.

## Failure behavior

The migrator exits nonzero on a missing environment variable, connection
failure, SQL failure, checksum mismatch, seed failure, or verification failure.
Render must not promote that deployment. A failed migration transaction rolls
back its schema changes and migration record together.

Do not edit an applied migration to repair production. Add a new numbered
migration with forward and rollback instructions.

## Read-only verification queries

```sql
SELECT version, filename, checksum_sha256, applied_at
FROM automation_os.schema_migrations
ORDER BY version;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'automation_os'
ORDER BY table_name;

SELECT shop_domain, display_name, active
FROM automation_os.stores;
```

## Rollback policy

Before production data exists, a failed first installation may be corrected by
fixing the unapplied migration and retrying. After any migration is recorded,
use a new forward migration. Destructive schema rollback requires an explicit
backup, a reviewed rollback script, and human approval.
