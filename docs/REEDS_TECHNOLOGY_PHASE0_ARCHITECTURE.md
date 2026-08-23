# Reeds Technology Phase 0 Architecture

## Purpose

Phase 0 renders the complete owner-governed intelligence ecosystem as eleven inspectable n8n canvases while preserving the existing production foundation. It provides an honest implementation map before credentials, APIs, applications, or hardware are connected.

## Workflow set

| Workflow | Responsibility |
|---|---|
| 00 — Reeds Master Control Plane | Executive chain and departmental map |
| 01 — Identity and Authority | Owner identity, organizations, permissions, budgets and emergency authority |
| 02 — Memory and Knowledge | Governed temporal knowledge, provenance, promotion and retention |
| 03 — Goals and Planning | Goals, missions, tasks, budgets, simulation, evidence and recovery |
| 04 — Agents and Models | Model routing, specialist society and independent review |
| 05 — Tools and Actions | Tool registry, authorization, execution, verification and rollback |
| 06 — Digital Life | Phone, communications, calendar, files, browser, finance and health adapters |
| 07 — Business Domains | Shopify, CJdropshipping, Reeds Solutions, PrimeContractorOS and platform adapters |
| 08 — Physical Systems | Edge devices, wearables, smart home, vehicles, labs and robotics |
| 09 — Learning and Improvement | Outcome verification, feedback, corrections and controlled releases |
| 10 — Security and Continuity | Mandatory approval, privacy, credential, audit, kill-switch and recovery controls |

## Status vocabulary

- `OPERATIONAL`: a corresponding tested foundation exists elsewhere in the workflow pack.
- `PLANNED`: contract and location are defined, but the capability is not implemented.
- `REQUIRES CREDENTIALS`: implementation requires an approved external account and scoped secret.
- `REQUIRES HARDWARE`: implementation requires a trusted physical device or sensor.
- `FUTURE RESEARCH`: the capability is exploratory and must not be represented as production-ready.

An `OPERATIONAL` label in an architecture map points to an existing tested workflow; the Phase 0 node itself remains inert.

## Safety contract

Phase 0 architecture workflows:

1. remain inactive in source control;
2. contain no credentials or credential identifiers;
3. contain no external HTTP calls;
4. contain no database reads or writes;
5. contain no sub-workflow execution nodes;
6. contain no spending, messaging, production-change, or physical-action capability;
7. use No Operation nodes for every visual component;
8. return only a structured architecture manifest when manually inspected.

## Activation sequence

1. Phase 0 — complete visible architecture.
2. Phase 1 — universal identity, authority, event envelope, tool registry, policies and generalized schemas.
3. Phase 2 — goals, task decomposition, outcome evaluation and memory promotion.
4. Phase 3 — permissioned digital-life adapters.
5. Phase 4 — Reeds platform services, API gateway, event bus, edge and offline routing.
6. Phase 5 — physical systems through mandatory physical-action gates.

No later phase may bypass Dominique's root authority, deterministic policy gates, audit requirements, kill switch, or explicit approval requirements.

## Controlled n8n import

Set `SYNC_PHASE0_ARCHITECTURE_ONCE=true` for exactly one deployment. Startup copies only the eleven `*-phase0.json` files into an isolated temporary directory, verifies the count is exactly eleven, and imports that directory. It does not import or replace the executive, memory, Shopify, AgentMail, or reliability workflows.

After the deployment log reports `Successfully imported 11 workflows.`, immediately restore `SYNC_PHASE0_ARCHITECTURE_ONCE=false` and deploy again. Leaving the switch enabled risks duplicate architecture canvases on a later restart.
