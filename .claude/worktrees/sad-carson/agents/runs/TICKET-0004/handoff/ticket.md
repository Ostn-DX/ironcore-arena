---
ticket: TICKET-0004
title: "Generate headless match regression corpus"
scope: large
needs_codex: true
risk: low
allowlist:
  - agents/context/conventions.md
notes:
  - 10_Regression_Harness/Simulation_Test_Suite.md
---

## Goal

Use Codex to generate an initial regression corpus of 20 headless match
scenarios based on the Regression Test Protocol in the vault. Each scenario
should be a JSON fixture describing combatant loadouts and expected outcome
ranges.

## Acceptance Criteria

- [ ] AC1: 20 scenario JSON fixtures generated under `agents/context/`
- [ ] AC2: Each fixture has fields: `scenario_id`, `combatants`, `expected_outcome`
- [ ] AC3: `conventions.md` updated to document fixture schema

## Notes

- Codex is needed for structured data generation from spec.
- Output is data files, not game engine code.
- Expected route: **codex** (needs_codex: true).

## Definition of Done

`python tools/run_ticket.py --ticket agents/tickets/TICKET-0004.md` exits 0
with `WAITING_FOR_EXTERNAL_EXECUTOR` status and executor `codex` in REPORT.md.
