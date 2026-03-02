---
title: Economy_Progression_System
type: mechanic
layer: design
status: active
tags:
  - economy
  - progression
  - balance
  - credits
depends_on:
  - "[Arena_Difficulty_Curve]]"
  - "[[Component_Unlock_System]"
used_by:
  - "[Player_Retention_Loop]]"
  - "[[Monetization_Design]"
---

# Economy Progression System

## Purpose
Create satisfying progression loop where players earn credits from battles, purchase components, and unlock new tiers. Balance risk/reward to maintain engagement.

## Core Rules

### Credit Flow

| Arena | Entry Fee | Reward | Net Profit | ROI |
|-------|-----------|--------|------------|-----|
| Boot Camp | 0 CR | 100 CR | +100 | ∞% |
| Iron Graveyard | 50 CR | 200 CR | +150 | 300% |
| Kill Grid | 150 CR | 400 CR | +250 | 267% |
| The Gauntlet | 300 CR | 600 CR | +300 | 200% |
| Champion's Pit | 500 CR | 1200 CR | +700 | 240% |

### Progression Pacing

**Starting:** 500 CR

| Step | Action | Credits |
|------|--------|---------|
| 1 | Win Boot Camp | 600 CR |
| 2 | Buy medium chassis (-550) | 50 CR |
| 3 | Win Graveyard (+150 net) | 200 CR |
| 4 | Save for plating | 200 CR |
| 5 | Win Graveyard ×2 | 500 CR |
| 6 | Buy plating (-380) | 120 CR |
| 7 | Unlock Kill Grid | 120 CR |

**Time to Unlock:**
- Tier 2: ~1 hour
- Tier 3: ~3 hours  
- Tier 4: ~6 hours
- Tier 5: ~10 hours

### Weight Limits by Arena

| Arena | Weight Cap | Strategic Implication |
|-------|------------|----------------------|
| Boot Camp | 80 kg | Light builds only |
| Graveyard | 100 kg | Medium builds unlock |
| Kill Grid | 130 kg | Heavy builds possible |
| Gauntlet | 150 kg | Dual bot strategy |
| Champion | 200 kg | Bring everything |

## Failure Modes

### Credit Inflation
**Symptom:** Players have too many credits, no meaningful choices
**Fix:** Increase component costs or add consumables

### Credit Starvation
**Symptom:** Players stuck grinding low arenas
**Fix:** Increase low-tier rewards or reduce costs

### Paywall Frustration
**Symptom:** Tier unlock feels too far away
**Fix:** Add side objectives with bonus credits

### Optimal Build Dominance
**Symptom:** One build type beats all arenas
**Fix:** Vary arena conditions (weight caps, enemy types)

## Enforcement

### Balance Metrics
```gdscript
# Automated analysis
target_credits_per_hour: float = 600.0
target_attempts_per_unlock: int = 5
max_grinding_ratio: float = 0.3  # 30% of time grinding
```

### Validation Tool
```gdscript
# Balance validator simulates 1000 players
func simulate_progression() -> Report:
    for player in 1000:
        while not campaign_complete:
            battle_result := simulate_battle()
            update_economy(battle_result)
    return analyze_paths()
```

### Red Flags
- >50% of time spent in Boot Camp (too grindy)
- Average >10 attempts per arena (too hard)
- <2 unique builds used (not enough variety)

## Related
[[Arena_Difficulty_Curve]]
[[Component_Pricing_Strategy]]
[[Weight_Cap_Design]]
[[Risk_Reward_Balance]]
