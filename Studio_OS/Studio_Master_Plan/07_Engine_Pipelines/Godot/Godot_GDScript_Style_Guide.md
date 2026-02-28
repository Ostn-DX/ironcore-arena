---
title: Godot GDScript Style Guide
type: rule
layer: enforcement
status: active
tags:
  - godot
  - gdscript
  - style
  - conventions
  - code-quality
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Project_Layout_Conventions]"
used_by:
  - "[Godot_Lint_Static_Checks]]"
  - "[[Godot_GUT_Test_Framework]"
---

# Godot GDScript Style Guide

Consistent code style enables AI agents to read, modify, and generate GDScript predictably. This guide extends the official Godot style with studio-specific conventions for the AI-Native Game Studio OS.

## Naming Conventions

### Files
```
# Correct
player.gd
main_menu.tscn
weapon_data.tres

# Incorrect
Player.gd
MainMenu.tscn
weaponData.tres
```

### Classes
```gdscript
# Use PascalCase for class_name
class_name PlayerController
class_name InventorySystem
class_name SaveManager
```

### Variables
```gdscript
# snake_case for all variables
var player_health: int = 100
var movement_speed: float = 5.0
var is_invincible: bool = false

# Private prefix with underscore
var _internal_state: Dictionary = {}
var _cached_value: float = 0.0

# Constants in UPPER_SNAKE_CASE
const MAX_HEALTH := 100
const DEFAULT_SPEED := 5.0
const TICK_RATE := 60
```

### Functions
```gdscript
# snake_case for functions
func take_damage(amount: int) -> void:
func calculate_trajectory(start: Vector2, end: Vector2) -> Vector2:
func is_alive() -> bool:

# Private functions with underscore prefix
func _update_physics() -> void:
func _handle_input() -> void:
```

### Signals
```gdscript
# Past tense for completed actions
signal health_changed(new_health: int, delta: int)
signal died()
signal item_collected(item: ItemData)

# Future tense for requests
signal save_requested(slot: int)
signal pause_requested()
```

### Enums
```gdscript
# Enum names in PascalCase, values in UPPER_SNAKE_CASE
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
enum Difficulty { EASY, NORMAL, HARD, NIGHTMARE }

# Usage
var current_state: GameState = GameState.MENU
```

## Code Structure

### File Organization
```gdscript
extends BaseClass
class_name MyClass

# 1. Constants
const MAX_COUNT := 10

# 2. Exported variables (visible in editor)
@export var health: int = 100
@export var speed: float = 5.0

# 3. Public variables
var is_active: bool = true

# 4. Private variables
var _internal_counter: int = 0

# 5. Onready variables
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# 6. Built-in virtual functions
func _init() -> void:
    pass

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    pass

# 7. Public functions
func activate() -> void:
    is_active = true

# 8. Private functions
func _calculate_value() -> float:
    return 0.0
```

### Function Structure
```gdscript
func do_something(param1: Type1, param2: Type2) -> ReturnType:
    # Early returns for guard clauses
    if not is_valid:
        return default_value
    
    # Main logic
    var result := _process_data(param1, param2)
    
    # Return statement
    return result
```

## Type Safety

### Static Typing
```gdscript
# Always use static typing
var health: int = 100
var position: Vector2 = Vector2.ZERO
var player: Player = null

# Function signatures must be typed
func take_damage(amount: int) -> void:
func get_position() -> Vector2:
func find_target() -> Node2D:

# Return types even for void
func update_ui() -> void:
```

### Type Inference
```gdscript
# Use := for local variables when type is obvious
var damage := 10  # Inferred as int
var position := Vector2(100, 200)  # Inferred as Vector2
var player := get_node("Player") as Player  # Explicit cast

# Don't use := when type isn't clear
var data  # Use explicit: var data: Dictionary
var result  # Use explicit: var result: Error
```

## Comments

### Documentation Comments
```gdscript
# Brief description of the class
# Longer explanation if needed
class_name Player

# Brief description
# @param amount: Description of parameter
# @returns: Description of return value
func heal(amount: int) -> int:
    health += amount
    return health
```

### Inline Comments
```gdscript
# Explain WHY, not WHAT
# Correct: Compensate for frame time variance
velocity *= 1.0 + delta * compensation_factor

# Incorrect: Multiply velocity by factor
velocity *= 1.0 + delta * compensation_factor
```

## Best Practices

### Node References
```gdscript
# Use @onready for node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $UI/HealthBar

# Use unique names for deep paths
@onready var deep_node: Node = %UniqueNodeName

# Cache expensive lookups
var _players: Array[Player] = []

func _ready() -> void:
    _players = get_tree().get_nodes_in_group("players")
```

### Signals
```gdscript
# Connect in _ready, disconnect in _exit_tree
func _ready() -> void:
    EventBus.player_damaged.connect(_on_player_damaged)

func _exit_tree() -> void:
    EventBus.player_damaged.disconnect(_on_player_damaged)

# Handler naming: _on_[emitter]_[signal]
func _on_player_damaged(amount: int, source: String) -> void:
    pass
```

### Groups
```gdscript
# Add to groups in _ready
func _ready() -> void:
    add_to_group("enemies")
    add_to_group("damageable")

# Use groups for efficient queries
var enemies := get_tree().get_nodes_in_group("enemies")
```

### Performance Patterns
```gdscript
# Cache node paths
@onready var _sprite: Sprite2D = $Sprite2D

# Use local variables in loops
for i in range(count):
    var local_pos := positions[i]
    _process_position(local_pos)

# Avoid repeated property access
var transform := global_transform
for i in range(10):
    use_transform(transform)

# Use const for literals
const ITERATIONS := 100
for i in range(ITERATIONS):
    pass
```

### Error Handling
```gdscript
# Check and handle errors
var file := FileAccess.open(path, FileAccess.READ)
if file == null:
    push_error("Failed to open file: " + path)
    return ERR_FILE_CANT_OPEN

# Use Error return type
func load_data(path: String) -> Error:
    if not FileAccess.file_exists(path):
        return ERR_FILE_NOT_FOUND
    return OK
```

## Anti-Patterns

### Avoid Global State Access
```gdscript
# Incorrect - hidden dependency
func take_damage(amount: int) -> void:
    health -= amount
    GameState.total_damage += amount  # Hidden side effect!

# Correct - explicit parameter
func take_damage(amount: int, stats_tracker: StatsTracker = null) -> void:
    health -= amount
    if stats_tracker:
        stats_tracker.record_damage(amount)
```

### Avoid Deep Nesting
```gdscript
# Incorrect - pyramid of doom
func process() -> void:
    if is_active:
        if has_target:
            if can_attack:
                attack()

# Correct - early returns
func process() -> void:
    if not is_active:
        return
    if not has_target:
        return
    if not can_attack:
        return
    attack()
```

### Avoid Magic Numbers
```gdscript
# Incorrect
if health < 25:
    play_low_health_effect()

# Correct
const LOW_HEALTH_THRESHOLD := 25
if health < LOW_HEALTH_THRESHOLD:
    play_low_health_effect()
```

## Enforcement

### Pre-commit Hook
```bash
#!/bin/bash
# scripts/hooks/pre-commit-style

# Check for untyped functions
if grep -r "func.*):" --include="*.gd" src/ | grep -v "->"; then
    echo "ERROR: Functions must have return type annotations"
    exit 1
fi

# Check naming conventions
# ... additional checks
```

### CI Validation
The [[Godot_Lint_Static_Checks]] pipeline validates all style rules.

## See Also

- [[Godot_Lint_Static_Checks]] - Automated style enforcement
- [[Godot_Project_Layout_Conventions]] - File organization
- [[Godot_GUT_Test_Framework]] - Testing patterns
