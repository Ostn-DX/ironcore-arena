extends Node
## UIManager singleton — manages screen transitions and input routing.

signal screen_changed(screen_name: String)

enum Screen {
	NONE,
	MAIN_MENU,
	BUILD,
	BATTLE,
	CAMPAIGN,
	SHOP,
	SETTINGS
}

var current_screen: Screen = Screen.NONE
var _screens: Dictionary = {}

@onready var screen_container: Control = null


func _ready() -> void:
	# Find or create screen container
	_call_deferred_setup()


func _call_deferred_setup() -> void:
	await get_tree().process_frame
	
	# Try to find existing container
	var main: Node = get_tree().current_scene
	if main:
		screen_container = main.get_node_or_null("ScreenContainer")
		if not screen_container:
			# Create container
			screen_container = Control.new()
			screen_container.name = "ScreenContainer"
			screen_container.anchor_right = 1.0
			screen_container.anchor_bottom = 1.0
			main.add_child(screen_container)
	
	# Register screens
	_register_screen(Screen.MAIN_MENU, "res://scenes/main_menu.tscn")
	_register_screen(Screen.BUILD, "res://scenes/build_screen.tscn")
	_register_screen(Screen.BATTLE, "res://scenes/battle_screen.tscn")
	_register_screen(Screen.CAMPAIGN, "res://scenes/campaign_screen.tscn")
	
	# Show main menu by default
	show_main_menu()


func _register_screen(screen: Screen, scene_path: String) -> void:
	_screens[screen] = {
		"path": scene_path,
		"instance": null
	}


func show_screen(screen: Screen) -> void:
	print("UIManager: Showing screen ", _screen_to_string(screen))
	if current_screen == screen:
		print("UIManager: Already on this screen, returning")
		return
	
	# Hide current
	_hide_current_screen()
	
	# Show new
	current_screen = screen
	
	if _screens.has(screen):
		var screen_data: Dictionary = _screens[screen]
		
		# Instantiate if needed
		if screen_data["instance"] == null or not is_instance_valid(screen_data["instance"]):
			var scene: PackedScene = load(screen_data["path"])
			if scene:
				screen_data["instance"] = scene.instantiate()
				screen_container.add_child(screen_data["instance"])
			else:
				push_error("UIManager: Failed to load screen: ", screen_data["path"])
				return
		
		screen_data["instance"].show()
		screen_data["instance"].process_mode = Node.PROCESS_MODE_INHERIT
		
		# Notify screen it's shown
		if screen_data["instance"].has_method("on_show"):
			screen_data["instance"].on_show()
	
	screen_changed.emit(_screen_to_string(screen))


func _hide_current_screen() -> void:
	print("UIManager: Hiding current screen: ", _screen_to_string(current_screen))
	if current_screen == Screen.NONE:
		print("UIManager: No current screen to hide")
		return
	
	if _screens.has(current_screen):
		var screen_data: Dictionary = _screens[current_screen]
		if screen_data["instance"] != null and is_instance_valid(screen_data["instance"]):
			print("UIManager: Hiding instance of ", _screen_to_string(current_screen))
			screen_data["instance"].hide()
			screen_data["instance"].process_mode = Node.PROCESS_MODE_DISABLED
			
			if screen_data["instance"].has_method("on_hide"):
				screen_data["instance"].on_hide()
		else:
			print("UIManager: No valid instance to hide")
	else:
		print("UIManager: Current screen not in _screens")


func show_main_menu() -> void:
	show_screen(Screen.MAIN_MENU)

func show_build_screen() -> void:
	show_screen(Screen.BUILD)


func show_battle_screen() -> void:
	show_screen(Screen.BATTLE)


func show_campaign_screen() -> void:
	show_screen(Screen.CAMPAIGN)


func get_current_screen_instance() -> Node:
	if current_screen == Screen.NONE:
		return null
	if _screens.has(current_screen):
		return _screens[current_screen]["instance"]
	return null


func _screen_to_string(screen: Screen) -> String:
	match screen:
		Screen.MAIN_MENU: return "main_menu"
		Screen.BUILD: return "build"
		Screen.BATTLE: return "battle"
		Screen.CAMPAIGN: return "campaign"
		Screen.SHOP: return "shop"
		Screen.SETTINGS: return "settings"
	return "none"
