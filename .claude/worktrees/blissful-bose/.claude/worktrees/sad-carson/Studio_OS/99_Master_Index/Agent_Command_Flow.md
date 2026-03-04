---
title: Agent_Command_Flow
type: index
layer: architecture
status: active
tags:
  - index
  - workflow
  - agents
  - orchestration
depends_on: []
used_by: []
---

# Agent Command Flow

## Overview

The AI-native game studio operates on a deterministic workflow loop. Human intent flows through architecture to implementation to validation to certification.

## The Loop

```
┌─────────────────────────────────────────────────────────────┐
│  HUMAN INTENT                                               │
│  "Add tactical AI with cover system"                        │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  TICKET CREATION                                            │
│  Create TICKET-001 with:                                    │
│  - Explicit allowlist                                       │
│  - Acceptance criteria                                      │
│  - Forbidden files                                          │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  CONTEXT PACK                                               │
│  tools/build_context_pack.py                                │
│  Extracts relevant code, invariants, conventions            │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  ARCHITECT AGENT                                            │
│  Inputs: Ticket + Context Pack                              │
│  Outputs: Design doc, skeleton code, integration points     │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  IMPLEMENTATION AGENT                                       │
│  Inputs: Architecture spec                                  │
│  Outputs: NEW_FILES/, MODIFICATIONS/, INTEGRATION_GUIDE.md  │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  OUTPUT NORMALIZATION                                       │
│  tools/normalize_agent_output.py                            │
│  Validates: No TODOs, no forbidden edits, complete files    │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  HUMAN INTEGRATION                                          │
│  Apply changes per INTEGRATION_GUIDE.md                     │
│  Copy NEW_FILES, apply MODIFICATIONS                        │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  VALIDATION AGENT                                           │
│  Inputs: Integrated code                                    │
│  Outputs: TESTS/, test results                              │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  DEV GATE                                                   │
│  tools/dev_gate.sh                                          │
│  - Headless match tests (10 battles)                        │
│  - UI smoke tests (full navigation)                         │
│  Must pass with 0 failures                                  │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  CERTIFICATION                                              │
│  Release criteria validation                                │
│  All tests pass, metrics met                                │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  COMMIT & DEPLOY                                            │
│  git commit -m "TICKET-001: Tactical AI"                    │
│  CI runs gate, merges if passed                             │
└─────────────────────────────────────────────────────────────┘
```

## Agent Responsibilities

### Architect Agent
- **Authority**: Can read any file, suggest any architecture
- **Outputs**: Design documents, interfaces, skeleton code
- **Constraints**: No implementation details, no optimization

### Implementation Agent
- **Authority**: Only files in ticket allowlist
- **Outputs**: Production-ready GDScript
- **Constraints**: No "while I'm here" changes, complete implementations only

### Validation Agent
- **Authority**: Read-only access
- **Outputs**: Test suites, edge case documentation
- **Constraints**: No code changes, only test files

### Balancer Agent
- **Authority**: Read-only access, JSON recommendations
- **Outputs**: Balance reports, tuning suggestions
- **Constraints**: No gameplay code changes

## Quality Gates

### Gate 1: Output Normalization
```
Input: agent_runs/TICKET-XXX/
Checks:
  ✓ All required files present
  ✓ No TODO/FIXME stubs
  ✓ No edits outside allowlist
  ✓ Follows naming conventions
Output: Normalized or REJECTED
```

### Gate 2: Dev Gate
```
Input: Integrated code
Checks:
  ✓ Headless matches pass (10/10)
  ✓ UI smoke tests pass (6/6)
  ✓ No crashes, no timeouts
Output: PASS or FAIL (with specifics)
```

### Gate 3: Release Certification
```
Input: All features complete
Checks:
  ✓ All automated tests pass
  ✓ Performance targets met
  ✓ Code review completed
  ✓ Documentation updated
Output: CERTIFIED or BLOCKED
```

## Escalation Conditions

| Issue | Escalate To | Action |
|-------|-------------|--------|
| Architecture conflict | Human Architect | Override decision |
| Determinism break | Determinism Agent | Audit all RNG usage |
| Performance regression | Performance Agent | Profile and optimize |
| Test failure | Validation Agent | Add regression test |
| Balance issue | Balancer Agent | Statistical analysis |

## Human Intervention Points

1. **Ticket Creation**: Human defines scope and allowlist
2. **Architecture Review**: Human approves design before implementation
3. **Integration**: Human applies agent output to codebase
4. **Gate Failure**: Human decides fix vs. redesign
5. **Conflict Resolution**: Human arbitrates agent disagreements

## Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Gate pass rate | >95% | TBD |
| Tickets per week | 5-10 | TBD |
| Integration time | <30 min | TBD |
| Agent conflicts | <5% | TBD |

## Related

[[Agent_Swarm_Architecture]]
[[Ticket_Based_Workflow]]
[[Dev_Gate_Validation_System]]
[[Release_Certification_Criteria]]
