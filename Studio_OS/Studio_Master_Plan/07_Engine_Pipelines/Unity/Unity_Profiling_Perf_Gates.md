---
title: Unity Profiling Perf Gates
type: gate
layer: enforcement
status: active
tags:
  - unity
  - profiling
  - performance
  - perf-gates
  - optimization
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Build_Automation]"
used_by:
  - "[Unity_CI_Template]"
---

# Unity Profiling Perf Gates

Performance gates ensure Unity builds meet quality standards before release. This document defines profiling methodologies, performance thresholds, and automated performance testing for Studio OS Unity projects.

## Profiling Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  PROFILING ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   CPU       │    │   GPU       │    │   Memory    │     │
│  │ Profiler    │    │ Profiler    │    │ Profiler    │     │
│  │             │    │             │    │             │     │
│  │ • Scripts   │    │ • DrawCalls │    │ • Alloc     │     │
│  │ • Physics   │    │ • Batches   │    │ • GC        │     │
│  │ • Animation │    │ • Fill Rate │    │ • Texture   │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            ▼                                │
│                    ┌───────────────┐                        │
│                    │  Perf Gates   │                        │
│                    │               │                        │
│                    │ • FPS Target  │                        │
│                    │ • Memory Cap  │                        │
│                    │ • Load Time   │                        │
│                    └───────────────┘                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Performance Targets

### Frame Rate Targets

| Platform | Target FPS | Minimum FPS | Notes |
|----------|-----------|-------------|-------|
| PC (High) | 144 | 60 | VSync off, uncapped |
| PC (Standard) | 60 | 30 | VSync on |
| Steam Deck | 60 | 30 | Power efficient |
| Console | 60 | 30 | Locked to display |

### Memory Budgets

| Platform | Target | Maximum | Notes |
|----------|--------|---------|-------|
| PC (8GB) | 2 GB | 3 GB | Leave room for OS |
| PC (16GB) | 4 GB | 6 GB | Standard target |
| Steam Deck | 8 GB | 12 GB | Shared VRAM |

### Loading Time Targets

| Load Type | Target | Maximum |
|-----------|--------|---------|
| Initial boot | 10s | 20s |
| Level load | 5s | 10s |
| Scene transition | 2s | 5s |
| Asset load | 1s | 3s |

## Profiling Tools

### Unity Profiler

```csharp
// Enable deep profiling for detailed analysis
public static class ProfilerConfig
{
    [MenuItem("Profiling/Enable Deep Profile")]
    public static void EnableDeepProfile()
    {
        Profiler.enabled = true;
        Profiler.enableBinaryLog = true;
        Profiler.logFile = "profiler.log";
        Profiler.maxUsedMemory = 256 * 1024 * 1024; // 256MB
    }
    
    [MenuItem("Profiling/Record Frame")]
    public static void RecordFrame()
    {
        Profiler.AddFramesFromFile("profiler.log");
    }
}
```

### Custom Profiling

```csharp
// Custom profiler markers
public static class PerformanceMarkers
{
    private static readonly ProfilerMarker s_playerUpdate = 
        new ProfilerMarker("Player.Update");
    private static readonly ProfilerMarker s_enemyUpdate = 
        new ProfilerMarker("Enemy.Update");
    private static readonly ProfilerMarker s_physicsSim = 
        new ProfilerMarker("Physics.Simulate");
    
    public static void ProfilePlayerUpdate(System.Action action)
    {
        using (s_playerUpdate.Auto())
        {
            action();
        }
    }
    
    public static void ProfileEnemyUpdate(System.Action action)
    {
        using (s_enemyUpdate.Auto())
        {
            action();
        }
    }
}
```

### Usage Example

```csharp
public class PlayerController : MonoBehaviour
{
    private void Update()
    {
        PerformanceMarkers.ProfilePlayerUpdate(() =>
        {
            HandleInput();
            UpdateMovement();
            UpdateAnimation();
        });
    }
}
```

## Performance Testing

### Frame Rate Test

```csharp
// Assets/_Project/Tests/Runtime/Performance/FrameRateTest.cs
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using System.Collections;
using UnityEngine.SceneManagement;

namespace StudioOS.Tests.Runtime.Performance
{
    public class FrameRateTests
    {
        private const float TARGET_FPS = 60f;
        private const float MIN_ACCEPTABLE_FPS = 30f;
        private const int MEASURE_FRAMES = 300; // 5 seconds at 60fps
        
        [UnityTest]
        public IEnumerator Gameplay_MaintainsTargetFrameRate()
        {
            // Load gameplay scene
            SceneManager.LoadScene("Level_Test_Performance");
            yield return new WaitForSeconds(2f); // Warmup
            
            // Measure frame rate
            float[] frameTimes = new float[MEASURE_FRAMES];
            
            for (int i = 0; i < MEASURE_FRAMES; i++)
            {
                frameTimes[i] = Time.unscaledDeltaTime;
                yield return null;
            }
            
            // Calculate statistics
            float avgFPS = CalculateAverageFPS(frameTimes);
            float minFPS = CalculateMinFPS(frameTimes);
            float percentile1 = CalculatePercentileFPS(frameTimes, 0.01f);
            
            // Assert
            Debug.Log($"Performance Results - Avg: {avgFPS:F1} FPS, Min: {minFPS:F1} FPS, 1%: {percentile1:F1} FPS");
            
            Assert.GreaterOrEqual(avgFPS, TARGET_FPS * 0.95f, 
                $"Average FPS {avgFPS:F1} below target {TARGET_FPS}");
            Assert.GreaterOrEqual(percentile1, MIN_ACCEPTABLE_FPS, 
                $"1% low FPS {percentile1:F1} below minimum {MIN_ACCEPTABLE_FPS}");
        }
        
        private float CalculateAverageFPS(float[] frameTimes)
        {
            float totalTime = 0f;
            foreach (float t in frameTimes)
                totalTime += t;
            return frameTimes.Length / totalTime;
        }
        
        private float CalculateMinFPS(float[] frameTimes)
        {
            float maxTime = 0f;
            foreach (float t in frameTimes)
                maxTime = Mathf.Max(maxTime, t);
            return 1f / maxTime;
        }
        
        private float CalculatePercentileFPS(float[] frameTimes, float percentile)
        {
            var sorted = new List<float>(frameTimes);
            sorted.Sort();
            int index = Mathf.FloorToInt(sorted.Count * percentile);
            return 1f / sorted[index];
        }
    }
}
```

### Memory Test

```csharp
public class MemoryTests
{
    private const long MAX_MEMORY_MB = 2048; // 2GB
    
    [UnityTest]
    public IEnumerator Gameplay_MemoryWithinBudget()
    {
        // Load gameplay scene
        SceneManager.LoadScene("Level_Test_Performance");
        yield return new WaitForSeconds(2f);
        
        // Force GC and measure
        System.GC.Collect();
        yield return null;
        
        long memoryBefore = GC.GetTotalMemory(false);
        
        // Run gameplay simulation
        for (int i = 0; i < 600; i++) // 10 seconds
        {
            yield return null;
        }
        
        // Measure memory
        long memoryAfter = GC.GetTotalMemory(false);
        long memoryDelta = memoryAfter - memoryBefore;
        long totalMemory = GC.GetTotalMemory(false) / (1024 * 1024);
        
        Debug.Log($"Memory - Total: {totalMemory} MB, Delta: {memoryDelta / (1024 * 1024)} MB");
        
        Assert.Less(totalMemory, MAX_MEMORY_MB, 
            $"Memory usage {totalMemory} MB exceeds budget {MAX_MEMORY_MB} MB");
    }
}
```

### Load Time Test

```csharp
public class LoadTimeTests
{
    private const float MAX_LEVEL_LOAD_TIME = 5f;
    private const float MAX_SCENE_TRANSITION_TIME = 2f;
    
    [UnityTest]
    public IEnumerator LevelLoad_WithinTimeBudget()
    {
        float startTime = Time.realtimeSinceStartup;
        
        var operation = SceneManager.LoadSceneAsync("Level_Test_Performance");
        while (!operation.isDone)
        {
            yield return null;
        }
        
        float loadTime = Time.realtimeSinceStartup - startTime;
        Debug.Log($"Level load time: {loadTime:F2}s");
        
        Assert.Less(loadTime, MAX_LEVEL_LOAD_TIME, 
            $"Level load time {loadTime:F2}s exceeds budget {MAX_LEVEL_LOAD_TIME}s");
    }
}
```

## Performance Gates

### Gate Configuration

```csharp
// Assets/Editor/Profiling/PerformanceGates.cs
using UnityEditor;
using UnityEngine;

namespace StudioOS.Editor.Profiling
{
    public static class PerformanceGates
    {
        public static class Thresholds
        {
            public const float MIN_FPS = 30f;
            public const float TARGET_FPS = 60f;
            public const long MAX_MEMORY_MB = 2048;
            public const float MAX_LOAD_TIME = 5f;
            public const int MAX_DRAW_CALLS = 1000;
            public const int MAX_SET_PASS_CALLS = 100;
        }
        
        [MenuItem("Profiling/Run Performance Gates")]
        public static void RunPerformanceGates()
        {
            bool passed = true;
            
            // Run all gates
            passed &= CheckFrameRate();
            passed &= CheckMemoryUsage();
            passed &= CheckLoadTimes();
            passed &= CheckDrawCalls();
            
            if (passed)
            {
                Debug.Log("All performance gates passed!");
            }
            else
            {
                Debug.LogError("Some performance gates failed!");
            }
        }
        
        private static bool CheckFrameRate()
        {
            // Implementation
            return true;
        }
        
        private static bool CheckMemoryUsage()
        {
            long memoryMB = GC.GetTotalMemory(false) / (1024 * 1024);
            bool passed = memoryMB < Thresholds.MAX_MEMORY_MB;
            
            if (!passed)
            {
                Debug.LogError($"Memory gate failed: {memoryMB} MB > {Thresholds.MAX_MEMORY_MB} MB");
            }
            
            return passed;
        }
        
        private static bool CheckLoadTimes()
        {
            // Implementation
            return true;
        }
        
        private static bool CheckDrawCalls()
        {
            // Implementation
            return true;
        }
    }
}
```

## Automated Profiling

### CI Performance Tests

```yaml
# .github/workflows/performance.yml
name: Performance Tests

on:
  schedule:
    - cron: '0 2 * * *' # Daily at 2 AM

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Performance Tests
        uses: game-ci/unity-test-runner@v3
        with:
          testMode: playmode
          testFilter: 'Performance'
      
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: performance-results
          path: artifacts
```

## Optimization Guidelines

### CPU Optimization

```csharp
// Cache component references
private Transform _transform;
private void Awake() => _transform = transform;

// Avoid GetComponent in Update
// DON'T: GetComponent<Rigidbody>().AddForce(...)
// DO: _rigidbody.AddForce(...)

// Use object pooling
public class ObjectPool<T> where T : Component
{
    private Queue<T> _pool = new();
    private T _prefab;
    
    public T Get()
    {
        if (_pool.Count > 0)
            return _pool.Dequeue();
        return Object.Instantiate(_prefab);
    }
    
    public void Return(T obj)
    {
        obj.gameObject.SetActive(false);
        _pool.Enqueue(obj);
    }
}
```

### GPU Optimization

```csharp
// Batch static objects
// Use GPU Instancing for repeated meshes
// Minimize material variants
// Use texture atlasing

// LOD System
public class LODController : MonoBehaviour
{
    [SerializeField] private float[] _distances;
    [SerializeField] private GameObject[] _lodLevels;
    
    private void Update()
    {
        float distance = Vector3.Distance(transform.position, Camera.main.transform.position);
        
        for (int i = 0; i < _distances.Length; i++)
        {
            bool active = distance < _distances[i];
            if (_lodLevels[i].activeSelf != active)
                _lodLevels[i].SetActive(active);
        }
    }
}
```

### Memory Optimization

```csharp
// Reduce allocations
// DON'T: string concatenation in Update
// DO: Use StringBuilder

// Object pooling for particles
// DON'T: Instantiate/Destroy particle effects
// DO: Use ParticleSystem pool

// Texture compression
// Use platform-specific formats
// ASTC for mobile, DXT for desktop
```

## Enforcement

### CI Gates
- Performance tests pass
- Frame rate above minimum
- Memory within budget
- Load times acceptable

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| FPS below target | Warning | Optimization required |
| FPS below minimum | Error | Block release |
| Memory exceeds budget | Error | Block release |
| Load time exceeded | Warning | Review required |
