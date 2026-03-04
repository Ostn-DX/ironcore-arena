## ID
TICKET-004

## Title
Create context pack builder tool

## Goal
Implement Python script that builds minimal deterministic context packs from tickets.

## Allowed Files (edit allowlist)
- agents/context/invariants.md
- agents/context/project_summary.md
- agents/context/conventions.md

## New Files (if any)
- tools/build_context_pack.py

## Forbidden Files
- All project source files
- Any Godot files

## Acceptance Criteria
- [ ] AC1: Parses ticket file for ID, title, goal, allowlist
- [ ] AC2: Copies context files (invariants, summary, conventions)
- [ ] AC3: Copies all allowlisted files into pack
- [ ] AC4: Creates pack_metadata.txt with summary
- [ ] AC5: Handles missing files with clear warnings

## Tests Required
- [ ] test1: Run on TICKET-001.md, verify output structure
- [ ] test2: Verify missing file warning works
- [ ] test3: Verify pack_metadata.txt is complete

## Run Command
```
python tools/build_context_pack.py agents/tickets/TICKET-001.md
```

## Notes
- This is a meta-tool for the agent workflow
- Must run before any agent implementation
- Context packs go to tools/context_packs/<ticket_id>/
