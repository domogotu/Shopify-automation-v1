BEGIN;

CREATE TABLE webhook_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  provider text NOT NULL,
  webhook_id text NOT NULL,
  topic text NOT NULL,
  signature_verified boolean NOT NULL DEFAULT false,
  payload_hash text NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  processing_status text NOT NULL DEFAULT 'RECEIVED',
  correlation_id text NOT NULL,
  UNIQUE (provider, webhook_id)
);

CREATE TABLE event_outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  aggregate_type text NOT NULL,
  aggregate_id text NOT NULL,
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  idempotency_key text NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  attempt_count integer NOT NULL DEFAULT 0,
  available_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (idempotency_key)
);

CREATE INDEX event_outbox_dispatch_idx
  ON event_outbox (status, available_at, created_at)
  WHERE status IN ('PENDING','RETRY');

CREATE TABLE dead_letter_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  correlation_id text NOT NULL,
  source_type text NOT NULL,
  source_id text NOT NULL,
  failure_class text NOT NULL,
  failure_reason text NOT NULL,
  payload_reference text,
  attempt_count integer NOT NULL,
  status text NOT NULL DEFAULT 'OPEN',
  assigned_to text,
  resolution jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

CREATE INDEX dead_letter_review_idx
  ON dead_letter_items (status, created_at DESC);

CREATE TABLE feature_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  flag_key text NOT NULL,
  stage text NOT NULL CHECK (stage IN ('OFF','OBSERVE','DRAFT','APPROVAL_REQUIRED','CANARY','AUTOMATED')),
  rollout_percent numeric(5,2) NOT NULL DEFAULT 0 CHECK (rollout_percent >= 0 AND rollout_percent <= 100),
  rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  kill_switch boolean NOT NULL DEFAULT false,
  version integer NOT NULL DEFAULT 1,
  updated_by text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE NULLS NOT DISTINCT (store_id, flag_key)
);

CREATE TABLE reconciliation_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  resource_type text NOT NULL,
  window_start timestamptz NOT NULL,
  window_end timestamptz NOT NULL,
  source_counts jsonb NOT NULL DEFAULT '{}'::jsonb,
  mismatch_count integer NOT NULL DEFAULT 0,
  mismatches jsonb NOT NULL DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'STARTED',
  correlation_id text NOT NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE service_level_measurements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_key text NOT NULL,
  workflow_key text,
  metric_name text NOT NULL,
  metric_value numeric NOT NULL,
  unit text NOT NULL,
  dimensions jsonb NOT NULL DEFAULT '{}'::jsonb,
  correlation_id text,
  observed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX service_level_measurements_time_idx
  ON service_level_measurements (service_key, metric_name, observed_at DESC);

COMMIT;
