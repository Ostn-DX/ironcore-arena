---
title: Godot UI Smoke Runner Spec
type: system
layer: execution
status: active
tags:
  - godot
  - ui
  - testing
  - smoke-test
  - automation
  - headless
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Headless_Sim_Runner_Spec]"
used_by:
  - "[Godot_GUT_Test_Framework]]"
  - "[[Godot_CI_Template]"
---

# Godot UI Smoke Runner Spec

The UI Smoke Runner validates critical user interface paths through automated interaction. Unlike the Headless Sim Runner, this requires display capabilities but runs without human intervention to catch UI regressions, navigation failures, and state inconsistencies.

## Purpose

- Verify UI navigation paths work end-to-end
- Catch broken button connections and missing signals
- Validate screen transitions and state persistence
- Detect layout issues and missing textures
- Ensure critical user flows remain functional

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   UI Smoke Runner                        │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Flow Parser  │→ │ Input Inject │→ │ Assert Check │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓                 ↓                 ↓           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ JSON Flows   │  │ Event Sim    │  │ Screenshot   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Command-Line Interface

### Basic Usage
```bash
# Run single UI flow
godot --script src/tests/runners/ui_smoke.gd \
    --flow=res://src/tests/flows/main_menu.json \
    --screenshot-on-failure

# Run full UI test suite
godot --script src/tests/runners/ui_smoke.gd \
    --suite=res://src/tests/suites/ui_regression.json \
    --output=ui_results.json

# Run with display (for debugging)
godot --script src/tests/runners/ui_smoke.gd \
    --flow=res://src/tests/flows/settings.json \
    --visible \
    --delay=0.5
```

### CLI Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `--flow` | Path to flow JSON file | Required (if no suite) |
| `--suite` | Path to suite JSON file | Required (if no flow) |
| `--visible` | Show window during test | false (headless) |
| `--delay` | Seconds between actions | 0.1 |
| `--screenshot-on-failure` | Capture on assert fail | false |
| `--screenshot-on-complete` | Capture on completion | false |
| `--output` | Results JSON path | stdout |
| `--timeout` | Max seconds per flow | 60 |

## Flow Definition Format

### Basic Flow Structure
```json
{
  "name": "main_menu_to_game",
  "description": "Navigate from main menu to active gameplay",
  "starting_scene": "res://src/ui/screens/main_menu.tscn",
  "steps": [
    {
      "action": "wait_for_scene",
      "scene_name": "MainMenu",
      "timeout": 5.0
    },
    {
      "action": "click_button",
      "button_path": "VBoxContainer/StartButton",
      "wait_for_signal": "pressed"
    },
    {
      "action": "wait_for_scene",
      "scene_name": "LevelSelect",
      "timeout": 3.0
    },
    {
      "action": "click_button",
      "button_path": "LevelButtons/Level1"
    },
    {
      "action": "wait_for_scene",
      "scene_name": "Game",
      "timeout": 10.0
    },
    {
      "action": "assert_visible",
      "node_path": "HUD/HealthBar"
    },
    {
      "action": "assert_property",
      "node_path": "Player",
      "property": "health",
      "operator": "gt",
      "value": 0
    }
  ]
}
```

## Available Actions

### Interaction Actions
| Action | Parameters | Description |
|--------|------------|-------------|
| `click_button` | `button_path`, `wait_for_signal` | Click button at path |
| `click_at` | `position` | Click at screen coordinates |
| `input_text` | `field_path`, `text` | Type text into line edit |
| `select_option` | `dropdown_path`, `option_index` | Select dropdown option |
| `toggle_checkbox` | `checkbox_path` | Toggle checkbox state |
| `slider_value` | `slider_path`, `value` | Set slider to value |

### Navigation Actions
| Action | Parameters | Description |
|--------|------------|-------------|
| `wait_for_scene` | `scene_name`, `timeout` | Wait for scene load |
| `wait_for_node` | `node_path`, `timeout` | Wait for node existence |
| `wait_seconds` | `seconds` | Pause execution |
| `go_back` | - | Trigger UI back action |
| `reload_scene` | - | Reload current scene |

### Assertion Actions
| Action | Parameters | Description |
|--------|------------|-------------|
| `assert_visible` | `node_path` | Node is visible |
| `assert_hidden` | `node_path` | Node is hidden |
| `assert_text` | `label_path`, `expected` | Label text matches |
| `assert_property` | `node_path`, `property`, `operator`, `value` | Property comparison |
| `assert_scene_active` | `scene_name` | Scene is current |
| `screenshot` | `filename` | Capture screenshot |

## Runner Implementation

### Core Runner Script
```gdscript
# src/tests/runners/ui_smoke.gd
extends SceneTree

var _config: Dictionary = {}
var _current_flow: Dictionary = {}
var _results: Array[Dictionary] = []
var _screenshot_count: int = 0

func _initialize() -> void:
    _parse_arguments()
    
    if _config.has("suite"):
        _run_suite(_config.suite)
    elif _config.has("flow"):
        _run_flow(_config.flow)
    
    _output_results()
    quit(_get_exit_code())

func _run_suite(suite_path: String) -> void:
    var suite := _load_json(suite_path)
    
    for flow_ref in suite.flows:
        var flow_path := flow_ref as String
        if flow_path.is_relative_path():
            flow_path = suite_path.get_base_dir().path_join(flow_path)
        
        var result := _run_flow(flow_path)
        _results.append(result)

func _run_flow(flow_path: String) -> Dictionary:
    _current_flow = _load_json(flow_path)
    var flow_result := {
        "name": _current_flow.name,
        "passed": true,
        "steps": [],
        "duration_ms": 0
    }
    
    var start_time := Time.get_ticks_msec()
    
    # Load starting scene
    if _current_flow.has("starting_scene"):
        _change_scene(_current_flow.starting_scene)
    
    # Execute steps
    for step in _current_flow.steps:
        var step_result := _execute_step(step)
        flow_result.steps.append(step_result)
        
        if not step_result.passed:
            flow_result.passed = false
            if _config.get("screenshot_on_failure", false):
                _take_screenshot("failure_" + _current_flow.name)
            break
    
    flow_result.duration_ms = Time.get_ticks_msec() - start_time
    
    if _config.get("screenshot_on_complete", false):
        _take_screenshot("complete_" + _current_flow.name)
    
    return flow_result

func _execute_step(step: Dictionary) -> Dictionary:
    var result := {"action": step.action, "passed": false, "message": ""}
    
    match step.action:
        "wait_for_scene":
            result.passed = await _wait_for_scene(step.scene_name, step.get("timeout", 5.0))
        "click_button":
            result.passed = await _click_button(step.button_path, step.get("wait_for_signal", false))
        "input_text":
            result.passed = _input_text(step.field_path, step.text)
        "assert_visible":
            result.passed = _assert_visible(step.node_path)
        "assert_property":
            result.passed = _assert_property(step.node_path, step.property, step.operator, step.value)
        "wait_seconds":
            await get_tree().create_timer(step.seconds).timeout
            result.passed = true
        "screenshot":
            result.passed = _take_screenshot(step.get("filename", "screenshot"))
        _:
            result.message = "Unknown action: " + step.action
    
    return result

func _click_button(path: String, wait_for_signal: bool) -> bool:
    var button := _find_node(path) as Button
    if button == null:
        return false
    
    if wait_for_signal:
        var signal_received := false
        var callable := func(): signal_received = true
        button.pressed.connect(callable, CONNECT_ONE_SHOT)
        button.emit_signal("pressed")
        await get_tree().create_timer(0.5).timeout
        return signal_received
    else:
        button.emit_signal("pressed")
        return true

func _assert_visible(path: String) -> bool:
    var node := _find_node(path)
    if node == null:
        return false
    return node.visible if node.has_method("is_visible") else true

func _assert_property(path: String, property: String, operator: String, value) -> bool:
    var node := _find_node(path)
    if node == null:
        return false
    
    var actual = node.get(property)
    match operator:
        "eq": return actual == value
        "gt": return actual > value
        "gte": return actual >= value
        "lt": return actual < value
        "lte": return actual <= value
        _: return false

func _take_screenshot(filename: String) -> bool:
    var image := get_viewport().get_texture().get_image()
    var path := "builds/test_screenshots/" + filename + "_" + str(_screenshot_count) + ".png"
    _screenshot_count += 1
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return image.save_png(path) == OK

func _find_node(path: String) -> Node:
    return get_root().get_node_or_null(path)

func _change_scene(scene_path: String) -> void:
    var scene := load(scene_path) as PackedScene
    var instance := scene.instantiate()
    get_root().add_child(instance)

func _wait_for_scene(scene_name: String, timeout: float) -> bool:
    var elapsed := 0.0
    while elapsed < timeout:
        var current := get_root().get_child(get_root().get_child_count() - 1)
        if current.name == scene_name:
            return true
        await get_tree().create_timer(0.1).timeout
        elapsed += 0.1
    return false
```

## Test Suite Organization

### Regression Suite Example
```json
{
  "name": "ui_regression",
  "description": "Core UI flows that must not break",
  "flows": [
    "flows/main_menu.json",
    "flows/settings_navigation.json",
    "flows/new_game_flow.json",
    "flows/load_game_flow.json",
    "flows/pause_menu.json",
    "flows/game_over.json"
  ],
  "global_timeout": 300,
  "parallel": false
}
```

## CI Integration

### GitHub Actions (with display)
```yaml
- name: Setup Virtual Display
  run: |
    sudo apt-get install xvfb
    export DISPLAY=:99
    Xvfb :99 -screen 0 1920x1080x24 &

- name: Run UI Smoke Tests
  run: |
    godot --script src/tests/runners/ui_smoke.gd \
      --suite=src/tests/suites/ui_regression.json \
      --output=ui_results.json \
      --screenshot-on-failure
    
    # Upload screenshots on failure
    if [ -d builds/test_screenshots ]; then
      tar -czf ui_screenshots.tar.gz builds/test_screenshots/
    fi
```

## Common UI Test Patterns

### Form Validation Test
```json
{
  "name": "settings_validation",
  "steps": [
    {"action": "click_button", "button_path": "SettingsButton"},
    {"action": "input_text", "field_path": "NameInput", "text": ""},
    {"action": "click_button", "button_path": "SaveButton"},
    {"action": "assert_visible", "node_path": "ErrorLabel"},
    {"action": "assert_text", "label_path": "ErrorLabel", "expected": "Name is required"}
  ]
}
```

### State Persistence Test
```json
{
  "name": "settings_persistence",
  "steps": [
    {"action": "click_button", "button_path": "SettingsButton"},
    {"action": "slider_value", "slider_path": "VolumeSlider", "value": 0.5},
    {"action": "click_button", "button_path": "BackButton"},
    {"action": "click_button", "button_path": "SettingsButton"},
    {"action": "assert_property", "node_path": "VolumeSlider", "property": "value", "operator": "eq", "value": 0.5}
  ]
}
```

## Failure Modes

| Failure | Detection | Resolution |
|---------|-----------|------------|
| Button not found | Null node reference | Check node path in scene |
| Scene timeout | Wait exceeds limit | Check scene loading logic |
| Signal not received | Button press fails | Verify signal connection |
| Property mismatch | Assertion failure | Check property name/type |
| Screenshot black | Rendering issue | Verify display setup in CI |

## See Also

- [[Godot_Headless_Sim_Runner_Spec]] - Simulation testing
- [[Godot_GUT_Test_Framework]] - Unit testing
- [[Godot_CI_Template]] - CI configuration
