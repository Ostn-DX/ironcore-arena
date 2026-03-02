---
title: Art Direction Intake Format
type: template
layer: design
status: active
tags:
  - art
  - direction
  - intake
  - template
  - style-guide
depends_on:
  - "[Art_Pipeline_Overview]"
used_by:
  - "[Style_Lock_Approval_Process]]"
  - "[[Prompt_Architecture_Templates]]"
  - "[[Batch_Generation_Workflow]"
---

# Art Direction Intake Format

## Purpose

Standardized intake form that transforms vague creative direction into machine-actionable generation parameters. Every art request must complete this format before entering the pipeline.

---

## Intake Form Template

### 1. Asset Classification

```yaml
asset_type: [character | environment | prop | UI | effect | icon]
quantity_needed: [number]
priority: [blocker | high | medium | low]
deadline: [YYYY-MM-DD]
```

### 2. Visual Style Definition

**Base Style Selection** (pick one):
- [ ] Pixel Art (16x16, 32x32, 64x64)
- [ ] Low Poly 3D
- [ ] Hand-Drawn 2D
- [ ] Vector Flat
- [ ] Photorealistic
- [ ] Stylized Realistic
- [ ] Anime/Cartoon
- [ ] Other: ___________

**Reference Links** (minimum 3 required):
- Moodboard URL: ___________
- Style reference image: ___________
- Existing in-game reference: ___________

### 3. Technical Constraints

```yaml
resolution: [64x64 | 128x128 | 256x256 | 512x512 | 1024x1024 | 2048x2048]
color_palette: [monochrome | limited (specify) | full]
background: [transparent | solid color | environmental]
animation: [static | 2-frame | 4-frame | 8-frame | full]
format: [PNG | JPG | SVG | PSD]
```

### 4. Content Description

**Subject**: What is being depicted?
```
[Detailed description of the asset content]
```

**Mood/Atmosphere**:
- [ ] Cheerful  - [ ] Dark/Moody  - [ ] Mysterious  - [ ] Action/Intense
- [ ] Calm      - [ ] Horror      - [ ] Whimsical   - [ ] Epic

**Lighting**:
- [ ] Daylight  - [ ] Night       - [ ] Interior    - [ ] Dramatic
- [ ] Flat      - [ ] Backlit     - [ ] Side-lit    - [ ] Ambient

### 5. Composition Requirements

```yaml
framing: [close-up | medium | wide | establishing]
angle: [front | side | three-quarter | top-down | isometric]
focal_point: [center | rule-of-thirds | golden-ratio]
negative_space: [minimal | moderate | generous]
```

### 6. Style Lock Parameters

**Approved Base Model**: ___________
**Approved LoRA**: ___________
**Seed Range**: ___________ to ___________
**CFG Scale**: ___________
**Sampling Steps**: ___________

### 7. Must-Include Elements

```
[List specific visual elements that MUST appear]
```

### 8. Must-Exclude Elements (Negative Prompt Base)

```
[List specific visual elements that MUST NOT appear]
```

### 9. Consistency Requirements

**Must match existing asset**: [ID or name]
**Color hex codes**: ___________
**Style variance tolerance**: [strict | moderate | flexible]

### 10. Approval Chain

```yaml
requester: [name]
art_lead_approval: [pending | approved | rejected]
technical_lead_approval: [pending | approved | rejected]
approval_date: [YYYY-MM-DD]
```

---

## Example Completed Form

```yaml
# Forest Enemy - Shadow Stalker
asset_type: character
quantity_needed: 8
priority: high
deadline: 2024-03-15

base_style: Pixel Art
resolution: 64x64
animation: 4-frame

subject: "A shadowy forest creature with glowing eyes, hunched posture, elongated limbs"
mood: Dark/Moody
lighting: Night

framing: medium
angle: side

base_model: "pixel-art-xl-v1"
lora: "forest-creatures-lora-v2"
cfg_scale: 7
steps: 25

must_include: [glowing eyes, shadow aura, clawed hands]
must_exclude: [bright colors, human features, weapons, background elements]

color_palette: limited
primary: "#1a1a2e"
accent: "#e94560"

requester: "Design Team"
approval_status: approved
```

---

## Automation Integration

This form feeds directly into:

1. **Prompt Generator**: Converts content description + must-include into positive prompt
2. **Negative Prompt Builder**: Combines must-exclude with base negative prompt
3. **Batch Config**: Resolution, quantity, and technical settings auto-configure generation job
4. **Validation Rules**: Format and constraints become automated check criteria

---

## Quick Reference: Style Keywords

| Style | Model | Key Prompt Terms |
|-------|-------|------------------|
| Pixel Art | pixel-art-xl | pixel art, 16-bit, dithering, limited palette |
| Low Poly | anything-v5 | low poly, flat shading, geometric, game asset |
| Hand-Drawn | dreamshaper | hand drawn, sketch, ink, watercolor, painterly |
| Vector Flat | flat-2d-xl | flat design, vector art, minimal, solid colors |
| Anime | meinamix | anime style, cel shaded, vibrant colors, clean lines |

---

## Related Systems

- [[Style_Lock_Approval_Process]] - Form triggers style lock workflow
- [[Prompt_Architecture_Templates]] - Form data populates prompt templates
- [[Asset_Resolution_Standards]] - Resolution field validates against standards
