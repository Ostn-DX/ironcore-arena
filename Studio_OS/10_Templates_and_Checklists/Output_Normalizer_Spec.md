---
title: Output_Normalizer_Spec
type: template
layer: execution
status: active
tags:
  - template
  - validation
  - output
  - automation
depends_on: []
used_by:
  - "[Daily_Operator_Protocol]"
---

# Output Normalizer Spec

## Purpose
Validate agent deliverables before human integration. Catches incomplete work early.

## Validation Command

```bash
python tools/normalize_agent_output.py TICKET-XXX
```

## Validation Rules

### 1. Directory Structure
```
agent_runs/TICKET-XXX/
├── NEW_FILES/          [REQUIRED]
├── MODIFICATIONS/      [REQUIRED]
├── TESTS/              [REQUIRED]
├── INTEGRATION_GUIDE.md [REQUIRED]
└── CHANGELOG.md        [REQUIRED]
```

**Fail if:** Any required directory/file missing

### 2. New Files Validation

```python
checks = {
    "no_todo": r'TODO|FIXME|XXX',
    "no_stubs": r'func \w+\([^)]*\)\s*->\s*\w+\s*:\s*\n\s*pass\s*$',
    "type_hints": r'func \w+\([^)]*\)\s*->',
    "class_name": r'class_name \w+',
}
```

**Fail if:**
- Any TODO/FIXME found
- Empty function stubs
- Missing type hints
- Missing class_name

### 3. Modification Validation

- All modified files must be in ticket allowlist
- No forbidden files touched
- Patch files must apply cleanly

**Fail if:**
- Edit outside allowlist
- Patch applies with fuzz
- Binary files modified

### 4. Integration Guide Validation

Required sections:
- Prerequisites
- New files to create
- Files to modify
- Test commands
- Rollback instructions

**Fail if:** Any section missing or incomplete

### 5. Test Validation

```python
test_requirements = {
    "gut_format": True,
    "test_functions": ">= 1",
    "assertions": ">= 1",
    "no_pending": True,
}
```

**Fail if:** No test files or empty tests

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Pass, ready for integration |
| 1 | Critical failure (structural) |
| 2 | Content failure (TODOs, stubs) |
| 3 | Allowlist violation |
| 4 | Test failure |

## Error Report Format

```
=== OUTPUT NORMALIZATION: TICKET-001 ===

Status: FAIL ✗

CRITICAL:
  ✗ Missing required file: INTEGRATION_GUIDE.md

CONTENT:
  ✗ Stub found in tactical.gd:42 - "pass # TODO implement"
  ✗ Missing type hint in squad.gd:15

ALLOWLIST:
  ✓ All modifications in allowlist

TESTS:
  ⚠ Only 2 test functions (recommend 5+)

Fix and re-run normalization.
```

## Automated Fixes

```bash
# Auto-fix minor issues
python tools/normalize_agent_output.py TICKET-XXX --fix

# Fixes applied:
# - Trailing whitespace
# - Missing newlines at EOF
# - Mixed indentation
```

## Human Review Triggers

| Condition | Action |
|-----------|--------|
| Normalization fails 3x | Human review required |
| Test coverage < 50% | Request more tests |
| Cost exceeds estimate 2x | Escalate to human |

## Related
[[Ticket_Template]]
[[Patch_Protocol]]
[[Escalation_Triggers]]
