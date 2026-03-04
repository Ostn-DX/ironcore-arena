# Cost Model
## AI-Native Game Studio OS - Budget & Burn Analysis

---

## Budget Allocation Hierarchy

```yaml
BudgetHierarchy:
  Organization:
    total_monthly_budget: ${ORG_BUDGET}
    
  Projects:
    allocation_formula: |
      ProjectBudget = TotalBudget × PriorityWeight × ComplexityFactor
      
    priority_weights:
      critical: 0.40
      high: 0.30
      medium: 0.20
      low: 0.10
      
  Services:
    ai_inference: 0.35      # LLM calls, embeddings
    compute: 0.25           # VMs, containers, serverless
    storage: 0.15           # Databases, object storage
    networking: 0.10        # CDN, bandwidth
    monitoring: 0.08        # Logs, metrics, tracing
    contingency: 0.07       # Buffer for spikes
```

---

## Burn Rate Formulas

### Hourly Burn Rate

```
HourlyBurnRate(t) = Σ(CostThisHour_i) for i ∈ [0, 3600] seconds
```

### Daily Burn Rate

```
DailyBurnRate(d) = Σ(HourlyBurnRate(h)) for h ∈ [0, 23] hours
```

### Projected Monthly

```
ProjectedMonthly = DailyBurnRate × 30.44  # Average days per month
```

### Burn Rate Velocity

```
BurnVelocity(t) = (BurnRate(t) - BurnRate(t-1)) / Δt
```

### Spike Detection

```
IsSpike(t) = BurnRate(t) > (μ + 3σ)  # 3-sigma rule
```

---

## Alert Threshold Matrix

| Severity | Threshold | Notification | Response Time |
|----------|-----------|--------------|---------------|
| INFO | 25% budget | Dashboard only | N/A |
| YELLOW | 50% budget | Slack + Email | 5 min |
| ORANGE | 75% budget | PagerDuty + SMS | 2 min |
| RED | 90% budget | Phone call + Auto-restrict | 30 sec |
| BLACK | 100% budget | Emergency shutdown | Immediate |

---

## Adaptive Thresholding

```python
# Dynamic threshold based on historical patterns
AdaptiveThreshold = μ_historical + (Z_score × σ_historical)

# Where:
μ_historical = (1/n) Σ BurnRate(i) for i ∈ [t-n, t-1]
σ_historical = √[(1/n) Σ (BurnRate(i) - μ)²]

# Z-scores by severity
Z_scores = {
    'yellow': 1.0,   # ~84th percentile
    'orange': 1.5,   # ~93rd percentile
    'red': 2.0,      # ~98th percentile
    'black': 3.0     # ~99.9th percentile
}
```

---

## Burn Cap Mathematics

```python
# Hard Cap Enforcement
HardCap = BudgetAllocation × CapMultiplier

CapMultipliers = {
    'hourly': 1.0,      # Cannot exceed hourly allocation
    'daily': 1.05,      # 5% daily overage allowed
    'weekly': 1.10,     # 10% weekly overage allowed
    'monthly': 1.0      # Strict monthly cap
}

# Soft Cap (warning zone)
SoftCap = HardCap × 0.90

# Enforcement
if CurrentBurn > HardCap:
    enforce_shutdown()
elif CurrentBurn > SoftCap:
    trigger_throttling()
```

---

## Predictive Burn Projection

```python
# Linear projection (short-term)
LinearProjection(t) = CurrentBurn + (BurnRate × t)

# Exponential smoothing (medium-term)
EWMA_α = 0.3  # Smoothing factor
EWMA(t) = α × BurnRate(t) + (1-α) × EWMA(t-1)

# Monte Carlo projection (long-term, 95% CI)
MCProjection = MonteCarlo(
    n_simulations=10000,
    distribution='lognormal',
    params={'mu': μ, 'sigma': σ}
)
```

---

## Cost Tracking Granularity

| Level | Interval | Retention | Precision |
|-------|----------|-----------|-----------|
| Real-time | 1 second | 24 hours | 6 decimals |
| Operational | 1 minute | 30 days | 4 decimals |
| Analytical | 1 hour | 365 days | 2 decimals |

---

## Model Cost Matrix

| Model | Input Cost | Output Cost | Context Cost |
|-------|------------|-------------|--------------|
| Claude-3-Opus | $15.00/M | $75.00/M | $0.00 |
| Claude-3-Sonnet | $3.00/M | $15.00/M | $0.00 |
| Claude-3-Haiku | $0.25/M | $1.25/M | $0.00 |
| GPT-4o | $5.00/M | $15.00/M | $0.00 |
| GPT-4o-mini | $0.15/M | $0.60/M | $0.00 |
| Local-LLM (70B) | $0.00 | $0.00 | $0.50/hr |

---

## Escalation Trigger Rules

| Trigger ID | Condition | Window | Action | Auto-Execute |
|------------|-----------|--------|--------|--------------|
| T001 | BurnRateSpike > 150% avg | 5 min | ALERT | No |
| T002 | BurnRateSpike > 200% avg | 5 min | RESTRICT | Yes |
| T003 | BudgetExhaustion > 90% | 1 min | ALERT+RESTRICT | Yes |
| T004 | BudgetExhaustion > 95% | 1 min | EMERGENCY | Yes |
| T005 | BudgetExhaustion > 100% | Immediate | SHUTDOWN | Yes |
| T006 | Velocity > 3σ | 10 min | ALERT | No |
| T007 | Anomaly Score > 0.95 | 1 min | INVESTIGATE | No |
| T008 | Provider Rate Limit | Immediate | FAILOVER | Yes |
| T009 | Multi-provider Spike | 5 min | GLOBAL_THROTTLE | Yes |
| T010 | Forecast Exceeds Budget | 1 hour | PLAN_ADJUST | No |

---

*Last Updated: 2024-01-15*
