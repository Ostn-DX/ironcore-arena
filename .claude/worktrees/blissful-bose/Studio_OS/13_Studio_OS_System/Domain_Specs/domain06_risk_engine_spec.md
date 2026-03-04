---
title: "D06: Risk Engine Specification"
type: specification
layer: system
status: active
domain: studio_os
tags:
  - specification
  - domain
  - studio_os
depends_on: []
used_by: []
---

# Risk Scoring Engine Specification v1.0
## AI-Native Game Studio OS - Domain 06

---

## 1. RISK SCORE FORMULA

### Core Formula
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

### Factor Definitions
| Factor | Symbol | Domain | Description |
|--------|--------|--------|-------------|
| Files Touched | f1 | ℕ⁺ | Number of files modified in change |
| Simulation Core Flag | f2 | {0,1} | 1 if touches physics/simulation, 0 otherwise |
| Determinism Delta | f3 | [0,1] | Deviation from deterministic baseline |
| Diff Line Count | f4 | ℕ⁺ | Total lines added/removed |
| Retry Count | f5 | ℕ₀ | Number of LLM retries for this task |
| Historical Failure Rate | f6 | [0,1] | Task-type failure rate over last N runs |

---

## 2. WEIGHT CONFIGURATIONS

### 2.1 CONSERVATIVE (Safety-First)
```
┌──────────────────────┬────────┬─────────────────────────────────┐
│ Factor               │ Weight │ Rationale                       │
├──────────────────────┼────────┼─────────────────────────────────┤
│ files_touched        │ 0.15   │ Scope awareness                 │
│ simulation_core      │ 0.30   │ HIGH: Physics stability critical │
│ determinism_delta    │ 0.25   │ HIGH: Determinism is sacred      │
│ diff_line_count      │ 0.10   │ Change magnitude                │
│ retry_count          │ 0.12   │ Uncertainty indicator           │
│ historical_failure   │ 0.08   │ Past performance bias           │
└──────────────────────┴────────┴─────────────────────────────────┘
Σ = 1.00
```

### 2.2 BALANCED (Default)
```
┌──────────────────────┬────────┬─────────────────────────────────┐
│ Factor               │ Weight │ Rationale                       │
├──────────────────────┼────────┼─────────────────────────────────┤
│ files_touched        │ 0.20   │ Scope awareness                 │
│ simulation_core      │ 0.20   │ Balanced physics concern        │
│ determinism_delta    │ 0.20   │ Balanced determinism concern    │
│ diff_line_count      │ 0.20   │ Change magnitude                │
│ retry_count          │ 0.12   │ Uncertainty indicator           │
│ historical_failure   │ 0.08   │ Past performance bias           │
└──────────────────────┴────────┴─────────────────────────────────┘
Σ = 1.00
```

### 2.3 AGGRESSIVE (Velocity-First)
```
┌──────────────────────┬────────┬─────────────────────────────────┐
│ Factor               │ Weight │ Rationale                       │
├──────────────────────┼────────┼─────────────────────────────────┤
│ files_touched        │ 0.25   │ Scope awareness                 │
│ simulation_core      │ 0.15   │ LOW: Accept physics risk        │
│ determinism_delta    │ 0.15   │ LOW: Accept determinism drift   │
│ diff_line_count      │ 0.25   │ Change magnitude                │
│ retry_count          │ 0.12   │ Uncertainty indicator           │
│ historical_failure   │ 0.08   │ Past performance bias           │
└──────────────────────┴────────┴─────────────────────────────────┘
Σ = 1.00
```

### Configuration Selection Matrix
```
┌─────────────────────┬─────────────────┬─────────────────────────────┐
│ Trigger Condition   │ Selected Config │ Override TTL                │
├─────────────────────┼─────────────────┼─────────────────────────────┤
│ Release week        │ CONSERVATIVE    │ 7 days                      │
│ Default state       │ BALANCED        │ N/A                         │
│ Rapid iteration     │ AGGRESSIVE      │ 3 days                      │
│ Critical bug fix    │ CONSERVATIVE    │ Until fix verified          │
│ New feature dev     │ AGGRESSIVE      │ Until feature complete      │
│ Production hotfix   │ CONSERVATIVE    │ Single operation            │
└─────────────────────┴─────────────────┴─────────────────────────────┘
```

---

## 3. NORMALIZATION METHODS

### 3.1 Files Touched (f1)
```python
# Log-scaled min-max with ceiling
f1_norm = min(1.0, log₂(files_touched + 1) / log₂(101))

# Rationale: Diminishing returns beyond 100 files
# f1(1) = 0.07, f1(10) = 0.50, f1(100) = 1.0, f1(500) = 1.0
```

### 3.2 Simulation Core Flag (f2)
```python
# Binary flag - no normalization needed
f2 = 1.0 if touches_simulation_core() else 0.0

SIMULATION_CORE_PATTERNS = [
    r"Physics\\.cs$",
    r"Rigidbody",
    r"Collider",
    r"FixedUpdate",
    r"Time\\.fixedDeltaTime",
    r"Physics\\.Raycast",
    r"Physics\\.Simulate",
    r"DeterministicSimulation",
    r"LockstepManager",
    r"RollbackSystem"
]
```

### 3.3 Determinism Delta (f3)
```python
# Sigmoid-normalized based on checksum variance
f3_norm = 1 / (1 + e^(-10 × (variance - 0.05)))

# Thresholds:
# variance < 0.01  → f3 ≈ 0.0 (deterministic)
# variance = 0.05  → f3 = 0.5 (uncertain)
# variance > 0.10  → f3 ≈ 1.0 (non-deterministic)
```

### 3.4 Diff Line Count (f4)
```python
# Sqrt-scaled normalization
f4_norm = min(1.0, √(diff_lines) / √1000)

# f4(10) = 0.10, f4(100) = 0.32, f4(500) = 0.71, f4(1000+) = 1.0
```

### 3.5 Retry Count (f5)
```python
# Exponential decay normalization
f5_norm = 1 - e^(-retry_count / 3)

# f5(0) = 0.0, f5(1) = 0.28, f5(3) = 0.63, f5(5+) = 0.81
```

### 3.6 Historical Failure Rate (f6)
```python
# Windowed moving average (last 20 runs of same task type)
f6 = Σ(failure_i) / min(20, total_runs) for i ∈ [1, min(20, N)]

# Bootstrap: If < 5 samples, use global average × 1.5
```

### Normalization Summary Table
```
┌──────────────────┬──────────────────────────────┬───────────────┐
│ Factor           │ Method                       │ Output Range  │
├──────────────────┼──────────────────────────────┼───────────────┤
│ files_touched    │ log₂(x+1)/log₂(101)          │ [0, 1]        │
│ simulation_core  │ Binary flag                  │ {0, 1}        │
│ determinism_delta│ Sigmoid: 1/(1+e^(-10(x-0.05)))│ [0, 1]       │
│ diff_line_count  │ √x/√1000                     │ [0, 1]        │
│ retry_count      │ 1-e^(-x/3)                   │ [0, 1]        │
│ hist_failure     │ Windowed moving average      │ [0, 1]        │
└──────────────────┴──────────────────────────────┴───────────────┘
```

---

## 4. THRESHOLD DEFINITIONS

### 4.1 Risk Level Classification
```
┌─────────────┬─────────────┬─────────────────────────────────────────┐
│ Risk Level  │ Score Range │ Required Action                         │
├─────────────┼─────────────┼─────────────────────────────────────────┤
│ LOW         │ [0, 30]     │ AUTO-APPROVE: Execute without review    │
│             │             │ • Log to audit trail                    │
│             │             │ • Update metrics                        │
│             │             │ • No human intervention                 │
├─────────────┼─────────────┼─────────────────────────────────────────┤
│ MEDIUM      │ (30, 60]    │ STANDARD REVIEW: Async human review     │
│             │             │ • Queue for reviewer                    │
│             │             │ • 4-hour SLA for approval               │
│             │             │ • Auto-escalate if SLA breached         │
├─────────────┼─────────────┼─────────────────────────────────────────┤
│ HIGH        │ (60, 80]    │ SENIOR REVIEW: Immediate attention      │
│             │             │ • Notify senior engineer                │
│             │             │ • 1-hour SLA for approval               │
│             │             │ • Require test plan validation          │
│             │             │ • Block dependent operations            │
├─────────────┼─────────────┼─────────────────────────────────────────┤
│ CRITICAL    │ (80, 100]   │ HUMAN-ONLY: Full manual process         │
│             │             │ • Disable auto-execution                │
│             │             │ • Require 2-person approval             │
│             │             │ • Mandatory rollback plan               │
│             │             │ • Executive notification                │
│             │             │ • Post-incident review required         │
└─────────────┴─────────────┴─────────────────────────────────────────┘
```

### 4.2 Threshold Override Conditions
```
┌──────────────────────────────┬─────────────┬────────────────────────┐
│ Condition                    │ Override    │ Justification          │
├──────────────────────────────┼─────────────┼────────────────────────┤
│ Emergency security patch     │ LOW→AUTO    │ Security > Risk        │
│ Production outage            │ ANY→AUTO    │ Availability critical  │
│ Data corruption in progress  │ ANY→BLOCK   │ Prevent further damage │
│ Compliance deadline < 24h    │ +20 points  │ Time pressure          │
│ First-time task type         │ +10 points  │ Unknown risk           │
│ >3 failures in last hour     │ +15 points  │ System instability     │
└──────────────────────────────┴─────────────┴────────────────────────┘
```

---

## 5. DYNAMIC ADJUSTMENT LOGIC

### 5.1 Feedback Loop Architecture
```
                    ┌─────────────────┐
    ┌──────────────►│  Risk Outcomes  │◄──────────────┐
    │               │    Database     │               │
    │               └────────┬────────┘               │
    │                        │                        │
    │                        ▼                        │
    │               ┌─────────────────┐               │
    │               │  Weight Tuner   │               │
    │               │   (Weekly)      │               │
    │               └────────┬────────┘               │
    │                        │                        │
    ▼                        ▼                        │
┌─────────┐          ┌─────────────────┐              │
│  Input  │─────────►│  Risk Engine    │──────────────┘
│ Factors │          │  (Real-time)    │
└─────────┘          └─────────────────┘
                              │
                              ▼
                       ┌─────────────┐
                       │ Risk Score  │
                       │  + Action   │
                       └─────────────┘
```

### 5.2 Weight Adjustment Algorithm
```python
def adjust_weights(outcomes: List[Outcome], current_weights: Weights) -> Weights:
    """
    Weekly weight adjustment based on outcome analysis.
    
    Outcome types:
    - TRUE_POSITIVE: High risk → Blocked → Would have failed
    - FALSE_POSITIVE: High risk → Blocked → Would have succeeded
    - TRUE_NEGATIVE: Low risk → Approved → Succeeded
    - FALSE_NEGATIVE: Low risk → Approved → Failed
    """
    
    # Calculate misprediction rates per factor
    for factor in FACTORS:
        fp_rate = count_false_positives(factor) / total_predictions
        fn_rate = count_false_negatives(factor) / total_predictions
        
        # Adjust weight toward better predictor
        if fp_rate > fn_rate:
            # Too conservative - reduce weight
            delta = -0.02 * fp_rate
        elif fn_rate > fp_rate:
            # Too aggressive - increase weight
            delta = +0.02 * fn_rate
        else:
            delta = 0
            
        current_weights[factor] = clamp(current_weights[factor] + delta, 0.05, 0.50)
    
    # Renormalize to sum = 1.0
    return normalize_weights(current_weights)
```

### 5.3 Temporal Decay Functions
```python
# Historical failure rate time decay
DECAY_HALF_LIFE_DAYS = 7

def decay_factor(age_days: float) -> float:
    return 0.5 ^ (age_days / DECAY_HALF_LIFE_DAYS)

# Weighted historical failure
f6_effective = Σ(failure_i × decay_factor(age_i)) / Σ(decay_factor(age_i))
```

### 5.4 Context-Aware Multipliers
```
┌─────────────────────────┬────────────┬────────────────────────────────┐
│ Context                 │ Multiplier │ Applies To                     │
├─────────────────────────┼────────────┼────────────────────────────────┤
│ Business hours (9-5)    │ ×0.90      │ All scores                     │
│ Weekend/holiday         │ ×1.15      │ All scores                     │
│ Release freeze period   │ ×1.30      │ All scores                     │
│ New engineer (<30 days) │ ×1.20      │ Files touched, diff lines      │
│ Senior engineer         │ ×0.85      │ Files touched, diff lines      │
│ Automated test coverage>80%│ ×0.90   │ Simulation core, determinism   │
│ No test coverage        │ ×1.25      │ Simulation core, determinism   │
│ Monorepo main branch    │ ×1.10      │ All scores                     │
│ Feature branch          │ ×0.95      │ All scores                     │
└─────────────────────────┴────────────┴────────────────────────────────┘
```

---

## 6. SUCCESS CRITERIA (Measurable)

### 6.1 Primary Metrics
```
┌─────────────────────────────┬──────────┬──────────┬──────────────────┐
│ Metric                      │ Target   │ Minimum  │ Measurement      │
├─────────────────────────────┼──────────┼──────────┼──────────────────┤
│ False Positive Rate         │ <5%      │ <10%     │ Weekly audit     │
│ False Negative Rate         │ <2%      │ <5%      │ Weekly audit     │
│ Mean Time to Decision       │ <5s      │ <10s     │ p99 latency      │
│ Auto-approval Rate          │ 40-60%   │ 30-70%   │ Daily tracking   │
│ Escalation Accuracy         │ >90%     │ >80%     │ Monthly review   │
│ Weight Convergence Time     │ <4 weeks │ <8 weeks │ A/B test         │
└─────────────────────────────┴──────────┴──────────┴──────────────────┘
```

### 6.2 Secondary Metrics
```
┌─────────────────────────────┬──────────┬──────────────────────────────┐
│ Metric                      │ Target   │ Notes                        │
├─────────────────────────────┼──────────┼──────────────────────────────┤
│ Determinism preservation    │ 99.9%    │ Checksum match rate          │
│ Rollback success rate       │ >95%     │ When rollback triggered      │
│ Human review satisfaction   │ >4.0/5   │ Post-review survey           │
│ System availability         │ 99.95%   │ Risk engine uptime           │
│ Prediction confidence       │ >0.85    │ Average across predictions   │
└─────────────────────────────┴──────────┴──────────────────────────────┘
```

### 6.3 Success Measurement Protocol
```python
# Weekly success report generation
def generate_success_report(week: DateRange) -> Report:
    return {
        "false_positives": calculate_fp_rate(week),
        "false_negatives": calculate_fn_rate(week),
        "latency_p50": get_latency_percentile(week, 50),
        "latency_p99": get_latency_percentile(week, 99),
        "auto_approval_rate": get_auto_rate(week),
        "threshold_breaches": count_threshold_violations(week),
        "weight_stability": calculate_weight_variance(week),
        "recommendations": generate_recommendations(week)
    }
```

---

## 7. FAILURE STATES

### 7.1 Engine Failure Modes
```
┌────────────────────────┬────────────────────────────────────────────────┐
│ Failure Mode           │ Response                                       │
├────────────────────────┼────────────────────────────────────────────────┤
│ NORMALIZATION_OVERFLOW │ Clamp to [0,1], log warning, continue          │
│ WEIGHT_SUM_MISMATCH    │ Renormalize, alert ops, log incident           │
│ FACTOR_CALC_TIMEOUT    │ Use cached/default value, flag for review      │
│ DATABASE_UNAVAILABLE   │ Fallback to CONSERVATIVE static weights        │
│ THRESHOLD_INVALID      │ Use default thresholds, alert ops              │
│ CONTEXT_UNKNOWN        │ Apply no multipliers, log for analysis         │
│ HISTORY_CORRUPT        │ Reset to global average, rebuild from logs     │
└────────────────────────┴────────────────────────────────────────────────┘
```

### 7.2 Graceful Degradation Chain
```
FULL_OPERATION ──► CACHED_WEIGHTS ──► STATIC_CONSERVATIVE ──► BLOCK_ALL
     │                  │                    │                    │
     │                  │                    │                    │
   Normal          DB unavailable      All caches miss      Critical error
   operation       Use last known      Use hardcoded        Fail-safe mode
```

### 7.3 Circuit Breaker Configuration
```python
CIRCUIT_BREAKER_CONFIG = {
    "failure_threshold": 5,        # Open after 5 failures
    "recovery_timeout": 30,        # Seconds before half-open
    "half_open_max_calls": 3,      # Test calls in half-open
    "success_threshold": 2         # Close after 2 successes
}

# States: CLOSED → OPEN → HALF_OPEN → CLOSED
```

### 7.4 Alerting Thresholds
```
┌─────────────────────────┬───────────────┬─────────────────────────────┐
│ Condition               │ Severity      │ Alert Destination           │
├─────────────────────────┼───────────────┼─────────────────────────────┤
│ p99 latency > 10s       │ WARNING       │ #risk-engine-alerts         │
│ p99 latency > 30s       │ CRITICAL      │ PagerDuty + Slack           │
│ False positive > 10%    │ WARNING       │ #risk-engine-alerts         │
│ False negative > 5%     │ CRITICAL      │ PagerDuty + Email           │
│ Weight variance > 0.1   │ INFO          │ #risk-engine-logs           │
│ Database error rate >1% │ CRITICAL      │ PagerDuty + On-call         │
│ Cache hit rate < 80%    │ WARNING       │ #risk-engine-alerts         │
└─────────────────────────┴───────────────┴─────────────────────────────┘
```

---

## 8. INTEGRATION SURFACE

### 8.1 API Endpoints
```yaml
# Risk Score Calculation
POST /api/v1/risk/calculate
Request:
  task_id: string
  task_type: enum[CODE_GEN, REFACTOR, TEST_GEN, DOC_GEN]
  files_touched: string[]
  diff_content: string (optional)
  retry_count: integer
  context: object

Response:
  risk_score: float [0-100]
  risk_level: enum[LOW, MEDIUM, HIGH, CRITICAL]
  recommended_action: enum[AUTO_APPROVE, REVIEW, SENIOR_REVIEW, BLOCK]
  confidence: float [0-1]
  factor_breakdown: object
  processing_time_ms: integer

# Configuration Management
GET  /api/v1/risk/config
POST /api/v1/risk/config  # Admin only
PUT  /api/v1/risk/config/weights  # Admin only

# Health & Metrics
GET /api/v1/risk/health
GET /api/v1/risk/metrics
GET /api/v1/risk/outcomes
```

### 8.2 Event Interface
```python
# Events published by Risk Engine
class RiskScoreCalculated(Event):
    task_id: str
    risk_score: float
    risk_level: RiskLevel
    factors: Dict[str, float]
    config_used: str  # CONSERVATIVE, BALANCED, AGGRESSIVE
    timestamp: datetime

class ThresholdBreached(Event):
    task_id: str
    threshold: RiskLevel
    score: float
    action_taken: str

class WeightsAdjusted(Event):
    old_weights: Dict[str, float]
    new_weights: Dict[str, float]
    adjustment_reason: str
```

### 8.3 Integration Points
```
┌─────────────────────────────────────────────────────────────────────┐
│                        INTEGRATION DIAGRAM                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐      │
│  │  Agent   │───►│  Task    │───►│  Risk    │───►│ Decision │      │
│  │  System  │    │  Queue   │    │  Engine  │    │  Router  │      │
│  └──────────┘    └──────────┘    └────┬─────┘    └────┬─────┘      │
│                                       │               │             │
│                                       ▼               ▼             │
│                              ┌─────────────┐   ┌─────────────┐      │
│                              │   Metrics   │   │   Action    │      │
│                              │   Store     │   │   Executor  │      │
│                              └─────────────┘   └─────────────┘      │
│                                                                     │
│  External Integrations:                                             │
│  • CI/CD Pipeline (GitHub Actions, GitLab CI)                       │
│  • Monitoring (Prometheus, Grafana)                                 │
│  • Alerting (PagerDuty, Slack)                                      │
│  • Audit Log (Elasticsearch)                                        │
│  • Determinism Checker (Custom)                                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 8.4 Authentication & Authorization
```yaml
API_KEY_SCOPES:
  risk:read:      # Calculate scores, view configs
    - /api/v1/risk/calculate
    - /api/v1/risk/health
    - /api/v1/risk/metrics
  
  risk:admin:     # Modify configurations
    - /api/v1/risk/config
    - /api/v1/risk/config/weights
    
  risk:audit:     # View outcomes, reports
    - /api/v1/risk/outcomes
    - /api/v1/risk/reports/*
```

---

## 9. JSON SCHEMAS

### 9.1 Risk Calculation Request
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "RiskCalculationRequest",
  "type": "object",
  "required": ["task_id", "task_type", "files_touched"],
  "properties": {
    "task_id": {
      "type": "string",
      "pattern": "^[a-z0-9-]+$",
      "description": "Unique task identifier"
    },
    "task_type": {
      "type": "string",
      "enum": ["CODE_GEN", "REFACTOR", "TEST_GEN", "DOC_GEN", "CONFIG_CHANGE"]
    },
    "files_touched": {
      "type": "array",
      "items": { "type": "string" },
      "minItems": 1
    },
    "diff_content": {
      "type": "string",
      "description": "Unified diff for line count calculation"
    },
    "retry_count": {
      "type": "integer",
      "minimum": 0,
      "default": 0
    },
    "context": {
      "type": "object",
      "properties": {
        "author": { "type": "string" },
        "branch": { "type": "string" },
        "timestamp": { "type": "string", "format": "date-time" },
        "test_coverage": { "type": "number", "minimum": 0, "maximum": 1 }
      }
    }
  }
}
```

### 9.2 Risk Calculation Response
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "RiskCalculationResponse",
  "type": "object",
  "required": ["task_id", "risk_score", "risk_level", "recommended_action"],
  "properties": {
    "task_id": { "type": "string" },
    "risk_score": {
      "type": "number",
      "minimum": 0,
      "maximum": 100
    },
    "risk_level": {
      "type": "string",
      "enum": ["LOW", "MEDIUM", "HIGH", "CRITICAL"]
    },
    "recommended_action": {
      "type": "string",
      "enum": ["AUTO_APPROVE", "REVIEW", "SENIOR_REVIEW", "BLOCK"]
    },
    "confidence": {
      "type": "number",
      "minimum": 0,
      "maximum": 1
    },
    "factor_breakdown": {
      "type": "object",
      "properties": {
        "files_touched": { "type": "number" },
        "simulation_core": { "type": "number" },
        "determinism_delta": { "type": "number" },
        "diff_line_count": { "type": "number" },
        "retry_count": { "type": "number" },
        "historical_failure": { "type": "number" }
      }
    },
    "weights_used": {
      "type": "object",
      "properties": {
        "config_name": { "type": "string" },
        "weights": {
          "type": "object",
          "properties": {
            "files_touched": { "type": "number" },
            "simulation_core": { "type": "number" },
            "determinism_delta": { "type": "number" },
            "diff_line_count": { "type": "number" },
            "retry_count": { "type": "number" },
            "historical_failure": { "type": "number" }
          }
        }
      }
    },
    "processing_time_ms": { "type": "integer" },
    "timestamp": { "type": "string", "format": "date-time" }
  }
}
```

### 9.3 Weight Configuration Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "WeightConfiguration",
  "type": "object",
  "required": ["config_name", "weights"],
  "properties": {
    "config_name": {
      "type": "string",
      "enum": ["CONSERVATIVE", "BALANCED", "AGGRESSIVE"]
    },
    "weights": {
      "type": "object",
      "required": ["files_touched", "simulation_core", "determinism_delta",
                   "diff_line_count", "retry_count", "historical_failure"],
      "properties": {
        "files_touched": { "type": "number", "minimum": 0, "maximum": 1 },
        "simulation_core": { "type": "number", "minimum": 0, "maximum": 1 },
        "determinism_delta": { "type": "number", "minimum": 0, "maximum": 1 },
        "diff_line_count": { "type": "number", "minimum": 0, "maximum": 1 },
        "retry_count": { "type": "number", "minimum": 0, "maximum": 1 },
        "historical_failure": { "type": "number", "minimum": 0, "maximum": 1 }
      },
      "additionalProperties": false
    },
    "thresholds": {
      "type": "object",
      "properties": {
        "low_max": { "type": "number", "default": 30 },
        "medium_max": { "type": "number", "default": 60 },
        "high_max": { "type": "number", "default": 80 }
      }
    },
    "context_multipliers": {
      "type": "object",
      "additionalProperties": { "type": "number" }
    }
  }
}
```

### 9.4 Outcome Record Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "RiskOutcome",
  "type": "object",
  "required": ["task_id", "predicted_level", "actual_outcome"],
  "properties": {
    "task_id": { "type": "string" },
    "predicted_score": { "type": "number" },
    "predicted_level": {
      "type": "string",
      "enum": ["LOW", "MEDIUM", "HIGH", "CRITICAL"]
    },
    "actual_outcome": {
      "type": "string",
      "enum": ["SUCCESS", "FAILURE", "TIMEOUT", "CANCELLED"]
    },
    "outcome_type": {
      "type": "string",
      "enum": ["TRUE_POSITIVE", "FALSE_POSITIVE", "TRUE_NEGATIVE", "FALSE_NEGATIVE"]
    },
    "executed_at": { "type": "string", "format": "date-time" },
    "reviewed_by": { "type": "string" },
    "review_notes": { "type": "string" }
  }
}
```

---

## 10. PSEUDO-IMPLEMENTATION

### 10.1 Core Risk Engine Class
```python
class RiskScoringEngine:
    """
    Production-ready risk scoring engine for AI-Native Game Studio OS.
    """
    
    def __init__(self, config: EngineConfig):
        self.config = config
        self.weights = self._load_weights(config.default_profile)
        self.metrics = MetricsCollector()
        self.cache = LRUCache(maxsize=1000)
        self.circuit_breaker = CircuitBreaker(**CIRCUIT_BREAKER_CONFIG)
        
    def calculate_risk(self, request: RiskRequest) -> RiskResponse:
        """Main entry point for risk calculation."""
        start_time = time.monotonic()
        
        try:
            with self.circuit_breaker:
                # Check cache
                cache_key = self._generate_cache_key(request)
                if cache_key in self.cache:
                    return self.cache[cache_key]
                
                # Calculate normalized factors
                factors = self._calculate_factors(request)
                
                # Apply context multipliers
                factors = self._apply_context_multipliers(factors, request.context)
                
                # Compute weighted score
                risk_score = self._compute_score(factors)
                
                # Determine risk level and action
                risk_level = self._classify_risk(risk_score)
                action = self._determine_action(risk_level, request)
                
                # Build response
                response = RiskResponse(
                    task_id=request.task_id,
                    risk_score=round(risk_score, 2),
                    risk_level=risk_level,
                    recommended_action=action,
                    confidence=self._calculate_confidence(factors),
                    factor_breakdown=factors,
                    weights_used={
                        "config_name": self.config.active_profile,
                        "weights": self.weights
                    },
                    processing_time_ms=int((time.monotonic() - start_time) * 1000),
                    timestamp=datetime.utcnow().isoformat()
                )
                
                # Cache and return
                self.cache[cache_key] = response
                self.metrics.record_calculation(response)
                return response
                
        except CircuitBreakerOpen:
            return self._fallback_response(request, "CIRCUIT_OPEN")
        except Exception as e:
            logger.error(f"Risk calculation failed: {e}")
            return self._fallback_response(request, "ERROR")
    
    def _calculate_factors(self, request: RiskRequest) -> Dict[str, float]:
        """Calculate all normalized risk factors."""
        return {
            "files_touched": self._normalize_files_touched(
                len(request.files_touched)
            ),
            "simulation_core": self._check_simulation_core(
                request.files_touched, request.diff_content
            ),
            "determinism_delta": self._get_determinism_delta(
                request.files_touched
            ),
            "diff_line_count": self._normalize_diff_lines(
                request.diff_content
            ),
            "retry_count": self._normalize_retry_count(
                request.retry_count
            ),
            "historical_failure": self._get_historical_failure_rate(
                request.task_type
            )
        }
    
    def _normalize_files_touched(self, count: int) -> float:
        """Log-scaled normalization for file count."""
        return min(1.0, math.log2(count + 1) / math.log2(101))
    
    def _check_simulation_core(self, files: List[str], diff: str) -> float:
        """Binary check for simulation core patterns."""
        patterns = SIMULATION_CORE_PATTERNS
        for file in files:
            if any(re.search(p, file) for p in patterns):
                return 1.0
        if diff and any(p in diff for p in patterns):
            return 1.0
        return 0.0
    
    def _get_determinism_delta(self, files: List[str]) -> float:
        """Fetch determinism variance from checker service."""
        variance = determinism_checker.get_variance(files)
        # Sigmoid normalization
        return 1 / (1 + math.exp(-10 * (variance - 0.05)))
    
    def _normalize_diff_lines(self, diff: Optional[str]) -> float:
        """Sqrt-scaled normalization for diff line count."""
        if not diff:
            return 0.0
        lines = len(diff.splitlines())
        return min(1.0, math.sqrt(lines) / math.sqrt(1000))
    
    def _normalize_retry_count(self, retries: int) -> float:
        """Exponential decay normalization for retries."""
        return 1 - math.exp(-retries / 3)
    
    def _get_historical_failure_rate(self, task_type: str) -> float:
        """Windowed moving average of failure rate."""
        return outcome_store.get_failure_rate(task_type, window=20)
    
    def _compute_score(self, factors: Dict[str, float]) -> float:
        """Compute weighted risk score."""
        score = sum(
            self.weights[factor] * value
            for factor, value in factors.items()
        )
        return min(100, max(0, score * 100))
    
    def _classify_risk(self, score: float) -> RiskLevel:
        """Classify score into risk level."""
        if score <= 30:
            return RiskLevel.LOW
        elif score <= 60:
            return RiskLevel.MEDIUM
        elif score <= 80:
            return RiskLevel.HIGH
        else:
            return RiskLevel.CRITICAL
    
    def _determine_action(
        self, 
        level: RiskLevel, 
        request: RiskRequest
    ) -> Action:
        """Determine recommended action based on risk level."""
        action_map = {
            RiskLevel.LOW: Action.AUTO_APPROVE,
            RiskLevel.MEDIUM: Action.REVIEW,
            RiskLevel.HIGH: Action.SENIOR_REVIEW,
            RiskLevel.CRITICAL: Action.BLOCK
        }
        
        # Check for overrides
        if self._is_emergency_override(request):
            return Action.AUTO_APPROVE
            
        return action_map[level]
    
    def _fallback_response(
        self, 
        request: RiskRequest, 
        reason: str
    ) -> RiskResponse:
        """Generate fallback response during failures."""
        return RiskResponse(
            task_id=request.task_id,
            risk_score=75.0,  # Conservative default
            risk_level=RiskLevel.HIGH,
            recommended_action=Action.SENIOR_REVIEW,
            confidence=0.5,
            factor_breakdown={},
            weights_used={"config_name": "FALLBACK", "weights": {}},
            processing_time_ms=0,
            timestamp=datetime.utcnow().isoformat(),
            fallback_reason=reason
        )
```

### 10.2 Weight Tuner (Weekly Adjustment)
```python
class WeightTuner:
    """Adjusts weights based on outcome feedback."""
    
    def __init__(self, engine: RiskScoringEngine):
        self.engine = engine
        self.adjustment_rate = 0.02
        
    def run_weekly_adjustment(self) -> WeightAdjustment:
        """Execute weekly weight tuning cycle."""
        outcomes = self._fetch_last_week_outcomes()
        current_weights = self.engine.weights.copy()
        
        # Calculate misprediction rates per factor
        adjustments = {}
        for factor in FACTORS:
            fp_rate = self._calculate_fp_rate(outcomes, factor)
            fn_rate = self._calculate_fn_rate(outcomes, factor)
            
            if fp_rate > fn_rate + 0.05:
                adjustments[factor] = -self.adjustment_rate * fp_rate
            elif fn_rate > fp_rate + 0.05:
                adjustments[factor] = self.adjustment_rate * fn_rate
            else:
                adjustments[factor] = 0
        
        # Apply adjustments with bounds
        new_weights = {}
        for factor, weight in current_weights.items():
            new_weights[factor] = clamp(
                weight + adjustments.get(factor, 0),
                0.05,  # Minimum weight
                0.50   # Maximum weight
            )
        
        # Renormalize
        total = sum(new_weights.values())
        new_weights = {k: v/total for k, v in new_weights.items()}
        
        # Log and apply
        adjustment = WeightAdjustment(
            old_weights=current_weights,
            new_weights=new_weights,
            adjustments=adjustments,
            outcome_summary=self._summarize_outcomes(outcomes),
            timestamp=datetime.utcnow().isoformat()
        )
        
        self.engine.weights = new_weights
        return adjustment
```

### 10.3 Determinism Checker Integration
```python
class DeterminismChecker:
    """Interface to determinism validation system."""
    
    def __init__(self, service_url: str):
        self.service_url = service_url
        self.cache = TTLCache(maxsize=100, ttl=300)
    
    def get_variance(self, files: List[str]) -> float:
        """Get determinism variance for file set."""
        cache_key = hash(tuple(sorted(files)))
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        try:
            response = requests.post(
                f"{self.service_url}/variance",
                json={"files": files},
                timeout=5
            )
            variance = response.json()["variance"]
            self.cache[cache_key] = variance
            return variance
        except Exception as e:
            logger.warning(f"Determinism check failed: {e}")
            return 0.5  # Conservative default
```

---

## 11. OPERATIONAL EXAMPLE

### 11.1 Complete Workflow Example
```
┌──────────────────────────────────────────────────────────────────────────┐
│ SCENARIO: AI agent generates code for player movement system             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│ INPUT DATA:                                                              │
│ ───────────────────────────────────────────────────────────────────────  │
│ task_id:          "task-2024-001-movement-refactor"                      │
│ task_type:        CODE_GEN                                               │
│ files_touched:    ["PlayerController.cs", "PhysicsHelper.cs"]            │
│ diff_lines:       245 lines                                              │
│ retry_count:      2                                                      │
│ author:           "ai-agent-7"                                           │
│ branch:           "feature/player-movement"                              │
│ test_coverage:    0.75                                                   │
│                                                                          │
│ FACTOR CALCULATION:                                                      │
│ ───────────────────────────────────────────────────────────────────────  │
│ files_touched_norm  = log₂(2+1)/log₂(101) = 0.24                         │
│ simulation_core     = 1.0 (matches PhysicsHelper.cs)                     │
│ determinism_delta   = 0.12 (low variance from baseline)                  │
│ diff_line_count_norm= √245/√1000 = 0.49                                  │
│ retry_count_norm    = 1-e^(-2/3) = 0.49                                  │
│ historical_failure  = 0.08 (8% failure rate for CODE_GEN)                │
│                                                                          │
│ WEIGHT APPLICATION (BALANCED CONFIG):                                    │
│ ───────────────────────────────────────────────────────────────────────  │
│ Component           │ Raw    │ Weight │ Contribution                      │
│ ────────────────────┼────────┼────────┼─────────────────────────────────  │
│ files_touched       │ 0.24   │ 0.20   │ 4.8                               │
│ simulation_core     │ 1.00   │ 0.20   │ 20.0                              │
│ determinism_delta   │ 0.12   │ 0.20   │ 2.4                               │
│ diff_line_count     │ 0.49   │ 0.20   │ 9.8                               │
│ retry_count         │ 0.49   │ 0.12   │ 5.9                               │
│ historical_failure  │ 0.08   │ 0.08   │ 0.6                               │
│ ────────────────────┴────────┴────────┴─────────────────────────────────  │
│ RAW SCORE: 43.5                                                          │
│                                                                          │
│ CONTEXT MULTIPLIERS:                                                     │
│ ───────────────────────────────────────────────────────────────────────  │
│ test_coverage > 80%? No → ×1.0                                           │
│ feature branch? Yes → ×0.95                                              │
│ business hours? Yes → ×0.90                                              │
│                                                                          │
│ FINAL SCORE: 43.5 × 0.95 × 0.90 = 37.2                                   │
│                                                                          │
│ RISK CLASSIFICATION: MEDIUM (31-60)                                      │
│ RECOMMENDED ACTION: STANDARD REVIEW (4-hour SLA)                         │
│                                                                          │
│ EXECUTION FLOW:                                                          │
│ ───────────────────────────────────────────────────────────────────────  │
│ 1. Risk engine returns score 37.2, level MEDIUM                          │
│ 2. Task queued for standard review                                       │
│ 3. Reviewer notification sent to #code-reviews                           │
│ 4. Reviewer approves after 45 minutes                                    │
│ 5. Code merged to feature branch                                         │
│ 6. Outcome recorded as TRUE_NEGATIVE (predicted MEDIUM, succeeded)       │
│ 7. Metrics updated, weights unchanged (correct prediction)               │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### 11.2 Edge Case Examples
```
┌──────────────────────────────────────────────────────────────────────────┐
│ CASE 1: Critical Simulation Change                                       │
├──────────────────────────────────────────────────────────────────────────┤
│ Files: ["PhysicsEngine.cs", "RollbackSystem.cs"] (simulation_core=1.0)   │
│ Determinism variance: 0.15 (high)                                        │
│ BALANCED weights: simulation_core(0.20) + determinism_delta(0.20)        │
│ Base contribution: 20 + 20 = 40 points                                   │
│ Other factors push score to 78 → HIGH → SENIOR REVIEW                    │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────┤
│ CASE 2: Emergency Security Patch                                         │
│ Score calculated: 72 (HIGH)                                              │
│ Override triggered: security_patch flag                                  │
│ Override applied: -45 points                                             │
│ Final score: 27 (LOW) → AUTO-APPROVE                                     │
│ Executive notification sent for audit trail                              │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────┤
│ CASE 3: First-Time Task Type                                             │
│ Task type: "SHADER_GENERATION" (no historical data)                     │
│ Bootstrap: historical_failure = global_avg × 1.5 = 0.18                  │
│ Uncertainty bonus: +10 points                                            │
│ Score shifts from 42 → 52 (still MEDIUM, but closer to HIGH)             │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### 11.3 Failure Recovery Example
```
┌──────────────────────────────────────────────────────────────────────────┐
│ SCENARIO: Database unavailable during risk calculation                   │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│ 1. Request received for task "task-2024-002"                             │
│ 2. Attempt to fetch historical_failure_rate from database                │
│ 3. Database connection timeout after 3s                                  │
│ 4. Circuit breaker transitions: CLOSED → OPEN                            │
│ 5. Fallback mode activated                                               │
│ 6. Response generated:                                                   │
│    - risk_score: 75.0 (conservative default)                             │
│    - risk_level: HIGH                                                    │
│    - action: SENIOR_REVIEW                                               │
│    - fallback_reason: "DATABASE_UNAVAILABLE"                             │
│ 7. Alert sent to #risk-engine-alerts                                     │
│ 8. Task proceeds with elevated scrutiny                                  │
│ 9. After 30s, circuit breaker enters HALF_OPEN                           │
│ 10. Test request succeeds → CLOSED                                       │
│ 11. Normal operation resumes                                             │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## APPENDIX A: Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    RISK SCORING ENGINE - QUICK REF                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ FORMULA: RiskScore = Σ(wi × fi_norm) × 100                              │
│                                                                         │
│ WEIGHTS:                                                                │
│   Conservative: [0.15, 0.30, 0.25, 0.10, 0.12, 0.08]                    │
│   Balanced:     [0.20, 0.20, 0.20, 0.20, 0.12, 0.08]                    │
│   Aggressive:   [0.25, 0.15, 0.15, 0.25, 0.12, 0.08]                    │
│                                                                         │
│ THRESHOLDS:                                                             │
│   LOW      [0-30]   → AUTO-APPROVE                                      │
│   MEDIUM   [31-60]  → REVIEW (4h SLA)                                   │
│   HIGH     [61-80]  → SENIOR_REVIEW (1h SLA)                            │
│   CRITICAL [81-100] → BLOCK (human only)                                │
│                                                                         │
│ NORMALIZATION:                                                          │
│   files:      log₂(x+1)/log₂(101)                                       │
│   sim_core:   binary flag                                               │
│   determinism: 1/(1+e^(-10(x-0.05)))                                    │
│   diff_lines: √x/√1000                                                  │
│   retries:    1-e^(-x/3)                                                │
│   history:    windowed moving average                                   │
│                                                                         │
│ TARGETS:                                                                │
│   FP rate < 5%, FN rate < 2%, Latency p99 < 10s                         │
│   Auto-approval 40-60%, Escalation accuracy > 90%                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## APPENDIX B: Configuration File Example

```yaml
# risk_engine_config.yaml
version: "1.0"

profiles:
  conservative:
    weights:
      files_touched: 0.15
      simulation_core: 0.30
      determinism_delta: 0.25
      diff_line_count: 0.10
      retry_count: 0.12
      historical_failure: 0.08
    thresholds:
      low_max: 25      # More strict
      medium_max: 55
      high_max: 75
      
  balanced:
    weights:
      files_touched: 0.20
      simulation_core: 0.20
      determinism_delta: 0.20
      diff_line_count: 0.20
      retry_count: 0.12
      historical_failure: 0.08
    thresholds:
      low_max: 30
      medium_max: 60
      high_max: 80
      
  aggressive:
    weights:
      files_touched: 0.25
      simulation_core: 0.15
      determinism_delta: 0.15
      diff_line_count: 0.25
      retry_count: 0.12
      historical_failure: 0.08
    thresholds:
      low_max: 35      # More lenient
      medium_max: 65
      high_max: 85

default_profile: balanced

context_multipliers:
  business_hours: 0.90
  weekend: 1.15
  release_freeze: 1.30
  new_engineer: 1.20
  senior_engineer: 0.85
  high_test_coverage: 0.90
  no_test_coverage: 1.25
  main_branch: 1.10
  feature_branch: 0.95

overrides:
  emergency_security_patch:
    action: AUTO_APPROVE
    notification: executive
  production_outage:
    action: AUTO_APPROVE
    notification: pagerduty
  data_corruption:
    action: BLOCK
    notification: pagerduty

circuit_breaker:
  failure_threshold: 5
  recovery_timeout: 30
  half_open_max_calls: 3
  success_threshold: 2

tuning:
  adjustment_rate: 0.02
  min_weight: 0.05
  max_weight: 0.50
  weekly_schedule: "0 2 * * 0"  # Sunday 2 AM
```

---

*Document Version: 1.0*  
*Last Updated: 2024*  
*Owner: Domain 06 - Risk Scoring Engine Design*
