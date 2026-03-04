---
title: Paid Diffusion Routing
type: decision
layer: execution
status: active
tags:
  - art
  - diffusion
  - paid
  - api
  - routing
  - cost-control
depends_on:
  - "[Art_Pipeline_Overview]]"
  - "[[Local_Diffusion_Setup]]"
  - "[[Asset_Pack_First_Rule]"
used_by:
  - "[Batch_Generation_Workflow]"
---

# Paid Diffusion Routing

## Purpose

Define when and how to use paid AI generation APIs, ensuring they are reserved for cases where local generation or asset packs are insufficient.

---

## The Cost Reality

| Service | Cost per Image | 1000 Images | Monthly Budget |
|---------|---------------|-------------|----------------|
| Midjourney | $0.02-0.08 | $20-80 | $100-400 |
| DALL-E 3 | $0.02-0.08 | $20-80 | $100-400 |
| Stable Diffusion API | $0.002-0.01 | $2-10 | $10-50 |
| Leonardo.ai | $0.01-0.03 | $10-30 | $50-150 |
| Local RTX 4090 | $0.002 | $2 | $10 (electricity) |

**Rule**: Paid APIs cost 10-40x more than local generation.

---

## Routing Decision Tree

```
Need art asset?
│
├─▶ Check Asset Packs First
│   ├─▶ Pack exists and fits? → BUY PACK (cheapest)
│   └─▶ No suitable pack? → Continue
│
├─▶ Can Local Generation Work?
│   ├─▶ Style achievable locally? → USE LOCAL (cost-effective)
│   └─▶ Style requires paid API? → Continue
│
├─▶ Is This a Special Case?
│   ├─▶ Rush deadline? → USE PAID (time critical)
│   ├─▶ Complex composition? → USE PAID (quality critical)
│   ├─▶ Specific artist style? → USE PAID (only option)
│   └─▶ None of above? → USE LOCAL
│
└─▶ PAID API APPROVED
```

---

## When to Use Paid APIs

### Approved Use Cases

| Scenario | Justification | Approval Required |
|----------|---------------|-------------------|
| Rush deadline (< 24h) | Local batch too slow | Art Lead |
| Complex composition | Local models struggle | Art Lead + Tech Lead |
| Specific artist style | Only available via API | Art Lead |
| Key art/marketing | High visibility, quality critical | Studio Lead |
| Prototyping | Need quick iteration | None (within budget) |
| Style exploration | Before locking style | None (within budget) |

### Prohibited Use Cases

| Scenario | Why Not | Alternative |
|----------|---------|-------------|
| Bulk background art | Too expensive | Local generation |
| Common enemy sprites | Wasteful | Local generation |
| UI elements | Overkill | Asset packs or local |
| Placeholder art | Unnecessary cost | Gray boxes, local gen |
| Already have pack | Double spending | Use the pack |

---

## Service Selection

### Midjourney

**Best For**: Artistic styles, concept art, high-quality illustrations

**Pros**:
- Excellent aesthetic quality
- Strong at artistic styles
- Good prompt understanding

**Cons**:
- Expensive
- No API (Discord bot only)
- Limited control

**Cost**: $10-30/month subscription + $0.02-0.08/image

### DALL-E 3

**Best For**: Text accuracy, following complex prompts

**Pros**:
- Excellent text in images
- Great prompt adherence
- Available via OpenAI API

**Cons**:
- Expensive
- Can be overly "polished"
- Limited style control

**Cost**: $0.04-0.08 per image

### Leonardo.ai

**Best For**: Game assets, character consistency

**Pros**:
- Game-focused features
- Character consistency tools
- More affordable

**Cons**:
- Quality varies
- Smaller community

**Cost**: $0.01-0.03 per image

### Stable Diffusion API (Replicate, etc.)

**Best For**: When you need cloud but want SD control

**Pros**:
- Same models as local
- No hardware needed
- Pay per use

**Cons**:
- Still costs money
- Network latency

**Cost**: $0.002-0.01 per image

---

## Budget Management

### Monthly Budget Allocation

```yaml
art_generation_budget:
  total: $500
  
  allocation:
    asset_packs: $200      # 40% - always first choice
    local_generation: $50   # 10% - electricity, maintenance
    paid_api_rush: $150     # 30% - time-critical needs
    paid_api_quality: $100  # 20% - quality-critical needs
```

### Approval Thresholds

| Cost | Approval Required |
|------|-------------------|
| <$25 | None (within monthly budget) |
| $25-50 | Art Lead |
| $50-100 | Art Lead + Project Lead |
| >$100 | Studio Lead |

---

## Cost Tracking

### Usage Log

```yaml
paid_api_usage:
  - date: "2024-01-15"
    service: "leonardo.ai"
    images: 50
    cost: $1.50
    purpose: "Boss concept art exploration"
    approved_by: "art_lead"
    
  - date: "2024-01-16"
    service: "dall-e-3"
    images: 10
    cost: $0.80
    purpose: "Key art for store page"
    approved_by: "studio_lead"
```

### Monthly Report

```
PAID API USAGE - JANUARY 2024
==============================
Total Spent: $234.50
Budget: $500.00
Remaining: $265.50

Breakdown:
- Leonardo.ai: $150.00 (64%)
- DALL-E 3: $84.50 (36%)

Use Cases:
- Concept art: $150.00
- Marketing art: $84.50
```

---

## Integration with Pipeline

### API Integration Script

```python
import openai
import os

def generate_with_dalle(prompt, size="1024x1024", n=1):
    """Generate with DALL-E 3"""
    
    # Check budget
    if not check_budget_available(cost_estimate=0.04 * n):
        raise BudgetExceededError("Monthly budget exceeded")
    
    # Log usage
    log_api_request(service="dall-e-3", prompt=prompt, estimated_cost=0.04 * n)
    
    # Generate
    response = openai.images.generate(
        model="dall-e-3",
        prompt=prompt,
        size=size,
        n=n,
        response_format="url"
    )
    
    # Download and save
    for i, image in enumerate(response.data):
        download_image(image.url, f"dalle_output_{i}.png")
    
    # Log actual cost
    log_api_cost(service="dall-e-3", actual_cost=0.04 * n)
    
    return response
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  PAID API ROUTING QUICK REFERENCE                      │
├────────────────────────────────────────────────────────┤
│  APPROVED USES:                                        │
│  ✓ Rush deadlines (< 24h)                              │
│  ✓ Complex compositions                                │
│  ✓ Specific artist styles                              │
│  ✓ Key/marketing art                                   │
│  ✓ Prototyping (within budget)                         │
├────────────────────────────────────────────────────────┤
│  PROHIBITED USES:                                      │
│  ✗ Bulk background generation                          │
│  ✗ Common enemy sprites                                │
│  ✗ UI elements                                         │
│  ✗ When asset pack exists                              │
├────────────────────────────────────────────────────────┤
│  DECISION ORDER:                                       │
│  1. Asset Pack → 2. Local Gen → 3. Paid API            │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Asset_Pack_First_Rule]] - First choice in decision tree
- [[Local_Diffusion_Setup]] - Second choice in decision tree
- [[Art_Pipeline_Overview]] - Cost-first philosophy
- [[Batch_Generation_Workflow]] - Routing integration
