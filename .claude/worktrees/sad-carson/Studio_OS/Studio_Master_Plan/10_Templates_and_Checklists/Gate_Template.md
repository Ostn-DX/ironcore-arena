---
title: Gate Template
type: template
layer: enforcement
status: active
tags:
  - template
  - gate
  - quality
  - enforcement
  - automation
depends_on:
  - "[Quality_Gates_Overview]"
used_by: []
---

# Gate Template

## Purpose

Use this template when creating a new quality gate. Copy this file, replace all `[BRACKETED]` content, and customize for your specific gate.

## Gate Specification

---
title: [Gate_Name]_Gate
type: gate
layer: enforcement
status: [active|draft|deprecated]
tags: [tag1, tag2, ...]
depends_on: [[Quality_Gates_Overview]], [[Dependency_Gate_1]]
used_by: [[Downstream_Gate_1]], [[Release_Certification_Checklist]]
---

# [Gate_Name] Gate

## Purpose

[Brief description of what this gate validates and why it matters.]

## Tool/Script

**Primary**: `scripts/gates/[gate_name]_gate.py`
**Supporting Tools**: [List any supporting tools]

## Local Run

```bash
# Standard run
python scripts/gates/[gate_name]_gate.py

# With options
python scripts/gates/[gate_name]_gate.py --option value

# Quick mode
python scripts/gates/[gate_name]_gate.py --quick

# Verbose output
python scripts/gates/[gate_name]_gate.py --verbose
```

## CI Run

```yaml
# .github/workflows/[gate-name]-gate.yml
name: [Gate_Name] Gate
on: [push, pull_request]
jobs:
  [gate-name]:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: [Gate_Name] Gate
        run: python scripts/gates/[gate_name]_gate.py
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| [Check 1] | [Threshold] | [How measured] |
| [Check 2] | [Threshold] | [How measured] |
| [Check 3] | [Threshold] | [How measured] |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| [Check 1] | [Threshold] | [HARD/SOFT FAIL] |
| [Check 2] | [Threshold] | [HARD/SOFT FAIL] |
| [Check 3] | [Threshold] | [HARD/SOFT FAIL] |

## Configuration

```yaml
# config/[gate_name]_gate.yml
[gate_name]:
  threshold: [value]
  options:
    - option1: value1
    - option2: value2
```

## Failure Modes

### [Failure Mode 1]

**Symptoms**: [What you see when this fails]
**Root Causes**: [Why it might fail]
**Immediate Action**: [What happens when gate fails]

### [Failure Mode 2]

**Symptoms**: [What you see when this fails]
**Root Causes**: [Why it might fail]
**Immediate Action**: [What happens when gate fails]

## Remediation Steps

### Fix [Issue Type]

1. [Step 1]
2. [Step 2]
3. [Step 3]
4. Re-run gate: `python scripts/gates/[gate_name]_gate.py`
5. Verify fix

## Implementation Template

```python
# scripts/gates/[gate_name]_gate.py
#!/usr/bin/env python3
"""
[Gate_Name] Gate

[Brief description of gate purpose]
"""

import sys
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class GateResult:
    """Result of gate execution."""
    passed: bool
    message: str
    details: Optional[dict] = None
    
    def exit_code(self) -> int:
        return 0 if self.passed else 1

class [Gate_Name]Gate:
    """
    [Description of gate functionality]
    """
    
    # Configuration
    THRESHOLD = [value]
    TIMEOUT = [seconds]
    
    def __init__(self, config_path: Optional[Path] = None):
        self.config = self.load_config(config_path)
    
    def load_config(self, path: Optional[Path]) -> dict:
        """Load gate configuration."""
        if path and path.exists():
            import yaml
            return yaml.safe_load(path.read_text())
        return {}
    
    def run(self, options: dict) -> GateResult:
        """
        Execute the gate.
        
        Args:
            options: Runtime options
            
        Returns:
            GateResult with pass/fail status
        """
        try:
            # Perform validation
            issues = self.validate(options)
            
            if issues:
                return GateResult(
                    passed=False,
                    message=f"Gate failed with {len(issues)} issues",
                    details={"issues": issues}
                )
            
            return GateResult(
                passed=True,
                message="Gate passed"
            )
            
        except Exception as e:
            return GateResult(
                passed=False,
                message=f"Gate error: {e}"
            )
    
    def validate(self, options: dict) -> List[dict]:
        """
        Perform validation checks.
        
        Returns:
            List of issues found (empty if none)
        """
        issues = []
        
        # Check 1
        if not self.check_1():
            issues.append({
                "check": "check_1",
                "message": "Check 1 failed"
            })
        
        # Check 2
        if not self.check_2():
            issues.append({
                "check": "check_2",
                "message": "Check 2 failed"
            })
        
        return issues
    
    def check_1(self) -> bool:
        """Implement check 1."""
        pass
    
    def check_2(self) -> bool:
        """Implement check 2."""
        pass

def main():
    parser = argparse.ArgumentParser(description="[Gate_Name] Gate")
    parser.add_argument("--config", type=Path, help="Config file path")
    parser.add_argument("--quick", action="store_true", help="Quick mode")
    parser.add_argument("--verbose", action="store_true", help="Verbose output")
    
    args = parser.parse_args()
    
    gate = [Gate_Name]Gate(config_path=args.config)
    result = gate.run(vars(args))
    
    if args.verbose:
        print(f"Result: {result}")
    else:
        print(result.message)
    
    sys.exit(result.exit_code())

if __name__ == "__main__":
    main()
```

## Testing the Gate

```python
# tests/gates/test_[gate_name]_gate.py
import pytest
from scripts.gates.[gate_name]_gate import [Gate_Name]Gate, GateResult

class Test[Gate_Name]Gate:
    def test_passes_when_valid(self):
        gate = [Gate_Name]Gate()
        result = gate.run({"test_data": "valid"})
        assert result.passed
    
    def test_fails_when_invalid(self):
        gate = [Gate_Name]Gate()
        result = gate.run({"test_data": "invalid"})
        assert not result.passed
    
    def test_handles_errors(self):
        gate = [Gate_Name]Gate()
        result = gate.run({"test_data": "error"})
        assert not result.passed
        assert "error" in result.message.lower()
```

## Integration with Other Gates

- **Requires**: [[Dependency_Gate_1]] must pass first
- **Blocks**: [[Downstream_Gate_1]], [[Release_Certification_Checklist]]
- **Metrics feed**: [[Regression_Harness_Spec]]

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| [Issue description] | [Workaround] | [TICKET-XXX] |

## Checklist for New Gate

- [ ] Gate script implemented
- [ ] Configuration file created
- [ ] Tests written
- [ ] CI workflow added
- [ ] Documentation complete
- [ ] Thresholds defined
- [ ] Remediation steps documented
- [ ] Integration with other gates verified
- [ ] Added to [[Quality_Gates_Overview]]
- [ ] Added to [[Release_Certification_Checklist]]
