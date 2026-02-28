---
title: Calibration Protocol
type: pipeline
layer: execution
status: active
tags:
  - calibration
  - measurement
  - benchmark
  - validation
  - metrics
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Model_Cost_Matrix]]"
  - "[[Cost_Per_Feature_Estimates]"
used_by:
  - "[Monthly_Budget_Prototype_Tier]]"
  - "[[Monthly_Budget_Indie_Tier]]"
  - "[[Monthly_Budget_MultiProject_Tier]]"
  - "[[Cost_Monitoring_Dashboard_Spec]"
---

# Calibration Protocol

## Overview

The calibration protocol validates all cost assumptions through systematic measurement. Run this monthly or whenever models/prices change.

## Benchmark Suite

### Test Categories

**Category 1: Code Completion (10 tests)**
- Simple function completion
- Method signature completion
- Import statement completion
- Comment-to-code generation
- Test case generation

**Category 2: Code Generation (10 tests)**
- CRUD endpoint generation
- React component generation
- Database schema generation
- API client generation
- Configuration file generation

**Category 3: Code Review (10 tests)**
- Bug detection in sample code
- Style issue identification
- Performance problem spotting
- Security vulnerability detection
- Refactoring suggestion

**Category 4: Architecture (10 tests)**
- System design from requirements
- API design for new feature
- Database schema design
- Microservice boundary decisions
- Technology selection reasoning

**Category 5: Debugging (10 tests)**
- Error message interpretation
- Stack trace analysis
- Root cause identification
- Fix suggestion validation
- Regression test suggestion

### Test Format

```yaml
benchmark_test:
  id: "CG-001"
  category: "Code Generation"
  difficulty: medium
  
  input:
    prompt: "Generate a Python function that..."
    context: "existing codebase context"
    
  expected_output:
    type: "code"
    validation: "automated_tests"
    
  metrics:
    - tokens_input
    - tokens_output
    - latency_ms
    - quality_score
    - cost_usd
```

## Measurement Process

### Phase 1: Baseline (Week 1)

**Step 1: Environment Setup**
- Document hardware configuration
- Record model versions
- Set up instrumentation
- Configure logging

**Step 2: Run Benchmark Suite**
- Execute all 50 tests
- Record for each model tier:
  - Local 7B/8B
  - Local 14B
  - API Tier 1 (Flash/Haiku)
  - API Tier 2 (Sonnet/GPT-4o)

**Step 3: Collect Metrics**
```yaml
metrics_collected:
  per_test:
    - input_tokens
    - output_tokens
    - total_tokens
    - latency_ms
    - cost_usd
    - quality_score (1-10)
    - success (pass/fail)
    
  per_model:
    - average_latency
    - p95_latency
    - average_cost
    - success_rate
    - average_quality
```

### Phase 2: Analysis (Week 2)

**Statistical Analysis**

For each metric, calculate:
- Mean (average)
- Median (50th percentile)
- Standard deviation
- P95 (95th percentile)
- P99 (99th percentile)

**Cost Model Validation**

Compare actual vs estimated:
```
Variance = (Actual - Estimated) / Estimated

Acceptable variance:
- < 20%: Excellent
- 20-50%: Good, minor adjustment
- 50-100%: Poor, major adjustment needed
- > 100%: Critical, investigate
```

**Quality vs Cost Analysis**

Create scatter plot:
- X-axis: Cost per task
- Y-axis: Quality score
- Each point: One model on one test

Identify:
- Pareto frontier (best quality for cost)
- Diminishing returns point
- Unacceptable quality models

### Phase 3: Adjustment (Week 3)

**Update Cost Estimates**

```yaml
adjustment_rules:
  if_variance_under_20%:
    action: "no_change"
    
  if_variance_20_to_50%:
    action: "adjust_estimate"
    formula: "new_estimate = actual_mean * 1.1"
    
  if_variance_over_50%:
    action: "investigate_and_adjust"
    steps:
      - "review test validity"
      - "check for anomalies"
      - "adjust model or estimate"
```

**Update Routing Rules**

Based on quality/cost analysis:
- Promote models that over-perform
- Demote models that under-perform
- Adjust confidence thresholds

### Phase 4: Documentation (Week 4)

**Calibration Report**

```yaml
calibration_report:
  period: "2024-01"
  
  executive_summary:
    tests_run: 50
    models_evaluated: 6
    key_findings: "..."
    
  cost_validation:
    prototype_tier:
      estimated: $73
      actual: $68
      variance: -7%
      
    indie_tier:
      estimated: $911
      actual: $1050
      variance: +15%
      
  model_performance:
    llama3.1_8b:
      quality_score: 7.2
      cost_per_task: $0.02
      recommendation: "maintain_primary"
      
  adjustments_made:
    - "Increased Indie tier budget to $1000"
    - "Promoted Qwen 2.5 14B to primary complex task model"
    
  next_calibration: "2024-02"
```

## Continuous Monitoring

### Daily Metrics

- Total API calls
- Total tokens used
- Total cost
- Cache hit rate
- Error rate

### Weekly Review

- Cost vs budget (7-day rolling)
- Per-feature cost trends
- Model usage distribution
- Anomaly detection

### Monthly Deep Dive

- Full calibration protocol
- Cost attribution by project/feature
- ROI analysis
- Budget adjustment recommendations

## Calibration Schedule

| Trigger | Action | Timeline |
|---------|--------|----------|
| Scheduled | Full calibration | Monthly |
| New model released | Partial calibration | Within 1 week |
| Price change | Cost update | Immediate |
| Quality issues | Targeted calibration | Within 3 days |
| Budget overrun | Emergency calibration | Within 1 day |

## Tools and Automation

### Automated Benchmark Runner

```python
# Pseudo-code
class BenchmarkRunner:
    def run_suite(tests, models):
        results = []
        for test in tests:
            for model in models:
                result = self.run_test(test, model)
                results.append(result)
        return self.analyze(results)
    
    def run_test(test, model):
        start = time.now()
        response = model.call(test.input)
        end = time.now()
        
        return {
            'test_id': test.id,
            'model': model.name,
            'input_tokens': count_tokens(test.input),
            'output_tokens': count_tokens(response),
            'latency_ms': end - start,
            'cost': calculate_cost(model, tokens),
            'quality': evaluate_quality(test, response)
        }
```

### Dashboard Integration

Calibration results feed into:
- [[Cost_Monitoring_Dashboard_Spec]]
- Budget tier updates
- Model routing decisions
- ROI calculations

## Success Criteria

**Good Calibration**:
- 90% of estimates within 30% of actual
- All models ranked by quality/cost
- Clear routing recommendations
- Actionable insights

**Poor Calibration** (requires redo):
- >20% of estimates off by >50%
- Anomalous results not explained
- Missing key metrics
- No actionable recommendations

---

*Measurement beats estimation. Calibration turns guesses into data.*
