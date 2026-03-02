---
title: Escalation_Policy
type: rule
layer: enforcement
status: active
tags:
  - escalation
  - policy
  - rules
  - autonomy
depends_on:
  - "[Autonomy_Ladder_L0_to_L5]"
used_by:
  - "[Daily_Operator_Protocol]"
---

# Escalation Policy

## Purpose
Clear rules for when OpenClaw must escalate to human. Part of autonomy framework.

## Escalation Levels

### Level 0: Log Only (L5 Autonomy)
Continue execution, log for review.

**Triggers:**
- Minor cost variance (<10%)
- Warnings from tools
- Non-critical suggestions

**Human Action:** None (review in weekly report)

---

### Level 1: Notify (L4 Autonomy)
Notify human, continue execution.

**Triggers:**
- Cost approaching 75% of ticket budget
- Quality warning (test coverage <80%)
- Retry count = 2
- Unusual pattern detected

**Human Action:** Monitor, intervene if desired

---

### Level 2: Pause (L3 Autonomy)
Pause execution, await human input.

**Triggers:**
- Gate failure
- Cost exceeds 125% of estimate
- Determinism warning
- 3 consecutive retries
- Unknown error type

**Human Action:** Provide guidance, approve continue

---

### Level 3: Halt (L2 Autonomy - Current)
Halt execution, human must take over.

**Triggers:**
- Critical gate failure (crash, determinism break)
- Budget exceeded
- Agent conflict detected
- Circular dependency
- Security concern

**Human Action:** Resolve issue, restart or abort

---

### Level 4: Emergency (L1 Autonomy)
Immediate human takeover, potential rollback.

**Triggers:**
- Production impacted
- Data corruption risk
- Security breach
- Budget critical (>90% monthly)

**Human Action:** Emergency response, rollback if needed

## Escalation Decision Matrix

| Condition | L5 | L4 | L3 | L2 | L1 |
|-----------|----|----|----|----|----|
| Gate warning | Log | Notify | Pause | - | - |
| Gate failure | - | - | Pause | Halt | - |
| Cost 75% | Log | Notify | - | - | - |
| Cost 125% | - | - | Pause | Halt | - |
| Budget 90% | - | - | - | Halt | Emergency |
| Unknown error | - | - | Pause | Halt | - |
| Determinism break | - | - | - | Halt | - |
| Security | - | - | - | - | Emergency |

## Escalation Format

```markdown
## ESCALATION: Level [0-4]

**Ticket:** TICKET-XXX
**Trigger:** [Specific condition met]
**Current State:**
- Progress: X%
- Iterations: N
- Cost: $X / $Y estimated
- Blockers: [List]

**Recommended Action:**
[Agent recommendation]

**Options:**
1. [Option 1 with cost/risk]
2. [Option 2 with cost/risk]
3. [Option 3 with cost/risk]

**Awaiting Response:**
- CONTINUE: Resume execution
- ADJUST: Modify approach
- ABORT: Cancel ticket
- MANUAL: Human takes over
```

## Response SLAs

| Level | Response Time | Action |
|-------|---------------|--------|
| 0 | N/A | Auto-continue |
| 1 | 4 hours | Continue if no response |
| 2 | 1 hour | Pause until response |
| 3 | 15 minutes | Halt until resolved |
| 4 | Immediate | Emergency protocols |

## Prevention

### Self-Healing Attempts
Before escalating, agent must try:
1. Retry with modified prompt
2. Reduce scope
3. Change model
4. Request clarification

### Success Criteria
Escalation avoided if:
- Issue resolves within 2 retries
- Alternative approach succeeds
- Human provides guidance that unblocks

## Metrics

Track escalation metrics:
- Escalations per week
- Escalations by level
- Resolution time by level
- False positive rate

**Target:**
- Level 1: <10% of tickets
- Level 2: <5% of tickets
- Level 3: <2% of tickets
- Level 4: <1% of tickets

## Related
[[Autonomy_Ladder_L0_to_L5]]
[[Escalation_Triggers]]
[[Gate_Failure_Response_Playbook]]
