#!/bin/sh
set -eu

required="PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD REDIS_HOST REDIS_PORT REDIS_PASSWORD N8N_ENCRYPTION_KEY"
for key in $required; do
  eval "value=\${$key:-}"
  if [ -z "$value" ]; then
    echo "Required environment variable is missing: $key"
    exit 1
  fi
done

mode="${SERVICE_MODE:-main}"

if [ "$mode" = "main" ]; then
  sh /opt/shopify-automation/scripts/apply-migrations.sh
  exec n8n start
fi

if [ "$mode" = "worker" ]; then
  attempts=0
  until [ "$(psql -Atqc "SELECT 1 FROM schema_migrations WHERE version='011'" 2>/dev/null || true)" = "1" ]; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 60 ]; then
      echo "Timed out waiting for database migrations"
      exit 1
    fi
    sleep 5
  done
  exec n8n worker --concurrency="${N8N_WORKER_CONCURRENCY:-5}"
fi

echo "Unknown SERVICE_MODE: $mode"
exit 1
