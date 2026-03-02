---
title: Performance_Degradation_Pitfall
type: pitfall
layer: enforcement
status: active
tags:
  - pitfall
  - performance
  - optimization
  - fps
depends_on:
  - "[Performance_Constraints]"
used_by:
  - "[Performance_Monitor_Agent]]"
  - "[[Code_Review_Checklist]"
---

# Performance Degradation Pitfall

## The Trap
Allocating memory, doing O(n²) operations, or loading resources in hot paths. Game runs fine with 2 bots, crawls with 20.

## Symptoms
- FPS drops below 60 with 10+ bots
- Frame time spikes during combat
- Memory usage grows over time
- GC pauses cause stuttering

## Root Causes

### 1. Allocation in Hot Paths
```gdscript
# BAD - Allocates every tick
func _run_tick() -> void:
    for bot in bots:
        var nearby: Array = []  # New allocation each tick!
        nearby = get_nearby_bots(bot.position)

# GOOD - Reuse array
var _nearby_buffer: Array = []

func _run_tick() -> void:
    for bot in bots:
        _nearby_buffer.clear()
        get_nearby_bots(bot.position, _nearby_buffer)
```

### 2. O(n²) Collision Detection
```gdscript
# BAD - O(n²) nested loops
for bot_a in bots:
    for bot_b in bots:
        if bot_a.position.distance_to(bot_b.position) < threshold:
            collide(bot_a, bot_b)

# GOOD - Spatial partitioning
var grid: SpatialHash = SpatialHash.new(cell_size: 100)
for bot in bots:
    var nearby: Array = grid.get_nearby(bot.position)
    for other in nearby:
        collide(bot, other)
```

### 3. Uncached Node Lookups
```gdscript
# BAD - Traverses tree every tick
func _run_tick() -> void:
    var sim: SimulationManager = get_node("/root/SimulationManager")

# GOOD - Cache in _ready()
@onready var _sim: SimulationManager = get_node("/root/SimulationManager")

func _run_tick() -> void:
    # Use cached _sim
```

### 4. String Concatenation in Debug
```gdscript
# BAD - String ops every tick
func _run_tick() -> void:
    if debug:
        print("Bot " + bot.name + " at " + str(bot.position))

# GOOD - Conditional, infrequent
func _run_tick() -> void:
    if debug and tick % 60 == 0:  # Once per second
        print("Bot %s at %s" % [bot.name, bot.position])
```

## Detection

### Profiling
- Godot Profiler: Look for allocation spikes
- Custom frame time tracking in PerformanceMonitor
- FPS counter in debug UI

### Stress Testing
```gdscript
# Performance test
func test_20_bot_performance() -> void:
    spawn_bots(20)
    var avg_frame_time: float = measure_fps_for_seconds(10)
    assert(avg_frame_time < 16.67)  # 60 FPS
```

## Prevention

### Hot Path Rules
- No `new` or `[]` in `_run_tick()`
- Cache all node lookups in `_ready()`
- Use spatial partitioning for collision
- Pre-allocate arrays at max size

### Monitoring
```gdscript
# PerformanceMonitor.gd
func _physics_process(_delta: float) -> void:
    if frame_time > 20.0:  # > 20ms = < 50 FPS
        push_warning("Frame time spike: %.2f ms" % frame_time)
```

## Recovery

If performance degrades:
1. Profile to find hot spots
2. Identify allocation sources
3. Replace with object pools
4. Add spatial partitioning
5. Profile again to verify

## Related
[[Object_Pooling_System]]
[[Spatial_Partitioning_Implementation]]
[[Performance_Monitoring_Tools]]
