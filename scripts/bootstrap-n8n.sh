#!/bin/sh
set -eu

if [ "${RUN_DATABASE_MIGRATIONS:-false}" = "true" ]; then
  echo "Applying governed Shopify Automation database migrations"
  node /opt/shopify-automation/migrate-database.mjs
else
  echo "Database migrations disabled; preserving existing schemas"
fi

if [ "${SYNC_EXECUTIVE_WORKFLOW_ONCE:-false}" = "true" ]; then
  echo "Synchronizing corrected executive workflow only"
  mkdir -p /tmp/shopify-automation-executive-sync
  cp /opt/shopify-automation/workflows/00-chatgpt-executive-supervisor-v1.json /tmp/shopify-automation-executive-sync/
  n8n import:workflow --separate --input=/tmp/shopify-automation-executive-sync
elif [ "${FORCE_BOOTSTRAP_WORKFLOWS:-false}" = "true" ] || [ "${BOOTSTRAP_WORKFLOWS:-false}" = "true" ]; then
  echo "Importing governed Shopify Automation workflows"
  n8n import:workflow --separate --input=/opt/shopify-automation/workflows
else
  echo "Workflow bootstrap disabled; preserving database workflows"
fi

exec n8n start
