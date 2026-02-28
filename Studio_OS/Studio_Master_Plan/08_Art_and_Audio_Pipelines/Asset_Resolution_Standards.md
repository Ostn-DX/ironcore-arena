---
title: Asset Resolution Standards
type: rule
layer: enforcement
status: active
tags:
  - art
  - resolution
  - standards
  - optimization
  - performance
depends_on:
  - "[Art_Pipeline_Overview]"
used_by:
  - "[Batch_Generation_Workflow]]"
  - "[[Asset_Format_Specifications]"
---

# Asset Resolution Standards

## Purpose

Define resolution constraints for each asset type to ensure performance, consistency, and memory efficiency. Every pixel has a cost—use only what you need.

---

## Resolution Philosophy

**Minimum Viable Resolution**: Use the smallest resolution that maintains visual clarity at target display size.

**Memory Cost Reference**:
| Resolution | Uncompressed | Compressed (PNG) | VRAM (RGBA) |
|------------|--------------|------------------|-------------|
| 32x32 | 4 KB | ~1 KB | 4 KB |
| 64x64 | 16 KB | ~3 KB | 16 KB |
| 128x128 | 64 KB | ~10 KB | 64 KB |
| 256x256 | 256 KB | ~35 KB | 256 KB |
| 512x512 | 1 MB | ~120 KB | 1 MB |
| 1024x1024 | 4 MB | ~450 KB | 4 MB |
| 2048x2048 | 16 MB | ~1.5 MB | 16 MB |

**Rule**: A 2048x2048 texture uses 4000x more memory than 32x32. Choose wisely.

---

## Standard Resolutions by Asset Type

### Characters

| Asset Type | Resolution | Use Case |
|------------|------------|----------|
| Small Enemy | 32x32 | Basic enemies, projectiles |
| Standard Character | 64x64 | Player character, common NPCs |
| Large Enemy | 128x128 | Bosses, large creatures |
| Giant/Boss | 256x256 | Final bosses, massive entities |

**Animation Frames**: Same resolution per character. No mixing 64x64 and 128x128 frames.

### Environment

| Asset Type | Resolution | Use Case |
|------------|------------|----------|
| Tile/Tileable | 64x64, 128x128 | Ground tiles, repeating patterns |
| Small Prop | 64x64 | Rocks, small plants |
| Medium Prop | 128x128 | Trees, buildings |
| Large Prop | 256x256 | Mountains, large structures |
| Background Layer | 512x512 to 2048x2048 | Parallax backgrounds |

**Parallax Rule**: Background layers can be larger but should be lower detail.

### UI Elements

| Asset Type | Resolution | Use Case |
|------------|------------|----------|
| Small Icon | 16x16, 32x32 | Inventory items, small abilities |
| Medium Icon | 64x64 | Ability icons, equipment |
| Large Icon | 128x128 | Character portraits, large buttons |
| Button/Frame | Variable | Match target display size |
| Full Screen BG | 1920x1080 | Menu backgrounds |

**UI Scaling**: Design at 1x, let engine handle scaling. Don't create 1x, 2x, 3x versions manually.

### Props/Items

| Asset Type | Resolution | Use Case |
|------------|------------|----------|
| Small Item | 32x32 | Coins, small collectibles |
| Standard Item | 64x64 | Weapons, tools |
| Large Item | 128x128 | Two-handed weapons, large objects |

### Effects/VFX

| Asset Type | Resolution | Use Case |
|------------|------------|----------|
| Small Effect | 32x32 | Sparks, small particles |
| Medium Effect | 64x64 | Explosions, medium particles |
| Large Effect | 128x128 | Big explosions, screen-wide effects |

### Textures (3D)

| Asset Type | Resolution | Use Case |
|------------|------------|----------|
| Small Object | 256x256 | Props, small items |
| Medium Object | 512x512 | Characters, weapons |
| Large Object | 1024x1024 | Bosses, large structures |
| Environment | 1024x1024 to 2048x2048 | Terrain, large surfaces |

---

## Resolution Constraints Table

| Asset Category | Min | Standard | Max | Exception Process |
|---------------|-----|----------|-----|-------------------|
| Characters | 32x32 | 64x64 | 256x256 | Technical Lead approval |
| Environment Props | 32x32 | 128x128 | 512x512 | Performance review |
| UI Icons | 16x16 | 64x64 | 128x128 | Design Lead approval |
| UI Backgrounds | 512x512 | 1920x1080 | 3840x2160 | Performance review |
| Effects | 16x16 | 64x64 | 128x128 | Technical Lead approval |
| 3D Textures | 128x128 | 512x512 | 2048x2048 | Performance review |

---

## Power-of-Two Rule

**All textures MUST be power-of-two dimensions**:
- ✅ 16, 32, 64, 128, 256, 512, 1024, 2048
- ❌ 100, 150, 300, 500, 1000

**Why**: GPU texture compression and mipmapping require power-of-two.

**Exception**: UI elements that don't use texture compression can be non-power-of-two (NPOT).

---

## Aspect Ratio Guidelines

| Aspect | Use For | Example |
|--------|---------|---------|
| 1:1 | Icons, character sprites | 64x64 icons |
| 2:1 | Wide backgrounds, landscapes | 2048x1024 parallax |
| 1:2 | Tall backgrounds, towers | 512x1024 tower |
| 4:3 | UI panels, portraits | 256x192 portrait |
| 16:9 | Full-screen backgrounds | 1920x1080 menu |

---

## Multi-Resolution Strategy

### Option 1: Single Resolution + Engine Scaling (Preferred)

Create at target resolution, let engine scale:
- ✅ Simple pipeline
- ✅ Lower asset count
- ⚠️ May lose quality at extreme scales

### Option 2: Resolution Tiers

Create 2-3 versions for different quality settings:
```
char_hero_64.png   # Low quality setting
char_hero_128.png  # Medium quality setting
char_hero_256.png  # High quality setting
```

**When to use**: When target platforms have vastly different capabilities.

---

## Resolution Validation

### Automated Checks
```python
def validate_resolution(filename, width, height):
    """Validate asset resolution against standards"""
    
    # Check power-of-two
    def is_power_of_two(n):
        return n > 0 and (n & (n - 1)) == 0
    
    if not is_power_of_two(width) or not is_power_of_two(height):
        return False, "Resolution must be power-of-two"
    
    # Check against category max
    category = get_category_from_filename(filename)
    max_res = CATEGORY_MAX_RESOLUTIONS.get(category, 1024)
    
    if width > max_res or height > max_res:
        return False, f"Resolution exceeds max for {category}: {max_res}"
    
    return True, "Valid"
```

---

## Performance Budgets

### Per-Scene Limits

| Scene Type | Texture Memory Budget | Max Texture Count |
|------------|----------------------|-------------------|
| Small Level | 64 MB | 100 textures |
| Medium Level | 128 MB | 200 textures |
| Large Level | 256 MB | 400 textures |
| Boss Arena | 512 MB | 500 textures |

**Calculation**:
```
Total Memory = Σ(texture_width × texture_height × 4 bytes)
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  RESOLUTION QUICK REFERENCE                            │
├────────────────────────────────────────────────────────┤
│  Characters:    64x64 (std), 32x32 (small), 128x128    │
│  Environment:   128x128 (std), 512x512 (bg)            │
│  UI Icons:      64x64 (std), 32x32 (small)             │
│  UI Background: 1920x1080 (std)                        │
│  Effects:       64x64 (std), 32x32 (small)             │
│  3D Textures:   512x512 (std), 1024x1024 (high)        │
├────────────────────────────────────────────────────────┤
│  RULES:                                                │
│  ✓ Power-of-two only                                   │
│  ✓ Use minimum viable resolution                       │
│  ✓ Consistent within asset type                        │
│  ✓ Consider memory budget                              │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Batch_Generation_Workflow]] - Uses resolution standards
- [[Asset_Format_Specifications]] - Format constraints
- [[Atlas_Packing_Strategy]] - Atlas resolution planning
- [[Import_Settings_Validation]] - Resolution validation on import
