CREATE TABLE decision_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  conversation_id uuid REFERENCES conversations(id) ON DELETE SET NULL,
  correlation_id text NOT NULL,
  actor_id text NOT NULL,
  request_text text NOT NULL,
  request_type text,
  status text NOT NULL DEFAULT 'ANALYZING',
  risk_level text NOT NULL DEFAULT 'UNKNOWN',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  UNIQUE (store_id, correlation_id)
);

CREATE TABLE executive_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  decision_case_id uuid NOT NULL REFERENCES decision_cases(id) ON DELETE CASCADE,
  plan_version text NOT NULL,
  selected_agents jsonb NOT NULL DEFAULT '[]'::jsonb,
  questions_to_answer jsonb NOT NULL DEFAULT '[]'::jsonb,
  required_memory_scopes jsonb NOT NULL DEFAULT '[]'::jsonb,
  required_tools jsonb NOT NULL DEFAULT '[]'::jsonb,
  known_facts jsonb NOT NULL DEFAULT '[]'::jsonb,
  assumptions jsonb NOT NULL DEFAULT '[]'::jsonb,
  missing_information jsonb NOT NULL DEFAULT '[]'::jsonb,
  candidate_actions jsonb NOT NULL DEFAULT '[]'::jsonb,
  requires_human_approval boolean NOT NULL DEFAULT false,
  model_name text NOT NULL,
  response_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE specialist_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  decision_case_id uuid NOT NULL REFERENCES decision_cases(id) ON DELETE CASCADE,
  agent_key text NOT NULL,
  status text NOT NULL,
  facts jsonb NOT NULL DEFAULT '[]'::jsonb,
  findings jsonb NOT NULL DEFAULT '[]'::jsonb,
  options jsonb NOT NULL DEFAULT '[]'::jsonb,
  risks jsonb NOT NULL DEFAULT '[]'::jsonb,
  source_refs jsonb NOT NULL DEFAULT '[]'::jsonb,
  missing_information jsonb NOT NULL DEFAULT '[]'::jsonb,
  recommendation jsonb NOT NULL DEFAULT '{}'::jsonb,
  provider text,
  model_name text,
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE supervisor_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  decision_case_id uuid NOT NULL REFERENCES decision_cases(id) ON DELETE CASCADE,
  review_version text NOT NULL,
  evidence_quality text NOT NULL,
  confidence numeric(5,4) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  selected_option text,
  rationale text NOT NULL,
  rejected_options jsonb NOT NULL DEFAULT '[]'::jsonb,
  unresolved_conflicts jsonb NOT NULL DEFAULT '[]'::jsonb,
  missing_information jsonb NOT NULL DEFAULT '[]'::jsonb,
  policy_checks jsonb NOT NULL DEFAULT '[]'::jsonb,
  requires_human_approval boolean NOT NULL,
  safe_to_execute boolean NOT NULL DEFAULT false,
  recommended_next_step text NOT NULL,
  model_name text NOT NULL,
  response_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE decision_outcomes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  decision_case_id uuid NOT NULL REFERENCES decision_cases(id) ON DELETE CASCADE,
  approval_id uuid REFERENCES approvals(id) ON DELETE SET NULL,
  final_status text NOT NULL,
  action_payload_hash text,
  external_result_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  verification_result jsonb NOT NULL DEFAULT '{}'::jsonb,
  expected_effect jsonb NOT NULL DEFAULT '{}'::jsonb,
  actual_effect jsonb NOT NULL DEFAULT '{}'::jsonb,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX decision_cases_status_idx ON decision_cases (store_id, status, created_at DESC);
CREATE INDEX specialist_reports_case_idx ON specialist_reports (decision_case_id, agent_key);
CREATE INDEX supervisor_reviews_case_idx ON supervisor_reviews (decision_case_id, created_at DESC);
