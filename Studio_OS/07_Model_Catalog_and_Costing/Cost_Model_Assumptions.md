---
title: Cost_Model_Assumptions
type: cost
layer: costing
status: active
tags:
  - cost
  - assumptions
  - budgeting
  - estimation
depends_on: []
used_by:
  - "[Monthly_Budget_Tiers]"
---

# Cost Model Assumptions

## Purpose
Explicit assumptions underlying all cost estimates. All numbers include 20% overhead for retries/rework.

## Base Assumptions

### Token Estimates

| Content Type | Tokens/Line | Overhead Factor |
|--------------|-------------|-----------------|
| GDScript code | 4 tokens/line | 1.5x (comments + types) |
| JSON data | 3 tokens/line | 1.2x |
| Markdown docs | 5 tokens/line | 1.0x |
| Context (code + comments) | 6 tokens/line | 2.0x |

### Task Size Estimates

| Task Type | Lines of Output | Context Size | Total Tokens |
|-----------|-----------------|--------------|--------------|
| Bug fix | 20-50 lines | 5K-10K | 15K-30K |
| Component | 100-200 lines | 10K-20K | 50K-100K |
| System | 300-500 lines | 30K-50K | 150K-300K |
| Architecture doc | 50-100 lines | 5K-10K | 20K-40K |

### Iteration Estimates

| Task Complexity | Avg Iterations | Rework Rate |
|-----------------|----------------|-------------|
| Simple | 1.2 iterations | 10% |
| Medium | 1.5 iterations | 20% |
| Complex | 2.0 iterations | 30% |
| Architectural | 2.5 iterations | 40% |

### Model Cost Per 1K Tokens

| Model | Input Cost | Output Cost | Blended (2:1 ratio) |
|-------|------------|-------------|---------------------|
| Kimi k2.5 | $0.80 | $0.80 | $0.80 |
| GPT-4o | $2.50 | $10.00 | $5.00 |
| Claude 3.5 Sonnet | $3.00 | $15.00 | $7.00 |
| Gemini Flash | $0.075 | $0.30 | $0.15 |
| GPT-4o-mini | $0.15 | $0.60 | $0.30 |

## Cost Formulas

### Single Task Cost
```
cost = (input_tokens × input_rate + output_tokens × output_rate) × iterations × 1.20
```

### Example: Medium Component (Kimi k2.5)
```
Input: 20K tokens (context)
Output: 40K tokens (200 lines × 4 × 1.5 × 2.0 overhead)
Iterations: 1.5

Base: (20000 × $0.80 + 40000 × $0.80) / 1000000 = $48.00
With overhead: $48.00 × 1.5 × 1.20 = $86.40
```

### Example: Bug Fix (GPT-4o-mini)
```
Input: 10K tokens
Output: 5K tokens
Iterations: 1.2

Base: (10000 × $0.15 + 5000 × $0.60) / 1000000 = $4.50
With overhead: $4.50 × 1.2 × 1.20 = $6.48
```

## Validation Methods

### Monthly Reconciliation
1. Track actual API costs
2. Compare to estimated costs
3. Adjust assumptions if variance > 20%
4. Update calibration factors

### Per-Ticket Tracking
```yaml
# Added to ticket frontmatter
estimated_cost: $5.00
actual_cost: $6.20
variance: +24%
model_used: kimi-k2.5
tokens_input: 25000
tokens_output: 42000
```

## Confidence Intervals

| Estimate Type | Low | Likely | High |
|---------------|-----|--------|------|
| Simple bug fix | $0.50 | $1.00 | $2.00 |
| Component | $2.00 | $5.00 | $10.00 |
| System | $10.00 | $25.00 | $50.00 |
| Architecture | $20.00 | $50.00 | $100.00 |

## Related
[[Monthly_Budget_Tiers]]
[[Calibration_Protocol]]
[[Task_Routing_Table]]
