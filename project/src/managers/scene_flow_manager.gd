extends Node
class_name SceneFlowManager
## SceneFlowManager - handles navigation between game screens.
## UPDATED: Integrated new Bible-compliant UI screens

# Screen references (old menu for compatibility)
@onready var main_menu: Control = $ScreenManager/MainMenu

# NEW: Bible-compliant screen scenes
var main_menu_screen_scene: PackedScene = preload("res://scenes/ui/screens/main_menu_screen.tscn")
var career_submenu_scene: PackedScene = preload("res://scenes/ui/screens/career_submenu_screen.tscn")
var career_hub_scene: PackedScene = preload("res://scenes/ui/screens/career_hub_screen.tscn")
var builder_screen_scene: PackedScene = preload("res://scenes/ui/screens/builder_screen.tscn")

# Legacy scenes (for compatibility)
var battle_screen_scene: PackedScene = preload("res://scenes/battle_screen.tscn")
var old_build_screen_scene: PackedScene = preload("res://scenes/build_screen.tscn")
var shop_screen_scene: PackedScene = preload("res://scenes/shop_screen.tscn")
var campaign_screen_scene: PackedScene = preload("res://scenes/campaign_screen.tscn")
var results_screen_scene: PackedScene = preload("res://scenes/results_screen.tscn")

# Active screens
var current_screen: Control = null
var screen_stack: Array[Control] = []

# Screen container
@onready var screen_manager: CanvasLayer = $ScreenManager

# Current arena for battles
var _next_arena_id: String = "arena_boot_camp"

# Bible B1.3: Track signal connections for cleanup
var _connected_signals: Array[Dictionary] = []

func _ready() -> void:
	_setup_signals()
	
	## NEW: Show Bible-compliant menu instead of old menu
	## Hide old menu completely
	if main_menu:
		main_menu.visible = false
		main_menu.process_mode = Node.PROCESS_MODE_DISABLED
	
	## Show new menu after brief delay to ensure everything loaded
	call_deferred("_show_new_menu_deferred")
	
	# Auto-save on exit
	get_tree().set_auto_accept_quit(false)

func _show_new_menu_deferred() -> void:
	## Use new Bible-compliant menu
	show_new_main_menu()

func _setup_signals() -> void:
	# Connect old main menu signals for compatibility
	if main_menu:
		if main_menu.has_signal("start_campaign_pressed"):
			_safe_connect(main_menu, "start_campaign_pressed", _on_start_campaign)
			_safe_connect(main_menu, "start_arcade_pressed", _on_start_arcade)
			_safe_connect(main_menu, "continue_pressed", _on_continue_campaign)
			_safe_connect(main_menu, "shop_pressed", _on_open_shop)
			_safe_connect(main_menu, "builder_pressed", _on_open_builder)
			_safe_connect(main_menu, "settings_pressed", _on_open_settings)
			_safe_connect(main_menu, "quit_pressed", _on_quit)

func _safe_connect(obj: Object, signal_name: String, callable: Callable) -> void:
	## Bible B1.3: Safe signal connection pattern
	if obj and is_instance_valid(obj):
		if obj.has_signal(signal_name):
			var sig = obj.get(signal_name)
			if sig and not sig.is_connected(callable):
				sig.connect(callable)
				_connected_signals.append({"object": obj, "signal": signal_name, "callable": callable})

func _notification(what: int) -> void:
	# Auto-save when quitting
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("SceneFlow: Auto-saving before exit...")
		if SaveManager and is_instance_valid(SaveManager):
			SaveManager.save()
		get_tree().quit()

func _exit_tree() -> void:
	## Bible B1.3: Cleanup all signal connections
	for conn in _connected_signals:
		var obj = conn.get("object")
		var sig_name = conn.get("signal")
		var callable = conn.get("callable")
		
		if obj and is_instance_valid(obj) and obj.has_signal(sig_name):
			var sig = obj.get(sig_name)
			if sig and sig.is_connected(callable):
				sig.disconnect(callable)
	_connected_signals.clear()

# ============================================================================
# NEW BIBLE-COMPLIANT SCREEN NAVIGATION
# ============================================================================

func show_new_main_menu() -> void:
	## Show the new Bible-compliant main menu
	print("SceneFlow: Showing NEW main menu")
	_hide_main_menu()
	
	## Ensure screen_manager is valid
	if not screen_manager or not is_instance_valid(screen_manager):
		push_error("SceneFlow: screen_manager is null!")
		return
	
	var menu: Control = main_menu_screen_scene.instantiate()
	if not menu:
		push_error("SceneFlow: Failed to instantiate main menu!")
		return
		
	menu.name = "MainMenuScreen"
	
	## Ensure menu fills screen and processes input
	menu.anchor_right = 1.0
	menu.anchor_bottom = 1.0
	menu.offset_right = 0
	menu.offset_bottom = 0
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect signals with Bible B1.3 pattern
	if menu.has_signal("career_pressed"):
		_safe_connect(menu, "career_pressed", _on_new_career_pressed)
	if menu.has_signal("arcade_pressed"):
		_safe_connect(menu, "arcade_pressed", _on_new_arcade_pressed)
	if menu.has_signal("settings_pressed"):
		_safe_connect(menu, "settings_pressed", _on_open_settings)
	if menu.has_signal("exit_pressed"):
		_safe_connect(menu, "exit_pressed", _on_quit)
	
	screen_manager.add_child(menu)
	print("SceneFlow: New menu added to screen_manager")
	
	_switch_to_screen(menu, false)
	print("SceneFlow: New menu is now current_screen")

func _on_new_career_pressed() -> void:
	## Navigate to career submenu
	if current_screen and current_screen != main_menu:
		current_screen.queue_free()
	
	var submenu: Control = career_submenu_scene.instantiate()
	submenu.name = "CareerSubmenuScreen"
	
	if submenu.has_signal("continue_pressed"):
		_safe_connect(submenu, "continue_pressed", _on_career_continue)
	if submenu.has_signal("new_career_pressed"):
		_safe_connect(submenu, "new_career_pressed", _on_career_new)
	if submenu.has_signal("load_career_pressed"):
		_safe_connect(submenu, "load_career_pressed", _on_career_load)
	if submenu.has_signal("back_pressed"):
		_safe_connect(submenu, "back_pressed", show_new_main_menu)
	
	screen_manager.add_child(submenu)
	_switch_to_screen(submenu, false)

func _on_new_arcade_pressed() -> void:
	## Start arcade mode (all items unlocked)
	print("SceneFlow: Starting arcade mode")
	
	if GameState and is_instance_valid(GameState):
		GameState.set_game_mode("arcade")
		GameState._give_all_parts()  # Unlock everything
	
	# Go straight to builder
	show_new_builder()

func _on_career_continue() -> void:
	## Continue existing career
	print("SceneFlow: Continuing career")
	
	if SaveManager and is_instance_valid(SaveManager):
		SaveManager.load()
	
	if GameState and is_instance_valid(GameState):
		GameState.set_game_mode("campaign")
	
	show_career_hub()

func _on_career_new() -> void:
	## Start new career
	print("SceneFlow: Starting new career")
	
	if GameState and is_instance_valid(GameState):
		GameState.set_game_mode("campaign")
		GameState.delete_save()
		GameState._give_starter_kit()
	
	show_career_hub()

func _on_career_load() -> void:
	## Load career (show load dialog - not implemented yet)
	print("SceneFlow: Load career (TODO)")
	# TODO: Implement save slot selection screen
	_on_career_continue()  # Fallback to slot 0

func show_career_hub() -> void:
	## Show career hub with mission/bot management
	if current_screen and current_screen != main_menu:
		current_screen.queue_free()
	
	var hub: Control = career_hub_scene.instantiate()
	hub.name = "CareerHubScreen"
	
	if hub.has_signal("next_mission_pressed"):
		_safe_connect(hub, "next_mission_pressed", _on_hub_next_mission)
	if hub.has_signal("missions_pressed"):
		_safe_connect(hub, "missions_pressed", _on_hub_missions)
	if hub.has_signal("bot_management_pressed"):
		_safe_connect(hub, "bot_management_pressed", show_new_builder)
	if hub.has_signal("back_pressed"):
		_safe_connect(hub, "back_pressed", show_new_main_menu)
	
	screen_manager.add_child(hub)
	_switch_to_screen(hub, false)

func _on_hub_next_mission() -> void:
	## Start next available mission
	var next_arena: String = ""
	if GameState and is_instance_valid(GameState):
		next_arena = GameState.get_next_unlocked_arena()
	
	if next_arena.is_empty():
		next_arena = "arena_training"
	
	start_battle(next_arena)

func _on_hub_missions() -> void:
	## Open mission selection (campaign map)
	_open_campaign_map()

func show_new_builder() -> void:
	## Show new Bible-compliant builder
	if current_screen and current_screen != main_menu:
		current_screen.queue_free()
	
	var builder: Control = builder_screen_scene.instantiate()
	builder.name = "BuilderScreen"
	
	if builder.has_signal("back_pressed"):
		_safe_connect(builder, "back_pressed", _on_builder_back)
	if builder.has_signal("deploy_pressed"):
		_safe_connect(builder, "deploy_pressed", _on_builder_deploy)
	
	screen_manager.add_child(builder)
	_switch_to_screen(builder, false)

func _on_builder_back() -> void:
	## Return to career hub from builder
	if GameState and is_instance_valid(GameState):
		if GameState.game_mode == "arcade":
			show_new_main_menu()
		else:
			show_career_hub()

func _on_builder_deploy() -> void:
	## Deploy to mission select
	_open_campaign_map()

# ============================================================================
# LEGACY SCREEN NAVIGATION (for compatibility)
# ============================================================================

func _show_main_menu() -> void:
	# Show the main menu and hide others
	if current_screen and current_screen != main_menu:
		current_screen.visible = false
		if current_screen != main_menu:
			current_screen.queue_free()
			screen_stack.clear()
	
	main_menu.visible = true
	if main_menu.has_method("show_menu"):
		main_menu.show_menu()
	current_screen = main_menu
	
	# Save progress when returning to menu
	if SaveManager and is_instance_valid(SaveManager):
		SaveManager.autosave()

func _hide_main_menu() -> void:
	## Aggressively hide old menu - multiple safety checks
	if main_menu and is_instance_valid(main_menu):
		main_menu.visible = false
		main_menu.process_mode = Node.PROCESS_MODE_DISABLED
		if main_menu.has_method("hide_menu"):
			main_menu.hide_menu()
		print("SceneFlow: Old main menu hidden")
	else:
		print("SceneFlow: Old main menu reference invalid")
	
	## Also try to find and hide by name as fallback
	var old_menu := screen_manager.get_node_or_null("MainMenu")
	if old_menu and is_instance_valid(old_menu):
		old_menu.visible = false
		old_menu.process_mode = Node.PROCESS_MODE_DISABLED
		print("SceneFlow: Old menu (by name) hidden")

func _switch_to_screen(new_screen: Control, add_to_stack: bool = true) -> void:
	# Switch to a new screen with transition
	if current_screen and current_screen != main_menu:
		if add_to_stack:
			screen_stack.append(current_screen)
		current_screen.visible = false
	
	current_screen = new_screen
	current_screen.visible = true
	
	# Animate entry
	if current_screen.has_method("on_show"):
		current_screen.on_show()

func _go_back() -> void:
	# Return to previous screen
	if screen_stack.size() > 0:
		if current_screen and current_screen != main_menu:
			current_screen.visible = false
			
		current_screen = screen_stack.pop_back()
		current_screen.visible = true
		
		if current_screen.has_method("on_show"):
			current_screen.on_show()
	else:
		# Return to main menu
		if current_screen and current_screen != main_menu:
			if is_instance_valid(current_screen):
				current_screen.queue_free()
		_show_main_menu()

# ============================================================================
# MAIN MENU HANDLERS (Legacy)
# ============================================================================

func _on_start_campaign() -> void:
	print("SceneFlow: Starting new campaign")
	
	# Reset campaign progress for new game
	if GameState:
		GameState.set_game_mode("campaign")
		# Check if save exists and confirm overwrite
		if SaveManager and SaveManager._has_save():
			print("SceneFlow: Existing save found, starting fresh")
			GameState.delete_save()
			GameState._give_starter_kit()
	
	# Go to builder first
	_open_builder()

func _on_start_arcade() -> void:
	print("SceneFlow: Starting arcade mode")
	
	if GameState:
		GameState.set_game_mode("arcade")
	
	# Arcade goes straight to builder with all parts unlocked
	_open_builder()

func _on_continue_campaign() -> void:
	print("SceneFlow: Continuing campaign")
	
	if GameState:
		GameState.set_game_mode("campaign")
		# Load existing save
		SaveManager.load()
	
	# Go to campaign map or builder
	var next_arena: String = GameState.get_next_unlocked_arena()
	if next_arena.is_empty():
		_open_builder()
	else:
		_open_campaign_map()

func _on_open_shop() -> void:
	print("SceneFlow: Opening shop")
	_open_shop()

func _on_open_builder() -> void:
	print("SceneFlow: Opening builder")
	_open_builder()

func _on_open_settings() -> void:
	print("SceneFlow: Opening settings (not implemented)")
	pass

func _on_show_credits() -> void:
	print("SceneFlow: Showing credits (not implemented)")
	pass

func _on_quit() -> void:
	print("SceneFlow: Quitting game")
	if SaveManager and is_instance_valid(SaveManager):
		SaveManager.save()
	get_tree().quit()

# ============================================================================
# LEGACY SCREEN OPENERS
# ============================================================================

func _open_builder() -> void:
	_hide_main_menu()
	
	var builder: Control = old_build_screen_scene.instantiate()
	builder.name = "BuildScreen"
	
	# Connect builder signals
	if builder.has_signal("back_pressed"):
		_safe_connect(builder, "back_pressed", _go_back)
	if builder.has_signal("test_battle_pressed"):
		_safe_connect(builder, "test_battle_pressed", _on_test_battle)
	if builder.has_signal("start_campaign_pressed"):
		_safe_connect(builder, "start_campaign_pressed", _on_builder_start_campaign)
	
	# Also check for button connections in scene
	var back_btn: Button = builder.get_node_or_null("MarginContainer/VBox/BottomBar/BackBtn")
	if back_btn:
		_safe_connect_signal(back_btn, "pressed", _go_back)
	
	var test_btn: Button = builder.get_node_or_null("MarginContainer/VBox/BottomBar/TestBtn")
	if test_btn:
		_safe_connect_signal(test_btn, "pressed", _on_test_battle)
	
	screen_manager.add_child(builder)
	_switch_to_screen(builder)

func _safe_connect_signal(obj: Object, signal_name: String, callable: Callable) -> void:
	## Bible B1.3: Safe signal connection for objects
	if obj and is_instance_valid(obj):
		if obj.has_signal(signal_name):
			var sig = obj.get(signal_name)
			if sig and not sig.is_connected(callable):
				sig.connect(callable)

func _open_shop() -> void:
	_hide_main_menu()
	
	var shop: Control = shop_screen_scene.instantiate()
	shop.name = "ShopScreen"
	
	# Connect shop closed signal
	if shop.has_signal("shop_closed"):
		_safe_connect(shop, "shop_closed", _on_shop_closed)
	
	screen_manager.add_child(shop)
	_switch_to_screen(shop)
	
	if shop.has_method("open_shop"):
		shop.open_shop()

func _open_campaign_map() -> void:
	_hide_main_menu()
	
	var campaign: Control = campaign_screen_scene.instantiate()
	campaign.name = "CampaignScreen"
	
	# Connect campaign signals
	if campaign.has_signal("arena_selected"):
		_safe_connect(campaign, "arena_selected", _on_arena_selected)
	if campaign.has_signal("back_pressed"):
		_safe_connect(campaign, "back_pressed", _go_back)
	
	screen_manager.add_child(campaign)
	_switch_to_screen(campaign)

func _on_shop_closed() -> void:
	_go_back()

func _on_test_battle() -> void:
	# Start test battle from builder
	print("SceneFlow: Starting test battle")
	start_battle("arena_training")

func _on_builder_start_campaign() -> void:
	# Builder signals it's ready to start
	print("SceneFlow: Builder ready, starting campaign battle")
	var next_arena: String = ""
	if GameState and is_instance_valid(GameState):
		next_arena = GameState.get_next_unlocked_arena()
	if next_arena.is_empty():
		next_arena = "arena_training"
	start_battle(next_arena)

func _on_arena_selected(arena_id: String) -> void:
	# Campaign map selected an arena
	print("SceneFlow: Arena selected: ", arena_id)
	start_battle(arena_id)

# ============================================================================
# BATTLE FLOW
# ============================================================================

func start_battle(arena_id: String) -> void:
	print("SceneFlow: Starting battle in ", arena_id)
	_next_arena_id = arena_id
	
	# Hide current screen
	if current_screen:
		current_screen.visible = false
	
	# Create battle screen
	var battle: Control = battle_screen_scene.instantiate()
	battle.name = "BattleScreen"
	
	# Connect battle end signal
	if battle.has_signal("battle_ended"):
		_safe_connect(battle, "battle_ended", _on_battle_ended)
	
	screen_manager.add_child(battle)
	_switch_to_screen(battle, false)  # Don't add battle to stack
	
	# Start the battle
	if battle.has_method("start_campaign_battle"):
		battle.start_campaign_battle(arena_id)

func _on_battle_ended(result: Dictionary) -> void:
	# Battle finished - process results
	print("SceneFlow: Battle ended, result: ", result)
	
	# Update game state with results
	if result.get("victory", false):
		if GameState and is_instance_valid(GameState):
			GameState.complete_arena(_next_arena_id)
			GameState.add_credits(result.get("credits", 0))
	
	# Show results screen
	_show_results(result)

func _show_results(result: Dictionary) -> void:
	# Show results screen
	var results_screen: Control = results_screen_scene.instantiate()
	results_screen.name = "ResultsScreen"
	
	# Set results data
	if results_screen.has_method("set_results"):
		results_screen.set_results(result)
	
	# Connect results signals
	if results_screen.has_signal("continue_pressed"):
		_safe_connect(results_screen, "continue_pressed", _on_results_continue)
	if results_screen.has_signal("restart_pressed"):
		_safe_connect(results_screen, "restart_pressed", _on_results_restart)
	if results_screen.has_signal("menu_pressed"):
		_safe_connect(results_screen, "menu_pressed", _on_results_menu)
	
	# Hide battle, show results
	if current_screen:
		current_screen.queue_free()
	
	screen_manager.add_child(results_screen)
	current_screen = results_screen
	results_screen.visible = true

func _on_results_continue() -> void:
	# Continue to next arena or builder
	if current_screen:
		current_screen.queue_free()
	
	var next_arena: String = ""
	if GameState and is_instance_valid(GameState):
		next_arena = GameState.get_next_unlocked_arena()
	
	if next_arena.is_empty():
		_show_main_menu()  # All arenas complete
	else:
		_open_campaign_map()

func _on_results_restart() -> void:
	# Restart same battle
	if current_screen:
		current_screen.queue_free()
	start_battle(_next_arena_id)

func _on_results_menu() -> void:
	# Return to main menu
	if current_screen:
		current_screen.queue_free()
	_show_main_menu()

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input(event: InputEvent) -> void:
	# Global input handling
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			# ESC goes back or shows pause menu
			if current_screen != main_menu:
				_go_back()
		
		# F5 for quick save (debug)
		if event.pressed and event.keycode == KEY_F5:
			print("SceneFlow: Quick save triggered")
			if SaveManager and is_instance_valid(SaveManager):
				SaveManager.save()
		
		# F9 for quick load (debug)
		if event.pressed and event.keycode == KEY_F9:
			print("SceneFlow: Quick load triggered")
			if SaveManager and is_instance_valid(SaveManager):
				SaveManager.load()
