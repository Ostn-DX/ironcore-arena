---
title: Risk Engine
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

# Risk Engine
## AI-Native Game Studio OS - Risk Scoring System

---

## Risk Score Formula

```
RiskScore = Σ(wi × fi_norm) ∈ [0, 100]

Where:
  w1 = files_touched_weight      | f1 = files_touched_norm
  w2 = simulation_core_weight    | f2 = simulation_core_flag
  w3 = determinism_delta_weight  | f3 = determinism_delta_norm
  w4 = diff_line_count_weight    | f4 = diff_line_count_norm
  w5 = retry_count_weight        | f5 = retry_count_norm
  w6 = historical_failure_weight | f6 = historical_failure_rate

Constraint: Σ(wi) = 1.0 ∀ configurations
```

---

## Factor Definitions

| Factor | Symbol | Domain | Description |
|--------|--------|--------|-------------|
| Files Touched | f1 | ℕ⁺ | Number of files modified in change |
| Simulation Core Flag | f2 | {0,1} | 1 if touches physics/simulation, 0 otherwise |
| Determinism Delta | f3 | [0,1] | Deviation from deterministic baseline |
| Diff Line Count | f4 | ℕ⁺ | Total lines added/removed |
| Retry Count | f5 | ℕ₀ | Number of LLM retries for this task |
| Historical Failure Rate | f6 | [0,1] | Task-type failure rate over last N runs |

---

## Weight Configurations

### Conservative (Safety-First)

| Factor | Weight | Rationale |
|--------|--------|-----------|
| files_touched | 0.15 | Scope awareness |
| simulation_core | 0.30 | HIGH: Physics stability critical |
| determinism_delta | 0.25 | HIGH: Determinism is sacred |
| diff_line_count | 0.10 | Change magnitude |
| retry_count | 0.12 | Uncertainty indicator |
| historical_failure | 0.08 | Past performance bias |
| **Σ** | **1.00** | |

### Balanced (Default)

| Factor | Weight | Rationale |
|--------|--------|-----------|
| files_touched | 0.20 | Scope awareness |
| simulation_core | 0.20 | Balanced physics concern |
| determinism_delta | 0.20 | Balanced determinism concern |
| diff_line_count | 0.20 | Change magnitude |
| retry_count | 0.12 | Uncertainty indicator |
| historical_failure | 0.08 | Past performance bias |
| **Σ** | **1.00** | |

### Aggressive (Velocity-First)

| Factor | Weight | Rationale |
|--------|--------|-----------|
| files_touched | 0.25 | Scope awareness |
| simulation_core | 0.15 | LOW: Accept physics risk |
| determinism_delta | 0.15 | LOW: Accept determinism drift |
| diff_line_count | 0.25 | Change magnitude |
| retry_count | 0.12 | Uncertainty indicator |
| historical_failure | 0.08 | Past performance bias |
| **Σ** | **1.00** | |

---

## Configuration Selection Matrix

| Trigger Condition | Selected Config | Override TTL |
|-------------------|-----------------|--------------|
| Release week | CONSERVATIVE | 7 days |
| Default state | BALANCED | N/A |
| Rapid iteration | AGGRESSIVE | 3 days |
| Critical bug fix | CONSERVATIVE | Until fix verified |
| New feature dev | AGGRESSIVE | Until feature complete |
| Production hotfix | CONSERVATIVE | Single operation |

---

## Normalization Methods

### Files Touched (f1)

```python
# Log-scaled min-max with ceiling
f1_norm = min(1.0, log₂(files_touched + 1) / log₂(101))

# Rationale: Diminishing returns beyond 100 files
# f1(1) = 0.07, f1(10) = 0.50, f1(100) = 1.0, f1(500) = 1.0
```

### Simulation Core Flag (f2)

```python
# Binary flag - no normalization needed
f2 = 1.0 if touches_simulation_core() else 0.0

SIMULATION_CORE_PATTERNS = [
    r"Physics\.cs$",
    r"Rigidbody",
    r"Collider",
    r"FixedUpdate",
    r"Time\.fixedDeltaTime",
    r"Physics\.Raycast",
    r"Physics\.Simulate",
    r"DeterministicSimulation",
    r"LockstepManager",
    r"RollbackSystem"
]
```

### Determinism Delta (f3)

```python
# Sigmoid-normalized based on checksum variance
f3_norm = 1 / (1 + e^(-10 × (variance - 0.05)))

# Thresholds:
# variance < 0.01  → f3 ≈ 0.0 (deterministic)
# variance = 0.05  → f3 = 0.5 (uncertain)
# variance > 0.10  → f3 ≈ 1.0 (non-deterministic)
```

### Diff Line Count (f4)

```python
# Sqrt-scaled normalization
f4_norm = min(1.0, √(diff_lines) / √1000)

# f4(10) = 0.10, f4(100) = 0.32, f4(500) = 0.71, f4(1000+) = 1.0
```

### Retry Count (f5)

```python
# Exponential decay normalization
f5_norm = 1 - e^(-retry_count / 3)

# f5(0) = 0.0, f5(1) = 0.28, f5(3) = 0.63, f5(5+) = 0.81
```

### Historical Failure Rate (f6)

```python
# Windowed moving average (last 20 runs of same task type)
f6 = Σ(failure_i) / min(20, total_runs) for i ∈ [1, min(20, N)]

# Bootstrap: If < 5 samples, use global average × 1.5
```

---

## Normalization Summary

| Factor | Method | Output Range |
|--------|--------|--------------|
| files_touched | log₂(x+1)/log₂(101) | [0, 1] |
| simulation_core | Binary flag | {0, 1} |
| determinism_delta | Sigmoid: 1/(1+e^(-10(x-0.05))) | [0, 1] |
| diff_line_count | √x/√1000 | [0, 1] |
| retry_count | 1-e^(-x/3) | [0, 1] |
| hist_failure | Windowed moving average | [0, 1] |

---

## Risk Level Classification

| Risk Level | Score Range | Required Action |
|------------|-------------|-----------------|
| LOW | [0, 30] | AUTO-APPROVE: Execute without review |
| MEDIUM | (30, 60] | STANDARD REVIEW: Async human review (4-hour SLA) |
| HIGH | (60, 80] | SENIOR REVIEW: Immediate attention (1-hour SLA) |
| CRITICAL | (80, 100] | EXECUTIVE REVIEW: Block execution, escalate immediately |

---

*Last Updated: 2024-01-15*
