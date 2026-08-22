#!/bin/sh
set -eu

if [ "${BOOTSTRAP_WORKFLOWS:-false}" = "true" ]; then
  echo "Importing governed Shopify Automation workflows"
  n8n import:workflow --separate --input=/opt/shopify-automation/workflows
else
  echo "Workflow bootstrap disabled; preserving database workflows"
fi

exec n8n start
