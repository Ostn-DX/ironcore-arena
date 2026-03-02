---
title: Calibration_Protocol
type: cost
layer: costing
status: active
tags:
  - calibration
  - validation
  - cost
  - tracking
depends_on:
  - "[Cost_Model_Assumptions]"
used_by:
  - "[Monthly_Budget_Tiers]"
---

# Calibration Protocol

## Purpose
Measure actual costs vs. estimates and adjust model to reduce variance. Target: ±20% accuracy.

## Calibration Cycle

### Weekly Mini-Calibration
**Duration:** 15 minutes
**Frequency:** Every Friday

1. Review completed tickets from week
2. Compare estimated vs. actual cost
3. Flag tickets with >50% variance
4. Adjust assumptions if pattern emerges

### Monthly Full Calibration
**Duration:** 1 hour
**Frequency:** End of month

1. Aggregate all ticket data
2. Calculate model-wide accuracy
3. Update cost formulas
4. Adjust routing rules
5. Reconcile budget

## Data Collection

### Per-Ticket Metrics
```yaml
# Stored in ticket file
cost_data:
  estimated: $5.00
  actual: $6.50
  variance: +30%
  model: kimi-k2.5
  tokens:
    input: 25000
    output: 42000
  iterations: 1.5
  time_to_complete: 45min
  quality_score: 8/10
```

### Aggregated Metrics
| Metric | Calculation | Target |
|--------|-------------|--------|
| Mean variance | Σ|actual - estimated| / n | < 20% |
| Overrun rate | % tickets over estimate | < 30% |
| Model accuracy | By model, by task type | > 80% |
| Cost/ticket | Total cost / ticket count | Track trend |

## Variance Analysis

### High Variance Causes

| Pattern | Cause | Fix |
|---------|-------|-----|
| Consistently over | Estimates too conservative | Reduce base estimate 20% |
| Consistently under | Underestimating complexity | Add complexity multiplier |
| Random scatter | Task definition unclear | Improve ticket specificity |
| Model-dependent | Wrong model for task | Adjust routing rules |

### Adjustment Formulas

```python
# If mean variance > 20%
new_estimate = old_estimate × (1 + mean_variance)

# If specific model underperforming
if kimi_variance > 30%:
    route_less_to_kimi()
    increase_estimates_for_kimi()

# If task type consistently underestimated
if architectural_variance > 40%:
    architectural_multiplier *= 1.5
```

## Quality vs. Cost Tradeoff

### Acceptable Tradeoffs
| Scenario | Action |
|----------|--------|
| +10% cost, +20% quality | Acceptable |
| +50% cost, same quality | Unacceptable, change model |
| -20% cost, -10% quality | Acceptable for non-critical |
| -50% cost, -50% quality | Unacceptable, increase budget |

### Quality Scoring
| Aspect | Weight | How Measured |
|--------|--------|--------------|
| Gate pass | 40% | Pass/fail |
| Code review | 30% | Human 1-10 |
| Bug count | 30% | Issues found |

## Escalation

### Auto-Adjust Triggers
| Condition | Action |
|-----------|--------|
| 3 consecutive overruns | +25% estimate buffer |
| Model accuracy < 70% | Deprioritize model |
| Week-over-week cost +50% | Downgrade tier |

### Human Review Triggers
| Condition | Action |
|-----------|--------|
| Monthly budget exceeded | Emergency review |
| Quality score < 6/10 | Process review |
| Systematic bias detected | Assumption review |

## Related
[[Cost_Model_Assumptions]]
[[Monthly_Budget_Tiers]]
