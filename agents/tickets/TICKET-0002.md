---
ticket: TICKET-0002
title: "Add project_summary to agent context files"
scope: small
risk: low
allowlist:
  - agents/context/project_summary.md
notes:
  - 02_Autonomy_Framework/Autonomy_Ladder_L0_to_L5.md
---

## Goal

Update `agents/context/project_summary.md` to include the current phase
(Phase 4: routing and handoff) and the list of active enforcement tools.

## Acceptance Criteria

- [ ] AC1: `agents/context/project_summary.md` mentions Phase 4
- [ ] AC2: Active tool list includes route_ticket, build_handoff_packet
- [ ] AC3: No other files modified

## Notes

- Small, self-contained edit to a single context file.
- No game engine code involved.
- Expected route: **local** (small scope, low risk, single file).

## Definition of Done

`python tools/run_ticket.py --ticket agents/tickets/TICKET-0002.md` exits 0
and REPORT.md shows executor `local`.
