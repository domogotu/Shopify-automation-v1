#!/bin/sh
set -eu

if [ "${RUN_DATABASE_MIGRATIONS:-false}" = "true" ]; then
  echo "Applying governed Shopify Automation database migrations"
  node /opt/shopify-automation/migrate-database.mjs
else
  echo "Database migrations disabled; preserving existing schemas"
fi

if [ "${SYNC_PHASE0_ARCHITECTURE_ONCE:-false}" = "true" ]; then
  echo "Importing Reeds Technology Phase 0 architecture workflows"
  mkdir -p /tmp/reeds-technology-phase0-sync
  cp /opt/shopify-automation/workflows/[0-9][0-9]-architecture-*-phase0.json /tmp/reeds-technology-phase0-sync/
  phase0_count="$(find /tmp/reeds-technology-phase0-sync -maxdepth 1 -type f -name '*-phase0.json' | wc -l | tr -d ' ')"
  if [ "$phase0_count" -ne 11 ]; then
    echo "Expected 11 Phase 0 architecture workflows, found $phase0_count"
    exit 1
  fi
  n8n import:workflow --separate --input=/tmp/reeds-technology-phase0-sync
elif [ "${SYNC_PHASE1_ENVELOPE_ONCE:-false}" = "true" ]; then
  echo "Synchronizing Phase 1 universal event envelope workflow"
  mkdir -p /tmp/reeds-technology-phase1-envelope-sync
  cp /opt/shopify-automation/workflows/00A-universal-event-envelope-v1.json /tmp/reeds-technology-phase1-envelope-sync/
  phase1_count="$(find /tmp/reeds-technology-phase1-envelope-sync -maxdepth 1 -type f -name '00A-universal-event-envelope-v1.json' | wc -l | tr -d ' ')"
  if [ "$phase1_count" -ne 1 ]; then
    echo "Expected 1 Phase 1 universal event envelope workflow, found $phase1_count"
    exit 1
  fi
  n8n import:workflow --separate --input=/tmp/reeds-technology-phase1-envelope-sync
elif [ "${SYNC_MEMORY_WORKFLOWS_ONCE:-false}" = "true" ]; then
  echo "Synchronizing governed memory workflows"
  mkdir -p /tmp/shopify-automation-memory-sync
  cp /opt/shopify-automation/workflows/00D-memory-write-gate-v1.json /tmp/shopify-automation-memory-sync/
  cp /opt/shopify-automation/workflows/00E-scoped-memory-retrieval-v1.json /tmp/shopify-automation-memory-sync/
  n8n import:workflow --separate --input=/tmp/shopify-automation-memory-sync
elif [ "${SYNC_EXECUTIVE_WORKFLOW_ONCE:-false}" = "true" ]; then
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
