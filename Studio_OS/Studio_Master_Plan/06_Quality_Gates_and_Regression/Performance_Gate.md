---
title: Performance Gate
type: gate
layer: enforcement
status: active
tags:
  - performance
  - fps
  - memory
  - gate
  - profiling
  - budgets
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Build_Gate]]"
  - "[[Perf_Budget_Enforcement]"
used_by:
  - "[Release_Certification_Checklist]]"
  - "[[Regression_Harness_Spec]"
---

# Performance Gate

## Purpose

The Performance Gate enforces performance budgets for FPS, memory usage, and load times. It prevents performance regressions from reaching production and ensures the game meets platform requirements.

## Tool/Script

**Primary**: `scripts/gates/performance_gate.py`
**Profiler**: Unity Profiler + custom instrumentation
**Memory Tracker**: `Assets/Scripts/Core/Performance/MemoryTracker.cs`
**FPS Monitor**: `Assets/Scripts/Core/Performance/FPSMonitor.cs`

## Local Run

```bash
# Quick performance check
python scripts/gates/performance_gate.py --quick

# Full performance suite
python scripts/gates/performance_gate.py --full

# Specific scenario
python scripts/gates/performance_gate.py --scenario combat_heavy

# Profile specific scene
python scripts/gates/performance_gate.py --scene Gameplay --duration 60

# Memory-only check
python scripts/gates/performance_gate.py --memory-only
```

## CI Run

```yaml
# .github/workflows/performance-gate.yml
name: Performance Gate
on:
  push:
    branches: [main]
  pull_request:
    paths:
      - 'Assets/**'
      - 'Scripts/**'
jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Performance Gate
        run: python scripts/gates/performance_gate.py --full
      - name: Upload Profile Data
        uses: actions/upload-artifact@v3
        with:
          name: profile-data
          path: reports/performance/
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| Average FPS | >= 60 | Mean frames per second |
| Minimum FPS | >= 30 | 1st percentile FPS |
| Frame Time 99th | < 33ms | 99th percentile frame time |
| Memory Peak | < Budget | Peak allocated memory |
| Memory Leak | < 1MB/min | Memory growth rate |
| Scene Load Time | < Budget | Time to interactive |
| Shader Compile | < 100ms | Stutter from shader compilation |
| GC Pressure | < 1 collection/min | Garbage collection frequency |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| Average FPS | < 60 | SOFT FAIL - performance regression |
| Minimum FPS | < 30 | HARD FAIL - unacceptable experience |
| Frame Time Spike | > 100ms | SOFT FAIL - visible stutter |
| Memory Budget | Exceeded | HARD FAIL - OOM risk |
| Load Time Budget | Exceeded | SOFT FAIL - UX issue |
| Regression > 10% | Any metric | SOFT FAIL - requires review |

## Performance Budgets by Platform

| Platform | Target FPS | Min FPS | Memory Budget | Load Time |
|----------|------------|---------|---------------|-----------|
| PC High | 144 | 60 | 8GB | 10s |
| PC Medium | 60 | 30 | 6GB | 15s |
| PC Low | 60 | 30 | 4GB | 20s |
| Console | 60 | 30 | 8GB | 15s |
| Mobile High | 60 | 30 | 3GB | 10s |
| Mobile Low | 30 | 20 | 2GB | 15s |

## Performance Scenarios

| Scenario | Description | Duration | Focus |
|----------|-------------|----------|-------|
| Main Menu | Static menu | 30s | Memory baseline |
| Loading | Scene transitions | Varies | Load time |
| Gameplay Light | Few entities | 60s | Baseline FPS |
| Gameplay Heavy | Max entities | 60s | Stress test |
| Combat | Combat simulation | 60s | CPU/GPU stress |
| UI Heavy | Many UI elements | 30s | UI performance |

## Performance Test Pattern

```csharp
// Assets/Tests/PlayMode/Performance/PerformanceTests.cs
[TestFixture]
public class PerformanceTests
{
    [UnityTest]
    [Category("Performance")]
    [Timeout(120000)]
    public IEnumerator Combat_Heavy_Maintains_60FPS()
    {
        // Arrange
        yield return LoadScene("CombatTest");
        var fpsMonitor = new FPSMonitor();
        var memoryTracker = new MemoryTracker();
        
        // Spawn heavy combat scenario
        SpawnMaxEntities();
        
        // Act - Run for 60 seconds
        fpsMonitor.StartRecording();
        memoryTracker.StartRecording();
        yield return new WaitForSeconds(60);
        fpsMonitor.StopRecording();
        memoryTracker.StopRecording();
        
        // Assert
        var stats = fpsMonitor.GetStats();
        Assert.GreaterOrEqual(stats.AverageFPS, 60, 
            $"Average FPS {stats.AverageFPS} below threshold 60");
        Assert.GreaterOrEqual(stats.MinFPS, 30, 
            $"Minimum FPS {stats.MinFPS} below threshold 30");
        
        var memoryStats = memoryTracker.GetStats();
        Assert.Less(memoryStats.GrowthRateMBPerMinute, 1, 
            $"Memory leak detected: {memoryStats.GrowthRateMBPerMinute} MB/min");
    }
}
```

## Failure Modes

### FPS Drop

**Symptoms**: Frame rate below threshold
**Root Causes**:
- New expensive rendering feature
- Unoptimized code path
- Increased entity count
- Shader/texture memory pressure

### Memory Leak

**Symptoms**: Memory grows continuously
**Root Causes**:
- Unreleased resources
- Event handler leaks
- Static reference accumulation
- Texture/audio not unloaded

### Load Time Regression

**Symptoms**: Scene loading slower than budget
**Root Causes**:
- New assets added to scene
- Synchronous loading operations
- Unoptimized asset bundles
- Shader compilation stutter

## Remediation Steps

### Fix FPS Drop

1. Capture profiler data during failure
2. Identify hotspot in CPU/GPU profiler
3. Optimize identified code/assets
4. Re-run performance gate
5. Verify improvement meets budget

### Fix Memory Leak

1. Capture memory snapshot at start and end
2. Compare snapshots to identify leaked objects
3. Fix reference retention issues
4. Add disposal patterns where missing
5. Re-run gate to verify

### Fix Load Time

1. Profile scene loading: `scripts/tools/profile_scene_load.py`
2. Identify slow-loading assets
3. Move to async loading where possible
4. Preload/precompile shaders
5. Re-run gate

## Performance Report Format

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "scenario": "combat_heavy",
  "platform": "StandaloneWindows64",
  "fps": {
    "average": 62.5,
    "min": 45.2,
    "max": 144.0,
    "p99": 28.5,
    "target": 60,
    "status": "PASS"
  },
  "memory": {
    "peak_mb": 2048,
    "current_mb": 1850,
    "budget_mb": 4096,
    "growth_rate_mb_per_min": 0.5,
    "status": "PASS"
  },
  "load_time": {
    "scene_name": "CombatTest",
    "duration_seconds": 8.5,
    "budget_seconds": 10,
    "status": "PASS"
  },
  "hotspots": [
    {
      "category": "Rendering",
      "time_ms": 8.2,
      "recommendation": "Consider GPU instancing for particles"
    }
  ]
}
```

## Integration with Other Gates

- **Requires**: [[Build_Gate]], [[Perf_Budget_Enforcement]]
- **Provides data to**: [[Regression_Harness_Spec]]
- **Required by**: [[Release_Certification_Checklist]]
- **Budget definitions**: [[Perf_Budget_Enforcement]]

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| Profiler overhead affects results | Run with deep profiling disabled | PERF-123 |
| CI GPU different from target | Use software renderer + margins | PERF-456 |
| Memory measurement varies | Take multiple samples, use median | PERF-789 |
