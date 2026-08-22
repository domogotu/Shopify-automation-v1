CREATE TABLE feedback_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  conversation_id uuid REFERENCES conversations(id) ON DELETE SET NULL,
  message_id uuid REFERENCES conversation_messages(id) ON DELETE SET NULL,
  correlation_id text NOT NULL,
  actor_id text NOT NULL,
  rating text NOT NULL CHECK (rating IN ('HELPFUL','PARTLY_HELPFUL','NOT_HELPFUL','INCORRECT','UNSAFE')),
  feedback_text text,
  status text NOT NULL DEFAULT 'RECEIVED',
  assigned_agent_key text NOT NULL DEFAULT 'approval_compliance',
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by text,
  resolution jsonb NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (store_id, correlation_id)
);

CREATE TABLE memory_corrections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  feedback_case_id uuid NOT NULL REFERENCES feedback_cases(id) ON DELETE CASCADE,
  memory_id uuid REFERENCES memory_items(id) ON DELETE SET NULL,
  correction_type text NOT NULL CHECK (correction_type IN ('CORRECT','SUPERSEDE','REDACT','FORGET','NO_CHANGE')),
  proposed_content jsonb NOT NULL DEFAULT '{}'::jsonb,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'PROPOSED',
  approved_by text,
  approved_at timestamptz,
  applied_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE answer_quality_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  feedback_case_id uuid NOT NULL REFERENCES feedback_cases(id) ON DELETE CASCADE,
  executive_plan_id uuid REFERENCES executive_plans(id) ON DELETE SET NULL,
  supervisor_review_id uuid REFERENCES supervisor_reviews(id) ON DELETE SET NULL,
  failure_categories jsonb NOT NULL DEFAULT '[]'::jsonb,
  evidence_review jsonb NOT NULL DEFAULT '{}'::jsonb,
  proposed_lesson jsonb NOT NULL DEFAULT '{}'::jsonb,
  safe_for_learning boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX feedback_cases_queue_idx ON feedback_cases (store_id, status, created_at DESC);
CREATE INDEX memory_corrections_status_idx ON memory_corrections (store_id, status, created_at DESC);
