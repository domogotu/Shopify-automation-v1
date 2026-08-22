BEGIN;

CREATE TYPE knowledge_category_status AS ENUM ('PROPOSED','ACTIVE','ARCHIVED','REJECTED');
CREATE TYPE category_proposal_action AS ENUM ('CREATE','RENAME','MOVE','MERGE','SPLIT','ARCHIVE');
CREATE TYPE category_proposal_status AS ENUM ('PENDING','AUTO_APPROVED','APPROVED','REJECTED','APPLIED');

CREATE TABLE knowledge_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES knowledge_categories(id) ON DELETE RESTRICT,
  slug text NOT NULL,
  name text NOT NULL,
  description text,
  status knowledge_category_status NOT NULL DEFAULT 'PROPOSED',
  sensitivity text NOT NULL DEFAULT 'INTERNAL',
  risk_level text NOT NULL DEFAULT 'LOW',
  sort_order integer NOT NULL DEFAULT 0,
  created_by text NOT NULL,
  approved_by text,
  approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  CHECK (parent_id IS NULL OR parent_id <> id),
  UNIQUE (store_id, parent_id, slug)
);

CREATE INDEX knowledge_categories_tree_idx
  ON knowledge_categories (store_id, parent_id, status, sort_order);

CREATE TABLE knowledge_category_aliases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES knowledge_categories(id) ON DELETE CASCADE,
  alias text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, alias)
);

CREATE TABLE memory_category_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  memory_id uuid NOT NULL REFERENCES memory_items(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES knowledge_categories(id) ON DELETE RESTRICT,
  is_primary boolean NOT NULL DEFAULT false,
  confidence numeric(5,4) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  assignment_reason text,
  assigned_by text NOT NULL,
  reviewed_by text,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (memory_id, category_id)
);

CREATE UNIQUE INDEX memory_one_primary_category_idx
  ON memory_category_assignments (memory_id)
  WHERE is_primary;

CREATE INDEX memory_category_lookup_idx
  ON memory_category_assignments (store_id, category_id, memory_id);

CREATE TABLE category_proposals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  action category_proposal_action NOT NULL,
  status category_proposal_status NOT NULL DEFAULT 'PENDING',
  proposed_name text,
  proposed_slug text,
  proposed_parent_id uuid REFERENCES knowledge_categories(id) ON DELETE RESTRICT,
  source_category_ids uuid[] NOT NULL DEFAULT '{}',
  affected_memory_ids uuid[] NOT NULL DEFAULT '{}',
  rationale text NOT NULL,
  duplicate_check jsonb NOT NULL DEFAULT '{}'::jsonb,
  risk_level text NOT NULL DEFAULT 'LOW',
  confidence numeric(5,4) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  proposed_by text NOT NULL,
  reviewed_by text,
  review_reason text,
  reviewed_at timestamptz,
  applied_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX category_proposals_review_idx
  ON category_proposals (store_id, status, created_at DESC);

CREATE TABLE category_change_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  category_id uuid REFERENCES knowledge_categories(id) ON DELETE SET NULL,
  proposal_id uuid REFERENCES category_proposals(id) ON DELETE SET NULL,
  action text NOT NULL,
  before_state jsonb,
  after_state jsonb,
  actor_id text NOT NULL,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX category_change_log_store_time_idx
  ON category_change_log (store_id, created_at DESC);

COMMIT;
