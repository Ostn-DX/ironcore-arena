---
title: Autonomy_Scoring_Rubric
type: system
layer: execution
status: active
tags:
  - autonomy
  - scoring
  - metrics
  - measurement
depends_on:
  - "[Autonomy_Ladder_L0_to_L5]"
used_by:
  - "[Daily_Operator_Protocol]"
---

# Autonomy Scoring Rubric

## Purpose
Quantify OpenClaw autonomy level with measurable metrics. Track progression toward L4.

## Scoring Dimensions

### 1. Execution Autonomy (0-100)
**Measures:** Ability to execute tasks without human intervention

| Score | Criteria |
|-------|----------|
| 100 | Full auto-execution, auto-commit |
| 80 | Auto-execution, human approves commit |
| 60 | Executes, human integrates |
| 40 | Prepares execution, human runs |
| 20 | Recommends, human executes |
| 0 | No autonomous execution |

**Current:** 60 (Executes, human integrates)

---

### 2. Decision Autonomy (0-100)
**Measures:** Ability to make implementation decisions

| Score | Criteria |
|-------|----------|
| 100 | Full architectural decisions |
| 80 | Implementation decisions, human reviews |
| 60 | Minor decisions, human guides major |
| 40 | Recommends decisions |
| 20 | Options only, human decides |
| 0 | No decision input |

**Current:** 40 (Recommends decisions)

---

### 3. Quality Score (0-100)
**Measures:** Output quality without human review

| Score | Criteria |
|-------|----------|
| 100 | Zero bugs, perfect gate pass |
| 90 | <5% minor bugs |
| 80 | <10% bugs, all caught by gate |
| 70 | <20% bugs, quick fixes |
| 60 | <30% bugs, some rework |
| <60 | Unacceptable quality |

**Current:** 75 (Some bugs, caught by gate)

---

### 4. Cost Efficiency (0-100)
**Measures:** Budget adherence

| Score | Criteria |
|-------|----------|
| 100 | Always under budget |
| 90 | <10% overruns |
| 80 | <20% overruns |
| 70 | <30% overruns |
| 60 | <50% overruns |
| <60 | Unacceptable cost |

**Current:** 85 (<15% overruns)

---

### 5. Escalation Rate (0-100, inverted)
**Measures:** How often human intervention needed

| Score | Criteria |
|-------|----------|
| 100 | <2% escalation |
| 90 | <5% escalation |
| 80 | <10% escalation |
| 70 | <20% escalation |
| 60 | <30% escalation |
| <60 | >30% escalation |

**Current:** 85 (<10% escalation)

---

## Composite Autonomy Score

```python
autonomy_score = (
    execution * 0.30 +
    decision * 0.20 +
    quality * 0.25 +
    cost * 0.15 +
    escalation * 0.10
)
```

**Current Calculation:**
```
(60 * 0.30) + (40 * 0.20) + (75 * 0.25) + (85 * 0.15) + (85 * 0.10)
= 18 + 8 + 18.75 + 12.75 + 8.5
= 66/100
```

**Classification:**
- 90-100: L5 (Full autonomy)
- 80-89: L4 (High autonomy) ← TARGET
- 70-79: L3 (Conditional)
- 60-69: L2 (Supervised) ← CURRENT
- 50-59: L1 (Assisted)
- 0-49: L0 (Manual)

## Target Scores for L4

| Dimension | Current | Target L4 |
|-----------|---------|-----------|
| Execution | 60 | 85 |
| Decision | 40 | 70 |
| Quality | 75 | 85 |
| Cost | 85 | 90 |
| Escalation | 85 | 95 |
| **Composite** | **66** | **85** |

## Improvement Plan

### To Reach L4 (Score 85)
1. **Execution (+25):** Automate integration step
2. **Decision (+30):** Allow minor architectural choices
3. **Quality (+10):** Improve test coverage
4. **Cost (+5):** Better estimation
5. **Escalation (+10):** Reduce edge cases

### Timeline
- Current: L2 (Score 66)
- 1 month: Target L3 (Score 75)
- 3 months: Target L4 (Score 85)

## Tracking

Update scores weekly:
```bash
python tools/calculate_autonomy_score.py
```

Output:
```
=== AUTONOMY SCORE ===
Execution: 60/100
Decision: 40/100
Quality: 75/100
Cost: 85/100
Escalation: 85/100

Composite: 66/100 (L2: Supervised)
Target: 85/100 (L4: High Autonomy)
Gap: 19 points
======================
```

## Related
[[Autonomy_Ladder_L0_to_L5]]
[[Daily_Operator_Protocol]]
[[Calibration_Protocol]]
