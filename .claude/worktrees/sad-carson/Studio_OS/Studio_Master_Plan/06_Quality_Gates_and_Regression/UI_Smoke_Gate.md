---
title: UI Smoke Gate
type: gate
layer: enforcement
status: active
tags:
  - ui
  - smoke-test
  - automation
  - gate
  - playmode
  - critical-path
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Build_Gate]"
used_by:
  - "[Release_Certification_Checklist]]"
  - "[[Regression_Harness_Spec]"
---

# UI Smoke Gate

## Purpose

The UI Smoke Gate validates critical user paths through automated PlayMode tests. It ensures that players can complete essential actions like starting the game, navigating menus, and accessing core features without encountering blocking UI issues.

## Tool/Script

**Primary**: `scripts/gates/ui_smoke_gate.py`
**Test Framework**: Unity Test Framework (PlayMode)
**UI Automation**: `UnityEngine.UI` + custom test helpers
**Alternative**: Appium for platform-specific testing

## Local Run

```bash
# Run all UI smoke tests
python scripts/gates/ui_smoke_gate.py

# Run specific critical path
python scripts/gates/ui_smoke_gate.py --path main_menu_to_gameplay

# Run with screenshot capture
python scripts/gates/ui_smoke_gate.py --screenshots

# Debug mode (visible Unity window)
python scripts/gates/ui_smoke_gate.py --debug

# Via Unity directly
/Unity -runTests -testPlatform PlayMode -testCategory UI_Smoke
```

## CI Run

```yaml
# .github/workflows/ui-smoke-gate.yml
name: UI Smoke Gate
on: [push, pull_request]
jobs:
  ui-smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: UI Smoke Gate
        run: python scripts/gates/ui_smoke_gate.py --screenshots
      - name: Upload Screenshots
        uses: actions/upload-artifact@v3
        with:
          name: ui-screenshots
          path: reports/ui/screenshots/
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| Critical Path Success | 100% | All critical paths complete |
| UI Element Detection | 100% | Required elements found |
| Screen Transition Time | < 3s | Time between screen changes |
| No Exceptions | 0 | Unhandled UI exceptions |
| Screenshot Match | > 95% | Visual regression threshold |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| Critical Path Fail | >= 1 | HARD FAIL - blocking issue |
| Missing UI Element | >= 1 | HARD FAIL - UI broken |
| Transition Timeout | >= 1 | SOFT FAIL - performance issue |
| UI Exception | >= 1 | SOFT FAIL - error handling |
| Visual Regression | > 10% | SOFT FAIL - intentional change? |

## Critical Paths

| Path | Description | Max Duration | Priority |
|------|-------------|--------------|----------|
| Launch to Main Menu | Game boots, shows menu | 10s | P0 |
| Start New Game | New game flow completes | 30s | P0 |
| Load Save Game | Save loads successfully | 15s | P0 |
| Settings Navigation | All settings accessible | 20s | P1 |
| Quit Game | Clean exit | 5s | P0 |
| In-Game Menu | Pause/resume works | 10s | P0 |
| Tutorial Flow | Tutorial completes | 60s | P1 |

## UI Test Pattern

```csharp
// Assets/Tests/PlayMode/UI/CriticalPathTests.cs
[TestFixture]
public class CriticalPathTests
{
    [UnityTest]
    [Category("UI_Smoke")]
    [Timeout(30000)]
    public IEnumerator Launch_To_MainMenu_Completes()
    {
        // Arrange
        var sceneLoader = new SceneTestHelper();
        
        // Act
        yield return sceneLoader.LoadSceneAsync("Boot");
        yield return WaitForScene("MainMenu", timeout: 10f);
        
        // Assert
        var mainMenu = GameObject.Find("MainMenuCanvas");
        Assert.IsNotNull(mainMenu, "Main menu should be visible");
        
        var startButton = mainMenu.GetComponentInChildren<Button>(b => b.name == "StartButton");
        Assert.IsNotNull(startButton, "Start button should exist");
        Assert.IsTrue(startButton.interactable, "Start button should be interactable");
    }
    
    [UnityTest]
    [Category("UI_Smoke")]
    [Timeout(60000)]
    public IEnumerator Start_New_Game_Completes()
    {
        yield return NavigateToMainMenu();
        
        // Click Start
        yield return ClickButton("StartButton");
        yield return WaitForScene("Game", timeout: 30f);
        
        // Verify game started
        var gameManager = GameObject.FindObjectOfType<GameManager>();
        Assert.IsNotNull(gameManager, "Game manager should exist");
        Assert.IsTrue(gameManager.IsRunning, "Game should be running");
    }
}
```

## Failure Modes

### UI Element Not Found

**Symptoms**: Test fails to find expected UI element
**Root Causes**:
- Element renamed or removed
- Scene not loaded correctly
- Element disabled or hidden
- Timing issue (element not yet created)

### Screen Transition Timeout

**Symptoms**: Screen takes too long to change
**Root Causes**:
- Loading performance regression
- Async operation not completing
- Scene load blocking

### Visual Regression

**Symptoms**: Screenshot differs from baseline
**Root Causes**:
- Intentional UI changes
- Rendering differences
- Resolution/platform variations

## Remediation Steps

### Fix Missing UI Element

1. Check test log for element name
2. Open scene in Unity Editor
3. Verify element exists with correct name
4. Check if element is active/enabled
5. Update test if element was intentionally changed
6. Re-run UI smoke gate

### Fix Transition Timeout

1. Identify slow transition from logs
2. Profile scene loading: `scripts/tools/profile_scene_load.py`
3. Optimize loading operations
4. Consider increasing timeout if change is acceptable
5. Re-run gate

### Update Visual Baseline

```bash
# If UI change is intentional, update baselines
python scripts/gates/ui_smoke_gate.py --update-baselines

# Review changes before committing
git diff reports/ui/baselines/
```

## UI Test Helpers

```csharp
// Assets/Tests/TestUtils/UITestHelpers.cs
public static class UITestHelpers
{
    public static IEnumerator ClickButton(string buttonName)
    {
        var button = GameObject.Find(buttonName)?.GetComponent<Button>();
        Assert.IsNotNull(button, $"Button '{buttonName}' not found");
        button.onClick.Invoke();
        yield return null;
    }
    
    public static IEnumerator WaitForScene(string sceneName, float timeout)
    {
        var timer = 0f;
        while (SceneManager.GetActiveScene().name != sceneName && timer < timeout)
        {
            timer += Time.deltaTime;
            yield return null;
        }
        Assert.AreEqual(sceneName, SceneManager.GetActiveScene().name);
    }
    
    public static IEnumerator WaitForElement(string elementName, float timeout)
    {
        var timer = 0f;
        GameObject element = null;
        while (element == null && timer < timeout)
        {
            element = GameObject.Find(elementName);
            timer += Time.deltaTime;
            yield return null;
        }
        Assert.IsNotNull(element, $"Element '{elementName}' not found within {timeout}s");
    }
}
```

## Screenshot Comparison

```python
# scripts/tools/compare_screenshots.py
def compare_screenshots(baseline: Path, current: Path) -> float:
    """Compare screenshots and return similarity percentage."""
    baseline_img = Image.open(baseline)
    current_img = Image.open(current)
    
    diff = ImageChops.difference(baseline_img, current_img)
    diff_pixels = sum(1 for p in diff.getdata() if p != (0, 0, 0, 0))
    total_pixels = baseline_img.size[0] * baseline_img.size[1]
    
    similarity = (1 - diff_pixels / total_pixels) * 100
    return similarity
```

## Integration with Other Gates

- **Requires**: [[Build_Gate]] must pass
- **Runs after**: [[Unit_Tests_Gate]]
- **Required by**: [[Release_Certification_Checklist]]
- **Screenshot artifacts**: Attached to CI runs

## Platform-Specific Testing

| Platform | Test Approach | Notes |
|----------|---------------|-------|
| PC | PlayMode tests | Primary platform |
| Mobile | Device farm or emulator | Touch input simulation |
| Console | Hardware-in-loop | Requires dev kit |
| WebGL | Browser automation | Selenium/Playwright |

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| PlayMode tests flaky in CI | Add retry logic (max 3) | UI-123 |
| Screenshots differ by GPU | Use software renderer in CI | UI-456 |
| Timing issues on slow CI | Increase timeouts | UI-789 |
