---
title: Perf Budget Enforcement
type: rule
layer: enforcement
status: active
tags:
  - performance
  - budget
  - enforcement
  - fps
  - memory
  - load-time
  - metrics
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Performance_Gate]]"
  - "[[Regression_Harness_Spec]"
used_by:
  - "[Release_Certification_Checklist]"
---

# Perf Budget Enforcement

## Purpose

Performance budgets define the maximum resource consumption allowed for game systems. The Perf Budget Enforcement system tracks actual usage against budgets and blocks releases that exceed thresholds.

## Budget Categories

| Category | Metric | Budget | Measurement |
|----------|--------|--------|-------------|
| Frame Rate | Average FPS | >= 60 | Runtime measurement |
| Frame Rate | Minimum FPS | >= 30 | 1st percentile |
| Frame Time | 99th percentile | < 33ms | Per-frame timing |
| Memory | Peak allocated | < 4GB | Profiler snapshot |
| Memory | Growth rate | < 1MB/min | Over 30 min session |
| Load Time | Scene load | < 10s | To interactive |
| Load Time | Initial boot | < 15s | To main menu |
| Build Size | Windows | < 2GB | Final package |
| Build Size | Update patch | < 500MB | Delta size |

## Budget by Platform

| Platform | Target FPS | Min FPS | Memory | Load Time |
|----------|------------|---------|--------|-----------|
| PC High | 144 | 60 | 8GB | 10s |
| PC Medium | 60 | 30 | 6GB | 15s |
| PC Low | 60 | 30 | 4GB | 20s |
| Steam Deck | 60 | 30 | 8GB | 15s |
| Console | 60 | 30 | 8GB | 15s |
| Mobile High | 60 | 30 | 3GB | 10s |
| Mobile Low | 30 | 20 | 2GB | 15s |

## System-Level Budgets

| System | CPU Budget | Memory Budget | Notes |
|--------|------------|---------------|-------|
| Rendering | 8ms/frame | 1GB | Includes culling, draw calls |
| Game Logic | 4ms/frame | 512MB | Simulation, AI, physics |
| UI | 2ms/frame | 256MB | Canvas, animations |
| Audio | 1ms/frame | 128MB | Mixing, streaming |
| Networking | 1ms/frame | 64MB | Packet processing |
| GC | < 1ms/collection | N/A | Minimize allocations |

## Budget Definition File

```yaml
# config/performance_budgets.yml
platforms:
  pc_high:
    fps:
      target: 144
      minimum: 60
    frame_time:
      p99: 6.9  # ms (1/144)
    memory:
      peak_mb: 8192
      growth_rate_mb_per_min: 1
    load_time:
      boot_seconds: 10
      scene_seconds: 5
    build_size:
      max_mb: 2048
      patch_max_mb: 512

  pc_low:
    fps:
      target: 60
      minimum: 30
    frame_time:
      p99: 33.3  # ms (1/30)
    memory:
      peak_mb: 4096
      growth_rate_mb_per_min: 1
    load_time:
      boot_seconds: 20
      scene_seconds: 10
    build_size:
      max_mb: 2048
      patch_max_mb: 512

systems:
  rendering:
    cpu_ms_per_frame: 8
    memory_mb: 1024
  
  game_logic:
    cpu_ms_per_frame: 4
    memory_mb: 512
  
  ui:
    cpu_ms_per_frame: 2
    memory_mb: 256
```

## Enforcement Levels

| Violation | Action | Notification |
|-----------|--------|--------------|
| > 10% over budget | Warning | Slack #performance |
| > 20% over budget | Alert | Email leads |
| > 50% over budget | Block PR | PR blocked |
| Min FPS < 30 | Block release | Release blocked |
| Memory OOM risk | Block release | Release blocked |

## Budget Tracking

```csharp
// Assets/Scripts/Core/Performance/BudgetTracker.cs
public class BudgetTracker : MonoBehaviour
{
    [System.Serializable]
    public class Budget
    {
        public string name;
        public float limit;
        public Action<float> onExceeded;
    }
    
    private Dictionary<string, Budget> budgets = new();
    private Dictionary<string, float> current = new();
    
    public void SetBudget(string name, float limit, Action<float> onExceeded)
    {
        budgets[name] = new Budget { name = name, limit = limit, onExceeded = onExceeded };
    }
    
    public void ReportUsage(string name, float value)
    {
        current[name] = value;
        
        if (budgets.TryGetValue(name, out var budget))
        {
            float ratio = value / budget.limit;
            
            if (ratio > 1.5f)
            {
                Debug.LogError($"[BUDGET] {name}: {value:F2} / {budget.limit:F2} ({ratio:P0}) - CRITICAL");
                budget.onExceeded?.Invoke(value);
            }
            else if (ratio > 1.2f)
            {
                Debug.LogWarning($"[BUDGET] {name}: {value:F2} / {budget.limit:F2} ({ratio:P0}) - WARNING");
            }
            else if (ratio > 1.0f)
            {
                Debug.Log($"[BUDGET] {name}: {value:F2} / {budget.limit:F2} ({ratio:P0}) - OVER");
            }
        }
    }
}
```

## Performance Gate Integration

```python
# scripts/gates/performance_gate.py
class PerformanceGate:
    def check_budgets(self, results: PerformanceResults) -> GateResult:
        violations = []
        
        for metric, value in results.metrics.items():
            budget = self.budgets.get(metric)
            if budget:
                ratio = value / budget.limit
                
                if ratio > 1.5:
                    violations.append({
                        "metric": metric,
                        "value": value,
                        "budget": budget.limit,
                        "ratio": ratio,
                        "severity": "critical"
                    })
                elif ratio > 1.2:
                    violations.append({
                        "metric": metric,
                        "value": value,
                        "budget": budget.limit,
                        "ratio": ratio,
                        "severity": "warning"
                    })
        
        if any(v["severity"] == "critical" for v in violations):
            return GateResult.failed("Critical budget violations", violations)
        
        if violations:
            return GateResult.warning("Budget warnings", violations)
        
        return GateResult.passed()
```

## Budget Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│                  PERFORMANCE BUDGET DASHBOARD                │
├─────────────────────────────────────────────────────────────┤
│  FPS: 62.5 / 60 (104%) ✅                                    │
│  Memory: 2.1GB / 4GB (52%) ✅                                │
│  Load Time: 8.2s / 10s (82%) ✅                              │
│  Build Size: 1.8GB / 2GB (90%) ⚠️                           │
├─────────────────────────────────────────────────────────────┤
│  SYSTEM BUDGETS                                              │
│  Rendering: 6.2ms / 8ms (78%) ✅                             │
│  Game Logic: 3.1ms / 4ms (78%) ✅                            │
│  UI: 1.8ms / 2ms (90%) ⚠️                                   │
│  Audio: 0.5ms / 1ms (50%) ✅                                 │
└─────────────────────────────────────────────────────────────┘
```

## Remediation Workflow

### Budget Exceeded

1. **Identify**: Which budget and by how much
2. **Profile**: Capture detailed profiler data
3. **Analyze**: Find the hotspot
4. **Optimize**: Apply appropriate optimization
5. **Verify**: Re-measure against budget
6. **Document**: Note optimization in changelog

### Common Optimizations

| Issue | Optimization | Expected Gain |
|-------|--------------|---------------|
| High draw calls | GPU instancing, batching | 30-50% |
| Texture memory | Compression, atlasing | 50-70% |
| GC pressure | Object pooling, struct usage | 80-90% |
| Slow loading | Async loading, asset bundles | 40-60% |
| CPU bottleneck | Job System, Burst compiler | 50-80% |

## Integration with Other Gates

- **Budget definitions**: Consumed by [[Performance_Gate]]
- **Trend data**: From [[Regression_Harness_Spec]]
- **Enforcement**: Blocks [[Release_Certification_Checklist]]
- **Alerts**: Sent to performance Slack channel

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| Budgets vary by scene | Per-scene budget overrides | BUDGET-123 |
| Profiler overhead | Use release builds for final validation | BUDGET-456 |
| Mobile budgets hard to meet | Use adaptive quality | BUDGET-789 |
