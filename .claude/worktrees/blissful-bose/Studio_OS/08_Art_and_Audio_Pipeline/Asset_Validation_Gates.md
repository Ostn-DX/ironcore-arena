---
title: Asset_Validation_Gates
type: system
layer: enforcement
status: active
tags:
  - validation
  - gates
  - assets
  - quality
depends_on: []
used_by:
  - "[Batch_Generation_Wlog]"
---

# Asset Validation Gates

## Purpose
Ensure all assets meet technical and visual standards before integration.

## Gate 1: Technical Validation (Automated)

### Command
```bash
python tools/validate_assets.py --batch BATCH-001
```

### Checks
| Check | Rule | Auto-Fix |
|-------|------|----------|
| Naming | Follows convention | No |
| Dimensions | Multiple of 8 | No |
| Format | PNG for sprites | No |
| File size | < 1MB per file | Compress |
| Color profile | sRGB | Convert |
| Transparency | Sprites only | No |

### Output
```
BATCH-001 Validation:
✓ Naming: 20/20 passed
✓ Dimensions: 20/20 passed
✓ Format: 20/20 passed
✓ File size: 18/20 passed (2 compressed)
✓ Color profile: 20/20 passed

Result: PASS (with 2 auto-fixes)
```

## Gate 2: Visual Validation (Human)

### Sample Rate
- 20% of batch (min 5 assets)
- All unique asset types
- Random selection

### Checklist
- [ ] Style matches design system
- [ ] Colors within palette
- [ ] Shadow present (if required)
- [ ] Readable at game size
- [ ] Consistent with existing assets

### Time Limit
- 30 seconds per asset
- Batch of 20: 2 minutes

## Gate 3: Integration Validation (Automated)

### Command
```bash
./tools/dev_gate.sh  # Includes asset loading tests
```

### Checks
- Assets load without errors
- No missing references
- Performance acceptable

## Rejection Categories

| Category | Action | Threshold |
|----------|--------|-----------|
| Critical | Reject entire batch | >5% fail |
| Major | Reject specific assets | Individual |
| Minor | Approve with notes | <5% fail |

## Fix Loop

```
Asset Fails
    ↓
Categorize (Critical/Major/Minor)
    ↓
Auto-fix if possible
    ↓
Manual fix if needed
    ↓
Re-validate
    ↓
Pass → Integrate
    ↓
Fail → Reject or regenerate
```

## Cost of Validation

| Gate | Time | Cost |
|------|------|------|
| Technical | 1 min/batch | $0 (automated) |
| Visual | 2 min/batch | $0.05 (human time) |
| Integration | 5 min | $0 (part of dev gate) |

## Related
[[Batch_Generation_Workflow]]
[[Asset_Naming_and_Import_Rules]]
[[Dev_Gate_Validation_System]]
