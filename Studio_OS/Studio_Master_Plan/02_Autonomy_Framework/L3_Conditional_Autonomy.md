---
title: L3 Conditional Autonomy
type: system
layer: execution
status: active
tags:
  - autonomy
  - L3
  - conditional
  - auto-gates
  - level-3
depends_on:
  - "[Autonomy_Ladder_L0_L5]]"
  - "[[Autonomy_Score_Rubric]]"
  - "[[L2_Supervised_Autonomy]"
used_by:
  - "[L4_High_Autonomy]]"
  - "[[Autonomy_Upgrade_Path]"
---

# L3: Conditional Autonomy

## Level Definition

L3 (Conditional Autonomy) is AI-driven execution with automated gates. The system executes work and validates it against automated gates without human involvement during normal operation. Human is available for escalation but not required for standard workflow progression.

## Human Role

**Available Supervisor**: Human available if needed but not required.

**Responsibilities**:
- Monitor progress notifications
- Respond to escalations
- Intervene if concerns arise
- Review aggregated results periodically
- Handle exceptions

**Authority**:
- Interrupt any operation
- Escalate or de-escalate autonomy
- Override system decisions
- Request manual checkpoints

**Time Commitment**:
- Monitoring: Minimal (notifications only)
- Escalations: As needed
- Typical ticket: ~5-10 minutes human time

## System Role

**Self-Directed Executor**: System manages full execution with auto-validation.

**Capabilities**:
- Execute complete workflows without pause
- Run automated gates at checkpoints
- Auto-remediate known failure modes
- Self-monitor and self-report
- Escalate when conditions met
- Progress without human approval between gates

**Automated Gates**:
- All gates automated (no human judgment required)
- Gates have explicit pass/fail criteria
- Failed gates trigger remediation or escalation
- Gate results logged

## When to Use L3

### Appropriate Contexts
- **Routine Work**: Repetitive, well-understood tasks
- **High-Volume Operations**: Many similar tickets
- **Proven Patterns**: Established with high success rate
- **Limited Human Availability**: Nights, weekends, parallel work
- **Time-Sensitive**: Need fast turnaround

### Indicators for L3
- Autonomy Score: 56-75
- Automated gates defined and tested
- Historical success rate >90%
- Pattern maturity high
- Human trusts system judgment

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    L3 WORKFLOW                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. SYSTEM parses ticket and creates plan                   │
│     └─ Human notified (async)                               │
│                                                              │
│  2. SYSTEM executes complete workflow                       │
│     └─ No human checkpoints                                 │
│                                                              │
│  3. SYSTEM runs automated gates at checkpoints              │
│     └─ Gates validate output                                │
│                                                              │
│  4. IF gates pass:                                          │
│     └─ Continue to next phase                               │
│                                                              │
│  5. IF gates fail with known remediation:                   │
│     └─ Auto-remediate and retry                             │
│                                                              │
│  6. IF gates fail without remediation:                      │
│     └─ ESCALATE to human                                    │
│                                                              │
│  7. SYSTEM completes all phases                             │
│     └─ Final validation passed                              │
│                                                              │
│  8. SYSTEM integrates and ships                             │
│     └─ Human notified of completion                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Automated Gates

### Gate Requirements
All gates at L3 MUST be:
- **Automated**: No human judgment required
- **Deterministic**: Same input always produces same result
- **Fast**: Execute in <5 minutes
- **Reliable**: False positive rate <5%

### Gate Types

| Gate Type | Purpose | Example |
|-----------|---------|---------|
| Syntax | Code compiles/parses | GDScript parser, C# compiler |
| Style | Follows style guidelines | gdformat, dotnet format |
| Tests | All tests pass | Unit tests, integration tests |
| Coverage | Minimum coverage met | >80% line coverage |
| Static Analysis | No critical issues | Type checking, linting |
| Integration | Works with system | Play mode tests |

### Gate Definition Format

```yaml
gate:
  id: [UUID]
  name: [Gate name]
  type: [Gate type]
  
  criteria:
    - metric: [What to measure]
      operator: [==, >, <, >=, <=, contains]
      value: [Expected value]
    
  auto_remediation:
    enabled: [true/false]
    max_attempts: [N]
    actions: [List of remediation actions]
    
  on_failure:
    action: [escalate / retry / abort]
    notify: [who to notify]
```

## Auto-Remediation

### When Auto-Remediation Applies
- Failure pattern is known
- Remediation action is defined
- Confidence in remediation is high
- Max attempts not exceeded

### Auto-Remediation Actions
| Issue | Remediation |
|-------|-------------|
| Style violation | Auto-format code |
| Missing import | Add required import |
| Test failure (known flaky) | Retry test |
| Coverage gap | Generate missing tests |
| Simple logic error | Apply known fix pattern |

### Auto-Remediation Limits
- Maximum 3 remediation attempts per gate
- After 3 failures, escalate to human
- Remediation time tracked
- All attempts logged

## Escalation Triggers

From L3, escalate to L2 when:
- Gate fails without remediation path
- Novel failure pattern detected
- Cost threshold exceeded
- Time threshold exceeded
- Human requests checkpoint
- Confidence drops below threshold

From L3, escalate to L4 when:
- Sustained success at L3
- Human rarely intervenes
- Pattern extremely stable
- Batching would improve efficiency

## Exit Criteria

To promote from L3 to L4:
- Minimum 20 successful L3 completions
- Escalation rate <5%
- Auto-remediation success rate >80%
- Human approves promotion
- Milestone gates defined

## Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Gate pass rate | >95% | Passed / Total gates |
| Auto-remediation success | >80% | Fixed / Attempted |
| Escalation rate | <5% | Escalated / Total |
| Cycle time vs L2 | -20% | Compared to supervised |
| Human time per ticket | <10 min | Total human involvement |

## Cost Profile

| Cost Type | Amount |
|-----------|--------|
| API calls | Moderate-High (full execution) |
| Compute | Local + cloud for gates |
| Human time | Low (~10% of L0) |

## Safety

L3 safety through automated gates:
- All output validated before integration
- Known failure modes auto-remediated
- Unknown failures escalate
- Full audit trail maintained
- Human can interrupt anytime

## Best Practices

1. **Define Gates Carefully**: Gates are your safety net
2. **Monitor Escalations**: Patterns indicate gate gaps
3. **Review Auto-Remediation**: Ensure it's helping, not hiding
4. **Keep Human Informed**: Notifications build trust
5. **Start Conservative**: Begin with more gates, remove as confidence grows

## Example Gate Configuration

```yaml
gates:
  - id: syntax_check
    name: "Syntax Validation"
    type: syntax
    criteria:
      - metric: parse_errors
        operator: ==
        value: 0
    auto_remediation:
      enabled: false
    on_failure:
      action: escalate
      notify: developer

  - id: style_check
    name: "Style Compliance"
    type: style
    criteria:
      - metric: style_violations
        operator: ==
        value: 0
    auto_remediation:
      enabled: true
      max_attempts: 1
      actions: [auto_format]
    on_failure:
      action: escalate
      notify: developer

  - id: test_coverage
    name: "Test Coverage"
    type: coverage
    criteria:
      - metric: line_coverage
        operator: >=
        value: 80
    auto_remediation:
      enabled: true
      max_attempts: 2
      actions: [generate_tests]
    on_failure:
      action: escalate
      notify: developer
```

## Enforcement

- All gates MUST be automated at L3
- Failed gates without remediation MUST escalate
- Auto-remediation attempts MUST be limited
- Human MUST be able to interrupt
- All gate results logged
