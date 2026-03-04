# Agent Workflow - Quick Reference

## One-Line Commands

```bash
# Create context pack
python tools/build_context_pack.py agents/tickets/TICKET-XXX.md

# Validate agent output
python tools/normalize_agent_output.py TICKET-XXX

# Run gate (Windows)
.\tools\dev_gate.ps1

# Run gate (Mac/Linux)
./tools/dev_gate.sh
```

## Ticket Lifecycle

```
1. Write ticket → agents/tickets/TICKET-XXX.md
2. Build pack  → python tools/build_context_pack.py ...
3. Agent works → Uses pack, outputs to agent_runs/
4. Normalize   → python tools/normalize_agent_output.py ...
5. Apply       → Copy NEW_FILES/, apply MODIFICATIONS/
6. Gate        → ./tools/dev_gate.sh
7. Commit      → git commit -m "TICKET-XXX: Description"
```

## Ticket Template Essentials

```markdown
## ID
TICKET-XXX

## Title
Clear description

## Goal
One sentence

## Allowed Files
- path/to/file.gd

## New Files
- new_file.gd

## Acceptance Criteria
- [ ] AC1: Testable condition

## Run Command
./tools/dev_gate.sh
```

## Gate Output

```
=== HEADLESS MATCH SUMMARY ===
Total matches: 10
Crashes: 0          ← Must be 0
Timeouts: 0
Avg duration: 2.45s
Player win rate: 50.0%
==============================

=== UI SMOKE TEST SUMMARY ===
Transitions: 6 passed, 0 failed  ← Must be 0 failed
Success rate: 100.0%
=============================

DEVELOPMENT GATE: PASSED ✓
```

## File Locations

| Type | Path |
|------|------|
| Tickets | `agents/tickets/` |
| Context | `agents/context/` |
| Context Packs | `tools/context_packs/<ticket>/` |
| Agent Output | `agent_runs/<ticket>/` |
| Reports | `reports/` |
| Gate Scripts | `tools/dev_gate.*` |

## Common Issues

**Gate fails: "Godot not found"**
→ Add Godot to PATH or edit script to set GODOT path

**Match crashes**
→ Check `reports/match_report.json` for error details

**UI transition fails**
→ Check `reports/ui_smoke.json` for which transition broke

**Normalizer rejects output**
→ Fix TODO/FIXME in agent output, ensure all files complete
