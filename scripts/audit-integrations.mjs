#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const workflowsDir = path.join(root, 'workflows');
const workflowFiles = fs.readdirSync(workflowsDir).filter((name) => name.endsWith('.json')).sort();
const envContract = [
  fs.readFileSync(path.join(root, 'config', '.env.example'), 'utf8'),
  fs.readFileSync(path.join(root, 'render.yaml'), 'utf8'),
].join('\n');
const dockerfile = fs.readFileSync(path.join(root, 'Dockerfile'), 'utf8');
const renderYaml = fs.readFileSync(path.join(root, 'render.yaml'), 'utf8');

const allowedHosts = new Set([
  'api.openai.com',
  'api.anthropic.com',
  'api.agentmail.to',
]);
const customTables = [
  'stores',
  'conversations',
  'conversation_messages',
  'memory_items',
  'improvement_cases',
  'tool_result_assertions',
];
const unsafeTrueFlags = [
  'AUTO_PUBLISH_PRODUCTS',
  'AUTO_SUBMIT_SUPPLIER_ORDERS',
  'AUTO_SEND_SUPPORT_MESSAGES',
  'AUTO_PROCESS_REFUNDS',
  'AUTO_CREATE_DISCOUNTS',
  'AUTO_LAUNCH_CAMPAIGNS',
  'CJ_API_ENABLED',
];
const secretPatterns = [
  /sk-proj-[A-Za-z0-9_-]{16,}/g,
  /sk-ant-[A-Za-z0-9_-]{16,}/g,
  /ghp_[A-Za-z0-9]{20,}/g,
  /github_pat_[A-Za-z0-9_]{20,}/g,
  /xox[baprs]-[A-Za-z0-9-]{16,}/g,
];

const errors = [];
const warnings = [];
const requiredEnv = new Set();
let codeNodes = 0;
let postgresNodes = 0;
let httpNodes = 0;

function error(file, message) {
  errors.push({ file, message });
}

function warning(file, message) {
  warnings.push({ file, message });
}

for (const filename of workflowFiles) {
  const relative = path.join('workflows', filename);
  const raw = fs.readFileSync(path.join(workflowsDir, filename), 'utf8');
  let workflow;
  try {
    workflow = JSON.parse(raw);
  } catch (cause) {
    error(relative, `invalid JSON: ${cause.message}`);
    continue;
  }

  if (workflow.active === true) error(relative, 'workflow is active in source control');
  for (const field of ['tags', 'tagIds', 'shared']) {
    if (Object.prototype.hasOwnProperty.call(workflow, field)) {
      error(relative, `non-portable relationship field is present: ${field}`);
    }
  }

  for (const match of raw.matchAll(/\$env\.([A-Z0-9_]+)/g)) requiredEnv.add(match[1]);
  for (const pattern of secretPatterns) {
    if (pattern.test(raw)) error(relative, 'possible live secret detected');
    pattern.lastIndex = 0;
  }

  for (const node of workflow.nodes ?? []) {
    if (node.type === 'n8n-nodes-base.code') codeNodes += 1;
    if (node.type === 'n8n-nodes-base.postgres') {
      postgresNodes += 1;
      if (!node.credentials) warning(relative, `Postgres credential must be assigned in n8n: ${node.name}`);
      const query = String(node.parameters?.query ?? '');
      for (const table of customTables) {
        const unqualified = new RegExp(`(?<!automation_os\\.)\\b${table}\\b`);
        if (unqualified.test(query)) error(relative, `custom table is not schema-qualified: ${table}`);
      }
    }
    if (node.type === 'n8n-nodes-base.httpRequest') {
      httpNodes += 1;
      const url = String(node.parameters?.url ?? '');
      const match = url.match(/https:\/\/([^/}\s]+)/);
      if (match && !allowedHosts.has(match[1])) error(relative, `external HTTP host is not allowlisted: ${match[1]}`);
    }
  }
}

for (const key of [...requiredEnv].sort()) {
  const present = new RegExp(`(?:^|\\n)(?:\\s*- key:\\s*|)${key}(?:=|\\s*$)`, 'm').test(envContract);
  if (!present) error('environment', `missing declared environment contract: ${key}`);
}

if (/^FROM\s+n8nio\/n8n:(?:latest|main)\s*$/m.test(dockerfile)) {
  error('Dockerfile', 'n8n image must be pinned to a tested version');
}

for (const key of unsafeTrueFlags) {
  const unsafe = new RegExp(`- key:\\s*${key}\\s*\\n\\s*value:\\s*["']?true["']?`, 'i');
  if (unsafe.test(renderYaml)) error('render.yaml', `unsafe action flag is enabled: ${key}`);
}
if (!/- key:\s*SYSTEM_KILL_SWITCH\s*\n\s*value:\s*["']?true["']?/i.test(renderYaml)) {
  error('render.yaml', 'SYSTEM_KILL_SWITCH must default to true');
}
if (!/- key:\s*RUN_DATABASE_MIGRATIONS\s*\n\s*value:\s*["']?false["']?/i.test(renderYaml)) {
  error('render.yaml', 'RUN_DATABASE_MIGRATIONS must remain false by default');
}

const report = {
  status: errors.length === 0 ? 'PASS' : 'FAIL',
  workflows: workflowFiles.length,
  code_nodes: codeNodes,
  postgres_nodes: postgresNodes,
  http_nodes: httpNodes,
  required_environment_keys: [...requiredEnv].sort(),
  errors,
  warnings,
};
console.log(JSON.stringify(report, null, 2));
if (errors.length > 0) process.exit(1);
