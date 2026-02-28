## Headless Match Runner

Creates: res://tools/run_headless_matches.gd

Requirements:
- Initialize autoloads (DataLoader/GameState/SimulationManager)
- Run N matches AI vs AI with fixed seed list
- Output JSON report to /reports/match_report.json
- Exit nonzero on crash, invalid state, or failed assertions

Report fields:
- git sha/version string
- seeds used
- crash count
- timeout count/rate
- average battle duration
- win rates by AI profile
- any error strings collected

Implementation notes:
- Use SimulationManager.headless mode
- Fixed seeds for reproducibility
- Hook into SimulationManager signals for battle events
- Collect stats per match, aggregate at end
