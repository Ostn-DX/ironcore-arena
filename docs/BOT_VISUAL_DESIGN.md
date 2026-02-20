# Ironcore Arena - Bot Visual Design
## Outhold-Inspired Flat Design

---

## Design Philosophy

**"Geometric nodes with depth"**
- Flat 2D sprites with 3D-esque long shadows
- Clean geometric shapes (circles, rounded rectangles)
- Bold accent colors per tier
- White line details for "tech" feel
- Consistent 48x48px base size

---

## Color Tiers (Exact Hex)

| Tier | Name | Primary | Shadow | Accent Light | Use Case |
|------|------|---------|--------|--------------|----------|
| 1 | Starter | `#2D3548` | `#1A1F2E` | `#4A5568` | Light bots |
| 2 | Standard | `#00D4FF` | `#006B7F` | `#80EAFF` | Balanced |
| 3 | Advanced | `#FFA530` | `#BF7C24` | `#FFD699` | Heavy |
| 4 | Elite | `#9B5DE5` | `#5C3689` | `#CFAEFF` | Special |

---

## Chassis Types

### Type 1: Scout (Light)
```
Size: 40x40px
Shape: Rounded square (radius: 8px)

Visual:
  [########]  ← Main color fill
  [#......#]  ← 4px internal margin
  [..####..]  ← Central sensor (white square 16x16)
  [..#..#..]  ← Two small "eyes"
  [########]

Shadow: 6px offset, 25% black
Details: Small antenna on top (2px line + 4px circle)
```

### Type 2: Fighter (Medium)
```
Size: 48x48px
Shape: Rounded rectangle (radius: 6px)

Visual:
  [##############]
  [#............#]
  [#..########..#]  ← Turret base (32x32 circle)
  [#..#......#..#]
  [#..########..#]
  [#............#]
  [##############]

Shadow: 6px offset
Details: Side vents (2px rectangles), tread marks
```

### Type 3: Tank (Heavy)
```
Size: 56x56px
Shape: Rounded square (radius: 4px, more boxy)

Visual:
  [################]
  [##............##]
  [##..########..##]  ← Thick armor look
  [##..#......#..##]
  [##..#......#..##]
  [##..########..##]
  [##............##]
  [################]

Shadow: 8px offset (heavier shadow for mass)
Details: Corner armor plates, central red sensor
```

---

## Weapon Mounts

Weapons attach to chassis center and rotate independently.

### Weapon Sprite Sizes
- **Light**: 8x24px (machine guns)
- **Medium**: 12x32px (cannons)
- **Heavy**: 16x40px (launchers)

### Barrel Design
```
  [====]  ← Base (attaches to turret)
    ||
    ||    ← Barrel (2-4px thick)
    ||
   [##]   ← Muzzle brake (wider)
```

Color: Darker shade of chassis color

---

## Animation Frames

### Idle (1 frame)
- Static sprite
- Subtle glow pulse on sensor (shader)

### Moving (2 frames)
```
Frame 1: Normal position
Frame 2: Slight chassis tilt (2px offset)
Loop: 0.2s per frame
```

### Shooting (3 frames)
```
Frame 1: Normal
Frame 2: Recoil (barrel back 2px, muzzle flash)
Frame 3: Recovery (barrel forward 1px)
Duration: 0.1s total
```

### Destroyed (4 frames)
```
Frame 1: Normal with red overlay
Frame 2: Tilted 15°, smoke particles
Frame 3: Tilted 45°, more smoke
Frame 4: Flat on ground, blackened
Duration: 0.5s, then remove
```

---

## Shadow System

Every bot has TWO shadow elements:

### 1. Ground Shadow (separate sprite)
```
Offset: (6, 6) from chassis
Color: rgba(0, 0, 0, 0.25)
Size: Same as chassis
Shape: Matches chassis shape

Godot implementation:
  var shadow = Sprite2D.new()
  shadow.texture = shadow_texture
  shadow.position = Vector2(6, 6)
  shadow.modulate.a = 0.25
  shadow.z_index = -1
```

### 2. Press Shadow (when selected)
```
On click: Shadow moves to (0, 0), opacity 0
Release: Shadow returns to (6, 6), opacity 0.25
Duration: 0.1s tween
```

---

## Team Differentiation

### Player Team (Blue tint)
```
Method: Modulate sprite color
Normal: Color(0.3, 0.8, 1.0)  // Cyan-blue
Selected: Color(0.5, 0.9, 1.0) // Brighter + glow
```

### Enemy Team (Red tint)
```
Normal: Color(1.0, 0.3, 0.3)  // Red
Elite: Color(1.0, 0.5, 0.0)   // Orange for bosses
```

### Neutral/Gray
```
Color: Color(0.6, 0.6, 0.6)  // Gray
Use: Obstacles, practice dummies
```

---

## Implementation in Godot

### Scene Structure
```
BotVisual (Node2D)
├── Shadow (Sprite2D)       # Long shadow
├── Chassis (Sprite2D)      # Main body
├── Turret (Node2D)         # Rotates independently
│   ├── Base (Sprite2D)     # Turret base
│   └── Barrel (Sprite2D)   # Weapon
└── HPBar (Control)         # Health display
```

### Code Setup
```gdscript
@export var team_color: Color = Color(0.3, 0.8, 1.0)

func _ready():
    $Chassis.modulate = team_color
    $Turret/Base.modulate = team_color.darkened(0.2)
    $Turret/Barrel.modulate = team_color.darkened(0.3)

func set_turret_rotation(angle_degrees: float):
    $Turret.rotation_degrees = angle_degrees
```

---

## Arena Integration

### Depth Sorting
```gdscript
# In Arena scene
$YSort.enabled = true

# Bots sort by Y position automatically
bot.z_as_relative = false
bot.z_index = int(bot.position.y)
```

### Perspective
```
Camera: 15° tilt down
Result: Bots at bottom of screen appear slightly larger
Implementation: Scale based on Y position
  scale = 1.0 + (y / 720) * 0.1  # 0-10% size variation
```

---

## File Naming Convention

```
sprites/
├── chassis/
│   ├── chassis_scout_t1.png
│   ├── chassis_fighter_t1.png
│   └── chassis_tank_t1.png
├── weapons/
│   ├── wpn_mg_t1.png
│   ├── wpn_cannon_t2.png
│   └── wpn_launcher_t3.png
├── effects/
│   ├── muzzle_flash.png
│   ├── explosion_01.png (4 frames)
│   └── shadow_48x48.png
└── ui/
    ├── icon_move.png
    ├── icon_attack.png
    └── icon_follow.png
```

---

## Quick Start Checklist

- [ ] Create 3 chassis sprites (48x48 PNG)
- [ ] Create 3 weapon sprites (8-16x24-40 PNG)
- [ ] Create shadow template (48x48 transparent PNG)
- [ ] Set up Godot SpriteFrames for animations
- [ ] Implement team color modulation
- [ ] Add Y-sort for depth
- [ ] Test with long shadow offset
- [ ] Add selection glow effect

---

## Reference Colors (Godot Code)

```gdscript
const PALETTE = {
    "bg_dark": Color("#1A1F2E"),
    "bg_panel": Color("#252B3D"),
    "bg_card": Color("#2D3548"),
    "accent_cyan": Color("#00D4FF"),
    "accent_orange": Color("#FFA530"),
    "accent_red": Color("#FF5A5A"),
    "accent_purple": Color("#9B5DE5"),
    "accent_green": Color("#06D6A0"),
    "text_white": Color.WHITE,
    "text_dim": Color("#A0AEC0"),
    "shadow": Color(0, 0, 0, 0.25)
}
```
