#!/bin/sh
set -eu

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
failures=0

for file in "$root_dir"/config/*.json "$root_dir"/workflows/*.json; do
  if ! jq empty "$file"; then
    echo "Invalid JSON: $file"
    failures=$((failures + 1))
  fi
done

node "$root_dir/scripts/validate-workflow-code.js" || failures=$((failures + 1))\nnode "$root_dir/scripts/audit-integrations.mjs" || failures=$((failures + 1))

expected=1
for migration in "$root_dir"/database/migrations/*.sql; do
  number="$(basename "$migration" | cut -d_ -f1 | sed 's/^0*//')"
  if [ -z "$number" ]; then number=0; fi
  if [ "$number" -ne "$expected" ]; then
    echo "Migration sequence error: expected $expected, found $(basename "$migration")"
    failures=$((failures + 1))
  fi
  if grep -q '^BEGIN;' "$migration" || grep -q '^COMMIT;' "$migration"; then
    echo "Migration contains embedded transaction boundary: $(basename "$migration")"
    failures=$((failures + 1))
  fi
  expected=$((expected + 1))
done

for required in "await client.query('BEGIN')" "await client.query('COMMIT')" "await client.query('ROLLBACK')" "pg_advisory_lock" "checksum_sha256"; do
  if ! grep -Fq "$required" "$root_dir/scripts/migrate-database.mjs"; then
    echo "Database migrator missing safety control: $required"
    failures=$((failures + 1))
  fi
done

for key in N8N_ENCRYPTION_KEY N8N_USER_MANAGEMENT_JWT_SECRET POSTGRES_PASSWORD REDIS_PASSWORD SYSTEM_KILL_SWITCH; do
  if ! grep -q "^${key}=" "$root_dir/config/.env.docker.example"; then
    echo "Missing environment contract: $key"
    failures=$((failures + 1))
  fi
done

for unsafe in 'AUTO_PUBLISH_PRODUCTS: "true"' 'AUTO_SUBMIT_SUPPLIER_ORDERS: "true"' 'AUTO_SEND_SUPPORT_MESSAGES: "true"' 'SYSTEM_KILL_SWITCH: "false"'; do
  if grep -q "$unsafe" "$root_dir/compose.yaml"; then
    echo "Unsafe compose default found: $unsafe"
    failures=$((failures + 1))
  fi
done

if [ "$failures" -ne 0 ]; then
  echo "Foundation validation failed with $failures error(s)"
  exit 1
fi

echo "Foundation validation passed"
