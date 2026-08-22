#!/bin/sh
set -eu

# Compatibility wrapper. The Node migrator uses n8n's installed PostgreSQL
# driver, applies each migration atomically, verifies checksums, and isolates
# custom objects from n8n internals in the automation_os schema.
exec node /opt/shopify-automation/migrate-database.mjs
