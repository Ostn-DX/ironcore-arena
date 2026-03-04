# Ironcore Arena - Code Conventions

## Naming

### Files
- GDScript: `snake_case.gd`
- Scenes: `snake_case.tscn`
- Resources: `PascalCase.tres` (matches class name)
- JSON: `snake_case.json`

### Code
```gdscript
# Classes
class_name BotController

# Constants
const MAX_HEALTH: int = 100
const TICKS_PER_SECOND: float = 60.0

# Variables
var current_health: int
var _private_var: String
@onready var cached_node: Node

# Functions
func take_damage(amount: int) -> void:
func calculate_score(base: float, multiplier: float) -> float:
func _private_helper() -> bool:

# Signals
signal health_changed(new_health: int, max_health: int)
signal bot_destroyed(bot_id: int)

# Enums
enum State { IDLE, MOVING, ATTACKING }
enum WeaponType { MACHINE_GUN, CANNON, BEAM }
```

## Formatting

### Indentation
- Tabs for indentation (Godot standard)
- 4 spaces visually in editor

### Spacing
```gdscript
# Bad
func foo()->void:
    var x=1+2

# Good
func foo() -> void:
    var x: int = 1 + 2
```

### Line Length
- Soft limit: 100 characters
- Hard limit: 120 characters
- Break long lines at logical points

## Documentation

### File Header
```gdscript
## Brief description of the script's purpose.
## Longer explanation if needed, max 2-3 lines.
## Dependencies: references to other systems.
```

### Functions
```gdscript
## Calculate damage with armor mitigation.
## Returns final damage after all modifiers.
func calculate_damage(base_damage: int, armor: int) -> int:
```

### Complex Logic
```gdscript
# Calculate weight penalty: heavier = slower
# Formula: speed_mult = 1 - (weight / capacity * 0.5)
var speed_multiplier: float = 1.0 - (current_weight / weight_capacity * 0.5)
```

## Type Safety

### Required Everywhere
```gdscript
# Variables
var health: int = 100
var speed: float = 5.0
var bot: Bot
var bots: Array[Bot] = []
var data: Dictionary = {}

# Function signatures
func spawn_bot(position: Vector2, team: int) -> Bot:
func get_bots_in_range(center: Vector2, radius: float) -> Array[Bot]:
```

### Optional (Nullable)
```gdscript
var target_bot: Bot = null  # OK: explicitly null
var maybe_data: Variant     # OK: when type truly varies
```

## Error Handling

### Guard Clauses
```gdscript
func damage_target(target: Bot, amount: int) -> void:
    if not is_instance_valid(target):
        push_error("Invalid target in damage_target")
        return
    
    if amount <= 0:
        return
    
    target.take_damage(amount)
```

### Assertions (Debug Only)
```gdscript
assert(speed > 0, "Speed must be positive")
assert(bot != null, "Bot is required")
```

## Performance

### Hot Path Avoidances
```gdscript
# Bad: allocation in loop
for i in range(100):
    var arr: Array = []  # New allocation each iteration

# Good: reuse
var arr: Array = []
for i in range(100):
    arr.clear()
```

### Caching
```gdready
@onready var _game_state: GameState = get_node("/root/GameState")
@onready var _event_bus: EventBus = get_node("/root/EventBus")
```

## Scene Organization

### Node Naming
- PascalCase for node names in scene
- Descriptive: `HealthBar`, not `Control2`

### Script Attachment
- One script per scene root (usually)
- Sub-nodes use `@onready` to find siblings/children

## JSON Data

### Schema
Always include `version` field:
```json
{
  "version": "1.0.0",
  "items": [...]
}
```

### IDs
- Use `snake_case` IDs
- Prefix with category: `chassis_light_t1`, `wpn_mg_t1`

## Git

### Commits
- Present tense: "Add headless match runner"
- Specific: "Fix division by zero in speed calculation"
- No: "Fix bug", "Update", "WIP"

### Branches
- `main` - stable, playable
- `feature/description` - new features
- `fix/description` - bug fixes
