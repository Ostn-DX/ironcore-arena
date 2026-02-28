---
title: Self_Repair_Loop
type: system
layer: execution
status: planned
tags:
  - autonomy
  - repair
  - self-healing
  - automation
depends_on:
  - "[Autonomy_Ladder_L0_to_L5]"
used_by:
  - "[Daily_Operator_Protocol]"
---

# Self-Repair Loop

## Purpose
Enable OpenClaw to fix common issues without human escalation. Required for L4 autonomy.

## Repair Categories

### Category 1: Syntax Errors
**Detection:** Gate failure, parse error

**Auto-Fix Attempts:**
```python
fixes = [
    "Add missing colon at end of function definition",
    "Fix indentation (tabs vs spaces)",
    "Add missing 'var' keyword",
    "Close unclosed parentheses/brackets",
    "Add missing 'pass' in empty function",
]
```

**Success Rate Target:** 80%

**Escalation:** If 2 auto-fixes fail → Human

---

### Category 2: Missing Imports
**Detection:** "Identifier not declared" errors

**Auto-Fix:**
```python
# Scan file for class names
# Check if class_name exists in project
# Add 'const ClassName = preload("path")'
```

**Success Rate Target:** 90%

---

### Category 3: Type Mismatch
**Detection:** Type checker warnings

**Auto-Fix:**
```python
# Add explicit type casts
# Fix function return types
# Update variable declarations
```

**Success Rate Target:** 70%

---

### Category 4: Test Failures
**Detection:** GUT test fails

**Auto-Fix:**
```python
# Check if test expects old behavior
# Update test to match implementation
# Or fix implementation to match test
```

**Escalation:** If logic error suspected → Human

---

### Category 5: Gate Failures (Non-Critical)
**Detection:** UI smoke test fails

**Auto-Fix:**
```python
# Check if node renamed
# Update references in code
# Check if scene file saved
```

**Escalation:** If structural issue → Human

## Repair Loop Process

```
DETECT FAILURE
     │
     ├─→ Can auto-fix?
     │   ├─→ YES → Apply fix
     │   │          │
     │   │          ├─→ Fixed? → Re-run gate
     │   │          │                │
     │   │          │                ├─→ PASS → Continue
     │   │          │                └─→ FAIL → Next fix
     │   │          │
     │   │          └─→ Not fixed? → Next fix
     │   │
     │   └─→ NO → ESCALATE
     │
     └─→ Out of fixes? → ESCALATE
```

## Repair Limits

| Category | Max Attempts | Escalate After |
|----------|--------------|----------------|
| Syntax | 3 | 4th failure |
| Imports | 2 | 3rd failure |
| Types | 2 | 3rd failure |
| Tests | 1 | Logic suspected |
| Gate | 2 | Structural issue |

## Success Tracking

```yaml
repair_metrics:
  category: "syntax"
  attempts: 150
  successes: 127
  success_rate: 84.7%
  avg_fixes_per_success: 1.3
  escalation_rate: 15.3%
```

**Target:** >80% success rate overall

## Not Auto-Repairable

These always escalate:
- Determinism breaks
- Logic errors
- Architecture issues
- Performance regressions
- Design decisions

## Implementation

```python
class SelfRepairSystem:
    def attempt_repair(self, failure_type, error_message):
        strategies = self.get_strategies(failure_type)
        
        for strategy in strategies:
            if strategy.can_apply(error_message):
                fix_applied = strategy.apply()
                if fix_applied:
                    return RepairResult.SUCCESS
        
        return RepairResult.ESCALATE
```

## Related
[[Autonomy_Ladder_L0_to_L5]]
[[Escalation_Policy]]
