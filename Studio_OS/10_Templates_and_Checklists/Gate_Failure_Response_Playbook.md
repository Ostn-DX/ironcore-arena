---
title: Gate_Failure_Response_Playbook
type: template
layer: execution
status: active
tags:
  - template
  - playbook
  - gate
  - failure
depends_on: []
used_by:
  - "[Daily_Operator_Protocol]"
---

# Gate Failure Response Playbook

## Purpose
Standardized response to gate failures. Eliminates panic and ensures systematic resolution.

## Gate Failure Types

### Type A: Match Test Failure
**Symptoms:**
- Crashes during headless matches
- Timeouts > 20%
- Determinism check fails

**Response:**

```bash
# 1. Check logs
./tools/dev_gate.sh 2>&1 | tee gate.log
grep "ERROR\|CRASH\|FAIL" gate.log

# 2. Identify failing seed
# Look for: "Match X failed"

# 3. Reproduce manually
godot --headless --script res://tools/run_headless_matches.gd

# 4. If reproducible:
# - Check SimulationManager.gd for recent changes
# - Verify determinism (seeded RNG)
# - Check for null references
```

**Resolution paths:**
1. Fix crash cause → Re-run gate
2. If determinism break → Escalate to architect
3. If performance issue → Profile and optimize

### Type B: UI Smoke Failure
**Symptoms:**
- Scene transition fails
- Button not found
- Signal not connected

**Response:**

```bash
# 1. Identify failing transition
# Look for: "FAIL: Main → Builder"

# 2. Check scene exists
ls -la project/scenes/main_menu.tscn

# 3. Check for node name changes
# Compare scene file to test expectations

# 4. Verify button names
# Look for: "Button 'X' not found"
```

**Common fixes:**
- Renamed node not updated in code
- Scene not saved after edit
- Signal connection missing

### Type C: Determinism Failure
**Symptoms:**
- Same seed, different results
- Replay desync

**Response:**

```bash
# 1. Run determinism check
./tools/run_determinism_check.sh

# 2. Search for unseeded random
grep -r "randf()\|randi()" --include="*.gd" project/src/

# 3. Check for time-based logic
grep -r "Time.get_unix" --include="*.gd" project/

# 4. Check dictionary iteration
grep -r ".keys()" --include="*.gd" project/src/ | grep -v ".sort()"
```

**Always escalates to architect** - Determinism is critical.

## Decision Tree

```
GATE FAILS
    │
    ├─→ Match crash?
    │   ├─→ Yes → Fix crash → Re-run
    │   └─→ No → Continue
    │
    ├─→ UI smoke fail?
    │   ├─→ Yes → Check node names → Fix → Re-run
    │   └─→ No → Continue
    │
    ├─→ Determinism fail?
    │   ├─→ Yes → ESCALATE (architect review)
    │   └─→ No → Continue
    │
    └─→ Unknown?
        └─→ ESCALATE (human investigation)
```

## Retry Limits

| Failure Type | Max Retries | Escalate After |
|--------------|-------------|----------------|
| Match crash | 2 | 3rd failure |
| UI smoke | 2 | 3rd failure |
| Determinism | 1 | Immediate |
| Unknown | 1 | Immediate |

## Documentation Required

Every gate failure must log:
```markdown
## Gate Failure Log

**Ticket:** TICKET-XXX
**Date:** YYYY-MM-DD
**Type:** [Match/UI/Determinism]
**Error:** [Specific error message]
**Root Cause:** [What caused it]
**Fix:** [How it was fixed]
**Time to Resolve:** [Minutes]
```

## Prevention

### Pre-Flight Checks
```bash
# Before submitting to gate:
./tools/lint.sh           # Static analysis
./tools/validate_syntax.sh # GDScript syntax
./tools/check_determinism.sh # Quick determinism check
```

### CI Integration
- Gate runs on every PR
- Gate runs on every commit to main
- Failed gate blocks merge

## Related
[[Dev_Gate_Validation_System]]
[[Escalation_Triggers]]
[[Patch_Protocol]]
