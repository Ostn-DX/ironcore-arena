---
title: Studio OS in 10 Rules
type: rule
layer: enforcement
status: active
tags:
  - rules
  - enforcement
  - 10-rules
  - principles
  - must-read
depends_on:
  - "[Studio_OS_Overview]]"
  - "[[Studio_Priorities_Manifesto]"
used_by:
  - "[Quickstart_OpenClaw]]"
  - "[[30_Day_Enablement_Plan]"
---

# Studio OS in 10 Rules

## Enforceable Rules (Not Motivational)

These rules are enforced by the system. Violations block progress.

---

### Rule 1: Every Ticket Must Reference at Least One Gate

**Enforcement**: Parser rejects tickets without gate references.

**Why**: Without gates, there is no quality enforcement.

**Correct**:
```yaml
---
title: Implement feature
gates: [build, unit-tests]
---
```

**Incorrect**:
```yaml
---
title: Implement feature
# Missing gates!
---
```

---

### Rule 2: All Gates Must Have Explicit Pass/Fail Criteria

**Enforcement**: Gate template requires criteria definition.

**Why**: Ambiguous gates are bypassed gates.

**Correct**:
```yaml
gate:
  name: unit-tests
  pass_criteria: "100% tests pass"
  fail_criteria: "Any test failure"
```

**Incorrect**:
```yaml
gate:
  name: unit-tests
  # No criteria defined!
```

---

### Rule 3: All Production Code Must Pass Through a Gate

**Enforcement**: Git hooks block merges without gate passes.

**Why**: Production code without gate validation is a bug waiting to happen.

**Implementation**:
```bash
# Pre-merge hook
if ! openclaw gates --verify $BRANCH; then
    echo "Gate verification failed. Merge blocked."
    exit 1
fi
```

---

### Rule 4: Cost Thresholds Must Be Enforced by Automated Monitors

**Enforcement**: OpenClaw pauses when budget exceeded.

**Why**: Humans forget to check costs. Automation doesn't.

**Configuration**:
```yaml
openclaw:
  max_cost_per_ticket: 5.00  # USD
  max_cost_per_day: 50.00    # USD
  action_on_exceed: pause    # pause|alert|continue
```

---

### Rule 5: All Autonomy Escalations Must Be Logged with Justification

**Enforcement**: Escalation requires reason code.

**Why**: Escalation without justification is uncontrolled risk.

**Logged**:
```yaml
escalation:
  from: L2
  to: L3
  reason: "confidence_below_threshold"
  justification: "Model confidence 0.62 < 0.70 threshold"
  ticket: TICKET-2024-001
  timestamp: "2024-01-15T14:32:00Z"
```

---

### Rule 6: Local Models Are Default; Paid APIs Are Explicit Opt-In

**Enforcement**: Router defaults to local, requires flag for paid.

**Why**: Cost control requires opt-in, not opt-out.

**Correct Routing**:
```
Task received
  └── Route to: Local Small (7B)
        └── Confidence: 0.65 (below threshold)
              └── Escalate to: Local Medium (13B)
                    └── Confidence: 0.82 (acceptable)
```

**Incorrect**:
```
Task received
  └── Route to: GPT-4 (default - WRONG!)
```

---

### Rule 7: Every Note Must Have ≥1 Inbound and ≥1 Outbound Link

**Enforcement**: Weekly orphan detection fails CI.

**Why**: Orphan notes create knowledge gaps.

**Valid Note**:
```yaml
---
depends_on: [[Prerequisite_Note]]  # Outbound
used_by: [[Consumer_Note]]          # Inbound
---

Content with [[Another_Link]]  # Additional outbound
```

---

### Rule 8: Failed Gates Must Trigger Remediation, Not Bypass

**Enforcement**: Gate failures block progression automatically.

**Why**: Gate bypass is a security vulnerability.

**Flow**:
```
Gate Fails
  ├── Retry (automatic, max 3)
  ├── Remediate (AI fix attempt)
  ├── Escalate (human required)
  └── NEVER: Bypass
```

---

### Rule 9: All State Changes Must Be Version Controlled

**Enforcement**: OpenClaw commits state after every operation.

**Why**: Without version control, recovery is impossible.

**Commit Pattern**:
```
[OpenClaw] TICKET-2024-001: Implementation complete
- Files modified: 3
- Gates passed: 4/4
- Cost: $0.042
```

---

### Rule 10: Human Override Must Always Be Available

**Enforcement**: Emergency stop button in all autonomy levels.

**Why**: AI systems must never remove human agency.

**Override Commands**:
```bash
# Emergency stop
openclaw stop --emergency

# Pause for review
openclaw pause --reason "human-review-required"

# Force autonomy level
openclaw config --autonomy L0 --ticket TICKET-2024-001

# Rollback changes
openclaw rollback --to checkpoint-123
```

---

## Rule Enforcement Matrix

| Rule | Enforced By | Failure Action |
|------|-------------|----------------|
| 1 | Parser | Ticket rejected |
| 2 | Gate Template | Gate invalid |
| 3 | Git Hooks | Merge blocked |
| 4 | Cost Monitor | Operation paused |
| 5 | Escalation Logger | Escalation blocked |
| 6 | Model Router | Routing corrected |
| 7 | Orphan Check | CI fails |
| 8 | Gate Protocol | Progress blocked |
| 9 | State Manager | Auto-commit |
| 10 | Emergency Handler | Immediate stop |

## Rule Violation Response

### Level 1: Automatic Correction
- Rule 6: Router corrects to local model
- Rule 9: State manager auto-commits

### Level 2: Block and Notify
- Rule 1: Parser rejects, notifies author
- Rule 2: Gate validation fails, notifies owner
- Rule 7: CI fails, notifies team

### Level 3: Escalate to Human
- Rule 3: Merge blocked, requires override
- Rule 4: Operations paused, requires approval
- Rule 5: Escalation blocked, requires justification
- Rule 8: Progress blocked, requires decision
- Rule 10: Emergency stop, requires restart

## Rule Review

Rules are reviewed quarterly for:
- Effectiveness (are they preventing issues?)
- Burden (are they slowing work unnecessarily?)
- Coverage (are there gaps?)

Proposed changes require Tech Lead approval.

---

*These rules are non-negotiable. They exist because violations cause failures.*
