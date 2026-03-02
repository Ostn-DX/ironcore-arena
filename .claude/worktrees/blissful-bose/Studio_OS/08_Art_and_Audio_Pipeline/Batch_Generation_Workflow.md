---
title: Batch_Generation_Workflow
type: system
layer: execution
status: active
tags:
  - workflow
  - batch
  - generation
  - automation
depends_on:
  - "[Art_Direction_Intake_Template]"
used_by:
  - "[Daily_Operator_Protocol]"
---

# Batch Generation Workflow

## Purpose
Generate multiple assets efficiently with minimal human oversight. Cost-optimized and quality-gated.

## Workflow Steps

### 1. Batch Definition
```yaml
batch_id: BATCH-001
category: chassis
tier: 1
count: 5
priority: high
estimated_cost: $0.20
```

### 2. Prompt Preparation
```python
# Generate prompts from template
base_prompt = load_template("chassis")
variants = ["scout", "fighter", "tank", "sniper", "support"]

prompts = []
for variant in variants:
    prompt = base_prompt.format(
        type=variant,
        color=get_tier_color(tier),
        size=get_size(variant)
    )
    prompts.append(prompt)
```

### 3. Generation
```bash
# Run batch generation
python tools/generate_batch.py BATCH-001

# Output to:
assets/generated/BATCH-001/
  - raw/
  - processed/
  - rejected/
```

### 4. Auto-Validation
```python
for asset in batch:
    checks = {
        "dimensions": validate_size(asset),
        "colors": validate_palette(asset),
        "format": validate_png(asset),
        "naming": validate_naming(asset),
    }
    
    if all(checks.values()):
        move_to_processed(asset)
    else:
        move_to_rejected(asset, reason=checks)
```

### 5. Human Review
```
Review queue: assets/generated/BATCH-001/processed/

Human checks:
- Visual quality
- Style consistency
- Game readability

Approve: Move to assets/sprites/
Reject: Back to generation with feedback
```

## Batch Sizes

| Category | Optimal Batch | Cost | Review Time |
|----------|---------------|------|-------------|
| Sprites | 10-20 | $0.40-0.80 | 15 min |
| Tilesets | 5-10 | $0.40-0.80 | 10 min |
| UI Elements | 20-50 | $0.40-1.00 | 20 min |
| Effects | 10-15 | $0.40-0.60 | 10 min |

## Cost Optimization

### Model Selection
```python
if batch_size > 20:
    model = "stable-diffusion-xl"  # Cheaper at scale
else:
    model = "dall-e-3"  # Better quality
```

### Parallel Generation
```bash
# Generate 5 at once
cat prompts.txt | xargs -P 5 -I {} generate.sh {}
```

### Reuse
- Similar assets: Start from existing, modify
- Color variants: Hue shift, don't regenerate
- Tier progression: Recolor + detail add

## Validation Gates

### Gate 1: Technical
- Automated, 100% of assets
- Dimensions, format, naming
- < 1 second per asset

### Gate 2: Visual
- Human, 20% sample
- Style, quality, consistency
- < 30 seconds per asset

### Gate 3: In-Game
- Human, 100% of approved
- Playtest visibility
- < 2 minutes per asset

## Rejection Handling

| Rejection Rate | Action |
|---------------|--------|
| < 10% | Acceptable, continue |
| 10-30% | Review prompts, adjust |
| > 30% | Stop batch, fix process |

## Related
[[Art_Direction_Intake_Template]]
[[Asset_Validation_Gates]]
[[Prompt_Architecture_Standard]]
