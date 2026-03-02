---
title: Godot Deterministic Fixed Timestep
type: rule
layer: enforcement
status: active
tags:
  - godot
  - determinism
  - fixed-timestep
  - 60hz
  - replay
  - multiplayer
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Autoload_Conventions]"
used_by:
  - "[Godot_Headless_Sim_Runner_Spec]]"
  - "[[Godot_GUT_Test_Framework]"
---

# Godot Deterministic Fixed Timestep

Deterministic simulation ensures identical inputs produce identical outputs across runs, platforms, and time. This enables replay systems, networked multiplayer with lockstep, and reproducible testing. This rule enforces 60Hz fixed timestep determinism in Godot 4.x.

## Why Determinism Matters

| Use Case | Determinism Requirement |
|----------|------------------------|
| Replay system | Same inputs → same outputs |
| Lockstep multiplayer | All clients stay synchronized |
| Regression testing | Tests produce same results |
| AI training | Reproducible episodes |
| Bug reproduction | Exact state recreation |
| Speedrunning validation | Verifiable runs |

## The Determinism Challenge

Godot's default behavior is NON-deterministic:
- `delta` varies per frame
- `randf()` uses global state
- Floating-point varies by CPU
- Physics timestep defaults to variable

## 60Hz Fixed Timestep Configuration

### Project Settings (project.godot)
```ini
[physics]
common/physics_ticks_per_second=60
common/max_physics_steps_per_frame=8
common/physics_jitter_fix=0.5

[application]
run/max_fps=60
run/delta_smoothing=false
```

### Physics Process Only
```gdscript
# CORRECT: Use _physics_process for game logic
func _physics_process(delta: float) -> void:
    # delta is ALWAYS 1/60 ≈ 0.016667
    _update_game_logic()
    _apply_movement()
```

```gdscript
# WRONG: _process has variable delta
func _process(delta: float) -> void:
    # delta varies: 0.008, 0.020, 0.016...
    _update_game_logic()  # NON-DETERMINISTIC!
```

## Deterministic Random

### Seeded RNG
```gdscript
# src/core/deterministic_rng.gd
class_name DeterministicRNG

var _state: int = 0

func seed(value: int) -> void:
    _state = value

func random() -> float:
    # Xorshift32 - deterministic across platforms
    _state ^= _state << 13
    _state ^= _state >> 17
    _state ^= _state << 5
    return float(_state & 0x7FFFFFFF) / 0x7FFFFFFF

func random_range(min_val: float, max_val: float) -> float:
    return min_val + random() * (max_val - min_val)

func random_int(max_val: int) -> int:
    return int(random() * max_val)
```

### Usage Pattern
```gdscript
# In entity that needs randomness
var _rng: DeterministicRNG = DeterministicRNG.new()

func _ready() -> void:
    # Seed from deterministic source (frame count, position hash, etc.)
    _rng.seed(hash(global_position) + GameState.current_seed)

func take_damage() -> void:
    var crit := _rng.random() < 0.1  # Deterministic!
```

## Input Synchronization

### Input Frame Queue
```gdscript
# src/core/input_buffer.gd
class_name InputBuffer

var _inputs: Array[Dictionary] = []
var _current_frame: int = 0

func record_input(frame: int, actions: Dictionary) -> void:
    _inputs.append({"frame": frame, "actions": actions})

func get_input_for_frame(frame: int) -> Dictionary:
    for input in _inputs:
        if input.frame == frame:
            return input.actions
    return {}

func serialize() -> String:
    return JSON.stringify(_inputs)

func deserialize(data: String) -> void:
    _inputs = JSON.parse_string(data)
```

### Input Recording/Playback
```gdscript
# In main game controller
var _input_buffer: InputBuffer = InputBuffer.new()
var _playback_mode: bool = false
var _playback_data: Array[Dictionary] = []

func _physics_process(_delta: float) -> void:
    var frame := Engine.get_physics_frames()
    
    if _playback_mode:
        _apply_input(_playback_data[frame])
    else:
        var input := _capture_input()
        _input_buffer.record_input(frame, input)
        _apply_input(input)
```

## Floating-Point Determinism

### Fixed-Point Alternative
```gdscript
# src/core/fixed_point.gd
class_name FixedPoint

const PRECISION := 1000

static func to_fixed(value: float) -> int:
    return int(value * PRECISION)

static func from_fixed(value: int) -> float:
    return float(value) / PRECISION

static func fixed_mul(a: int, b: int) -> int:
    return (a * b) / PRECISION
```

### When to Use Fixed-Point
| Scenario | Recommendation |
|----------|----------------|
| Position comparison | Use fixed-point |
| Physics calculations | Use Godot's physics (deterministic at 60Hz) |
| Visual rendering | Float is fine (not part of sim) |
| Score/currency | Integer only |

## Physics Determinism

### RigidBody2D Constraints
```gdscript
# For deterministic physics
@export var _use_deterministic_physics: bool = true

func _ready() -> void:
    if _use_deterministic_physics:
        # Disable features that break determinism
        gravity_scale = 1.0  # No random variation
        linear_damp = 0.0    # Handle damping manually
        angular_damp = 0.0
```

### Collision Layer Consistency
```gdscript
# Always set layers in code, not inspector (for version control)
const LAYER_PLAYER := 1
const LAYER_ENEMY := 2
const LAYER_WALL := 3

func _ready() -> void:
    collision_layer = 1 << (LAYER_PLAYER - 1)
    collision_mask = (1 << (LAYER_ENEMY - 1)) | (1 << (LAYER_WALL - 1))
```

## Replay System

### Recording
```gdscript
func save_replay(filename: String) -> void:
    var replay := {
        "version": 1,
        "seed": GameState.initial_seed,
        "inputs": _input_buffer.serialize(),
        "duration_frames": Engine.get_physics_frames()
    }
    var file := FileAccess.open(filename, FileAccess.WRITE)
    file.store_string(JSON.stringify(replay))
```

### Validation
```gdscript
func validate_replay(filename: String) -> bool:
    var replay := _load_replay(filename)
    
    # Reset to initial state
    GameState.reset()
    GameState.initial_seed = replay.seed
    
    # Run simulation
    _playback_mode = true
    _playback_data = JSON.parse_string(replay.inputs)
    
    for frame in replay.duration_frames:
        _physics_process(1.0 / 60.0)
    
    # Compare final state
    return _hash_game_state() == replay.final_state_hash
```

## CI Determinism Testing

### Replay Regression Test
```gdscript
# In GUT test
func test_determinism() -> void:
    var replay_file := "res://src/tests/fixtures/test_replay.json"
    
    # Run once
    var result1 := _run_replay(replay_file)
    
    # Run again
    var result2 := _run_replay(replay_file)
    
    # Must be identical
    assert_eq(result1.final_hash, result2.final_hash)
    assert_eq(result1.final_position, result2.final_position)
```

### Headless Determinism Check
```bash
# Run in CI
./scripts/test_determinism.sh --replay test_replay.json --iterations 10
# All 10 runs must produce identical final state hashes
```

## Common Non-Determinism Sources

| Source | Fix |
|--------|-----|
| `randf()` | Use `DeterministicRNG` |
| `OS.get_time()` | Use frame count |
| `get_instance_id()` | Don't use in simulation logic |
| Dictionary iteration order | Use `OrderedDictionary` or sort keys |
| Floating-point math | Use fixed-point for comparisons |
| `await` timing | Use frame-based delays |
| Node `_ready()` order | Explicit initialization sequence |

## Enforcement

### Static Analysis Rule
```python
# In linter - flag non-deterministic patterns
BANNED_PATTERNS = [
    "randf()",
    "randi()",
    "randomize()",
    "OS.get_time()",
    "Time.get_time_dict_from_system()"
]
```

### Runtime Detection (Debug Only)
```gdscript
# src/core/determinism_checker.gd
class_name DeterminismChecker

var _state_hashes: Array[int] = []

func _physics_process(_delta: float) -> void:
    if OS.is_debug_build():
        var hash := _compute_state_hash()
        _state_hashes.append(hash)
        
        # Warn if hash varies unexpectedly
        if _state_hashes.size() > 1:
            var prev := _state_hashes[_state_hashes.size() - 2]
            if hash != prev and _should_be_deterministic():
                push_warning("Non-deterministic state detected!")
```

## See Also

- [[Godot_Headless_Sim_Runner_Spec]] - Headless testing
- [[Godot_GUT_Test_Framework]] - Unit testing with determinism
- [[Godot_Autoload_Conventions]] - Global systems organization
