---
title: Godot Headless Sim Runner Spec
type: system
layer: execution
status: active
tags:
  - godot
  - headless
  - testing
  - simulation
  - automation
  - ci
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Deterministic_Fixed_Timestep]"
used_by:
  - "[Godot_GUT_Test_Framework]]"
  - "[[Godot_CI_Template]"
---

# Godot Headless Sim Runner Spec

The Headless Sim Runner executes Godot simulations without display, audio, or user interaction. This enables fast, deterministic testing in CI environments and local development without window management overhead.

## Purpose

- Run game logic tests without GPU/display requirements
- Validate simulation determinism across runs
- Enable CI testing on headless servers
- Support batch testing of multiple scenarios
- Provide fast feedback during development

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Headless Sim Runner                     │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Test Loader  │→ │ Scene Runner │→ │ State Assert │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓                 ↓                 ↓           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ JSON Config  │  │ Frame Adv.   │  │ Report Gen   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Command-Line Interface

### Basic Usage
```bash
# Run a single simulation test
godot --headless --script src/tests/runners/headless_sim.gd \
    --scene=res://src/tests/scenes/combat_test.tscn \
    --frames=3600 \
    --output=results.json

# Run test suite from config
godot --headless --script src/tests/runners/headless_sim.gd \
    --config=res://src/tests/configs/combat_suite.json

# Validate determinism with multiple runs
godot --headless --script src/tests/runners/headless_sim.gd \
    --scene=res://src/tests/scenes/determinism_test.tscn \
    --iterations=10 \
    --compare-hashes
```

### CLI Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--scene` | Path to test scene | Required |
| `--frames` | Frames to simulate | 600 (10 sec @ 60Hz) |
| `--config` | JSON config file path | None |
| `--output` | Output file for results | stdout |
| `--iterations` | Number of runs for determinism | 1 |
| `--compare-hashes` | Compare state hashes across runs | false |
| `--speed` | Simulation speed multiplier | 1.0 |
| `--timeout` | Max seconds before failure | 300 |

## Test Scene Structure

### Minimal Test Scene
```gdscript
# src/tests/scenes/base_sim_test.gd
class_name BaseSimTest
extends Node2D

# Required interface for headless runner
func get_test_name() -> String:
    return "base_sim_test"

func get_expected_duration_frames() -> int:
    return 600

func get_state_hash() -> int:
    # Return hash of all relevant state
    return hash(str(_get_state_dict()))

func _get_state_dict() -> Dictionary:
    return {
        "frame": Engine.get_physics_frames(),
        "entities": _get_entity_states()
    }

func _get_entity_states() -> Array:
    var states := []
    for entity in get_tree().get_nodes_in_group("test_entities"):
        states.append({
            "type": entity.get_class(),
            "position": entity.global_position,
            "health": entity.get("health")
        })
    return states

func is_test_complete() -> bool:
    # Return true when test can end early
    return false

func get_test_result() -> Dictionary:
    # Return test-specific results
    return {
        "passed": true,
        "metrics": _collect_metrics()
    }
```

### Combat Test Example
```gdscript
# src/tests/scenes/combat_test.gd
extends BaseSimTest

@onready var _player: Node2D = $Player
@onready var _enemies: Node = $Enemies

var _enemies_defeated: int = 0

func _ready() -> void:
    EventBus.enemy_defeated.connect(_on_enemy_defeated)

func _on_enemy_defeated(_type: String, _pos: Vector2) -> void:
    _enemies_defeated += 1

func is_test_complete() -> bool:
    # Test complete when all enemies defeated
    return _enemies_defeated >= _enemies.get_child_count()

func get_test_result() -> Dictionary:
    var duration_frames := Engine.get_physics_frames()
    return {
        "passed": _enemies_defeated >= 5,
        "enemies_defeated": _enemies_defeated,
        "duration_frames": duration_frames,
        "player_health": _player.health
    }
```

## Runner Implementation

### Core Runner Script
```gdscript
# src/tests/runners/headless_sim.gd
extends SceneTree

var _config: Dictionary = {}
var _results: Array[Dictionary] = []
var _current_iteration: int = 0

func _initialize() -> void:
    _parse_arguments()
    
    if _config.has("config_file"):
        _load_config_file(_config.config_file)
    
    _run_tests()

func _parse_arguments() -> void:
    var args := OS.get_cmdline_args()
    for i in range(args.size()):
        match args[i]:
            "--scene":
                _config.scene = args[i + 1]
            "--frames":
                _config.frames = args[i + 1].to_int()
            "--config":
                _config.config_file = args[i + 1]
            "--iterations":
                _config.iterations = args[i + 1].to_int()
            "--compare-hashes":
                _config.compare_hashes = true

func _run_tests() -> void:
    var iterations := _config.get("iterations", 1)
    
    for i in range(iterations):
        _current_iteration = i
        var result := _run_single_test()
        _results.append(result)
    
    if _config.get("compare_hashes", false) and iterations > 1:
        _validate_determinism()
    
    _output_results()
    quit()

func _run_single_test() -> Dictionary:
    # Load and instance test scene
    var scene := load(_config.scene) as PackedScene
    var instance := scene.instantiate() as BaseSimTest
    
    root.add_child(instance)
    
    var max_frames := _config.get("frames", 600)
    var frame := 0
    
    # Run simulation
    while frame < max_frames and not instance.is_test_complete():
        _physics_process(1.0 / 60.0)
        frame += 1
    
    # Collect results
    var result := {
        "iteration": _current_iteration,
        "frames_run": frame,
        "state_hash": instance.get_state_hash(),
        "test_result": instance.get_test_result()
    }
    
    instance.queue_free()
    return result

func _validate_determinism() -> void:
    var first_hash := _results[0].state_hash
    for result in _results:
        if result.state_hash != first_hash:
            push_error("Determinism failure: hash mismatch")
            _results.append({"determinism_passed": false})
            return
    _results.append({"determinism_passed": true})

func _output_results() -> void:
    var output := JSON.stringify({
        "config": _config,
        "results": _results,
        "summary": _generate_summary()
    }, "  ")
    
    if _config.has("output"):
        var file := FileAccess.open(_config.output, FileAccess.WRITE)
        file.store_string(output)
    else:
        print(output)
```

## Configuration Format

### Test Suite JSON
```json
{
  "suite_name": "combat_regression",
  "timeout_seconds": 300,
  "tests": [
    {
      "name": "player_vs_slime",
      "scene": "res://src/tests/scenes/combat_slime.tscn",
      "frames": 600,
      "assertions": [
        {"type": "state_hash", "expected": "abc123"},
        {"type": "metric_gte", "path": "player_health", "value": 50}
      ]
    },
    {
      "name": "player_vs_boss",
      "scene": "res://src/tests/scenes/combat_boss.tscn",
      "frames": 3600,
      "iterations": 3,
      "compare_hashes": true
    }
  ]
}
```

## CI Integration

### GitHub Actions Step
```yaml
- name: Run Headless Sim Tests
  run: |
    godot --headless --script src/tests/runners/headless_sim.gd \
      --config=src/tests/configs/ci_suite.json \
      --output=sim_results.json
    
    # Validate results
    python scripts/validate_sim_results.py sim_results.json
```

### Local Test Script
```bash
#!/bin/bash
# scripts/test_sim.sh

CONFIG=${1:-"src/tests/configs/default.json"}
OUTPUT="builds/test_results/sim_$(date +%Y%m%d_%H%M%S).json"

mkdir -p builds/test_results

echo "Running headless simulation tests..."
godot --headless --script src/tests/runners/headless_sim.gd \
    --config="$CONFIG" \
    --output="$OUTPUT"

if [ $? -eq 0 ]; then
    echo "Tests passed: $OUTPUT"
    exit 0
else
    echo "Tests failed. See: $OUTPUT"
    exit 1
fi
```

## Performance Benchmarks

| Test Type | Frames | Local Time | CI Time |
|-----------|--------|------------|---------|
| Unit sim | 600 | ~1s | ~2s |
| Combat scenario | 3600 | ~5s | ~8s |
| Level completion | 10800 | ~15s | ~25s |
| Full determinism (10x) | 6000 | ~10s | ~20s |

## Failure Modes

| Failure | Detection | Resolution |
|---------|-----------|------------|
| Scene load error | Exception on load | Check scene path and dependencies |
| Infinite loop | Timeout exceeded | Add completion condition |
| Memory leak | Process memory growth | Proper cleanup in test scenes |
| Determinism failure | Hash mismatch | Check [[Godot_Deterministic_Fixed_Timestep]] |
| Missing assertions | Empty result | Add test assertions |

## See Also

- [[Godot_UI_Smoke_Runner_Spec]] - UI automation testing
- [[Godot_GUT_Test_Framework]] - Unit testing integration
- [[Godot_Deterministic_Fixed_Timestep]] - Determinism requirements
- [[Godot_CI_Template]] - Full CI configuration
