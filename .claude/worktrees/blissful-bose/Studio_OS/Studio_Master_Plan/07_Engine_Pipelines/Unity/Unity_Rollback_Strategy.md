---
title: Unity Rollback Strategy
type: rule
layer: architecture
status: active
tags:
  - unity
  - rollback
  - determinism
  - networking
  - state-sync
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Determinism_Strategy]"
used_by:
  - "[Unity_PlayMode_Test_Framework]"
---

# Unity Rollback Strategy

When full determinism cannot be achieved or maintained, rollback strategies provide a path to recover from desync, handle network latency, and maintain gameplay consistency. This document defines rollback patterns for Unity projects where determinism fails.

## Rollback Scenarios

### When Rollback is Required

| Scenario | Cause | Rollback Type |
|----------|-------|---------------|
| Network desync | Latency, packet loss | State rollback |
| Physics divergence | Platform differences | Position correction |
| Random divergence | Seed mismatch | Reseed + resync |
| Save corruption | File I/O error | Backup restore |
| Replay failure | Version mismatch | Graceful degradation |

## Rollback Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ROLLBACK ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ State Buffer│    │  Predictor  │    │  Corrector  │     │
│  │  (History)  │    │  (Client)   │    │  (Server)   │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            ▼                                │
│                    ┌───────────────┐                        │
│                    │  Rollback     │                        │
│                    │  Controller   │                        │
│                    └───────┬───────┘                        │
│                            │                                │
│         ┌──────────────────┼──────────────────┐             │
│         ▼                  ▼                  ▼             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ Full State  │    │ Delta State │    │  Snapshot   │     │
│  │  Rollback   │    │  Rollback   │    │   Restore   │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## State Buffer System

### Ring Buffer Implementation

```csharp
public class StateBuffer<T> where T : IGameState
{
    private readonly T[] _states;
    private int _currentIndex;
    private readonly int _capacity;

    public StateBuffer(int capacity)
    {
        _capacity = capacity;
        _states = new T[capacity];
    }

    public void Push(T state, int frame)
    {
        _currentIndex = frame % _capacity;
        _states[_currentIndex] = state;
    }

    public T GetState(int frame)
    {
        int index = frame % _capacity;
        return _states[index];
    }

    public bool HasState(int frame)
    {
        int index = frame % _capacity;
        return _states[index]?.Frame == frame;
    }

    public void RollbackTo(int frame)
    {
        // Invalidate all states after frame
        for (int i = frame + 1; i <= _currentIndex; i++)
        {
            int index = i % _capacity;
            _states[index] = default;
        }
        _currentIndex = frame % _capacity;
    }
}
```

## Network Rollback (GGPO-Style)

### Input Prediction

```csharp
public class InputPredictor
{
    private InputState _lastConfirmedInput;
    private int _predictionFrame;

    public InputState PredictInput(int frame)
    {
        // Simple prediction: repeat last input
        return _lastConfirmedInput;
    }

    public void ConfirmInput(int frame, InputState actualInput)
    {
        var predicted = PredictInput(frame);
        
        if (!predicted.Equals(actualInput))
        {
            // Misprediction - trigger rollback
            OnMisprediction?.Invoke(frame, actualInput);
        }
        
        _lastConfirmedInput = actualInput;
    }
}
```

### Rollback Controller

```csharp
public class RollbackController : MonoBehaviour
{
    [SerializeField] private int _rollbackFrames = 8;
    [SerializeField] private int _inputDelay = 2;

    private StateBuffer<GameState> _stateBuffer;
    private InputRecorder _inputRecorder;
    private List<IRollbackEntity> _entities;

    void Awake()
    {
        _stateBuffer = new StateBuffer<GameState>(_rollbackFrames * 2);
        _inputRecorder = new InputRecorder();
        _entities = FindObjectsOfType<MonoBehaviour>()
            .OfType<IRollbackEntity>().ToList();
    }

    void FixedUpdate()
    {
        int currentFrame = Time.frameCount;
        
        // Save state before simulation
        var state = CaptureState();
        _stateBuffer.Push(state, currentFrame);

        // Simulate with predicted inputs
        SimulateFrame(currentFrame);
    }

    public void OnRemoteInputReceived(int frame, InputState input)
    {
        // Check if we need to rollback
        if (frame < Time.frameCount - _rollbackFrames)
        {
            // Too old to rollback
            Debug.LogWarning($"Input too old: frame {frame}");
            return;
        }

        // Check for misprediction
        var predicted = _inputRecorder.GetInputForFrame(frame);
        if (!predicted.Equals(input))
        {
            PerformRollback(frame, input);
        }
    }

    private void PerformRollback(int toFrame, InputState correctedInput)
    {
        // 1. Restore state at rollback frame
        var state = _stateBuffer.GetState(toFrame);
        RestoreState(state);

        // 2. Update input for that frame
        _inputRecorder.UpdateInput(toFrame, correctedInput);

        // 3. Re-simulate forward
        for (int frame = toFrame; frame <= Time.frameCount; frame++)
        {
            var input = _inputRecorder.GetInputForFrame(frame);
            SimulateFrameWithInput(frame, input);
            
            // Update state buffer
            var newState = CaptureState();
            _stateBuffer.Push(newState, frame);
        }

        OnRollbackComplete?.Invoke(toFrame);
    }

    private void SimulateFrame(int frame)
    {
        var input = _inputRecorder.GetInputForFrame(frame);
        SimulateFrameWithInput(frame, input);
    }

    private void SimulateFrameWithInput(int frame, InputState input)
    {
        foreach (var entity in _entities)
        {
            entity.Simulate(frame, input);
        }
    }

    private GameState CaptureState()
    {
        var state = new GameState
        {
            Frame = Time.frameCount,
            EntityStates = _entities.Select(e => e.CaptureState()).ToList()
        };
        return state;
    }

    private void RestoreState(GameState state)
    {
        for (int i = 0; i < _entities.Count; i++)
        {
            _entities[i].RestoreState(state.EntityStates[i]);
        }
    }
}
```

## Entity Rollback Interface

```csharp
public interface IRollbackEntity
{
    void Simulate(int frame, InputState input);
    EntityState CaptureState();
    void RestoreState(EntityState state);
}

public class RollbackPlayer : MonoBehaviour, IRollbackEntity
{
    private Vector3 _position;
    private Vector3 _velocity;

    public void Simulate(int frame, InputState input)
    {
        // Apply input
        _velocity += new Vector3(input.MoveX, 0, input.MoveY) * acceleration;
        _velocity *= damping;
        _position += _velocity * Time.fixedDeltaTime;
        
        transform.position = _position;
    }

    public EntityState CaptureState()
    {
        return new PlayerState
        {
            Position = _position,
            Velocity = _velocity
        };
    }

    public void RestoreState(EntityState state)
    {
        var playerState = (PlayerState)state;
        _position = playerState.Position;
        _velocity = playerState.Velocity;
        transform.position = _position;
    }
}
```

## Save/Load Rollback

### Backup Strategy

```csharp
public class SaveRollbackSystem
{
    private const int MAX_BACKUPS = 5;
    private string _savePath;
    private string _backupPath;

    public async Task<bool> SaveWithBackup(GameState state)
    {
        try
        {
            // Rotate backups
            RotateBackups();
            
            // Save current to backup
            var currentBackup = Path.Combine(_backupPath, "save_backup_0.dat");
            if (File.Exists(_savePath))
            {
                File.Copy(_savePath, currentBackup, true);
            }
            
            // Save new state
            var data = state.Serialize();
            await File.WriteAllBytesAsync(_savePath, data);
            
            return true;
        }
        catch (Exception ex)
        {
            Debug.LogError($"Save failed: {ex.Message}");
            return false;
        }
    }

    public async Task<GameState> LoadWithRollback()
    {
        try
        {
            // Try primary save
            if (File.Exists(_savePath))
            {
                var data = await File.ReadAllBytesAsync(_savePath);
                return GameState.Deserialize(data);
            }
        }
        catch (Exception ex)
        {
            Debug.LogError($"Primary save corrupt: {ex.Message}");
        }

        // Try backups
        for (int i = 0; i < MAX_BACKUPS; i++)
        {
            var backupPath = Path.Combine(_backupPath, $"save_backup_{i}.dat");
            try
            {
                if (File.Exists(backupPath))
                {
                    var data = await File.ReadAllBytesAsync(backupPath);
                    var state = GameState.Deserialize(data);
                    Debug.Log($"Restored from backup {i}");
                    return state;
                }
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"Backup {i} corrupt: {ex.Message}");
            }
        }

        // All saves failed - return new game state
        Debug.LogError("All save files corrupt - starting new game");
        return GameState.NewGame();
    }

    private void RotateBackups()
    {
        for (int i = MAX_BACKUPS - 1; i > 0; i--)
        {
            var oldPath = Path.Combine(_backupPath, $"save_backup_{i-1}.dat");
            var newPath = Path.Combine(_backupPath, $"save_backup_{i}.dat");
            
            if (File.Exists(oldPath))
            {
                File.Copy(oldPath, newPath, true);
            }
        }
    }
}
```

## Visual Rollback Handling

### Smooth Correction

```csharp
public class VisualRollbackHandler : MonoBehaviour
{
    [SerializeField] private float _correctionSpeed = 10f;
    
    private Vector3 _authoritativePosition;
    private Vector3 _visualPosition;

    void Update()
    {
        // Smoothly interpolate to authoritative position
        _visualPosition = Vector3.Lerp(
            _visualPosition, 
            _authoritativePosition, 
            _correctionSpeed * Time.deltaTime
        );
        
        transform.position = _visualPosition;
    }

    public void SetAuthoritativePosition(Vector3 position)
    {
        _authoritativePosition = position;
    }

    public void SnapToAuthoritative()
    {
        _visualPosition = _authoritativePosition;
        transform.position = _visualPosition;
    }
}
```

## Rollback Limits

### Maximum Rollback Window

```csharp
public class RollbackLimits
{
    // Maximum frames to rollback
    public const int MAX_ROLLBACK_FRAMES = 8;
    
    // Maximum time to spend on rollback
    public const float MAX_ROLLBACK_TIME_MS = 16f;
    
    // Maximum state buffer size
    public const int MAX_STATE_BUFFER = 256;

    public static bool CanRollback(int fromFrame, int toFrame)
    {
        int frames = fromFrame - toFrame;
        return frames > 0 && frames <= MAX_ROLLBACK_FRAMES;
    }
}
```

## Enforcement

### Testing Requirements
- Rollback unit tests
- Network simulation tests
- Save corruption tests
- Performance benchmarks

### Monitoring
- Rollback frequency logging
- Prediction accuracy metrics
- State size tracking

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Rollback exceeds limit | Error | Disconnect/resync |
| State corruption | Error | Restore from backup |
| Prediction accuracy <90% | Warning | Tune prediction |
| Rollback time >16ms | Warning | Optimize simulation |
