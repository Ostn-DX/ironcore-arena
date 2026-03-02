---
title: Art Pipeline Overview
type: pipeline
layer: architecture
status: active
tags:
  - art
  - pipeline
  - automation
  - overview
  - philosophy
depends_on: []
used_by:
  - "[Art_Direction_Intake_Format]]"
  - "[[Batch_Generation_Workflow]]"
  - "[[Local_Diffusion_Setup]]"
  - "[[Asset_Pack_First_Rule]"
---

# Art Pipeline Overview

## Philosophy: Generate at Scale, Curate with Precision

The AI-Native Game Studio art pipeline treats visual asset creation as a **batch manufacturing process** rather than a craft exercise. The goal is to produce consistent, game-ready art with minimal human intervention while maintaining quality standards through automated validation gates.

### Core Principles

**1. Local-First Generation**
- Primary generation happens on local hardware (ComfyUI/Stable Diffusion/Flux)
- Paid APIs reserved for edge cases: specific styles, rush deadlines, or complex compositions
- Token budget allocated monthly; local generation is "free" after hardware investment

**2. Asset Pack Priority**
- Before any generation, check existing asset packs (Unity Asset Store, Unreal Marketplace, itch.io, Kenney.nl)
- Packs provide: consistency, proven integration, no generation time
- Rule: If a pack exists at < $50 that covers 80% of needs, buy it

**3. Batch Over Individual**
- Generate in batches of 20-50 variants per prompt
- Curate via automated filters (resolution check, color consistency, blur detection)
- Human review only on pre-filtered candidates

**4. Style Lock Early**
- Define visual style in pre-production and lock it
- All generation uses the same base model + LoRA + prompt structure
- Style drift is expensive; prevent it through enforced templates

### Pipeline Stages

```
Design Intent → Style Validation → Batch Generate → Auto-Curate → Human Pick → Import → Validate
```

| Stage | Automation Level | Human Touch |
|-------|-----------------|-------------|
| Design Intent | Template-driven | Fill form |
| Style Validation | Auto-check against style guide | Approve/Revise |
| Batch Generate | 100% automated | Monitor queue |
| Auto-Curate | Filter scripts run | Review shortlist |
| Human Pick | None | Select finalists |
| Import | Scripted pipeline | Verify in-engine |
| Validate | Automated checks | Fix failures |

### Cost Model

| Approach | Cost per 100 assets | Time | Quality Variance |
|----------|---------------------|------|------------------|
| Local SD/Flux | $2-5 (electricity) | 2-4 hours | Medium |
| Paid API (Midjourney/DALL-E) | $20-80 | 30 min | Low |
| Asset Pack | $10-50 | Immediate | Low |
| Manual Artist | $500-2000 | 1-2 weeks | Very Low |

**Decision Rule**: Asset Pack → Local Generation → Paid API → Manual (in that order)

### Tool Stack

**Generation**: ComfyUI + Flux.1-dev (local), Automatic1111 (legacy), Fooocus (quick gen)
**Upscaling**: Upscayl (local), Real-ESRGAN
**Batch Processing**: ImageMagick, Python PIL scripts
**Validation**: Custom pytest suite, perceptual hash comparison
**Integration**: Unity/Unreal import scripts, addressable asset pipeline

### Success Metrics

- **Generation Rate**: >50 assets/hour on local hardware
- **Acceptance Rate**: >30% of generated assets pass auto-curation
- **Integration Time**: <5 minutes from generation to in-engine preview
- **Cost per Asset**: <$0.50 average across all asset types

### Anti-Patterns

❌ Generating one asset at a time and tweaking prompts
❌ Using paid APIs for bulk background/environment art
❌ Manual Photoshop cleanup on generated assets
❌ No naming convention - assets scattered across folders
❌ Different artists/models producing same asset type

### Related Systems

- [[Asset_Pack_First_Rule]] - The cardinal rule of cost control
- [[Batch_Generation_Workflow]] - Detailed generation process
- [[Style_Lock_Approval_Process]] - Preventing style drift
- [[Art_Validation_Gates]] - Automated quality checks
