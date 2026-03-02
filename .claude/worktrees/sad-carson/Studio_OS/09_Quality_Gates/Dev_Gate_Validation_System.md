---
title: Dev_Gate_Validation_System
type: system
layer: enforcement
status: active
tags:
  - quality
  - gates
  - testing
  - automation
depends_on:
  - "[Headless_Match_Runner]]"
  - "[[UI_Smoke_Test]]"
  - "[[Determinism_Test]"
used_by:
  - "[Pre_Commit_Hook]]"
  - "[[CI_Pipeline]]"
  - "[[Agent_Output_Validation]"
---

# Dev Gate Validation System

## Purpose
Single command that validates build is playable, stable, and regression-free. Gate must pass before any commit or merge.

## Core Rules

### Gate Stages

#### Stage 1: Headless Match Tests
```bash
godot --headless --script res://tools/run_headless_matches.gd
```

**Validation:**
- 10 matches complete without crashes
- Timeout rate < 20%
- Average duration 2-10 seconds
- Deterministic (same seeds)

**Exit Code:**
- 0 = Pass
- 1 = Fail (crash, timeout, or error)

#### Stage 2: UI Smoke Tests
```bash
godot --headless --script res://tools/run_ui_smoke.gd
```

**Navigation Path:**
```
Main Menu → Builder → Campaign → Battle → Results → Campaign
```

**Validation:**
- All scenes load successfully
- All buttons clickable
- All transitions complete
- No missing nodes or signals

#### Stage 3: Determinism Check (Optional)
```bash
godot --headless --script res://tools/run_determinism_check.gd
```

**Validation:**
- Same seed = identical battle log hash
- Cross-platform consistency

### Gate Script Interface

**Windows:**
```powershell
.\tools\dev_gate.ps1
```

**Mac/Linux:**
```bash
./tools/dev_gate.sh
```

**Output:**
```
=== HEADLESS MATCH SUMMARY ===
Total matches: 10
Crashes: 0 ✓
Timeouts: 0 ✓
Avg duration: 2.45s
Player win rate: 50.0%
==============================

=== UI SMOKE TEST SUMMARY ===
Transitions: 6 passed, 0 failed ✓
Success rate: 100.0%
=============================

DEVELOPMENT GATE: PASSED ✓
```

## Failure Modes

### Gate Fail - Match Crashes
**Action:** Fix crash, re-run gate
**Do Not:** Commit with failing gate

### Gate Fail - UI Transition Broken
**Action:** Fix scene/node reference, re-run gate
**Common Causes:**
- Renamed node not updated in code
- Missing scene file
- Signal connection broken

### Gate Fail - Determinism Broken
**Action:** Audit for unseeded random calls
**Severity:** Critical (blocks all AI work)

## Enforcement

### Pre-Commit Hook
```bash
# .git/hooks/pre-commit
./tools/dev_gate.sh
if [ $? -ne 0 ]; then
    echo "Gate failed. Commit aborted."
    exit 1
fi
```

### CI Pipeline
- Gate runs on every PR
- Gate runs on every push to main
- Failed gate blocks merge

### Agent Workflow
- Every ticket ends with gate run
- Gate must pass before ticket complete
- Agent output normalizer validates gate readiness

## Related
[[Headless_Match_Runner_Implementation]]
[[UI_Smoke_Test_Implementation]]
[[CI_CD_Pipeline_Configuration]]
[[Git_Hooks_Setup]]
