#!/bin/sh
set -eu

psql -v ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
  version text PRIMARY KEY,
  filename text NOT NULL,
  applied_at timestamptz NOT NULL DEFAULT now()
);
CREATE SCHEMA IF NOT EXISTS n8n;
SQL

for migration in /migrations/*.sql; do
  version="$(basename "$migration" | cut -d_ -f1)"
  filename="$(basename "$migration")"
  applied="$(psql -v ON_ERROR_STOP=1 -Atqc "SELECT 1 FROM schema_migrations WHERE version = '$version'")"
  if [ "$applied" = "1" ]; then
    echo "Skipping applied migration $filename"
    continue
  fi
  echo "Applying migration $filename"
  psql -v ON_ERROR_STOP=1 -f "$migration"
  psql -v ON_ERROR_STOP=1 -c "INSERT INTO schema_migrations (version, filename) VALUES ('$version', '$filename')"
done

echo "Applying idempotent seed data"
psql -v ON_ERROR_STOP=1 \
  -v shopify_store_domain="$SHOPIFY_STORE_DOMAIN" \
  -v shopify_store_name="$SHOPIFY_STORE_NAME" \
  -f /seeds/001_store.sql

echo "Database foundation is ready"
