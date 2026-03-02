---
title: Autonomy Ladder L0-L5
type: system
layer: architecture
status: active
tags:
  - autonomy
  - ladder
  - levels
  - capabilities
  - requirements
depends_on:
  - "[Studio_OS_Overview]]"
  - "[[Studio_Priorities_Manifesto]"
used_by:
  - "[Intent_to_Release_Pipeline]]"
  - "[[Decision_Making_Protocols]]"
  - "[[Governance_and_Authority_Boundaries]]"
  - "[[Autonomy_Score_Rubric]]"
  - "[[L0_Manual_Operation]]"
  - "[[L1_Assisted_Operation]]"
  - "[[L2_Supervised_Autonomy]]"
  - "[[L3_Conditional_Autonomy]]"
  - "[[L4_High_Autonomy]]"
  - "[[L5_Full_Autonomy]]"
  - "[[Autonomy_Upgrade_Path]"
---

# Autonomy Ladder L0-L5

## Overview

The Autonomy Ladder defines six levels of operational independence for the Studio OS. Each level specifies what the system can do without human involvement, what requires human approval, and the prerequisites for operating at that level.

## Ladder Summary

| Level | Name | Human Role | System Role | Typical Use Case |
|-------|------|------------|-------------|------------------|
| L0 | Manual Operation | Full control | None | Exploration, learning, emergency |
| L1 | Assisted Operation | Drives, AI assists | Suggestions, automation | New domains, complex decisions |
| L2 | Supervised Autonomy | AI drives, human reviews | Execution with checkpoints | Standard development, established patterns |
| L3 | Conditional Autonomy | Available for escalation | Self-directed with auto-gates | Routine work, proven domains |
| L4 | High Autonomy | Milestone checkpoints | Full pipeline execution | Production workflows, mature systems |
| L5 | Full Autonomy | Exception handling only | Self-operating, self-healing | 24/7 operations, well-understood domains |

## Detailed Level Definitions

### L0: Manual Operation
**Human**: Executes all work directly
**System**: Provides tools but no automation
**Prerequisites**: None
**Escalation**: N/A (already at minimum autonomy)

**Capabilities**:
- Human uses IDE, asset tools, build systems directly
- System provides documentation and reference materials
- No automated execution

**Use When**:
- Learning new technology
- Emergency situations requiring direct control
- Tasks too novel for any automation
- Debugging system behavior

### L1: Assisted Operation
**Human**: Drives execution, makes all decisions
**System**: Provides suggestions, automates sub-tasks
**Prerequisites**: Tooling available, basic context loaded
**Escalation**: Automatic for any ambiguity

**Capabilities**:
- AI suggests approaches based on context
- Automates repetitive sub-tasks (formatting, renaming)
- Generates boilerplate from templates
- Human approves every significant action

**Use When**:
- Working in unfamiliar domain
- High-stakes decisions
- First-time implementation of pattern
- Human wants to learn while doing

### L2: Supervised Autonomy
**Human**: Reviews checkpoints, approves progression
**System**: Executes work, pauses at defined points
**Prerequisites**: Established patterns, clear acceptance criteria
**Escalation**: At every checkpoint, on any error

**Capabilities**:
- AI executes multi-step work
- Pauses at gates for human review
- Human must explicitly approve to continue
- Full context provided at each checkpoint

**Use When**:
- Standard development work
- Well-understood problem domain
- First runs of new automation
- Building trust in system capabilities

### L3: Conditional Autonomy
**Human**: Available for escalation, not required for normal flow
**System**: Self-directs execution, auto-passes defined gates
**Prerequisites**: Proven track record at L2, automated gates defined
**Escalation**: On gate failure without remediation path, on cost threshold

**Capabilities**:
- AI executes full pipeline stages without pause
- Automated gates validate output
- Auto-remediation for known failure modes
- Human notified of progress, can interrupt

**Use When**:
- Routine, repetitive work
- Established patterns with high success rate
- Time-sensitive operations
- Human availability limited

### L4: High Autonomy
**Human**: Involved at milestones only
**System**: Manages full workflows, aggregates for review
**Prerequisites**: Sustained success at L3, milestone gates defined
**Escalation**: At milestones, on exception conditions

**Capabilities**:
- AI manages multiple related tickets
- Batches work for milestone review
- Self-prioritizes within constraints
- Human reviews aggregated results

**Use When**:
- Production development workflows
- Mature systems with established patterns
- High-volume operations
- Human time best spent on review, not direction

### L5: Full Autonomy
**Human**: Exception handling only
**System**: Self-operating, self-monitoring, self-healing
**Prerequisites**: Proven reliability at L4, comprehensive monitoring
**Escalation**: Only on unhandled exceptions

**Capabilities**:
- AI operates continuously without human involvement
- Self-detects and resolves issues
- Maintains operations within defined boundaries
- Escalates only true exceptions

**Use When**:
- 24/7 operations (build servers, monitoring)
- Extremely well-understood domains
- Human unavailable (nights, weekends)
- Maximum efficiency required

## Autonomy Level Determination

The system determines appropriate autonomy level based on:

### Context Factors
- **Domain Familiarity**: Has this type of work been done before?
- **Pattern Maturity**: Are established patterns available?
- **Risk Level**: What's the blast radius of failure?
- **Stakeholder Impact**: Who/what is affected by this work?
- **Reversibility**: Can changes be easily undone?

### Historical Factors
- **Success Rate**: Historical pass rate for similar work
- **Time Since Last Failure**: Recency of issues
- **Complexity Score**: Measured complexity of task
- **Cost History**: Typical resource consumption

### Override Rules
- Human can specify minimum autonomy level in ticket
- Human can force escalation at any time
- System can downgrade autonomy based on detected risk
- Cost thresholds can force downgrade regardless of other factors

## Level Transitions

### Promotion Criteria
To advance from L(N) to L(N+1):
- Minimum 10 successful completions at current level
- Zero escalations in last 5 operations
- Gate pass rate > 95%
- Cost within expected bounds
- Human explicitly approves promotion

### Demotion Triggers
Demote from L(N) to L(N-1) when:
- 2 consecutive gate failures
- Escalation rate exceeds 20%
- Cost exceeds 150% of estimate
- Human requests demotion
- New risk factor detected

## Visual Ladder

```
                    L5: FULL AUTONOMY
                    ┌─────────────┐
                    │  Exception  │
                    │  Handling   │
                    │    Only     │
                    └──────┬──────┘
                           │ Requires: Proven L4, monitoring
                           ▼
                    L4: HIGH AUTONOMY
                    ┌─────────────┐
                    │  Milestone  │
                    │   Reviews   │
                    │   Only      │
                    └──────┬──────┘
                           │ Requires: Proven L3, milestones defined
                           ▼
                    L3: CONDITIONAL AUTONOMY
                    ┌─────────────┐
                    │  Available  │
                    │   for Esc.  │
                    │  Not Required
                    └──────┬──────┘
                           │ Requires: Proven L2, auto-gates
                           ▼
                    L2: SUPERVISED AUTONOMY
                    ┌─────────────┐
                    │  AI Drives  │
                    │ Human Reviews
                    │ Checkpoints │
                    └──────┬──────┘
                           │ Requires: Established patterns
                           ▼
                    L1: ASSISTED OPERATION
                    ┌─────────────┐
                    │ Human Drives│
                    │  AI Assists │
                    └──────┬──────┘
                           │ Requires: Tooling available
                           ▼
                    L0: MANUAL OPERATION
                    ┌─────────────┐
                    │  Full Human │
                    │   Control   │
                    └─────────────┘
```

## Enforcement

- Autonomy level MUST be explicitly stated on every ticket
- System MUST respect autonomy level boundaries
- Human MUST be notified of any autonomy level changes
- All level transitions MUST be logged with justification
