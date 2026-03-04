# Ticket Template

## ID
TICKET-XXX (assign sequential number)

## Title
Brief, actionable description

## Goal
One-sentence objective. What does "done" look like?

## Allowed Files (edit allowlist)
List every file you may edit. No edits outside this list.

- path/to/file1.gd
- path/to/file2.gd
- data/specific.json

## New Files (if any)
Files you will create:

- new_file.gd
- new_file.tscn

## Forbidden Files
Everything not in Allowed Files. Specifically do NOT touch:

- autoload/GameState.gd (unless explicitly allowed)
- data/components.json (unless explicitly allowed)
- Any scene files outside allowlist

## Acceptance Criteria
- [ ] AC1: Specific, testable condition
- [ ] AC2: Another specific condition
- [ ] AC3: Edge case handled

## Tests Required
- [ ] test1: What to verify
- [ ] test2: Another verification

## Run Command
```
tools/dev_gate.ps1   # Windows
tools/dev_gate.sh    # Mac/Linux
```

## Notes
- Invariants: See agents/context/invariants.md
- Conventions: See agents/context/conventions.md
- Related tickets: (optional, for context)

## Definition of Done
Gate script passes with no errors.
