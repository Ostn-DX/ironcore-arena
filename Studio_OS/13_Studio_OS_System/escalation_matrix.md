---
title: Escalation Matrix
type: reference
layer: system
status: active
domain: studio_os
tags:
  - reference
  - studio_os
depends_on: []
used_by: []
---

# Escalation Matrix
## AI-Native Game Studio OS - Escalation & Alerting System

---

## Escalation Levels

| Level | Score Range | Action | Response Time |
|-------|-------------|--------|---------------|
| L0 | 0.00-0.25 | Normal operation | N/A |
| L1 | 0.25-0.45 | Monitor closely | 15 min |
| L2 | 0.45-0.65 | Alert team | 5 min |
| L3 | 0.65-0.85 | Escalate to lead | 2 min |
| L4 | 0.85-1.00 | Critical response | 30 sec |

---

## Escalation Score Formula

```
EscalationScore = Σ(w_i × normalized_factor_i) ∈ [0, 1]

Where:
  w = [0.40, 0.20, 0.15, 0.15, 0.07, 0.03]
  
  f_failure_rate = normalized failure rate
  f_retry_count = normalized retry count
  f_time_in_queue = normalized queue time
  f_risk_score = RiskScore / 100
  f_resource_saturation = current utilization
  f_dependency_failure = binary flag

Thresholds:
  L0: 0.00-0.25 → Normal
  L1: 0.25-0.45 → Watch
  L2: 0.45-0.65 → Alert
  L3: 0.65-0.85 → Escalate
  L4: 0.85-1.00 → Critical
```

---

## Factor Normalization

| Factor | Normalization | Range |
|--------|---------------|-------|
| failure_rate | f / 0.10 (10% max) | [0, 1] |
| retry_count | min(count / 5, 1.0) | [0, 1] |
| time_in_queue | min(time / 240min, 1.0) | [0, 1] |
| risk_score | RiskScore / 100 | [0, 1] |
| resource_saturation | utilization / 100% | [0, 1] |
| dependency_failure | 0 or 1 | {0, 1} |

---

## Notification Matrix

| Level | Channels | Recipients | Frequency |
|-------|----------|------------|-----------|
| L1 | Slack #alerts | Team | Immediate |
| L2 | Slack + Email | Team + Lead | Immediate + 5min |
| L3 | Slack + Email + SMS | Team + Lead + Manager | Immediate + 2min |
| L4 | All + PagerDuty | All + On-call | Immediate + 1min |

---

## Escalation Chain

```
┌─────────────────────────────────────────────────────────────────┐
│                      ESCALATION CHAIN                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  L0 (Normal)                                                     │
│    │                                                             │
│    │ Score > 0.25                                                │
│    ▼                                                             │
│  L1 (Watch) ──► Team Channel                                     │
│    │                                                             │
│    │ Score > 0.45                                                │
│    ▼                                                             │
│  L2 (Alert) ──► Team + Lead ──► 5min reminder                    │
│    │                                                             │
│    │ Score > 0.65                                                │
│    ▼                                                             │
│  L3 (Escalate) ──► Team + Lead + Manager ──► 2min reminder       │
│    │                                                             │
│    │ Score > 0.85                                                │
│    ▼                                                             │
│  L4 (Critical) ──► All + On-call ──► 1min reminder ──► PagerDuty │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Escalation Triggers by Domain

| Domain | Trigger Condition | Escalation Level |
|--------|-------------------|------------------|
| D06 Risk Engine | RiskScore > 75 | L3 |
| D07 Cost Guardrail | Budget > 90% | L2 |
| D07 Cost Guardrail | Budget > 100% | L4 |
| D10 Determinism | Checksum mismatch | L3 |
| D11 CI | Test failure rate > 20% | L2 |
| D12 Auto-Ticket | Ticket queue > 100 | L2 |
| D19 Escalation | EscalationScore > 0.85 | L4 |

---

## Response Procedures

### L1 Response
- [ ] Acknowledge alert in Slack
- [ ] Monitor metrics dashboard
- [ ] No immediate action required

### L2 Response
- [ ] Acknowledge within 5 minutes
- [ ] Assess impact
- [ ] Begin investigation
- [ ] Update team channel

### L3 Response
- [ ] Acknowledge within 2 minutes
- [ ] Page lead if unavailable
- [ ] Begin active mitigation
- [ ] Create incident ticket

### L4 Response
- [ ] Immediate response
- [ ] Page on-call engineer
- [ ] Execute emergency procedures
- [ ] Notify stakeholders
- [ ] Begin post-mortem

---

*Last Updated: 2024-01-15*
