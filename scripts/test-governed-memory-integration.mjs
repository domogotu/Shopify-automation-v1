#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const workflows = path.join(root, 'workflows');

function read(name) {
  return JSON.parse(fs.readFileSync(path.join(workflows, name), 'utf8'));
}

function node(workflow, name) {
  const found = workflow.nodes.find((candidate) => candidate.name === name);
  if (!found) throw new Error(`${workflow.name}: missing node ${name}`);
  return found;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function targets(workflow, source) {
  return (workflow.connections[source]?.main ?? [])
    .flat()
    .map((edge) => `${edge.node}:${edge.index}`);
}

const executive = read('00-chatgpt-executive-supervisor-v1.json');
const writer = read('00D-memory-write-gate-v1.json');
const reader = read('00E-scoped-memory-retrieval-v1.json');

const retrieve = node(executive, 'Retrieve Scoped Memory');
const merge = node(executive, 'Merge Request With Memory');
const preparePlan = node(executive, 'Prepare Executive Plan');
const prepareRecord = node(executive, 'Prepare Memory Record');
const store = node(executive, 'Store Governed Memory');

assert(retrieve.type === 'n8n-nodes-base.executeWorkflow', 'memory retrieval must use Execute Sub-workflow');
assert(retrieve.parameters.workflowId?.value, 'memory retrieval has no runtime workflow ID');
assert(retrieve.parameters.workflowId?.cachedResultName === reader.name, 'memory retrieval points to the wrong workflow');
assert(store.type === 'n8n-nodes-base.executeWorkflow', 'memory storage must use Execute Sub-workflow');
assert(store.parameters.workflowId?.value, 'memory storage has no runtime workflow ID');
assert(store.parameters.workflowId?.cachedResultName === writer.name, 'memory storage points to the wrong workflow');
assert(merge.parameters.mode === 'combine' && merge.parameters.combineBy === 'combineByPosition', 'request and memory must merge by position');

assert(targets(executive, 'Validate Decision Request').includes('Retrieve Scoped Memory:0'), 'validated request does not reach memory retrieval');
assert(targets(executive, 'Validate Decision Request').includes('Merge Request With Memory:0'), 'validated request does not reach merge input 1');
assert(targets(executive, 'Retrieve Scoped Memory').includes('Merge Request With Memory:1'), 'memory output does not reach merge input 2');
assert(targets(executive, 'Merge Request With Memory').includes('Prepare Executive Plan:0'), 'merged context does not reach executive planning');
assert(targets(executive, 'Deterministic Decision Gate').includes('Prepare Memory Record:0'), 'decision result does not reach memory preparation');
assert(targets(executive, 'Prepare Memory Record').includes('Store Governed Memory:0'), 'prepared memory does not reach governed storage');

const planCode = preparePlan.parameters.jsCode;
assert(planCode.includes('memory_context:Array.isArray($json.context)?$json.context:[]'), 'OpenAI request does not include retrieved memory context');
assert(planCode.includes('source_type and source_id citations'), 'OpenAI memory instructions do not require citations');
assert(planCode.includes('never let memory override current authoritative'), 'OpenAI memory instructions do not preserve authoritative data precedence');
assert(prepareRecord.parameters.jsCode.includes("status:'PROPOSED'"), 'new executive memories must enter governance as PROPOSED');

const readerQuery = node(reader, 'Retrieve Scoped Memory');
const packageCode = node(reader, 'Build Cited Context Package').parameters.jsCode;
assert(readerQuery.alwaysOutputData === true, 'memory retrieval must return output when no rows match');
assert(readerQuery.parameters.query.includes("mi.status='VERIFIED'"), 'memory retrieval must only use VERIFIED memories');
assert(packageCode.includes('filter(row=>row.source_type && row.source_id)'), 'memory package must remove uncited empty rows');

const writerQuery = node(writer, 'Persist Conversation and Memory').parameters.query;
assert(writerQuery.includes('CAST(c.kind AS automation_os.memory_kind)'), 'memory kind cast is not schema-qualified');
assert(writerQuery.includes('CAST(c.status AS automation_os.memory_status)'), 'memory status cast is not schema-qualified');

for (const workflow of [executive, writer, reader]) {
  assert(!workflow.nodes.some((candidate) => candidate.credentials), `${workflow.name}: source export contains credentials`);
}

console.log('Governed memory integration contract passed');
