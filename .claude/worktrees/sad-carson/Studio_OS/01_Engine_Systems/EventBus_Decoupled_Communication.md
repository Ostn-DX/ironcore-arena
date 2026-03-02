---
title: EventBus_Decoupled_Communication
type: system
layer: architecture
status: active
tags:
  - events
  - signals
  - decoupling
  - pub-sub
depends_on: []
used_by:
  - "[UI_Screen_Transitions]]"
  - "[[Combat_Events]]"
  - "[[Economy_Events]"
---

# EventBus Decoupled Communication

## Purpose
Eliminate direct singleton references between systems. Systems communicate through typed events rather than hardcoded dependencies.

## Core Rules

### EventBus Singleton
```gdscript
class_name EventBus
extends Node

# Combat events
signal enemy_died(enemy: Bot, position: Vector2, xp: int)
signal player_hit(damage: int, source: String)
signal battle_started(arena_id: String)
signal battle_ended(result: String, stats: Dictionary)

# Economy events
signal credits_changed(new_amount: int, delta: int)
signal item_purchased(item_id: String, cost: int)
signal tier_unlocked(tier: int)

# Progression events
signal arena_completed(arena_id: String)
signal achievement_unlocked(id: String)
```

### Emission Pattern
```gdscript
# OLD (coupled):
get_node("/root/GameState").add_credits(100)
get_node("/root/UIManager").update_credits()

# NEW (decoupled):
EventBus.credits_changed.emit(GameState.credits + 100, 100)
# UIManager listens and updates automatically
```

### Connection Pattern
```gdscript
func _ready() -> void:
    EventBus.enemy_died.connect(_on_enemy_died)
    EventBus.credits_changed.connect(_on_credits_changed)

func _exit_tree() -> void:
    EventBus.enemy_died.disconnect(_on_enemy_died)
    EventBus.credits_changed.disconnect(_on_credits_changed)
```

## Failure Modes

### Memory Leak
**Symptom:** Disconnected UI still receives events
**Cause:** Not disconnecting in `_exit_tree()`

### Signal Storm
**Symptom:** Event triggers cascade of updates
**Cause:** Events triggering other events without debounce

### Type Mismatch
**Symptom:** Connected function signature doesn't match signal
**Cause:** GDScript doesn't enforce at connection time

## Enforcement

### Static Analysis
- All EventBus usages must disconnect in `_exit_tree()`
- Signal signatures documented in EventBus.gd
- No direct singleton access allowed (use EventBus)

## Related
[[Singleton_Pattern_Godot]]
[[Memory_Management]]
[[Observer_Pattern]]
