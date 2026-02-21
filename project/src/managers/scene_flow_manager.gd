extends Node
class_name SceneFlowManager
## SceneFlowManager — handles navigation between game screens.
## WIRED UP: Connects all screens with proper signal flow

# Screen references
@onready var main_menu: Control = $ScreenManager/MainMenu

# Preloaded scenes
var battle_screen_scene: PackedScene = preload("res://scenes/battle_screen.tscn")
var build_screen_scene: PackedScene = preload("res://scenes/build_screen.tscn")
var shop_screen_scene: PackedScene = preload("res://scenes/shop_screen.tscn")
var campaign_screen_scene: PackedScene = preload("res://scenes/campaign_screen.tscn")

# Active screens
var current_screen: Control = null
var screen_stack: Array[Control] = []

# Screen container
@onready var screen_manager: CanvasLayer = $ScreenManager

# Current arena for battles
var _next_arena_id: String = "arena_boot_camp"

func _ready() -> void:
	_setup_signals()
	_show_main_menu()
	
	# Auto-save on exit
	get_tree().set_auto_accept_quit(false)

func _setup_signals() -> void:
	# Connect main menu signals - works with both old and redesigned menu
	if main_menu:
		# Try redesigned menu signals first
		if main_menu.has_signal("start_campaign_pressed"):
			main_menu.start_campaign_pressed.connect(_on_start_campaign)
			main_menu.start_arcade_pressed.connect(_on_start_arcade)
			main_menu.continue_pressed.connect(_on_continue_campaign)
			main_menu.shop_pressed.connect(_on_open_shop)
			main_menu.builder_pressed.connect(_on_open_builder)
			main_menu.settings_pressed.connect(_on_open_settings)
			main_menu.quit_pressed.connect(_on_quit)
		else:
			# Fallback to old menu signals
			main_menu.start_campaign_pressed.connect(_on_start_campaign)
			main_menu.start_arcade_pressed.connect(_on_start_arcade)
			main_menu.continue_pressed.connect(_on_continue_campaign)
			main_menu.shop_pressed.connect(_on_open_shop)
			main_menu.builder_pressed.connect(_on_open_builder)
			main_menu.settings_pressed.connect(_on_open_settings)
			main_menu.credits_pressed.connect(_on_show_credits)
			main_menu.quit_pressed.connect(_on_quit)

func _notification(what: int) -> void:
	# Auto-save when quitting
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("SceneFlow: Auto-saving before exit...")
		SaveManager.save()
		get_tree().quit()

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
	SaveManager.autosave()

func _hide_main_menu() -> void:
	if main_menu:
		main_menu.visible = false
		if main_menu.has_method("hide_menu"):
			main_menu.hide_menu()

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
# MAIN MENU HANDLERS
# ============================================================================

func _on_start_campaign() -> void:
	print("SceneFlow: Starting new campaign")
	
	# Reset campaign progress for new game
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
	
	GameState.set_game_mode("arcade")

# Arcade goes straight to builder with all parts unlocked
_open_builder()

func _on_continue_campaign() -> void:
	print("SceneFlow: Continuing campaign")
	
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
	# TODO: Implement settings screen
	pass

func _on_show_credits() -> void:
	print("SceneFlow: Showing credits (not implemented)")
	# TODO: Implement credits screen
	pass

func _on_quit() -> void:
	print("SceneFlow: Quitting game")
	SaveManager.save()
	get_tree().quit()

# ============================================================================
# SCREEN OPENERS
# ============================================================================

func _open_builder() -> void:
	_hide_main_menu()
	
	var builder: Control = build_screen_scene.instantiate()
	builder.name = "BuildScreen"
	
	# Connect builder signals
	if builder.has_signal("back_pressed"):
		builder.back_pressed.connect(_go_back)
	if builder.has_signal("test_battle_pressed"):
		builder.test_battle_pressed.connect(_on_test_battle)
	if builder.has_signal("start_campaign_pressed"):
		builder.start_campaign_pressed.connect(_on_builder_start_campaign)
	
	# Also check for button connections in scene
	var back_btn: Button = builder.get_node_or_null("MarginContainer/VBox/BottomBar/BackBtn")
	if back_btn:
		back_btn.pressed.connect(_go_back)
	
	var test_btn: Button = builder.get_node_or_null("MarginContainer/VBox/BottomBar/TestBtn")
	if test_btn:
		test_btn.pressed.connect(_on_test_battle)
	
	screen_manager.add_child(builder)
	_switch_to_screen(builder)

func _open_shop() -> void:
	_hide_main_menu()
	
	var shop: Control = shop_screen_scene.instantiate()
	shop.name = "ShopScreen"
	
	# Connect shop closed signal
	if shop.has_signal("shop_closed"):
		shop.shop_closed.connect(_on_shop_closed)
	
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
		campaign.arena_selected.connect(_on_arena_selected)
	if campaign.has_signal("back_pressed"):
		campaign.back_pressed.connect(_go_back)
	
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
	var next_arena: String = GameState.get_next_unlocked_arena()
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
		battle.battle_ended.connect(_on_battle_ended)
	
	screen_manager.add_child(battle)
	_switch_to_screen(battle, false)  ; Don't add battle to stack
	
	# Start the battle
	if battle.has_method("start_campaign_battle"):
		battle.start_campaign_battle(arena_id)

func _on_battle_ended(result: Dictionary) -> void:
	# Battle finished - process results
	print("SceneFlow: Battle ended, result: ", result)
	
	# Update game state with results
	if result.get("victory", false):
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
		results_screen.continue_pressed.connect(_on_results_continue)
	if results_screen.has_signal("restart_pressed"):
		results_screen.restart_pressed.connect(_on_results_restart)
	if results_screen.has_signal("menu_pressed"):
		results_screen.menu_pressed.connect(_on_results_menu)
	
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
	
	var next_arena: String = GameState.get_next_unlocked_arena()
	if next_arena.is_empty():
		_show_main_menu()  ; All arenas complete
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
			else:
				# On main menu, ESC could show quit confirm
				pass
		
		# F5 for quick save (debug)
		if event.pressed and event.keycode == KEY_F5:
			print("SceneFlow: Quick save triggered")
			SaveManager.save()
		
		# F9 for quick load (debug)
		if event.pressed and event.keycode == KEY_F9:
			print("SceneFlow: Quick load triggered")
			SaveManager.load()
