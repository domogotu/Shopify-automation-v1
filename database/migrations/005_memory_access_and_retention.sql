CREATE TABLE memory_access_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  conversation_id uuid REFERENCES conversations(id) ON DELETE SET NULL,
  correlation_id text NOT NULL,
  actor_id text NOT NULL,
  agent_key text NOT NULL,
  purpose text NOT NULL,
  requested_scopes jsonb NOT NULL DEFAULT '[]'::jsonb,
  returned_memory_ids uuid[] NOT NULL DEFAULT '{}',
  denied_memory_ids uuid[] NOT NULL DEFAULT '{}',
  result_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX memory_access_log_store_time_idx
  ON memory_access_log (store_id, created_at DESC);

CREATE TABLE memory_retention_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  memory_kind memory_kind,
  resource_type text,
  sensitivity text,
  retention_days integer NOT NULL CHECK (retention_days > 0),
  action text NOT NULL CHECK (action IN ('DELETE','REDACT','SUMMARIZE','ARCHIVE')),
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE memory_summaries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  resource_type text,
  resource_id text,
  summary_type text NOT NULL,
  summary jsonb NOT NULL,
  source_message_ids uuid[] NOT NULL DEFAULT '{}',
  source_memory_ids uuid[] NOT NULL DEFAULT '{}',
  effective_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX memory_summaries_scope_idx
  ON memory_summaries (store_id, resource_type, resource_id, effective_at DESC);

INSERT INTO memory_retention_rules (memory_kind, retention_days, action)
VALUES
  ('WORKING', 7, 'DELETE'),
  ('ENTITY', 2555, 'ARCHIVE'),
  ('SEMANTIC', 730, 'SUMMARIZE'),
  ('EPISODIC', 730, 'SUMMARIZE'),
  ('PROCEDURAL', 2555, 'ARCHIVE'),
  ('APPROVAL', 2555, 'ARCHIVE');
