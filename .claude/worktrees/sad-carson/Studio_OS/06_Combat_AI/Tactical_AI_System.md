---
title: Tactical_AI_System
type: system
layer: execution
status: planned
tags:
  - ai
  - tactics
  - pathfinding
  - combat
depends_on:
  - "[Deterministic_60Hz_Simulation]]"
  - "[[Pathfinding_System]]"
  - "[[Squad_Coordination]"
used_by:
  - "[AI_Tank_Profile]]"
  - "[[AI_Assault_Profile]]"
  - "[[AI_Sniper_Profile]]"
  - "[[AI_Scout_Profile]"
---

# Tactical AI System

## Purpose
Replace simplistic "walk and shoot" AI with tactical behaviors: cover usage, flanking, range management, and squad coordination.

## Core Rules

### Tactical Position Scoring
```gdscript
func evaluate_position(pos: Vector2) -> float:
    var score: float = 0.0
    
    # Distance to optimal weapon range
    var range_score: float = 1.0 - abs(current_distance - optimal_range) / optimal_range
    score += range_score * 2.0  # Weight: 2x
    
    # Proximity to cover
    var cover_score: float = get_distance_to_nearest_cover(pos)
    score += cover_score * 1.5  # Weight: 1.5x
    
    # Line of sight to enemies
    var los_score: float = count_visible_enemies(pos) / max_enemies
    score += los_score * 1.0  # Weight: 1x
    
    # Risk (exposure to enemy fire)
    var risk_penalty: float = calculate_exposure(pos)
    score -= risk_penalty * 2.0  # Weight: -2x
    
    # Cohesion (distance to allies)
    var cohesion_score: float = 1.0 - (distance_to_nearest_ally / max_cohesion_distance)
    score += cohesion_score * 0.5  # Weight: 0.5x
    
    return score
```

### AI Role Behaviors

| Role | Primary Goal | Range Preference | Cover Usage |
|------|-------------|------------------|-------------|
| **Tank** | Absorb damage, draw fire | Close (50% max) | Low (blocks allies) |
| **Assault** | Sustained damage | Medium (70% max) | High (peek-shoot) |
| **Sniper** | Burst damage, priority targets | Maximum range | Very high |
| **Scout** | Flank, hit backline | Variable | Medium |

### State Transitions
```gdscript
enum TacticalState {
    ENGAGE,      # Actively fighting
    TAKE_COVER,  # Moving to/behind cover
    FLANK,       # Moving to side/rear of enemy
    RETREAT,     # Low HP, no allies nearby
    HOLD         # Waiting for opportunity
}
```

### Retreat Conditions
- HP < 25% AND
- No allies within 150 units AND
- No cover within 50 units

## Failure Modes

### AI Stuck
**Symptom:** Bot circles obstacle indefinitely
**Cause:** Pathfinding oscillation between similar-scored positions
**Fix:** Position cache with cooldown, random jitter

### Suicidal AI
**Symptom:** Bot runs into open fire
**Cause:** Underestimating risk score
**Fix:** Increase risk penalty weight, add suppression mechanic

### Determinism Break
**Symptom:** Same seed, different AI choices
**Cause:** Unseeded random in position evaluation
**Fix:** All randomness through seeded RNG

## Enforcement

### Metrics
- Sniper maintains 70%+ max weapon range
- Tank positions closer to enemies than allies
- Focus-fire coordination: 3+ bots on same target within 2s
- Retreat triggers correctly at 25% HP

### Tests
- [[Test_AI_Pathfinding]]: Navigates around obstacles
- [[Test_Squad_Coordination]]: Focus fire works
- [[Test_Range_Maintenance]]: Roles maintain preferences

## Related
[[AStar_Pathfinding_Implementation]]
[[Influence_Maps_For_Tactics]]
[[Squad_Manager_System]]
[[AI_Determinism_Validation]]
