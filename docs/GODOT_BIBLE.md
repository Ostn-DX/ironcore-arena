# Godot Bible - Ironcore Arena Edition
## Reusable Patterns for Godot 4.x Game Development

This document captures the architectural patterns, coding standards, and best practices established during Ironcore Arena development. Use this as a foundation for future projects.

---

## 1. PROJECT STRUCTURE

### Folder Organization
```
project/
├── autoload/              # Singletons (GameState, DataLoader, etc.)
├── src/
│   ├── managers/          # Game logic managers
│   ├── entities/          # Game objects (Bot, Arena, etc.)
│   ├── components/        # Reusable components (Health, StateMachine)
│   ├── ui/               # UI screens and components
│   └── tools/            # Editor tools
├── scenes/               # .tscn files
├── assets/               # Graphics, audio, fonts
│   ├── sprites/          # Game sprites
│   ├── audio/            # SFX and music
│   └── ui/               # UI-specific assets
├── data/                 # JSON data files (components, levels)
└── docs/                 # Documentation
```

### Naming Conventions
- **Files:** `snake_case.gd` for scripts, `snake_case.tscn` for scenes
- **Classes:** `PascalCase` with explicit `class_name`
- **Variables:** `snake_case` with type hints
- **Signals:** `snake_case` with descriptive names
- **Constants:** `UPPER_SNAKE_CASE`

---

## 2. SINGLETON PATTERN (Autoloads)

### Implementation
```gdscript
## autoload/game_state.gd
extends Node
class_name GameState

## Use explicit class_name for type safety
## Bible 4.1: Always typed

signal credits_changed(new_amount: int)
signal parts_changed()

## Bible 4.1: Static typing on all variables
var credits: int = 500:
    set(value):
        credits = maxi(0, value)
        credits_changed.emit(credits)

var owned_parts: Dictionary[String, int] = {}

func _ready() -> void:
    ## Initialization with fallback
    if not DataLoader or not is_instance_valid(DataLoader):
        push_error("GameState: DataLoader not available!")
        return
    load_game()
```

### Key Principles
1. **Always check validity:** Before accessing other autoloads, verify with `is_instance_valid()`
2. **Emit signals on change:** Notify UI and other systems of state changes
3. **Type all exports:** Use typed dictionaries and arrays
4. **Fail gracefully:** Log errors but don't crash on missing dependencies

---

## 3. SIGNAL PATTERN (Bible B1.3)

### Safe Connection
```gdscript
## Always check before connecting
if button and is_instance_valid(button):
    if not button.pressed.is_connected(_on_pressed):
        button.pressed.connect(_on_pressed)
```

### Safe Disconnection (Cleanup)
```gdscript
func _exit_tree() -> void:
    ## Bible B1.3: Disconnect all signals
    if button and is_instance_valid(button):
        if button.pressed.is_connected(_on_pressed):
            button.pressed.disconnect(_on_pressed)
```

### Signal Declaration
```gdscript
## Use typed signals with descriptive names
signal health_changed(current: float, maximum: float)
signal bot_destroyed(bot_id: String, position: Vector2)
signal item_purchased(item_id: String, cost: int, quantity: int)
```

---

## 4. COMPONENT PATTERN

### Reusable Component Example
```gdscript
## src/components/health_component.gd
class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal damage_taken(amount: float, source: Node)
signal died()

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
    current_health = max_health

func take_damage(amount: float, source: Node = null) -> void:
    if amount <= 0:
        return
    
    current_health = maxf(0.0, current_health - amount)
    health_changed.emit(current_health, max_health)
    damage_taken.emit(amount, source)
    
    if current_health <= 0:
        died.emit()

func heal(amount: float) -> void:
    current_health = minf(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)
```

### Usage
```gdscript
## Add to entity
var health := HealthComponent.new()
health.max_health = 150.0
add_child(health)

## Connect to signals
health.died.connect(_on_death)
```

---

## 5. DATA-DRIVEN DESIGN

### JSON Data Structure
```json
{
  "chassis": [
    {
      "id": "akaumin_dl2_100",
      "name": "AKAUMIN DL2-100",
      "tier": 0,
      "hp_base": 80,
      "cost": 300
    }
  ]
}
```

### DataLoader Pattern
```gdscript
## autoload/data_loader.gd
extends Node

var _data: Dictionary = {}

func _ready() -> void:
    _load_data()

func _load_data() -> void:
    var file := FileAccess.open("res://data/components.json", FileAccess.READ)
    if not file:
        push_error("Failed to load components.json")
        return
    
    var json := JSON.new()
    var error := json.parse(file.get_as_text())
    if error != OK:
        push_error("JSON parse error: %s" % json.get_error_message())
        return
    
    _data = json.data

func get_chassis(id: String) -> Dictionary:
    for chassis in _data.get("chassis", []):
        if chassis.get("id") == id:
            return chassis
    return {}
```

---

## 6. SCENE FLOW MANAGEMENT

### SceneFlowManager Pattern
```gdscript
## src/managers/scene_flow_manager.gd
extends Node
class_name SceneFlowManager

## Preload all screen scenes
var main_menu_scene: PackedScene = preload("res://scenes/ui/main_menu.tscn")
var builder_scene: PackedScene = preload("res://scenes/ui/builder.tscn")

var current_screen: Control = null
var screen_stack: Array[Control] = []

func show_screen(screen_scene: PackedScene, add_to_stack: bool = true) -> void:
    ## Hide current
    if current_screen:
        if add_to_stack:
            screen_stack.append(current_screen)
        current_screen.visible = false
    
    ## Create new
    var new_screen: Control = screen_scene.instantiate()
    add_child(new_screen)
    current_screen = new_screen
    
    ## Connect back button if exists
    if new_screen.has_signal("back_pressed"):
        new_screen.back_pressed.connect(_go_back)

func _go_back() -> void:
    if screen_stack.is_empty():
        return
    
    if current_screen:
        current_screen.queue_free()
    
    current_screen = screen_stack.pop_back()
    current_screen.visible = true
```

---

## 7. ERROR HANDLING PATTERN

### Defensive Programming
```gdscript
func process_item(item: Dictionary) -> void:
    ## Bible: Validate inputs
    if item.is_empty():
        push_warning("process_item called with empty dictionary")
        return
    
    if not item.has("id"):
        push_error("Item missing required 'id' field")
        return
    
    ## Process safely
    var id: String = item.get("id", "unknown")
    var quantity: int = item.get("quantity", 0)
    
    if quantity < 0:
        push_warning("Negative quantity for item %s, clamping to 0" % id)
        quantity = 0
    
    ## Actual processing...
```

### Resource Loading Safety
```gdscript
func load_texture(path: String) -> Texture2D:
    if not ResourceLoader.exists(path):
        push_warning("Texture not found: %s" % path)
        return preload("res://assets/sprites/default.png")
    
    var texture: Texture2D = load(path)
    if not texture:
        push_error("Failed to load texture: %s" % path)
        return preload("res://assets/sprites/default.png")
    
    return texture
```

---

## 8. KEYBOARD NAVIGATION PATTERN

### UI Screen Setup
```gdscript
extends Control
class_name MyScreen

var _focusable_buttons: Array[Button] = []
var _focused_index: int = 0

func _ready() -> void:
    _setup_keyboard_navigation()

func _setup_keyboard_navigation() -> void:
    _focusable_buttons.clear()
    
    ## Add buttons in navigation order
    if button_a:
        _focusable_buttons.append(button_a)
    if button_b:
        _focusable_buttons.append(button_b)
    
    ## Set initial focus
    if not _focusable_buttons.is_empty():
        _focusable_buttons[0].grab_focus()

func _input(event: InputEvent) -> void:
    if not visible:
        return
    
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_UP:
                _navigate_focus(-1)
                get_viewport().set_input_as_handled()
            KEY_DOWN:
                _navigate_focus(1)
                get_viewport().set_input_as_handled()
            KEY_ENTER, KEY_SPACE:
                _activate_focused()
                get_viewport().set_input_as_handled()
            KEY_ESCAPE:
                _on_back_pressed()
                get_viewport().set_input_as_handled()

func _navigate_focus(direction: int) -> void:
    if _focusable_buttons.is_empty():
        return
    
    _focused_index += direction
    _focused_index = clampi(_focused_index, 0, _focusable_buttons.size() - 1)
    _focusable_buttons[_focused_index].grab_focus()
```

---

## 9. TESTING PATTERN

### Automated Test Runner
```gdscript
## autoload/automated_test_runner.gd
extends Node

signal test_completed(test_name: String, passed: bool)
signal all_tests_completed(results: Dictionary)

func run_all_tests() -> void:
    await _test_data_loader()
    await _test_game_state()
    await _test_economy()
    _report_results()

func _test_economy() -> void:
    _start_test("Economy")
    
    ## Test credit operations
    var initial: int = GameState.credits
    GameState.add_credits(100)
    
    if GameState.credits != initial + 100:
        _fail_test("add_credits failed")
        return
    
    _pass_test("Economy tests passed")

func _start_test(name: String) -> void:
    print("[Test] Starting: %s" % name)

func _pass_test(message: String) -> void:
    print("[Test] ✓ PASSED: %s" % message)
    test_completed.emit(_current_test, true)

func _fail_test(message: String) -> void:
    print("[Test] ✗ FAILED: %s" % message)
    test_completed.emit(_current_test, false)
```

---

## 10. QUICK REFERENCE

### Bible Checklist for New Files
- [ ] `class_name` declared at top
- [ ] `extends` specified explicitly
- [ ] All variables typed (`: Type`)
- [ ] Signals use type hints (`signal name(param: Type)`)
- [ ] `@onready` used for node references
- [ ] `is_instance_valid()` checks before node access
- [ ] `is_connected()` checks before signal operations
- [ ] `_exit_tree()` cleans up signals
- [ ] Input handled in `_input()` or `_unhandled_input()`
- [ ] Errors use `push_error()`, warnings use `push_warning()`

### Common Snippets

**Safe Node Access:**
```gdscript
if node and is_instance_valid(node):
    node.do_something()
```

**Safe Signal Connection:**
```gdscript
if not signal.is_connected(callback):
    signal.connect(callback)
```

**Safe Resource Load:**
```gdscript
if ResourceLoader.exists(path):
    var res: Resource = load(path)
```

**Safe Dictionary Access:**
```gdscript
var value: int = dict.get("key", 0)  ## Default fallback
```

---

## 11. PROJECT TEMPLATE

Use this as a starting point for new projects:

```gdscript
## File: src/template.gd
class_name MyClass
extends Node

## Signals
signal my_signal(data: Dictionary)

## Exports
@export var my_export: int = 10

## Variables
var _private_var: String = ""
var _node_reference: Button

## Onready
@onready var _button: Button = %Button

func _ready() -> void:
    _setup_signals()
    _initialize()

func _setup_signals() -> void:
    if _button and is_instance_valid(_button):
        if not _button.pressed.is_connected(_on_pressed):
            _button.pressed.connect(_on_pressed)

func _initialize() -> void:
    ## Bible: Check dependencies
    if not GameState or not is_instance_valid(GameState):
        push_error("MyClass: GameState not available")
        return

func _on_pressed() -> void:
    if is_instance_valid(self):
        my_signal.emit({"key": "value"})

func _exit_tree() -> void:
    ## Bible: Cleanup
    if _button and is_instance_valid(_button):
        if _button.pressed.is_connected(_on_pressed):
            _button.pressed.disconnect(_on_pressed)
```

---

*Document Version: 1.0*
*Based on Ironcore Arena development patterns*
*Compatible with Godot 4.2+*
