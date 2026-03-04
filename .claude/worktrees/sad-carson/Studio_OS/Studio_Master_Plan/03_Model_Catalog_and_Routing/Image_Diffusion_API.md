---
title: Image Diffusion (API)
type: agent
layer: execution
status: active
tags:
  - image
  - diffusion
  - api
  - midjourney
  - dalle
  - generation
  - assets
depends_on:
  - "[Model_Catalog_Overview]]"
  - "[[Image_Diffusion_Local]]"
  - "[[Vision_Art_Direction]"
used_by:
  - "[Asset_Integration_Routing]"
---

# Image Diffusion (API)

## Model Class: Commercial Image Generation APIs

API-based image generation services provide highest-quality results with minimal setup. These services are ideal for critical assets, rapid prototyping, and when local hardware is insufficient.

### Supported Services

| Service | Quality | Speed | Cost/Image | Best For |
|---------|---------|-------|------------|----------|
| Midjourney v6.1 | 10/10 | 30-60s | $0.08-0.10 | Production art |
| DALL-E 3 | 9/10 | 10-20s | $0.04-0.08 | UI, concepts |
| Stable Diffusion XL (API) | 8/10 | 5-15s | $0.002-0.02 | Volume generation |
| Leonardo.ai | 8/10 | 10-30s | $0.01-0.05 | Game assets |
| Ideogram | 8/10 | 10-20s | $0.04-0.08 | Text in images |
| Firefly 3 | 8/10 | 5-10s | $0.02-0.05 | Commercial use |

### Capability Profile

**Strengths:**
- Highest quality generation
- No hardware investment
- Fast iteration
- Regular model updates
- Built-in upscaling
- User-friendly interfaces
- Professional results out-of-box

**Weaknesses:**
- Per-generation cost
- Rate limits
- Privacy concerns
- Limited parameter control
- Dependency on service availability
- Licensing restrictions
- Less customization

### Optimal Use Cases

**Best for API Generation:**
- Key art and promotional materials
- Final production assets
- Rapid prototyping
- When quality > cost
- Complex compositions
- Photorealistic requirements
- Time-critical needs

**Better Local:**
- High-volume generation
- Iterative refinement
- Sensitive content
- Custom styles/characters
- Tight budget constraints

### Cost Comparison

| Service | Standard | HD/4K | Bulk Pricing |
|---------|----------|-------|--------------|
| Midjourney | $0.08 | $0.16 | Subscription |
| DALL-E 3 | $0.04 | $0.08 | API credits |
| Leonardo | $0.01 | $0.04 | Token packs |
| SDXL API | $0.002 | $0.008 | Pay-per-use |

### Quality Benchmarks

| Aspect | Midjourney | DALL-E 3 | SDXL API |
|--------|-----------|----------|----------|
| Artistic Quality | 10/10 | 8/10 | 7/10 |
| Prompt Adherence | 7/10 | 9/10 | 8/10 |
| Consistency | 8/10 | 8/10 | 7/10 |
| Character Accuracy | 8/10 | 8/10 | 6/10 |
| Text Rendering | 5/10 | 8/10 | 4/10 |
| Upscaling | 9/10 | 7/10 | 6/10 |

### Service Selection Guide

| Need | Recommended Service | Why |
|------|---------------------|-----|
| Best overall quality | Midjourney v6.1 | Superior aesthetics |
| Prompt accuracy | DALL-E 3 | Best adherence |
| Text in images | Ideogram 2.0 | Designed for text |
| Volume/budget | SDXL API | Lowest cost |
| Game-specific | Leonardo.ai | Asset-focused |
| Commercial safety | Firefly 3 | Licensed training |

### Workflow Integration

```
1. Define asset requirements
2. Select service based on needs
3. Craft optimized prompt
4. Generate initial batch
5. Iterate on best results
6. Upscale final selection
7. Download and validate
8. Post-process if needed
9. Integrate into game
```

### Prompt Engineering by Service

**Midjourney:**
```
/imagine prompt: fantasy castle on floating island, 
magnificent architecture, dramatic lighting, golden hour, 
8k, highly detailed, cinematic composition --ar 16:9 --v 6.1
```

**DALL-E 3:**
```
"A detailed fantasy castle on a floating island, 
professional game art style, dramatic golden hour lighting, 
highly detailed, 4K quality"
```

**Leonardo:**
```
Fantasy castle, floating island, dramatic lighting, 
<game art style>, highly detailed, masterpiece
[Select: RPG v5 model, 1024x1024]
```

### Cost Optimization

**Strategies:**
1. Use local models for iteration
2. Reserve APIs for final assets
3. Batch generations
4. Use subscription plans for volume
5. Start with cheaper services
6. Cache and reuse assets

**Budget Allocation:**
- 70% local generation (iteration)
- 20% mid-tier API (validation)
- 10% premium API (final assets)

### Failure Patterns

1. **Prompt Ignored**: Doesn't follow instructions
   - *Detection*: Visual comparison
   - *Remediation*: Refine prompt, try different service

2. **Inconsistent Style**: Batch variations too different
   - *Detection*: Style comparison
   - *Remediation*: Add style references, use seed

3. **Quality Inconsistency**: Some outputs poor
   - *Detection*: Batch review
   - *Remediation*: Generate extras, curate best

4. **Rate Limiting**: Generation blocked
   - *Detection*: API error
   - *Remediation*: Implement backoff, queue system

### Best Practices

1. Maintain service-specific prompt libraries
2. Use reference images when available
3. Generate 3-5x needed for curation
4. Document successful prompts
5. Monitor costs per asset type
6. Have fallback services
7. Review licensing terms

### Cost Governance

**Monthly Budget Tiers:**
- Indie: $50-100 (mostly local, selective API)
- Small Studio: $200-500 (balanced usage)
- Mid Studio: $1000-3000 (API-heavy)
- AAA: $5000+ (volume + premium)

### Integration

Used primarily by:
- [[Asset_Integration_Routing]]: High-quality 2D asset pipeline
