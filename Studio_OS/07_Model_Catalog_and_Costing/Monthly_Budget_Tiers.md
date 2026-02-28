---
title: Monthly_Budget_Tiers
type: cost
layer: costing
status: active
tags:
  - budget
  - tiers
  - cost
  - planning
depends_on:
  - "[Cost_Model_Assumptions]"
used_by:
  - "[Daily_Operator_Protocol]"
---

# Monthly Budget Tiers

## Purpose
Pre-defined budget tiers for different development velocities. Choose tier based on project phase and funding.

## Tier Definitions

### Tier 1: Maintenance Mode
**Monthly Budget:** $50-100
**Weekly Tokens:** ~100K input, ~50K output

| Metric | Target |
|--------|--------|
| Tickets/week | 2-3 |
| Avg cost/ticket | $8 |
| Primary model | GPT-4o-mini, Gemini Flash |
| Escalation allowed | No |

**Use Case:**
- Bug fixes only
- Documentation updates
- Minor tweaks
- Between releases

**Model Mix:**
- 70% GPT-4o-mini
- 30% Gemini Flash

### Tier 2: Steady Development
**Monthly Budget:** $300-500
**Weekly Tokens:** ~500K input, ~250K output

| Metric | Target |
|--------|--------|
| Tickets/week | 5-8 |
| Avg cost/ticket | $12 |
| Primary model | Kimi k2.5, GPT-4o |
| Escalation allowed | Limited |

**Use Case:**
- Feature implementation
- Test coverage
- Balance tuning
- Active development

**Model Mix:**
- 60% Kimi k2.5
- 30% GPT-4o
- 10% Claude 3.5 Sonnet (escalation only)

### Tier 3: Accelerated Development
**Monthly Budget:** $800-1200
**Weekly Tokens:** ~1.5M input, ~750K output

| Metric | Target |
|--------|--------|
| Tickets/week | 10-15 |
| Avg cost/ticket | $15 |
| Primary model | Kimi k2.5, Claude 3.5 Sonnet |
| Escalation allowed | Yes |

**Use Case:**
- Major features
- Architecture redesigns
- Content pipelines
- Pre-release sprint

**Model Mix:**
- 50% Kimi k2.5
- 30% GPT-4o
- 20% Claude 3.5 Sonnet

### Tier 4: Full Autonomy
**Monthly Budget:** $1500-2500
**Weekly Tokens:** ~3M input, ~1.5M output

| Metric | Target |
|--------|--------|
| Tickets/week | 20-30 |
| Avg cost/ticket | $20 |
| Primary model | All models as needed |
| Escalation allowed | Yes, automatic |

**Use Case:**
- Multi-agent swarm
- Rapid iteration
- Experimental features
- Maximum velocity

**Model Mix:**
- 40% Kimi k2.5
- 30% GPT-4o
- 20% Claude 3.5 Sonnet
- 10% Gemini Flash (docs)

## Current Status

**Active Tier:** Tier 3 (Accelerated Development)
**Monthly Budget:** $800-1200
**Current Month Spend:** $0 (start of month)

## Budget Controls

### Daily Limit
```python
daily_limit = monthly_budget / 30 × 1.5  # 50% buffer
if daily_spend > daily_limit:
    halt_non_critical_tickets()
    escalate_to_human()
```

### Per-Ticket Cap
- Soft cap: $25
- Hard cap: $50
- Over $50 = human approval required

### Budget Alerts
| Threshold | Action |
|-----------|--------|
| 50% | Warning notification |
| 75% | Reduce to Tier 2 |
| 90% | Halt all non-critical |
| 100% | Full stop, human review |

## Cost Optimization

### Token Reduction Strategies
1. **Context minimization** - Only include necessary files
2. **Incremental delivery** - Skeleton first, details second
3. **Model downgrading** - Start cheap, escalate if needed
4. **Caching** - Reuse previous context when possible

### When to Downgrade Tier
- Velocity lower than expected
- Quality issues requiring rework
- External costs (art, audio) increasing
- Approaching release (less coding needed)

### When to Upgrade Tier
- Critical path blocked
- Deadline approaching
- High-value feature opportunity
- Funding secured

## Related
[[Cost_Model_Assumptions]]
[[Task_Routing_Table]]
[[Calibration_Protocol]]
