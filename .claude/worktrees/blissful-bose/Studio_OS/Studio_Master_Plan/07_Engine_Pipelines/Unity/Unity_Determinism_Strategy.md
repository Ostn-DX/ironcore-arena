---
title: Unity Determinism Strategy
type: rule
layer: architecture
status: active
tags:
  - unity
  - determinism
  - replay
  - networking
  - random
  - physics
depends_on:
  - "[Unity_Pipeline_Overview]"
used_by:
  - "[Unity_Rollback_Strategy]]"
  - "[[Unity_PlayMode_Test_Framework]"
---

# Unity Determinism Strategy

Determinism in Unity enables replay systems, networked gameplay synchronization, and reproducible testing. However, Unity's default behavior is non-deterministic across platforms and even runs. This document defines strategies for achieving deterministic behavior where required and establishing acceptable boundaries.

## Determinism Scope

### Full Determinism (Target)
- Game logic state
- Random number generation
- Fixed timestep physics
- Serialized game state

### Acceptable Non-Determinism
- Visual effects (particles, animations)
- Audio timing (within 16ms)
- Rendering order
- Garbage collection timing
- Thread scheduling

## Determinism Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  DETERMINISM ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  Input Feed  │───▶│  Game Logic  │───▶│  State Hash  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                   │                     │         │
│         │            ┌──────┴──────┐              │         │
│         │            │             │              │         │
│         │       ┌────▼────┐  ┌────▼────┐         │         │
│         │       │ Physics │  │  Random │         │         │
│         │       │ (Fixed) │  │  (Seed) │         │         │
│         │       └────┬────┘  └────┬────┘         │         │
│         │            │            │              │         │
│         └────────────┴────────────┴──────────────┘         │
│                                                              │
│  Deterministic: Input → Logic → State → Hash (Reproducible) │
└─────────────────────────────────────────────────────────────┘
```

## Random Number Generation

### Deterministic Random

```csharp
public class DeterministicRandom
{
    private System.Random _random;
    private int _seed;
    private int _callCount;

    public DeterministicRandom(int seed)
    {
        _seed = seed;
        _random = new System.Random(seed);
        _callCount = 0;
    }

    public int Next(int min, int max)
    {
        _callCount++;
        return _random.Next(min, max);
    }

    public float NextFloat()
    {
        _callCount++;
        return (float)_random.NextDouble();
    }

    // Serialize state for save/replay
    public RandomState GetState() => new RandomState
    {
        Seed = _seed,
        CallCount = _callCount
    };

    public void SetState(RandomState state)
    {
        _seed = state.Seed;
        _callCount = state.CallCount;
        _random = new System.Random(_seed);
        
        // Replay calls to reach same state
        for (int i = 0; i < _callCount; i++)
            _random.Next();
    }
}

public struct RandomState
{
    public int Seed;
    public int CallCount;
}
```

### Unity Random Replacement

```csharp
public static class GameRandom
{
    private static DeterministicRandom _random;

    public static void Initialize(int seed)
    {
        _random = new DeterministicRandom(seed);
    }

    public static int Range(int min, int max) => _random.Next(min, max);
    public static float Range(float min, float max) => 
        min + _random.NextFloat() * (max - min);

    public static RandomState GetState() => _random.GetState();
    public static void SetState(RandomState state) => _random.SetState(state);
}
```

## Physics Determinism

### Fixed Timestep Configuration

```
// Project Settings > Time
Fixed Timestep: 0.02 (50Hz)
Maximum Allowed Timestep: 0.1
```

### Physics Settings for Determinism

```
// Edit > Project Settings > Physics
Auto Sync Transforms: false
Reuse Collision Callbacks: true
Default Solver Iterations: 6
Default Solver Velocity Iterations: 1
```

### Deterministic Physics Wrapper

```csharp
public class DeterministicPhysics
{
    // Use only FixedUpdate for physics
    public static void Simulate(float deltaTime)
    {
        Physics.Simulate(deltaTime);
    }

    // Deterministic raycast ordering
    public static RaycastHit[] RaycastAll(Vector3 origin, Vector3 direction, float maxDistance)
    {
        var hits = Physics.RaycastAll(origin, direction, maxDistance);
        
        // Sort by distance for deterministic ordering
        System.Array.Sort(hits, (a, b) => 
            a.distance.CompareTo(b.distance));
        
        return hits;
    }
}
```

## Floating Point Determinism

### Cross-Platform Considerations

| Platform | Float Behavior |
|----------|---------------|
| Windows x86 | x87 FPU (80-bit internal) |
| Windows x64 | SSE2 (32-bit) |
| macOS ARM | NEON (32-bit) |
| Linux | SSE2 (32-bit) |

### Mitigation Strategies

```csharp
public static class DeterministicMath
{
    // Use epsilon comparisons
    public const float EPSILON = 0.0001f;

    public static bool Approximately(float a, float b)
    {
        return Math.Abs(a - b) < EPSILON;
    }

    // Round to fixed precision for serialization
    public static float RoundToPrecision(float value, int decimals = 4)
    {
        return (float)Math.Round(value, decimals);
    }

    // Deterministic min/max
    public static float Min(float a, float b) => a < b ? a : b;
    public static float Max(float a, float b) => a > b ? a : b;
}
```

## State Serialization

### Game State Snapshot

```csharp
[Serializable]
public class GameState
{
    public int FrameNumber;
    public int RandomSeed;
    public int RandomCallCount;
    public List<EntityState> Entities;
    public byte[] PhysicsState; // Serialized physics

    public byte[] Serialize()
    {
        return MessagePackSerializer.Serialize(this);
    }

    public static GameState Deserialize(byte[] data)
    {
        return MessagePackSerializer.Deserialize<GameState>(data);
    }

    // Deterministic hash for verification
    public ulong ComputeHash()
    {
        using (var xxh = new XXH64())
        {
            xxh.Update(Serialize());
            return xxh.Hash;
        }
    }
}
```

## Determinism Verification

### Checksum Validation

```csharp
public class DeterminismValidator : MonoBehaviour
{
    private List<ulong> _frameHashes = new();
    
    void FixedUpdate()
    {
        var state = GameStateManager.CaptureState();
        ulong hash = state.ComputeHash();
        _frameHashes.Add(hash);
        
        // Log for replay verification
        Debug.Log($"Frame {Time.fixedTime}: Hash = {hash:X16}");
    }

    public bool VerifyAgainstRecording(List<ulong> recordedHashes)
    {
        for (int i = 0; i < Math.Min(_frameHashes.Count, recordedHashes.Count); i++)
        {
            if (_frameHashes[i] != recordedHashes[i])
            {
                Debug.LogError($"Determinism failure at frame {i}");
                return false;
            }
        }
        return true;
    }
}
```

## Replay System

### Recording Inputs

```csharp
public class InputRecorder
{
    private List<InputFrame> _inputs = new();

    public void RecordFrame(int frame, InputState input)
    {
        _inputs.Add(new InputFrame
        {
            Frame = frame,
            MoveX = input.MoveX,
            MoveY = input.MoveY,
            Buttons = input.Buttons
        });
    }

    public InputState GetInputForFrame(int frame)
    {
        var inputFrame = _inputs.Find(i => i.Frame == frame);
        return inputFrame?.ToInputState() ?? InputState.Default;
    }
}
```

## Acceptable Non-Determinism Boundaries

### Visual Systems (Non-Deterministic OK)
- Particle systems
- Animation blending
- Shader effects
- Post-processing

### Audio Systems (16ms tolerance)
- Audio clip playback timing
- Spatial audio calculations
- Mixer transitions

### When Non-Determinism is Acceptable
1. Single-player games without replay
2. Client-authoritative multiplayer
3. Visual-only effects
4. Non-competitive gameplay

## Enforcement

### CI Gates
- Determinism test for 1000 frames
- Cross-platform hash comparison
- Replay verification

### Runtime Checks
- Hash logging in development builds
- Desync detection in multiplayer

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Hash mismatch | Error | Block release |
| Replay desync | Error | Debug + fix |
| Physics divergence | Warning | Review required |
