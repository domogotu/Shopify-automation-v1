#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const dir = path.join(root, 'workflows');
const files = fs.readdirSync(dir).filter((name) => name.endsWith('.json')).sort();
const errors = [];
const warnings = [];
const names = new Map();
const webhookPaths = new Map();
let nodeCount = 0;

for (const file of files) {
  const relative = `workflows/${file}`;
  const workflow = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8'));
  if (!workflow.name) errors.push(`${relative}: missing workflow name`);
  if (names.has(workflow.name)) errors.push(`${relative}: duplicate workflow name also used by ${names.get(workflow.name)}`);
  names.set(workflow.name, relative);
  if (workflow.active === true) errors.push(`${relative}: source workflow must remain inactive`);

  const nodes = workflow.nodes ?? [];
  nodeCount += nodes.length;
  const nodeNames = new Set();
  const nodeIds = new Set();
  for (const node of nodes) {
    if (nodeNames.has(node.name)) errors.push(`${relative}: duplicate node name ${node.name}`);
    if (nodeIds.has(node.id)) errors.push(`${relative}: duplicate node id ${node.id}`);
    nodeNames.add(node.name);
    nodeIds.add(node.id);

    if (node.type === 'n8n-nodes-base.webhook') {
      const webhookPath = node.parameters?.path;
      if (!webhookPath) errors.push(`${relative}: webhook node has no path`);
      else if (webhookPaths.has(webhookPath)) errors.push(`${relative}: duplicate webhook path also used by ${webhookPaths.get(webhookPath)}`);
      else webhookPaths.set(webhookPath, relative);
    }

    if (node.type === 'n8n-nodes-base.httpRequest') {
      const method = String(node.parameters?.method ?? 'GET').toUpperCase();
      const timeout = Number(node.parameters?.options?.timeout ?? 0);
      if (!timeout) errors.push(`${relative}: HTTP node has no explicit timeout: ${node.name}`);
      if (method !== 'GET' && /agentmail\.to/.test(String(node.parameters?.url ?? ''))) {
        const headers = node.parameters?.headerParameters?.parameters ?? [];
        if (!headers.some((header) => String(header.name).toLowerCase() === 'idempotency-key')) {
          errors.push(`${relative}: AgentMail write has no idempotency key: ${node.name}`);
        }
      }
    }
  }

  for (const [source, outputs] of Object.entries(workflow.connections ?? {})) {
    if (!nodeNames.has(source)) errors.push(`${relative}: connection source does not exist: ${source}`);
    for (const groups of Object.values(outputs ?? {})) {
      for (const group of groups ?? []) {
        for (const edge of group ?? []) {
          if (!nodeNames.has(edge.node)) errors.push(`${relative}: connection target does not exist: ${edge.node}`);
        }
      }
    }
  }

  const triggerCount = nodes.filter((node) => /(?:webhook|manualTrigger|executeWorkflowTrigger)$/.test(node.type)).length;
  if (triggerCount === 0) warnings.push(`${relative}: no supported trigger found`);
}

const report = {
  status: errors.length === 0 ? 'PASS' : 'FAIL',
  workflows: files.length,
  nodes: nodeCount,
  webhook_paths: [...webhookPaths.keys()].sort(),
  errors,
  warnings,
};
console.log(JSON.stringify(report, null, 2));
if (errors.length) process.exit(1);
