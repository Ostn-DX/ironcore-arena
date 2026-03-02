---
title: Agent_Swarm_Architecture
type: system
layer: architecture
status: active
tags:
  - agents
  - swarm
  - orchestration
  - workflow
depends_on:
  - "[Ticket_Based_Workflow]]"
  - "[[Context_Pack_System]]"
  - "[[Output_Normalization]"
used_by:
  - "[Architect_Agent]]"
  - "[[Implementation_Agent]]"
  - "[[Validation_Agent]"
---

# Agent Swarm Architecture

## Purpose
Coordinate multiple specialized AI agents to implement complex features while maintaining code quality, determinism, and playability.

## Core Rules

### Agent Types

| Agent | Responsibility | Authority | Outputs |
|-------|---------------|-----------|---------|
| **Architect** | System design, interfaces | Can modify any file | Design docs, skeletons |
| **Implementer** | Code implementation | Allowlist only | Production code |
| **Validator** | Testing, edge cases | Read-only | Test suites |
| **Reviewer** | Code review | Read-only | Review comments |
| **Balancer** | Game balance analysis | Read-only | Reports, recommendations |

### One Ticket at a Time
- Single scoped ticket per execution
- No multi-initiative changes
- No "while I'm here" refactors
- Complete ticket → Gate pass → Next ticket

### File Allowlist Enforcement
```yaml
TICKET-001:
  allowed:
    - autoload/SimulationManager.gd
    - src/ai/tactical_ai.gd
  forbidden:
    - scenes/*.tscn
    - autoload/GameState.gd
```

Any attempt to touch forbidden files = hard failure

### Context Pack System
```
Input: Ticket file
↓
Context Pack Builder
↓
Output: tools/context_packs/TICKET-XXX/
  - invariants.md
  - project_summary.md
  - conventions.md
  - allowlisted_files/
  - ticket.md
```

Agent receives only the context pack — no full repo access

### Output Normalization
Agent must produce:
```
agent_runs/TICKET-XXX/
├── NEW_FILES/           # Complete implementations
├── MODIFICATIONS/       # Diffs for existing files
├── TESTS/              # Test files
├── INTEGRATION_GUIDE.md # Step-by-step
└── CHANGELOG.md        # Summary
```

Validator checks:
- No TODO/FIXME stubs
- No edits outside allowlist
- All files present
- Follows conventions

## Failure Modes

### Scope Creep
**Symptom:** Agent modifies files not in allowlist
**Prevention:** File watcher validates all writes

### Context Overflow
**Symptom:** Agent receives too much context, produces confused output
**Prevention:** Context pack limited to 5000 tokens

### Integration Failure
**Symptom:** Agent output doesn't integrate cleanly
**Prevention:** Mandatory gate run after integration

### Agent Loop
**Symptom:** Agent A fixes what Agent B broke, cycle repeats
**Prevention:** Human review for conflicting tickets

## Enforcement

### Orchestration Rules
1. Architect designs → Implementer builds → Validator tests
2. No agent skips gate
3. Failed gate = return to implementer
4. Human arbitrates agent conflicts

### Quality Thresholds
- Gate pass rate: 100%
- Test coverage: >80% for new systems
- Type safety: 100% (no untyped functions)
- Determinism: Verified for sim changes

## Related
[[Ticket_Template_Structure]]
[[Context_Pack_Builder]]
[[Output_Normalizer]]
[[Agent_Communication_Protocol]]
[[Human_In_The_Loop_Policy]]
