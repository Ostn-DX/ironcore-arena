---
title: Art_Direction_Intake_Template
type: template
layer: execution
status: active
tags:
  - art
  - template
  - intake
  - pipeline
depends_on: []
used_by:
  - "[Batch_Generation_Workflow]"
---

# Art Direction Intake Template

## Purpose
Standardized brief for art generation. Ensures consistent output from any model.

## Copy/Paste Block

```markdown
## Asset Request

### Metadata
- **Type:** [sprite/tileset/ui/icon]
- **ID:** [unique_identifier]
- **Tier:** [1/2/3/4]
- **Priority:** [critical/high/medium/low]

### Visual Description
- **Subject:** [What is depicted]
- **Style:** [Clean Flat Tech / detailed / pixel art]
- **Colors:** [Primary + 2 accents from palette]
- **Size:** [WxH in pixels]
- **Perspective:** [top-down/side/3-4 view]

### Technical Specs
- **Format:** PNG
- **Transparent:** [Yes/No]
- **Animation:** [Static/4-frame/8-frame]
- **Sprite sheet:** [Yes, layout / No]

### References
- **Similar to:** [existing asset ID]
- **Inspiration:** [game/image reference]
- **Avoid:** [specific elements to exclude]

### Prompt Architecture
```
[Style] [Subject] [Details] [Colors] [Technical]

Example:
"Clean flat tech style heavy tank chassis, 
boxy rectangular shape with angular armor plates,
primary color #00D4FF cyan with #1A1F2E navy accents,
56x56 pixels, top-down perspective, transparent background,
sharp long shadow 6px offset, minimal detail"
```

### Approval Criteria
- [ ] Matches style guide
- [ ] Correct dimensions
- [ ] Transparent where needed
- [ ] Color palette compliant
- [ ] Long shadow present
```

## Prompt Engineering Rules

### Required Elements
1. **Style declaration** - Always first
2. **Subject clarity** - Unambiguous object
3. **Color specification** - Hex codes preferred
4. **Technical details** - Size, format, transparency
5. **Shadow direction** - Consistent 6px offset

### Forbidden Elements
- ❌ "Beautiful" (subjective)
- ❌ "High quality" (assumed)
- ❌ Vague sizes ("large", "small")
- ❌ Ambiguous colors ("blue" vs "#00D4FF")

### Batch Variations
```markdown
## Batch: Chassis Tier 2

Base: "Clean flat tech style [chassis_type] chassis"
Variants:
1. ["scout", "sleek rounded", "18kg", "40x40px"]
2. ["fighter", "balanced angular", "35kg", "48x48px"]
3. ["tank", "boxy heavy", "50kg", "56x56px"]

Color progression:
- All: Primary #00D4FF
- Scout: Accent #80EAFF (light)
- Fighter: Accent #FF6B35 (orange)
- Tank: Accent #9B59B6 (purple)
```

## Validation Checklist

Before submitting for generation:
- [ ] All hex colors from approved palette
- [ ] Dimensions match grid system (multiples of 8)
- [ ] Transparent specified for sprites
- [ ] Shadow direction consistent
- [ ] ID follows naming convention

## Cost Estimation

| Asset Type | Model | Est. Cost | Avg Time |
|------------|-------|-----------|----------|
| Single sprite | DALL-E 3 | $0.04 | 10s |
| Sprite batch (10) | DALL-E 3 | $0.40 | 2min |
| Tileset | DALL-E 3 | $0.08 | 20s |
| UI element | SDXL | $0.02 | 5s |

## Related
[[Prompt_Architecture_Standard]]
[[Asset_Naming_and_Import_Rules]]
[[Batch_Generation_Workflow]]
