---
title: "Unity C# Style Guide"
type: rule
layer: architecture
status: active
tags:
  - unity
  - csharp
  - style
  - coding-standards
  - conventions
depends_on:
  - "[Unity_Pipeline_Overview]"
used_by:
  - "[Unity_Analyzers_Setup]]"
  - "[[Unity_CI_Template]"
---

# Unity C# Style Guide

Consistent code style improves readability, reduces cognitive load, and enables AI agents to work effectively across projects. This document defines the mandatory C# coding standards for all Studio OS Unity projects.

## Naming Conventions

### General Rules

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `PlayerController`, `GameManager` |
| Interfaces | PascalCase + I prefix | `IPlayerInput`, `ISaveable` |
| Methods | PascalCase | `Move()`, `TakeDamage()` |
| Properties | PascalCase | `Health`, `IsDead` |
| Fields (private) | _camelCase with underscore | `_health`, `_isDead` |
| Fields (public) | PascalCase | `MaxHealth` |
| Constants | PascalCase | `MaxPlayers` |
| Enums | PascalCase | `GameState` |
| Enum values | PascalCase | `Playing`, `Paused` |
| Parameters | camelCase | `damageAmount`, `targetPosition` |
| Local variables | camelCase | `currentHealth`, `deltaTime` |
| Events | PascalCase + On prefix | `OnHealthChanged`, `OnDeath` |
| UnityEvents | PascalCase | `OnClick`, `OnValueChanged` |

### Examples

```csharp
// Class naming
public class PlayerController : MonoBehaviour, IDamageable
{
    // Constants
    public const int MaxHealth = 100;
    
    // Private fields
    private int _currentHealth;
    private bool _isInvulnerable;
    private Vector3 _targetPosition;
    
    // Public properties
    public int Health => _currentHealth;
    public bool IsDead => _currentHealth <= 0;
    
    // Events
    public event Action<int> OnHealthChanged;
    public event Action OnDeath;
    
    // UnityEvents (for inspector wiring)
    public UnityEvent OnDamageTaken;
    
    // Methods
    public void TakeDamage(int damageAmount)
    {
        if (_isInvulnerable || IsDead)
            return;
            
        _currentHealth = Mathf.Max(0, _currentHealth - damageAmount);
        OnHealthChanged?.Invoke(_currentHealth);
        OnDamageTaken?.Invoke();
        
        if (IsDead)
        {
            OnDeath?.Invoke();
        }
    }
}
```

## Code Organization

### File Structure

```csharp
// 1. Using statements
using System;
using UnityEngine;

// 2. Namespace
namespace StudioOS.Gameplay.Player
{
    // 3. Class declaration
    public class PlayerController : MonoBehaviour
    {
        // 4. Nested types (enums, structs)
        public enum PlayerState
        {
            Idle,
            Moving,
            Attacking,
            Dead
        }
        
        // 5. Constants
        private const float MoveSpeed = 5f;
        private const float RotationSpeed = 360f;
        
        // 6. Serialized fields
        [SerializeField] private float _moveSpeed = MoveSpeed;
        [SerializeField] private float _rotationSpeed = RotationSpeed;
        
        // 7. Private fields
        private PlayerState _currentState;
        private Vector3 _inputDirection;
        private CharacterController _characterController;
        
        // 8. Public properties
        public PlayerState CurrentState => _currentState;
        public bool IsMoving => _currentState == PlayerState.Moving;
        
        // 9. Events
        public event Action<PlayerState> OnStateChanged;
        
        // 10. Unity lifecycle methods
        private void Awake()
        {
            _characterController = GetComponent<CharacterController>();
        }
        
        private void Update()
        {
            HandleInput();
            UpdateMovement();
        }
        
        // 11. Public methods
        public void SetState(PlayerState newState)
        {
            if (_currentState == newState)
                return;
                
            _currentState = newState;
            OnStateChanged?.Invoke(newState);
        }
        
        // 12. Private methods
        private void HandleInput()
        {
            float horizontal = Input.GetAxis("Horizontal");
            float vertical = Input.GetAxis("Vertical");
            _inputDirection = new Vector3(horizontal, 0, vertical).normalized;
        }
        
        private void UpdateMovement()
        {
            if (_inputDirection.sqrMagnitude > 0.01f)
            {
                SetState(PlayerState.Moving);
                _characterController.Move(_inputDirection * _moveSpeed * Time.deltaTime);
            }
            else
            {
                SetState(PlayerState.Idle);
            }
        }
    }
}
```

## Formatting Rules

### Braces

```csharp
// Opening brace on same line
public void Method()
{
    // Content
}

// Always use braces for control structures
if (condition)
{
    DoSomething();
}

// NOT this way
if (condition)
    DoSomething();
```

### Indentation
- Use 4 spaces (not tabs)
- Indent each nested level

### Line Length
- Maximum 120 characters per line
- Break long lines at logical points

```csharp
// Good
var result = SomeLongMethodName(
    parameter1,
    parameter2,
    parameter3);

// Good
var query = from item in collection
            where item.Value > threshold
            select item.Name;
```

### Spacing

```csharp
// Operators: spaces around
var sum = a + b;
var result = (x * y) + z;

// Method calls: no space before parentheses
Method();
Method(argument);

// Generic types: no space
List<int> numbers;
Dictionary<string, object> data;

// Commas: space after
Method(arg1, arg2, arg3);

// Colons: space after
public class Derived : Base, IInterface
```

## Comments

### XML Documentation

```csharp
/// <summary>
/// Applies damage to the player.
/// </summary>
/// <param name="damageAmount">Amount of damage to apply.</param>
/// <param name="damageSource">Source of the damage.</param>
/// <returns>True if damage was applied, false if blocked or invulnerable.</returns>
public bool TakeDamage(int damageAmount, GameObject damageSource)
{
    // Implementation
}
```

### Code Comments

```csharp
// Use // for single-line comments
// Explain WHY, not WHAT

/*
 * Use block comments for longer explanations
 * or temporarily disabled code
 */

// TODO: Comments for future work
// FIXME: Comments for known issues
// HACK: Comments for temporary solutions
// NOTE: Comments for important information
```

## Unity-Specific Conventions

### SerializeField

```csharp
// Always use [SerializeField] for inspector-exposed fields
// Never use public fields for serialization

// Good
[SerializeField] private float _moveSpeed;
[SerializeField] private LayerMask _groundLayer;

// Bad
public float moveSpeed; // Don't do this
```

### RequiredComponent

```csharp
// Use RequireComponent for dependencies
[RequireComponent(typeof(CharacterController))]
[RequireComponent(typeof(Animator))]
public class PlayerController : MonoBehaviour
{
    private void Awake()
    {
        // Safe to GetComponent - guaranteed to exist
        _characterController = GetComponent<CharacterController>();
    }
}
```

### Null Checks

```csharp
// Use null-conditional operators
var player = FindObjectOfType<PlayerController>()?.gameObject;

// Use null-coalescing for defaults
var config = GameConfig.Instance ?? GameConfig.Default;

// Validate serialized fields
private void OnValidate()
{
    if (_playerPrefab == null)
    {
        Debug.LogWarning("Player prefab not assigned", this);
    }
}
```

### Coroutines

```csharp
// Use IEnumerator for coroutines
private IEnumerator MoveToPosition(Vector3 target, float duration)
{
    Vector3 start = transform.position;
    float elapsed = 0f;
    
    while (elapsed < duration)
    {
        elapsed += Time.deltaTime;
        float t = elapsed / duration;
        transform.position = Vector3.Lerp(start, target, t);
        yield return null;
    }
    
    transform.position = target;
}

// Use async/await when possible (preferred)
private async Task MoveToPositionAsync(Vector3 target, float duration)
{
    // Modern C# approach
}
```

## Performance Guidelines

### Object Pooling

```csharp
// Use pooling for frequently instantiated objects
public class BulletPool : MonoBehaviour
{
    [SerializeField] private Bullet _bulletPrefab;
    [SerializeField] private int _poolSize = 50;
    
    private Queue<Bullet> _pool = new();
    
    public Bullet GetBullet()
    {
        if (_pool.Count > 0)
        {
            var bullet = _pool.Dequeue();
            bullet.gameObject.SetActive(true);
            return bullet;
        }
        
        return Instantiate(_bulletPrefab);
    }
    
    public void ReturnBullet(Bullet bullet)
    {
        bullet.gameObject.SetActive(false);
        _pool.Enqueue(bullet);
    }
}
```

### Cache References

```csharp
// Cache component references in Awake/Start
public class CachedReferences : MonoBehaviour
{
    private Transform _transform;
    private Rigidbody _rigidbody;
    private Animator _animator;
    
    private void Awake()
    {
        _transform = transform;
        _rigidbody = GetComponent<Rigidbody>();
        _animator = GetComponent<Animator>();
    }
    
    private void Update()
    {
        // Use cached references
        _transform.position += Vector3.up * Time.deltaTime;
    }
}
```

### Avoid in Update

```csharp
// DON'T do these in Update()
void Update()
{
    GetComponent<Rigidbody>(); // Expensive lookup
    FindObjectOfType<Player>(); // Expensive search
    Camera.main; // Expensive tag search
    GameObject.Find("Player"); // Expensive name search
}
```

## Async/Await Patterns

```csharp
// Use async/await for async operations
public async Task LoadLevelAsync(string levelName)
{
    var operation = SceneManager.LoadSceneAsync(levelName);
    
    while (!operation.isDone)
    {
        float progress = operation.progress;
        UpdateLoadingUI(progress);
        await Task.Yield();
    }
}

// Handle exceptions
public async Task SafeOperationAsync()
{
    try
    {
        await RiskyOperationAsync();
    }
    catch (Exception ex)
    {
        Debug.LogError($"Operation failed: {ex.Message}");
    }
}

// Cancellation support
public async Task CancellableOperationAsync(CancellationToken token)
{
    await Task.Delay(1000, token);
}
```

## Enforcement

### EditorConfig

```ini
# .editorconfig
root = true

[*.{cs}]
indent_style = space
indent_size = 4
trim_trailing_whitespace = true
insert_final_newline = true
max_line_length = 120
```

### CI Gates
- Style validation passes
- No naming violations
- XML documentation for public APIs

### Failure Modes
| Violation | Severity | Response |
|---------|----------|----------|
| Naming violation | Warning | CI warning |
| Missing documentation | Warning | Review required |
| Formatting issue | Info | Auto-fix suggestion |
