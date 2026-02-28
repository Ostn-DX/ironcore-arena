---
title: Daily_Operator_Protocol
type: system
layer: execution
status: active
tags:
  - protocol
  - daily
  - operations
  - workflow
depends_on:
  - "[Autonomy_Ladder_L0_to_L5]"
used_by: []
---

# Daily Operator Protocol

## Purpose
Minimize human involvement while maintaining quality and control. Target: <15 minutes per development day.

## Daily Workflow

### Morning (5 minutes)

```bash
# 1. Review overnight status
python tools/daily_report.py

# Output:
# - Tickets completed: N
# - Gates passed/failed: X/Y
# - Cost: $X.XX / $Y.YY budget
# - Escalations: N
```

**Human Actions:**
- [ ] Review escalations (if any)
- [ ] Approve auto-integrations (L3+)
- [ ] Check budget status

### Mid-Day (5 minutes)

```bash
# 2. Create or prioritize tickets
# Human creates 1-3 new tickets based on goals

# Template:
# - Clear allowlist
# - Acceptance criteria
# - Estimated cost
```

**Human Actions:**
- [ ] Create tickets for priority work
- [ ] Review agent output from morning
- [ ] Approve/reject integration

### Evening (5 minutes)

```bash
# 3. End-of-day summary
python tools/eod_report.py

# Output:
# - Progress toward goals
# - Blockers for tomorrow
# - Cost summary
```

**Human Actions:**
- [ ] Review day's progress
- [ ] Set priorities for tomorrow
- [ ] Approve any pending integrations

## Weekly Consolidation (30 minutes)

### Friday Afternoon

```bash
# 1. Weekly metrics
python tools/weekly_report.py

# Output:
# - Tickets completed: N
# - Cost: $X.XX
# - Quality score: X/100
# - Autonomy level: L2 (66/100)
```

**Human Actions:**
- [ ] Review weekly metrics
- [ ] Update cost assumptions if needed
- [ ] Plan next week's tickets
- [ ] Calibrate models if variance >20%

## Human Intervention Triggers

### Immediate (Stop Everything)
- Gate fails 3x on same ticket
- Budget exceeded
- Determinism break
- Security concern

### Same Day (Review Required)
- Escalation Level 2+
- Cost 2x estimate
- Quality score <70
- Agent conflict

### Weekly (Plan Adjust)
- Velocity off target
- Cost variance >30%
- Quality trend down
- Scope change needed

## Automation Levels

### Current (L2): Supervised
| Task | Human | OpenClaw |
|------|-------|----------|
| Create tickets | ✓ | Suggests |
| Build context | | ✓ |
| Implement | | ✓ |
| Integrate | ✓ | Prepares |
| Run gate | ✓ | Executes |
| Commit | ✓ | Recommends |

### Target (L4): High Autonomy
| Task | Human | OpenClaw |
|------|-------|----------|
| Create tickets | Approve | ✓ Drafts |
| Build context | | ✓ |
| Implement | | ✓ |
| Integrate | Review | ✓ Auto |
| Run gate | | ✓ |
| Commit | Approve | ✓ Auto |

## Commands Quick Reference

```bash
# Daily status
./tools/daily_report.sh

# Create ticket from template
cp Studio_OS/10_Templates_and_Checklists/Ticket_Template.md agents/tickets/TICKET-XXX.md

# Build context pack
python tools/build_context_pack.py agents/tickets/TICKET-XXX.md

# Validate agent output
python tools/normalize_agent_output.py TICKET-XXX

# Run gate
./tools/dev_gate.sh

# Weekly calibration
python tools/weekly_calibration.py
```

## Time Budget

| Activity | Current (L2) | Target (L4) |
|----------|--------------|-------------|
| Morning review | 5 min | 2 min |
| Ticket creation | 5 min | 1 min |
| Integration review | 5 min | 2 min |
| Evening summary | 5 min | 2 min |
| Weekly review | 30 min | 10 min |
| **Daily Total** | **20 min** | **7 min** |
| **Weekly Total** | **2.5 hrs** | **1 hr** |

## Escalation Summary

| Level | Response Time | Human Action |
|-------|---------------|--------------|
| 1 | 4 hours | Review if convenient |
| 2 | 1 hour | Respond before continue |
| 3 | 15 min | Immediate attention |
| 4 | Immediate | Drop everything |

## Success Metrics

Track weekly:
- Human time per ticket
- Gate pass rate
- Escalation rate
- Cost per feature
- Quality score

**Targets for L4:**
- < 10 min human time per ticket
- > 95% gate pass rate
- < 5% escalation rate
- Cost within 20% of estimate
- Quality score > 85

## Related
[[Autonomy_Ladder_L0_to_L5]]
[[Autonomy_Scoring_Rubric]]
[[Escalation_Policy]]
