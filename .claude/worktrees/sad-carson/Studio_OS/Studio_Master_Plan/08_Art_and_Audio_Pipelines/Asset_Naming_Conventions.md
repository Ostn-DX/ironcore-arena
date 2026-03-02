---
title: Asset Naming Conventions
type: rule
layer: enforcement
status: active
tags:
  - art
  - naming
  - conventions
  - organization
  - standards
depends_on:
  - "[Art_Pipeline_Overview]"
used_by:
  - "[Batch_Generation_Workflow]]"
  - "[[Import_Settings_Validation]"
---

# Asset Naming Conventions

## Purpose

Consistent naming enables automated processing, searchability, and prevents asset chaos. All art assets MUST follow these conventions.

---

## Universal Naming Rules

### Format
```
{category}_{type}_{descriptor}_{variant}_{state}.{extension}
```

### Rules
- ✅ Use **lowercase only**
- ✅ Use **underscores** as separators
- ✅ Use **no spaces**
- ✅ Use **descriptive** but concise names
- ✅ Include **version** if iterating
- ❌ No special characters except underscore
- ❌ No redundant words ("the", "a", "an")

---

## Category Prefixes

| Prefix | Category | Example |
|--------|----------|---------|
| `char_` | Characters | `char_hero_idle_v1.png` |
| `env_` | Environments | `env_forest_bg_day.png` |
| `prop_` | Props/Items | `prop_sword_iron_basic.png` |
| `ui_` | UI Elements | `ui_button_primary_hover.png` |
| `fx_` | Effects/VFX | `fx_explosion_fire_large.png` |
| `icon_` | Icons | `icon_ability_heal.png` |
| `tex_` | Textures | `tex_wood_oak_diffuse.png` |
| `spr_` | Sprites | `spr_coin_spin_01.png` |

---

## Type Suffixes

### Character Types
```
char_{name}_{action}_{direction}_{frame}
char_hero_idle_front_01.png
char_enemy_goblin_run_left_03.png
char_boss_dragon_attack_01.png
```

### Environment Types
```
env_{biome}_{element}_{time}_{layer}
env_forest_tree_pine_day_fg.png
env_cave_wall_stalactite_dark_bg.png
env_city_building_tower_night_sky.png
```

### Prop Types
```
prop_{category}_{item}_{material}_{state}
prop_weapon_sword_steel_equipped.png
prop_consumable_potion_red_full.png
prop_key_golden_ancient_unused.png
```

### UI Types
```
ui_{element}_{style}_{state}
ui_button_primary_default.png
ui_button_primary_hover.png
ui_button_primary_pressed.png
ui_frame_panel_wood_border.png
ui_bar_health_empty.png
ui_bar_health_fill.png
```

### Effect Types
```
fx_{type}_{element}_{size}_{frame}
fx_hit_spark_small_01.png
fx_explosion_fire_medium_04.png
fx_buff_heal_glow_loop.png
```

### Icon Types
```
icon_{category}_{item}_{size}
icon_ability_fireball_64.png
icon_item_potion_health_32.png
icon_resource_wood_oak_16.png
```

---

## Animation Frame Naming

### Sequential Frames
```
char_hero_run_01.png
char_hero_run_02.png
char_hero_run_03.png
...
char_hero_run_08.png
```

### Directional Frames
```
char_hero_idle_front_01.png
char_hero_idle_back_01.png
char_hero_idle_left_01.png
char_hero_idle_right_01.png
```

### State Variants
```
prop_door_wood_closed.png
prop_door_wood_open.png
prop_door_wood_damaged.png
prop_door_wood_broken.png
```

---

## Texture Map Suffixes

| Suffix | Map Type | Example |
|--------|----------|---------|
| `_diff` | Diffuse/Albedo | `tex_metal_iron_diff.png` |
| `_norm` | Normal | `tex_metal_iron_norm.png` |
| `_spec` | Specular | `tex_metal_iron_spec.png` |
| `_rough` | Roughness | `tex_metal_iron_rough.png` |
| `_metal` | Metallic | `tex_metal_iron_metal.png` |
| `_ao` | Ambient Occlusion | `tex_metal_iron_ao.png` |
| `_emit` | Emission | `tex_metal_iron_emit.png` |
| `_height` | Height/Displacement | `tex_metal_iron_height.png` |

---

## Resolution Indicators

Include resolution in name when multiple sizes exist:

```
icon_ability_fireball_16.png
icon_ability_fireball_32.png
icon_ability_fireball_64.png
icon_ability_fireball_128.png
```

---

## Version Control

For work-in-progress or iterations:

```
char_hero_concept_v1.png
char_hero_concept_v2.png
char_hero_concept_v3.png
char_hero_final.png  # Approved version drops version number
```

---

## Folder Structure

```
Assets/
├── Characters/
│   ├── Heroes/
│   │   ├── char_hero_idle_01.png
│   │   └── char_hero_run_01.png
│   └── Enemies/
│       ├── char_enemy_slime_idle_01.png
│       └── char_enemy_slime_run_01.png
├── Environments/
│   ├── Forest/
│   │   ├── env_forest_tree_01.png
│   │   └── env_forest_ground_01.png
│   └── Cave/
│       └── env_cave_wall_01.png
├── Props/
│   ├── Weapons/
│   │   └── prop_weapon_sword_01.png
│   └── Items/
│       └── prop_item_potion_01.png
├── UI/
│   ├── Buttons/
│   │   └── ui_button_primary_*.png
│   └── Icons/
│       └── icon_ability_*.png
└── Effects/
    └── fx_explosion_*.png
```

---

## Automated Enforcement

### Validation Script
```python
def validate_asset_name(filename):
    """Returns (is_valid, error_message)"""
    
    # Check lowercase
    if filename != filename.lower():
        return False, "Must be lowercase"
    
    # Check no spaces
    if ' ' in filename:
        return False, "No spaces allowed"
    
    # Check valid prefix
    valid_prefixes = ['char_', 'env_', 'prop_', 'ui_', 'fx_', 'icon_', 'tex_', 'spr_']
    if not any(filename.startswith(p) for p in valid_prefixes):
        return False, f"Must start with valid prefix: {valid_prefixes}"
    
    # Check extension
    valid_extensions = ['.png', '.jpg', '.svg', '.psd', '.tga']
    if not any(filename.endswith(e) for e in valid_extensions):
        return False, f"Invalid extension"
    
    return True, "Valid"
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│  ASSET NAMING CHEAT SHEET                               │
├─────────────────────────────────────────────────────────┤
│  Format: {category}_{type}_{descriptor}_{variant}       │
├─────────────────────────────────────────────────────────┤
│  Categories:                                            │
│  • char_ = Characters                                   │
│  • env_  = Environments                                 │
│  • prop_ = Props/Items                                  │
│  • ui_   = UI Elements                                  │
│  • fx_   = Effects                                      │
│  • icon_ = Icons                                        │
│  • tex_  = Textures                                     │
│  • spr_  = Sprites                                      │
├─────────────────────────────────────────────────────────┤
│  Rules:                                                 │
│  ✓ lowercase only                                       │
│  ✓ underscores for spaces                               │
│  ✓ no special characters                                │
│  ✓ descriptive but concise                              │
└─────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Batch_Generation_Workflow]] - Uses naming for organization
- [[Import_Settings_Validation]] - Validates naming on import
- [[Atlas_Packing_Strategy]] - Uses naming for atlas grouping
