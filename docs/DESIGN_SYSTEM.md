# IRONCORE ARENA - DESIGN SYSTEM
## Visual Style Guide v1.0

---

## Design Philosophy

**"Clean Flat Tech"**
- Flat geometric shapes with subtle depth
- Long shadows for visual interest
- Bold, limited color palette
- High contrast for readability
- Consistent 8px grid system

**Inspiration:** Outhold's node network + Wii Tanks toy aesthetic + modern flat UI

---

## Color Palette

### Primary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Navy Dark** | `#0F1419` | 15, 20, 25 | Main background |
| **Navy** | `#1A1F2E` | 26, 31, 46 | Panels, cards |
| **Navy Light** | `#252B3D` | 37, 43, 61 | Elevated surfaces |
| **Slate** | `#3D4554` | 61, 69, 84 | Borders, dividers |

### Accent Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Cyan** | `#00D4FF` | 0, 212, 255 | Primary accent, selected |
| **Cyan Glow** | `#80EAFF` | 128, 234, 255 | Highlights |
| **Orange** | `#FF6B35` | 255, 107, 53 | Warnings, attack |
| **Green** | `#2ECC71` | 46, 204, 113 | Success, player team |
| **Red** | `#E74C3C` | 231, 76, 60 | Danger, enemy team |
| **Yellow** | `#F1C40F` | 241, 196, 15 | Special, elite |
| **Purple** | `#9B59B6` | 155, 89, 182 | Rare/unique items |

### Tier Colors (for progression)

| Tier | Color | Hex | Use |
|------|-------|-----|-----|
| 1 | Gray | `#95A5A6` | Starter equipment |
| 2 | Cyan | `#00D4FF` | Standard equipment |
| 3 | Orange | `#FF6B35` | Advanced equipment |
| 4 | Purple | `#9B59B6` | Elite equipment |

### Functional Colors

| Purpose | Color | Hex |
|---------|-------|-----|
| Text Primary | White | `#FFFFFF` |
| Text Secondary | Light Gray | `#B0B8C4` |
| Text Muted | Gray | `#6B7280` |
| Shadow | Black 25% | `rgba(0,0,0,0.25)` |
| Overlay | Black 50% | `rgba(0,0,0,0.5)` |

---

## Typography

### Font Family
- **Primary:** Inter (Google Fonts)
- **Monospace:** JetBrains Mono (for numbers/stats)
- **Fallback:** System sans-serif

### Type Scale

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| **Hero** | 48px | Bold (700) | Title screen |
| **H1** | 32px | Bold (700) | Screen titles |
| **H2** | 24px | Semi-bold (600) | Section headers |
| **H3** | 18px | Semi-bold (600) | Card titles |
| **Body** | 16px | Regular (400) | General text |
| **Small** | 14px | Regular (400) | Descriptions |
| **Tiny** | 12px | Medium (500) | Labels, stats |

### Typography Rules
- Line height: 1.5x font size
- Max line length: 45-75 characters
- All caps for button labels (tracking: +0.05em)
- Left-aligned text (except center in cards)

---

## Spacing System

### Base Unit: 8px

| Token | Value | Use |
|-------|-------|-----|
| `xs` | 4px | Tight spacing |
| `sm` | 8px | Standard padding |
| `md` | 16px | Card padding |
| `lg` | 24px | Section gaps |
| `xl` | 32px | Major sections |
| `2xl` | 48px | Screen padding |

### Grid
- 8px base grid
- Components align to grid
- Margins in multiples of 8px

---

## Shadows

### Long Shadow Style
```css
/* Standard card shadow */
offset-x: 6px
offset-y: 6px
blur: 0px (sharp shadow)
color: rgba(0, 0, 0, 0.25)

/* Elevated (hover) */
offset-x: 8px
offset-y: 8px
color: rgba(0, 0, 0, 0.2)

/* Pressed */
offset-x: 0px
offset-y: 0px
color: rgba(0, 0, 0, 0)
```

### Implementation
- Shadows are separate nodes behind content
- Use ColorRect or duplicate sprite
- Animate on hover/press

---

## Components

### Cards

**Standard Card**
- Background: `#252B3D`
- Border radius: 8px
- Padding: 16px
- Shadow: 6px offset

**Elevated Card (hover)**
- Background: `#2D3548` (lighter)
- Shadow: 8px offset
- Slight scale: 1.02x

**Selected Card**
- Border: 2px solid `#00D4FF`
- Glow effect (optional)

### Buttons

**Primary Button**
- Background: `#00D4FF`
- Text: `#0F1419` (dark on light)
- Padding: 12px 24px
- Border radius: 8px
- Shadow: 4px offset
- Hover: Lighten 10%
- Press: Remove shadow, darken

**Secondary Button**
- Background: `#252B3D`
- Text: `#FFFFFF`
- Border: 1px solid `#3D4554`

**Ghost Button**
- Background: transparent
- Text: `#00D4FF`
- Border: 1px solid `#00D4FF`

**Danger Button**
- Background: `#E74C3C`
- Text: `#FFFFFF`

### Icons

- Size: 24px (standard), 16px (small)
- Style: Line icons, 2px stroke
- Color: Inherit from text
- Source: Phosphor Icons or Feather Icons

---

## Game Elements

### Bot Design

**Chassis Types**
1. **Scout (Light)** - 40x40px, rounded square
2. **Fighter (Medium)** - 48x48px, rounded rectangle
3. **Tank (Heavy)** - 56x56px, boxy square

**Visual Elements**
- Flat color fill (tier color)
- 2px darker border
- White detail lines (tech details)
- Center sensor (glowing dot)
- Independent rotating turret
- 6-8px long shadow

**Team Colors**
- Player: Cyan `#00D4FF` tint
- Enemy: Red `#E74C3C` tint
- Neutral: Gray `#95A5A6`

### Arena Design

**Background**
- Base: `#0F1419` (navy dark)
- Grid: `#1A1F2E` dots at 40px spacing
- Vignette: Darker at edges

**Floor**
- Color: Varies by theme
- Pattern: Subtle grid or dot pattern

**Walls/Obstacles**
- 3/4 perspective (3 visible faces)
- Top face: Lightest
- Front face: Theme color
- Side face: Darker shade
- 6px shadow offset

### Arena Themes

| Arena | Floor | Walls | Accent |
|-------|-------|-------|--------|
| **Training** | `#1A1F2E` | `#3D4554` | Cyan |
| **Scrapyard** | `#2D241E` | `#5C4B3A` | Orange |
| **Minefield** | `#1E242D` | `#2D3A4D` | Red |
| **Chrometek** | `#0D1A1E` | `#00D4FF` | Cyan |

---

## Animation

### Timing
- **Fast:** 150ms (micro-interactions)
- **Normal:** 300ms (standard transitions)
- **Slow:** 500ms (emphasis, screen transitions)

### Easing
- **Standard:** `ease-out` (deceleration)
- **Enter:** `ease-out-back` (slight overshoot)
- **Exit:** `ease-in` (acceleration)

### Common Animations

**Hover**
- Scale: 1.0 → 1.02
- Shadow: 6px → 8px
- Duration: 150ms

**Press**
- Scale: 1.02 → 0.98
- Shadow: 8px → 0px
- Duration: 100ms

**Appear**
- Opacity: 0 → 1
- Scale: 0.95 → 1.0
- Duration: 300ms

**Destroy (bot)**
- Flash white
- Scale up 1.2x
- Fade to smoke
- Duration: 500ms

---

## Layout

### Screen Structure
```
┌─────────────────────────────────┐
│  Header (64px)                  │
│  [Logo]       [Currency] [Menu] │
├─────────────────────────────────┤
│                                 │
│  Content Area                   │
│  (centered, max 1200px)         │
│                                 │
├─────────────────────────────────┤
│  Footer (optional)              │
└─────────────────────────────────┘
```

### Safe Area
- Keep UI within 8% margin on all sides
- Critical info: top-left corner
- Actions: bottom-right or centered

---

## Accessibility

### Contrast
- Minimum 4.5:1 for normal text
- Minimum 3:1 for large text/UI
- Use white text on dark backgrounds

### Interaction
- Minimum touch target: 44x44px
- Focus states for keyboard navigation
- Don't rely on color alone (icons + text)

### Motion
- Respect `prefers-reduced-motion`
- Keep animations under 500ms
- Provide instant alternatives

---

## File Organization

```
assets/
├── fonts/
│   ├── Inter-Bold.ttf
│   ├── Inter-SemiBold.ttf
│   └── Inter-Regular.ttf
├── sprites/
│   ├── chassis/
│   ├── weapons/
│   ├── effects/
│   └── ui/
├── tilesets/
│   ├── arena_training.png
│   ├── arena_scrapyard.png
│   └── ...
└── audio/
    ├── sfx/
    └── music/
```

---

## Implementation Notes

### Godot Settings
```
Project Settings:
  Rendering > Textures > Canvas Textures: Nearest
  Rendering > 2D > Snap 2D Vertices to Pixel: ON
  Display > Window > Stretch: canvas_items
```

### Shaders
- Use for glow effects (selected items)
- Use for screen transitions
- Keep simple for performance

### Performance
- Use Texture atlases
- Limit real-time shadows
- Pool particle effects
- Use object culling

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-20 | Initial design system |

---

## Quick Reference Card

```
BACKGROUND:  #0F1419
PANEL:       #1A1F2E
CARD:        #252B3D
BORDER:      #3D4554

ACCENT:      #00D4FF
SUCCESS:     #2ECC71
WARNING:     #FF6B35
DANGER:      #E74C3C

TEXT:        #FFFFFF
TEXT DIM:    #B0B8C4

SHADOW:      6px offset, 25% black
RADIUS:      8px corners
SPACING:     8px base grid
```
