---
title: Art Validation Gates
type: gate
layer: enforcement
status: active
tags:
  - art
  - validation
  - gates
  - quality-control
  - automation
depends_on:
  - "[Art_Pipeline_Overview]]"
  - "[[Batch_Generation_Workflow]]"
  - "[[Asset_Naming_Conventions]"
used_by:
  - "[Batch_Generation_Workflow]]"
  - "[[Import_Settings_Validation]"
---

# Art Validation Gates

## Purpose

Automated checkpoints that validate art assets against defined standards before they enter the production pipeline. Catches errors early, prevents downstream issues.

---

## Gate Philosophy

**Every asset passes through gates. Gates are automated. Gates don't negotiate.**

```
Asset Created → Gate 1 → Gate 2 → Gate 3 → Production Ready
                (Naming)  (Format)  (Quality)
```

---

## Gate 1: Naming Convention Gate

**Purpose**: Ensure consistent naming for organization and automation

### Checks

| Check | Rule | Auto-Fix |
|-------|------|----------|
| Prefix valid | Must start with approved prefix | No |
| Lowercase | All lowercase | Yes |
| No spaces | Underscores only | Yes |
| No special chars | A-Z, 0-9, _ only | No |
| Extension valid | .png, .jpg, .svg, etc. | No |

### Validation Script

```python
def naming_gate(filename):
    """Returns (passed, errors, warnings)"""
    errors = []
    warnings = []
    
    # Check prefix
    valid_prefixes = ['char_', 'env_', 'prop_', 'ui_', 'fx_', 'icon_', 'tex_', 'spr_']
    if not any(filename.startswith(p) for p in valid_prefixes):
        errors.append(f"Invalid prefix. Must start with: {valid_prefixes}")
    
    # Check lowercase
    if filename != filename.lower():
        warnings.append("Not lowercase")
    
    # Check spaces
    if ' ' in filename:
        errors.append("Contains spaces")
    
    # Check extension
    valid_extensions = ['.png', '.jpg', '.jpeg', '.svg', '.psd', '.tga']
    if not any(filename.endswith(e) for e in valid_extensions):
        errors.append(f"Invalid extension. Use: {valid_extensions}")
    
    return len(errors) == 0, errors, warnings
```

### Gate Output

```yaml
gate_1_naming:
  asset: "char_Hero Idle.png"
  passed: false
  errors:
    - "Contains spaces"
    - "Not lowercase"
  warnings: []
  suggested_fix: "char_hero_idle.png"
```

---

## Gate 2: Resolution Gate

**Purpose**: Ensure assets meet resolution standards

### Checks

| Check | Rule | Auto-Fix |
|-------|------|----------|
| Power-of-two | Width/height must be power-of-two | No |
| Within limits | Size <= category maximum | No |
| Aspect ratio | Within acceptable range | No |
| Minimum size | Size >= category minimum | No |

### Validation Script

```python
def resolution_gate(image_path, category):
    """Returns (passed, errors, warnings)"""
    from PIL import Image
    
    img = Image.open(image_path)
    width, height = img.size
    errors = []
    warnings = []
    
    # Power-of-two check
    def is_power_of_two(n):
        return n > 0 and (n & (n - 1)) == 0
    
    if not is_power_of_two(width):
        errors.append(f"Width {width} is not power-of-two")
    if not is_power_of_two(height):
        errors.append(f"Height {height} is not power-of-two")
    
    # Size limits
    limits = {
        'char': (32, 256),
        'env': (64, 512),
        'ui': (16, 128),
        'fx': (16, 128),
    }
    
    min_size, max_size = limits.get(category, (32, 1024))
    
    if width > max_size or height > max_size:
        errors.append(f"Size exceeds maximum {max_size}x{max_size}")
    if width < min_size or height < min_size:
        warnings.append(f"Size below minimum {min_size}x{min_size}")
    
    return len(errors) == 0, errors, warnings
```

---

## Gate 3: Format Gate

**Purpose**: Ensure correct file format for asset type

### Checks

| Check | Rule | Auto-Fix |
|-------|------|----------|
| Format appropriate | Format matches category requirements | No |
| Transparency | PNG/SVG if transparency needed | No |
| Compression | File size within limits | No |
| Corruption | File is valid and readable | No |

### Validation Script

```python
def format_gate(file_path, category):
    """Returns (passed, errors, warnings)"""
    import os
    from PIL import Image
    
    errors = []
    warnings = []
    
    extension = file_path.split('.')[-1].lower()
    
    # Format requirements
    format_requirements = {
        'char': ['png'],
        'env': ['png', 'jpg'],
        'prop': ['png'],
        'ui': ['png', 'svg'],
        'fx': ['png'],
        'icon': ['png', 'svg'],
    }
    
    required_formats = format_requirements.get(category, ['png'])
    
    if extension not in required_formats:
        errors.append(f"Format .{extension} not suitable for {category}. Use: {required_formats}")
    
    # File corruption check
    try:
        img = Image.open(file_path)
        img.verify()
    except Exception as e:
        errors.append(f"File corruption detected: {e}")
    
    # File size check
    file_size = os.path.getsize(file_path)
    size_limits = {
        'char': 100 * 1024,      # 100 KB
        'env': 500 * 1024,       # 500 KB
        'ui': 50 * 1024,         # 50 KB
        'fx': 100 * 1024,        # 100 KB
    }
    
    limit = size_limits.get(category, 1024 * 1024)
    if file_size > limit:
        warnings.append(f"File size {file_size/1024:.1f}KB exceeds recommended {limit/1024:.1f}KB")
    
    return len(errors) == 0, errors, warnings
```

---

## Gate 4: Quality Gate

**Purpose**: Ensure visual quality meets standards

### Checks

| Check | Rule | Auto-Fix |
|-------|------|----------|
| Blur detection | Laplacian variance > threshold | No |
| Color consistency | Palette distance < threshold | No |
| Content presence | Subject detected in image | No |
| Duplicate check | Not duplicate of existing asset | No |

### Validation Script

```python
import cv2
import numpy as np
from PIL import Image
import imagehash

def quality_gate(image_path, reference_palette=None):
    """Returns (passed, errors, warnings)"""
    errors = []
    warnings = []
    
    img = cv2.imread(image_path)
    
    # Blur detection
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    
    if laplacian_var < 100:
        errors.append(f"Image too blurry (variance: {laplacian_var:.1f})")
    elif laplacian_var < 200:
        warnings.append(f"Image slightly blurry (variance: {laplacian_var:.1f})")
    
    # Color consistency (if reference provided)
    if reference_palette:
        img_pil = Image.open(image_path)
        img_palette = img_pil.getpalette()
        
        # Compare palettes
        palette_distance = compare_palettes(img_palette, reference_palette)
        if palette_distance > 50:
            warnings.append(f"Color palette diverges from reference (distance: {palette_distance:.1f})")
    
    # Duplicate detection
    img_hash = imagehash.average_hash(Image.open(image_path))
    # Check against existing assets database
    
    return len(errors) == 0, errors, warnings
```

---

## Gate 5: Style Consistency Gate

**Purpose**: Ensure asset matches approved style lock

### Checks

| Check | Rule | Auto-Fix |
|-------|------|----------|
| Style match | Perceptual hash within threshold | No |
| Color palette | Uses approved palette | No |
| Generation params | Metadata matches style lock | No |

### Validation Script

```python
def style_gate(image_path, style_lock):
    """Returns (passed, errors, warnings)"""
    from PIL import Image
    import imagehash
    
    errors = []
    warnings = []
    
    img = Image.open(image_path)
    
    # Perceptual hash comparison
    img_hash = imagehash.average_hash(img)
    ref_hash = imagehash.hex_to_hash(style_lock['reference_hash'])
    
    hash_diff = img_hash - ref_hash
    if hash_diff > 10:
        errors.append(f"Style divergence detected (hash diff: {hash_diff})")
    elif hash_diff > 5:
        warnings.append(f"Minor style variation (hash diff: {hash_diff})")
    
    # Check embedded metadata
    metadata = extract_metadata(image_path)
    if metadata:
        if metadata.get('model') != style_lock['model']:
            warnings.append(f"Model mismatch: {metadata.get('model')} vs {style_lock['model']}")
    
    return len(errors) == 0, errors, warnings
```

---

## Gate Pipeline Integration

### Full Validation Pipeline

```python
def validate_asset(asset_path, category, style_lock=None):
    """Run all validation gates"""
    
    results = {
        'asset': asset_path,
        'timestamp': datetime.now().isoformat(),
        'gates': {}
    }
    
    # Gate 1: Naming
    passed, errors, warnings = naming_gate(os.path.basename(asset_path))
    results['gates']['naming'] = {'passed': passed, 'errors': errors, 'warnings': warnings}
    
    if not passed:
        return results  # Stop if naming fails
    
    # Gate 2: Resolution
    passed, errors, warnings = resolution_gate(asset_path, category)
    results['gates']['resolution'] = {'passed': passed, 'errors': errors, 'warnings': warnings}
    
    if not passed:
        return results
    
    # Gate 3: Format
    passed, errors, warnings = format_gate(asset_path, category)
    results['gates']['format'] = {'passed': passed, 'errors': errors, 'warnings': warnings}
    
    if not passed:
        return results
    
    # Gate 4: Quality
    passed, errors, warnings = quality_gate(asset_path)
    results['gates']['quality'] = {'passed': passed, 'errors': errors, 'warnings': warnings}
    
    # Gate 5: Style (if style lock provided)
    if style_lock:
        passed, errors, warnings = style_gate(asset_path, style_lock)
        results['gates']['style'] = {'passed': passed, 'errors': errors, 'warnings': warnings}
    
    # Overall result
    results['overall_passed'] = all(g['passed'] for g in results['gates'].values())
    
    return results
```

---

## Gate Failure Handling

| Gate | Failure Action | Retry Allowed |
|------|---------------|---------------|
| Naming | Reject, require rename | Yes |
| Resolution | Reject, require resize | Yes |
| Format | Reject, require conversion | Yes |
| Quality | Flag for review | Yes (re-generate) |
| Style | Alert, pause batch | Yes (adjust prompt) |

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  VALIDATION GATES QUICK REFERENCE                      │
├────────────────────────────────────────────────────────┤
│  GATE 1: Naming                                        │
│  ✓ Valid prefix ✓ Lowercase ✓ No spaces               │
├────────────────────────────────────────────────────────┤
│  GATE 2: Resolution                                    │
│  ✓ Power-of-two ✓ Within limits ✓ Valid aspect        │
├────────────────────────────────────────────────────────┤
│  GATE 3: Format                                        │
│  ✓ Appropriate format ✓ Valid file ✓ Size OK          │
├────────────────────────────────────────────────────────┤
│  GATE 4: Quality                                       │
│  ✓ Not blurry ✓ Color consistent ✓ Content present    │
├────────────────────────────────────────────────────────┤
│  GATE 5: Style                                         │
│  ✓ Matches style lock ✓ Palette consistent            │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Batch_Generation_Workflow]] - Gates integrated into workflow
- [[Asset_Naming_Conventions]] - Gate 1 criteria
- [[Asset_Resolution_Standards]] - Gate 2 criteria
- [[Asset_Format_Specifications]] - Gate 3 criteria
- [[Style_Lock_Approval_Process]] - Gate 5 criteria
