BEGIN;

CREATE TYPE improvement_case_status AS ENUM (
  'DETECTED','EVIDENCE_REQUIRED','DESIGNING','READY_FOR_REVIEW','APPROVED',
  'REJECTED','SANDBOX','SHADOW','CANARY','PRODUCTION','ROLLED_BACK','CLOSED'
);

CREATE TYPE improvement_change_type AS ENUM (
  'KNOWLEDGE_REFRESH','CATEGORY_CHANGE','AGENT_CHANGE','WORKFLOW_CHANGE',
  'PROMPT_CHANGE','POLICY_CHANGE','TOOL_CHANGE','INTEGRATION_CHANGE',
  'DATABASE_CHANGE','UI_CHANGE','RETIREMENT'
);

CREATE TABLE improvement_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  correlation_id text NOT NULL,
  signal_type text NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  status improvement_case_status NOT NULL DEFAULT 'DETECTED',
  risk_level text NOT NULL DEFAULT 'MEDIUM',
  urgency text NOT NULL DEFAULT 'NORMAL',
  occurrence_count integer NOT NULL DEFAULT 1,
  affected_components jsonb NOT NULL DEFAULT '[]'::jsonb,
  evidence jsonb NOT NULL DEFAULT '[]'::jsonb,
  detected_by text NOT NULL,
  owner_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  UNIQUE (correlation_id)
);

CREATE INDEX improvement_cases_queue_idx
  ON improvement_cases (status, risk_level, created_at DESC);

CREATE TABLE system_change_proposals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  improvement_case_id uuid NOT NULL REFERENCES improvement_cases(id) ON DELETE CASCADE,
  change_type improvement_change_type NOT NULL,
  target_component text NOT NULL,
  current_version text,
  proposed_version text NOT NULL,
  design jsonb NOT NULL,
  expected_benefit jsonb NOT NULL DEFAULT '{}'::jsonb,
  risks jsonb NOT NULL DEFAULT '[]'::jsonb,
  cost_estimate jsonb NOT NULL DEFAULT '{}'::jsonb,
  required_permissions jsonb NOT NULL DEFAULT '[]'::jsonb,
  rollback_plan jsonb NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  proposed_by text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE system_change_tests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_id uuid NOT NULL REFERENCES system_change_proposals(id) ON DELETE CASCADE,
  stage text NOT NULL CHECK (stage IN ('STATIC','SANDBOX','REGRESSION','SECURITY','SHADOW','CANARY','ROLLBACK')),
  test_name text NOT NULL,
  input_fixture jsonb NOT NULL DEFAULT '{}'::jsonb,
  expected_result jsonb NOT NULL DEFAULT '{}'::jsonb,
  actual_result jsonb,
  status text NOT NULL DEFAULT 'PENDING',
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE system_change_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_id uuid NOT NULL REFERENCES system_change_proposals(id) ON DELETE CASCADE,
  proposal_hash text NOT NULL,
  decision text NOT NULL CHECK (decision IN ('APPROVED','REJECTED','CHANGES_REQUESTED')),
  reviewer_id text NOT NULL,
  reason text,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (proposal_id, proposal_hash, reviewer_id)
);

CREATE TABLE system_component_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  component_key text NOT NULL,
  version text NOT NULL,
  artifact_type text NOT NULL,
  artifact_reference text NOT NULL,
  artifact_hash text NOT NULL,
  environment text NOT NULL CHECK (environment IN ('DRAFT','SANDBOX','SHADOW','CANARY','PRODUCTION','RETIRED')),
  proposal_id uuid REFERENCES system_change_proposals(id) ON DELETE SET NULL,
  activated_by text,
  activated_at timestamptz,
  retired_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (component_key, version, environment)
);

CREATE TABLE system_evolution_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  improvement_case_id uuid REFERENCES improvement_cases(id) ON DELETE SET NULL,
  proposal_id uuid REFERENCES system_change_proposals(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  actor_id text NOT NULL,
  event_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX system_evolution_log_time_idx
  ON system_evolution_log (created_at DESC);

COMMIT;
