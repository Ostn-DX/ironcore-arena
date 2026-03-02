---
title: Escalation_Triggers
type: template
layer: execution
status: active
tags:
  - template
  - escalation
  - automation
  - rules
depends_on: []
used_by:
  - "[Daily_Operator_Protocol]"
---

# Escalation Triggers

## Purpose
Clear criteria for when OpenClaw stops and human takes over. Prevents runaway costs and quality degradation.

## Auto-Escalation Triggers

### Cost Triggers

| Trigger | Condition | Action |
|---------|-----------|--------|
| **Budget warning** | 75% of monthly budget used | Notify human |
| **Budget critical** | 90% of monthly budget used | Halt non-essential |
| **Ticket overflow** | 2x estimated cost | Pause, human decision |
| **Daily limit** | Exceed 150% of daily average | Review before continue |

### Quality Triggers

| Trigger | Condition | Action |
|---------|-----------|--------|
| **Gate failure** | 3 consecutive failures | Human review |
| **Determinism break** | Any determinism test fail | Immediate human |
| **Test coverage drop** | Coverage < 70% | Request more tests |
| **Revert rate** | >30% of commits are reverts | Process review |

### System Triggers

| Trigger | Condition | Action |
|---------|-----------|--------|
| **Agent conflict** | Agents produce conflicting outputs | Human arbitration |
| **Circular dependency** | Ticket A depends on B, B on A | Human redesign |
| **Scope explosion** | Ticket grows 2x original scope | Scope review |
| **Unknown error** | Error not in known categories | Human investigation |

## Escalation Levels

### Level 1: Notification (Continue)
Human notified, agent continues.
- Cost approaching budget
- Minor test failures
- Warnings from tools

### Level 2: Pause (Review Required)
Agent pauses, human must approve continue.
- Ticket cost 1.5x estimate
- Gate failure on retry
- Determinism warning

### Level 3: Halt (Human Takeover)
Agent stops, human must resolve.
- Budget exceeded
- Critical system failure
- Agent stuck in loop

## Response Protocol

### When Escalated

```markdown
## Escalation Report: TICKET-XXX

**Trigger:** [Cost/Quality/System]
**Severity:** [1/2/3]
**Condition:** [Specific trigger met]

**Current State:**
- Cost: $X.XX / $Y.YY estimated
- Iterations: N
- Gate status: [PASS/FAIL]
- Blockers: [List]

**Options:**
1. [Option with cost/risk]
2. [Option with cost/risk]
3. [Option with cost/risk]

**Recommendation:** [Agent recommendation]

**Awaiting human decision.**
```

### Human Response Options

| Response | Action |
|----------|--------|
| **CONTINUE** | Resume agent work |
| **ADJUST** | Modify ticket, retry |
| **ESCALATE** | Route to architect |
| **ABORT** | Cancel ticket, rollback |
| **MANUAL** | Human takes over implementation |

## Prevention

### Before Escalation
Agent must try:
1. Retry with clearer instructions
2. Reduce scope
3. Change model/tier
4. Request clarification

### Self-Healing
Some issues auto-resolve:
- Transient failures (network, API)
- Minor formatting issues
- Missing imports (auto-add)

## Metrics

Track escalation rates:
| Metric | Target | Review if |
|--------|--------|-----------|
| Escalations/week | < 2 | > 5 |
| Cost escalations | < 20% | > 40% |
| Quality escalations | < 10% | > 25% |

## Related
[[Gate_Failure_Response_Playbook]]
[[Patch_Protocol]]
