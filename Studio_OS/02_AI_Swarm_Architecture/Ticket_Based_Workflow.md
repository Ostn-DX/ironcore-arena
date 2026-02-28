---
title: Ticket_Based_Workflow
type: system
layer: execution
status: active
tags:
  - workflow
  - tickets
  - process
  - agile
depends_on: []
used_by:
  - "[Agent_Swarm_Architecture]"
---

# Ticket Based Workflow

## Purpose
Ensure every change is scoped, documented, and validated before integration. Prevents scope creep and broken builds.

## Core Rules

### Ticket Template
```markdown
## ID
TICKET-XXX

## Title
Clear, actionable description

## Goal
One sentence objective

## Allowed Files
- path/to/file.gd
- path/to/file2.gd

## New Files
- new_file.gd

## Forbidden Files
- autoload/GameState.gd
- scenes/*.tscn

## Acceptance Criteria
- [ ] AC1: Specific, testable condition
- [ ] AC2: Another condition

## Run Command
./tools/dev_gate.sh
```

### One Ticket at a Time
- Complete current ticket before starting next
- No multi-initiative changes
- No "while I'm here" edits
- Gate must pass before ticket complete

### File Allowlist Enforcement
- Agent can ONLY edit allowed files
- Any other edit = hard failure
- Forbidden files explicitly listed

### Ticket Lifecycle
```
1. Create ticket
2. Build context pack
3. Agent implements
4. Normalize output
5. Human integrates
6. Run gate
7. Gate pass → commit
8. Gate fail → fix → re-run
```

## Failure Modes

### Scope Creep
**Symptom:** Ticket grows during implementation
**Prevention:** Strict allowlist, human review

### Integration Failure
**Symptom:** Agent output doesn't work when integrated
**Prevention:** Mandatory gate run

### Orphan Tickets
**Symptom:** Tickets created but never completed
**Prevention:** Ticket queue limit (max 10 open)

## Related
[[Ticket_Template_Structure]]
[[Context_Pack_System]]
[[Output_Normalization]]
