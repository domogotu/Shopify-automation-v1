# Reeds Technology — Architecture

Owner-governed intelligence ecosystem. This document is the **specification**, not a
claim of implementation. Each section marks what is built versus what is planned.

---

## Core Rule

Everything must move through the same governed route:

```
Input
  -> identity
  -> context/memory
  -> planning
  -> model/agent work
  -> supervisor
  -> policy gate
  -> approval if needed
  -> action
  -> verification
  -> memory/audit
```

Nothing important skips identity, policy, approval, verification, or memory.

---

## Master Route

The main system route inside n8n. Lives in `00 — Reeds Master Control Plane`,
which is the top-level traffic controller: every request enters here or is
shaped to match this route.

```
Universal Event Intake
  -> Identity and Context
  -> Scoped Memory Retrieval
  -> Goal and Mission Planner
  -> Model and Agent Router
  -> Specialist Work
  -> Executive Supervisor
  -> Deterministic Policy Gate
  -> Human Approval When Required
  -> Tool and Action Execution
  -> Result Verification
  -> Governed Memory Write
```

---

## Domain Map

| # | Domain | Purpose | Contains |
|---|--------|---------|----------|
| 00 | Reeds Master Control Plane | The main executive chain | Full visible system path; links to every department |
| 01 | Identity and Authority | Decide who is asking, what they own, what they may do | Root authority, roles, permissions, projects, budgets, approvals, kill switch |
| 02 | Memory and Knowledge | Retrieve and store governed context | Conversation memory, memory items, citations, expiration, promotion, supersession |
| 03 | Goals and Planning | Turn a request into a bounded mission | Goal registry, mission planner, task decomposition, risk forecast, recovery planner |
| 04 | Agents and Models | Decide which model or specialist handles the work | OpenAI, Claude, local models, vision, speech, specialist agents, executive supervisor |
| 05 | Tools and Actions | Control real-world or external actions | Tool registry, credential scope, authorization, execution, result assertion, rollback, audit |
| 06 | Digital Life | Phone, email, calendar, files, browser, finance, health, media | Personal adapters, all behind permission and privacy gates |
| 07 | Business Domains | Business systems | Shopify, CJdropshipping, AgentMail, GitHub, Render, PostgreSQL, Google Drive, accounting |
| 08 | Physical Systems | Future hardware and physical actions | Reeds Hub, Edge, Mesh, Ear, Vision, Watch, smart home, vehicles, labs, robotics |
| 09 | Learning and Improvement | Learn from outcomes without uncontrolled self-modification | Evidence collector, result validator, feedback, corrections, improvement cases, release pipeline |
| 10 | Security and Continuity | Hard safety controls | Human approval, spending gate, message gate, production gate, privacy gate, kill switch, backups |

---

## Current Working Route

This is the operational foundation that is actually running today:

```
Manual/Webhook Request
  -> Validate Decision Request
  -> Retrieve Scoped Memory
  -> Merge Request With Memory
  -> Prepare Executive Plan
  -> ChatGPT Executive Brain
  -> Collect Specialist Reports
  -> Prepare Supervisor Review
  -> ChatGPT Decision Supervisor
  -> Deterministic Decision Gate
  -> Prepare Memory Record
  -> Store Governed Memory
```

---

## Why Memory Splits Into Two Workflows

There are two distinct memory jobs, and they run at different points in the route.

**`00E — Scoped Memory Retrieval`** — used *before* decision-making.
Answers: *what does the system already know that is relevant?*

**`00D — Memory Write Gate`** — used *after* the decision/result.
Answers: *what should be safely stored from this event?*

So the memory route is:

```
Validate Request
  -> Retrieve Scoped Memory
  -> Merge Request With Memory
  -> Decision Chain
  -> Prepare Memory Record
  -> Store Governed Memory
```

---

## Phase Plan

### Phase 0 — Visual Architecture — **built**
Show the whole Reeds Technology ecosystem in n8n without pretending everything
works yet. Safe visual canvases: no messages, no spending, no production changes,
no account access, no hardware control.

### Phase 1 — Universal Foundation — *next*
Real identity, authority, event envelope, policy registry, tool registry,
generalized schemas.

### Phase 2 — Goals and Learning
Mission planner, task graph, outcome checking, correction records, memory promotion.

### Phase 3 — Digital Life
Connect phone, email, contacts, calendar, files, browser, finance, health —
all behind permissions.

### Phase 4 — Reeds Platform
Reeds API, event bus, mobile app, local/edge routing, offline mode.

### Phase 5 — Physical Technology
Hardware, wearables, smart home, vehicles, lab systems, drones, robotics —
through physical gates.

---

## Next Practical Step

Phase 0 is imported and the current executive route is green. The next build
step is **Phase 1**:

```
Universal Event Envelope
  -> Identity Resolver
  -> Root Authority Check
  -> Permission Scope
  -> Policy Decision
  -> Audit Record
```

This is the part that makes every future input follow the same rules before it
touches memory, models, tools, money, messages, or hardware.
