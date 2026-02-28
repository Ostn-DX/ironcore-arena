---
title: Asset Pack First Rule
type: rule
layer: enforcement
status: active
tags:
  - art
  - asset-packs
  - cost-control
  - rule
  - optimization
depends_on:
  - "[Art_Pipeline_Overview]"
used_by:
  - "[Paid_Diffusion_Routing]]"
  - "[[Batch_Generation_Workflow]"
---

# Asset Pack First Rule

## The Rule

> **"Do not burn tokens on assets when asset packs suffice."**

This is the cardinal rule of cost-effective art production. Before any generation—local or paid—check if a suitable asset pack exists.

---

## Why Asset Packs First?

### Cost Comparison

| Approach | 100 Assets | 1000 Assets | Quality |
|----------|-----------|-------------|---------|
| Asset Pack ($30) | $30 | $30 | Consistent, proven |
| Local Generation | $2 | $20 | Variable |
| Paid API | $20-80 | $200-800 | High but expensive |
| Manual Artist | $500-2000 | $5000-20000 | Highest |

**Insight**: A $30 asset pack pays for itself after ~50 generated images.

### Benefits of Asset Packs

| Benefit | Description |
|---------|-------------|
| **Consistency** | All assets share the same style |
| **Proven Quality** | Reviewed by community, tested in games |
| **Instant Availability** | Download and use immediately |
| **No Generation Time** | Skip the generation pipeline entirely |
| **Support Included** | Often includes updates and fixes |
| **Legal Clarity** | Clear licensing terms |

---

## Asset Pack Search Process

### Step 1: Define Requirements

Before searching, document:
```yaml
asset_requirements:
  type: "2D character sprites"
  style: "pixel art, 64x64"
  quantity: "20+ characters"
  theme: "fantasy RPG"
  animations: "idle, walk, attack"
  budget: "$50 max"
```

### Step 2: Search Sources

| Source | URL | Strengths |
|--------|-----|-----------|
| Unity Asset Store | assetstore.unity.com | Largest selection, quality filter |
| Unreal Marketplace | unrealengine.com/marketplace | High quality, engine-integrated |
| itch.io | itch.io/game-assets | Indie-friendly, affordable |
| Kenney.nl | kenney.nl | Free, consistent style |
| OpenGameArt | opengameart.org | Free, community-driven |
| Craftpix | craftpix.net | Game-ready packs |
| GameDev Market | gamedevmarket.net | Varied selection |

### Step 3: Evaluation Criteria

| Criterion | Weight | Check |
|-----------|--------|-------|
| Style Match | 30% | Does it fit our game's aesthetic? |
| Coverage | 25% | Does it cover 80%+ of needs? |
| Quality | 20% | Are assets polished and professional? |
| Price | 15% | Is it within budget? |
| License | 10% | Is the license suitable? |

**Minimum Score**: 70/100 to consider purchase

### Step 4: Pack Evaluation Form

```yaml
pack_evaluation:
  name: "Fantasy Character Pack Vol.1"
  source: "Unity Asset Store"
  price: $29.99
  
  style_match:
    score: 8/10
    notes: "Pixel art matches, slightly brighter palette"
    adjustment_needed: "Color grading in-engine"
  
  coverage:
    score: 9/10
    needed_assets: 25
    covered: 23
    missing: ["boss_character", "shopkeeper"]
  
  quality:
    score: 9/10
    notes: "Professional, consistent, good animations"
  
  license:
    type: "Single Entity"
    commercial_use: true
    modification: allowed
    redistribution: prohibited
  
  overall_score: 87/100
  recommendation: PURCHASE
```

---

## The 80% Rule

> **"If a pack covers 80% of your needs, buy it. Generate only the missing 20%."**

### Example Application

**Need**: 25 character sprites
**Pack Coverage**: 23 characters
**Missing**: 2 characters (boss, unique NPC)

**Decision**: BUY PACK + Generate 2 characters locally

**Cost**: $30 (pack) + $1 (local generation) = $31
**Alternative**: Generate all 25 locally = $50 (time) + electricity

---

## Pack Modification Guidelines

### Allowed Modifications

✅ Color adjustments (in-engine)
✅ Scale modifications
✅ Adding custom details (small edits)
✅ Combining pack assets
✅ Creating variations from base assets

### Prohibited Modifications

❌ Redistributing modified assets
❌ Claiming as original work
❌ Reselling modifications
❌ Using in violation of license

---

## Pack Integration Workflow

```
1. Purchase and download pack
2. Review license and attribution requirements
3. Import to project
4. Document pack usage in asset registry
5. Note any required modifications
6. Generate missing assets (if any)
7. Apply consistent post-processing
8. Validate all assets together
```

### Asset Registry Entry

```yaml
asset_registry:
  pack_id: "PACK-001"
  name: "Fantasy Character Pack Vol.1"
  source: "Unity Asset Store"
  purchase_date: "2024-01-15"
  price: $29.99
  license: "Single Entity"
  
  assets:
    - char_warrior_idle_01.png
    - char_warrior_walk_01.png
    - char_mage_idle_01.png
    # ... 23 total assets
  
  modifications:
    - type: "color_grading"
      description: "Adjusted brightness to match game palette"
    
  generated_supplements:
    - char_boss_dragon_idle_01.png
    - char_npc_shopkeeper_idle_01.png
```

---

## When Packs Don't Suffice

### Valid Reasons to Skip Packs

| Reason | Example | Action |
|--------|---------|--------|
| Unique art style | Game has custom aesthetic | Generate locally |
| Specific requirements | Procedural generation needs | Generate locally |
| Pack quality insufficient | All packs reviewed, none suitable | Generate or commission |
| Budget constraint | No funds for packs | Use free packs or generate |
| License incompatibility | License doesn't fit use case | Generate or find alternative |

### Documentation Required

When skipping packs, document why:
```yaml
pack_skip_justification:
  asset_type: "sci-fi UI elements"
  packs_reviewed: 12
  
  reasons:
    - "No packs match game's holographic UI style"
    - "Required animations not available in any pack"
    - "Custom interaction system requires specific layouts"
  
  decision: "Generate locally using Style Lock"
  approved_by: "art_lead"
```

---

## Free Pack Sources

### High-Quality Free Packs

| Source | License | Notes |
|--------|---------|-------|
| Kenney.nl | CC0 | Excellent quality, consistent style |
| OpenGameArt | Various | Community submissions, variable quality |
| Unity Standard Assets | Unity EULA | Official, well-supported |
| Unreal Starter Content | Unreal EULA | Official, high quality |
| Game-icons.net | CC BY | SVG icons, scalable |

---

## Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Pack Coverage Rate | >60% | % of assets from packs |
| Pack Purchase Efficiency | <$1/asset | Total pack cost / assets used |
| Pack Search Time | <30 min | Time to find suitable pack |
| Pack Integration Time | <1 hour | Time from purchase to in-engine |

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  ASSET PACK FIRST RULE                                 │
├────────────────────────────────────────────────────────┤
│  THE RULE:                                             │
│  "Do not burn tokens on assets when packs suffice."    │
├────────────────────────────────────────────────────────┤
│  THE 80% RULE:                                         │
│  If a pack covers 80% of needs, BUY IT.                │
│  Generate only the missing 20%.                        │
├────────────────────────────────────────────────────────┤
│  DECISION ORDER:                                       │
│  1. Free Packs → 2. Paid Packs → 3. Local Gen          │
├────────────────────────────────────────────────────────┤
│  KEY SOURCES:                                          │
│  • Kenney.nl (free)                                    │
│  • Unity Asset Store                                   │
│  • Unreal Marketplace                                  │
│  • itch.io                                             │
│  • OpenGameArt                                         │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Art_Pipeline_Overview]] - Cost-first philosophy
- [[Paid_Diffusion_Routing]] - Next option if no pack
- [[Batch_Generation_Workflow]] - Generation if pack insufficient
- [[Style_Lock_Approval_Process]] - Ensures pack-modified assets match
