---
title: Image Diffusion (Local)
type: agent
layer: execution
status: active
tags:
  - image
  - diffusion
  - local
  - sd
  - flux
  - generation
  - assets
depends_on:
  - "[Model_Catalog_Overview]]"
  - "[[Vision_Art_Direction]"
used_by:
  - "[Asset_Integration_Routing]"
---

# Image Diffusion (Local)

## Model Class: Local Stable Diffusion / Flux Models

Local image diffusion models provide cost-effective, private asset generation for games. Modern local models (SDXL, Flux, SD3) achieve quality approaching commercial APIs while maintaining full control and privacy.

### Supported Models

| Model | Parameters | VRAM | Quality | Speed (1024x1024) |
|-------|------------|------|---------|-------------------|
| Flux.1 [dev] | 12B | 16-24GB | Excellent | 30-60s |
| Flux.1 [schnell] | 12B | 12-16GB | Very Good | 10-20s |
| SDXL | 3.5B | 6-8GB | Very Good | 15-30s |
| SD 1.5 | 1B | 4-6GB | Good | 5-15s |
| SD 3 Medium | 2B | 8-12GB | Very Good | 20-40s |
| Pony Diffusion | 1B | 4-6GB | Good | 5-15s |

### Capability Profile

**Strengths:**
- No per-generation cost
- Full privacy (no data leaves local machine)
- Unlimited generations
- Complete parameter control
- Custom model training/fine-tuning
- No rate limits
- Offline capability

**Weaknesses:**
- Significant hardware requirements
- Slower than API services
- Setup complexity
- Model management overhead
- Quality slightly below best APIs
- Requires technical knowledge

### Optimal Asset Types

**Well-Suited for Local Generation:**
- Concept art iterations
- Texture variations
- UI elements and icons
- Background images
- Character portraits (with LoRA)
- Prop and item images
- Marketing materials

**Challenging for Local:**
- Very high resolution (4K+)
- Complex multi-character scenes
- Specific style matching
- Photorealistic humans
- Complex compositions

### Hardware Requirements

| Tier | GPU | VRAM | Performance | Cost |
|------|-----|------|-------------|------|
| Entry | RTX 3060 12GB | 12GB | 1-2 img/min | $300 |
| Mid | RTX 4070 Ti 16GB | 16GB | 3-4 img/min | $800 |
| High | RTX 4090 24GB | 24GB | 6-8 img/min | $1600 |
| Pro | 2x RTX 4090 | 48GB | 12-16 img/min | $3200 |

### Generation Configuration

```yaml
diffusion:
  model: "flux1-dev.safetensors"
  
  # Generation parameters
  width: 1024
  height: 1024
  steps: 20-50  # quality vs speed
  cfg_scale: 7.0  # prompt adherence
  sampler: "dpmpp_2m"  # or "euler_a"
  
  # Optimization
  batch_size: 1-4
  vae_tiling: true  # for large images
  cpu_offload: false  # for low VRAM
  
  # LoRA for style/character
  lora:
    - path: "style_lora.safetensors"
      weight: 0.8
    - path: "character_lora.safetensors"
      weight: 0.9
```

### Cost Analysis

| Factor | Local | API (Midjourney) |
|--------|-------|------------------|
| Hardware | $800-3200 | $0 |
| Per image | $0.001* | $0.08-0.20 |
| 1000 images | $1 | $80-200 |
| 10000 images | $10 | $800-2000 |
| Break-even | ~5000 images | Immediate |

*Electricity cost

### Quality Comparison

| Model | Concept Art | Characters | Environments | UI |
|-------|-------------|------------|--------------|-----|
| Flux.1 [dev] | 9/10 | 8/10 | 9/10 | 8/10 |
| SDXL + Refiner | 8/10 | 7/10 | 8/10 | 7/10 |
| SD 1.5 | 6/10 | 5/10 | 6/10 | 6/10 |
| Midjourney v6 | 9/10 | 9/10 | 9/10 | 7/10 |
| DALL-E 3 | 8/10 | 8/10 | 8/10 | 8/10 |

### Workflow Integration

```
1. Define asset requirements
2. Load appropriate model + LoRAs
3. Generate prompt from art direction
4. Generate batch (4-8 variations)
5. Review and select best
6. Upscale if needed
7. Post-process (remove artifacts)
8. Export to game format
9. Validate in-engine
```

### Prompt Engineering

**Effective Prompt Structure:**
```
[Subject], [Style], [Quality modifiers], [Technical specs]

Example:
"Fantasy warrior portrait, oil painting style, highly detailed, 
masterpiece, best quality, 8k uhd, dramatic lighting"

Negative prompt:
"low quality, blurry, deformed, bad anatomy, watermark, signature"
```

### Failure Patterns

1. **Artifacting**: Strange visual artifacts
   - *Detection*: Visual inspection
   - *Remediation*: Increase steps, adjust CFG

2. **Anatomy Issues**: Incorrect body proportions
   - *Detection*: Character review
   - *Remediation*: Use character LoRA, inpaint fixes

3. **Style Drift**: Doesn't match target style
   - *Detection*: Art director review
   - *Remediation*: Adjust LoRA weights, refine prompt

4. **Resolution Limits**: Quality drops at high res
   - *Detection*: Pixel inspection
   - *Remediation*: Use upscale pipeline, tiled generation

### Best Practices

1. Maintain prompt library for consistency
2. Use LoRAs for character/style consistency
3. Generate multiple variations
4. Establish quality review process
5. Version control models and settings
6. Document successful prompts
7. Batch process similar assets

### Cost Governance

**Monthly Operating Costs:**
- Hardware amortization: $50-200/mo
- Electricity: $20-100/mo
- Model downloads: $0-50/mo
- **Total**: $70-350/mo for unlimited generation

### Integration

Used primarily by:
- [[Asset_Integration_Routing]]: 2D asset pipeline
