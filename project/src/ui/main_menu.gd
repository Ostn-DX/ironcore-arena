extends Control
## MainMenu — entry point with campaign, arcade, settings, instructions, exit

@onready var title_label: Label = $TitleLabel
@onready var button_container: VBoxContainer = $ButtonContainer

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Dark background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	# Title
	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.text = "IRONCORE ARENA"
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_top = 80
	title.offset_left = -200
	title.offset_right = 200
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	add_child(title)
	
	# Subtitle
	var subtitle: Label = Label.new()
	subtitle.text = "Bot Arena 4 - Spiritual Successor"
	subtitle.anchor_left = 0.5
	subtitle.anchor_right = 0.5
	subtitle.offset_top = 140
	subtitle.offset_left = -150
	subtitle.offset_right = 150
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.modulate = Color(0.7, 0.7, 0.7)
	add_child(subtitle)
	
	# Button container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "ButtonContainer"
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -100
	vbox.offset_top = -100
	vbox.offset_right = 100
	vbox.offset_bottom = 200
	vbox.add_theme_constant_override("separation", 15)
	add_child(vbox)
	
	# Create buttons
	_create_button("Campaign", _on_campaign_pressed)
	_create_button("Arcade Battle", _on_arcade_pressed)
	_create_button("Instructions", _on_instructions_pressed)
	_create_button("Settings", _on_settings_pressed)
	_create_button("Exit", _on_exit_pressed)

func _create_button(text: String, callback: Callable) -> void:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 50)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(callback)
	$ButtonContainer.add_child(btn)

func _on_campaign_pressed() -> void:
	print("Campaign pressed - calling show_build_screen")
	# Set mode to campaign (career progression)
	GameState.set_game_mode("campaign")
	print("Game mode set to campaign, now showing build screen")
	UIManager.show_build_screen()
	print("show_build_screen called")

func _on_arcade_pressed() -> void:
	print("Arcade Battle pressed")
	# Set mode to arcade (everything unlocked)
	GameState.set_game_mode("arcade")
	UIManager.show_build_screen()

func _on_instructions_pressed() -> void:
	print("Instructions pressed")
	_show_instructions()

func _on_settings_pressed() -> void:
	print("Settings pressed")
	_show_settings()

func _on_exit_pressed() -> void:
	print("Exit pressed")
	get_tree().quit()

func _show_instructions() -> void:
	var popup: AcceptDialog = AcceptDialog.new()
	popup.title = "How to Play"
	popup.dialog_text = """IRONCORE ARENA - Instructions

BUILD YOUR BOT:
- Buy parts from the shop
- Equip chassis, weapons, armor, mobility
- Watch your weight limit!

BATTLE:
- Bots fight automatically
- Drag your bot to move
- Drag to enemy to focus fire
- Destroy all enemies to win

TIPS:
- Stay at max weapon range
- Use cover and positioning
- Upgrade parts as you earn credits

Good luck, commander!"""
	popup.size = Vector2(500, 400)
	add_child(popup)
	popup.popup_centered()

func _show_settings() -> void:
	var popup: AcceptDialog = AcceptDialog.new()
	popup.title = "Settings"
	popup.dialog_text = "Settings will be implemented in a future update."
	popup.size = Vector2(400, 200)
	add_child(popup)
	popup.popup_centered()

func on_show() -> void:
	visible = true

func on_hide() -> void:
	visible = false
