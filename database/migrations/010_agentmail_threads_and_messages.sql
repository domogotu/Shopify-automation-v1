CREATE TABLE agentmail_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  inbox_id text NOT NULL,
  thread_id text NOT NULL,
  subject text,
  participants jsonb NOT NULL DEFAULT '[]'::jsonb,
  last_message_id text,
  last_event_at timestamptz,
  status text NOT NULL DEFAULT 'OPEN',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, inbox_id, thread_id)
);

CREATE TABLE agentmail_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  thread_record_id uuid NOT NULL REFERENCES agentmail_threads(id) ON DELETE CASCADE,
  event_id text NOT NULL,
  inbox_id text NOT NULL,
  thread_id text NOT NULL,
  message_id text NOT NULL,
  direction text NOT NULL CHECK (direction IN ('INBOUND','OUTBOUND')),
  sender jsonb,
  recipients jsonb NOT NULL DEFAULT '[]'::jsonb,
  subject text,
  extracted_text text,
  labels jsonb NOT NULL DEFAULT '[]'::jsonb,
  attachment_metadata jsonb NOT NULL DEFAULT '[]'::jsonb,
  provider_timestamp timestamptz NOT NULL,
  processing_status text NOT NULL DEFAULT 'RECEIVED',
  payload_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, event_id),
  UNIQUE (store_id, inbox_id, message_id)
);

CREATE INDEX agentmail_messages_thread_idx
  ON agentmail_messages (store_id, inbox_id, thread_id, provider_timestamp DESC);

CREATE TABLE agentmail_send_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  correlation_id text NOT NULL,
  inbox_id text NOT NULL,
  reply_to_message_id text NOT NULL,
  expected_thread_id text NOT NULL,
  approval_id uuid,
  idempotency_key text NOT NULL,
  content_hash text NOT NULL,
  provider_message_id text,
  provider_thread_id text,
  content_status text NOT NULL DEFAULT 'PENDING',
  verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, idempotency_key)
);
