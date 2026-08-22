#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const registry = JSON.parse(fs.readFileSync(path.join(root, 'config', 'integration-registry.json'), 'utf8'));
const missingEnvironment = [];
const integrations = [];

for (const integration of registry.integrations) {
  const missing = (integration.required_env ?? []).filter((key) => !process.env[key]);
  missingEnvironment.push(...missing.map((key) => ({ integration: integration.key, key })));
  integrations.push({
    key: integration.key,
    provider: integration.provider,
    declared_readiness: integration.readiness,
    environment_ready: missing.length === 0,
    missing_environment_keys: missing,
    manual_credentials_required: integration.required_n8n_credentials ?? [],
    risk: integration.risk,
  });
}

const controls = {
  system_kill_switch: process.env.SYSTEM_KILL_SWITCH ?? 'UNSET',
  database_migrations: process.env.RUN_DATABASE_MIGRATIONS ?? 'UNSET',
  bootstrap_workflows: process.env.BOOTSTRAP_WORKFLOWS ?? 'UNSET',
  auto_publish_products: process.env.AUTO_PUBLISH_PRODUCTS ?? 'UNSET',
  auto_submit_supplier_orders: process.env.AUTO_SUBMIT_SUPPLIER_ORDERS ?? 'UNSET',
  auto_send_support_messages: process.env.AUTO_SEND_SUPPORT_MESSAGES ?? 'UNSET',
  auto_process_refunds: process.env.AUTO_PROCESS_REFUNDS ?? 'UNSET',
};

const unsafe = [];
if (controls.system_kill_switch !== 'true') unsafe.push('SYSTEM_KILL_SWITCH must be true');
for (const [name, value] of Object.entries(controls)) {
  if (name.startsWith('auto_') && value === 'true') unsafe.push(`${name} must not be true during setup`);
}
if (controls.database_migrations === 'true') unsafe.push('database migrations are enabled');
if (controls.bootstrap_workflows === 'true') unsafe.push('workflow bootstrap is enabled');

const report = {
  status: unsafe.length ? 'UNSAFE' : missingEnvironment.length ? 'CONFIGURATION_REQUIRED' : 'READY_FOR_MOCK_TESTS',
  generated_at: new Date().toISOString(),
  secret_values_redacted: true,
  controls,
  unsafe,
  integrations,
  missing_environment: missingEnvironment,
  manual_steps: [
    'Assign Postgres credentials to the four database workflows',
    'Keep all workflows inactive',
    'Use mock data before any live integration test',
    'Verify content, not only execution status',
  ],
};
console.log(JSON.stringify(report, null, 2));
if (unsafe.length || process.argv.includes('--strict') && missingEnvironment.length) process.exit(1);
