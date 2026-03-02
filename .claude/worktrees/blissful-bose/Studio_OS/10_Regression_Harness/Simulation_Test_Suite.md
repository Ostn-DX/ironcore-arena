---
title: Simulation_Test_Suite
type: system
layer: enforcement
status: planned
tags:
  - testing
  - validation
  - determinism
  - edge_cases
depends_on:
  - "[Deterministic_60Hz_Simulation]]"
  - "[[GUT_Testing_Framework]"
used_by:
  - "[CI_Pipeline]]"
  - "[[Pre_Commit_Validation]"
---

# Simulation Test Suite

## Purpose
Comprehensive automated tests for battle simulation correctness, determinism, and edge case handling. Catches regressions before they reach players.

## Core Rules

### Test Categories

#### 1. Determinism Tests
```gdscript
func test_same_seed_same_result() -> void:
    var battle_a := run_headless(seed: 12345)
    var battle_b := run_headless(seed: 12345)
    assert_equal(battle_a.log_hash, battle_b.log_hash)

func test_cross_platform_consistency() -> void:
    var expected_hash: String = "a1b2c3d4..."  # Known good
    var actual := run_headless(seed: 12345).log_hash
    assert_equal(expected_hash, actual)
```

#### 2. Core Simulation Tests
- Tick timing: 3600 ticks = 60 seconds exactly
- Pause/resume: Battle continues correctly
- Max ticks timeout: Battle ends at MAX_TICKS
- Spawn teams: Correct count and team assignment

#### 3. Bot Behavior Tests
```gdscript
func test_bot_movement_speed() -> void:
    var bot := spawn_bot(speed: 5.0)
    advance_ticks(60)  # 1 second
    assert_float_equal(bot.distance_traveled, 5.0, tolerance: 0.1)

func test_bot_death() -> void:
    var bot := spawn_bot(hp: 10)
    bot.damage(20)
    assert_true(bot.is_destroyed)
    assert_signal_emitted(bot, "died")
```

#### 4. Projectile Tests
- Trajectory: Projectile reaches expected position
- Hit detection: Registers within hit radius
- Range limit: Destroyed at max range
- Friendly fire: Off by default

#### 5. Edge Case Tests
```gdscript
func test_zero_health_bot() -> void:
    var bot := spawn_bot(hp: 0)
    assert_true(bot.is_destroyed)  # Dies immediately

func test_negative_damage() -> void:
    var bot := spawn_bot(hp: 50)
    bot.damage(-10)
    assert_equal(bot.hp, 50)  # No change, or heal

func test_infinite_loop_prevention() -> void:
    # Two bots with 0 damage weapons
    var battle := run_headless(weapons: [weapon_0_dmg])
    assert_equal(battle.result, "timeout")  # Must time out
```

#### 6. Balance Integrity Tests
- All components load from JSON
- No weapon exceeds DPS cap
- No infinite damage combos
- Arena configs valid

### Test Requirements

| Metric | Target |
|--------|--------|
| Total test cases | 30+ |
| Determinism tests | 5+ |
| Edge case tests | 10+ |
| Execution time | < 30 seconds |
| Pass rate | 100% |

## Failure Modes

### Flaky Tests
**Symptom:** Test passes sometimes, fails others
**Cause:** Unseeded random, timing-dependent logic
**Fix:** Make fully deterministic

### Slow Tests
**Symptom:** Suite takes > 60 seconds
**Cause:** Running full battles unnecessarily
**Fix:** Use shorter battles for unit tests, integration tests for full

### False Positives
**Symptom:** Test passes but bug exists
**Cause:** Test doesn't actually verify behavior
**Fix:** Test should fail if bug is present

## Enforcement

### Pre-Commit
```bash
# .git/hooks/pre-commit
if ! ./tools/run_test_suite.sh; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

### CI Pipeline
- Run on every PR
- Run on every push to main
- Failed tests block merge

### Coverage Requirements
- New features must include tests
- Bug fixes must include regression test
- Determinism-critical code: 100% coverage

## Related
[[GUT_Testing_Framework]]
[[Headless_Test_Runner]]
[[Determinism_Validation]]
[[Edge_Case_Catalog]]
