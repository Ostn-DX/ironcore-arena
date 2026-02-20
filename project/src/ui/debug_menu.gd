extends Control
class_name DebugMenu
## Debug menu for testing - accessible from main menu or via keybind
## Features: Arena select, infinite money, instant win, etc.

signal arena_selected(arena_id: String)
signal toggle_infinite_money(enabled: bool)
signal instant_win
signal reset_save

var _infinite_money: bool = false

func _ready() -> void:
	_setup_ui()
	visible = false  ; Hidden by default

func _setup_ui() -> void:
	; Semi-transparent background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.9)
	add_child(bg)
	
	; Title
	var title: Label = Label.new()
	title.text = "DEBUG MENU"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(540, 30)
	title.size = Vector2(200, 40)
	title.modulate = Color(1, 0.5, 0)  ; Orange for debug
	add_child(title)
	
	; Container for buttons
	var container: VBoxContainer = VBoxContainer.new()
	container.position = Vector2(440, 100)
	container.size = Vector2(400, 500)
	container.theme_override_constants/separation = 10
	add_child(container)
	
	; Section: Arena Select
	_add_section_header(container, "ARENA SELECT")
	_add_arena_button(container, "Boot Camp (1v1)", "arena_boot_camp")
	_add_arena_button(container, "Iron Graveyard (1v2)", "arena_iron_graveyard")
	_add_arena_button(container, "Kill Grid (1v3)", "arena_kill_grid")
	
	; Section: Cheats
	_add_section_header(container, "CHEATS")
	_add_toggle_button(container, "Infinite Money", _toggle_infinite_money)
	_add_action_button(container, "+1000 Credits", _add_credits)
	_add_action_button(container, "Unlock All Arenas", _unlock_all)
	_add_action_button(container, "Reset Save (New Game)", _reset_save)
	
	; Section: Battle
	_add_section_header(container, "BATTLE")
	_add_action_button(container, "Instant Win", _instant_win)
	_add_action_button(container, "Instant Loss", _instant_loss)
	_add_action_button(container, "Kill All Enemies", _kill_enemies)
	
	; Close button
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	container.add_child(spacer)
	
	var close_btn: Button = Button.new()
	close_btn.text = "CLOSE (ESC)"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.pressed.connect(hide_menu)
	container.add_child(close_btn)
	
	; Instructions
	var instructions: Label = Label.new()
	instructions.text = "F1: Toggle Debug Menu | F2: Quick Win | F3: +1000 CR"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.position = Vector2(340, 680)
	instructions.size = Vector2(600, 20)
	instructions.modulate = Color(0.7, 0.7, 0.7)
	add_child(instructions)

func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var header: Label = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 18)
	header.modulate = Color(0.5, 0.8, 1)
	parent.add_child(header)
	
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	parent.add_child(spacer)

func _add_arena_button(parent: VBoxContainer, label: String, arena_id: String) -> void:
	var btn: Button = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(300, 35)
	btn.pressed.connect(_on_arena_selected.bind(arena_id))
	parent.add_child(btn)

func _add_action_button(parent: VBoxContainer, label: String, callback: Callable) -> void:
	var btn: Button = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(300, 30)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _add_toggle_button(parent: VBoxContainer, label: String, callback: Callable) -> void:
	var btn: Button = Button.new()
	btn.text = label + ": OFF"
	btn.custom_minimum_size = Vector2(300, 30)
	btn.toggle_mode = true
	btn.toggled.connect(callback.bind(btn))
	parent.add_child(btn)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				toggle_visibility()
			KEY_F2:
				_instant_win()
			KEY_F3:
				_add_credits()
			KEY_ESCAPE:
				if visible:
					hide_menu()

func toggle_visibility() -> void:
	visible = !visible
	if visible:
		; Pause game when debug menu open
		get_tree().paused = true
		print("DebugMenu: Opened")
	else:
		get_tree().paused = false
		print("DebugMenu: Closed")

func show_menu() -> void:
	visible = true
	get_tree().paused = true

func hide_menu() -> void:
	visible = false
	get_tree().paused = false

; ============================================================================
; HANDLERS
; ============================================================================

func _on_arena_selected(arena_id: String) -> void:
	print("DebugMenu: Selected arena: ", arena_id)
	arena_selected.emit(arena_id)
	hide_menu()
	
	; Start battle in selected arena
	if SceneFlowManager:
		SceneFlowManager.start_battle(arena_id)

func _toggle_infinite_money(enabled: bool, btn: Button) -> void:
	_infinite_money = enabled
	btn.text = "Infinite Money: " + ("ON" if enabled else "OFF")
	toggle_infinite_money.emit(enabled)
	print("DebugMenu: Infinite money ", "enabled" if enabled else "disabled")

func _add_credits() -> void:
	if GameState:
		GameState.add_credits(1000)
		print("DebugMenu: Added 1000 credits")

func _unlock_all() -> void:
	if GameState:
		GameState.unlocked_arenas = ["arena_boot_camp", "arena_iron_graveyard", "arena_kill_grid"]
		print("DebugMenu: All arenas unlocked")

func _reset_save() -> void:
	if SaveManager:
		SaveManager.delete_save()
		GameState._give_starter_kit()
		print("DebugMenu: Save reset, new game started")

func _instant_win() -> void:
	print("DebugMenu: Instant win triggered")
	instant_win.emit()
	; Force battle end with victory
	if BattleManager and BattleManager.is_battle_active():
		BattleManager._end_battle(BattleManager.BattleResult.ResultType.VICTORY)

func _instant_loss() -> void:
	print("DebugMenu: Instant loss triggered")
	if BattleManager and BattleManager.is_battle_active():
		BattleManager._end_battle(BattleManager.BattleResult.ResultType.DEFEAT)

func _kill_enemies() -> void:
	print("DebugMenu: Killing all enemies")
	if SimulationManager:
		for bot_id in SimulationManager.bots:
			var bot = SimulationManager.bots[bot_id]
			if bot.team == 1:  ; Enemy team
				bot.take_damage(9999)

func is_visible() -> bool:
	return visible
