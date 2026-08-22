CREATE TYPE memory_status AS ENUM ('PROPOSED','VERIFIED','SUPERSEDED','EXPIRED','REJECTED');
CREATE TYPE memory_kind AS ENUM ('WORKING','ENTITY','SEMANTIC','EPISODIC','PROCEDURAL','APPROVAL');

CREATE TABLE agent_definitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_key text NOT NULL,
  version text NOT NULL,
  description text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  intents jsonb NOT NULL DEFAULT '[]'::jsonb,
  memory_scopes jsonb NOT NULL DEFAULT '[]'::jsonb,
  read_tools jsonb NOT NULL DEFAULT '[]'::jsonb,
  write_tools jsonb NOT NULL DEFAULT '[]'::jsonb,
  approval_types jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (agent_key, version)
);

CREATE TABLE agent_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  correlation_id text NOT NULL,
  actor_id text,
  channel text NOT NULL,
  selected_agent_key text,
  intent text,
  status text NOT NULL DEFAULT 'STARTED',
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  UNIQUE (store_id, correlation_id)
);

CREATE TABLE memory_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  kind memory_kind NOT NULL,
  status memory_status NOT NULL DEFAULT 'PROPOSED',
  resource_type text NOT NULL,
  resource_id text,
  memory_key text NOT NULL,
  content jsonb NOT NULL,
  source_type text NOT NULL,
  source_id text NOT NULL,
  source_observed_at timestamptz NOT NULL,
  confidence numeric(5,4) NOT NULL DEFAULT 1.0 CHECK (confidence >= 0 AND confidence <= 1),
  sensitivity text NOT NULL DEFAULT 'INTERNAL',
  effective_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  supersedes_id uuid REFERENCES memory_items(id) ON DELETE SET NULL,
  content_hash text NOT NULL,
  created_by text,
  verified_by text,
  verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, resource_type, memory_key, content_hash)
);

CREATE INDEX memory_items_scope_idx ON memory_items (store_id, resource_type, resource_id, status);
CREATE INDEX memory_items_effective_idx ON memory_items (store_id, effective_at DESC);
CREATE INDEX memory_items_content_gin_idx ON memory_items USING gin (content);

CREATE TABLE memory_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  from_memory_id uuid NOT NULL REFERENCES memory_items(id) ON DELETE CASCADE,
  to_memory_id uuid NOT NULL REFERENCES memory_items(id) ON DELETE CASCADE,
  relationship text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, from_memory_id, to_memory_id, relationship)
);

CREATE TABLE context_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  session_id uuid REFERENCES agent_sessions(id) ON DELETE SET NULL,
  correlation_id text NOT NULL,
  agent_key text NOT NULL,
  task_hash text NOT NULL,
  memory_ids uuid[] NOT NULL DEFAULT '{}',
  context_payload jsonb NOT NULL,
  token_estimate integer,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE memory_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  memory_id uuid REFERENCES memory_items(id) ON DELETE SET NULL,
  session_id uuid REFERENCES agent_sessions(id) ON DELETE SET NULL,
  feedback_type text NOT NULL,
  outcome jsonb NOT NULL DEFAULT '{}'::jsonb,
  reviewer_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE policy_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_key text NOT NULL,
  version text NOT NULL,
  policy jsonb NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  effective_at timestamptz,
  approved_by text,
  approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (policy_key, version)
);

CREATE TABLE tool_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_key text NOT NULL,
  tool_key text NOT NULL,
  operation text NOT NULL CHECK (operation IN ('READ','WRITE')),
  approval_type text,
  enabled boolean NOT NULL DEFAULT true,
  max_risk_level text NOT NULL DEFAULT 'LOW',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (agent_key, tool_key, operation)
);
