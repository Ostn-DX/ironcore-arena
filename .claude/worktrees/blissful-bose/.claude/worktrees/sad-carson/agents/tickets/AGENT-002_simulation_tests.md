## ID
AGENT-002

## Title
Build Comprehensive Simulation Test Suite

## Goal
Create exhaustive tests for battle simulation determinism, correctness, and edge case handling. The simulation must be provably correct.

## Problem Statement
Current simulation has **zero tests**. GUT framework is included but empty. This is dangerous because:
- Floating-point determinism issues go undetected
- Edge cases (divide by zero, array bounds) cause crashes
- Balance changes can subtly break mechanics
- Refactors risk regressions

The simulation is 60Hz deterministic. Every behavior must be testable and replayable.

## Allowed Files
- project/tests/ (all files, this is a new test suite)
- project/autoload/SimulationManager.gd (read for understanding)
- project/src/entities/bot.gd (read for understanding)
- project/src/entities/projectile.gd (read for understanding)
- project/data/components.json (read for test data)

## New Files
- project/tests/test_simulation_core.gd
- project/tests/test_bot_behavior.gd
- project/tests/test_projectile_physics.gd
- project/tests/test_determinism.gd
- project/tests/test_balance_integrity.gd
- project/tests/test_edge_cases.gd
- tools/run_test_suite.gd (headless test runner)
- tests/README.md (test documentation)

## Forbidden Files
- Any source files in autoload/, src/, scenes/ (tests only, no modifications)
- Any JSON data files (read-only)

## Test Categories

### 1. Determinism Tests (test_determinism.gd)
```gdscript
func test_same_seed_same_result() -> void:
    ## Run battle with seed 12345 twice
    ## Assert: Identical tick-by-tick bot positions
    
func test_different_seed_different_result() -> void:
    ## Run battle with seeds 12345 and 67890
    ## Assert: Different outcomes (or at least different paths)
    
func test_cross_platform_determinism() -> void:
    ## Document: expected hash of battle log
    ## Future: CI validates against known hash
```

### 2. Core Simulation Tests (test_simulation_core.gd)
```gdscript
func test_tick_timing() -> void:
    ## 60Hz = exactly 16.67ms per tick
    ## Assert: 3600 ticks = 60 seconds
    
func test_max_ticks_timeout() -> void:
    ## Run battle until MAX_TICKS
    ## Assert: battle_ended signal fired with "timeout"
    
func test_pause_resume() -> void:
    ## Pause at tick 100, resume, pause at 200
    ## Assert: battle continues correctly from pause point
    
func test_spawn_teams() -> void:
    ## Spawn 3 player bots, 3 enemy bots
    ## Assert: Correct team assignment, no overlap
```

### 3. Bot Behavior Tests (test_bot_behavior.gd)
```gdscript
func test_bot_movement_speed() -> void:
    ## Bot with speed 5.0 moves exactly 5.0 units/sec
    ## Test for 1, 5, 10 seconds
    
func test_bot_health_damage() -> void:
    ## Bot with 100 HP takes 25 damage
    ## Assert: HP = 75
    
func test_bot_death() -> void:
    ## Bot at 10 HP takes 20 damage
    ## Assert: HP = 0, destroyed signal emitted
    
func test_bot_collision_avoidance() -> void:
    ## Two bots moving toward same point
    ## Assert: They don't occupy same space
    
func test_weapon_reload() -> void:
    ## Fire weapon, check cooldown
    ## Assert: Can't fire during reload, can after
```

### 4. Projectile Physics Tests (test_projectile_physics.gd)
```gdscript
func test_projectile_trajectory() -> void:
    ## Launch projectile at 45°, speed 10
    ## Assert: Reaches expected position at t=1, t=2
    
func test_projectile_hit_detection() -> void:
    ## Projectile aimed at target
    ## Assert: Hit registered when within hit radius
    
func test_projectile_range_limit() -> void:
    ## Projectile with max range 500
    ## Assert: Destroyed at 500 units, not before
    
func test_friendly_fire_off() -> void:
    ## Projectile from team 0 hits team 0 bot
    ## Assert: No damage (assuming friendly fire off)
```

### 5. Edge Case Tests (test_edge_cases.gd)
```gdscript
func test_divide_by_zero_speed() -> void:
    ## What if bot speed formula divides by weight and weight=0?
    ## Assert: No crash, graceful handling
    
func test_zero_health_bot() -> void:
    ## Spawn bot with 0 max HP
    ## Assert: Dies immediately, no crash
    
func test_negative_damage() -> void:
    ## Weapon with negative damage (healing?)
    ## Assert: Defined behavior (heal or clamp to 0)
    
func test_massive_bot_count() -> void:
    ## Spawn 100 bots
    ## Assert: No crash, performance degrades gracefully
    
func test_infinite_loop_prevention() -> void:
    ## Two bots with 0 damage weapons attacking each other
    ## Assert: Battle times out at MAX_TICKS
    
func test_null_target() -> void:
    ## Bot commanded to attack null target
    ## Assert: No crash, transitions to idle/hold
```

### 6. Balance Integrity Tests (test_balance_integrity.gd)
```gdscript
func test_all_components_load() -> void:
    ## Load all chassis, weapons, armor from components.json
    ## Assert: No missing data, all required fields present
    
func test_no_infinite_damage_combo() -> void:
    ## Check weapon damage * fire_rate formulas
    ## Assert: No DPS > 1000 (or some reasonable cap)
    
func test_weight_capacity_enforced() -> void:
    ## Build bot with weight > capacity
    ## Assert: Build rejected or speed = 0
    
func test_tier_progression_valid() -> void:
    ## All arenas reference valid enemy loadouts
    ## Assert: All components in loadouts exist in components.json
```

## Headless Test Runner (tools/run_test_suite.gd)
```gdscript
## Runs all GUT tests, outputs JSON report
## Usage: godot --headless --script res://tools/run_test_suite.gd

## Report format:
{
  "total_tests": 50,
  "passed": 48,
  "failed": 2,
  "skipped": 0,
  "duration_seconds": 15.3,
  "failures": [
    {"test": "test_bot_death", "error": "Signal not emitted"}
  ]
}
```

## Deliverable Structure
```
agent_runs/AGENT-002/
  NEW_FILES/
    - tests/test_simulation_core.gd
    - tests/test_bot_behavior.gd
    - tests/test_projectile_physics.gd
    - tests/test_determinism.gd
    - tests/test_balance_integrity.gd
    - tests/test_edge_cases.gd
    - tools/run_test_suite.gd
    - tests/README.md
  MODIFICATIONS/
    - (none - tests only)
  TESTS/
    - test_test_runner.gd (meta-test)
  INTEGRATION_GUIDE.md
  CHANGELOG.md
```

## Integration Steps
1. Copy all test files to project/tests/
2. Copy test runner to project/tools/
3. Run: `godot --headless --script res://tools/run_test_suite.gd`
4. Verify all tests pass (or document expected failures)

## Acceptance Criteria
- [ ] AC1: Minimum 30 test cases across all categories
- [ ] AC2: All existing mechanics have at least one test
- [ ] AC3: Determinism tests prove replayability
- [ ] AC4: Edge case tests catch at least 3 potential crashes
- [ ] AC5: Test runner outputs valid JSON report
- [ ] AC6: Tests run in < 30 seconds total
- [ ] AC7: Tests are independent (order doesn't matter)
- [ ] AC8: Tests clean up after themselves

## Research Areas
1. GUT testing framework (Godot Unit Test)
2. Property-based testing (fuzzing strategies)
3. Floating-point determinism in Godot/GLSL
4. Replay system validation techniques
