##
## UI Smoke Test Runner - Automated UI navigation testing
## Validates scene transitions and basic UI functionality
##
## Usage: godot --headless --script res://tools/run_ui_smoke.gd
## Output: reports/ui_smoke.json
##

class_name UISmokeRunner
extends SceneTree

const MAX_BATTLE_TICKS: int = 3600  # 1 minute at 60Hz
const TRANSITION_TIMEOUT: float = 5.0  # seconds per transition

var _transition_results: Array[Dictionary] = []
var _current_scene: String = ""
var _test_passed: bool = true
var _start_time: int = 0

# Scene paths
const SCENES: Dictionary = {
    "main_menu": "res://scenes/main_menu.tscn",
    "builder": "res://scenes/build_screen.tscn",
    "campaign": "res://scenes/campaign_screen.tscn",
    "battle": "res://scenes/battle_screen.tscn",
    "results": "res://scenes/results_screen.tscn"
}

# Navigation path: Main → Builder → Campaign → Battle → Results → Campaign
const NAVIGATION_PATH: Array[Dictionary] = [
    {"from": "", "to": "main_menu", "trigger": "load"},
    {"from": "main_menu", "to": "builder", "trigger": "button", "button": "BuilderButton"},
    {"from": "builder", "to": "campaign", "trigger": "button", "button": "CampaignButton"},
    {"from": "campaign", "to": "battle", "trigger": "select_arena", "arena": "roxtan_park"},
    {"from": "battle", "to": "results", "trigger": "battle_end"},
    {"from": "results", "to": "campaign", "trigger": "button", "button": "ContinueButton"}
]

func _initialize() -> void:
    _start_time = Time.get_ticks_msec()
    
    # Create reports directory
    var dir := DirAccess.open("user://")
    if dir:
        dir.make_dir_recursive("reports")
    
    print("=== Ironcore Arena UI Smoke Test ===\n")
    
    # Run navigation tests
    _run_navigation_tests()

func _run_navigation_tests() -> void:
    for transition in NAVIGATION_PATH:
        var result: Dictionary = _attempt_transition(transition)
        _transition_results.append(result)
        
        if not result["success"]:
            _test_passed = false
            print("✗ FAIL: %s → %s: %s" % [result["from"], result["to"], result["error"]])
        else:
            print("✓ PASS: %s → %s (%.2fs)" % [result["from"], result["to"], result["duration"]])
        
        # Small delay between transitions
        await create_timer(0.5).timeout
    
    _generate_report()
    quit(0 if _test_passed else 1)

func _attempt_transition(transition: Dictionary) -> Dictionary:
    var start_time: int = Time.get_ticks_msec()
    var result: Dictionary = {
        "from": transition["from"],
        "to": transition["to"],
        "success": false,
        "error": "",
        "duration": 0.0
    }
    
    match transition["trigger"]:
        "load":
            # Initial load of main menu
            var err := change_scene_to_file(SCENES["main_menu"])
            if err != OK:
                result["error"] = "Failed to load main_menu: error %d" % err
                return result
            
            # Wait for scene to load
            await create_timer(TRANSITION_TIMEOUT).timeout
            
            if not _verify_scene_loaded("main_menu"):
                result["error"] = "Main menu scene not found after load"
                return result
            
        "button":
            var button_name: String = transition["button"]
            if not _click_button(button_name):
                result["error"] = "Button '%s' not found or not clickable" % button_name
                return result
            
            # Wait for scene transition
            await create_timer(TRANSITION_TIMEOUT).timeout
            
            if not _verify_scene_loaded(transition["to"]):
                result["error"] = "Scene '%s' not loaded after clicking %s" % [transition["to"], button_name]
                return result
            
        "select_arena":
            # Select first arena from campaign map
            if not _select_arena(transition["arena"]):
                result["error"] = "Failed to select arena: %s" % transition["arena"]
                return result
            
            await create_timer(TRANSITION_TIMEOUT).timeout
            
            if not _verify_scene_loaded("battle"):
                result["error"] = "Battle scene not loaded after arena selection"
                return result
            
        "battle_end":
            # Wait for battle to complete (shortened)
            if not _wait_for_battle_end():
                result["error"] = "Battle did not end within timeout"
                return result
    
    var duration_ms: int = Time.get_ticks_msec() - start_time
    result["duration"] = duration_ms / 1000.0
    result["success"] = true
    _current_scene = transition["to"]
    
    return result

func _verify_scene_loaded(scene_name: String) -> bool:
    var current := current_scene
    if not current:
        return false
    
    var expected_path: String = SCENES.get(scene_name, "")
    if expected_path.is_empty():
        return false
    
    return current.scene_file_path == expected_path

func _click_button(button_name: String) -> bool:
    var current := current_scene
    if not current:
        return false
    
    var button := current.get_node_or_null(button_name) as Button
    if not button:
        # Try common patterns
        button = current.get_node_or_null("UI/" + button_name) as Button
        if not button:
            button = current.get_node_or_null("MarginContainer/VBoxContainer/" + button_name) as Button
    
    if not button:
        return false
    
    if not button.visible or not button.disabled == false:
        return false
    
    # Emit pressed signal
    button.pressed.emit()
    return true

func _select_arena(arena_id: String) -> bool:
    var current := current_scene
    if not current:
        return false
    
    # Try to find arena button/list
    var arena_list := current.get_node_or_null("ArenaList")
    if not arena_list:
        arena_list = current.get_node_or_null("UI/ArenaList")
    
    if arena_list:
        # Try to find button with arena_id
        for child in arena_list.get_children():
            if child is Button and child.name == arena_id:
                child.pressed.emit()
                return true
    
    # Fallback: look for any button that might start battle
    var start_button := current.get_node_or_null("StartButton")
    if start_button and start_button is Button:
        start_button.pressed.emit()
        return true
    
    return false

func _wait_for_battle_end() -> bool:
    # In headless mode, we need to wait for SimulationManager
    var sim := get_node_or_null("/root/SimulationManager") as SimulationManager
    if not sim:
        return false
    
    # Set short battle timeout
    var original_max: int = sim.MAX_TICKS
    sim.MAX_TICKS = MAX_BATTLE_TICKS
    
    # Wait for battle end or timeout
    var waited: float = 0.0
    while sim.is_running and waited < 10.0:
        await create_timer(0.5).timeout
        waited += 0.5
    
    sim.MAX_TICKS = original_max
    return not sim.is_running

func _generate_report() -> void:
    var total_duration: int = Time.get_ticks_msec() - _start_time
    
    var passed: int = 0
    var failed: int = 0
    for r in _transition_results:
        if r["success"]:
            passed += 1
        else:
            failed += 1
    
    var report: Dictionary = {
        "version": "0.1.0",
        "timestamp": Time.get_datetime_string_from_system(),
        "total_duration_seconds": total_duration / 1000.0,
        "total_transitions": _transition_results.size(),
        "passed": passed,
        "failed": failed,
        "success_rate": float(passed) / float(_transition_results.size()),
        "overall_pass": _test_passed,
        "transitions": _transition_results
    }
    
    var json_string: String = JSON.stringify(report, "  ")
    var file := FileAccess.open("user://reports/ui_smoke.json", FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()
        print("\nReport saved: user://reports/ui_smoke.json")
    else:
        push_error("Failed to write report file")
    
    # Print summary
    print("\n=== UI SMOKE TEST SUMMARY ===")
    print("Transitions: %d passed, %d failed" % [passed, failed])
    print("Success rate: %.1f%%" % (float(passed) / float(_transition_results.size()) * 100))
    print("Total time: %.2fs" % (total_duration / 1000.0))
    print("Overall: %s" % ("PASS ✓" if _test_passed else "FAIL ✗"))
    print("=============================")

# Entry point
func _init():
    create_timer(0.1).timeout.connect(_initialize)
