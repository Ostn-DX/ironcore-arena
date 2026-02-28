## ID
TICKET-005

## Title
Create output normalizer tool

## Goal
Implement Python script that validates and normalizes agent deliverables.

## Allowed Files (edit allowlist)
- agents/TICKET_TEMPLATE.md

## New Files (if any)
- tools/normalize_agent_output.py

## Forbidden Files
- All project source files
- agent_runs/* (reads only)

## Acceptance Criteria
- [ ] AC1: Validates required directory structure (NEW_FILES, MODIFICATIONS, TESTS)
- [ ] AC2: Validates required files (INTEGRATION_GUIDE.md, CHANGELOG.md)
- [ ] AC3: Rejects TODO/FIXME stubs in GDScript files
- [ ] AC4: Rejects modifications to forbidden files (outside allowlist)
- [ ] AC5: Generates validation report in reports/
- [ ] AC6: Exits with code 0 on pass, nonzero on fail

## Tests Required
- [ ] test1: Create valid output, verify pass
- [ ] test2: Add TODO stub, verify fail
- [ ] test3: Touch forbidden file, verify fail

## Run Command
```
python tools/normalize_agent_output.py TICKET-001
```

## Notes
- This is a meta-tool for the agent workflow
- Must run after agent produces output
- Validates deliverable contract
