---
title: Godot Autoload Conventions
type: rule
layer: architecture
status: active
tags:
  - godot
  - autoload
  - singleton
  - globals
  - architecture
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Project_Layout_Conventions]"
used_by:
  - "[Godot_Deterministic_Fixed_Timestep]]"
  - "[[Godot_GDScript_Style_Guide]"
---

# Godot Autoload Conventions

Autoloads (singletons) in Godot provide global access to systems and state. Misuse creates hidden dependencies, testing difficulties, and coupling. This convention defines when and how to use autoloads correctly.

## The Autoload Problem

Autoloads are convenient but dangerous:
- **Hidden dependencies**: `GameState.player_health` is invisible in function signatures
- **Testing difficulty**: Tests must mock or reset global state
- **Tight coupling**: Changes to autoloads ripple through entire codebase
- **Initialization order**: Complex dependencies create fragile startup sequences

## The 8-Autoload Limit

**Rule**: Maximum 8 autoloads per project. This forces intentional design and prevents singleton abuse.

Current autoload slots:

| Slot | Name | Purpose | Order |
|------|------|---------|-------|
| 1 | `Types` | Constants, enums, type definitions | 1 |
| 2 | `EventBus` | Decoupled event system | 2 |
| 3 | `GameState` | Global game state | 3 |
| 4 | `SaveManager` | Save/load persistence | 4 |
| 5 | `SceneManager` | Scene transitions | 5 |
| 6 | `AudioManager` | Audio playback | 6 |
| 7 | `InputManager` | Input abstraction | 7 |
| 8 | `RESERVED` | Project-specific need | 8 |

## Autoload Specifications

### Types (Slot 1)
```gdscript
# src/autoload/types.gd
extends Node

# All game enums in one location
enum GameMode { CAMPAIGN, ENDLESS, SANDBOX }
enum Difficulty { EASY, NORMAL, HARD, NIGHTMARE }

# Constants
const MAX_PLAYERS := 4
const TICK_RATE := 60

# Custom types for type hints
class_name PlayerData
var health: int
var position: Vector2
```

**Purpose**: Central type definitions prevent circular dependencies.

### EventBus (Slot 2)
```gdscript
# src/autoload/event_bus.gd
extends Node

# Decoupled event system using signals
signal player_damaged(amount: int, source: String)
signal enemy_defeated(enemy_type: String, position: Vector2)
signal level_completed(level_id: String)
signal game_saved()
signal game_loaded()

# Usage: EventBus.player_damaged.emit(10, "slime")
```

**Purpose**: Eliminate direct coupling between systems.

### GameState (Slot 3)
```gdscript
# src/autoload/game_state.gd
extends Node

# Minimal global state - prefer component state
var current_level: String = ""
var game_mode: Types.GameMode = Types.GameMode.CAMPAIGN
var session_start_time: int = 0

# Accessed via GameState.current_level
# Modified via GameState.set_current_level(value)
```

**Rule**: GameState contains only truly global data. Entity state belongs in entities.

### SaveManager (Slot 4)
```gdscript
# src/autoload/save_manager.gd
extends Node

const SAVE_PATH := "user://saves/"

func save_game(slot: int) -> Error:
    var data := _collect_save_data()
    return _write_save_file(slot, data)

func load_game(slot: int) -> Error:
    var data := _read_save_file(slot)
    return _apply_save_data(data)

func _collect_save_data() -> Dictionary:
    # Gather data from all savable systems
    return {
        "game_state": _serialize_game_state(),
        "player": _serialize_player(),
        "level": _serialize_level()
    }
```

**Pattern**: SaveManager knows how to serialize; entities provide data.

### SceneManager (Slot 5)
```gdscript
# src/autoload/scene_manager.gd
extends Node

signal scene_changed(new_scene: String)

var _current_scene: Node = null
var _loading_screen: PackedScene = preload("res://src/ui/screens/loading_screen.tscn")

func change_scene(path: String, transition: bool = true) -> void:
    if transition:
        await _do_transition(path)
    else:
        _load_scene(path)

func _load_scene(path: String) -> void:
    var scene := load(path) as PackedScene
    var instance := scene.instantiate()
    get_tree().root.add_child(instance)
    _current_scene = instance
    scene_changed.emit(path)
```

**Pattern**: Handles scene lifecycle, transitions, and cleanup.

### AudioManager (Slot 6)
```gdscript
# src/autoload/audio_manager.gd
extends Node

@export var music_bus: StringName = "Music"
@export var sfx_bus: StringName = "SFX"

var _music_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []

func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
    # Crossfade implementation
    pass

func play_sfx(stream: AudioStream, position: Vector2 = Vector2.ZERO) -> void:
    # Pool-based SFX playback
    pass
```

**Pattern**: Abstracts audio system, handles pooling and mixing.

### InputManager (Slot 7)
```gdscript
# src/autoload/input_manager.gd
extends Node

# Input action abstraction for remapping support
signal action_pressed(action: StringName)
signal action_released(action: StringName)

var _action_map: Dictionary = {}

func is_action_pressed(action: StringName) -> bool:
    return Input.is_action_pressed(_action_map.get(action, action))

func remap_action(action: StringName, event: InputEvent) -> void:
    _action_map[action] = event
```

**Pattern**: Enables runtime input remapping and action abstraction.

## What NOT to Autoload

| Anti-Pattern | Why | Solution |
|--------------|-----|----------|
| Player singleton | Player is a scene instance | Reference via node path or signal |
| Enemy manager | Use groups or spawn system | Group: `get_tree().get_nodes_in_group("enemies")` |
| Camera singleton | Camera is a scene node | Use RemoteTransform or viewport tracking |
| Inventory singleton | Belongs to player | Component on player node |
| Quest system | Large, complex state | Scene-based system with EventBus communication |

## Access Patterns

### Correct: Signal-Based Communication
```gdscript
# In enemy.gd - NO direct autoload access
func _on_health_depleted() -> void:
    EventBus.enemy_defeated.emit(enemy_type, global_position)
    queue_free()

# In game_state.gd - listens to events
func _ready() -> void:
    EventBus.enemy_defeated.connect(_on_enemy_defeated)

func _on_enemy_defeated(type: String, pos: Vector2) -> void:
    enemies_defeated += 1
```

### Incorrect: Direct Autoload Access
```gdscript
# Anti-pattern - hidden dependency
func take_damage(amount: int) -> void:
    health -= amount
    GameState.total_damage_taken += amount  # Hidden side effect!
    if health <= 0:
        GameState.enemies_defeated += 1  # Another hidden dependency!
```

## Testing with Autoloads

### Reset Pattern
```gdscript
# In test setup
func before_each() -> void:
    GameState.reset()  # Clear all state
    EventBus.clear_connections()  # Disconnect all signals
```

### Mock Pattern
```gdscript
# Replace autoload for isolated tests
func test_with_mock_audio() -> void:
    var mock_audio = MockAudioManager.new()
    AudioManager.free()
    get_tree().root.add_child(mock_audio)
    # Run tests...
```

## Initialization Order

Autoloads initialize in Project Settings order. Dependencies must respect this:

```gdscript
# In GameState.gd - wait for dependencies
func _ready() -> void:
    # Types is already initialized (order 1)
    # EventBus is already initialized (order 2)
    await get_tree().process_frame  # Wait one frame if needed
    _initialize_state()
```

## Enforcement

### CI Check
```bash
# Count autoloads in project.godot
grep -c "autoload" project.godot
# Must be <= 8
```

### Code Review Checklist
- [ ] New global need justified in PR description
- [ ] Could this be a component instead?
- [ ] Does it use EventBus for communication?
- [ ] Is it testable with reset/mock patterns?

## See Also

- [[Godot_Project_Layout_Conventions]] - Folder structure
- [[Godot_GDScript_Style_Guide]] - Code style
- [[Godot_GUT_Test_Framework]] - Testing patterns
