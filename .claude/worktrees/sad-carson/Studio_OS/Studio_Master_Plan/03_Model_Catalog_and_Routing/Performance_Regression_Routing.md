---
title: Performance Regression Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - performance
  - regression
  - optimization
  - profiling
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Bug_Triage_Routing]]"
  - "[[Local_LLM_Coder_Medium]]"
  - "[[Frontier_Reasoning_Model]"
used_by: []
---

# Performance Regression Routing

## Performance Issue Classification and Routing

Performance regressions require specialized routing due to their measurement-dependent nature and potential for complex root causes spanning multiple systems.

### Regression Severity Classification

| Severity | Impact | Threshold | Response Time |
|----------|--------|-----------|---------------|
| Critical | Unplayable | >50% degradation | Immediate |
| High | Significant | 25-50% degradation | 4 hours |
| Medium | Noticeable | 10-25% degradation | 24 hours |
| Low | Minor | 5-10% degradation | Next sprint |

### Performance Issue Types

| Type | Description | Detection | Routing |
|------|-------------|-----------|---------|
| CPU Bound | High CPU usage | Profiler | Local Medium |
| Memory Leak | Growing memory | Heap track | Frontier |
| GPU Bound | Frame time issues | GPU profiler | Frontier |
| I/O Bound | Disk/network wait | I/O monitor | Local Medium |
| Algorithmic | O(n²) instead of O(n) | Benchmark | Frontier |
| Allocation | Excessive GC | Memory profiler | Local Medium |
| Cache Miss | Poor locality | Cache profiler | Frontier |

### Routing Decision Tree

```
Performance Regression Detected
│
├── Severity = Critical (>50% degradation)
│   └── Route: Human + Frontier
│       └── Human investigates immediately
│       └── Frontier analyzes profile data
│       └── Human implements fix
│       └── Verify improvement before merge
│
├── Type = Memory Leak
│   └── Route: Frontier Primary
│       └── Memory analysis required
│       └── Root cause often complex
│       └── Human review mandatory
│
├── Type = GPU/Rendering
│   └── Route: Frontier Primary
│       └── Graphics expertise needed
│       └── Profile analysis required
│
├── Type = Algorithmic
│   └── Route: Frontier Primary
│       └── Complexity analysis needed
│       └── May require architectural change
│
├── Type = CPU Bound (hot path)
│   └── Route: Local Medium
│       └── Profile data provided
│       └── Optimize specific function
│       └── Confidence >= 0.75 → ACCEPT
│       └── Confidence < 0.75 → Frontier Review
│
├── Type = Allocation/GC
│   └── Route: Local Medium
│       └── Object pooling, allocation reduction
│       └── Confidence >= 0.70 → ACCEPT
│
└── Type = I/O Bound
    └── Route: Local Medium
        └── Async patterns, caching
        └── Confidence >= 0.75 → ACCEPT
```

### Owner Agent: Performance Agent

The Performance Agent owns performance regression investigation and optimization.

**Responsibilities:**
- Analyze performance metrics
- Classify regression type
- Gather profiling data
- Select optimization approach
- Implement fixes
- Verify improvement
- Document findings

### Context Pack Contents

**Performance Issue Context Pack:**
```yaml
context_pack:
  # Performance data
  benchmark_results: "Before/after metrics"
  profile_data: "CPU/GPU profile"
  memory_profile: "Heap snapshot"
  
  # Code context
  hot_path_files: 5  # Functions in hot path
  related_files: 5  # Calling code
  recent_changes: 10  # Recent commits
  
  # System context
  system_info: "Hardware specs"
  test_scenario: "Reproduction steps"
  
  total_tokens_budget: 24000
```

### Profiling Data Requirements

**Required for All Performance Issues:**
1. Before/after benchmark numbers
2. CPU profile (hot functions)
3. Call graph (caller/callee relationships)
4. Recent changes (git log)

**Additional by Type:**
- Memory: Heap snapshots, allocation tracking
- GPU: Frame capture, draw call analysis
- I/O: I/O operation timing, async patterns

### Optimization Process

```
1. Analyze profile data
2. Identify bottleneck
3. Generate optimization hypothesis
4. Implement optimization
5. Re-run benchmarks
6. Verify improvement
7. Check for regressions
8. Document optimization
```

### Gates Required

**Pre-Optimization Gates:**
1. **Baseline Established**: Before metrics recorded
2. **Profile Data Available**: Sufficient diagnostic info
3. **Reproduction Verified**: Issue can be reproduced

**Post-Optimization Gates:**
1. **Improvement Verified**: Performance improved
2. **No Regressions**: No new performance issues
3. **Functionality Preserved**: All tests pass
4. **Confidence Threshold**: Meet minimum for severity

### Confidence Thresholds

| Severity | Minimum Confidence | Review Required |
|----------|-------------------|-----------------|
| Critical | N/A | Human mandatory |
| High | 0.80 | Human review |
| Medium | 0.75 | Automated review |
| Low | 0.70 | Automated review |

### Improvement Verification

**Acceptance Criteria:**
```yaml
performance_fix:
  # Must improve by at least half the regression
  minimum_improvement: 0.5  # 50% of regression
  
  # Must not introduce new issues
  max_new_allocations: 0
  max_new_cpu_time: 0.05  # 5% increase allowed
  
  # Must pass all tests
  test_pass_rate: 1.0
```

### Escalation Triggers

| Trigger | From | To | Condition |
|---------|------|-----|-----------|
| No improvement | Local Medium | Frontier | After 2 attempts |
| Complex root cause | Local Medium | Frontier | Multiple systems |
| Memory leak | Any | Frontier | Type detected |
| GPU issue | Any | Frontier | Type detected |
| Algorithmic | Any | Frontier | Type detected |
| Critical severity | Any | Human | Severity level |

### Cost Estimates

| Severity | Local Medium | Frontier | Human | Total Range |
|----------|--------------|----------|-------|-------------|
| Low | $0.005 | - | - | $0.005 |
| Medium | $0.010 | $0.20* | - | $0.01-0.20 |
| High | $0.020 | $0.50 | - | $0.50 |
| Critical | $0.030 | $1.00* | $150/hr | $150+ |

*If escalation occurs

### Best Practices

1. Always establish baseline before optimization
2. Profile before optimizing (don't guess)
3. Optimize one bottleneck at a time
4. Verify improvement with benchmarks
5. Document optimization rationale
6. Monitor for regression in production

### Performance Budget

**Per-System Performance Budgets:**
```yaml
performance_budgets:
  frame_time: 16.67ms  # 60 FPS
  memory: 512MB  # Per level
  load_time: 5s  # Level load
  allocation_rate: 1MB/s  # Max allocation
```

### Integration

Related to:
- [[Bug_Triage_Routing]]: Performance bugs are a bug type
