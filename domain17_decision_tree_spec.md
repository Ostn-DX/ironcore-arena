# Model Selection Decision Tree Engine Specification
## AI-Native Game Studio OS - Domain Agent 17
### Version 1.0.0 | Ultra-Dense Technical Specification

---

## 1. DECISION TREE ARCHITECTURE

### 1.1 Hierarchical Structure

```
ROOT: TaskClassifier
│
├─[N1] DeterminismGate (Binary Split)
│   ├─ TRUE → DeterministicBranch
│   │   ├─[N1.1] SafetyCheck (safety_score)
│   │   │   ├─ FAIL → TERMINAL: HumanReview
│   │   │   └─ PASS → [N1.2] ComplexityGate
│   │   │       ├─ LOW → TERMINAL: Codex
│   │   │       └─ HIGH → TERMINAL: LocalLLM
│   │
│   └─ FALSE → ProbabilisticBranch
│       ├─[N2.1] RiskAssessment (risk_score ∈ [0,100])
│       │   ├─ CRITICAL (risk>75) → TERMINAL: HumanReview
│       │   ├─ HIGH (50<risk≤75) → [N2.2] BudgetGate
│       │   │   ├─ INSUFFICIENT (budget<15%) → TERMINAL: LocalLLM
│       │   │   └─ SUFFICIENT → TERMINAL: ClaudeOpus
│       │   └─ MODERATE (risk≤50) → [N2.3] LatencyGate
│       │       ├─ STRICT (latency<100ms) → TERMINAL: LocalLLM
│       │       └─ RELAXED → [N2.4] ContextGate
│       │           ├─ LARGE (ctx>100k) → TERMINAL: ClaudeOpus
│       │           └─ SMALL → TERMINAL: ClaudeHaiku
│
└─[N3] FallbackRouter (Error Recovery)
    ├─ RETRY → ROOT (max_depth=3)
    ├─ DEGRADE → LowerCapabilityModel
    └─ ESCALATE → TERMINAL: HumanReview
```

### 1.2 Node Depth Analysis

| Depth | Nodes | Purpose |
|-------|-------|---------|
| 0 | 1 | Root classification |
| 1 | 2 | Determinism bifurcation |
| 2 | 4 | Risk/Budget/Latency/Context gates |
| 3 | 6 | Terminal resolution |
| 4 | 3 | Fallback recovery |

**Max Traversal Depth:** 4  
**Average Path Length:** 2.7 nodes  
**Branching Factor:** 1.8 (weighted average)

---

## 2. NODE LOGIC WITH MATHEMATICAL THRESHOLDS

### 2.1 Decision Node Specifications

| NodeID | Function | Condition | TrueBranch | FalseBranch | Threshold |
|--------|----------|-----------|------------|-------------|-----------|
| N1 | `is_deterministic(T)` | `det_score > 0.85` | N1.1 | N2.1 | 0.85 |
| N1.1 | `safety_check(T)` | `safety_score ≥ 90` | N1.2 | T_Human | 90 |
| N1.2 | `complexity_gate(T)` | `comp_score > 100` | T_Local | T_Codex | 100 |
| N2.1 | `risk_assess(T)` | `risk_score > 75` | T_Human | N2.2 | 75 |
| N2.2 | `budget_gate(T)` | `budget_pct < 15` | T_Local | T_ClaudeOpus | 15 |
| N2.3 | `latency_gate(T)` | `latency_req < 100` | T_Local | N2.4 | 100ms |
| N2.4 | `context_gate(T)` | `ctx_tokens > 100000` | T_ClaudeOpus | T_ClaudeHaiku | 100k |
| N3 | `fallback_router(E)` | `retry_count < 3` | ROOT | T_Human | 3 |

### 2.2 Scoring Functions

#### Complexity Score (CS)
```
CS(T) = α·LOC + β·AST_DEPTH + γ·DEP_COUNT + δ·DATA_FLOW

Where:
  α = 0.4 (lines of code weight)
  β = 0.3 (AST nesting depth weight)
  γ = 0.2 (dependency count weight)
  δ = 0.1 (data flow complexity weight)

Thresholds:
  LOW:    CS ≤ 100
  MEDIUM: 100 < CS ≤ 300
  HIGH:   CS > 300
```

#### Risk Score (RS)
```
RS(T) = Σ(w_i · f_i) for i ∈ {financial, legal, reputational, operational, safety}

Component Functions:
  f_financial = min(100, transaction_value / 1000)
  f_legal = PII_count × 10 + regulatory_flag × 25
  f_reputational = brand_exposure × 20 + public_visibility × 15
  f_operational = downtime_cost / 100
  f_safety = user_safety_impact × 30

Weights:
  w = [0.25, 0.30, 0.20, 0.15, 0.10]

Normalization:
  RS_norm = min(100, max(0, RS))
```

#### Determinism Score (DS)
```
DS(T) = 1 - entropy(T) / max_entropy

entropy(T) = -Σ p(x) · log₂(p(x))

Classification:
  DETERMINISTIC:  DS ≥ 0.85
  STOCHASTIC:     DS < 0.85
```

### 2.3 Threshold Matrix

| Metric | Critical | High | Medium | Low | Negligible |
|--------|----------|------|--------|-----|------------|
| Risk Score | >75 | 50-75 | 25-50 | 10-25 | <10 |
| Complexity | >500 | 300-500 | 100-300 | 50-100 | <50 |
| Budget % | <10 | 10-15 | 15-25 | 25-40 | >40 |
| Latency (ms) | <50 | 50-100 | 100-500 | 500-1000 | >1000 |
| Context (k) | >200 | 100-200 | 50-100 | 10-50 | <10 |

---

## 3. FEATURE EVALUATION ORDER

### 3.1 Priority Queue (Descending)

```
PriorityRank = Σ(w_j · urgency_j · availability_j)
```

| Rank | Feature | Evaluation Function | Weight | Urgency Factor |
|------|---------|---------------------|--------|----------------|
| 1 | Determinism Required | `requires_deterministic_output()` | 0.30 | 1.0 |
| 2 | Risk Profile | `calculate_risk_vector()` | 0.25 | 0.95 |
| 3 | Complexity Index | `measure_task_complexity()` | 0.20 | 0.90 |
| 4 | Budget Constraint | `get_available_budget()` | 0.15 | 0.85 |
| 5 | Latency Requirement | `get_latency_sla()` | 0.07 | 0.80 |
| 6 | Context Window | `estimate_token_count()` | 0.03 | 0.75 |

### 3.2 Evaluation Pipeline

```python
# Pseudocode: Feature Evaluation Order
def evaluate_features(task):
    features = {}
    
    # P1: Determinism (blocking)
    features['deterministic'] = check_determinism_requirement(task)
    if features['deterministic']:
        return deterministic_branch(task)
    
    # P2: Risk (blocking if critical)
    features['risk'] = calculate_risk(task)
    if features['risk'] > 75:
        return route_to_human(task)
    
    # P3-P6: Parallel evaluation
    with concurrent_executor:
        features['complexity'] = measure_complexity(task)
        features['budget'] = get_budget_allocation(task)
        features['latency'] = get_latency_requirement(task)
        features['context'] = estimate_context_size(task)
    
    return features
```

### 3.3 Lazy Evaluation Rules

| Condition | Skip Evaluation | Reason |
|-----------|-----------------|--------|
| `risk > 75` | complexity, budget, latency | Human override |
| `deterministic = true` | risk, budget | Deterministic branch |
| `budget < 5%` | latency, context | Cost-constrained |
| `latency < 50ms` | complexity, context | Speed-critical |

---

## 4. TERMINAL NODE DEFINITIONS

### 4.1 Terminal Specifications

| TerminalID | Model | Provider | Capability | Confidence | Cost/1M | Latency |
|------------|-------|----------|------------|------------|---------|---------|
| T_Codex | codex-1.5-sonnet | Anthropic | Code gen | 0.85 | $3.00 | 800ms |
| T_ClaudeOpus | claude-3-opus | Anthropic | Complex reasoning | 0.92 | $15.00 | 1200ms |
| T_ClaudeHaiku | claude-3-haiku | Anthropic | Fast inference | 0.78 | $0.25 | 200ms |
| T_LocalLLM | llama-3.1-70b | Local | Privacy-first | 0.75 | $0.00 | 500ms |
| T_Human | human-expert | Internal | Judgment | 1.00 | $150.00 | 3600000ms |

### 4.2 Terminal Selection Matrix

| Task Type | Primary | Fallback | Emergency |
|-----------|---------|----------|-----------|
| Code Generation | T_Codex | T_ClaudeOpus | T_LocalLLM |
| Complex Analysis | T_ClaudeOpus | T_LocalLLM | T_Human |
| Quick Response | T_ClaudeHaiku | T_LocalLLM | T_Human |
| Sensitive Data | T_LocalLLM | T_Human | - |
| High-Risk Decision | T_Human | - | - |
| Real-time Inference | T_LocalLLM | T_ClaudeHaiku | T_Human |

### 4.3 Terminal Confidence Calibration

```
Confidence(Terminal) = base_confidence × calibration_factor × recency_decay

calibration_factor = accuracy_history / expected_accuracy
recency_decay = exp(-λ · time_since_last_use)

λ = 0.1 (decay constant)
```

| Terminal | Base | Calibrated Range | Decay Half-life |
|----------|------|------------------|-----------------|
| T_Codex | 0.85 | 0.80-0.90 | 7 days |
| T_ClaudeOpus | 0.92 | 0.88-0.95 | 14 days |
| T_ClaudeHaiku | 0.78 | 0.75-0.82 | 3 days |
| T_LocalLLM | 0.75 | 0.70-0.80 | 5 days |
| T_Human | 1.00 | 1.00 | ∞ |

---

## 5. CONFIDENCE SCORING

### 5.1 Confidence Aggregation

```
TotalConfidence = Π(confidence_i) ^ (1/n) × path_penalty × override_factor

path_penalty = 1 - (path_depth / max_depth) × 0.1
override_factor = 0.8 if override_applied else 1.0
```

### 5.2 Node-Level Confidence

| Node Type | Confidence Formula | Min Threshold |
|-----------|-------------------|---------------|
| Classification | `max(p_class) / Σp` | 0.70 |
| Threshold | `1 - |value - threshold| / range` | 0.60 |
| Routing | `similarity(query, route_pattern)` | 0.65 |
| Terminal | `model_accuracy × task_fit` | 0.50 |

### 5.3 Confidence Decay by Path Length

| Path Length | Confidence Multiplier | Effective Min |
|-------------|----------------------|---------------|
| 1 | 1.00 | 0.70 |
| 2 | 0.95 | 0.665 |
| 3 | 0.90 | 0.63 |
| 4 | 0.85 | 0.595 |
| 5+ | 0.80 | 0.56 |

### 5.4 Confidence Action Matrix

| Confidence Range | Action | Escalation |
|------------------|--------|------------|
| ≥0.90 | Execute immediately | None |
| 0.75-0.89 | Execute with logging | Monitor |
| 0.60-0.74 | Execute with verification | Alert |
| 0.40-0.59 | Request secondary check | Review |
| <0.40 | Block execution | Human review |

---

## 6. OVERRIDE MECHANISMS

### 6.1 Override Types

| OverrideID | Trigger | Authority | Effect | Audit Level |
|------------|---------|-----------|--------|-------------|
| OVR_SAFETY | safety_flag=true | SYSTEM | Force T_Human | CRITICAL |
| OVR_COST | budget_exceeded | SYSTEM | Force T_LocalLLM | HIGH |
| OVR_SPEED | latency_critical | SYSTEM | Force T_ClaudeHaiku | MEDIUM |
| OVR_MANUAL | user_override | USER | Force specified | CRITICAL |
| OVR_LEARN | pattern_match | SYSTEM | Suggest override | LOW |
| OVR_DEGRADE | model_unavailable | SYSTEM | Fallback chain | HIGH |

### 6.2 Override Priority Stack

```
Priority(Override) = base_priority × urgency × authority_level

Execution Order:
  1. OVR_SAFETY (priority: 1000)
  2. OVR_MANUAL (priority: 900)
  3. OVR_DEGRADE (priority: 800)
  4. OVR_COST (priority: 700)
  5. OVR_SPEED (priority: 600)
  6. OVR_LEARN (priority: 400)
```

### 6.3 Override Resolution

```python
def resolve_overrides(overrides, decision_tree):
    sorted_overrides = sorted(overrides, key=lambda o: o.priority, reverse=True)
    
    for override in sorted_overrides:
        if override.condition_met():
            if override.type == 'BLOCKING':
                return apply_override(override)
            elif override.type == 'SUGGESTION':
                decision_tree.add_suggestion(override)
    
    return decision_tree.execute()
```

### 6.4 Override Logging Schema

```json
{
  "override_id": "uuid",
  "timestamp": "ISO8601",
  "trigger": "safety_flag",
  "original_decision": "T_ClaudeOpus",
  "override_decision": "T_Human",
  "authority": "system_auto",
  "justification": "PII_detected_in_input",
  "confidence_impact": -0.15,
  "audit_trail": ["node_1", "node_2", "override_applied"]
}
```

---

## 7. SUCCESS CRITERIA (MEASURABLE)

### 7.1 Primary KPIs

| KPI | Formula | Target | Measurement |
|-----|---------|--------|-------------|
| Selection Accuracy | `correct_selections / total_selections` | ≥92% | Weekly |
| Latency Compliance | `sla_met / total_requests` | ≥99% | Real-time |
| Cost Efficiency | `optimal_cost / actual_cost` | ≤1.15 | Monthly |
| Human Escalation Rate | `human_routed / total` | ≤8% | Weekly |
| Confidence Calibration | `|predicted - actual|` | ≤0.05 | Quarterly |

### 7.2 Secondary KPIs

| KPI | Formula | Target | Measurement |
|-----|---------|--------|-------------|
| Path Efficiency | `optimal_path_length / actual_path_length` | ≥0.85 | Weekly |
| Override Necessity | `justified_overrides / total_overrides` | ≥95% | Monthly |
| Model Utilization | `requests_per_model / total_requests` | Balanced | Weekly |
| Fallback Success | `fallback_success / fallback_attempts` | ≥90% | Monthly |
| User Satisfaction | `satisfied_users / total_users` | ≥85% | Quarterly |

### 7.3 Success Thresholds by Terminal

| Terminal | Accuracy Target | Latency Target | Cost Target |
|----------|-----------------|----------------|-------------|
| T_Codex | 88% | <1000ms | <$5/req |
| T_ClaudeOpus | 94% | <1500ms | <$20/req |
| T_ClaudeHaiku | 80% | <300ms | <$1/req |
| T_LocalLLM | 75% | <600ms | $0 |
| T_Human | 98% | <4hrs | <$200/req |

### 7.4 Composite Success Score

```
SuccessScore = Σ(w_k · normalized(kpi_k)) for k ∈ KPIs

Weights:
  accuracy: 0.30
  latency: 0.25
  cost: 0.20
  escalation: 0.15
  satisfaction: 0.10

Target: SuccessScore ≥ 0.90
```

---

## 8. FAILURE STATES

### 8.1 Failure Classification

| FailureID | Type | Severity | Auto-Recovery | Escalation |
|-----------|------|----------|---------------|------------|
| F001 | Classification Error | HIGH | Retry (max 3) | Human |
| F002 | Threshold Mismatch | MEDIUM | Recalibrate | System |
| F003 | Model Unavailable | HIGH | Fallback chain | System |
| F004 | Confidence Too Low | MEDIUM | Secondary check | Human |
| F005 | Budget Exhausted | CRITICAL | Block + Alert | Human |
| F006 | Latency Violation | HIGH | Degrade model | System |
| F007 | Safety Violation | CRITICAL | Block + Audit | Human |
| F008 | Override Conflict | HIGH | Priority resolve | Human |

### 8.2 Failure Detection

```python
def detect_failure(state, decision):
    failures = []
    
    if decision.confidence < 0.40:
        failures.append(Failure.F004)
    
    if decision.selected_model.status == 'unavailable':
        failures.append(Failure.F003)
    
    if state.budget.remaining < state.budget.critical_threshold:
        failures.append(Failure.F005)
    
    if state.latency.actual > state.latency.sla * 1.5:
        failures.append(Failure.F006)
    
    if state.safety.violation_detected:
        failures.append(Failure.F007)
    
    return failures
```

### 8.3 Recovery Procedures

| Failure | Immediate Action | Recovery Time | Fallback |
|---------|------------------|---------------|----------|
| F001 | Retry with different features | 100ms | Human review |
| F002 | Use default thresholds | 50ms | Recalibration job |
| F003 | Route to next available | 10ms | T_LocalLLM |
| F004 | Request confidence boost | 200ms | Secondary model |
| F005 | Queue + alert finance | 0ms | Emergency budget |
| F006 | Degrade to faster model | 5ms | T_ClaudeHaiku |
| F007 | Block + security audit | 0ms | Security team |
| F008 | Apply priority override | 1ms | Human arbitration |

### 8.4 Failure Rate Targets

| Failure Type | Target Rate | Alert Threshold |
|--------------|-------------|-----------------|
| Classification Error | <2% | >5% |
| Model Unavailable | <1% | >3% |
| Confidence Low | <5% | >10% |
| Budget Exhausted | <0.1% | >0.5% |
| Latency Violation | <3% | >7% |
| Safety Violation | <0.01% | >0.1% |

---

## 9. INTEGRATION SURFACE

### 9.1 API Endpoints

| Endpoint | Method | Input | Output | Rate Limit |
|----------|--------|-------|--------|------------|
| `/v1/select` | POST | TaskSpec | ModelSelection | 1000/min |
| `/v1/batch` | POST | TaskSpec[] | Selection[] | 100/min |
| `/v1/feedback` | POST | FeedbackPayload | Ack | 500/min |
| `/v1/health` | GET | - | HealthStatus | No limit |
| `/v1/metrics` | GET | TimeRange | MetricsReport | 60/min |
| `/v1/override` | POST | OverrideSpec | OverrideResult | 50/min |

### 9.2 Input Schema (TaskSpec)

```json
{
  "task_id": "uuid",
  "task_type": "code_generation|analysis|reasoning|creative",
  "input_hash": "sha256",
  "estimated_tokens": 1000,
  "complexity_hints": {
    "lines_of_code": 50,
    "ast_depth": 5,
    "dependency_count": 10
  },
  "constraints": {
    "max_latency_ms": 500,
    "max_cost_usd": 5.00,
    "deterministic_required": false,
    "privacy_level": "standard|sensitive|critical"
  },
  "context": {
    "previous_selections": [],
    "user_preference": "speed|quality|cost",
    "project_id": "string"
  }
}
```

### 9.3 Output Schema (ModelSelection)

```json
{
  "selection_id": "uuid",
  "task_id": "uuid",
  "selected_model": "claude-3-opus",
  "confidence": 0.92,
  "path_taken": ["N1", "N2.1", "N2.2"],
  "estimated_cost_usd": 2.50,
  "estimated_latency_ms": 800,
  "fallback_chain": ["claude-3-sonnet", "local-llm"],
  "overrides_applied": [],
  "reasoning": "High complexity + sufficient budget",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### 9.4 Event Streaming

| Event Type | Topic | Payload Size | Frequency |
|------------|-------|--------------|-----------|
| selection.made | `model.selection` | ~500B | Per request |
| override.triggered | `model.override` | ~800B | As needed |
| failure.detected | `model.failure` | ~1KB | As needed |
| metrics.snapshot | `model.metrics` | ~5KB | 1/min |
| calibration.update | `model.calibration` | ~2KB | 1/hour |

### 9.5 Integration Patterns

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Game Studio   │────▶│  Decision Tree  │────▶│  Model Pool     │
│     Client      │     │     Engine      │     │ (Codex/Claude)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         │                       ▼                       │
         │              ┌─────────────────┐              │
         │              │  Feedback Loop  │◀─────────────┘
         │              │  (Metrics/Calib)│
         └─────────────▶│                 │
                        └─────────────────┘
```

---

## 10. JSON SCHEMAS

### 10.1 TaskSpec Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://studio.ai/taskspec.json",
  "title": "Task Specification",
  "type": "object",
  "required": ["task_id", "task_type", "input_hash"],
  "properties": {
    "task_id": {
      "type": "string",
      "format": "uuid",
      "description": "Unique task identifier"
    },
    "task_type": {
      "type": "string",
      "enum": ["code_generation", "analysis", "reasoning", "creative", "classification"]
    },
    "input_hash": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$",
      "description": "SHA-256 hash of input content"
    },
    "estimated_tokens": {
      "type": "integer",
      "minimum": 1,
      "maximum": 200000
    },
    "complexity_hints": {
      "type": "object",
      "properties": {
        "lines_of_code": {"type": "integer", "minimum": 0},
        "ast_depth": {"type": "integer", "minimum": 1},
        "dependency_count": {"type": "integer", "minimum": 0},
        "data_flow_complexity": {"type": "number", "minimum": 0, "maximum": 1}
      }
    },
    "constraints": {
      "type": "object",
      "properties": {
        "max_latency_ms": {"type": "integer", "minimum": 10},
        "max_cost_usd": {"type": "number", "minimum": 0},
        "deterministic_required": {"type": "boolean"},
        "privacy_level": {"type": "string", "enum": ["standard", "sensitive", "critical"]}
      }
    },
    "context": {
      "type": "object",
      "properties": {
        "previous_selections": {"type": "array", "items": {"type": "string"}},
        "user_preference": {"type": "string", "enum": ["speed", "quality", "cost", "balanced"]},
        "project_id": {"type": "string"}
      }
    }
  }
}
```

### 10.2 ModelSelection Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://studio.ai/modelselection.json",
  "title": "Model Selection Result",
  "type": "object",
  "required": ["selection_id", "task_id", "selected_model", "confidence"],
  "properties": {
    "selection_id": {"type": "string", "format": "uuid"},
    "task_id": {"type": "string", "format": "uuid"},
    "selected_model": {
      "type": "string",
      "enum": ["codex-1.5-sonnet", "claude-3-opus", "claude-3-haiku", "llama-3.1-70b", "human-expert"]
    },
    "confidence": {"type": "number", "minimum": 0, "maximum": 1},
    "path_taken": {"type": "array", "items": {"type": "string"}},
    "estimated_cost_usd": {"type": "number", "minimum": 0},
    "estimated_latency_ms": {"type": "integer", "minimum": 0},
    "fallback_chain": {"type": "array", "items": {"type": "string"}},
    "overrides_applied": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "override_type": {"type": "string"},
          "reason": {"type": "string"},
          "authority": {"type": "string"}
        }
      }
    },
    "reasoning": {"type": "string"},
    "timestamp": {"type": "string", "format": "date-time"}
  }
}
```

### 10.3 OverrideSpec Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://studio.ai/overridespec.json",
  "title": "Override Specification",
  "type": "object",
  "required": ["override_id", "override_type", "target_task_id"],
  "properties": {
    "override_id": {"type": "string", "format": "uuid"},
    "override_type": {
      "type": "string",
      "enum": ["SAFETY", "COST", "SPEED", "MANUAL", "LEARN", "DEGRADE"]
    },
    "target_task_id": {"type": "string", "format": "uuid"},
    "forced_model": {"type": "string"},
    "justification": {"type": "string", "minLength": 10},
    "authority": {"type": "string"},
    "expiry": {"type": "string", "format": "date-time"},
    "priority": {"type": "integer", "minimum": 1, "maximum": 1000}
  }
}
```

### 10.4 FeedbackPayload Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://studio.ai/feedback.json",
  "title": "Selection Feedback",
  "type": "object",
  "required": ["feedback_id", "selection_id", "outcome"],
  "properties": {
    "feedback_id": {"type": "string", "format": "uuid"},
    "selection_id": {"type": "string", "format": "uuid"},
    "outcome": {
      "type": "string",
      "enum": ["success", "partial", "failure", "unknown"]
    },
    "actual_cost_usd": {"type": "number"},
    "actual_latency_ms": {"type": "integer"},
    "output_quality_score": {"type": "number", "minimum": 0, "maximum": 1},
    "user_satisfaction": {"type": "integer", "minimum": 1, "maximum": 5},
    "corrections": {"type": "array", "items": {"type": "string"}},
    "timestamp": {"type": "string", "format": "date-time"}
  }
}
```

---

## 11. PSEUDO-IMPLEMENTATION

### 11.1 Core Engine Class

```python
class ModelSelectionEngine:
    def __init__(self, config):
        self.tree = DecisionTree(config.tree_config)
        self.overrides = OverrideManager(config.override_rules)
        self.calibrator = ConfidenceCalibrator(config.calibration)
        self.metrics = MetricsCollector()
        
    def select_model(self, task_spec: TaskSpec) -> ModelSelection:
        # Phase 1: Feature extraction
        features = self.extract_features(task_spec)
        
        # Phase 2: Override check
        active_overrides = self.overrides.check(task_spec, features)
        if active_overrides.has_blocking():
            return self.apply_override(active_overrides.get_highest_priority())
        
        # Phase 3: Tree traversal
        path, terminal = self.tree.traverse(features)
        
        # Phase 4: Confidence calculation
        confidence = self.calibrator.calculate(path, terminal, features)
        
        # Phase 5: Build result
        result = ModelSelection(
            task_id=task_spec.task_id,
            selected_model=terminal.model_id,
            confidence=confidence,
            path_taken=[n.id for n in path],
            overrides_applied=active_overrides.to_list()
        )
        
        # Phase 6: Record metrics
        self.metrics.record_selection(result)
        
        return result
    
    def extract_features(self, task_spec) -> FeatureVector:
        return FeatureVector(
            deterministic=self.check_determinism(task_spec),
            risk=self.calculate_risk(task_spec),
            complexity=self.measure_complexity(task_spec),
            budget=self.get_budget_status(task_spec),
            latency=self.get_latency_requirement(task_spec),
            context=self.estimate_context(task_spec)
        )
```

### 11.2 Decision Tree Traversal

```python
class DecisionTree:
    def __init__(self, config):
        self.root = self.build_tree(config)
        self.max_depth = config.max_depth
        
    def traverse(self, features: FeatureVector) -> Tuple[List[Node], Terminal]:
        path = []
        current = self.root
        depth = 0
        
        while not isinstance(current, Terminal) and depth < self.max_depth:
            path.append(current)
            
            # Evaluate node condition
            condition_result = current.evaluate(features)
            
            # Select next node
            if condition_result:
                current = current.true_branch
            else:
                current = current.false_branch
            
            depth += 1
        
        if not isinstance(current, Terminal):
            current = self.get_fallback_terminal(features)
        
        return path, current
    
    def build_tree(self, config) -> Node:
        # Build from configuration
        return Node.from_config(config.tree_structure)
```

### 11.3 Node Implementation

```python
class DecisionNode(Node):
    def __init__(self, node_id, condition_fn, threshold, true_branch, false_branch):
        self.id = node_id
        self.condition_fn = condition_fn
        self.threshold = threshold
        self.true_branch = true_branch
        self.false_branch = false_branch
        
    def evaluate(self, features: FeatureVector) -> bool:
        value = self.condition_fn(features)
        return value > self.threshold

class TerminalNode(Node):
    def __init__(self, model_id, base_confidence, cost_per_token, latency_profile):
        self.model_id = model_id
        self.base_confidence = base_confidence
        self.cost_per_token = cost_per_token
        self.latency_profile = latency_profile
```

### 11.4 Confidence Calibration

```python
class ConfidenceCalibrator:
    def __init__(self, config):
        self.history = ModelAccuracyHistory()
        self.decay_lambda = config.decay_lambda
        
    def calculate(self, path, terminal, features) -> float:
        # Base confidence from terminal
        base = terminal.base_confidence
        
        # Path penalty
        path_penalty = 1 - (len(path) / 4) * 0.1
        
        # Historical accuracy adjustment
        historical = self.history.get_accuracy(terminal.model_id)
        
        # Feature fit score
        fit_score = self.calculate_fit(terminal, features)
        
        # Combine
        confidence = base * path_penalty * (0.7 + 0.3 * historical) * fit_score
        
        return min(1.0, max(0.0, confidence))
    
    def calculate_fit(self, terminal, features) -> float:
        # Calculate how well terminal matches features
        scores = []
        
        if features.deterministic:
            scores.append(terminal.determinism_score)
        if features.risk > 50:
            scores.append(terminal.risk_handling_score)
        if features.complexity > 100:
            scores.append(terminal.complexity_score)
        
        return sum(scores) / len(scores) if scores else 0.8
```

### 11.5 Override Manager

```python
class OverrideManager:
    def __init__(self, rules):
        self.rules = rules
        self.active_overrides = []
        
    def check(self, task_spec, features) -> OverrideSet:
        overrides = OverrideSet()
        
        for rule in self.rules:
            if rule.condition(task_spec, features):
                overrides.add(Override(
                    type=rule.type,
                    priority=rule.priority,
                    forced_model=rule.forced_model,
                    justification=rule.justification
                ))
        
        return overrides
    
    def apply(self, override, selection) -> ModelSelection:
        return ModelSelection(
            task_id=selection.task_id,
            selected_model=override.forced_model,
            confidence=selection.confidence * 0.8,  # Penalty
            path_taken=selection.path_taken + ['override'],
            overrides_applied=selection.overrides_applied + [override.to_dict()]
        )
```

---

## 12. OPERATIONAL EXAMPLE

### 12.1 Scenario: Game Asset Code Generation

**Task Input:**
```json
{
  "task_id": "task_abc123",
  "task_type": "code_generation",
  "input_hash": "a1b2c3d4e5f6...",
  "estimated_tokens": 2500,
  "complexity_hints": {
    "lines_of_code": 150,
    "ast_depth": 8,
    "dependency_count": 25
  },
  "constraints": {
    "max_latency_ms": 2000,
    "max_cost_usd": 10.00,
    "deterministic_required": false,
    "privacy_level": "standard"
  },
  "context": {
    "previous_selections": ["codex-1.5-sonnet"],
    "user_preference": "quality",
    "project_id": "game_project_x"
  }
}
```

### 12.2 Execution Trace

```
[00:00:00.000] START: Task task_abc123 received
[00:00:00.005] EXTRACT: Features computed
  - deterministic: false (score: 0.32)
  - risk: 35 (low-medium)
  - complexity: 185 (high)
  - budget: 25% available
  - latency: 2000ms (relaxed)
  - context: 2500 tokens (small)

[00:00:00.010] NODE N1: DeterminismGate
  Condition: det_score > 0.85
  Value: 0.32
  Result: FALSE → ProbabilisticBranch

[00:00:00.015] NODE N2.1: RiskAssessment
  Condition: risk_score > 75
  Value: 35
  Result: FALSE → Continue to N2.3

[00:00:00.018] NODE N2.3: LatencyGate
  Condition: latency_req < 100
  Value: 2000
  Result: FALSE → Continue to N2.4

[00:00:00.022] NODE N2.4: ContextGate
  Condition: ctx_tokens > 100000
  Value: 2500
  Result: FALSE → TERMINAL T_ClaudeHaiku

[00:00:00.025] CONFIDENCE: Calculated
  Base: 0.78
  Path penalty: 0.925 (depth 3)
  Historical: 0.82
  Fit score: 0.75
  Final: 0.78 × 0.925 × (0.7 + 0.3×0.82) × 0.75 = 0.44

[00:00:00.030] CHECK: Confidence 0.44 < 0.60 threshold
  Action: Request secondary check

[00:00:00.035] SECONDARY: Re-evaluate with T_ClaudeOpus
  Complexity 185 > 100, quality preference
  New terminal: T_ClaudeOpus
  New confidence: 0.89

[00:00:00.040] RESULT: ModelSelection
{
  "selection_id": "sel_xyz789",
  "task_id": "task_abc123",
  "selected_model": "claude-3-opus",
  "confidence": 0.89,
  "path_taken": ["N1", "N2.1", "N2.3", "N2.4", "secondary_check"],
  "estimated_cost_usd": 3.75,
  "estimated_latency_ms": 1200,
  "fallback_chain": ["claude-3-sonnet", "codex-1.5-sonnet"],
  "overrides_applied": ["secondary_confidence_boost"],
  "reasoning": "High complexity (185) with quality preference, upgraded from haiku to opus after confidence check"
}
```

### 12.3 Post-Execution Feedback

```json
{
  "feedback_id": "fdb_123",
  "selection_id": "sel_xyz789",
  "outcome": "success",
  "actual_cost_usd": 3.82,
  "actual_latency_ms": 1150,
  "output_quality_score": 0.91,
  "user_satisfaction": 5,
  "corrections": [],
  "timestamp": "2024-01-15T10:32:15Z"
}
```

### 12.4 Calibration Update

```
[Post-Feedback] Updating confidence model for claude-3-opus
  Previous accuracy: 0.88
  New sample: 0.91
  Updated accuracy: 0.883 (EMA with α=0.1)
  
[Post-Feedback] Cost estimation error: +1.9%
  Adjusting cost model bias: -0.02
```

---

## APPENDIX A: Configuration Template

```yaml
decision_tree:
  max_depth: 4
  confidence_threshold: 0.60
  
  nodes:
    determinism_gate:
      threshold: 0.85
      
    complexity_gate:
      low_threshold: 100
      high_threshold: 300
      
    risk_assessment:
      critical: 75
      high: 50
      medium: 25
      
    budget_gate:
      critical_pct: 10
      low_pct: 15
      
    latency_gate:
      strict_ms: 100
      relaxed_ms: 500
      
    context_gate:
      large_tokens: 100000

terminals:
  codex:
    model_id: "codex-1.5-sonnet"
    base_confidence: 0.85
    cost_per_1m_tokens: 3.00
    
  claude_opus:
    model_id: "claude-3-opus"
    base_confidence: 0.92
    cost_per_1m_tokens: 15.00
    
  claude_haiku:
    model_id: "claude-3-haiku"
    base_confidence: 0.78
    cost_per_1m_tokens: 0.25
    
  local_llm:
    model_id: "llama-3.1-70b"
    base_confidence: 0.75
    cost_per_1m_tokens: 0.00
    
  human:
    model_id: "human-expert"
    base_confidence: 1.00
    cost_per_hour: 150.00

overrides:
  enabled: true
  max_concurrent: 10
  
  rules:
    - type: SAFETY
      priority: 1000
      condition: "safety_violation_detected"
      action: "force_human"
      
    - type: COST
      priority: 700
      condition: "budget_exhausted"
      action: "force_local"
      
    - type: SPEED
      priority: 600
      condition: "latency_critical"
      action: "force_haiku"

metrics:
  enabled: true
  collection_interval: 60
  retention_days: 90
```

---

## APPENDIX B: Glossary

| Term | Definition |
|------|------------|
| AST | Abstract Syntax Tree - code structure representation |
| EMA | Exponential Moving Average |
| KPI | Key Performance Indicator |
| LOC | Lines of Code |
| PII | Personally Identifiable Information |
| SLA | Service Level Agreement |
| Token | Unit of text for LLM processing (~4 chars) |

---

*Specification Version: 1.0.0*  
*Last Updated: 2024-01-15*  
*Domain Agent: 17 (Model Selection Decision Tree Engine)*
