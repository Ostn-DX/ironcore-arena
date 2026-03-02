---
title: Autonomy Upgrade Path
type: system
layer: execution
status: active
tags:
  - autonomy
  - upgrade
  - path
  - promotion
  - L2
  - L3
  - L4
  - L5
depends_on:
  - "[Autonomy_Ladder_L0_L5]]"
  - "[[Autonomy_Score_Rubric]]"
  - "[[L2_Supervised_Autonomy]]"
  - "[[L3_Conditional_Autonomy]]"
  - "[[L4_High_Autonomy]]"
  - "[[L5_Full_Autonomy]"
used_by:
  - "[Intent_to_Release_Pipeline]]"
  - "[[OpenClaw_Core_System]"
---

# Autonomy Upgrade Path

## Purpose

This document defines the concrete steps for promoting work from lower to higher autonomy levels. It provides measurable criteria, required actions, and validation steps for each level transition.

## Upgrade Philosophy

Autonomy upgrades are earned, not granted. Higher autonomy requires demonstrated competence at lower levels. The upgrade path ensures:
- Quality is maintained or improved
- Risk is managed
- Human trust is built
- System capabilities are proven

## Upgrade Path Overview

```
                    L5: FULL AUTONOMY
                         ▲
                         │ Requires: 10 L4 milestones,
                         │   95% approval, monitoring
                         │
                    L4: HIGH AUTONOMY
                         ▲
                         │ Requires: 20 L3 tickets,
                         │   95% gate pass, <5% escalation
                         │
                    L3: CONDITIONAL AUTONOMY
                         ▲
                         │ Requires: 10 L2 tickets,
                         │   90% checkpoint approval,
                         │   auto-gates defined
                         │
                    L2: SUPERVISED AUTONOMY
                         ▲
                         │ Requires: 5 L1 tickets,
                         │   70% suggestion acceptance
                         │
                    L1: ASSISTED OPERATION
                         ▲
                         │ Requires: L0 completion,
                         │   pattern documentation
                         │
                    L0: MANUAL OPERATION
```

## L2 → L3 Upgrade Path

### Prerequisites
- Minimum 10 successful L2 completions
- Checkpoint approval rate ≥90%
- Pattern documented
- Human approves upgrade

### Required Actions

#### Step 1: Define Automated Gates (Week 1)
- [ ] Identify all validation points
- [ ] Convert human judgment gates to automated gates
- [ ] Define explicit pass/fail criteria for each gate
- [ ] Test gates on historical data
- [ ] Document gate definitions

**Deliverable**: Gate definition document with 3-5 automated gates

#### Step 2: Implement Auto-Remediation (Week 1-2)
- [ ] Identify top 3 failure modes
- [ ] Define remediation actions for each
- [ ] Implement auto-remediation logic
- [ ] Test remediation on historical failures
- [ ] Set max attempt limits

**Deliverable**: Auto-remediation configuration

#### Step 3: Pilot L3 Operation (Week 2-3)
- [ ] Select 5 low-risk tickets
- [ ] Run at L3 with human monitoring
- [ ] Track all escalations
- [ ] Document any issues
- [ ] Adjust gates based on results

**Deliverable**: Pilot report with metrics

#### Step 4: Validation (Week 3-4)
- [ ] Gate pass rate ≥95%
- [ ] Escalation rate <10%
- [ ] Auto-remediation success ≥70%
- [ ] Human time per ticket <15 minutes
- [ ] No critical issues

**Deliverable**: Validation report

#### Step 5: Approval and Rollout (Week 4)
- [ ] Human reviews validation report
- [ ] Approves L3 for this work type
- [ ] Updates default autonomy
- [ ] Communicates to team

**Deliverable**: Approved autonomy upgrade

### Success Metrics
| Metric | Target | Measurement |
|--------|--------|-------------|
| Gate pass rate | ≥95% | Passed / Total gates |
| Escalation rate | <10% | Escalated / Total tickets |
| Auto-remediation success | ≥70% | Fixed / Attempted |
| Human time per ticket | <15 min | Total human involvement |

## L3 → L4 Upgrade Path

### Prerequisites
- Minimum 20 successful L3 completions
- Gate pass rate ≥95%
- Escalation rate <5%
- Human approves upgrade

### Required Actions

#### Step 1: Define Milestone Criteria (Week 1)
- [ ] Identify natural grouping for tickets
- [ ] Define milestone boundaries (daily/sprint-based)
- [ ] Create milestone review checklist
- [ ] Define approval criteria
- [ ] Document milestone process

**Deliverable**: Milestone definition document

#### Step 2: Implement Batching Logic (Week 1-2)
- [ ] Implement ticket grouping by theme
- [ ] Implement dependency sequencing
- [ ] Implement parallelization logic
- [ ] Create batch optimization rules
- [ ] Test batching on historical tickets

**Deliverable**: Batching configuration

#### Step 3: Create Milestone Report Template (Week 2)
- [ ] Define aggregate metrics to track
- [ ] Create report template
- [ ] Implement report generation
- [ ] Add trend analysis
- [ ] Test report on sample data

**Deliverable**: Milestone report template

#### Step 4: Pilot L4 Operation (Week 2-4)
- [ ] Select 2-3 milestones worth of tickets
- [ ] Run at L4 with human monitoring
- [ ] Track milestone approval rate
- [ ] Document any issues
- [ ] Adjust batch size based on results

**Deliverable**: Pilot report with metrics

#### Step 5: Validation (Week 4-6)
- [ ] Milestone approval rate ≥95%
- [ ] Changes per milestone <15%
- [ ] Escalation rate <5%
- [ ] Human time per ticket <10 minutes
- [ ] No critical issues

**Deliverable**: Validation report

#### Step 6: Approval and Rollout (Week 6)
- [ ] Human reviews validation report
- [ ] Approves L4 for this work type
- [ ] Updates default autonomy
- [ ] Communicates to team

**Deliverable**: Approved autonomy upgrade

### Success Metrics
| Metric | Target | Measurement |
|--------|--------|-------------|
| Milestone approval rate | ≥95% | Approved / Total |
| Changes per milestone | <15% | Changed / Total tickets |
| Escalation rate | <5% | Escalated / Total tickets |
| Human time per ticket | <10 min | Total human involvement |

## L4 → L5 Upgrade Path

### Prerequisites
- Minimum 10 successful L4 milestones
- Milestone approval rate ≥95%
- Changes per milestone <10%
- Comprehensive monitoring in place
- Human approves upgrade

### Required Actions

#### Step 1: Define Exception Boundaries (Week 1)
- [ ] Identify all possible failure modes
- [ ] Classify each as normal or exception
- [ ] Define exception detection rules
- [ ] Set boundary thresholds
- [ ] Document exception types

**Deliverable**: Exception boundary document

#### Step 2: Implement Self-Monitoring (Week 1-2)
- [ ] Define health metrics
- [ ] Implement metric collection
- [ ] Create anomaly detection
- [ ] Set alert thresholds
- [ ] Create health dashboard

**Deliverable**: Self-monitoring system

#### Step 3: Implement Self-Healing (Week 2-3)
- [ ] Identify self-healable issues
- [ ] Implement remediation actions
- [ ] Add retry logic with backoff
- [ ] Test self-healing scenarios
- [ ] Document self-healing capabilities

**Deliverable**: Self-healing configuration

#### Step 4: Create Kill Switches (Week 3)
- [ ] Implement emergency stop
- [ ] Implement per-domain stop
- [ ] Implement graceful shutdown
- [ ] Test all kill switches
- [ ] Document kill switch procedures

**Deliverable**: Kill switch system

#### Step 5: Pilot L5 Operation (Week 3-5)
- [ ] Run L5 during low-risk period
- [ ] Human on-call for exceptions
- [ ] Track all exceptions
- [ ] Document exception handling
- [ ] Adjust boundaries based on results

**Deliverable**: Pilot report with metrics

#### Step 6: Validation (Week 5-8)
- [ ] Uptime ≥99.9%
- [ ] Exception rate <0.5%
- [ ] Self-healing success ≥90%
- [ ] Human interventions <2 per week
- [ ] No safety incidents

**Deliverable**: Validation report

#### Step 7: Approval and Rollout (Week 8)
- [ ] Human reviews validation report
- [ ] Approves L5 for this work type
- [ ] Updates default autonomy
- [ ] Establishes on-call rotation
- [ ] Communicates to team

**Deliverable**: Approved autonomy upgrade

### Success Metrics
| Metric | Target | Measurement |
|--------|--------|-------------|
| Uptime | ≥99.9% | Operational / Total time |
| Exception rate | <0.5% | Exceptions / Total operations |
| Self-healing success | ≥90% | Fixed / Detected |
| Human interventions | <2/week | Exceptions requiring human |

## Upgrade Validation Checklist

### Before Upgrade
- [ ] All prerequisites met
- [ ] Required actions completed
- [ ] Success metrics achieved
- [ ] No outstanding issues
- [ ] Human approves

### During Upgrade
- [ ] Monitor closely for first 10 operations
- [ ] Track all metrics
- [ ] Document any issues
- [ ] Be ready to rollback

### After Upgrade
- [ ] Continue monitoring for 30 days
- [ ] Review metrics weekly
- [ ] Adjust based on learnings
- [ ] Document lessons learned

## Rollback Criteria

Downgrade if:
- Success metrics not met after 30 days
- Critical issue occurs
- Human confidence decreases
- Pattern stability degrades

Rollback process:
1. Immediate downgrade to previous level
2. Root cause analysis
3. Issue resolution
4. Re-validation
5. Re-upgrade when ready

## Upgrade Tracking

Track all upgrades:
```yaml
upgrade:
  work_type: [Type of work]
  from_level: [L0/L1/L2/L3/L4]
  to_level: [L1/L2/L3/L4/L5]
  date: [Upgrade date]
  
  prerequisites:
    - [List of prerequisites met]
  
  metrics_at_upgrade:
    - metric: [Name]
      value: [Value]
  
  approved_by: [Human approver]
  
  post_upgrade_monitoring:
    30_day_metrics: [Results]
    issues: [Any issues]
    rollback: [true/false]
```

## Enforcement

- Upgrades MUST follow defined path
- Prerequisites MUST be verified
- Human approval REQUIRED for all upgrades
- Metrics MUST be tracked
- Rollback MUST be possible
