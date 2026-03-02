---
ticket: TICKET-0001
title: "Smoke test — validate enforcement pipeline"
allowlist:
  - agents/context/conventions.md
  - agents/context/invariants.md
notes:
  - 09_Quality_Gates/Dev_Gate_Validation_System.md
  - 02_Autonomy_Framework/Autonomy_Ladder_L0_to_L5.md
---

## Goal

Validate that `run_ticket.py` correctly orchestrates the full enforcement pipeline:
build context pack → require pack → verify manifest → dev gate.

## Acceptance Criteria

- [ ] AC1: `build_context_pack.py` builds pack with manifest.json
- [ ] AC2: `require_context_pack.py` passes for TICKET-0001
- [ ] AC3: `verify_manifest.py` passes integrity check
- [ ] AC4: `dev_gate.ps1 -SkipGodot` passes vault validation
- [ ] AC5: `agents/runs/TICKET-0001/REPORT.md` is written
- [ ] AC6: `agents/runs/TICKET-0001/logs/` contains one log per step
- [ ] AC7: Vault notes appear in `vault_notes/` inside context pack

## Notes

- Allowlist contains only agents/context files — no game engine code touched.
- Notes reference two vault documents for context ingestion.
- This ticket exists to test the tooling, not ship a game feature.

## Definition of Done

`python tools/run_ticket.py --ticket agents/tickets/TICKET-0001.md` exits 0.
