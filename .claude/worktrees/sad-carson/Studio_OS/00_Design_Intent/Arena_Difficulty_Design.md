---
title: Arena_Difficulty_Design
type: mechanic
layer: design
status: active
tags:
  - arenas
  - difficulty
  - level_design
  - progression
depends_on:
  - "[Economy_Progression_System]"
used_by:
  - "[Player_Retention_Loop]]"
  - "[[Tutorial_Design]"
---

# Arena Difficulty Design

## Purpose
Create 5 arenas that teach mechanics progressively while providing satisfying challenge curve. Each arena focuses on one core lesson.

## Core Rules

### Arena Identity Matrix

| Arena | Theme | Mechanics Taught | Difficulty |
|-------|-------|------------------|------------|
| **Boot Camp** | Training facility | Basic controls | ⭐ Very Easy |
| **Iron Graveyard** | Scrapyard | Cover, flanking | ⭐⭐ Easy |
| **Kill Grid** | Death trap | Hazards, priorities | ⭐⭐⭐⭐ Hard |
| **The Gauntlet** | Chokepoint | Positioning, waves | ⭐⭐⭐⭐ Hard |
| **Champion's Pit** | Boss arena | Everything combined | ⭐⭐⭐⭐⭐ Expert |

### Layout Principles

#### Boot Camp
- Open central area (600×400)
- 1-2 simple barriers
- Clear sight lines
- Symmetrical for fairness

#### Iron Graveyard
- Central corridor + side alcoves
- 4-6 cover points
- Choke points and flanking routes
- Asymmetrical for strategy

#### Kill Grid
- Large open area (1000×700)
- Hazard zones (mines)
- Elevated sniper positions
- Central safe corridor

### Enemy Composition

| Arena | Enemies | Total Enemy Weight | Player Limit | Advantage |
|-------|---------|-------------------|--------------|-----------|
| Boot Camp | 1 Scout | 50 kg | 80 kg | +30kg (favored) |
| Graveyard | Fighter + Scout | 131 kg | 100 kg | -31kg (underdog) |
| Kill Grid | Tank + Fighter + Sniper | 251 kg | 130 kg | -121kg (challenging) |

### Teaching Progression

```
Boot Camp: "This is how you move and shoot"
    ↓
Graveyard: "Use cover or die"
    ↓
Kill Grid: "Prioritize targets, watch hazards"
    ↓
Gauntlet: "Position matters more than power"
    ↓
Champion: "Master everything"
```

## Failure Modes

### Difficulty Spike
**Symptom:** Arena 3 much harder than 2, players quit
**Fix:** Smooth curve, gradual enemy count increase

### Tutorial Drag
**Symptom:** Boot Camp too long, players bored
**Fix:** Keep tutorial under 5 minutes

### Visual Sameness
**Symptom:** All arenas look/feel similar
**Fix:** Distinct color palettes and obstacles

## Enforcement

### Metrics
- First-attempt clear rate per arena
- Average attempts before success
- Drop-off rate between arenas

### Targets
| Arena | First Attempt Clear | Avg Attempts |
|-------|---------------------|--------------|
| Boot Camp | >90% | 1.2 |
| Graveyard | >75% | 1.5 |
| Kill Grid | >50% | 2.5 |
| Gauntlet | >40% | 3.0 |
| Champion | >30% | 4.0 |

## Related
[[Enemy_AI_Profiles]]
[[Hazard_System_Design]]
[[Visual_Theme_Palette]]
[[Progression_Pacing]]
