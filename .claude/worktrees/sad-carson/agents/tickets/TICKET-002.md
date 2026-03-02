## ID
TICKET-002

## Title
Create UI smoke test navigation runner

## Goal
Implement automated UI navigation test to catch scene transition breakages.

## Allowed Files (edit allowlist)
- autoload/GameManager.gd
- autoload/SceneTransitionManager.gd (if exists)
- scenes/main_menu.tscn
- scenes/build_screen.tscn
- scenes/campaign_screen.tscn
- scenes/battle_screen.tscn
- scenes/results_screen.tscn

## New Files (if any)
- tools/run_ui_smoke.gd

## Forbidden Files
- autoload/SimulationManager.gd (use existing battle flow)
- autoload/GameState.gd (no direct mutation)
- src/entities/*.gd
- Any JSON data files

## Acceptance Criteria
- [ ] AC1: Successfully navigates full loop: Main → Builder → Campaign → Battle → Results → Campaign
- [ ] AC2: Detects missing nodes/signals and reports which transition failed
- [ ] AC3: Outputs JSON report with transition results
- [ ] AC4: Exits with code 0 on success, nonzero on failure
- [ ] AC5: Completes within 30 seconds (short battle timeout)

## Tests Required
- [ ] test1: Verify all required scenes exist and load
- [ ] test2: Verify transition detection works (break a scene, confirm failure)
- [ ] test3: Verify JSON output format

## Run Command
```
tools/dev_gate.ps1   # Windows
tools/dev_gate.sh    # Mac/Linux
```

## Notes
- Invariants: See agents/context/invariants.md
- Use button signal emission to trigger navigation
- Set SimulationManager.MAX_TICKS low for fast battles
- Check for node existence before interaction
