extends Node
class_name SceneFlowManager
## SceneFlowManager — handles navigation between game screens.
## Attached to Main scene, manages the screen stack.

# Screen references
@onready var main_menu: MainMenu = $ScreenManager/MainMenu

# Preloaded scenes
var battle_screen_scene: PackedScene = preload("res://scenes/battle_screen.tscn")
var build_screen_scene: PackedScene = preload("res://scenes/build_screen.tscn")
var shop_screen_scene: PackedScene = preload("res://scenes/shop_screen.tscn")
var results_screen_scene: PackedScene = preload("res://scenes/results_screen.tscn")

# Active screens
var current_screen: Control = null
var screen_stack: Array[Control] = []

# Screen container
@onready var screen_manager: CanvasLayer = $ScreenManager


func _ready() -> void:
	_setup_signals()
	_show_main_menu()


func _setup_signals() -> void:
	## Connect main menu signals
	if main_menu:
		main_menu.start_campaign_pressed.connect(_on_start_campaign)
		main_menu.start_arcade_pressed.connect(_on_start_arcade)
		main_menu.continue_pressed.connect(_on_continue_campaign)
		main_menu.shop_pressed.connect(_on_open_shop)
		main_menu.builder_pressed.connect(_on_open_builder)
		main_menu.settings_pressed.connect(_on_open_settings)
		main_menu.credits_pressed.connect(_on_show_credits)


# ============================================================================
# SCREEN NAVIGATION
# ============================================================================

func _show_main_menu() -> void:
	## Show the main menu
	if main_menu:
		main_menu.show_menu()
	current_screen = main_menu


func _hide_main_menu() -> void:
	## Hide the main menu
	if main_menu:
		main_menu.hide_menu()


func _switch_to_screen(new_screen: Control, add_to_stack: bool = true) -> void:
	## Switch to a new screen
	if current_screen and current_screen != main_menu:
		if add_to_stack:
			screen_stack.append(current_screen)
		current_screen.visible = false
	
	current_screen = new_screen
	current_screen.visible = true


func _go_back() -> void:
	## Go back to previous screen
	if screen_stack.size() > 0:
		if current_screen:
			current_screen.visible = false
		
		current_screen = screen_stack.pop_back()
		current_screen.visible = true
	else:
		# Go to main menu
		if current_screen:
			current_screen.visible = false
		_show_main_menu()


# ============================================================================
# MAIN MENU HANDLERS
# ============================================================================

func _on_start_campaign() -> void:
	## Start new campaign - go to builder first
	print("SceneFlow: Starting new campaign")
	# For now, go straight to battle for testing
	# In full game, might go to campaign map or builder
	_open_builder()


func _on_start_arcade() -> void:
	## Start arcade mode
	print("SceneFlow: Starting arcade mode")
	_open_builder()


func _on_continue_campaign() -> void:
	## Continue existing campaign
	print("SceneFlow: Continuing campaign")
	# Go to campaign map or next available arena
	_open_builder()


func _on_open_shop() -> void:
	## Open the shop
	print("SceneFlow: Opening shop")
	_open_shop()


func _on_open_builder() -> void:
	## Open the builder
	print("SceneFlow: Opening builder")
	_open_builder()


func _on_open_settings() -> void:
	## Open settings
	print("SceneFlow: Opening settings")
	# TODO: Implement settings screen
	pass


func _on_show_credits() -> void:
	## Show credits
	print("SceneFlow: Showing credits")
	# TODO: Implement credits screen
	pass


# ============================================================================
# SCREEN OPENERS
# ============================================================================

func _open_builder() -> void:
	## Open the builder screen
	_hide_main_menu()
	
	var builder = build_screen_scene.instantiate()
	builder.name = "BuildScreen"
	screen_manager.add_child(builder)
	
	# Connect builder signals
	# TODO: Connect to_back, to_battle signals
	
	_switch_to_screen(builder)


func _open_shop() -> void:
	## Open the shop screen
	_hide_main_menu()
	
	var shop = shop_screen_scene.instantiate()
	shop.name = "ShopScreen"
	shop.shop_closed.connect(_on_shop_closed)
	screen_manager.add_child(shop)
	
	_switch_to_screen(shop)
	shop.open_shop()


func _on_shop_closed() -> void:
	## Return from shop
	_go_back()


func start_battle(arena_id: String) -> void:
	## Start a battle in specific arena
	print("SceneFlow: Starting battle in ", arena_id)
	
	# Hide current screen
	if current_screen:
		current_screen.visible = false
	
	# Create battle screen
	var battle = battle_screen_scene.instantiate()
	battle.name = "BattleScreen"
	screen_manager.add_child(battle)
	
	_switch_to_screen(battle)
	
	# Start the battle
	battle.start_campaign_battle(arena_id)


# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input(event: InputEvent) -> void:
	## Global input handling
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			# ESC goes back or pauses
			if current_screen != main_menu:
				_go_back()
