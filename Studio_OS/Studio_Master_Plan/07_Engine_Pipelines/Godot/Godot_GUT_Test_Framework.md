---
title: Godot GUT Test Framework
type: system
layer: execution
status: active
tags:
  - godot
  - testing
  - gut
  - unit-test
  - tdd
  - ci
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Headless_Sim_Runner_Spec]"
used_by:
  - "[Godot_GDScript_Style_Guide]]"
  - "[[Godot_CI_Template]"
---

# Godot GUT Test Framework

GUT (Godot Unit Test) is the standard testing framework for Godot 4.x. This specification defines integration patterns, test organization, and CI requirements for comprehensive test coverage in the AI-Native Game Studio OS pipeline.

## Framework Installation

### Via Asset Library
1. Open AssetLib tab in Godot editor
2. Search for "GUT"
3. Install latest version (7.x for Godot 4)

### Via Git Submodule (Recommended)
```bash
git submodule add https://github.com/bitwes/Gut.git addons/gut
```

### Project Configuration
```gdscript
# project.godot
[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")

[gut]
directory="res://src/tests/unit"
include_subdirectories=true
ignore_pause=true
log_level=1
should_exit=true
should_maximize=false
```

## Test Organization

### Directory Structure
```
src/tests/
├── unit/                    # Unit tests
│   ├── entities/           # Entity tests
│   │   ├── test_player.gd
│   │   └── test_enemy.gd
│   ├── core/               # Core system tests
│   │   ├── test_state_machine.gd
│   │   └── test_pool_manager.gd
│   ├── utils/              # Utility tests
│   │   └── test_math_helpers.gd
│   └── autoload/           # Autoload tests
│       └── test_game_state.gd
├── integration/            # Integration tests
│   ├── test_combat_system.gd
│   └── test_save_load.gd
└── scenes/                 # Test scenes (manual)
    └── ...
```

## Test File Structure

### Standard Test Template
```gdscript
# src/tests/unit/entities/test_player.gd
extends GutTest

# Class under test
const Player := preload("res://src/entities/player/player.gd")

# Test fixtures
var _player: Node2D = null

func before_each() -> void:
    # Reset state before each test
    _player = Player.new()
    add_child_autofree(_player)

func after_each() -> void:
    # Cleanup handled by autofree
    pass

func test_initial_health() -> void:
    assert_eq(_player.health, 100, "Player should start with 100 health")

func test_take_damage_reduces_health() -> void:
    _player.take_damage(25)
    assert_eq(_player.health, 75, "Health should decrease by damage amount")

func test_take_damage_clamps_at_zero() -> void:
    _player.take_damage(150)
    assert_eq(_player.health, 0, "Health should not go below zero")
    assert_true(_player.is_dead(), "Player should be dead when health is zero")
```

## Assertion Reference

### Basic Assertions
```gdscript
# Equality
assert_eq(actual, expected, "message")
assert_ne(actual, not_expected, "message")

# Boolean
assert_true(condition, "message")
assert_false(condition, "message")

# Null checks
assert_null(value, "message")
assert_not_null(value, "message")

# Numeric
assert_gt(actual, expected, "message")   # greater than
assert_gte(actual, expected, "message")  # greater than or equal
assert_lt(actual, expected, "message")   # less than
assert_lte(actual, expected, "message")  # less than or equal
assert_between(value, low, high, "message")
assert_almost_eq(actual, expected, tolerance, "message")

# String
assert_string_contains(string, substring, "message")
assert_string_starts_with(string, prefix, "message")
assert_string_ends_with(string, suffix, "message")
```

### Godot-Specific Assertions
```gdscript
# Signals
assert_signal_emitted(object, signal_name, "message")
assert_signal_not_emitted(object, signal_name, "message")
assert_signal_emitted_with_parameters(object, signal_name, [param1, param2])
assert_has_signal(object, signal_name, "message")

# Groups
assert_is_in_group(node, group_name, "message")

# Files
assert_file_exists(path, "message")
assert_file_does_not_exist(path, "message")
```

## Testing Patterns

### Signal Testing
```gdscript
func test_damage_emits_signal() -> void:
    watch_signals(_player)
    _player.take_damage(10)
    assert_signal_emitted(_player, "health_changed", "Damage should emit health_changed")
    assert_signal_emitted_with_parameters(_player, "health_changed", [90, 10])
```

### Doubling/Mocking
```gdscript
func test_enemy_detects_player_with_mock() -> void:
    var mock_player = double(Player).new()
    stub(mock_player, "global_position").to_return(Vector2(100, 100))
    
    var enemy = Enemy.new()
    enemy.player = mock_player
    
    assert_true(enemy.can_see_player(), "Enemy should detect player at position")
```

### Async Testing
```gdscript
func test_save_completes_async() -> void:
    var completed := false
    SaveManager.save_completed.connect(func(): completed = true)
    
    SaveManager.save_game(1)
    
    await wait_for_signal(SaveManager.save_completed, 5.0)
    assert_true(completed, "Save should complete within 5 seconds")
```

### Parameterized Tests
```gdscript
func test_damage_calculation(params=use_parameters([
    [10, 90],
    [50, 50],
    [100, 0],
    [150, 0]
])) -> void:
    var damage: int = params[0]
    var expected_health: int = params[1]
    
    _player.take_damage(damage)
    assert_eq(_player.health, expected_health)
```

## Autoload Testing

### Reset Pattern
```gdscript
# src/tests/unit/autoload/test_game_state.gd
extends GutTest

func before_each() -> void:
    # Reset GameState to known initial state
    GameState.reset()
    GameState.current_level = ""
    GameState.player_health = 100

func test_level_completion_updates_state() -> void:
    GameState.complete_level("level_1")
    assert_true(GameState.is_level_completed("level_1"))
    assert_eq(GameState.completed_levels.size(), 1)
```

### Mock Autoload Pattern
```gdscript
func test_with_mock_audio() -> void:
    # Store original
    var original_audio = AudioManager
    
    # Replace with mock
    var mock_audio = autoqfree(MockAudioManager.new())
    get_tree().root.remove_child(AudioManager)
    get_tree().root.add_child(mock_audio)
    
    # Run test
    _player.play_attack_sound()
    assert_true(mock_audio.was_called("play_sfx"))
    
    # Restore original (handled by test framework cleanup)
```

## Determinism Testing

### Replay Validation
```gdscript
func test_deterministic_simulation() -> void:
    var runner = DeterminismRunner.new()
    
    # Run simulation twice with same inputs
    var result1 = runner.run_simulation("test_scenario", 600)
    var result2 = runner.run_simulation("test_scenario", 600)
    
    # Results must be identical
    assert_eq(result1.final_hash, result2.final_hash, 
        "Simulation must be deterministic")
    assert_eq(result1.entity_positions, result2.entity_positions,
        "Entity positions must match")
```

## Test Configuration

### GUT Panel Settings
```gdscript
# Configured via Editor → GUT panel
{
  "directories": ["res://src/tests/unit"],
  "include_subdirectories": true,
  "tests_like": "test_*.gd",
  "ignore_pause": true,
  "log_level": 1,
  "should_exit": true,
  "should_maximize": false
}
```

### Runtime Configuration
```gdscript
# Override settings programmatically
func before_all() -> void:
    GutConfig.set("log_level", 2)  # Verbose for debugging
```

## Command-Line Execution

### Basic Run
```bash
# Run all tests
godot --headless --script addons/gut/gut_cmdln.gd

# Run specific directory
godot --headless --script addons/gut/gut_cmdln.gd \
    -gdir=res://src/tests/unit/entities

# Run specific test
godot --headless --script addons/gut/gut_cmdln.gd \
    -gunit_test_name=test_take_damage

# Output formats
godot --headless --script addons/gut/gut_cmdln.gd \
    -ginclude_subdirs \
    -gjunit_xml=results.xml
```

### CI-Optimized Run
```bash
#!/bin/bash
# scripts/test_unit.sh

godot --headless --script addons/gut/gut_cmdln.gd \
    -gdir=res://src/tests/unit \
    -ginclude_subdirs \
    -gexit \
    -glog_level=1 \
    -gjunit_xml=builds/test_results/unit_tests.xml

exit_code=$?

# Parse results for summary
if [ -f builds/test_results/unit_tests.xml ]; then
    python scripts/parse_test_results.py builds/test_results/unit_tests.xml
fi

exit $exit_code
```

## Coverage Reporting

### Coverage Configuration
```gdscript
# Enable coverage in GUT settings
[gut]
coverage_enabled=true
coverage_include_scripts=["res://src/"]
coverage_exclude_scripts=["res://src/tests/", "res://addons/"]
```

### Coverage Report Generation
```bash
godot --headless --script addons/gut/gut_cmdln.gd \
    -gdir=res://src/tests/unit \
    -ginclude_subdirs \
    -gcoverage \
    -gcoverage_report=builds/coverage/report.xml
```

## Performance Testing

### Benchmark Tests
```gdscript
func test_pathfinding_performance() -> void:
    var start_time := Time.get_ticks_usec()
    
    for i in range(1000):
        _pathfinder.find_path(Vector2.ZERO, Vector2(1000, 1000))
    
    var elapsed := Time.get_ticks_usec() - start_time
    var avg_ms := elapsed / 1000.0 / 1000.0
    
    assert_lt(avg_ms, 1.0, "Pathfinding should average under 1ms")
```

## Failure Modes

| Failure | Cause | Resolution |
|---------|-------|------------|
| Test timeout | Infinite loop or async hang | Add timeouts, check awaits |
| Signal not received | Wrong signal name or connection | Verify signal exists |
| Double creation fails | Missing stub configuration | Add required stubs |
| Autofree cleanup issues | Circular references | Manual cleanup in after_each |
| Coverage gaps | Untested branches | Add tests or exclude intentionally |

## Best Practices

1. **One assertion per test** (ideally) - clearer failures
2. **Descriptive test names** - `test_when_X_then_Y`
3. **Arrange-Act-Assert** structure
4. **Use `before_each`** for setup, not inline
5. **Mock external dependencies** - database, network, time
6. **Test edge cases** - empty, null, maximum values
7. **Keep tests fast** - < 100ms per test ideal

## See Also

- [[Godot_Headless_Sim_Runner_Spec]] - Simulation testing
- [[Godot_UI_Smoke_Runner_Spec]] - UI automation testing
- [[Godot_Deterministic_Fixed_Timestep]] - Determinism requirements
- [[Godot_CI_Template]] - CI integration
