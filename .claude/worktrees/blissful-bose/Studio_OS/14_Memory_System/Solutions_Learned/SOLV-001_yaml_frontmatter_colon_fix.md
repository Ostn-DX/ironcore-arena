---
title: "YAML Frontmatter Colon Fix"
type: solution
layer: memory
status: active
domain: studio_os
tags:
  - solution
  - yaml
  - obsidian
  - vault_validation
---

# SOLV-001: YAML Frontmatter Colon Fix

**Problem Type:** YAML parsing error  
**Technology:** Obsidian Vault / Python  
**First Encountered:** 2026-03-01 in TASK-2026-03-01-001  
**Times Used:** 1

---

## Problem

### Symptoms
Vault validation fails with:
```
Invalid YAML frontmatter: mapping values are not allowed here
  in "<unicode string>", line 2, column 11:
    title: D01: Claude Teams Specification
```

### Context
When adding new markdown files to Studio_OS with titles containing colons (like "D01: Something"), the YAML parser interprets the colon as a key-value separator.

---

## Root Cause

YAML spec treats `key: value` syntax specially. A title like:
```yaml
title: D01: Claude Teams Specification
```

Is parsed as:
- `title`: `D01`
- `Claude Teams Specification`: (nothing - error!)

---

## Solution

### Immediate Fix
Wrap titles containing colons in quotes:

```yaml
title: "D01: Claude Teams Specification"
```

### Code Fix
Use regex to find and fix unquoted titles:

```python
import re

# Find title lines with colons that aren't quoted
new_content = re.sub(
    r'^title: ([^"\n][^\n]*?:[^\n]*)$',
    r'title: "\1"',
    content,
    flags=re.MULTILINE
)
```

### Prevention
Always quote titles in frontmatter if they contain:
- Colons (`:`)
- Hash symbols (`#`)
- Curly braces (`{}`)
- Square brackets (`[]`)

Or just always quote titles to be safe.

---

## Related Issues

- Fixed in: Adding 63 files to Studio_OS vault
- Affects: All new markdown files with colons in titles

---

## Verification

Run vault validation:
```bash
python tools/validate_vault.py
```

Expected: `VAULT VALIDATION PASSED`

---

## References

- YAML spec: https://yaml.org/spec/
- Python yaml module: https://pyyaml.org/wiki/PyYAMLDocumentation
