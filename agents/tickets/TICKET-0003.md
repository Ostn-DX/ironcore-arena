---
ticket: TICKET-0003
title: "Architectural review — agent autonomy ladder integration"
scope: architectural
risk: high
needs_external_llm: true
allowlist:
  - agents/context/conventions.md
  - agents/context/invariants.md
  - agents/context/project_summary.md
notes:
  - 02_Autonomy_Framework/Autonomy_Ladder_L0_to_L5.md
  - 02_Autonomy_Framework/Autonomy_Scoring_Rubric.md
  - 02_Autonomy_Framework/Escalation_Policy.md
  - 09_Quality_Gates/Dev_Gate_Validation_System.md
---

## Goal

Review and update the three core agent context files so they accurately
reflect the autonomy ladder (L0–L5) and escalation policy defined in the
Studio_OS vault. The output must be consistent with the vault—no divergence
between context files and vault notes.

## Acceptance Criteria

- [ ] AC1: `conventions.md` references the correct autonomy levels
- [ ] AC2: `invariants.md` lists the escalation triggers from Escalation_Policy.md
- [ ] AC3: `project_summary.md` describes the current routing tier (Phase 4)
- [ ] AC4: No contradictions between updated files and vault source notes

## Forbidden Files

- `project/` — game engine is out of scope
- `tools/` — enforcement pipeline must not be modified by this ticket
- `Studio_OS/` — vault is read-only

## Notes

- Requires deep reading of four vault notes plus three context files.
- Cross-file consistency check is needed — local model cannot reliably do this.
- Expected route: **claude** (architectural scope + risk=high + needs_external_llm).

## Definition of Done

`python tools/run_ticket.py --ticket agents/tickets/TICKET-0003.md` exits 0
with `WAITING_FOR_EXTERNAL_EXECUTOR` status and a populated `handoff/` directory.
