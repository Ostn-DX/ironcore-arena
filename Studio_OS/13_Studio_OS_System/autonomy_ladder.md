---
title: Autonomy Ladder
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

# Autonomy Ladder
## AI-Native Game Studio OS - Progressive Trust System

---

## Autonomy Levels

| Level | Trust Range | Human Involvement | Description |
|-------|-------------|-------------------|-------------|
| L1 | 0-25% | Required | All decisions require human approval |
| L2 | 25-50% | Supervised | AI executes, human reviews |
| L3 | 50-75% | Monitored | AI executes, human monitors |
| L4 | 75-100% | Escalation Only | AI autonomous, human on exception |

---

## Trust Score Formula

```
TrustScore = Σ(w_i × verification_metric_i)

Where:
  w = [0.30, 0.40, 0.30]
  
  f_success_rate = successful_executions / total_executions
  f_human_override_rate = 1 - (human_overrides / total_decisions)
  f_complexity_handled = complex_tasks_completed / complex_tasks_attempted
```

---

## Level Progression Criteria

### L1 → L2 Promotion

| Metric | Threshold | Window |
|--------|-----------|--------|
| Success Rate | ≥ 95% | 100 tasks |
| Human Override Rate | ≤ 10% | 100 tasks |
| Complexity Handled | ≥ 50 simple tasks | 30 days |
| No Critical Failures | 0 | 30 days |

### L2 → L3 Promotion

| Metric | Threshold | Window |
|--------|-----------|--------|
| Success Rate | ≥ 97% | 200 tasks |
| Human Override Rate | ≤ 5% | 200 tasks |
| Complexity Handled | ≥ 30 medium tasks | 30 days |
| No Critical Failures | 0 | 60 days |

### L3 → L4 Promotion

| Metric | Threshold | Window |
|--------|-----------|--------|
| Success Rate | ≥ 99% | 500 tasks |
| Human Override Rate | ≤ 2% | 500 tasks |
| Complexity Handled | ≥ 20 complex tasks | 60 days |
| No Critical Failures | 0 | 90 days |

---

## Level Demotion Criteria

### Any Level → L1 Demotion

| Trigger | Condition |
|---------|-----------|
| Critical Failure | Any safety-critical error |
| Success Rate Drop | < 80% over 50 tasks |
| Human Override Spike | > 30% over 50 tasks |
| Security Incident | Any unauthorized access |

### L4 → L3 Demotion

| Trigger | Condition |
|---------|-----------|
| Success Rate Drop | < 95% over 100 tasks |
| Human Override Spike | > 10% over 100 tasks |
| Budget Overrun | > 150% of allocated budget |

### L3 → L2 Demotion

| Trigger | Condition |
|---------|-----------|
| Success Rate Drop | < 90% over 100 tasks |
| Human Override Spike | > 15% over 100 tasks |

---

## Capabilities by Level

| Capability | L1 | L2 | L3 | L4 |
|------------|----|----|----|----|
| Code Generation | Human approval | Auto + review | Auto + monitor | Full auto |
| Test Execution | Human approval | Auto + review | Auto + monitor | Full auto |
| Documentation | Human approval | Auto + review | Auto + monitor | Full auto |
| Asset Generation | Human approval | Auto + review | Auto + monitor | Full auto |
| Deployment | Human approval | Human approval | Auto + review | Auto + monitor |
| Configuration | Human approval | Human approval | Auto + review | Auto + monitor |
| Budget Allocation | Human approval | Human approval | Human approval | Auto + review |
| Security Changes | Human approval | Human approval | Human approval | Human approval |

---

## Routing Behavior by Autonomy Level

| Autonomy Level | Routing Behavior |
|----------------|------------------|
| L1 | All requests → Human queue |
| L2 | AI executes → Human review queue |
| L3 | AI executes → Monitor metrics only |
| L4 | AI executes → Escalate on exception |

---

## Promotion Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                     PROMOTION WORKFLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐      │
│  │ Metrics │───▶│ Evaluate│───▶│ Approve │───▶│ Promote │      │
│  │Collect  │    │ Criteria│    │ Human   │    │ Level   │      │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘      │
│       │              │              │              │            │
│       ▼              ▼              ▼              ▼            │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐      │
│  │ 30-day  │    │ Check   │    │ Manager │    │ Update  │      │
│  │ window  │    │ all     │    │ Review  │    │ Config  │      │
│  │         │    │ metrics │    │         │    │ Notify  │      │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Demotion Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      DEMOTION WORKFLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐      │
│  │ Trigger │───▶│ Evaluate│───▶│ Approve │───▶│ Demote  │      │
│  │Detected │    │ Impact  │    │ Human   │    │ Level   │      │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘      │
│       │              │              │              │            │
│       ▼              ▼              ▼              ▼            │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐      │
│  │ Critical│    │ Assess  │    │ Lead    │    │ Update  │      │
│  │ Failure │    │ Risk    │    │ Approval│    │ Config  │      │
│  │         │    │         │    │         │    │ Notify  │      │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Monitoring Dashboard

| Metric | L1 Target | L2 Target | L3 Target | L4 Target |
|--------|-----------|-----------|-----------|-----------|
| Success Rate | N/A | ≥ 95% | ≥ 97% | ≥ 99% |
| Human Override | N/A | ≤ 10% | ≤ 5% | ≤ 2% |
| Avg Latency | N/A | < 5s | < 2s | < 1s |
| Cost per Task | N/A | < $1 | < $0.50 | < $0.25 |

---

*Last Updated: 2024-01-15*
