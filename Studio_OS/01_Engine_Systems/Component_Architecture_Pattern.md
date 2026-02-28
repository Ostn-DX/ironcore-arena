---
title: Component_Architecture_Pattern
type: system
layer: architecture
status: active
tags:
  - components
  - composition
  - patterns
  - reusability
depends_on: []
used_by:
  - "[Health_Component]]"
  - "[[State_Machine_Component]]"
  - "[[AI_Behavior_Component]"
---

# Component Architecture Pattern

## Purpose
Enable reusable, composable behaviors through node attachment rather than inheritance. Reduces code duplication and enables emergent bot combinations.

## Core Rules

### Component Structure
```gdscript
class_name HealthComponent
extends Node

@export var max_health: int = 100
var current_health: int

signal health_changed(new: int, max: int)
signal died()

func damage(amount: int) -> void:
    current_health = maxi(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    if current_health <= 0:
        died.emit()
```

### Attachment Pattern
- Components attach as child nodes
- Parent queries component via `has_node()` or `get_node()`
- Components query parent for context
- No hardcoded paths: use `@onready var parent: Bot = get_parent()`

### Standard Components
| Component | Responsibility | Used By |
|-----------|---------------|---------|
| `HealthComponent` | HP, damage, death | All bots |
| `StateMachine` | State transitions, validation | AI behaviors |
| `SpriteComponent` | Visual representation | All entities |
| `AnimationComponent` | State-based animations | All entities |

## Failure Modes

### Coupling Leak
**Symptom:** Component directly references sibling components
**Fix:** Components talk through parent only

### Initialization Order Bug
**Symptom:** Component tries to access parent in `_init()`
**Fix:** Use `_ready()` for parent references

### Type Safety Loss
**Symptom:** `get_parent()` returns `Node` instead of typed class
**Fix:** Cast with `as Bot` or use `@onready var parent: Bot`

## Enforcement

### Code Review Check
- All components use `class_name`
- All exported vars have types
- Parent references typed and cached
- Signals used for cross-component communication

## Related
[[Godot_Node_Lifecycle]]
[[Signal_Based_Communication]]
[[Type_Safety_In_GDScript]]
