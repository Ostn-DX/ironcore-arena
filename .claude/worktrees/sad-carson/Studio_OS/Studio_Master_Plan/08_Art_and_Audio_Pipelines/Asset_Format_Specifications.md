---
title: Asset Format Specifications
type: rule
layer: enforcement
status: active
tags:
  - art
  - format
  - specifications
  - png
  - jpg
  - svg
depends_on:
  - "[Art_Pipeline_Overview]]"
  - "[[Asset_Resolution_Standards]"
used_by:
  - "[Batch_Generation_Workflow]]"
  - "[[Import_Settings_Validation]"
---

# Asset Format Specifications

## Purpose

Define format requirements for each asset type to ensure compatibility, performance, and quality. Format choice directly impacts file size, quality, and engine compatibility.

---

## Format Selection Philosophy

**Choose the format that provides the best balance of:**
1. Quality preservation
2. File size
3. Engine compatibility
4. Feature support (transparency, animation)

---

## Format Reference

| Format | Transparency | Compression | Best For |
|--------|--------------|-------------|----------|
| PNG | Yes | Lossless | Sprites, UI, icons |
| JPG | No | Lossy | Backgrounds, photos |
| SVG | Yes | Vector | UI, icons, scalable elements |
| WebP | Yes | Lossy/Lossless | Web games, smaller files |
| TGA | Yes | Uncompressed | Source files, specific engines |
| PSD | Yes | None | Source files only |
| GIF | Yes (1-bit) | Lossy | Simple animations (avoid) |
| APNG | Yes | Lossless | Sprite animations |

---

## Format by Asset Type

### Sprites & Characters

**Primary Format**: PNG
```
char_hero_idle_01.png
```

**Requirements**:
- 32-bit RGBA (full transparency)
- Lossless compression
- No interlacing

**Why PNG**: Lossless quality, full transparency, universal support.

### Environment & Backgrounds

**Primary Format**: PNG (for transparency), JPG (for opaque)

**With Transparency**:
```
env_forest_tree_01.png  # Has transparent areas
```

**Opaque Only**:
```
env_sky_gradient_01.jpg  # No transparency needed
```

**Quality Settings**:
- PNG: Always lossless
- JPG: Quality 85-90 (balance of size/quality)

### UI Elements

**Icons (Small)**: PNG
```
icon_ability_fireball_64.png
```

**Icons (Scalable)**: SVG
```
icon_ability_fireball.svg
```

**Buttons/Frames**: PNG (if complex), SVG (if simple shapes)
```
ui_button_primary_default.png
ui_icon_simple_shape.svg
```

**Full-Screen Backgrounds**: JPG
```
ui_menu_background_01.jpg
```

### Props & Items

**Primary Format**: PNG
```
prop_sword_iron_01.png
```

**With Transparency**: Required for inventory icons

### Effects/VFX

**Primary Format**: PNG
```
fx_explosion_01.png
```

**Animation Sequences**: PNG sequence or sprite sheet
```
fx_explosion_sheet_512.png  # Sprite sheet
fx_explosion_01.png         # Frame 1
fx_explosion_02.png         # Frame 2
```

### Textures (3D)

**Primary Format**: PNG (source), compressed in-engine

**Source Files**:
```
tex_metal_iron_diffuse.png
tex_metal_iron_normal.png
tex_metal_iron_roughness.png
```

**Engine Compression**:
- Unity: DXT5 (diffuse), DXT5 (normal), DXT1 (roughness)
- Unreal: BC3 (diffuse), BC5 (normal), BC4 (roughness)

---

## Format Decision Tree

```
Does asset need transparency?
├── YES → Is it animated?
│   ├── YES → PNG sequence or APNG
│   └── NO  → PNG
└── NO  → Is it a photo/gradient?
    ├── YES → JPG (quality 85-90)
    └── NO  → Is it scalable vector?
        ├── YES → SVG
        └── NO  → PNG
```

---

## Compression Settings

### PNG Optimization

**Tools**: oxipng, pngquant, ImageMagick

**Recommended**:
```bash
# Lossless optimization
oxipng -o 4 --strip all input.png

# Lossy optimization (if needed)
pngquant --quality=65-80 input.png
```

**Settings**:
- Compression: Maximum (level 9)
- Filter: Adaptive
- No interlacing

### JPG Optimization

**Quality Guidelines**:
| Use Case | Quality | Reason |
|----------|---------|--------|
| UI Backgrounds | 90 | Must be crisp |
| Environment | 85 | Balance quality/size |
| Large Backgrounds | 80 | Size priority |
| Temporary/Placeholder | 70 | Fast iteration |

**Command**:
```bash
convert input.png -quality 85 output.jpg
```

### SVG Optimization

**Tools**: svgo

```bash
svgo input.svg -o output.svg
```

**Settings**:
- Remove unnecessary metadata
- Minify paths
- Remove unused defs

---

## Format Validation

### Automated Checks
```python
def validate_format(filename, file_content):
    """Validate asset format against standards"""
    
    extension = filename.split('.')[-1].lower()
    category = get_category_from_filename(filename)
    
    # Expected format for category
    expected_formats = {
        'char': ['png'],
        'env': ['png', 'jpg'],
        'prop': ['png'],
        'ui': ['png', 'svg'],
        'fx': ['png'],
        'icon': ['png', 'svg'],
        'tex': ['png', 'tga'],
    }
    
    expected = expected_formats.get(category, ['png'])
    
    if extension not in expected:
        return False, f"Format .{extension} not expected for {category}. Use: {expected}"
    
    # Check transparency requirement
    needs_transparency = category in ['char', 'prop', 'fx', 'icon']
    if needs_transparency and extension == 'jpg':
        return False, f"{category} requires transparency, cannot use JPG"
    
    return True, "Valid"
```

---

## File Size Targets

| Asset Type | Target Size | Maximum Size |
|------------|-------------|--------------|
| 32x32 Icon | < 5 KB | 10 KB |
| 64x64 Sprite | < 15 KB | 30 KB |
| 128x128 Character | < 50 KB | 100 KB |
| 256x256 Texture | < 150 KB | 300 KB |
| 512x512 Background | < 500 KB | 1 MB |
| 1024x1024 Texture | < 1.5 MB | 3 MB |
| 1920x1080 Background | < 2 MB | 5 MB |

**Alert Threshold**: Files exceeding max size trigger optimization review.

---

## Source File Management

### Source Files (PSD, AI, etc.)

**Rule**: Keep source files in separate `/Sources/` directory, never in game build.

```
Project/
├── Assets/           # Game-ready formats only
│   ├── Characters/
│   └── UI/
└── Sources/          # Source files
    ├── Characters/
    └── UI/
```

**Naming**: Add `_source` suffix
```
char_hero_source.psd
ui_button_source.ai
```

---

## Platform-Specific Notes

### Mobile

- Prefer compressed formats (PVR, ETC, ASTC)
- Keep PNG source, let engine compress
- Target: < 100 MB total texture memory

### Web

- Consider WebP for smaller downloads
- Fallback to PNG for compatibility
- Target: < 50 MB total download

### Console/PC

- Larger textures acceptable
- Use engine compression (BC1-BC7)
- Target: < 1 GB total texture memory

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  FORMAT QUICK REFERENCE                                │
├────────────────────────────────────────────────────────┤
│  PNG: Sprites, UI, icons, anything with transparency   │
│  JPG: Backgrounds, photos, opaque images               │
│  SVG: Scalable icons, simple UI shapes                 │
│  TGA: Source textures, specific engine requirements    │
├────────────────────────────────────────────────────────┤
│  RULES:                                                │
│  ✓ Use PNG for transparency                            │
│  ✓ Use JPG for large opaque images                     │
│  ✓ Use SVG for scalable elements                       │
│  ✓ Optimize before import                              │
│  ✓ Keep sources separate                               │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Asset_Resolution_Standards]] - Resolution constraints
- [[Batch_Generation_Workflow]] - Format selection
- [[Import_Settings_Validation]] - Format validation
- [[Atlas_Packing_Strategy]] - Atlas format requirements
