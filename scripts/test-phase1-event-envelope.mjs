#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const workflow = JSON.parse(fs.readFileSync(path.join(root, 'workflows/00A-universal-event-envelope-v1.json'), 'utf8'));
const migration = fs.readFileSync(path.join(root, 'database/migrations/012_universal_event_envelope.sql'), 'utf8');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function node(name) {
  const found = workflow.nodes.find((candidate) => candidate.name === name);
  if (!found) throw new Error(`missing node ${name}`);
  return found;
}

assert(workflow.active === false, 'Phase 1 envelope workflow must remain inactive on import');
assert(!workflow.nodes.some((candidate) => candidate.credentials), 'workflow source must not contain credentials');

const normalize = node('Normalize Universal Event Envelope');
const persist = node('Persist Universal Event Envelope');
const receipt = node('Return Envelope Receipt');

assert(normalize.type === 'n8n-nodes-base.code', 'normalizer must be a code node');
assert(persist.type === 'n8n-nodes-base.postgres', 'event envelope must persist to PostgreSQL');
assert(receipt.type === 'n8n-nodes-base.code', 'receipt must be returned by code node');

for (const required of ['store_domain', 'message', 'actor_id', 'source_type', 'request_type']) {
  assert(normalize.parameters.jsCode.includes(required), `normalizer does not enforce ${required}`);
}

for (const field of ['event_id','correlation_id','received_at','source_type','source_id','actor_id','store_domain','session_id','request_type','message','resource_type','risk_level','execution_mode']) {
  assert(normalize.parameters.jsCode.includes(field), `normalizer missing field ${field}`);
}

assert(persist.parameters.query.includes('automation_os.universal_event_envelopes'), 'envelope insert must be schema-qualified');
assert(persist.parameters.query.includes('automation_os.authority_audit_records'), 'authority audit insert must be schema-qualified');
assert(persist.parameters.query.includes('CAST($13 AS automation_os.universal_risk_level)'), 'risk level cast must be schema-qualified');
assert(persist.parameters.query.includes('ON CONFLICT (correlation_id)'), 'event envelope must be idempotent by correlation_id');

for (const ddl of ['CREATE TYPE universal_event_status', 'CREATE TYPE universal_risk_level', 'CREATE TABLE universal_event_envelopes', 'CREATE TABLE authority_audit_records', 'CREATE TABLE policy_decision_records']) {
  assert(migration.includes(ddl), `migration missing ${ddl}`);
}

console.log('Phase 1 universal event envelope contract passed');
