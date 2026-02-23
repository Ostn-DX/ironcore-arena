class_name MainMenu
extends Control
const UIThemeGenerator = preload("res://src/tools/ui_theme_generator.gd")
## MainMenu - entry point for the game.
## Provides navigation to all game modes and features.

signal start_campaign_pressed
signal start_arcade_pressed
signal continue_pressed
signal shop_pressed
signal builder_pressed
signal settings_pressed
signal credits_pressed
signal quit_pressed

# UI Elements
var title_label: Label = null
var subtitle_label: Label = null
var button_container: VBoxContainer = null
var version_label: Label = null
var save_info_label: Label = null

# Menu buttons
var continue_btn: Button = null
var new_campaign_btn: Button = null
var arcade_btn: Button = null
var shop_btn: Button = null
var builder_btn: Button = null
var settings_btn: Button = null
var credits_btn: Button = null
var quit_btn: Button = null

# Animation
var title_tween: Tween = null


func _ready() -> void:
	_apply_styled_theme()
	_setup_ui()
	_update_button_visibility()
	_animate_title()


func _apply_styled_theme() -> void:
	## Apply the generated UI theme
	var theme_gen: UIThemeGenerator = UIThemeGenerator.new()
	var theme: Theme = theme_gen.generate_theme()
	self.theme = theme


func _setup_ui() -> void:
	## Setup the main menu UI
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Background with generated texture
	var bg: TextureRect = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# Generate or load background
	var theme_gen: UIThemeGenerator = UIThemeGenerator.new()
	var bg_texture: Texture2D = theme_gen.generate_menu_background()
	bg.texture = bg_texture
	add_child(bg)
	
	# Title container
	var title_container: Control = Control.new()
	title_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	# Center horizontally based on viewport
	var viewport_width: float = get_viewport_rect().size.x
	title_container.position = Vector2(viewport_width / 2 - 640, 80)  # Offset from top center
	title_container.size = Vector2(1280, 200)
	add_child(title_container)
	
	# Main title
	title_label = Label.new()
	title_label.text = "IRONCORE"
	title_label.add_theme_font_size_override("font_size", 96)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.position = Vector2(0, 0)
	title_label.size = Vector2(1280, 100)
	
	# Title styling
	title_label.modulate = Color(0.9, 0.9, 0.95)
	title_container.add_child(title_label)
	
	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = "ARENA"
	subtitle_label.add_theme_font_size_override("font_size", 48)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.position = Vector2(0, 90)
	subtitle_label.size = Vector2(1280, 60)
	subtitle_label.modulate = Color(0.6, 0.7, 0.9)
	title_container.add_child(subtitle_label)
	
	# Tagline
	var tagline: Label = Label.new()
	tagline.text = "Build. Battle. Dominate."
	tagline.add_theme_font_size_override("font_size", 18)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.position = Vector2(0, 155)
	tagline.size = Vector2(1280, 30)
	tagline.modulate = Color(0.5, 0.5, 0.5)
	title_container.add_child(tagline)
	
	# Button container - responsive centering
	button_container = VBoxContainer.new()
	button_container.size = Vector2(200, 300)
	button_container.add_theme_constant_override("separation", 10)
	add_child(button_container)
	# Wait a frame for viewport to be ready, then center
	await get_tree().process_frame
	_center_button_container()
	
	# Continue button (only if save exists)
	continue_btn = _create_menu_button("Continue", _on_continue, true)
	button_container.add_child(continue_btn)
	
	# New Campaign
	new_campaign_btn = _create_menu_button("New Campaign", _on_new_campaign, true)
	button_container.add_child(new_campaign_btn)
	
	# Arcade Mode
	arcade_btn = _create_menu_button("Arcade Mode", _on_arcade, false)
	button_container.add_child(arcade_btn)
	
	# Shop
	shop_btn = _create_menu_button("Component Shop", _on_shop)
	button_container.add_child(shop_btn)
	
	# Builder
	builder_btn = _create_menu_button("Bot Builder", _on_builder)
	button_container.add_child(builder_btn)
	
	# Separator
	var separator: Control = Control.new()
	separator.custom_minimum_size = Vector2(0, 10)
	button_container.add_child(separator)
	
	# Settings
	settings_btn = _create_menu_button("Settings", _on_settings)
	button_container.add_child(settings_btn)
	
	# Credits
	credits_btn = _create_menu_button("Credits", _on_credits)
	button_container.add_child(credits_btn)
	
	# Separator
	var separator2: Control = Control.new()
	separator2.custom_minimum_size = Vector2(0, 10)
	button_container.add_child(separator2)
	
	# Quit
	quit_btn = _create_menu_button("Quit Game", _on_quit)
	button_container.add_child(quit_btn)
	
	# Save info label
	save_info_label = Label.new()
	save_info_label.position = Vector2(20, 680)
	save_info_label.size = Vector2(400, 30)
	save_info_label.add_theme_font_size_override("font_size", 14)
	save_info_label.modulate = Color(0.4, 0.4, 0.4)
	add_child(save_info_label)
	
	# Version label
	version_label = Label.new()
	version_label.text = "v0.1.0"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.position = Vector2(1100, 680)
	version_label.size = Vector2(160, 30)
	version_label.add_theme_font_size_override("font_size", 14)
	version_label.modulate = Color(0.4, 0.4, 0.4)
	add_child(version_label)


func _center_button_container() -> void:
	## Center the button container based on actual viewport size
	var viewport_size: Vector2 = get_viewport_rect().size
	button_container.position = Vector2(
		(viewport_size.x - button_container.size.x) / 2,
		(viewport_size.y - button_container.size.y) / 2
	)

func _create_menu_button(text: String, callback: Callable, is_primary: bool = false) -> Button:
	## Create a styled menu button
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 45)
	btn.size = Vector2(220, 45)
	
	# Style based on importance
	if is_primary:
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_font_size_override("font_size", 20)
	else:
		btn.add_theme_font_size_override("font_size", 18)
	
	# Connect signals
	btn.pressed.connect(callback)
	btn.mouse_entered.connect(_on_button_hover)
	
	return btn


func _on_button_hover() -> void:
	## Play hover sound
	get_node("/root/AudioManager").play_ui_hover()


func _update_button_visibility() -> void:
	## Update which buttons are visible based on save state
	var has_save: bool = _has_save_file()
	
	if continue_btn:
		continue_btn.visible = has_save
	
	if save_info_label:
		if has_save:
			var progress: String = _get_save_progress_summary()
			save_info_label.text = "Save found: " + progress
		else:
			save_info_label.text = "No save file - Start a new campaign"


func _has_save_file() -> bool:
	## Check if a save file exists
	return FileAccess.file_exists("user://ironcore_save.json")


func _get_save_progress_summary() -> String:
	## Get a brief summary of save progress
	var game_state = get_node("/root/GameState")
	var tier: int = game_state.current_tier
	var credits: int = game_state.credits
	var completed: int = game_state.completed_arenas.size()
	
	return "Tier %d | %d CR | %d arenas" % [tier + 1, credits, completed]


func _animate_title() -> void:
	## Animate the title
	title_tween = create_tween()
	title_tween.set_loops()
	title_tween.tween_property(title_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.0)
	title_tween.tween_property(title_label, "modulate", Color(0.9, 0.9, 0.95, 1.0), 2.0)


# ============================================================================
# BUTTON HANDLERS
# ============================================================================

func _on_continue() -> void:
	## Continue existing campaign
	print("MainMenu: Continue campaign")
	get_node("/root/GameState").set_game_mode("campaign")
	continue_pressed.emit()


func _on_new_campaign() -> void:
	## Start new campaign
	print("MainMenu: New campaign")
	
	# Confirm if save exists
	if _has_save_file():
		# In a real implementation, show a confirmation dialog
		print("MainMenu: Warning - overwriting existing save")
		get_node("/root/GameState").delete_save()
		get_node("/root/GameState").set_game_mode("campaign")
	else:
		get_node("/root/GameState").set_game_mode("campaign")
	
	start_campaign_pressed.emit()


func _on_arcade() -> void:
	## Start arcade mode
	print("MainMenu: Arcade mode")
	get_node("/root/GameState").set_game_mode("arcade")
	start_arcade_pressed.emit()


func _on_shop() -> void:
	## Open shop
	print("MainMenu: Open shop")
	shop_pressed.emit()


func _on_builder() -> void:
	## Open builder
	print("MainMenu: Open builder")
	builder_pressed.emit()


func _on_settings() -> void:
	## Open settings
	print("MainMenu: Open settings")
	settings_pressed.emit()


func _on_credits() -> void:
	## Show credits
	print("MainMenu: Show credits")
	credits_pressed.emit()


func _on_quit() -> void:
	## Quit game
	print("MainMenu: Quit game")
	quit_pressed.emit()
	get_tree().quit()


# ============================================================================
# PUBLIC API
# ============================================================================

func show_menu() -> void:
	## Show the main menu
	visible = true
	_update_button_visibility()


func hide_menu() -> void:
	## Hide the main menu
	visible = false
