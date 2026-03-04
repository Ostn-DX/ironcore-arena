---
title: Code_Conventions_Standard
type: rule
layer: enforcement
status: active
tags:
  - conventions
  - style
  - gdscript
  - quality
depends_on: []
used_by:
  - "[Lint_Agent]]"
  - "[[Code_Review_Checklist]"
---

# Code Conventions Standard

## Purpose
Maintain consistent, readable, maintainable codebase across all contributors and agents. Reduces cognitive load and prevents common errors.

## Core Rules

### Naming

| Element | Format | Example |
|---------|--------|---------|
| Class | PascalCase | `class_name BotController` |
| Constant | UPPER_SNAKE | `const MAX_HEALTH: int = 100` |
| Variable | snake_case | `var current_health: int` |
| Private | _prefix | `var _internal_state: bool` |
| Function | snake_case | `func take_damage(amount: int)` |
| Signal | snake_case | `signal health_changed(new, max)` |
| File | snake_case.gd | `bot_controller.gd` |

### Type Safety

**Required:**
```gdscript
var health: int = 100
var speed: float = 5.0
func damage(amount: int) -> void:
func get_bots() -> Array[Bot]:
```

**Forbidden:**
```gdscript
var health = 100  # Untyped
func damage(amount):  # No return type
```

### Documentation

```gdscript
## Brief description of purpose.
## Longer explanation if needed (2-3 lines max).
class_name BotController
extends Node

## Apply damage and emit health_changed signal.
## Returns true if bot died from this damage.
func take_damage(amount: int) -> bool:
```

### Error Handling

```gdscript
func process_target(target: Node) -> void:
    if not is_instance_valid(target):
        push_error("Invalid target in process_target")
        return
    
    if target.is_queued_for_deletion():
        return
    
    # Process valid target
```

### Performance

```gdscript
# Cache lookups
@onready var _game_state: GameState = get_node("/root/GameState")

# Reuse arrays
var _buffer: Array = []
func process() -> void:
    _buffer.clear()
    # Use _buffer, don't create new Array
```

## Enforcement

### Automated
- [[Lint_Agent]] checks naming and types
- CI fails on convention violations

### Manual
- Code review checklist includes conventions
- Architect reviews major deviations

## Related
[[GDScript_Style_Guide]]
[[Type_Safety_In_GDScript]]
[[Documentation_Standards]]
