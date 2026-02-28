---
title: Bug Triage Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - bug
  - triage
  - classification
  - fix
  - debug
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Code_Implementation_Routing]]"
  - "[[Local_LLM_Coder_Small]]"
  - "[[Local_LLM_Coder_Medium]]"
  - "[[Frontier_Reasoning_Model]"
used_by:
  - "[Performance_Regression_Routing]]"
  - "[[Determinism_Issue_Routing]"
---

# Bug Triage Routing

## Bug Classification and Routing

Bugs are routed based on severity, type, and available diagnostic information. The triage process determines the appropriate model and approach for resolution.

### Bug Severity Classification

| Severity | Impact | Response Time | Routing |
|----------|--------|---------------|---------|
| P0 (Critical) | Game unplayable | Immediate | Human + Frontier |
| P1 (High) | Major feature broken | 4 hours | Frontier |
| P2 (Medium) | Feature degraded | 24 hours | Local Medium |
| P3 (Low) | Minor issue | 72 hours | Local Small |
| P4 (Trivial) | Cosmetic | Next sprint | Local Small |

### Bug Type Classification

| Type | Description | Preferred Model | Success Rate |
|------|-------------|-----------------|--------------|
| Syntax | Compilation error | Local Small | 95% |
| Logic | Wrong behavior | Local Medium | 70% |
| Null/Undefined | Missing value | Local Small | 85% |
| Race Condition | Timing issue | Frontier | 40% |
| Performance | Slow execution | Frontier | 60% |
| Memory | Leak/overflow | Frontier | 50% |
| Integration | API mismatch | Local Medium | 75% |
| Regression | Previously worked | Local Medium | 80% |
| Deterministic | Always reproduces | Local Medium | 75% |
| Non-deterministic | Intermittent | Frontier | 35% |

### Routing Decision Tree

```
Bug Report Received
│
├── Severity = P0 (Critical)
│   └── Route: Human Primary + Frontier Assist
│       └── Human investigates
│       └── Frontier provides analysis
│       └── Human implements fix
│       └── Full regression test
│
├── Severity = P1 (High)
│   └── Route: Frontier Primary
│       └── Analyze error context
│       └── Generate fix hypothesis
│       └── Implement fix
│       └── Confidence >= 0.75 → ACCEPT
│       └── Confidence < 0.75 → Human Review
│
├── Type = Non-deterministic
│   └── Route: Frontier (see [[Determinism_Issue_Routing]])
│
├── Type = Race Condition
│   └── Route: Frontier Primary
│       └── Deep analysis required
│       └── Human review mandatory
│
├── Type = Simple (Syntax, Null, Simple Logic)
│   └── Route: Local Small
│       └── Confidence >= 0.85 → ACCEPT
│       └── Confidence 0.70-0.85 → Local Medium Review
│       └── Confidence < 0.70 → Escalate
│
└── Type = Complex (Logic, Integration, Regression)
    └── Route: Local Medium
        └── Confidence >= 0.75 → ACCEPT
        └── Confidence 0.60-0.75 → Frontier Review
        └── Confidence < 0.60 → Frontier Primary
```

### Owner Agent: Debug Agent

The Debug Agent owns bug triage and resolution.

**Responsibilities:**
- Classify bug severity and type
- Gather diagnostic information
- Select appropriate model
- Generate and test fixes
- Verify resolution
- Document root cause

### Context Pack Contents

**Simple Bug Context Pack:**
```yaml
context_pack:
  error_file: 1  # File with error
  error_message: "Full error text"
  stack_trace: "Stack trace if available"
  related_files: 2  # Calling code
  test_files: 1  # Failing test
  recent_changes: 3  # Recent commits
  total_tokens_budget: 6000
```

**Complex Bug Context Pack:**
```yaml
context_pack:
  error_file: 3  # Multiple error locations
  error_message: "Full error text"
  stack_trace: "Complete stack trace"
  related_files: 8  # Dependencies
  test_files: 3  # Test suite
  recent_changes: 10  # Commit history
  logs: "Relevant log excerpts"
  total_tokens_budget: 24000
```

### Diagnostic Information Gathering

**Automatic Collection:**
1. Error message and stack trace
2. Related source files
3. Recent changes (git log)
4. Failing test cases
5. Environment information
6. Reproduction steps (if provided)

**Manual Addition (if needed):**
1. Log files
2. User reports
3. Screenshot/video
4. Performance profiles

### Fix Generation Process

```
1. Analyze error context
2. Identify root cause candidates
3. Generate fix hypothesis
4. Implement fix
5. Run affected tests
6. Verify fix resolves issue
7. Check for regressions
8. Calculate confidence score
```

### Gates Required

**Pre-Fix Gates:**
1. **Reproduction Verified**: Bug can be reproduced
2. **Context Complete**: All relevant files identified
3. **Test Exists**: Test case covers bug (or create one)

**Post-Fix Gates:**
1. **Original Test Passes**: Bug is fixed
2. **Regression Tests Pass**: No new failures
3. **Static Analysis Clean**: No new issues
4. **Confidence Threshold**: Meet minimum for severity

### Confidence Thresholds by Severity

| Severity | Minimum Confidence | Review Required |
|----------|-------------------|-----------------|
| P0 | N/A | Human mandatory |
| P1 | 0.80 | Human spot-check |
| P2 | 0.75 | Automated review |
| P3 | 0.70 | Automated review |
| P4 | 0.65 | Automated review |

### Escalation Triggers

| Trigger | From | To | Condition |
|---------|------|-----|-----------|
| Fix fails | Local Small | Local Medium | After 2 attempts |
| Confidence low | Local Small | Local Medium | Score < 0.70 |
| Complex logic | Local Small | Local Medium | Multiple files |
| Fix fails | Local Medium | Frontier | After 2 attempts |
| Confidence low | Local Medium | Frontier | Score < 0.60 |
| Race condition | Any | Frontier | Type detected |
| Non-deterministic | Any | Frontier | Type detected |
| Security related | Any | Frontier + Human | Security flag |

### Cost Estimates

| Severity | Local Small | Local Medium | Frontier | Total Range |
|----------|-------------|--------------|----------|-------------|
| P4 | $0.001 | - | - | $0.001 |
| P3 | $0.002 | $0.005* | - | $0.002-0.005 |
| P2 | - | $0.005 | $0.10* | $0.005-0.10 |
| P1 | - | - | $0.30 | $0.30 |
| P0 | - | - | $0.50* | $0.50+human |

*If escalation occurs

### Best Practices

1. Always create test case for bug
2. Document root cause in ticket
3. Verify fix in production-like environment
4. Monitor for regression after fix
5. Update knowledge base with pattern

### Integration

Used by:
- [[Performance_Regression_Routing]]: Performance bugs
- [[Determinism_Issue_Routing]]: Non-deterministic bugs
