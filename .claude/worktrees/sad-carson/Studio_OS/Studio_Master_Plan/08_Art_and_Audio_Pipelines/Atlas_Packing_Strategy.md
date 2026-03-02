---
title: Atlas Packing Strategy
type: system
layer: architecture
status: active
tags:
  - art
  - atlas
  - texture-packing
  - optimization
  - performance
depends_on:
  - "[Asset_Resolution_Standards]]"
  - "[[Asset_Format_Specifications]"
used_by:
  - "[Batch_Generation_Workflow]]"
  - "[[Import_Settings_Validation]"
---

# Atlas Packing Strategy

## Purpose

Combine multiple small textures into larger atlases to reduce draw calls, improve memory locality, and optimize rendering performance. Atlas packing is essential for 2D games and UI-heavy projects.

---

## Atlas Benefits

| Metric | Individual Textures | Atlased Textures | Improvement |
|--------|--------------------|------------------|-------------|
| Draw Calls | 100 | 1 | 99% reduction |
| Texture Swaps | 100 | 1 | 99% reduction |
| Memory Overhead | High | Low | ~20% savings |
| Batch Efficiency | Poor | Excellent | Major |

**Rule**: Any group of 10+ small textures should be atlased.

---

## Atlas Size Standards

| Atlas Type | Size | Max Items | Use Case |
|------------|------|-----------|----------|
| Small | 512x512 | ~64 (64x64) | Icons, small UI |
| Medium | 1024x1024 | ~256 (64x64) | Characters, props |
| Large | 2048x2048 | ~1024 (64x64) | Full sprite sheets |
| Maximum | 4096x4096 | ~4096 (64x64) | Large projects |

**Platform Limits**:
- Mobile: 2048x2048 max
- Web: 2048x2048 max
- PC/Console: 4096x4096 max, 8192x8192 on high-end

---

## Atlas Categories

### UI Atlas

**Contains**: Buttons, frames, icons, cursors, sliders

**Naming**: `atlas_ui_{theme}_{size}.png`
```
atlas_ui_fantasy_1024.png
atlas_ui_scifi_1024.png
```

**Organization**:
```
┌─────────────────────────────────────┐
│  [Button Default] [Button Hover]    │
│  [Button Pressed] [Button Disabled] │
│  [Frame Top-Left] [Frame Top]       │
│  [Frame Top-Right] [Frame Left]     │
│  ...                                │
└─────────────────────────────────────┘
```

### Character Atlas

**Contains**: Character sprites, animations

**Naming**: `atlas_char_{name}_{action}_{size}.png`
```
atlas_char_hero_idle_512.png
atlas_char_hero_run_512.png
```

**Organization**: Grid-based animation frames
```
┌─────────────────────────────────────┐
│ [Frame 0,0] [Frame 0,1] [Frame 0,2] │
│ [Frame 1,0] [Frame 1,1] [Frame 1,2] │
│ [Frame 2,0] [Frame 2,1] [Frame 2,2] │
└─────────────────────────────────────┘
```

### Environment Atlas

**Contains**: Tiles, props, decorations

**Naming**: `atlas_env_{biome}_{size}.png`
```
atlas_env_forest_1024.png
atlas_env_cave_1024.png
```

### Effect Atlas

**Contains**: Particle textures, effect sprites

**Naming**: `atlas_fx_{category}_{size}.png`
```
atlas_fx_explosions_512.png
atlas_fx_magic_512.png
```

---

## Packing Algorithms

### MaxRects (Recommended)

**Best for**: Mixed-size sprites, efficient space usage

**Tools**: TexturePacker, FreeTexPacker, MaxRectsBinPack

**Advantages**:
- High packing efficiency (85-95%)
- Handles mixed sizes well
- Fast packing time

### Grid (Simple)

**Best for**: Uniform-size sprites, animation frames

**Advantages**:
- Simple UV calculation
- Predictable layout
- Easy manual editing

**Disadvantages**:
- Wasted space for mixed sizes
- Less efficient

### Shelf

**Best for**: UI elements, horizontal strips

**Advantages**:
- Good for row-based layouts
- Simple implementation

---

## Padding & Spacing

### Why Padding Matters

Without padding, texture bleeding occurs at edges:
```
┌─────────┐
│ Sprite  │──▶ Bleeding from adjacent texture
└─────────┘
```

### Padding Rules

| Context | Padding | Spacing |
|---------|---------|---------|
| Pixel Art | 0px | 0px |
| Standard 2D | 2px | 2px |
| Mipmapped | 4px | 4px |
| UI (no filter) | 1px | 1px |

**Formula**:
```
total_atlas_size = packed_size + (padding * 2) + (spacing * (count - 1))
```

---

## Atlas Generation Workflow

### Automated Pipeline

```bash
# 1. Collect assets for atlas
mkdir -p temp_atlas_input/
cp ui/buttons/*.png temp_atlas_input/
cp ui/frames/*.png temp_atlas_input/

# 2. Run packer
texturepacker \
  --format json \
  --data atlas_ui.json \
  --sheet atlas_ui.png \
  --max-size 1024 \
  --padding 2 \
  --algorithm MaxRects \
  temp_atlas_input/

# 3. Validate output
python validate_atlas.py atlas_ui.png atlas_ui.json

# 4. Move to assets
cp atlas_ui.png atlas_ui.json ../Assets/UI/
```

### Metadata Format (JSON)

```json
{
  "meta": {
    "image": "atlas_ui.png",
    "size": { "w": 1024, "h": 1024 }
  },
  "frames": {
    "button_default": {
      "frame": { "x": 0, "y": 0, "w": 128, "h": 64 },
      "rotated": false,
      "trimmed": false,
      "sourceSize": { "w": 128, "h": 64 }
    },
    "button_hover": {
      "frame": { "x": 128, "y": 0, "w": 128, "h": 64 },
      "rotated": false,
      "trimmed": false,
      "sourceSize": { "w": 128, "h": 64 }
    }
  }
}
```

---

## Engine Integration

### Unity

**Tools**: Sprite Atlas (built-in), TexturePacker Importer

**Setup**:
1. Create Sprite Atlas asset
2. Add sprites to atlas
3. Enable "Allow Rotation" for better packing
4. Set padding

### Unreal Engine

**Tools**: Paper2D (built-in), TexturePacker plugin

**Setup**:
1. Import sprite sheet
2. Extract sprites
3. Create tile set if needed

### Godot

**Tools**: AtlasTexture (built-in)

**Setup**:
1. Import atlas image
2. Create AtlasTexture resources
3. Define regions

---

## Atlas Optimization Tips

### 1. Group by Context

**Good**: All UI buttons in one atlas
**Bad**: UI buttons mixed with character sprites

### 2. Group by Frequency

**Good**: Frequently used together in same atlas
**Bad**: Rarely used items taking atlas space

### 3. Consider Draw Order

Pack items that render together to minimize atlas switches:
```
Atlas 1: All background elements
Atlas 2: All character sprites
Atlas 3: All UI elements
```

### 4. Leave Room for Growth

Target 80% packing efficiency to allow additions:
```
Current: 80% full
Growth:  20% buffer
```

---

## Validation Checks

```python
def validate_atlas(atlas_image, atlas_metadata):
    """Validate atlas integrity"""
    
    checks = {
        'power_of_two': is_power_of_two(atlas_image.width) and 
                       is_power_of_two(atlas_image.height),
        'within_platform_limits': atlas_image.width <= 2048 and 
                                  atlas_image.height <= 2048,
        'no_overlapping_frames': check_no_overlaps(atlas_metadata),
        'all_frames_within_bounds': check_bounds(atlas_image, atlas_metadata),
        'padding_sufficient': check_padding(atlas_image, atlas_metadata, min_padding=2),
    }
    
    return all(checks.values()), checks
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  ATLAS QUICK REFERENCE                                 │
├────────────────────────────────────────────────────────┤
│  SIZES: 512, 1024, 2048, 4096                          │
│  PADDING: 2px standard, 4px for mipmaps                │
│  ALGORITHM: MaxRects for mixed, Grid for uniform       │
├────────────────────────────────────────────────────────┤
│  NAMING: atlas_{category}_{name}_{size}.png            │
├────────────────────────────────────────────────────────┤
│  RULES:                                                │
│  ✓ Group by context                                    │
│  ✓ Use padding to prevent bleeding                     │
│  ✓ Generate metadata for UV lookup                     │
│  ✓ Validate before import                              │
│  ✓ Leave 20% growth buffer                             │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Asset_Resolution_Standards]] - Atlas size limits
- [[Asset_Format_Specifications]] - Atlas format requirements
- [[Batch_Generation_Workflow]] - Atlas generation step
- [[Import_Settings_Validation]] - Atlas validation
