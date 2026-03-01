extends Node
## DebugManager - In-game debugging tools
## Add a Debug button for instant state reproduction

signal debug_command_executed(command: String)

var _debug_buttons: Dictionary = {}
var _is_debug_mode: bool = false

func _ready() -> void:
	## Only enable in debug builds
	_is_debug_mode = OS.is_debug_build()
	if not _is_debug_mode:
		return
	
	print("[DebugManager] Debug mode enabled")
	_setup_debug_shortcuts()

func _setup_debug_shortcuts() -> void:
	## F1-F12 for quick debug commands
	var shortcuts: Dictionary = {
		KEY_F1: "give_max_credits",
		KEY_F2: "unlock_all_parts", 
		KEY_F3: "complete_all_arenas",
		KEY_F4: "reset_save",
		KEY_F5: "quick_save",
		KEY_F6: "quick_load",
		KEY_F7: "spawn_test_battle",
		KEY_F8: "show_debug_overlay",
	}
	
	for key in shortcuts:
		var action_name: String = "debug_" + shortcuts[key]
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var event := InputEventKey.new()
			event.keycode = key
			InputMap.action_add_event(action_name, event)

func _input(event: InputEvent) -> void:
	if not _is_debug_mode:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				_debug_give_max_credits()
			KEY_F2:
				_debug_unlock_all_parts()
			KEY_F3:
				_debug_complete_all_arenas()
			KEY_F4:
				_debug_reset_save()
			KEY_F5:
				_debug_quick_save()
			KEY_F6:
				_debug_quick_load()
			KEY_F7:
				_debug_spawn_test_battle()
			KEY_F8:
				_debug_show_overlay()
			KEY_F12:
				_debug_dump_state()

func _debug_give_max_credits() -> void:
	if GameState and is_instance_valid(GameState):
		GameState.credits = 999999
		print("[Debug] Max credits given")
		debug_command_executed.emit("give_max_credits")

func _debug_unlock_all_parts() -> void:
	if GameState and is_instance_valid(GameState):
		GameState._give_all_parts()
		print("[Debug] All parts unlocked")
		debug_command_executed.emit("unlock_all_parts")

func _debug_complete_all_arenas() -> void:
	if GameState and is_instance_valid(GameState):
		for arena in GameState.unlocked_arenas:
			GameState.complete_arena(arena)
		print("[Debug] All arenas completed")
		debug_command_executed.emit("complete_all_arenas")

func _debug_reset_save() -> void:
	if SaveManager and is_instance_valid(SaveManager):
		SaveManager.delete_save()
		print("[Debug] Save deleted - restart to see effect")
		debug_command_executed.emit("reset_save")

func _debug_quick_save() -> void:
	if GameState and is_instance_valid(GameState):
		GameState.save_game()
		print("[Debug] Quick save complete")
		debug_command_executed.emit("quick_save")

func _debug_quick_load() -> void:
	if GameState and is_instance_valid(GameState):
		GameState.load_game()
		print("[Debug] Quick load complete")
		debug_command_executed.emit("quick_load")

func _debug_spawn_test_battle() -> void:
	## Instantly start a test battle
	var scene_flow = get_node_or_null("/root/Main/SceneFlowManager")
	if scene_flow and is_instance_valid(scene_flow):
		scene_flow.start_battle("arena_training")
		print("[Debug] Test battle started")
		debug_command_executed.emit("spawn_test_battle")
	else:
		push_warning("[Debug] SceneFlowManager not found")

func _debug_show_overlay() -> void:
	## Toggle debug overlay with stats
	_toggle_debug_overlay()
	debug_command_executed.emit("show_debug_overlay")

func _toggle_debug_overlay() -> void:
	var existing := get_node_or_null("DebugOverlay")
	if existing:
		existing.queue_free()
		return
	
	var overlay := CanvasLayer.new()
	overlay.name = "DebugOverlay"
	
	var panel := Panel.new()
	panel.anchor_left = 0.7
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.4
	
	var vbox := VBoxContainer.new()
	vbox.offset_left = 10
	vbox.offset_top = 10
	
	var title := Label.new()
	title.text = "Debug Overlay (F8 to hide)"
	title.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(title)
	
	var fps_label := Label.new()
	fps_label.name = "FPSLabel"
	vbox.add_child(fps_label)
	
	var state_label := Label.new()
	state_label.name = "StateLabel"
	vbox.add_child(state_label)
	
	panel.add_child(vbox)
	overlay.add_child(panel)
	add_child(overlay)
	
	## Update loop
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(func():
		if fps_label and is_instance_valid(fps_label):
			fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
		if state_label and is_instance_valid(state_label) and GameState:
			state_label.text = "Credits: %d | Tier: %d" % [GameState.credits, GameState.current_tier]
	)
	overlay.add_child(timer)
	timer.start()

func _debug_dump_state() -> void:
	## Dump full game state to console
	print("\n========== DEBUG STATE DUMP ==========")
	if GameState and is_instance_valid(GameState):
		print("Credits: ", GameState.credits)
		print("Tier: ", GameState.current_tier)
		print("Owned Parts: ", GameState.owned_parts.size())
		print("Loadouts: ", GameState.loadouts.size())
		print("Completed Arenas: ", GameState.completed_arenas)
		print("Unlocked Arenas: ", GameState.unlocked_arenas)
	print("=====================================\n")
	debug_command_executed.emit("dump_state")

## Public API for scripts to add custom debug buttons
func add_debug_button(label: String, callback: Callable) -> void:
	if not _is_debug_mode:
		return
	_debug_buttons[label] = callback

func trigger_debug_command(command: String) -> void:
	match command:
		"give_max_credits":
			_debug_give_max_credits()
		"unlock_all_parts":
			_debug_unlock_all_parts()
		"complete_all_arenas":
			_debug_complete_all_arenas()
		"reset_save":
			_debug_reset_save()
		"quick_save":
			_debug_quick_save()
		"quick_load":
			_debug_quick_load()
		"spawn_test_battle":
			_debug_spawn_test_battle()
		"dump_state":
			_debug_dump_state()
		_:
			push_warning("[DebugManager] Unknown debug command: %s" % command)
