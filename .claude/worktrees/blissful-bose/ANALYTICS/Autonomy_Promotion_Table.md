# Autonomy Promotion Table
## AI-Native Game Studio OS - Progressive Trust Metrics

---

## Promotion Criteria Summary

| From | To | Success Rate | Override Rate | Tasks Required | Time Required |
|------|-----|--------------|---------------|----------------|---------------|
| L1 | L2 | ≥ 95% | ≤ 10% | 100 | 30 days |
| L2 | L3 | ≥ 97% | ≤ 5% | 200 | 30 days |
| L3 | L4 | ≥ 99% | ≤ 2% | 500 | 60 days |

---

## L1 → L2 Promotion Requirements

### Success Metrics

| Metric | Threshold | Measurement Window |
|--------|-----------|-------------------|
| Success Rate | ≥ 95% | Last 100 tasks |
| Human Override Rate | ≤ 10% | Last 100 tasks |
| Complex Tasks Completed | ≥ 50 | 30 days |
| Critical Failures | 0 | 30 days |

### Evaluation Checklist

- [ ] Success rate ≥ 95% over 100 tasks
- [ ] Human override rate ≤ 10% over 100 tasks
- [ ] At least 50 simple tasks completed
- [ ] No critical failures in 30 days
- [ ] All required training completed
- [ ] Manager approval obtained

---

## L2 → L3 Promotion Requirements

### Success Metrics

| Metric | Threshold | Measurement Window |
|--------|-----------|-------------------|
| Success Rate | ≥ 97% | Last 200 tasks |
| Human Override Rate | ≤ 5% | Last 200 tasks |
| Medium Tasks Completed | ≥ 30 | 30 days |
| Critical Failures | 0 | 60 days |

### Evaluation Checklist

- [ ] Success rate ≥ 97% over 200 tasks
- [ ] Human override rate ≤ 5% over 200 tasks
- [ ] At least 30 medium tasks completed
- [ ] No critical failures in 60 days
- [ ] Advanced training completed
- [ ] Senior engineer approval obtained

---

## L3 → L4 Promotion Requirements

### Success Metrics

| Metric | Threshold | Measurement Window |
|--------|-----------|-------------------|
| Success Rate | ≥ 99% | Last 500 tasks |
| Human Override Rate | ≤ 2% | Last 500 tasks |
| Complex Tasks Completed | ≥ 20 | 60 days |
| Critical Failures | 0 | 90 days |

### Evaluation Checklist

- [ ] Success rate ≥ 99% over 500 tasks
- [ ] Human override rate ≤ 2% over 500 tasks
- [ ] At least 20 complex tasks completed
- [ ] No critical failures in 90 days
- [ ] Expert-level training completed
- [ ] Engineering lead approval obtained

---

## Demotion Triggers

### Any Level → L1 Demotion

| Trigger | Condition | Immediate? |
|---------|-----------|------------|
| Critical Failure | Any safety-critical error | Yes |
| Success Rate Drop | < 80% over 50 tasks | No |
| Override Spike | > 30% over 50 tasks | No |
| Security Incident | Any unauthorized access | Yes |

### L4 → L3 Demotion

| Trigger | Condition | Immediate? |
|---------|-----------|------------|
| Success Rate Drop | < 95% over 100 tasks | No |
| Override Spike | > 10% over 100 tasks | No |
| Budget Overrun | > 150% of allocated budget | No |

### L3 → L2 Demotion

| Trigger | Condition | Immediate? |
|---------|-----------|------------|
| Success Rate Drop | < 90% over 100 tasks | No |
| Override Spike | > 15% over 100 tasks | No |

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

## Monitoring Dashboard Metrics

| Metric | L1 Target | L2 Target | L3 Target | L4 Target |
|--------|-----------|-----------|-----------|-----------|
| Success Rate | N/A | ≥ 95% | ≥ 97% | ≥ 99% |
| Human Override | N/A | ≤ 10% | ≤ 5% | ≤ 2% |
| Avg Latency | N/A | < 5s | < 2s | < 1s |
| Cost per Task | N/A | < $1 | < $0.50 | < $0.25 |
| Error Rate | N/A | < 2% | < 1% | < 0.5% |

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

## Sample Promotion Report

```markdown
# Autonomy Promotion Report
## Agent: [AGENT_ID]
## From: [CURRENT_LEVEL] → [TARGET_LEVEL]
## Date: [DATE]

### Metrics Summary
| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Success Rate | XX% | ≥ XX% | ✅/❌ |
| Override Rate | XX% | ≤ XX% | ✅/❌ |
| Tasks Completed | XXX | ≥ XXX | ✅/❌ |
| Critical Failures | X | = 0 | ✅/❌ |

### Recommendation
[APPROVE/DENY] - [Justification]

### Approved By
[Name] - [Date]
```

---

*Last Updated: 2024-01-15*
