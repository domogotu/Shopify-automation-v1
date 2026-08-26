-- Reeds Technology Ecosystem - Phase 4 (Deterministic Governance)
-- Minimal schema for Step 8 (Deterministic Policy Gate) and Step 9 (Human Approval)
-- Safe to run standalone against the existing Render-managed Postgres used by n8n.
-- Does not touch any existing n8n-internal tables.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS policy_decisions (
    policy_decision_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correlation_id       TEXT NOT NULL,
    event_id             TEXT,
    action_id            TEXT NOT NULL,
    tool_id               TEXT NOT NULL,
    action_class          TEXT NOT NULL,          -- read_only | internal_write | external_comm | spending | credential_change | production_change | destructive | physical | emergency
    decision              TEXT NOT NULL CHECK (decision IN ('allow','deny','require_approval')),
    policy_id              TEXT NOT NULL,
    reason                 TEXT NOT NULL,
    action_hash            TEXT NOT NULL,
    requesting_agent       TEXT,
    parameters              JSONB,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS approval_requests (
    approval_request_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_decision_id      UUID REFERENCES policy_decisions(policy_decision_id),
    correlation_id          TEXT NOT NULL,
    action_hash              TEXT NOT NULL,
    description               TEXT NOT NULL,       -- human-readable description shown to Dominique
    tool_id                    TEXT NOT NULL,
    parameters                  JSONB NOT NULL,
    credential_ref               TEXT,
    destination                   TEXT,             -- recipient / external system affected
    estimated_cost                 NUMERIC,
    records_affected                TEXT,
    reversible                       BOOLEAN,
    verification_method              TEXT,
    rollback_method                   TEXT,
    requesting_agent                   TEXT,
    requested_by                        TEXT NOT NULL DEFAULT 'dominique_root_owner',
    status                                TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','denied','expired')),
    decided_at                             TIMESTAMPTZ,
    expires_at                              TIMESTAMPTZ NOT NULL,
    created_at                               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_approval_requests_status ON approval_requests(status);
CREATE INDEX IF NOT EXISTS idx_approval_requests_correlation ON approval_requests(correlation_id);
CREATE INDEX IF NOT EXISTS idx_policy_decisions_correlation ON policy_decisions(correlation_id);
