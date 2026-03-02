---
title: Routing Policy
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

# Routing Policy
## AI-Native Game Studio OS - OpenClaw Routing Engine

---

## Routing Decision Tree

```
ROOT: Task Classification [T]
│
├── Branch A: Complexity Assessment [C]
│   ├── C ≤ 3 (Simple Tasks)
│   │   └── → ROUTE: Codex-4o-mini
│   │       └── Confidence ≥ 0.85 ? EXECUTE : ESCALATE
│   │
│   ├── 3 < C ≤ 7 (Medium Tasks)
│   │   └── → ROUTE: GPT-4o / Claude-3.5-Sonnet
│   │       └── LatencyCheck ? FAST_PATH : QUALITY_PATH
│   │
│   └── C > 7 (Complex Tasks)
│       └── → Branch B: Risk Assessment [R]
│
├── Branch B: Risk Assessment [R] (for C > 7)
│   ├── R ≤ 25 (Low Risk)
│   │   └── → ROUTE: Claude-3.5-Opus
│   │       └── TokenBudgetCheck ? EXECUTE : DEGRADE_TO_SONNET
│   │
│   ├── 25 < R ≤ 50 (Medium Risk)
│   │   └── → ROUTE: Claude-3.5-Opus + HumanReview
│   │       └── ReviewQueue: PRIORITY=MEDIUM
│   │
│   └── R > 50 (High Risk)
│       └── → ROUTE: Human-in-the-Loop [HITL]
│           └── HumanAvailable ? QUEUE : EMERGENCY_FALLBACK
│
├── Branch C: Latency-Critical Path [L]
│   └── L < 500ms
│       └── → ROUTE: Codex-4o-mini (cached) OR Local-LLM
│           └── CacheHit ? RETURN_CACHED : STREAM_RESPONSE
│
└── Branch D: Cost-Critical Path [$]
    └── $ < Budget_Threshold
        └── → ROUTE: Cost-Optimized Cascade
            └── PrimaryFail ? Fallback1 : Fallback2 : Local
```

---

## Decision Node Specifications

| Node | Function | Input Domain | Output Range | Latency Budget |
|------|----------|--------------|--------------|----------------|
| T (Classifier) | `f_classify(task)` | TaskDescriptor | {simple, medium, complex} | <10ms |
| C (Complexity) | `f_complexity(task, context)` | TaskDescriptor × ContextPack | [0, 10] | <15ms |
| R (Risk) | `f_risk(task, domain, history)` | TaskDescriptor × Domain × History | [0, 100] | <20ms |
| L (Latency) | `f_latency(requirements)` | SLADescriptor | {critical, normal, relaxed} | <5ms |
| $ (Cost) | `f_cost(budget, estimate)` | BudgetDescriptor × CostModel | {optimized, standard, premium} | <5ms |

---

## Mathematical Decision Functions

### Complexity Score

```python
C(task) = α·token_estimate(task) + β·reasoning_depth(task) + γ·domain_knowledge_required(task)

where:
  α = 0.4 (token weight)
  β = 0.35 (reasoning weight)
  γ = 0.25 (domain weight)
  
  token_estimate(task) = min(tokens(task) / 4000, 1.0)
  reasoning_depth(task) = {1: multi_step, 0.5: single_step, 0: retrieval}
  domain_knowledge_required(task) = domain_specificity_score(task) ∈ [0,1]
```

### Risk Score

```python
R(task) = Σ(w_i · r_i) for i ∈ {financial, legal, creative, technical, reputational}

where:
  w_financial = 0.30
  w_legal = 0.25
  w_creative = 0.20
  w_technical = 0.15
  w_reputational = 0.10
```

---

## Model Selection Matrix

| Factor | Symbol | Weight | Threshold | Direction | Model Mapping |
|--------|--------|--------|-----------|-----------|---------------|
| Complexity | C | 0.25 | C > 7 | ↑ | Claude-3.5-Opus |
| RiskScore | R | 0.30 | R > 50 | ↑ | Human-in-Loop |
| CostBudget | B | 0.20 | B < 20% | ↓ | Local-LLM |
| LatencyReq | L | 0.15 | L < 1s | ↓ | Codex-4o-mini |
| Determinism | D | 0.10 | D = Required | ↑ | Claude-3.5-Sonnet |
| ContextSize | X | 0.10 | X > 100K | ↑ | Claude-3.5-Opus |

---

## Selection Score Formula

```python
S(model) = Σ(w_i · normalized(f_i, model))

where normalized(f, model) = {
    1.0 if model optimal for f,
    0.5 if model acceptable for f,
    0.0 if model unsuitable for f
}

Final Selection: model* = argmax_{m ∈ M} S(m)
```

---

## Model Capability Matrix

| Model | Complexity Max | Risk Max | Cost/kTok | Latency | Context | Determinism |
|-------|---------------|----------|-----------|---------|---------|-------------|
| Codex-4o-mini | 4 | 15 | $0.15 | 200ms | 128K | Low |
| GPT-4o | 7 | 35 | $2.50 | 800ms | 128K | Medium |
| Claude-3.5-Sonnet | 8 | 45 | $3.00 | 900ms | 200K | High |
| Claude-3.5-Opus | 10 | 60 | $15.00 | 1500ms | 200K | High |
| Local-LLM (70B) | 6 | 25 | $0.05 | 500ms | 32K | Medium |
| Human Expert | 10 | 100 | $50.00 | 3600000ms | ∞ | Perfect |

---

## Threshold-Based Routing Rules

```
IF C ≤ 3 AND R ≤ 15 AND L < 2s:
    → Codex-4o-mini
    
IF 3 < C ≤ 7 AND R ≤ 35 AND B ≥ 30%:
    → GPT-4o OR Claude-3.5-Sonnet (by availability)
    
IF C > 7 AND R ≤ 50 AND D = Required:
    → Claude-3.5-Opus
    
IF R > 50 OR (C > 8 AND R > 40):
    → Human-in-the-Loop (HITL)
    
IF B < 20% AND C ≤ 6:
    → Local-LLM (Llama-3-70B)
    
IF L < 500ms AND C ≤ 4:
    → Codex-4o-mini with streaming
```

---

## Cost-Aware Routing

### Cost-Quality Pareto Frontier

```
Pareto Optimal Set P = {(c, q) | ∄(c', q') : c' ≤ c ∧ q' ≥ q ∧ (c', q') ≠ (c, q)}

where:
  c = cost(task, model)
  q = expected_quality(task, model) ∈ [0, 1]
```

### Cost-Constrained Optimization

```python
def route_cost_optimized(task, budget, quality_threshold):
    candidates = []
    
    for model in MODEL_REGISTRY:
        q = estimate_quality(task, model)
        r = estimate_risk(task, model)
        c = estimate_cost(task, model)
        
        if q >= quality_threshold AND r <= task.max_risk AND c <= budget:
            candidates.append((model, c, q, r))
    
    if not candidates:
        return trigger_fallback_chain(task, budget, quality_threshold)
    
    # Multi-objective: minimize cost, maximize quality, minimize risk
    scored = [(m, 0.5*(1/c_norm) + 0.3*q + 0.2*(1-r_norm)) 
              for m, c, q, r in candidates]
    
    return max(scored, key=lambda x: x[1])[0]
```

---

## Dynamic Budget Allocation

```python
class BudgetAllocator:
    def __init__(self, daily_budget):
        self.daily_budget = daily_budget
        self.hourly_budget = daily_budget / 24
        self.spent_hourly = 0
        self.spent_daily = 0
    
    def get_available_budget(self):
        remaining_daily = self.daily_budget - self.spent_daily
        remaining_hourly = self.hourly_budget - self.spent_hourly
        return min(remaining_daily, remaining_hourly * 2)  # 2x hourly buffer
    
    def allocate_for_task(self, task):
        available = self.get_available_budget()
        estimated_cost = estimate_cost(task)
        
        if estimated_cost > available * 0.5:  # 50% threshold
            return route_to_cheaper_model(task)
        
        return route_to_optimal_model(task)
```

---

## Failover Rules

| Primary Failure | First Fallback | Second Fallback | Final Fallback |
|-----------------|----------------|-----------------|----------------|
| Claude-3.5-Opus | Claude-3.5-Sonnet | GPT-4o | Local-LLM |
| GPT-4o | Claude-3.5-Sonnet | Local-LLM | Human |
| Codex-4o-mini | Local-LLM | Human | Queue |
| Local-LLM | Queue | Human | Reject |

---

*Last Updated: 2024-01-15*
