---
title: Prompt Architecture Templates
type: template
layer: execution
status: active
tags:
  - art
  - prompts
  - templates
  - stable-diffusion
  - generation
depends_on:
  - "[Art_Direction_Intake_Format]]"
  - "[[Style_Lock_Approval_Process]"
used_by:
  - "[Batch_Generation_Workflow]]"
  - "[[Local_Diffusion_Setup]"
---

# Prompt Architecture Templates

## Purpose

Standardized prompt structures that ensure consistent, high-quality generation across all asset types. These templates are designed for **Stable Diffusion/Flux** and enforce the Style Lock parameters.

---

## Core Prompt Structure

```
[STYLE_PREFIX] [SUBJECT] [DETAILS] [QUALITY_BOOSTERS] [STYLE_SUFFIX]
```

### Component Definitions

| Component | Purpose | Example |
|-----------|---------|---------|
| STYLE_PREFIX | Establishes base style | "pixel art, 64x64, game asset" |
| SUBJECT | Main content description | "forest monster with glowing eyes" |
| DETAILS | Specific visual elements | "hunched posture, elongated limbs, shadow aura" |
| QUALITY_BOOSTERS | Generation quality terms | "masterpiece, best quality, highly detailed" |
| STYLE_SUFFIX | Reinforces style constraints | "limited color palette, dithering, no background" |

---

## Asset-Type Templates

### Character Template

```python
CHARACTER_TEMPLATE = """
{style_prefix}, {subject}, game character sprite, 
{appearance}, {clothing}, {expression}, 
{pose}, {lighting}, 
masterpiece, best quality, highly detailed, 
{style_suffix}, transparent background, centered
"""

# Example fill:
# style_prefix = "pixel art, 64x64"
# subject = "forest guardian warrior"
# appearance = "muscular build, green skin, bark-like armor"
# clothing = "leaf cape, vine belt"
# expression = "determined scowl"
# pose = "battle stance, holding wooden staff"
# lighting = "dramatic side lighting"
# style_suffix = "limited palette, dithered shadows"
```

### Environment Template

```python
ENVIRONMENT_TEMPLATE = """
{style_prefix}, {biome} environment, {time_of_day}, 
{key_elements}, {atmosphere}, 
{perspective}, {focal_point}, 
masterpiece, best quality, highly detailed, 
{style_suffix}, game background, tileable
"""

# Example fill:
# style_prefix = "pixel art, 256x256"
# biome = "mystical forest"
# time_of_day = "moonlit night"
# key_elements = "ancient ruins, glowing mushrooms, twisted trees"
# atmosphere = "mysterious, enchanted"
# perspective = "side view platformer"
# focal_point = "ruined temple entrance"
# style_suffix = "parallax layers, atmospheric perspective"
```

### Prop/Item Template

```python
PROP_TEMPLATE = """
{style_prefix}, {item_type}, {material}, 
{condition}, {details}, 
{angle}, {lighting}, 
masterpiece, best quality, highly detailed, 
{style_suffix}, transparent background, centered, icon
"""

# Example fill:
# style_prefix = "pixel art, 32x32"
# item_type = "ancient magical sword"
# material = "obsidian blade, gold hilt"
# condition = "slightly worn, mystical glow"
# details = "runic engravings, emerald pommel"
# angle = "45 degree angle"
# lighting = "magical ambient glow"
# style_suffix = "inventory icon style, clear silhouette"
```

### UI Element Template

```python
UI_TEMPLATE = """
{style_prefix}, {ui_type}, {shape}, 
{state}, {theme}, 
clean design, clear readability, 
masterpiece, best quality, 
{style_suffix}, transparent background, UI asset
"""

# Example fill:
# style_prefix = "flat vector design"
# ui_type = "health bar frame"
# shape = "rectangular with rounded corners"
# state = "empty state, red color"
# theme = "fantasy RPG style"
# style_suffix = "scalable vector, minimal details"
```

---

## Negative Prompt Library

### Universal Negative (All Assets)

```
blurry, low quality, worst quality, jpeg artifacts, 
watermark, signature, text, logo, 
photorealistic, 3d render, photograph, 
nsfw, inappropriate, distorted, deformed
```

### Character-Specific Negative

```
bad anatomy, extra limbs, missing limbs, 
fused fingers, too many fingers, 
mutated hands, poorly drawn hands, 
extra face, double head, extra head, 
malformed limbs, missing arms, missing legs
```

### Environment-Specific Negative

```
blurry background, busy composition, 
cluttered, unclear focal point, 
modern elements, people, cars, 
low resolution, pixelated
```

### UI-Specific Negative

```
unclear text, illegible, complex patterns, 
gradients that reduce readability, 
cluttered design, inconsistent spacing
```

---

## Dynamic Prompt Variables

### Mood Keywords

| Mood | Prompt Terms |
|------|--------------|
| Cheerful | bright colors, sunny, vibrant, happy |
| Dark | muted colors, shadows, ominous, foreboding |
| Mysterious | fog, soft lighting, hidden details, atmospheric |
| Epic | dramatic lighting, grand scale, intense |
| Calm | soft colors, peaceful, serene, gentle |

### Lighting Keywords

| Lighting | Prompt Terms |
|----------|--------------|
| Daylight | bright daylight, sunlit, clear shadows |
| Night | moonlight, starlight, dark, nighttime |
| Interior | indoor lighting, warm glow, ambient |
| Dramatic | strong contrast, chiaroscuro, cinematic |
| Magical | ethereal glow, magical lighting, bioluminescent |

---

## Prompt Engineering Rules

### DO
- ✅ Use specific, concrete descriptors
- ✅ Order terms by importance (most important first)
- ✅ Use comma-separated tags for SD/Flux
- ✅ Include quality boosters for base models
- ✅ Test prompts with 5-10 samples before batch

### DON'T
- ❌ Use abstract concepts without concrete anchors
- ❌ Overload prompts (>75 tokens can degrade quality)
- ❌ Include conflicting terms ("photorealistic pixel art")
- ❌ Neglect negative prompts (they're 50% of quality)
- ❌ Skip prompt testing before large batches

---

## Batch Prompt Variation

For generating diverse assets from a base concept:

```python
def generate_variations(base_prompt, variations, count_per_variation):
    """
    variations: list of (key, value_list) tuples
    Example: [("color", ["red", "blue", "green"]), ("size", ["small", "large"])]
    """
    prompts = []
    for combo in itertools.product(*[v for k, v in variations]):
        prompt = base_prompt
        for (key, _), value in zip(variations, combo):
            prompt = prompt.replace(f"{{{key}}}", value)
        prompts.extend([prompt] * count_per_variation)
    return prompts
```

---

## Related Systems

- [[Style_Lock_Approval_Process]] - Templates enforce locked parameters
- [[Batch_Generation_Workflow]] - Templates feed generation queue
- [[Local_Diffusion_Setup]] - Templates configured for local models
