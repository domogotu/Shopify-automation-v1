#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const dir = path.join(root, 'workflows');
const bootstrap = fs.readFileSync(path.join(root, 'scripts', 'bootstrap-n8n.sh'), 'utf8');
const render = fs.readFileSync(path.join(root, 'render.yaml'), 'utf8');
const files = fs.readdirSync(dir).filter(name => /^\d{2}-architecture-.*-phase0\.json$/.test(name)).sort();
const requiredStatuses = ['OPERATIONAL','PLANNED','REQUIRES CREDENTIALS','REQUIRES HARDWARE','FUTURE RESEARCH'];
const errors = [];

if (files.length !== 11) errors.push(`Expected 11 Phase 0 workflows, found ${files.length}`);
if (!bootstrap.includes('SYNC_PHASE0_ARCHITECTURE_ONCE')) errors.push('Bootstrap is missing the dedicated Phase 0 import switch');
if (!bootstrap.includes('Expected 11 Phase 0 architecture workflows')) errors.push('Bootstrap does not verify the Phase 0 import count');
if (!/- key:\s*SYNC_PHASE0_ARCHITECTURE_ONCE\s*\n\s*value:\s*["']?false["']?/i.test(render)) errors.push('Phase 0 import switch must default to false');
for (const file of files) {
  const workflow = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8'));
  const nodes = workflow.nodes ?? [];
  const manifest = nodes.find(node => node.name === 'Architecture Manifest');
  if (!manifest) errors.push(`${file}: missing Architecture Manifest`);
  if (!nodes.some(node => node.name === 'Architecture Safety Notice')) errors.push(`${file}: missing safety notice`);
  for (const node of nodes.filter(node => /^\[/.test(node.name))) {
    const status = requiredStatuses.find(candidate => node.name.startsWith(`[${candidate}]`));
    if (!status) errors.push(`${file}: invalid or missing status on ${node.name}`);
    if (node.type !== 'n8n-nodes-base.noOp') errors.push(`${file}: architecture component is executable: ${node.name}`);
  }
  const raw = JSON.stringify(workflow);
  for (const forbidden of ['credentials','httpRequest','postgres','executeWorkflow']) {
    if (raw.includes(`n8n-nodes-base.${forbidden}`) || (forbidden === 'credentials' && raw.includes('"credentials"'))) {
      errors.push(`${file}: unsafe Phase 0 integration field detected: ${forbidden}`);
    }
  }
}

const master = files.find(file => file.startsWith('00-architecture-'));
if (master) {
  const workflow = JSON.parse(fs.readFileSync(path.join(dir, master), 'utf8'));
  const departmentNodes = (workflow.nodes ?? []).filter(node => /^\[PLANNED\] \d{2} —/.test(node.name));
  if (departmentNodes.length !== 10) errors.push(`Master control plane must show 10 departments, found ${departmentNodes.length}`);
}

console.log(JSON.stringify({ status: errors.length ? 'FAIL' : 'PASS', workflows: files.length, errors }, null, 2));
if (errors.length) process.exit(1);
