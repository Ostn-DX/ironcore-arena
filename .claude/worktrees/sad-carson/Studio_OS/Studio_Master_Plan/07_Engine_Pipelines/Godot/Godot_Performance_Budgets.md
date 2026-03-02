---
title: Godot Performance Budgets
type: rule
layer: enforcement
status: active
tags:
  - godot
  - performance
  - budgets
  - optimization
  - profiling
  - targets
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Asset_Import_Pipeline]"
used_by:
  - "[Godot_Profiling_Practices]]"
  - "[[Godot_CI_Template]"
---

# Godot Performance Budgets

Performance budgets define measurable targets that ensure games run smoothly across target hardware. This specification establishes budgets for FPS, memory, load times, and asset sizes in Godot 4.x projects.

## Budget Categories

### Frame Rate Budgets

| Platform | Target | Minimum | Measurement |
|----------|--------|---------|-------------|
| Desktop | 60 FPS | 30 FPS | Average over 60s |
| Console | 60 FPS | 30 FPS | 99th percentile |
| Mobile | 30 FPS | 24 FPS | Average over 30s |
| Web | 30 FPS | 20 FPS | Average over 30s |

### Frame Time Budgets (60 FPS = 16.67ms)

| System | Budget | Notes |
|--------|--------|-------|
| Total frame | 16.67ms | 60 FPS target |
| _physics_process | 8.33ms | 50% of frame |
| _process | 4.17ms | 25% of frame |
| Rendering | 4.17ms | 25% of frame |
| GPU | 16.67ms | Parallel with CPU |

### Memory Budgets

| Platform | RAM Budget | VRAM Budget | Notes |
|----------|------------|-------------|-------|
| Desktop (min) | 4 GB | 2 GB | GTX 750 Ti equivalent |
| Desktop (rec) | 8 GB | 4 GB | GTX 1060 equivalent |
| Console | 8 GB | Shared | PS4/Xbox One |
| Mobile (min) | 2 GB | 1 GB | Mid-range Android |
| Mobile (rec) | 4 GB | 2 GB | Flagship devices |
| Web | 2 GB | N/A | Browser dependent |

### Load Time Budgets

| Load Type | Target | Maximum | Notes |
|-----------|--------|---------|-------|
| Initial launch | 10s | 30s | To main menu |
| Level load | 3s | 10s | Small-medium level |
| Large level | 5s | 15s | Open world area |
| Save load | 2s | 5s | From menu |
| Checkpoint | 1s | 3s | In-game respawn |

### Asset Size Budgets

| Asset Type | Target | Maximum | Notes |
|------------|--------|---------|-------|
| 2D sprite | 512x512 | 1024x1024 | Per sprite |
| Sprite sheet | 2048x2048 | 4096x4096 | Atlas size |
| 3D texture | 1024x1024 | 2048x2048 | Per texture |
| Character model | 5K tris | 15K tris | Main character |
| Enemy model | 2K tris | 5K tris | Standard enemy |
| Environment | 50K tris | 100K tris | Per scene |
| SFX file | 500 KB | 2 MB | Per sound |
| Music track | 5 MB | 10 MB | Per track |
| Final build | 500 MB | 2 GB | Compressed |

## Budget Enforcement

### Runtime Monitoring
```gdscript
# src/core/performance_monitor.gd
class_name PerformanceMonitor
extends Node

@export var log_interval: float = 5.0
@export var fps_threshold: float = 55.0
@export var memory_threshold_mb: float = 512.0

var _fps_history: Array[float] = []
var _max_history: int = 60
var _timer: float = 0.0

func _process(delta: float) -> void:
    _timer += delta
    
    # Track FPS
    var fps := Engine.get_frames_per_second()
    _fps_history.append(fps)
    if _fps_history.size() > _max_history:
        _fps_history.remove_at(0)
    
    # Log periodically
    if _timer >= log_interval:
        _log_performance()
        _timer = 0.0
    
    # Warn on budget violation
    if fps < fps_threshold:
        push_warning("FPS below threshold: " + str(fps))

func _log_performance() -> void:
    var avg_fps := _calculate_average_fps()
    var memory_mb := OS.get_static_memory_usage() / 1024.0 / 1024.0
    
    print("Performance: FPS=%.1f, Memory=%.1f MB" % [avg_fps, memory_mb])
    
    if memory_mb > memory_threshold_mb:
        push_warning("Memory usage high: %.1f MB" % memory_mb)

func _calculate_average_fps() -> float:
    var sum := 0.0
    for fps in _fps_history:
        sum += fps
    return sum / _fps_history.size()

func get_average_fps() -> float:
    return _calculate_average_fps()

func get_memory_usage_mb() -> float:
    return OS.get_static_memory_usage() / 1024.0 / 1024.0
```

### Debug Overlay
```gdscript
# src/ui/debug/performance_overlay.gd
extends CanvasLayer

@onready var _fps_label: Label = $FPSLabel
@onready var _memory_label: Label = $MemoryLabel
@onready var _draw_calls_label: Label = $DrawCallsLabel

func _process(_delta: float) -> void:
    if not visible:
        return
    
    _fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
    _memory_label.text = "Memory: %.1f MB" % (OS.get_static_memory_usage() / 1024.0 / 1024.0)
    _draw_calls_label.text = "Draw Calls: " + str(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
```

## CI Performance Testing

### Automated Performance Test
```gdscript
# src/tests/performance/test_performance_budget.gd
extends GutTest

const PERFORMANCE_SCENE := "res://src/tests/scenes/performance_test.tscn"
const MIN_FPS := 55.0
const MAX_MEMORY_MB := 512.0

func test_maintains_target_fps() -> void:
    var runner := _load_performance_scene()
    
    # Run for 5 seconds
    await wait_seconds(5.0)
    
    var avg_fps := runner.get_average_fps()
    assert_gte(avg_fps, MIN_FPS, "Average FPS must be >= " + str(MIN_FPS))

func test_memory_within_budget() -> void:
    var memory_mb := OS.get_static_memory_usage() / 1024.0 / 1024.0
    assert_lte(memory_mb, MAX_MEMORY_MB, "Memory must be <= " + str(MAX_MEMORY_MB) + " MB")
```

### CI Performance Gate
```yaml
# .github/workflows/performance.yml
name: Performance Check

on: [pull_request]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.2.1
      
      - name: Run Performance Tests
        run: |
          godot --headless --script addons/gut/gut_cmdln.gd \
            -gdir=res://src/tests/performance \
            -gexit
      
      - name: Check Budget Compliance
        run: python scripts/check_performance_budgets.py
```

## Optimization Targets

### Draw Call Budgets
| Scene Type | Target | Maximum |
|------------|--------|---------|
| UI only | 10 | 50 |
| 2D gameplay | 50 | 200 |
| 3D simple | 100 | 500 |
| 3D complex | 500 | 2000 |

### Node Count Budgets
| Scene Type | Target | Maximum |
|------------|--------|---------|
| Simple UI | 20 | 100 |
| Complex UI | 100 | 500 |
| 2D level | 200 | 1000 |
| 3D level | 500 | 3000 |

### Physics Budgets
| Element | Target | Maximum |
|---------|--------|---------|
| RigidBodies | 50 | 200 |
| StaticBodies | 500 | 2000 |
| Active collisions | 100 | 500 |

## Profiling Integration

See [[Godot_Profiling_Practices]] for detailed profiling setup.

### Budget Violation Response

| Violation | Response |
|-----------|----------|
| FPS < target | Profile, identify bottleneck, optimize |
| Memory > budget | Check for leaks, reduce asset sizes |
| Load time > budget | Implement loading screen, async load |
| Draw calls > budget | Batch sprites, use atlases |

## Platform-Specific Adjustments

### Quality Settings
```gdscript
# src/core/quality_settings.gd
class_name QualitySettings

enum Quality { LOW, MEDIUM, HIGH, ULTRA }

const SETTINGS := {
    Quality.LOW: {
        "shadow_size": 1024,
        "msaa": Viewport.MSAA_DISABLED,
        "ssao": false,
        "glow": false
    },
    Quality.MEDIUM: {
        "shadow_size": 2048,
        "msaa": Viewport.MSAA_2X,
        "ssao": true,
        "glow": true
    },
    Quality.HIGH: {
        "shadow_size": 4096,
        "msaa": Viewport.MSAA_4X,
        "ssao": true,
        "glow": true
    }
}

static func apply_quality(quality: Quality) -> void:
    var settings: Dictionary = SETTINGS[quality]
    # Apply settings to rendering server
    RenderingServer.viewport_set_msaa(get_viewport().get_viewport_rid(), settings.msaa)
```

## Reporting

### Performance Report Template
```markdown
## Performance Report - Build [BUILD_ID]

### Frame Rate
- Average: [X] FPS
- Minimum: [X] FPS
- 1% Low: [X] FPS
- Status: [PASS/FAIL]

### Memory
- Peak: [X] MB
- Average: [X] MB
- Status: [PASS/FAIL]

### Load Times
- Initial: [X]s
- Level 1: [X]s
- Status: [PASS/FAIL]

### Recommendations
- [List optimizations if needed]
```

## See Also

- [[Godot_Profiling_Practices]] - Detailed profiling techniques
- [[Godot_Asset_Import_Pipeline]] - Asset optimization
- [[Godot_CI_Template]] - CI integration
