CREATE TABLE conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  external_session_id text NOT NULL,
  actor_id text NOT NULL,
  channel text NOT NULL DEFAULT 'web',
  title text,
  status text NOT NULL DEFAULT 'ACTIVE',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  UNIQUE (store_id, external_session_id)
);

CREATE TABLE conversation_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  correlation_id text NOT NULL,
  role text NOT NULL CHECK (role IN ('USER','ASSISTANT','SYSTEM','TOOL')),
  content text NOT NULL,
  selected_agent_key text,
  intent text,
  risk_level text,
  sources jsonb NOT NULL DEFAULT '[]'::jsonb,
  tool_calls jsonb NOT NULL DEFAULT '[]'::jsonb,
  model_provider text,
  model_name text,
  prompt_version text,
  input_tokens integer,
  output_tokens integer,
  latency_ms integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, correlation_id, role)
);

CREATE INDEX conversation_messages_timeline_idx
  ON conversation_messages (conversation_id, created_at DESC);

CREATE TABLE response_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  correlation_id text NOT NULL,
  job_type text NOT NULL,
  status text NOT NULL DEFAULT 'QUEUED',
  progress_percent integer NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
  progress_message text,
  result_message_id uuid REFERENCES conversation_messages(id) ON DELETE SET NULL,
  error_code text,
  error_detail text,
  created_at timestamptz NOT NULL DEFAULT now(),
  started_at timestamptz,
  completed_at timestamptz,
  UNIQUE (store_id, correlation_id)
);

CREATE TABLE realtime_tool_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  conversation_id uuid REFERENCES conversations(id) ON DELETE SET NULL,
  correlation_id text NOT NULL,
  agent_key text NOT NULL,
  tool_key text NOT NULL,
  operation text NOT NULL,
  status text NOT NULL,
  request_hash text,
  source_refs jsonb NOT NULL DEFAULT '[]'::jsonb,
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  latency_ms integer,
  error_detail text
);

CREATE INDEX realtime_tool_events_correlation_idx
  ON realtime_tool_events (store_id, correlation_id, started_at);
