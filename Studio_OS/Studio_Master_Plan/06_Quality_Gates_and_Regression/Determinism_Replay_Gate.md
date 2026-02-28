---
title: Determinism Replay Gate
type: gate
layer: enforcement
status: active
tags:
  - determinism
  - replay
  - simulation
  - gate
  - multiplayer
  - rng
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Unit_Tests_Gate]"
used_by:
  - "[Headless_Match_Batch_Gate]]"
  - "[[Regression_Harness_Spec]]"
  - "[[Release_Certification_Checklist]"
---

# Determinism Replay Gate

## Purpose

The Determinism Replay Gate ensures that game simulations produce identical results given identical inputs. This is critical for:
- Multiplayer synchronization
- Replay validation
- Bug reproduction
- AI training consistency

## Tool/Script

**Primary**: `scripts/gates/determinism_gate.py`
**Replay System**: `Assets/Scripts/Core/Replay/ReplaySystem.cs`
**Hash Validator**: `Assets/Scripts/Core/Determinism/StateHash.cs`

## Local Run

```bash
# Run determinism validation
python scripts/gates/determinism_gate.py --scenario set1

# Run with specific seed
python scripts/gates/determinism_gate.py --seed 12345 --iterations 10

# Full determinism suite
python scripts/gates/determinism_gate.py --full

# Debug mode (verbose logging)
python scripts/gates/determinism_gate.py --debug --scenario combat_basic
```

## CI Run

```yaml
# .github/workflows/determinism-gate.yml
name: Determinism Replay Gate
on: [push, pull_request]
jobs:
  determinism:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Determinism Gate
        run: python scripts/gates/determinism_gate.py --full
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| State Hash Match | 100% | Hash equality across runs |
| Replay Validity | 100% | All replays deserialize correctly |
| Frame Count Match | 100% | Same number of frames per run |
| Event Sequence Match | 100% | Event order identical |
| RNG Sequence Match | 100% | Random numbers identical |
| Floating Point Match | 100% | FP operations deterministic |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| Hash Mismatch | >= 1 | HARD FAIL - determinism broken |
| Replay Corruption | >= 1 | HARD FAIL - serialization issue |
| Frame Drift | >= 1 frame | HARD FAIL - timing issue |
| Event Reorder | >= 1 | HARD FAIL - event system bug |
| RNG Divergence | >= 1 | HARD FAIL - seeding issue |
| FP Divergence | >= 0.0001 | SOFT FAIL - FP precision issue |

## Determinism Requirements by System

| System | Determinism Level | Notes |
|--------|-------------------|-------|
| Game State | STRICT | Must be 100% deterministic |
| Physics | STRICT | Fixed timestep, no Unity physics |
| AI Decisions | STRICT | Same inputs = same outputs |
| Combat Resolution | STRICT | Damage, hit chance, etc. |
| Economy | STRICT | Resource calculations |
| RNG | STRICT | Seeded, reproducible |
| Visual Effects | LOOSE | Can vary without affecting gameplay |
| Audio | LOOSE | Timing can vary slightly |
| Animation | LOOSE | Visual-only, not gameplay |

## Determinism Checklist

### Code Patterns to Avoid

```csharp
// ❌ NON-DETERMINISTIC - Uses system time
float randomValue = Random.value; // Without seeded Random

// ❌ NON-DETERMINISTIC - Dictionary iteration order
foreach (var item in dictionary) { } // Use SortedDictionary

// ❌ NON-DETERMINISTIC - Floating point without epsilon
if (a == b) { } // Use Mathf.Approximately

// ❌ NON-DETERMINISTIC - LINQ without ordering
var first = list.First(); // Use OrderBy if order matters

// ✅ DETERMINISTIC - Seeded RNG
var rng = new System.Random(seed);
float value = (float)rng.NextDouble();

// ✅ DETERMINISTIC - Explicit ordering
foreach (var item in dictionary.OrderBy(kvp => kvp.Key)) { }

// ✅ DETERMINISTIC - Epsilon comparison
if (Mathf.Approximately(a, b)) { }
```

## Failure Modes

### State Hash Mismatch

**Symptoms**: Same inputs produce different state hashes
**Root Causes**:
- Unseeded Random usage
- Dictionary iteration order
- Floating point non-determinism
- Timing-dependent code
- Platform-specific behavior

### Replay Deserialization Failure

**Symptoms**: Saved replay cannot be loaded
**Root Causes**:
- Schema changes without migration
- Missing type registrations
- Version mismatch

## Remediation Steps

### Fix State Hash Mismatch

1. Run determinism gate with debug logging
2. Identify first divergent frame
3. Compare state dumps between runs
4. Locate non-deterministic code path
5. Apply determinism fix (see checklist above)
6. Re-run gate to verify

### Fix Replay Corruption

1. Check replay file format version
2. Verify all serialized types have [Serializable]
3. Add migration path if schema changed
4. Test replay load/save cycle
5. Re-run gate

### Add Determinism Test for New System

```csharp
[Test]
public void NewSystem_IsDeterministic()
{
    // Arrange
    const int seed = 12345;
    const int iterations = 100;
    
    // Act - Run twice with same seed
    var run1 = RunSimulation(seed, iterations);
    var run2 = RunSimulation(seed, iterations);
    
    // Assert
    Assert.AreEqual(run1.StateHash, run2.StateHash);
    Assert.AreEqual(run1.FinalState, run2.FinalState);
}
```

## State Hash Implementation

```csharp
// Assets/Scripts/Core/Determinism/StateHash.cs
public static class StateHash
{
    public static int Compute(GameState state)
    {
        unchecked
        {
            int hash = 17;
            hash = hash * 31 + state.TurnNumber.GetHashCode();
            hash = hash * 31 + ComputeEntityHash(state.Entities);
            hash = hash * 31 + ComputeResourceHash(state.Resources);
            return hash;
        }
    }
}
```

## Replay File Format

```json
{
  "version": "1.2.0",
  "seed": 12345,
  "initialState": { /* serialized state */ },
  "inputs": [
    {"frame": 0, "playerId": 1, "action": "move", "data": {...}},
    {"frame": 5, "playerId": 2, "action": "attack", "data": {...}}
  ],
  "finalHash": "a1b2c3d4"
}
```

## Integration with Other Gates

- **Requires**: [[Unit_Tests_Gate]] must pass
- **Enables**: [[Headless_Match_Batch_Gate]] (batch testing)
- **Required by**: [[Release_Certification_Checklist]] for multiplayer games
- **Metrics feed**: [[Regression_Harness_Spec]]

## Platform Considerations

| Platform | Determinism Notes |
|----------|-------------------|
| Windows | Baseline platform |
| Linux | May have FP differences - use strict FP mode |
| macOS | ARM vs Intel may differ - test both |
| WebGL | Single-threaded only, no threading issues |

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| Mathf.Sin slightly different on ARM | Use custom sin approximation | DET-123 |
| Dictionary order varies by runtime | Always use SortedDictionary | DET-456 |
| DateTime.Now in save files | Use UTC timestamps only | DET-789 |
