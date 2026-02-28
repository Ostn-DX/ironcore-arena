---
title: Prompt_Architecture_Standard
type: rule
layer: enforcement
status: active
tags:
  - prompts
  - architecture
  - standard
  - art
depends_on: []
used_by:
  - "[Art_Direction_Intake_Template]"
---

# Prompt Architecture Standard

## Purpose
Consistent prompt structure for all asset generation. Maximizes quality, minimizes iteration.

## Prompt Structure

```
[STYLE] + [SUBJECT] + [DETAILS] + [COLORS] + [TECHNICAL] + [COMPOSITION]
```

### 1. Style (Always First)
```
"Clean flat tech style"
"Pixel art 16-bit style"
"Minimalist vector style"
"Hand-painted watercolor style"
```

### 2. Subject
```
"heavy tank chassis"
"machine gun weapon"
"arena floor tile"
"health bar UI element"
```

### 3. Details
```
"with angular armor plates and exhaust vents"
"with rotating turret and barrel"
"with subtle grid pattern and scuff marks"
"with segmented fill and percentage text"
```

### 4. Colors
```
"primary color #00D4FF cyan with #1A1F2E navy accents"
"monochrome #3D4554 slate with #FFFFFF white highlights"
"gradient from #FF6B35 orange to #E74C3C red"
```

### 5. Technical
```
"56x56 pixels, top-down perspective, transparent background"
"tileable 64x64 pixels, seamless edges"
"long shadow 6px offset at 45 degrees, sharp"
"isometric 3-4 view with 3 visible faces"
```

### 6. Composition (Optional)
```
"centered with 4px margin"
"arranged in 4x4 grid"
"facing right, slight 3-4 angle"
```

## Complete Examples

### Example 1: Bot Chassis
```
Clean flat tech style heavy tank chassis, boxy rectangular 
shape with angular armor plates and glowing sensor eye, 
primary color #00D4FF cyan with #1A1F2E navy accents and 
#80EAFF cyan glow, 56x56 pixels, top-down perspective, 
transparent background, sharp long shadow 6px offset, 
minimal geometric detail
```

### Example 2: Weapon
```
Clean flat tech style machine gun weapon, compact rectangular 
body with rotating barrel and ammo feed, primary color #FF6B35 
orange with #3D4554 slate accents, 32x16 pixels, side profile, 
transparent background, sharp long shadow 6px offset, 
minimal geometric detail
```

### Example 3: UI Element
```
Clean flat tech style health bar UI element, horizontal 
rectangle with rounded corners 8px radius, segmented fill 
with percentage text, background #1A1F2E navy, fill #00D4FF 
cyan, text #FFFFFF white, 200x24 pixels, flat no shadow
```

## Model-Specific Adjustments

### DALL-E 3
- Longer prompts work better
- Include "digital art" for clarity
- Specify "transparent background" explicitly

### Stable Diffusion XL
- Shorter prompts better
- Use keywords heavily
- Negative prompts essential

### Midjourney
- Use parameters (--ar, --style)
- Emojis help with style
- Reference images powerful

## Negative Prompts (SDXL)

```
"photorealistic, 3d render, gradient background, 
blurry, noisy, text, watermark, signature, 
frame, border, complex detail, realistic shadows"
```

## Validation

Prompt must pass checks:
- [ ] Style declaration present
- [ ] Hex colors specified
- [ ] Dimensions included
- [ ] No forbidden words
- [ ] Within token limit (77 for SD)

## Related
[[Art_Direction_Intake_Template]]
[[Asset_Validation_Gates]]
