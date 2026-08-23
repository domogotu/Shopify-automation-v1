CREATE TYPE universal_event_status AS ENUM ('ACCEPTED','REJECTED','QUARANTINED');
CREATE TYPE universal_risk_level AS ENUM ('LOW','MEDIUM','HIGH','CRITICAL');

CREATE TABLE universal_event_envelopes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE SET NULL,
  event_id text NOT NULL,
  correlation_id text NOT NULL,
  received_at timestamptz NOT NULL,
  source_type text NOT NULL,
  source_id text NOT NULL,
  actor_id text NOT NULL,
  store_domain text NOT NULL,
  session_id text NOT NULL,
  request_type text NOT NULL,
  message text NOT NULL,
  resource_type text NOT NULL,
  resource_id text,
  risk_level universal_risk_level NOT NULL DEFAULT 'MEDIUM',
  execution_mode text NOT NULL DEFAULT 'MANUAL',
  identity_status text NOT NULL DEFAULT 'UNRESOLVED',
  policy_status text NOT NULL DEFAULT 'PENDING',
  envelope_status universal_event_status NOT NULL DEFAULT 'ACCEPTED',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (event_id),
  UNIQUE (correlation_id)
);

CREATE INDEX universal_event_envelopes_store_idx
  ON universal_event_envelopes (store_id, created_at DESC);

CREATE INDEX universal_event_envelopes_status_idx
  ON universal_event_envelopes (envelope_status, created_at DESC);

CREATE INDEX universal_event_envelopes_actor_idx
  ON universal_event_envelopes (actor_id, created_at DESC);

CREATE TABLE authority_audit_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE SET NULL,
  envelope_id uuid REFERENCES universal_event_envelopes(id) ON DELETE SET NULL,
  correlation_id text NOT NULL,
  actor_id text NOT NULL,
  authority_stage text NOT NULL,
  decision text NOT NULL,
  reason text NOT NULL,
  evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX authority_audit_records_correlation_idx
  ON authority_audit_records (correlation_id, created_at DESC);

CREATE TABLE policy_decision_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE SET NULL,
  envelope_id uuid REFERENCES universal_event_envelopes(id) ON DELETE SET NULL,
  correlation_id text NOT NULL,
  policy_key text NOT NULL,
  decision text NOT NULL,
  approval_required boolean NOT NULL DEFAULT false,
  risk_level universal_risk_level NOT NULL DEFAULT 'MEDIUM',
  reasons jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX policy_decision_records_correlation_idx
  ON policy_decision_records (correlation_id, created_at DESC);
