---
title: Unity PlayMode Test Framework
type: system
layer: execution
status: active
tags:
  - unity
  - testing
  - playmode
  - runtime
  - nunit
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Assembly_Definition_Strategy]"
used_by:
  - "[Unity_CI_Template]]"
  - "[[Unity_Build_Automation]"
---

# Unity PlayMode Test Framework

PlayMode tests execute in the Unity runtime environment, allowing testing of MonoBehaviour components, physics, coroutines, and time-dependent behavior. This framework defines the mandatory structure and patterns for runtime testing in Studio OS Unity projects.

## Test Framework Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PLAYMODE TEST ARCHITECTURE                │
├─────────────────────────────────────────────────────────────┤
│  Test Runner → Test Assembly → Runtime Assembly → Unity API │
├─────────────────────────────────────────────────────────────┤
│  Execution Context: PlayMode (Runtime)                       │
│  Framework: Unity Test Framework + NUnit                     │
│  Location: Assets/_Project/Tests/Runtime/                    │
└─────────────────────────────────────────────────────────────┘
```

## Test Assembly Setup

### Required Package
```json
// Packages/manifest.json
{
  "dependencies": {
    "com.unity.test-framework": "1.1.33"
  }
}
```

### Test Assembly Definition

**Location**: `Assets/_Project/Tests/Runtime/Tests.Runtime.asmdef`

```json
{
    "name": "Tests.Runtime",
    "rootNamespace": "StudioOS.Tests.Runtime",
    "references": [
        "Core",
        "Gameplay",
        "UI",
        "Services",
        "UnityEngine.TestRunner",
        "UnityEditor.TestRunner"
    ],
    "includePlatforms": [],
    "excludePlatforms": [],
    "allowUnsafeCode": false,
    "overrideReferences": true,
    "precompiledReferences": [
        "nunit.framework.dll"
    ],
    "autoReferenced": false,
    "defineConstraints": [
        "UNITY_INCLUDE_TESTS"
    ],
    "versionDefines": [],
    "noEngineReferences": false
}
```

## Test Categories

### 1. Component Tests

Test MonoBehaviour components in isolation:

```csharp
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using System.Collections;

namespace StudioOS.Tests.Runtime.Gameplay
{
    public class PlayerControllerTests
    {
        private GameObject _player;
        private PlayerController _controller;

        [SetUp]
        public void Setup()
        {
            _player = new GameObject("TestPlayer");
            _controller = _player.AddComponent<PlayerController>();
        }

        [TearDown]
        public void Teardown()
        {
            Object.DestroyImmediate(_player);
        }

        [Test]
        public void PlayerController_WhenInitialized_HasDefaultHealth()
        {
            // Arrange & Act (done in Setup)
            
            // Assert
            Assert.AreEqual(100, _controller.Health);
        }

        [UnityTest]
        public IEnumerator PlayerController_WhenDamaged_HealthDecreases()
        {
            // Arrange
            int initialHealth = _controller.Health;
            
            // Act
            _controller.TakeDamage(10);
            yield return null; // Wait one frame
            
            // Assert
            Assert.AreEqual(initialHealth - 10, _controller.Health);
        }
    }
}
```

### 2. Integration Tests

Test component interactions:

```csharp
public class CombatIntegrationTests
{
    [UnityTest]
    public IEnumerator Combat_PlayerAttacksEnemy_EnemyTakesDamage()
    {
        // Arrange
        var player = CreatePlayer();
        var enemy = CreateEnemy();
        var weapon = CreateWeapon();
        
        // Act
        player.Equip(weapon);
        player.Attack(enemy);
        yield return new WaitForSeconds(0.5f);
        
        // Assert
        Assert.Less(enemy.Health, enemy.MaxHealth);
        
        // Cleanup
        Cleanup(player, enemy, weapon);
    }
}
```

### 3. Scene Tests

Test in actual scene context:

```csharp
public class SceneTests
{
    [UnityTest]
    public IEnumerator Scene_LoadMainMenu_MenuIsActive()
    {
        // Act
        SceneManager.LoadScene("Menu_Main");
        yield return new WaitForSeconds(1f);
        
        // Assert
        var menu = GameObject.FindWithTag("MainMenu");
        Assert.IsNotNull(menu);
        Assert.IsTrue(menu.activeInHierarchy);
    }
}
```

### 4. Time-Based Tests

Test time-dependent behavior:

```csharp
public class TimeBasedTests
{
    [UnityTest]
    public IEnumerator Timer_AfterDuration_CallbackInvoked()
    {
        // Arrange
        bool callbackInvoked = false;
        var timer = new GameTimer(1f, () => callbackInvoked = true);
        
        // Act
        timer.Start();
        yield return new WaitForSeconds(1.1f);
        
        // Assert
        Assert.IsTrue(callbackInvoked);
    }
}
```

## Test Attributes

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `[Test]` | Synchronous test | Unit tests |
| `[UnityTest]` | Coroutine test | Frame-dependent tests |
| `[SetUp]` | Pre-test setup | Create test objects |
| `[TearDown]` | Post-test cleanup | Destroy test objects |
| `[OneTimeSetUp]` | Suite setup | Load test scene |
| `[OneTimeTearDown]` | Suite cleanup | Unload scene |
| `[Category("Integration")]` | Test category | Filter in runner |
| `[Timeout(10000)]` | Test timeout | Prevent hangs |

## Test Scene Pattern

### Dedicated Test Scene

Create a minimal test scene for component tests:

```csharp
public static class TestScene
{
    private const string TestSceneName = "Test_Empty";
    
    [OneTimeSetUp]
    public static IEnumerator LoadTestScene()
    {
        SceneManager.LoadScene(TestSceneName);
        yield return null;
    }
    
    [OneTimeTearDown]
    public static IEnumerator UnloadTestScene()
    {
        SceneManager.UnloadSceneAsync(TestSceneName);
        yield return null;
    }
}
```

## Mocking and Stubbing

### Service Mocking

```csharp
public class MockSaveService : ISaveService
{
    private Dictionary<string, object> _data = new();
    
    public void Save<T>(string key, T data) => _data[key] = data;
    public T Load<T>(string key) => (T)_data[key];
    public bool Exists(string key) => _data.ContainsKey(key);
}

[Test]
public void SaveSystem_WithMock_WorksCorrectly()
{
    // Arrange
    var mockService = new MockSaveService();
    var saveSystem = new SaveSystem(mockService);
    
    // Act
    saveSystem.SaveProgress(5);
    
    // Assert
    Assert.AreEqual(5, saveSystem.LoadProgress());
}
```

## Test Execution Order

### Explicit Ordering

```csharp
[TestFixture]
[TestOrder(1)]
public class CoreSystemTests { }

[TestFixture]
[TestOrder(2)]
public class GameplayTests { }
```

## CI Integration

### Command Line Execution

```bash
# Run PlayMode tests
/Applications/Unity/Unity.app/Contents/MacOS/Unity \
  -batchmode \
  -nographics \
  -runTests \
  -testPlatform PlayMode \
  -testResults "playmode-results.xml" \
  -projectPath "$(pwd)"
```

### Test Results Format

Unity Test Framework outputs NUnit-compatible XML:

```xml
<test-run id="2" name="Tests.Runtime.dll" 
          testcasecount="42" result="Passed"
          total="42" passed="42" failed="0">
  <test-suite name="StudioOS.Tests.Runtime">
    <!-- Test cases -->
  </test-suite>
</test-run>
```

## Performance Considerations

### Test Isolation
- Each test should be independent
- Use `[TearDown]` for cleanup
- Avoid static state

### Execution Time Targets
| Test Type | Target Duration |
|-----------|-----------------|
| Unit tests | <100ms each |
| Integration tests | <1s each |
| Scene tests | <5s each |
| Full suite | <10 minutes |

## Enforcement

### CI Gates
- All PlayMode tests must pass
- No test failures allowed
- Code coverage minimum: 60%
- Test execution time <10 minutes

### Pre-Commit Checks
- Run affected PlayMode tests
- Fast feedback (<2 minutes)

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Test failure | Error | Block merge |
| Test timeout | Error | Block merge |
| Coverage below threshold | Warning | Review required |
| Slow tests | Warning | Optimization required |
