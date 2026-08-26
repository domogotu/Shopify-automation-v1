-- Reeds Technology Ecosystem - Phase 1 (Core Contracts) + Phase 2 (Governed Memory, minimal)
-- Safe to run standalone against the existing Render-managed Postgres used by n8n.
-- Additive only - does not touch policy_decisions/approval_requests (001) or any n8n-internal tables.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -- Identity and authority ----------------------------------------------
CREATE TABLE IF NOT EXISTS owners (
    owner_id        TEXT PRIMARY KEY,
    display_name    TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS organizations (
    organization_id TEXT PRIMARY KEY,
    owner_id        TEXT NOT NULL REFERENCES owners(owner_id),
    name            TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS projects (
    project_id      TEXT PRIMARY KEY,
    organization_id TEXT NOT NULL REFERENCES organizations(organization_id),
    name            TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS identities (
    identity_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_type        TEXT NOT NULL,          -- external_customer | internal_agent | owner | delegated_role
    external_key      TEXT,                    -- e.g. email address for external customers
    owner_id          TEXT REFERENCES owners(owner_id),
    organization_id   TEXT REFERENCES organizations(organization_id),
    authenticated     BOOLEAN NOT NULL DEFAULT false,
    role              TEXT NOT NULL DEFAULT 'minimum_access',
    permissions       JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (actor_type, external_key)
);
CREATE INDEX IF NOT EXISTS idx_identities_external_key ON identities(external_key);

-- -- Events and execution ------------------------------------------------
CREATE TABLE IF NOT EXISTS events (
    event_id            TEXT PRIMARY KEY,
    correlation_id       TEXT NOT NULL,
    causation_id          TEXT,
    event_type             TEXT NOT NULL,
    schema_version           TEXT NOT NULL DEFAULT '1.0',
    occurred_at                TIMESTAMPTZ NOT NULL,
    received_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_system                TEXT,
    source_channel                 TEXT,
    source_adapter                   TEXT,
    actor_identity_id                  UUID REFERENCES identities(identity_id),
    owner_id                             TEXT REFERENCES owners(owner_id),
    organization_id                        TEXT REFERENCES organizations(organization_id),
    project_id                               TEXT REFERENCES projects(project_id),
    sensitivity                                TEXT,
    contains_pii                                 BOOLEAN DEFAULT false,
    contains_secret                                BOOLEAN DEFAULT false,
    idempotency_key                                  TEXT,
    content_hash                                       TEXT,
    requested_capability                                 TEXT,
    payload                                                JSONB,
    created_at                                             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (idempotency_key)
);
CREATE INDEX IF NOT EXISTS idx_events_correlation ON events(correlation_id);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);

CREATE TABLE IF NOT EXISTS audit_events (
    audit_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correlation_id  TEXT NOT NULL,
    actor            TEXT,
    action            TEXT NOT NULL,
    reason              TEXT,
    detail                 JSONB,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_events_correlation ON audit_events(correlation_id);

-- -- Governed memory (minimal viable, per blueprint Section 7) -----------
CREATE TABLE IF NOT EXISTS memories (
    memory_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    memory_type          TEXT NOT NULL,        -- working|conversation|episodic|semantic|procedural|preference|decision|error|performance|policy
    owner_id               TEXT NOT NULL REFERENCES owners(owner_id),
    organization_id           TEXT REFERENCES organizations(organization_id),
    project_id                  TEXT REFERENCES projects(project_id),
    subject_entity              TEXT,
    fact_or_claim                  TEXT NOT NULL,
    source_id                        TEXT,
    provenance_chain                   JSONB,
    confidence                           NUMERIC,
    sensitivity                            TEXT,
    valid_from                               TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to                                   TIMESTAMPTZ,
    supersedes_memory_id                         UUID REFERENCES memories(memory_id),
    verification_status                          TEXT NOT NULL DEFAULT 'unverified',
    created_by_actor                               TEXT,
    created_by_run_id                                TEXT,
    correlation_id                                     TEXT,
    created_at                                           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_memories_owner ON memories(owner_id);
CREATE INDEX IF NOT EXISTS idx_memories_type ON memories(memory_type);
CREATE INDEX IF NOT EXISTS idx_memories_fulltext ON memories USING gin (to_tsvector('english', fact_or_claim));

-- -- Tool execution and verification (Steps 10-11) ------------------------
CREATE TABLE IF NOT EXISTS tool_executions (
    tool_execution_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correlation_id        TEXT NOT NULL,
    action_hash             TEXT NOT NULL,
    tool_id                   TEXT NOT NULL,
    parameters                  JSONB,
    credential_ref                 TEXT,
    status                           TEXT NOT NULL DEFAULT 'pending', -- pending|success|failed
    provider_receipt                   JSONB,
    executed_at                          TIMESTAMPTZ,
    created_at                             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS verification_results (
    verification_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tool_execution_id      UUID REFERENCES tool_executions(tool_execution_id),
    correlation_id            TEXT NOT NULL,
    result                       TEXT NOT NULL CHECK (result IN ('verified','failed','partial','uncertain')),
    method                         TEXT,
    evidence                         JSONB,
    created_at                         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -- Seed the one real owner/org so foreign keys resolve -------------------
INSERT INTO owners (owner_id, display_name) VALUES ('dominique_root_owner','Dominique Reed')
  ON CONFLICT (owner_id) DO NOTHING;
INSERT INTO organizations (organization_id, owner_id, name) VALUES ('reeds_solutions_llc','dominique_root_owner','Reeds Solutions LLC')
  ON CONFLICT (organization_id) DO NOTHING;
INSERT INTO projects (project_id, organization_id, name) VALUES ('service_intake','reeds_solutions_llc','Service Intake')
  ON CONFLICT (project_id) DO NOTHING;
