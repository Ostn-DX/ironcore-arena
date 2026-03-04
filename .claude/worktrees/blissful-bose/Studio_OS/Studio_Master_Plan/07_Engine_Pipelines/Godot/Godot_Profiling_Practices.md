---
title: Godot Profiling Practices
type: rule
layer: execution
status: active
tags:
  - godot
  - profiling
  - performance
  - debugging
  - optimization
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Performance_Budgets]"
used_by:
  - "[Godot_CI_Template]"
---

# Godot Profiling Practices

Profiling identifies performance bottlenecks and validates optimization efforts. This specification defines profiling tools, techniques, and workflows for Godot 4.x projects.

## Built-in Profiling Tools

### Editor Profiler
```
Debug → Profiler → Start/Stop
```

Metrics available:
- Frame time (total)
- Physics time
- Idle time
- Draw calls
- Objects/nodes
- Memory
- Network

### Remote Scene Tree
```
Debug → Remote Scene Tree
```

Inspect running game:
- Node hierarchy
- Property values
- Signal connections
- Group membership

### Performance Monitor
```gdscript
# Access in code
var fps := Engine.get_frames_per_second()
var memory := OS.get_static_memory_usage()
var video_memory := RenderingServer.get_rendering_info(
    RenderingServer.RENDERING_INFO_VIDEO_MEM_USED
)
```

## Custom Profiling

### Function Timer
```gdscript
# src/utils/profiler.gd
class_name Profiler

static var _timers: Dictionary = {}

static func start_timer(name: String) -> void:
    _timers[name] = Time.get_ticks_usec()

static func end_timer(name: String) -> int:
    if not _timers.has(name):
        push_warning("Timer not started: " + name)
        return 0
    
    var elapsed := Time.get_ticks_usec() - _timers[name]
    _timers.erase(name)
    return elapsed

static func log_timer(name: String) -> void:
    var elapsed := end_timer(name)
    print("[Profiler] %s: %d μs (%.3f ms)" % [name, elapsed, elapsed / 1000.0])
```

### Usage Example
```gdscript
func expensive_operation() -> void:
    Profiler.start_timer("expensive_operation")
    
    # ... expensive code ...
    
    Profiler.log_timer("expensive_operation")
```

### Scoped Profiler
```gdscript
# src/utils/scoped_profiler.gd
class_name ScopedProfiler

var _name: String
var _start_time: int

func _init(name: String) -> void:
    _name = name
    _start_time = Time.get_ticks_usec()

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        var elapsed := Time.get_ticks_usec() - _start_time
        print("[ScopedProfiler] %s: %.3f ms" % [_name, elapsed / 1000.0])
```

### Scoped Usage
```gdscript
func process_entities() -> void:
    var _profiler := ScopedProfiler.new("process_entities")
    
    for entity in entities:
        entity.process()
    # Profiler logs automatically on scope exit
```

## CPU Profiling

### Physics Process Profiling
```gdscript
# src/core/physics_profiler.gd
extends Node

var _physics_times: Array[float] = []
var _max_samples: int = 60

func _physics_process(delta: float) -> void:
    var start := Time.get_ticks_usec()
    
    # Your physics code here
    _do_physics_work()
    
    var elapsed := (Time.get_ticks_usec() - start) / 1000.0  # ms
    _physics_times.append(elapsed)
    
    if _physics_times.size() > _max_samples:
        _physics_times.remove_at(0)

func get_average_physics_time() -> float:
    var sum := 0.0
    for t in _physics_times:
        sum += t
    return sum / _physics_times.size()
```

### GDScript Function Profiling
```gdscript
# Use @profile annotation (Godot 4.2+)
@profile
func frequently_called_function() -> void:
    pass
```

## GPU Profiling

### Rendering Metrics
```gdscript
func _print_rendering_stats() -> void:
    var draw_calls := RenderingServer.get_rendering_info(
        RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME
    )
    var vertices := RenderingServer.get_rendering_info(
        RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME
    )
    var video_mem := RenderingServer.get_rendering_info(
        RenderingServer.RENDERING_INFO_VIDEO_MEM_USED
    ) / 1024.0 / 1024.0
    
    print("Rendering: %d draw calls, %d vertices, %.1f MB VRAM" % [
        draw_calls, vertices, video_mem
    ])
```

### Viewport Profiling
```gdscript
# Enable viewport debug
get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
```

## Memory Profiling

### Object Count Tracking
```gdscript
# src/core/memory_profiler.gd
extends Node

var _object_counts: Dictionary = {}

func _process(_delta: float) -> void:
    _object_counts = {
        "nodes": get_tree().get_node_count(),
        "objects": Performance.get_monitor(Performance.OBJECT_COUNT),
        "resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
        "nodes_orphaned": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
    }

func print_memory_report() -> void:
    var static_mem := OS.get_static_memory_usage() / 1024.0 / 1024.0
    var dynamic_mem := Performance.get_monitor(Performance.MEMORY_DYNAMIC) / 1024.0 / 1024.0
    
    print("=== Memory Report ===")
    print("Static: %.1f MB" % static_mem)
    print("Dynamic: %.1f MB" % dynamic_mem)
    print("Nodes: %d" % _object_counts.nodes)
    print("Objects: %d" % _object_counts.objects)
```

### Leak Detection
```gdscript
func check_for_leaks() -> void:
    var nodes_before := get_tree().get_node_count()
    
    # Perform operation that should clean up
    _spawn_and_despawn_entities(100)
    
    # Force garbage collection
    OS.delay_msec(100)
    
    var nodes_after := get_tree().get_node_count()
    
    if nodes_after > nodes_before:
        push_warning("Possible leak: %d nodes not cleaned up" % (nodes_after - nodes_before))
```

## External Profiling Tools

### Godot Profiler Addon
```bash
# Install from Asset Library
# Search: "Godot Profiler"
```

### System Profilers

#### Windows
- Visual Studio Profiler
- Intel VTune
- AMD uProf
- PIX (for GPU)

#### macOS
- Instruments
- Metal System Trace

#### Linux
- perf
- sysprof
- NVIDIA Nsight
- RenderDoc

### RenderDoc Integration
```bash
# Launch Godot with RenderDoc
renderdoccmd capture godot --path /project

# Or use RenderDoc UI
# 1. Launch RenderDoc
# 2. File → Capture
# 3. Executable: godot
# 4. Working Dir: project folder
```

## Profiling Workflows

### Baseline Profiling
```gdscript
# 1. Establish baseline before optimization
# 2. Profile in release mode (not debug)
# 3. Run for representative duration (60s+)
# 4. Record: FPS, frame time, memory, draw calls

func establish_baseline() -> Dictionary:
    return {
        "fps_avg": _measure_avg_fps(60.0),
        "frame_time_ms": _measure_frame_time(),
        "memory_mb": OS.get_static_memory_usage() / 1024.0 / 1024.0,
        "draw_calls": _measure_avg_draw_calls(60.0)
    }
```

### Regression Testing
```gdscript
# Compare before/after optimization
func compare_performance(baseline: Dictionary, current: Dictionary) -> Dictionary:
    return {
        "fps_change_pct": (current.fps_avg - baseline.fps_avg) / baseline.fps_avg * 100,
        "memory_change_mb": current.memory_mb - baseline.memory_mb,
        "draw_calls_change": current.draw_calls - baseline.draw_calls
    }
```

## Common Bottlenecks

### CPU Bottlenecks
| Symptom | Cause | Solution |
|---------|-------|----------|
| High _physics_process time | Too many bodies | Reduce collision shapes, use layers |
| High _process time | Inefficient loops | Cache lookups, use groups |
| Slow instantiation | Creating nodes in loop | Use object pooling |
| Frame drops | Garbage collection | Reduce allocations |

### GPU Bottlenecks
| Symptom | Cause | Solution |
|---------|-------|----------|
| High draw calls | Many individual sprites | Use atlases, batching |
| High vertex count | Complex meshes | LOD, simplify geometry |
| Fill rate limited | Large overlapping sprites | Reduce overdraw |
| Shader bound | Complex shaders | Simplify, use cheaper variants |

### Memory Bottlenecks
| Symptom | Cause | Solution |
|---------|-------|----------|
| Growing memory | Leaks | Proper cleanup, autofree |
| High static memory | Large textures | Compress, reduce size |
| High dynamic memory | Frequent allocations | Pool objects |

## Profiling Checklist

### Before Optimization
- [ ] Profile in release mode
- [ ] Run for representative duration
- [ ] Document baseline metrics
- [ ] Identify actual bottleneck (not guess)

### During Optimization
- [ ] Profile after each change
- [ ] Measure improvement quantitatively
- [ ] Check for regressions
- [ ] Document what worked

### After Optimization
- [ ] Compare to baseline
- [ ] Verify no regressions
- [ ] Update performance budgets
- [ ] Document optimization

## Automated Profiling

### CI Performance Test
```yaml
# .github/workflows/profile.yml
name: Profile

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  profile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Profile Build
        run: |
          godot --headless --export-release "Linux/X11" builds/profile/game.x86_64
          timeout 120 ./builds/profile/game.x86_64 --profile --duration 60 > profile.txt
      
      - name: Upload Profile
        uses: actions/upload-artifact@v3
        with:
          name: profile-report
          path: profile.txt
```

## See Also

- [[Godot_Performance_Budgets]] - Performance targets
- [[Godot_CI_Template]] - CI integration
- Godot Docs: https://docs.godotengine.org/en/stable/tutorials/scripting/debug/
