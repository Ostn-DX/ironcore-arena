---
title: Determinism_Loss_Pitfall
type: pitfall
layer: enforcement
status: active
tags:
  - pitfall
  - determinism
  - bugs
  - critical
depends_on:
  - "[Deterministic_60Hz_Simulation]"
used_by:
  - "[Determinism_Validation_Agent]]"
  - "[[Code_Review_Checklist]"
---

# Determinism Loss Pitfall

## The Trap
Using unseeded random, time-based logic, or platform-dependent operations in simulation code. Appears to work during testing but breaks replayability and AI training.

## Symptoms
- Same battle seed produces different results
- Replays desync
- AI behavior inconsistent across runs
- Different results on different platforms

## Root Causes

### 1. Unseeded Random Calls
```gdscript
# BAD - Non-deterministic
var damage: int = randi() % 10 + 5

# GOOD - Deterministic
var damage: int = _rng.randi() % 10 + 5  # _rng is seeded DeterministicRNG
```

### 2. Time-Based Logic
```gdscript
# BAD - Platform-dependent
var seed: int = Time.get_unix_time_from_system()

# GOOD - Consistent
var seed: int = arena_id.hash() + attempt_number
```

### 3. Dictionary Iteration
```gdscript
# BAD - Order not guaranteed
for bot_id in bots.keys():
    process(bots[bot_id])

# GOOD - Deterministic order
var sorted_ids: Array = bots.keys()
sorted_ids.sort()
for bot_id in sorted_ids:
    process(bots[bot_id])
```

### 4. Floating Point Inconsistency
```gdscript
# Risky - May vary by platform
var angle: float = atan2(y, x)

# Safer - Use step() or fixed-point
var angle: float = step(atan2(y, x), 0.001)
```

## Detection

### Static Analysis
- Search for `randf()` and `randi()` (without `_rng.`)
- Search for `Time.get_unix_time`
- Search for `.keys()` without `.sort()`

### Runtime Validation
```gdscript
# Determinism test
func test_same_seed_same_result() -> void:
    var result_a := run_battle(seed: 12345)
    var result_b := run_battle(seed: 12345)
    assert(result_a.hash() == result_b.hash())
```

## Prevention

### Invariant Enforcement
- All random through `DeterministicRNG`
- No time functions in simulation
- Dictionary keys always sorted before iteration
- Cross-platform float validation in CI

### Code Review Checklist
- [ ] No unseeded random calls
- [ ] No `Time.*` in `_run_tick()`
- [ ] Dictionary iteration sorted
- [ ] Float operations use `step()`

## Recovery

If determinism is lost:
1. Bisect commits to find breaking change
2. Audit all random/time/dict usage in that commit
3. Fix violations
4. Add determinism test to prevent regression

## Related
[[Deterministic_RNG_Implementation]]
[[Replay_System_Architecture]]
[[Cross_Platform_Float_Consistency]]
