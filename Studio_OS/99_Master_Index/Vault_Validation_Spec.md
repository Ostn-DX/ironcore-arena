---
title: Vault_Validation_Spec
type: rule
layer: enforcement
status: active
tags:
  - validation
  - vault
  - quality
  - automation
depends_on: []
used_by:
  - "[validate_vault_py]"
---

# Vault Validation Spec

## Purpose
Mechanically verify Studio_OS vault integrity before any autonomy operations. Failed vault = halted execution.

## Validation Rules

### 1. YAML Frontmatter Required Keys
```yaml
---
title: [required, PascalCase, unique]
type: [required, enum: system|pitfall|rule|index|template|cost|agent|mechanic]
layer: [required, enum: design|architecture|enforcement|execution|meta|costing]
status: [required, enum: active|planned|deprecated|draft]
tags: [required, array of strings]
depends_on: [optional, array of wiki links]
used_by: [optional, array of wiki links]
---
```

**Validation:**
- All required keys present
- `title`: PascalCase, no spaces, unique across vault
- `type`: Must be from allowed enum
- `layer`: Must be from allowed enum
- `status`: Must be from allowed enum
- `tags`: Array format, lowercase with underscores

### 2. Link Resolution Rules
- All `[[WikiLinks]]` in body must resolve to existing note
- All `depends_on` links must resolve
- All `used_by` links must resolve
- Links are case-sensitive
- Self-links (`[[Self]]`) forbidden

### 3. Duplicate Title Detection
- `title` must be unique across all 21+ notes
- Case-insensitive comparison
- Violation = CRITICAL failure

### 4. Orphan Detection Rule
- Every note must have ≥1 inbound link (from `depends_on` or `used_by`)
- OR be in `99_Master_Index/` (index notes exempt)
- OR be root system notes with explicit exemption
- Violation = WARNING (not critical)

### 5. Max Word Count Rule
- Max: 800 words per note
- Count: All text after frontmatter
- Exclude: Code blocks, YAML frontmatter
- Violation = WARNING

### 6. Max Dependency Count Rule
- Max: 5 items in `depends_on`
- Max: 5 items in `used_by`
- Prevents note bloat
- Violation = WARNING

### 7. File Organization Rules
- All notes in `.md` format
- All in `Studio_OS/` subdirectories
- No notes at vault root
- Directory names: `XX_Category_Name/`

## Validation Output

### Pass
```
=== VAULT VALIDATION ===
Total Notes: 21
Critical: 0 failures
Warnings: 0
Status: PASS ✓
========================
```

### Fail
```
=== VAULT VALIDATION ===
Total Notes: 21
Critical: 2 failures
  ✗ Duplicate title: "System_Map" (notes/ 12, 45)
  ✗ Missing depends_on: "Tactical_AI_System" → "[[NonExistent]]"
Warnings: 1
  ⚠ Orphan: "Draft_Note" (0 inbound links)
Status: FAIL ✗
========================
```

## Enforcement

### Pre-Execution
- `validate_vault.py` must pass before any agent work
- Failed validation = immediate halt
- Human fixes, re-runs validation

### CI Integration
- Validation runs on every vault change
- Failed validation blocks merge

## Exit Codes
- `0`: Pass
- `1`: Critical failures
- `2`: Warnings only (pass with warnings)

## Related
[[validate_vault_py]]
[[Vault_Integrity_Policy]]
[[CI_Pipeline_Configuration]]
