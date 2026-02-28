## ID
TICKET-001

## Title
Create headless match runner for automated testing

## Goal
Implement a tool that runs AI vs AI battles without UI to validate simulation correctness and stability.

## Allowed Files (edit allowlist)
- autoload/SimulationManager.gd
- data/campaign.json
- data/components.json
- src/systems/deterministic_rng.gd
- src/entities/bot.gd
- src/entities/projectile.gd

## New Files (if any)
- tools/run_headless_matches.gd

## Forbidden Files
- scenes/*.tscn
- autoload/GameState.gd (read-only reference)
- autoload/DataLoader.gd (read-only reference)
- Any UI-related files

## Acceptance Criteria
- [ ] AC1: Runs 10 matches with fixed seeds without crashes
- [ ] AC2: Outputs JSON report with all required fields
- [ ] AC3: Exits with code 0 on success, nonzero on failure
- [ ] AC4: Runs in --headless mode (no display required)
- [ ] AC5: Completes within 60 seconds total

## Tests Required
- [ ] test1: Verify report JSON schema is valid
- [ ] test2: Verify crash detection works (inject error)
- [ ] test3: Verify deterministic (same seed = same result)

## Run Command
```
tools/dev_gate.ps1   # Windows
tools/dev_gate.sh    # Mac/Linux
```

## Notes
- Invariants: See agents/context/invariants.md
- Deterministic simulation must remain deterministic
- Use existing SimulationManager.headless flag
- Hook into battle_ended signal for completion detection
