# Visual Design Blueprint - Implementation Notes
## Ironcore Arena Art Style V2

---

## Style Summary

**Name:** Retro-Vector Mechanical Minimalism  
**Core:** Clarity > Detail, Function > Decoration  
**Feel:** Toy-like tactility, mechanical precision, arcade responsiveness

---

## Key Rules Implemented

### Shapes
- ✅ Circular or rounded geometry only
- ✅ No sharp corners
- ✅ Bold silhouettes readable at 25% scale

### Colors (Max 6 per asset)
1. Base color (mechanical tone)
2. Soft radial highlight (upper left)
3. Shadow gradient (lower right)
4. Panel line (darker version of base)
5. Accent detail (center sensor)
6. Optional: Saturated element for projectiles

### Lighting
- Single global light: **upper left**
- Shadow direction: **lower right**
- Soft highlights, not specular
- No multi-light setups

### Outlines
- Darker version of base color
- **Never pure black**
- Uniform thickness

### Animation Curves
- Linear motion (constant speed)
- Short ease-out only
- No elastic bounce
- Fast start, short settle

---

## Color Meanings

| Color | Meaning | Use |
|-------|---------|-----|
| **Green** | Friendly | Player units |
| **Yellow** | Attack | Enemy units, projectiles |
| **Blue** | Heavy/Defense | Defense chassis |
| **Purple** | Elite | Special/rare units |
| **Grey** | Neutral | Obstacles, debris |
| **Orange** | Saturated | Projectile glow |

---

## Visual Priority Stack

1. **Projectiles** (brightest, most visible)
2. **Units** (clear silhouettes)
3. **Health bars** (high contrast neon)
4. **Selection indicators**
5. **Terrain** (low contrast)
6. **Background** (non-competing)

---

## Sprite Specifications

### Chassis
| Type | Size | Shape | Team Colors |
|------|------|-------|-------------|
| Scout | 40×40 | Rounded diamond | Green/Yellow |
| Fighter | 48×48 | Circle | Green/Yellow |
| Tank | 56×56 | Rounded square | Green/Yellow |

### Weapons
| Type | Size | Barrel | Visual |
|------|------|--------|--------|
| Machine Gun | 32×32 | Short | Boxy, fast |
| Cannon | 32×32 | Thick | Heavy, slow |
| Launcher | 32×32 | Tubular | Rounded opening |
| Beam | 32×32 | Straight line | Energy glow |
| Sniper | 32×32 | Long thin | Scoped |

---

## Animation Specs

| Action | Timing | Curve | Notes |
|--------|--------|-------|-------|
| Movement | 200ms | Linear | Constant speed |
| Turret rotate | 150ms | Ease-out | Fast snap |
| Shoot recoil | 100ms | Linear | Brief, sharp |
| Spawn | 200ms | Ease-out | Scale 80%→100% |
| Death | 300ms | Linear | Fade + flash |
| Idle | 2000ms | Sine | Pulse ≤2% scale |

---

## Implementation

### Generator Tool
`src/tools/sprite_generator_v2.gd`

Generates:
- 3 chassis types × 2 teams = 6 sprites
- 5 weapon types = 5 sprites
- Total: 11 MVP sprites

### Usage
```gdscript
var gen = SpriteGeneratorV2.new()
gen.generate_all_sprites()
; Saves to assets/sprites/v2/
```

---

## File Naming

```
assets/sprites/v2/
├── chassis_scout_player.png
├── chassis_scout_enemy.png
├── chassis_fighter_player.png
├── chassis_fighter_enemy.png
├── chassis_tank_player.png
├── chassis_tank_enemy.png
├── weapon_machine_gun.png
├── weapon_cannon.png
├── weapon_launcher.png
├── weapon_beam.png
└── weapon_sniper.png
```

---

## Differences from Outhold Style

| Aspect | Outhold | Blueprint V2 |
|--------|---------|--------------|
| Background | Dark navy | Warm earthy |
| Shapes | Square cards | Rounded mechanical |
| Lighting | Flat | Single source |
| Outlines | None | Darker base color |
| Animation | Smooth tween | Linear mechanical |
| Feel | Clean UI | Toy/arcade |

---

## Next Steps

1. [ ] Run SpriteGeneratorV2 (creates 11 PNGs)
2. [ ] Update TilesetGenerator to match warm earthy backgrounds
3. [ ] Create animation test scene
4. [ ] Implement health bars (neon, floating)
5. [ ] Add projectile glow effects

---

## References

- **Inspiration:** Wii Tanks + Vector arcade games
- **Colors:** Warm backgrounds, muted units, saturated attacks
- **Motion:** Mechanical, precise, responsive
- **Priority:** Readability at all scales

---

**Version:** 2.0  
**Date:** 2026-02-20  
**Status:** Ready for generation
