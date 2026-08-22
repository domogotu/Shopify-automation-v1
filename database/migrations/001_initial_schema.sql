CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

CREATE TYPE approval_status AS ENUM ('PENDING','APPROVED','REJECTED','EXPIRED','CANCELLED');
CREATE TYPE candidate_status AS ENUM ('DISCOVERED','REVIEW','SAMPLE_REQUIRED','APPROVED','REJECTED','PAUSED','RETIRED');
CREATE TYPE order_state AS ENUM ('RECEIVED','REVIEW','SUPPLIER_SUBMITTED','SUPPLIER_ACCEPTED','TRACKING_RECEIVED','IN_TRANSIT','DELIVERED','EXCEPTION','CLOSED','CANCELLED');
CREATE TYPE run_status AS ENUM ('STARTED','SUCCEEDED','FAILED','RETRYING','CANCELLED');

CREATE TABLE stores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shopify_shop_id text UNIQUE,
  shop_domain text NOT NULL UNIQUE,
  display_name text NOT NULL,
  currency_code char(3) NOT NULL DEFAULT 'USD',
  timezone text NOT NULL DEFAULT 'America/Los_Angeles',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  supplier_type text NOT NULL,
  external_account_id text,
  name text NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, supplier_type, external_account_id)
);

CREATE TABLE supplier_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  supplier_id uuid NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  external_product_id text NOT NULL,
  source_url text,
  title text NOT NULL,
  product_cost numeric(12,2),
  shipping_cost numeric(12,2),
  warehouse_code text,
  processing_days_min integer,
  processing_days_max integer,
  delivery_days_min integer,
  delivery_days_max integer,
  inventory_status text,
  raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  last_verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, supplier_id, external_product_id)
);

CREATE TABLE supplier_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  supplier_product_id uuid NOT NULL REFERENCES supplier_products(id) ON DELETE CASCADE,
  external_variant_id text NOT NULL,
  sku text,
  option_values jsonb NOT NULL DEFAULT '{}'::jsonb,
  unit_cost numeric(12,2),
  shipping_cost numeric(12,2),
  available boolean NOT NULL DEFAULT true,
  raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, supplier_product_id, external_variant_id)
);

CREATE TABLE product_candidates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  supplier_product_id uuid REFERENCES supplier_products(id) ON DELETE SET NULL,
  status candidate_status NOT NULL DEFAULT 'DISCOVERED',
  proposed_title text,
  niche text,
  customer_problem text,
  risk_flags jsonb NOT NULL DEFAULT '[]'::jsonb,
  rejection_reason text,
  submitted_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE product_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  candidate_id uuid NOT NULL REFERENCES product_candidates(id) ON DELETE CASCADE,
  scoring_version text NOT NULL,
  demand_score numeric(5,2),
  margin_score numeric(5,2),
  shipping_score numeric(5,2),
  supplier_score numeric(5,2),
  return_risk_score numeric(5,2),
  regulatory_risk_score numeric(5,2),
  ip_risk_score numeric(5,2),
  overall_score numeric(5,2),
  evidence jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE shopify_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  candidate_id uuid REFERENCES product_candidates(id) ON DELETE SET NULL,
  shopify_product_id text NOT NULL,
  handle text,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  sync_version bigint NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, shopify_product_id),
  UNIQUE (store_id, handle)
);

CREATE TABLE shopify_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  shopify_product_id uuid NOT NULL REFERENCES shopify_products(id) ON DELETE CASCADE,
  shopify_variant_id text NOT NULL,
  sku text,
  option_values jsonb NOT NULL DEFAULT '{}'::jsonb,
  price numeric(12,2),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, shopify_variant_id),
  UNIQUE (store_id, sku)
);

CREATE TABLE supplier_variant_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  shopify_variant_id uuid NOT NULL REFERENCES shopify_variants(id) ON DELETE CASCADE,
  supplier_variant_id uuid NOT NULL REFERENCES supplier_variants(id) ON DELETE RESTRICT,
  active boolean NOT NULL DEFAULT true,
  verified_at timestamptz,
  verified_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, shopify_variant_id)
);

CREATE TABLE price_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  candidate_id uuid REFERENCES product_candidates(id) ON DELETE CASCADE,
  shopify_variant_id uuid REFERENCES shopify_variants(id) ON DELETE CASCADE,
  supplier_cost numeric(12,2) NOT NULL,
  supplier_shipping numeric(12,2) NOT NULL DEFAULT 0,
  duties_allowance numeric(12,2) NOT NULL DEFAULT 0,
  fee_allowance numeric(12,2) NOT NULL DEFAULT 0,
  refund_reserve numeric(12,2) NOT NULL DEFAULT 0,
  ad_allowance numeric(12,2) NOT NULL DEFAULT 0,
  landed_cost numeric(12,2) NOT NULL,
  proposed_price numeric(12,2) NOT NULL,
  contribution_profit numeric(12,2) NOT NULL,
  gross_margin_pct numeric(7,4) NOT NULL,
  pricing_version text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE content_drafts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  candidate_id uuid NOT NULL REFERENCES product_candidates(id) ON DELETE CASCADE,
  content_type text NOT NULL,
  content jsonb NOT NULL,
  source_facts jsonb NOT NULL DEFAULT '[]'::jsonb,
  model_provider text,
  model_name text,
  prompt_version text,
  status text NOT NULL DEFAULT 'DRAFT',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  approval_type text NOT NULL,
  resource_type text NOT NULL,
  resource_id uuid NOT NULL,
  status approval_status NOT NULL DEFAULT 'PENDING',
  requested_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  decision_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  requested_by text,
  decided_by text,
  requested_at timestamptz NOT NULL DEFAULT now(),
  decided_at timestamptz,
  expires_at timestamptz,
  idempotency_key text NOT NULL,
  UNIQUE (store_id, idempotency_key)
);

CREATE TABLE orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  shopify_order_id text NOT NULL,
  shopify_order_name text,
  state order_state NOT NULL DEFAULT 'RECEIVED',
  financial_status text,
  fulfillment_status text,
  currency_code char(3) NOT NULL DEFAULT 'USD',
  gross_total numeric(12,2),
  customer_reference_hash text,
  shipping_address_encrypted text,
  raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, shopify_order_id)
);

CREATE TABLE order_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  shopify_line_item_id text NOT NULL,
  shopify_variant_id uuid REFERENCES shopify_variants(id) ON DELETE SET NULL,
  supplier_variant_id uuid REFERENCES supplier_variants(id) ON DELETE SET NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(12,2),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, shopify_line_item_id)
);

CREATE TABLE fulfillments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  supplier_order_id text,
  shopify_fulfillment_order_id text,
  shopify_fulfillment_id text,
  state order_state NOT NULL DEFAULT 'REVIEW',
  submitted_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, supplier_order_id)
);

CREATE TABLE shipments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  fulfillment_id uuid NOT NULL REFERENCES fulfillments(id) ON DELETE CASCADE,
  tracking_number text,
  carrier text,
  tracking_url text,
  status text,
  shipped_at timestamptz,
  delivered_at timestamptz,
  last_event_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, tracking_number)
);

CREATE TABLE order_exceptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  exception_type text NOT NULL,
  severity text NOT NULL,
  status text NOT NULL DEFAULT 'OPEN',
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  resolution jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

CREATE TABLE support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
  external_ticket_id text,
  intent text,
  risk_level text,
  status text NOT NULL DEFAULT 'OPEN',
  assigned_to text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, external_ticket_id)
);

CREATE TABLE support_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  ticket_id uuid NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  direction text NOT NULL,
  body_encrypted text NOT NULL,
  ai_generated boolean NOT NULL DEFAULT false,
  approved_by text,
  sent_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE campaign_drafts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  channel text NOT NULL,
  campaign_type text NOT NULL,
  audience_definition jsonb NOT NULL DEFAULT '{}'::jsonb,
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'DRAFT',
  budget_limit numeric(12,2),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE automation_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  workflow_key text NOT NULL,
  n8n_execution_id text,
  correlation_id text NOT NULL,
  status run_status NOT NULL DEFAULT 'STARTED',
  attempt integer NOT NULL DEFAULT 1,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  error_class text,
  error_summary text,
  UNIQUE (workflow_key, correlation_id, attempt)
);

CREATE TABLE audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  correlation_id text NOT NULL,
  actor_type text NOT NULL,
  actor_id text,
  action text NOT NULL,
  resource_type text NOT NULL,
  resource_id text,
  payload_hash text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid REFERENCES stores(id) ON DELETE CASCADE,
  alert_type text NOT NULL,
  severity text NOT NULL,
  resource_type text,
  resource_id text,
  title text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'OPEN',
  created_at timestamptz NOT NULL DEFAULT now(),
  acknowledged_at timestamptz,
  resolved_at timestamptz
);

CREATE INDEX idx_candidates_store_status ON product_candidates(store_id, status);
CREATE INDEX idx_approvals_store_status ON approvals(store_id, status, approval_type);
CREATE INDEX idx_orders_store_state ON orders(store_id, state, created_at DESC);
CREATE INDEX idx_exceptions_open ON order_exceptions(store_id, status, severity);
CREATE INDEX idx_runs_correlation ON automation_runs(correlation_id);
CREATE INDEX idx_audit_resource ON audit_events(store_id, resource_type, resource_id, created_at DESC);
CREATE INDEX idx_alerts_open ON alerts(store_id, status, severity, created_at DESC);
