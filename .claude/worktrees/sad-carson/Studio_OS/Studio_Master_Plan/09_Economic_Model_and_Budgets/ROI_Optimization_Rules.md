---
title: ROI Optimization Rules
type: rule
layer: enforcement
status: active
tags:
  - roi
  - optimization
  - routing
  - decision
  - cost-benefit
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Model_Cost_Matrix]]"
  - "[[Cost_Per_Feature_Estimates]"
used_by:
  - "[Token_Burn_Controls]]"
  - "[[Compute_Burn_Controls]]"
  - "[[Monthly_Budget_Prototype_Tier]]"
  - "[[Monthly_Budget_Indie_Tier]]"
  - "[[Monthly_Budget_MultiProject_Tier]"
---

# ROI Optimization Rules

## Overview

These rules determine when to use paid APIs vs local models based on cost-benefit analysis. The goal is maximum value per dollar spent.

## Core Decision Framework

### The ROI Equation

```
ROI = (Value Generated - Cost) / Cost

Where:
- Value Generated = Time Saved × Hourly Rate
- Cost = API Cost + Compute Cost + Review Cost
```

### Decision Thresholds

| ROI Range | Action |
|-----------|--------|
| ROI > 3.0 | Definitely use |
| ROI 1.5-3.0 | Probably use |
| ROI 0.5-1.5 | Consider carefully |
| ROI < 0.5 | Don't use |

## Rule Set: When to Use Paid APIs

### Always Use Paid APIs

**Security-Critical Code**
- Authentication systems
- Payment processing
- Data encryption
- Access control

*Rationale: Cost of error >> API cost*

**Complex Multi-File Refactoring**
- >5 files affected
- Cross-module dependencies
- Breaking changes

*Rationale: Local models struggle with context*

**Novel Architecture Decisions**
- New system design
- Technology selection
- Integration patterns

*Rationale: High-stakes decisions benefit from best models*

### Usually Use Paid APIs

**Debug Complex Bugs**
- Multiple hours invested
- Non-obvious root cause
- Production impact

**Review Critical Code**
- Core business logic
- Performance-critical paths
- Public APIs

**Generate Complex Algorithms**
- Mathematical operations
- Optimization problems
- State machines

### Sometimes Use Paid APIs

**Generate Boilerplate**
- If local model fails twice
- If time pressure exists
- If quality > speed

**Write Documentation**
- For external APIs
- For complex features
- If local output poor

**Refactor Medium Complexity**
- 2-5 files affected
- Clear requirements
- Good test coverage

### Rarely Use Paid APIs

**Simple Code Completion**
- Local models handle 90%+
- Cache hit likely
- Low consequence of error

**Generate Tests for Simple Functions**
- Local models adequate
- Easy to verify
- Fast iteration

**Update Configuration**
- Pattern-based changes
- Low complexity
- Easy rollback

## Rule Set: When to Use Local Models

### Always Use Local First

**High-Volume, Low-Complexity Tasks**
- Code completion
- Simple generation
- Pattern matching

**Rapid Iteration**
- Experimentation
- Prototyping
- Learning

**Privacy-Sensitive Code**
- Proprietary algorithms
- Customer data handling
- Internal tools

### Prefer Local When

**Budget Constrained**
- Approaching daily limits
- End of month
- Prototype tier

**Latency Sensitive**
- Real-time features
- Interactive tools
- User-facing

**Offline Capability Needed**
- Travel/remote work
- Unreliable internet
- Security requirements

## Quality Thresholds

### Automatic Escalation

```yaml
escalation_rules:
  local_model_confidence:
    threshold: 0.7
    action: "accept_local"
    
  local_model_uncertainty:
    threshold: 0.5-0.7
    action: "retry_with_different_local"
    
  local_model_failure:
    threshold: <0.5
    action: "escalate_to_api"
    
  api_model_failure:
    threshold: <0.6
    action: "human_review_required"
```

### Confidence Scoring

```python
def calculate_confidence(model_output):
    factors = {
        'perplexity': measure_perplexity(model_output),
        'consistency': check_self_consistency(model_output),
        'pattern_match': compare_to_known_good_patterns(),
        'syntax_valid': validate_syntax(model_output),
        'test_pass': run_quick_tests(model_output)
    }
    
    return weighted_average(factors)
```

## Cost-Benefit Examples

### Example 1: Simple Function

```
Task: Generate getter/setter
Time to write manually: 2 minutes
Hourly rate: $100
Value: $3.33

Local model cost: $0.01
API cost: $0.05

ROI Local: (3.33 - 0.01) / 0.01 = 332
ROI API: (3.33 - 0.05) / 0.05 = 65.6

Decision: Use local (both positive, local better)
```

### Example 2: Complex Algorithm

```
Task: Implement pathfinding algorithm
Time to write manually: 4 hours
Hourly rate: $100
Value: $400

Local model cost: $0.50
Local quality: 5/10 (needs rework)
Rework time: 2 hours
Effective value: $200

API cost: $2.00
API quality: 8/10 (minor tweaks)
Rework time: 30 minutes
Effective value: $350

ROI Local: (200 - 0.50) / 0.50 = 399
ROI API: (350 - 2.00) / 2.00 = 174

Decision: Use API despite lower ROI (higher absolute value)
```

### Example 3: Security Code

```
Task: Implement OAuth flow
Time to write manually: 8 hours
Hourly rate: $100
Value: $800

Risk of local model error: High
Cost of security bug: $10,000+

Local model cost: $1.00
Expected cost with risk: $1.00 + (0.3 × $10000) = $3001

API cost: $5.00
Expected cost with risk: $5.00 + (0.05 × $10000) = $505

Decision: Use API (risk-adjusted cost much lower)
```

## Routing Decision Tree

```
Start
  │
  ├─ Is it security-critical? ──Yes──► Use API Tier 2-3
  │   No
  │
  ├─ Is it complex (>5 files)? ──Yes──► Use API Tier 2
  │   No
  │
  ├─ Is budget constrained? ──Yes──► Use Local
  │   No
  │
  ├─ Try Local Model
  │   │
  │   ├─ Confidence > 0.7? ──Yes──► Use Local
  │   │   No
  │   │
  │   ├─ Retry with different local
  │   │   │
  │   │   ├─ Confidence > 0.6? ──Yes──► Use Local
  │   │       No
  │   │
  │   └─ Use API Tier 1-2
  │
  └─ Monitor quality, adjust thresholds
```

## Tier-Specific Rules

### Prototype Tier

```yaml
rules:
  max_api_calls_per_day: 100
  api_use_requires:
    - "local_failed_twice"
    - "or_security_critical"
    - "or_time_critical"
  
  preferred_order:
    - local_7b
    - local_8b
    - api_tier1
    - api_tier2
```

### Indie Tier

```yaml
rules:
  max_api_calls_per_day: 500
  default_to_local: true
  
  auto_escalate:
    - local_confidence < 0.6
    - task_complexity > 7
    - security_related
```

### Multi-Project Tier

```yaml
rules:
  project_isolation: true
  smart_routing: true
  
  cost_optimization:
    - use_cheapest_capable_model
    - batch_requests
    - cache_aggressively
```

## Measurement and Adjustment

### Track Per-Rule Performance

```yaml
metrics:
  rule_id: "always_use_api_security"
  times_triggered: 45
  average_roi: 15.3
  success_rate: 98%
  recommendation: "maintain"
```

### Monthly Review

- Which rules triggered most?
- What was actual ROI?
- Any false positives/negatives?
- Adjust thresholds based on data

---

*The best model is the one that solves your problem at the lowest cost. These rules help you find it.*
