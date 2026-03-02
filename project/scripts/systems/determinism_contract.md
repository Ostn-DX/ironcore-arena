# Determinism Contract

## Overview

This document defines the rules for writing **deterministic code** in the Godot 4 AI Combat Simulation. All code that affects game state must follow these rules to ensure:

- **Reproducibility**: Same inputs always produce same outputs
- **Replay Support**: Simulations can be recorded and replayed
- **Network Synchronization**: Multiple clients stay in sync
- **Fair Competition**: AI tournaments are fair and verifiable

---

## Core Principle

> **Given the same initial state and inputs, the simulation must produce identical results on every run, on every platform, at all times.**

---

## Allowed Operations

The following operations are **SAFE** for deterministic code:

### ✅ Mathematics

```gdscript
# Basic arithmetic (all deterministic)
var sum: float = a + b
var diff: float = a - b
var product: float = a * b
var quotient: float = a / b  # Ensure no division by zero!
var modulo: int = a % b

# Standard math functions (deterministic)
var sqrt_val: float = sqrt(x)
var pow_val: float = pow(base, exp)
var abs_val: float = absf(x)
var clamped: float = clampf(x, min_val, max_val)
var rounded: int = roundi(x)
var floored: int = floori(x)
var ceiled: int = ceili(x)

# Trigonometry (deterministic)
var sine: float = sin(angle)
var cosine: float = cos(angle)
var tangent: float = tan(angle)
var arcsin_val: float = asin(x)
var arccos_val: float = acos(x)
var arctan_val: float = atan(x)
var atan2_val: float = atan2(y, x)

# Vector operations (deterministic)
var distance: float = pos1.distance_to(pos2)
var distance_sq: float = pos1.distance_squared_to(pos2)
var normalized: Vector2 = vec.normalized()
var dot_product: float = vec1.dot(vec2)
var cross_product: float = vec1.cross(vec2)
var rotated: Vector2 = vec.rotated(angle)
var lerped: Vector2 = pos1.lerp(pos2, t)
var moved: Vector2 = pos1.move_toward(pos2, delta)
```

### ✅ Control Flow

```gdscript
# All standard control flow is deterministic
if condition:
    pass
elif other_condition:
    pass
else:
    pass

for i in range(count):  # range() is deterministic
    pass

for i in range(start, end):  # Deterministic
    pass

for i in range(start, end, step):  # Deterministic
    pass

while condition:  # Deterministic if condition is deterministic
    pass

match value:  # Deterministic
    pattern1:
        pass
    pattern2:
        pass
    _:
        pass
```

### ✅ Data Structures (with caveats)

```gdscript
# Arrays - SAFE (ordered iteration)
var arr: Array[int] = [1, 2, 3]
for item in arr:  # Deterministic - maintains insertion order
    pass

# Dictionaries - REQUIRES SORTING for iteration
var dict: Dictionary = {"a": 1, "b": 2}

# ❌ WRONG - iteration order is undefined
for key in dict:
    pass

# ✅ CORRECT - explicitly sort keys
for key in dict.keys().sort():
    pass

# ✅ CORRECT - use deterministic iteration helper
for key in DeterminismHelpers.get_sorted_keys(dict):
    pass
```

### ✅ Random Numbers (via DeterministicRng)

```gdscript
# ✅ CORRECT - use the simulation's deterministic RNG
var rng: DeterministicRng = simulation_manager.get_rng()
var random_value: float = rng.random_float()  # [0.0, 1.0)
var random_int: int = rng.random_int(0, 100)  # [0, 100]
var random_bool: bool = rng.random_bool(0.3)  # 30% true
```

---

## Forbidden Operations

The following operations are **FORBIDDEN** in deterministic code:

### ❌ Godot Built-in Random

```gdscript
# NEVER use these - they use global non-deterministic state
var x = randf()        # ❌ FORBIDDEN
var y = randf_range(a, b)  # ❌ FORBIDDEN
var z = randi()        # ❌ FORBIDDEN
var w = randi_range(a, b)  # ❌ FORBIDDEN
var choice = arr[randi() % arr.size()]  # ❌ FORBIDDEN

# NEVER seed the global RNG - it affects everything
seed(12345)  # ❌ FORBIDDEN - affects global state
randomize()  # ❌ FORBIDDEN - uses system time
```

### ❌ Unordered Dictionary Iteration

```gdscript
# ❌ FORBIDDEN - iteration order is undefined
for key in my_dict:
    process(my_dict[key])

# ❌ FORBIDDEN - values() order is undefined
for value in my_dict.values():
    process(value)

# ❌ FORBIDDEN - items() order is undefined
for key_value in my_dict.items():
    process(key_value)
```

### ❌ System Time

```gdscript
# ❌ FORBIDDEN - varies every run
var now = Time.get_time_dict_from_system()
var unix = Time.get_unix_time_from_system()
var ticks = Time.get_ticks_msec()

# ❌ FORBIDDEN - varies every run
var delta = get_process_delta_time()  # Use fixed timestep instead!
```

### ❌ OS/Platform Dependent Operations

```gdscript
# ❌ FORBIDDEN - platform dependent
var unique_id = OS.get_unique_id()
var processor = OS.get_processor_name()
var locale = OS.get_locale()

# ❌ FORBIDDEN - file system order varies
var files = DirAccess.get_files_at("res://")
for file in files:  # Order varies by OS!
    pass
```

### ❌ Physics Direct Access

```gdscript
# ❌ FORBIDDEN - physics runs at different rate
var bodies = get_world_2d().direct_space_state.intersect_point(pos)

# ❌ FORBIDDEN - uses physics engine
move_and_slide()  # Use custom movement instead

# ❌ FORBIDDEN - collision detection varies
var collision = move_and_collide(velocity)
```

### ❌ Node Path Resolution (in hot paths)

```gdscript
# ❌ AVOID in process_tick - use cached references
var bot = get_node("/root/Simulation/Bot_" + str(id))

# ❌ AVOID - tree order may vary
for child in get_children():  # Order can vary!
    pass
```

### ❌ Floating Point Edge Cases

```gdscript
# ❌ FORBIDDEN - NaN propagation breaks determinism
var bad = 0.0 / 0.0  # NaN
var inf = 1.0 / 0.0  # Infinity

# ❌ FORBIDDEN - infinity comparisons are tricky
if x == INF:  # Avoid
    pass
```

---

## Float Handling Guidelines

Floating point numbers require special care for determinism:

### Epsilon Comparisons

```gdscript
# ❌ WRONG - direct equality check
if a == b:
    pass

# ✅ CORRECT - use epsilon comparison
if absf(a - b) <= SimConstants.FLOAT_EPSILON:
    pass

# ✅ CORRECT - use helper function
if SimConstants.floats_equal(a, b):
    pass
```

### Precision Limits

```gdscript
# Round to fixed precision for storage/comparison
var rounded: float = roundf(value * 10000.0) / 10000.0

# Or use the helper
var fixed: float = DeterminismHelpers.fix_precision(value)
```

### Avoid Division by Zero

```gdscript
# ❌ WRONG - may produce infinity
var result: float = numerator / denominator

# ✅ CORRECT - guard against zero
var result: float = 0.0
if absf(denominator) > SimConstants.FLOAT_EPSILON:
    result = numerator / denominator
else:
    result = 0.0  # Or some other default
```

### Vector Normalization

```gdscript
# ❌ WRONG - may produce NaN for zero vectors
var normal: Vector2 = vec.normalized()

# ✅ CORRECT - check length first
var normal: Vector2 = Vector2.ZERO
if vec.length_squared() > SimConstants.FLOAT_EPSILON:
    normal = vec.normalized()
```

---

## Tie-Breaking Rules

When multiple entities have equal scores/priority/position, we need deterministic tie-breaking:

### Priority Tie-Breaking

```gdscript
# When two targets have equal threat, use sim_id as tie-breaker
func select_target(targets: Array[Node]) -> Node:
    var best_target: Node = null
    var best_score: float = -INF
    
    for target in targets:
        var score: float = calculate_threat(target)
        
        if score > best_score + SimConstants.FLOAT_EPSILON:
            best_score = score
            best_target = target
        elif SimConstants.floats_equal(score, best_score):
            # Tie-breaker: lower sim_id wins
            if best_target == null or target.sim_id < best_target.sim_id:
                best_target = target
    
    return best_target
```

### Position Tie-Breaking

```gdscript
# When positions are equal, use sim_id to determine order
func sort_bots_by_distance(bots: Array[Node], from_pos: Vector2) -> Array[Node]:
    var sorted: Array[Node] = bots.duplicate()
    
    sorted.sort_custom(func(a: Node, b: Node) -> bool:
        var dist_a: float = a.position.distance_squared_to(from_pos)
        var dist_b: float = b.position.distance_squared_to(from_pos)
        
        if not SimConstants.floats_equal(dist_a, dist_b):
            return dist_a < dist_b
        
        # Tie-breaker: sim_id
        return a.sim_id < b.sim_id
    )
    
    return sorted
```

### General Tie-Breaking Hierarchy

When comparing entities with equal primary values, use this hierarchy:

1. **Primary value** (threat, distance, score, etc.)
2. **sim_id** (lower wins - stable identifier)
3. **team** (lower team ID)
4. **position.x** (lower wins)
5. **position.y** (lower wins)

```gdscript
func compare_entities(a: Node, b: Node, primary_a: float, primary_b: float) -> bool:
    # Primary comparison
    if not SimConstants.floats_equal(primary_a, primary_b):
        return primary_a < primary_b
    
    # Tie-breaker 1: sim_id
    if a.sim_id != b.sim_id:
        return a.sim_id < b.sim_id
    
    # Tie-breaker 2: team
    if a.team != b.team:
        return a.team < b.team
    
    # Tie-breaker 3: position x
    if not SimConstants.floats_equal(a.position.x, b.position.x):
        return a.position.x < b.position.x
    
    # Tie-breaker 4: position y
    return a.position.y < b.position.y
```

---

## Dictionary Iteration Patterns

### Pattern 1: Sort Keys Before Iteration

```gdscript
func process_bots_deterministically(bots: Dictionary) -> void:
    # bots: {int: Node} - sim_id to bot mapping
    
    var sorted_ids: Array = bots.keys()
    sorted_ids.sort()
    
    for id in sorted_ids:
        var bot: Node = bots[id]
        bot.process_tick(SimConstants.TIMESTEP)
```

### Pattern 2: Use Deterministic Helper

```gdscript
func process_bots_deterministically(bots: Dictionary) -> void:
    for bot in DeterminismHelpers.get_sorted_values(bots, "sim_id"):
        bot.process_tick(SimConstants.TIMESTEP)
```

### Pattern 3: Convert to Array First

```gdscript
func process_bots_deterministically(bots: Dictionary) -> void:
    var bot_array: Array[Node] = []
    bot_array.assign(bots.values())
    
    # Sort by sim_id
    bot_array.sort_custom(func(a: Node, b: Node) -> bool:
        return a.sim_id < b.sim_id
    )
    
    for bot in bot_array:
        bot.process_tick(SimConstants.TIMESTEP)
```

---

## Determinism Validation

### Checksum Verification

```gdscript
class DeterminismValidator:
    static func compute_checksum(sim_manager: Node) -> int:
        var hash_val: int = 0
        
        # Hash tick number
        hash_val = hash_combine(hash_val, sim_manager.get_sim_tick())
        
        # Hash all bot states (in deterministic order)
        var bots: Array[Node] = sim_manager.get_all_bots()
        bots.sort_custom(func(a: Node, b: Node) -> bool:
            return a.sim_id < b.sim_id
        )
        
        for bot in bots:
            hash_val = hash_combine(hash_val, hash_bot_state(bot))
        
        return hash_val
    
    static func hash_bot_state(bot: Node) -> int:
        var h: int = 0
        h = hash_combine(h, bot.sim_id)
        h = hash_combine(h, hash_float(bot.position.x))
        h = hash_combine(h, hash_float(bot.position.y))
        h = hash_combine(h, hash_float(bot.health))
        h = hash_combine(h, bot.team)
        return h
    
    static func hash_float(f: float) -> int:
        # Convert to fixed-point integer
        return int(roundf(f * 10000.0))
    
    static func hash_combine(seed: int, value: int) -> int:
        # FNV-like hash combination
        return (seed ^ value) * 16777619
```

### Debug Assertions

```gdscript
func process_tick(dt: float) -> void:
    # Validate determinism in debug builds
    if SimConstants.DEBUG_CHECKSUMS:
        var checksum_before: int = DeterminismValidator.compute_checksum(self)
    
    # ... simulation logic ...
    
    if SimConstants.DEBUG_CHECKSUMS:
        var checksum_after: int = DeterminismValidator.compute_checksum(self)
        # Log checksum for verification across runs
```

---

## Code Review Checklist

Before submitting deterministic code, verify:

- [ ] No `randf()`, `randi()`, `randf_range()`, `randi_range()` calls
- [ ] No `randomize()` or `seed()` calls
- [ ] No `Time.get_*()` system time calls
- [ ] Dictionary iteration uses sorted keys
- [ ] Array sorting uses stable tie-breakers
- [ ] Float equality uses epsilon comparison
- [ ] Division by zero is guarded
- [ ] Vector normalization checks length
- [ ] All randomness uses `DeterministicRng`
- [ ] No physics engine direct access
- [ ] No `get_process_delta_time()` - use fixed timestep
- [ ] Node iteration is sorted by stable ID
- [ ] Tie-breaking is deterministic (sim_id hierarchy)

---

## Common Pitfalls

### Pitfall 1: Implicit Dictionary Iteration

```gdscript
# ❌ WRONG - implicit iteration
for bot in bots_dict:
    bot.update()

# ✅ CORRECT - explicit sorted iteration
for id in bots_dict.keys().sort():
    bots_dict[id].update()
```

### Pitfall 2: Sorting Without Tie-Breaker

```gdscript
# ❌ WRONG - unstable sort
bots.sort_custom(func(a, b): return a.score > b.score)

# ✅ CORRECT - stable with tie-breaker
bots.sort_custom(func(a, b):
    if a.score != b.score:
        return a.score > b.score
    return a.sim_id < b.sim_id  # Tie-breaker
)
```

### Pitfall 3: Frame-Dependent Updates

```gdscript
# ❌ WRONG - frame-dependent
func _process(delta: float) -> void:
    position += velocity * delta  # Varies by framerate!

# ✅ CORRECT - tick-dependent
func process_tick(dt: float) -> void:
    position += velocity * SimConstants.TIMESTEP  # Fixed!
```

### Pitfall 4: Cached Random Results

```gdscript
# ❌ WRONG - cached random is wrong random
var cached_random: float = rng.random_float()

func process_tick(dt: float) -> void:
    if cached_random < 0.5:  # Same every tick!
        pass

# ✅ CORRECT - get random each time
func process_tick(dt: float) -> void:
    if rng.random_float() < 0.5:  # Fresh each tick
        pass
```

---

## Summary

| Category | Allowed | Forbidden |
|----------|---------|-----------|
| Random | `DeterministicRng` | `randf()`, `randi()`, `randomize()` |
| Iteration | Sorted arrays/dicts | Unsorted dictionary iteration |
| Time | Tick counter | System time, `get_process_delta_time()` |
| Physics | Custom collision | `move_and_slide()`, `direct_space_state` |
| Floats | Epsilon comparison | Direct `==` comparison |
| Division | Guarded by epsilon | Unprotected division |

---

## References

- [Godot 4 GDScript Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [Floating Point Determinism](https://randomascii.wordpress.com/2013/07/16/floating-point-determinism/)
- [IEEE 754 Standard](https://en.wikipedia.org/wiki/IEEE_754)
