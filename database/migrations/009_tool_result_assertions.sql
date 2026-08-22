CREATE TABLE tool_result_assertions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  correlation_id text NOT NULL,
  tool_call_id text NOT NULL,
  tool_key text NOT NULL,
  operation text NOT NULL,
  execution_status text,
  content_status text NOT NULL CHECK (content_status IN ('VALID','EMPTY_VALID','INVALID','ERROR','TIMEOUT','UNAUTHORIZED')),
  attempt integer NOT NULL DEFAULT 1 CHECK (attempt > 0),
  required_fields jsonb NOT NULL DEFAULT '[]'::jsonb,
  missing_fields jsonb NOT NULL DEFAULT '[]'::jsonb,
  assertions jsonb NOT NULL DEFAULT '[]'::jsonb,
  normalized_result jsonb,
  source_reference text,
  observed_at timestamptz,
  safe_for_agent_use boolean NOT NULL DEFAULT false,
  failure_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tool_call_id, attempt)
);

CREATE INDEX tool_result_assertions_lookup_idx
  ON tool_result_assertions (correlation_id, tool_key, created_at DESC);

CREATE TABLE system_change_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_id uuid NOT NULL REFERENCES system_change_proposals(id) ON DELETE CASCADE,
  component_version_id uuid REFERENCES system_component_versions(id) ON DELETE SET NULL,
  intended_state jsonb NOT NULL,
  actual_state jsonb,
  verification_method text NOT NULL,
  tool_assertion_ids uuid[] NOT NULL DEFAULT '{}',
  content_match boolean NOT NULL DEFAULT false,
  status text NOT NULL CHECK (status IN ('PENDING','VERIFIED','MISMATCH','FAILED','ROLLED_BACK')),
  verified_by text,
  verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
