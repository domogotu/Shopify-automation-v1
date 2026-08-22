#!/usr/bin/env node
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const sourceDir = path.join(root, 'workflows');
const currentArg = process.argv.find((arg) => arg.startsWith('--current='));
const currentDir = currentArg ? path.resolve(currentArg.slice('--current='.length)) : null;

function readWorkflowFile(file) {
  const parsed = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (Array.isArray(parsed)) {
    if (parsed.length !== 1) throw new Error(`Expected one workflow in ${file}`);
    return parsed[0];
  }
  return parsed;
}

function canonical(workflow) {
  const copy = structuredClone(workflow);
  for (const field of [
    'active', 'createdAt', 'updatedAt', 'versionId', 'versionCounter',
    'triggerCount', 'shared', 'tags', 'tagIds', 'meta',
  ]) delete copy[field];
  for (const node of copy.nodes ?? []) delete node.credentials;
  return stable(copy);
}

function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, stable(value[key])]));
  }
  return value;
}

function digest(value) {
  return crypto.createHash('sha256').update(JSON.stringify(value)).digest('hex');
}

function loadDirectory(directory) {
  const byName = new Map();
  if (!directory) return byName;
  for (const filename of fs.readdirSync(directory).filter((name) => name.endsWith('.json')).sort()) {
    const workflow = readWorkflowFile(path.join(directory, filename));
    if (!workflow.name) throw new Error(`Workflow has no name: ${filename}`);
    if (byName.has(workflow.name)) throw new Error(`Duplicate workflow name: ${workflow.name}`);
    byName.set(workflow.name, { filename, workflow, hash: digest(canonical(workflow)) });
  }
  return byName;
}

const source = loadDirectory(sourceDir);
const current = loadDirectory(currentDir);
const report = {
  mode: currentDir ? 'COMPARE' : 'SOURCE_MANIFEST',
  generated_at: new Date().toISOString(),
  source_directory: sourceDir,
  current_directory: currentDir,
  source_count: source.size,
  current_count: current.size,
  unchanged: [],
  changed: [],
  missing_from_n8n: [],
  extra_in_n8n: [],
  source_manifest: [],
};

for (const [name, entry] of source) {
  report.source_manifest.push({ name, filename: entry.filename, structural_sha256: entry.hash });
  if (!currentDir) continue;
  const existing = current.get(name);
  if (!existing) report.missing_from_n8n.push(name);
  else if (existing.hash === entry.hash) report.unchanged.push(name);
  else report.changed.push(name);
}
if (currentDir) {
  for (const name of current.keys()) if (!source.has(name)) report.extra_in_n8n.push(name);
}

report.release_required = report.changed.length > 0 || report.missing_from_n8n.length > 0;
report.safe_to_apply_automatically = false;
console.log(JSON.stringify(report, null, 2));
