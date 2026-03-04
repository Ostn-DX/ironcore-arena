## ID
TICKET-003

## Title
Create gate scripts for automated validation

## Goal
Create PowerShell and Bash scripts that run all validation tools and fail fast on errors.

## Allowed Files (edit allowlist)
- None (creating new files only)

## New Files (if any)
- tools/dev_gate.ps1
- tools/dev_gate.sh

## Forbidden Files
- All existing project files (read-only reference)

## Acceptance Criteria
- [ ] AC1: PowerShell script runs on Windows with Godot installed
- [ ] AC2: Bash script runs on Mac/Linux with Godot installed
- [ ] AC3: Both scripts execute headless matches first
- [ ] AC4: Both scripts execute UI smoke second (only if matches pass)
- [ ] AC5: Clear pass/fail output with specific failure location
- [ ] AC6: Returns exit code 0 on full pass, nonzero on any failure

## Tests Required
- [ ] test1: Verify script fails when headless runner crashes
- [ ] test2: Verify script fails when UI smoke fails
- [ ] test3: Verify script passes when both succeed

## Run Command
```
tools/dev_gate.ps1   # Windows
tools/dev_gate.sh    # Mac/Linux
```

## Notes
- Invariants: See agents/context/invariants.md
- Scripts must be executable (chmod +x for .sh)
- Godot executable must be in PATH or use common paths
- Create reports/ directory if missing
- Scripts should work from any working directory
