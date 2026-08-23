#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const workflowsDir = path.join(root, 'workflows');

const allowedStatuses = new Set([
  'OPERATIONAL',
  'PLANNED',
  'REQUIRES CREDENTIALS',
  'REQUIRES HARDWARE',
  'FUTURE RESEARCH',
]);

const departments = [
  {
    number: '00', slug: 'reeds-master-control-plane', title: 'Reeds Master Control Plane',
    purpose: 'Visible owner-governed executive chain and departmental control-plane map.',
    components: [
      ['PLANNED', 'Universal Event Intake', 'universal_event', 'normalized_event', 'identity and schema validation', 'event contract validation'],
      ['PLANNED', 'Identity and Context', 'normalized_event', 'authorized_context', 'Dominique root authority and scoped permissions', 'authority decision record'],
      ['OPERATIONAL', 'Scoped Memory Retrieval', 'authorized_context', 'cited_memory_context', 'store and sensitivity scopes', '00E workflow receipt'],
      ['PLANNED', 'Goal and Mission Planner', 'request_and_memory', 'mission_plan', 'budget, deadline and dependency boundaries', 'plan schema validation'],
      ['PLANNED', 'Model and Agent Router', 'mission_plan', 'specialist_assignments', 'model and agent allowlists', 'routing evidence'],
      ['PLANNED', 'Specialist Work', 'specialist_assignments', 'cited_reports', 'tool registry and least privilege', 'source and result assertions'],
      ['OPERATIONAL', 'Executive Supervisor', 'cited_reports', 'supervisor_review', 'independent review', 'structured OpenAI response'],
      ['OPERATIONAL', 'Deterministic Policy Gate', 'supervisor_review', 'authorization_decision', 'non-AI mandatory policy', 'deterministic status'],
      ['PLANNED', 'Human Approval When Required', 'authorization_decision', 'approval_receipt', 'Dominique retains final authority', 'signed approval binding'],
      ['PLANNED', 'Tool and Action Execution', 'approved_action', 'tool_result', 'kill switch, budget and credential scope', 'content assertion'],
      ['PLANNED', 'Result Verification', 'tool_result', 'verified_outcome', 'intended-versus-actual comparison', 'verification evidence'],
      ['OPERATIONAL', 'Governed Memory Write', 'verified_or_proposed_record', 'memory_receipt', 'redaction and governance', '00D workflow receipt'],
    ],
    departments: ['Identity and Authority','Memory and Knowledge','Goals and Planning','Agents and Models','Tools and Actions','Digital Life','Business Domains','Physical Systems','Learning and Improvement','Security and Continuity'],
  },
  {
    number: '01', slug: 'identity-and-authority', title: 'Identity and Authority',
    purpose: 'Resolve people, organizations, roles, permissions, budgets and owner authority before privileged work.',
    components: [
      ['PLANNED','Dominique Root Authority','identity_claim','root_authority_context','sole-owner authority cannot be delegated implicitly','root authority audit record'],
      ['PLANNED','Universal Identity Resolver','actor_claim','resolved_identity','source attribution and proof strength','identity resolution evidence'],
      ['PLANNED','Organizations and Projects','resolved_identity','ownership_context','organization and project isolation','membership lookup'],
      ['PLANNED','People and Relationships','identity_context','relationship_context','purpose-limited relationship access','relationship provenance'],
      ['PLANNED','Roles and Permissions','ownership_context','permission_decision','deny by default and least privilege','policy evaluation'],
      ['PLANNED','Boundaries and Consent','permission_decision','bounded_authorization','privacy and context boundaries','consent receipt'],
      ['PLANNED','Budgets and Spending','bounded_authorization','budget_decision','hard spending ceilings','ledger and approval check'],
      ['PLANNED','Approval Policies','bounded_authorization','approval_requirement','owner-defined mandatory gates','policy version binding'],
      ['PLANNED','Emergency Override','root_authority_context','time_limited_override','Dominique-only emergency authority','immutable override audit'],
      ['OPERATIONAL','Kill Switch Check','action_request','allow_or_block','SYSTEM_KILL_SWITCH defaults to true','environment safety assertion'],
    ],
  },
  {
    number: '02', slug: 'memory-and-knowledge', title: 'Memory and Knowledge',
    purpose: 'Store, retrieve, cite, expire, promote and supersede governed temporal knowledge.',
    components: [
      ['OPERATIONAL','Conversation Memory','scoped_query','recent_messages','store and session isolation','cited retrieval rows'],
      ['OPERATIONAL','Governed Memory Items','memory_candidate','memory_receipt','redaction, provenance and sensitivity','write counts and identifiers'],
      ['PLANNED','Working Memory','active_mission_context','short_lived_context','mission and expiration scope','expiry assertion'],
      ['PLANNED','Episodic Memory','verified_event','episodic_record','identity and temporal provenance','event/source citation'],
      ['PLANNED','Semantic Memory','verified_fact','semantic_record','confidence and supersession','fact validation'],
      ['PLANNED','Procedural Memory','approved_procedure','procedure_record','version and authority binding','procedure test'],
      ['PLANNED','Preference and Decision Memory','approved_preference_or_decision','governed_record','owner scope and reversibility','approval provenance'],
      ['PLANNED','Error and Performance Memory','verified_outcome','learning_record','no silent self-modification','outcome evidence'],
      ['PLANNED','People and Resource Graph','verified_relationships','knowledge_graph_edges','relationship-level access','graph integrity check'],
      ['PLANNED','Memory Promotion','proposed_memory','verified_or_rejected_memory','human or policy approval','promotion audit record'],
      ['PLANNED','Expiration and Supersession','memory_record','current_temporal_state','retention and legal holds','temporal consistency check'],
    ],
  },
  {
    number: '03', slug: 'goals-and-planning', title: 'Goals and Planning',
    purpose: 'Turn owner-authorized goals into bounded plans, tasks, simulations and recovery paths.',
    components: [
      ['PLANNED','Goal Registry','authorized_goal','goal_record','owner, organization and purpose scopes','goal contract validation'],
      ['PLANNED','Mission Planner','goal_record','mission_plan','policy, budget and deadline constraints','plan schema and evidence'],
      ['PLANNED','Task Decomposition','mission_plan','task_graph','bounded task size and permissions','dependency cycle check'],
      ['PLANNED','Dependencies and Deadlines','task_graph','scheduled_plan','calendar and resource constraints','critical-path validation'],
      ['PLANNED','Budget Constraints','scheduled_plan','cost_bounded_plan','approved budget envelope','cost forecast check'],
      ['PLANNED','Alternative Simulator','cost_bounded_plan','scenario_comparison','no external writes','scenario evidence'],
      ['PLANNED','Risk Forecaster','scenario_comparison','risk_register','owner risk policy','risk coverage check'],
      ['FUTURE RESEARCH','Digital Twin','verified_system_state','simulated_outcome','isolated simulation only','model calibration evidence'],
      ['PLANNED','Completion Evidence','task_results','completion_decision','evidence required before completion','result assertions'],
      ['PLANNED','Recovery Planner','failed_or_partial_result','recovery_plan','rollback and human escalation','recoverability test'],
    ],
  },
  {
    number: '04', slug: 'agents-and-models', title: 'Agents and Models',
    purpose: 'Route work across approved models and specialist agents with independent executive supervision.',
    components: [
      ['PLANNED','Model Router','model_request','model_assignment','provider allowlist, cost and sensitivity','routing receipt'],
      ['REQUIRES CREDENTIALS','OpenAI Executive','structured_request','structured_plan','approved model and budget','response schema validation'],
      ['REQUIRES CREDENTIALS','Claude Specialists','specialist_request','specialist_report','approved model and data scope','citation validation'],
      ['FUTURE RESEARCH','Local Private Models','private_model_request','local_result','offline and local-only boundary','local inference attestation'],
      ['REQUIRES CREDENTIALS','Vision Models','image_or_video_request','vision_report','consent and biometric restrictions','source and confidence check'],
      ['REQUIRES CREDENTIALS','Speech Models','audio_request','transcript_or_audio','consent and retention rules','transcription confidence'],
      ['PLANNED','Specialist Agent Society','mission_assignments','cited_specialist_reports','tool registry and least privilege','agent contract validation'],
      ['OPERATIONAL','Executive Supervisor','plans_and_reports','supervisor_review','independent reasoning stage','structured review schema'],
      ['PLANNED','Security and Legal Reviewers','high_risk_plan','review_findings','mandatory escalation boundaries','review completion evidence'],
      ['PLANNED','Memory Curator and Critic','candidate_knowledge','curation_decision','no autonomous promotion','provenance and approval check'],
    ],
  },
  {
    number: '05', slug: 'tools-and-actions', title: 'Tools and Actions',
    purpose: 'Register, authorize, execute and verify external tools without granting models unrestricted action.',
    components: [
      ['PLANNED','Tool Registry','tool_definition','registered_tool','owner approval and schema requirements','registry validation'],
      ['PLANNED','Capability and Credential Scope','tool_request','scoped_capability','least privilege and secret isolation','scope assertion'],
      ['PLANNED','Action Authorization','scoped_capability','allow_block_or_approve','policy, budget and risk gates','authorization receipt'],
      ['PLANNED','Idempotency Controller','authorized_action','idempotent_action','duplicate-write prevention','idempotency lookup'],
      ['PLANNED','Sandbox Execution','safe_action','tool_result','isolated non-production environment','sandbox evidence'],
      ['PLANNED','Production Execution','approved_action','tool_result','human approval and production gate','external result receipt'],
      ['OPERATIONAL','Tool Result Assertion','tool_result','safe_result_or_escalation','content not HTTP status','00K assertion record'],
      ['PLANNED','Rollback and Compensation','failed_action','recovery_result','declared recovery procedure','post-recovery verification'],
      ['OPERATIONAL','Audit Record','decision_or_action','audit_evidence','correlation and source attribution','database audit identifier'],
    ],
  },
  {
    number: '06', slug: 'digital-life', title: 'Digital Life',
    purpose: 'Represent personal digital systems as permissioned adapters behind the universal event gateway.',
    components: [
      ['REQUIRES HARDWARE','Phone and Reeds Mobile','mobile_event','normalized_event','device permission and owner identity','device attestation'],
      ['REQUIRES CREDENTIALS','Contacts and People Graph','contact_event','governed_relationship','purpose and consent boundaries','source attribution'],
      ['REQUIRES CREDENTIALS','Email and Accounts','email_event','normalized_message','account scope and send approval','provider receipt'],
      ['REQUIRES HARDWARE','Calls Voicemail and SMS','telephony_event','transcript_or_message','consent and jurisdiction rules','carrier receipt'],
      ['REQUIRES CREDENTIALS','Calendar and Reminders','calendar_event','scheduled_record','calendar ownership and conflict rules','calendar receipt'],
      ['REQUIRES CREDENTIALS','Files Documents and OCR','document_event','cited_document_context','classification and malware scanning','hash and OCR evidence'],
      ['REQUIRES CREDENTIALS','Photos Music and Media','media_event','media_context','copyright, privacy and storage boundaries','asset provenance'],
      ['REQUIRES CREDENTIALS','Browser and Universal Search','search_request','cited_search_result','domain and action restrictions','source citation'],
      ['REQUIRES HARDWARE','Location Maps and Travel','location_event','location_context','explicit consent and retention','location source evidence'],
      ['REQUIRES CREDENTIALS','Banking and Finance','financial_event','financial_context','read-only first and spending approval','ledger reconciliation'],
      ['REQUIRES CREDENTIALS','Health and Fitness','health_event','health_context','sensitive-data isolation and consent','source and freshness check'],
      ['PLANNED','Personal Timeline','verified_events','temporal_summary','scope and retention policies','timeline provenance'],
    ],
  },
  {
    number: '07', slug: 'business-domains', title: 'Business Domains',
    purpose: 'Connect business platforms through governed adapters rather than embedding domain logic in the intelligence core.',
    components: [
      ['REQUIRES CREDENTIALS','Shopify Adapter','shopify_event_or_query','normalized_commerce_result','read-only first; writes require approval','Shopify response assertion'],
      ['REQUIRES CREDENTIALS','CJdropshipping Adapter','supplier_request','normalized_supplier_result','orders and spending require approval','supplier response assertion'],
      ['PLANNED','Reeds Solutions LLC Adapter','business_event','business_context','organization permissions','source and audit record'],
      ['PLANNED','PrimeContractorOS Adapter','contracting_event','contracting_context','workspace isolation and CUI refusal','workspace and source validation'],
      ['PLANNED','CRM and Contacts','business_relationship_event','crm_record','role-based access','CRM receipt'],
      ['REQUIRES CREDENTIALS','AgentMail Adapter','email_event','thread_or_message_result','approved sends only','message and thread IDs'],
      ['REQUIRES CREDENTIALS','GitHub Adapter','repository_event','versioned_change_result','branch and review policy','commit or pull-request evidence'],
      ['REQUIRES CREDENTIALS','Render Adapter','deployment_event','deployment_status','production deployment approval','deployment ID and logs'],
      ['OPERATIONAL','PostgreSQL Backbone','database_request','governed_data_result','schema and row-level scopes','transaction result'],
      ['REQUIRES CREDENTIALS','Google Drive and Sheets','document_or_sheet_event','normalized_file_result','file ownership and sharing boundaries','file/version identifier'],
      ['PLANNED','Accounting and Analytics','business_result','financial_or_performance_record','financial permissions','reconciliation and source checks'],
      ['REQUIRES CREDENTIALS','Government Portals','contracting_request','portal_result','no unsupported automated submissions','portal confirmation'],
    ],
  },
  {
    number: '08', slug: 'physical-systems', title: 'Physical Systems',
    purpose: 'Reserve governed interfaces for future hardware and physical actions behind mandatory safety gates.',
    components: [
      ['REQUIRES HARDWARE','Reeds Hub and Edge','signed_device_event','edge_context','device identity and local boundary','hardware attestation'],
      ['REQUIRES HARDWARE','Reeds Mesh and Ear','sensor_or_audio_event','normalized_perception','consent and physical safety','device and sensor evidence'],
      ['REQUIRES HARDWARE','Reeds Vision Lens and Watch','vision_or_wearable_event','normalized_context','privacy and biometric restrictions','device provenance'],
      ['FUTURE RESEARCH','AR and Robotics Platform','approved_physical_mission','physical_action_result','human presence and emergency stop','physical result telemetry'],
      ['REQUIRES HARDWARE','Smart Home Adapter','home_event','home_action_result','resident consent and safety gate','device state verification'],
      ['REQUIRES HARDWARE','Vehicle Adapter','vehicle_event','vehicle_context','no autonomous control without certified system','vehicle telemetry'],
      ['REQUIRES HARDWARE','Laboratory Equipment','lab_request','lab_result','operator authorization and equipment interlock','instrument evidence'],
      ['FUTURE RESEARCH','Drones and Robotics','approved_mission','mission_telemetry','law, airspace and physical-action gates','telemetry and recovery check'],
      ['PLANNED','Physical Action Gate','physical_action_request','allow_block_or_approve','mandatory human approval and kill switch','signed approval and sensor check'],
    ],
  },
  {
    number: '09', slug: 'learning-and-improvement', title: 'Learning and Improvement',
    purpose: 'Compare intended and actual results, capture corrections, and propose controlled improvements without direct self-modification.',
    components: [
      ['PLANNED','Evidence Collector','execution_result','evidence_package','source integrity and correlation','evidence completeness check'],
      ['PLANNED','Result Validator','evidence_package','validated_result','content assertions and policy','expected-versus-actual comparison'],
      ['PLANNED','Outcome Comparator','validated_result','outcome_gap','declared success criteria','gap calculation'],
      ['PLANNED','Cost Time and Quality','validated_result','performance_record','budget and service-level definitions','metric reconciliation'],
      ['PLANNED','Feedback Intake','feedback_event','feedback_record','identity and source attribution','feedback receipt'],
      ['PLANNED','Correction Manager','verified_error','correction_case','owner authority and no silent edits','correction approval'],
      ['PLANNED','Memory Promotion','learning_candidate','promotion_decision','human or policy approval','promotion audit'],
      ['OPERATIONAL','Improvement Case Intake','failure_or_feedback','governed_improvement_case','no production mutation','00J case identifier'],
      ['FUTURE RESEARCH','Capability Gap Detector','verified_history','capability_proposal','research only; no self-installation','gap evidence'],
      ['PLANNED','Controlled Release Pipeline','approved_change','versioned_release','security review, tests and rollback','release evidence'],
    ],
  },
  {
    number: '10', slug: 'security-and-continuity', title: 'Security and Continuity',
    purpose: 'Apply mandatory privacy, credential, audit, release, continuity and emergency controls across every domain.',
    components: [
      ['PLANNED','Human Approval Gate','privileged_action','signed_decision','Dominique or delegated policy authority','payload-bound approval'],
      ['PLANNED','Spending Gate','financial_action','budget_decision','hard budget and vendor limits','ledger and approval evidence'],
      ['PLANNED','External Message Gate','outbound_message','send_decision','recipient and content approval','provider receipt'],
      ['PLANNED','Production Change Gate','release_candidate','release_decision','tests, review and rollback','versioned release record'],
      ['PLANNED','Privacy and Data Gate','data_operation','privacy_decision','classification, purpose and retention','privacy policy evaluation'],
      ['PLANNED','Physical Action Gate','physical_action','physical_decision','human approval and emergency stop','signed authorization'],
      ['PLANNED','Security and Rate Limits','request','throttled_authorization','abuse, anomaly and quota controls','rate-limit record'],
      ['PLANNED','Credential Scope','tool_request','credential_capability','secret isolation and least privilege','credential scope assertion'],
      ['OPERATIONAL','Audit Requirement','decision_or_action','immutable_audit_record','correlation and provenance','audit identifier'],
      ['OPERATIONAL','Kill Switch','action_request','allow_or_block','fail closed by default','environment assertion'],
      ['PLANNED','Backups and Replication','governed_data','recovery_copy','encryption and retention','restore test'],
      ['PLANNED','Health and Observability','system_telemetry','health_status','sensitive-data redaction','metric and log checks'],
      ['FUTURE RESEARCH','Failover and Offline Mode','availability_event','continuity_state','safe degraded operation','failover exercise'],
    ],
  },
];

function idFor(departmentIndex, nodeIndex) {
  return `a${String(departmentIndex).padStart(7, '0')}-0000-4000-8000-${String(nodeIndex).padStart(12, '0')}`;
}

function settings() {
  return {
    executionOrder: 'v1', saveManualExecutions: true, saveExecutionProgress: true,
    saveDataErrorExecution: 'all', saveDataSuccessExecution: 'all', timezone: 'America/Los_Angeles',
  };
}

function note(title, purpose, departmentIndex) {
  return {
    parameters: {
      content: `## ${title}\n\n${purpose}\n\n**PHASE 0 ARCHITECTURE MAP** — This workflow documents contracts and status. Architecture nodes are inert and do not call APIs, access credentials, spend funds, send messages, change production, or control hardware.`,
      height: 260, width: 620, color: 5,
    },
    id: idFor(departmentIndex, 1), name: 'Architecture Safety Notice',
    type: 'n8n-nodes-base.stickyNote', typeVersion: 1, position: [-420, -500],
  };
}

function manifestCode(department) {
  const manifest = department.components.map(([status,name,input,output,permissions,verification]) => ({
    status, name, expected_input: input, expected_output: output,
    permissions_and_boundaries: permissions, approval_requirement: /approval|spend|write|send|physical|production/i.test(`${name} ${permissions}`) ? 'POLICY_OR_HUMAN_APPROVAL_REQUIRED' : 'DEFINED_BY_POLICY',
    risk_classification: /physical|credential|spend|production|security|root/i.test(`${name} ${permissions}`) ? 'HIGH' : 'MEDIUM',
    verification_method: verification,
  }));
  return `return [{json:${JSON.stringify({
    status: 'ARCHITECTURE_VISIBLE', phase: 'PHASE_0', workflow: `${department.number} — ${department.title}`,
    purpose: department.purpose, operational_execution: false,
    notice: 'Architecture map only. Inert component nodes do not claim live capability.', components: manifest,
  })}}];`;
}

function makeDepartment(department, departmentIndex) {
  for (const component of department.components) {
    if (!allowedStatuses.has(component[0])) throw new Error(`Invalid status ${component[0]} in ${department.title}`);
  }
  const nodes = [note(`${department.number} — ${department.title}`, department.purpose, departmentIndex)];
  nodes.push({
    parameters: {}, id: idFor(departmentIndex, 2), name: 'Inspect Architecture',
    type: 'n8n-nodes-base.manualTrigger', typeVersion: 1, position: [-360, 0],
  });
  nodes.push({
    parameters: { jsCode: manifestCode(department) }, id: idFor(departmentIndex, 3), name: 'Architecture Manifest',
    type: 'n8n-nodes-base.code', typeVersion: 2, position: [-100, 0],
  });
  department.components.forEach(([status, name], index) => {
    const column = index % 4;
    const row = Math.floor(index / 4);
    nodes.push({
      parameters: {}, id: idFor(departmentIndex, index + 10), name: `[${status}] ${name}`,
      type: 'n8n-nodes-base.noOp', typeVersion: 1, position: [220 + column * 300, -180 + row * 220],
    });
  });
  if (department.departments) {
    department.departments.forEach((name, index) => {
      nodes.push({
        parameters: {}, id: idFor(departmentIndex, index + 100), name: `[PLANNED] ${String(index + 1).padStart(2, '0')} — ${name}`,
        type: 'n8n-nodes-base.noOp', typeVersion: 1, position: [220 + (index % 5) * 300, 620 + Math.floor(index / 5) * 180],
      });
    });
  }
  const connections = {
    'Inspect Architecture': { main: [[{ node: 'Architecture Manifest', type: 'main', index: 0 }]] },
  };
  const componentNames = department.components.map(([status,name]) => `[${status}] ${name}`);
  connections['Architecture Manifest'] = { main: [[{ node: componentNames[0], type: 'main', index: 0 }]] };
  componentNames.forEach((name, index) => {
    if (index < componentNames.length - 1) connections[name] = { main: [[{ node: componentNames[index + 1], type: 'main', index: 0 }]] };
  });
  if (department.departments) {
    const departmentNodes = department.departments.map((name,index) => `[PLANNED] ${String(index + 1).padStart(2, '0')} — ${name}`);
    connections['Architecture Manifest'].main[0].push(...departmentNodes.map(node => ({ node, type: 'main', index: 0 })));
  }
  return {
    name: `${department.number} — ${department.title} [PHASE 0]`, nodes, connections,
    pinData: {}, settings: settings(), staticData: null, triggerCount: 0,
    versionId: idFor(departmentIndex, 999),
  };
}

for (const [index, department] of departments.entries()) {
  const filename = `${department.number}-architecture-${department.slug}-phase0.json`;
  fs.writeFileSync(path.join(workflowsDir, filename), `${JSON.stringify(makeDepartment(department, index + 1), null, 2)}\n`);
}

console.log(`Generated ${departments.length} Phase 0 architecture workflows.`);
