---
title: Determinism Issue Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - determinism
  - non-deterministic
  - race
  - random
  - debug
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Bug_Triage_Routing]]"
  - "[[Frontier_Reasoning_Model]"
used_by: []
---

# Determinism Issue Routing

## Non-Deterministic Bug Classification and Routing

Non-deterministic bugs are the most challenging class of issues due to their intermittent nature. These require specialized routing to frontier models with deep reasoning capabilities.

### Determinism Issue Types

| Type | Description | Frequency | Routing |
|------|-------------|-----------|---------|
| Race Condition | Concurrent access | Intermittent | Frontier |
| Uninitialized | Variable not set | Sometimes | Local Medium |
| Random Seed | RNG not seeded | Varies | Local Small |
| Timing | Time-dependent | Intermittent | Frontier |
| External | Outside system | Varies | Frontier |
| Memory Corruption | Use-after-free | Rare | Frontier |
| Hardware | Platform-specific | Varies | Human |

### Routing Decision Tree

```
Non-Deterministic Bug Reported
│
├── Type clearly identified as Race Condition
│   └── Route: Frontier Primary
│       └── Deep concurrency analysis
│       └── Identify critical sections
│       └── Propose synchronization fix
│       └── Human review MANDATORY
│       └── Reproduce under stress test
│
├── Type clearly identified as Memory Corruption
│   └── Route: Frontier Primary
│       └── Memory analysis required
│       └── Valgrind/ASan integration
│       └── Human review MANDATORY
│
├── Type = Uninitialized Variable
│   └── Route: Local Medium
│       └── Static analysis often finds
│       └── Confidence >= 0.80 → ACCEPT
│       └── Confidence < 0.80 → Frontier Review
│
├── Type = Random Seed Issue
│   └── Route: Local Small
│       └── Find unseeded RNG
│       └── Confidence >= 0.85 → ACCEPT
│
├── Type = External Dependency
│   └── Route: Frontier Primary
│       └── Network/file system analysis
│       └── Error handling review
│       └── Human review recommended
│
└── Type Unknown (most common)
    └── Route: Frontier Primary
        └── Comprehensive analysis
        └── Hypothesis generation
        └── Logging enhancement
        └── Human collaboration required
```

### Owner Agent: Debug Agent (Specialized)

The Debug Agent uses specialized non-deterministic bug handling.

**Responsibilities:**
- Attempt to reproduce issue
- Gather all available logs
- Identify potential causes
- Coordinate with Frontier model
- Implement logging improvements
- Verify fix under stress

### Context Pack Contents

**Non-Deterministic Bug Context Pack:**
```yaml
context_pack:
  # All occurrences
  error_logs: "All logged instances"
  stack_traces: "All available traces"
  
  # Code context
  suspected_files: 10  # Files in stack traces
  concurrent_code: 5  # Threading/async code
  shared_state: 3  # Shared variables
  
  # System context
  timing_info: "When issues occur"
  environment: "Platform, hardware"
  reproduction_attempts: "Success/failure log"
  
  # Recent changes
  recent_commits: 20  # Broader history
  dependency_changes: "Library updates"
  
  total_tokens_budget: 32000
```

### Reproduction Strategy

**Automated Reproduction Attempts:**
```yaml
reproduction:
  attempts: 100  # Number of tries
  stress_multiplier: 10  # Load factor
  
  strategies:
    - name: "timing_variation"
      description: "Vary timing of operations"
    - name: "load_increase"
      description: "Run under heavy load"
    - name: "thread_count"
      description: "Vary number of threads"
    - name: "iteration_loop"
      description: "Repeat operation many times"
```

### Analysis Process

```
1. Collect all available data
2. Identify patterns in occurrences
3. Generate hypotheses
4. Add targeted logging
5. Run reproduction attempts
6. Analyze new data
7. Narrow down cause
8. Implement fix
9. Verify under stress
```

### Gates Required

**Pre-Fix Gates:**
1. **Hypothesis Validated**: Strong evidence for cause
2. **Reproduction Success**: Can reproduce (even intermittently)
3. **Root Cause Identified**: Clear understanding of issue

**Post-Fix Gates:**
1. **Stress Test Pass**: 1000+ iterations without failure
2. **Original Issue Resolved**: No new occurrences
3. **No New Issues**: No regressions introduced
4. **Human Review**: Mandatory for all non-deterministic fixes

### Confidence Scoring (Modified)

Non-deterministic fixes require higher confidence:

```python
def calculate_nd_confidence(fix_result):
    base_score = calculate_confidence(fix_result)
    
    # Non-deterministic penalty
    nd_penalty = 0.15
    
    # Stress test bonus
    stress_bonus = 0.0
    if fix_result.stress_iterations > 1000:
        stress_bonus = 0.10
    
    return min(1.0, base_score - nd_penalty + stress_bonus)
```

### Confidence Thresholds

| Type | Minimum Confidence | Stress Iterations | Review |
|------|-------------------|-------------------|--------|
| Uninitialized | 0.85 | 100 | Automated |
| Random Seed | 0.90 | 100 | Automated |
| Race Condition | 0.80 | 1000 | Human mandatory |
| Memory Corruption | 0.80 | 1000 | Human mandatory |
| External | 0.80 | 500 | Human recommended |
| Unknown | 0.85 | 1000 | Human mandatory |

### Escalation Triggers

| Trigger | From | To | Condition |
|---------|------|-----|-----------|
| Cannot reproduce | Any | Human | After 100 attempts |
| Multiple hypotheses | Any | Human | Frontier uncertain |
| Complex concurrency | Any | Frontier | Race condition suspected |
| Memory issue | Any | Frontier | Corruption suspected |
| Hardware suspected | Any | Human | Platform-specific |

### Cost Estimates

Non-deterministic bugs are expensive due to extended analysis:

| Type | Frontier | Human | Total Range |
|------|----------|-------|-------------|
| Uninitialized | $0.20* | - | $0.20 |
| Random Seed | $0.10* | - | $0.10 |
| Race Condition | $1.00-3.00 | $200/hr | $200-500 |
| Memory Corruption | $1.00-5.00 | $300/hr | $300-800 |
| External | $0.50-2.00 | $100/hr | $100-300 |
| Unknown | $1.00-5.00 | $200/hr | $200-700 |

*Local models attempted first

### Best Practices

1. Never mark non-deterministic bug as fixed without stress testing
2. Add comprehensive logging before attempting fix
3. Consider adding deterministic replay capability
4. Document root cause for knowledge base
5. Add regression test if possible
6. Review all concurrent code for similar issues

### Prevention Strategies

```yaml
prevention:
  static_analysis:
    - race_condition_detection: enabled
    - uninitialized_variable_detection: enabled
    
  runtime:
    - thread_sanitizer: enabled in debug
    - address_sanitizer: enabled in debug
    
  testing:
    - stress_tests: required
    - concurrency_tests: required
    - deterministic_replay: recommended
```

### Integration

Related to:
- [[Bug_Triage_Routing]]: Non-deterministic is a bug type
