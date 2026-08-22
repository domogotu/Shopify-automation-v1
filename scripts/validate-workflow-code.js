const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const workflowDir = path.join(root, "workflows");
const files = fs.readdirSync(workflowDir).filter((name) => name.endsWith(".json")).sort();
let codeNodeCount = 0;

for (const filename of files) {
  const workflow = JSON.parse(fs.readFileSync(path.join(workflowDir, filename), "utf8"));
  if (!workflow.name || !Array.isArray(workflow.nodes) || !workflow.connections) {
    throw new Error(`${filename}: missing workflow name, nodes, or connections`);
  }
  const nodeNames = new Set(workflow.nodes.map((node) => node.name));
  for (const node of workflow.nodes) {
    if (node.type === "n8n-nodes-base.code") {
      new Function(node.parameters.jsCode);
      codeNodeCount += 1;
    }
  }
  for (const [source, groups] of Object.entries(workflow.connections)) {
    if (!nodeNames.has(source)) throw new Error(`${filename}: missing connection source ${source}`);
    for (const group of groups.main || []) {
      for (const connection of group || []) {
        if (!nodeNames.has(connection.node)) throw new Error(`${filename}: missing connection target ${connection.node}`);
      }
    }
  }
}

console.log(`Validated ${files.length} workflows and ${codeNodeCount} Code nodes`);
