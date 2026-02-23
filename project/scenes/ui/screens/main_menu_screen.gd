class_name MainMenuScreen
extends Control

## Main Menu - Entry point for Ironcore Arena
## Bible B1.3: All signal connections use safe patterns

signal career_pressed
signal arcade_pressed
signal settings_pressed
signal exit_pressed

# UI References - Bible B1.2: @onready caching
@onready var _title_label: Label = %TitleLabel
@onready var _career_button: Button = %CareerButton
@onready var _arcade_button: Button = %ArcadeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _exit_button: Button = %ExitButton
@onready var _animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	## Bible B1.3: Safe signal connections
	_setup_button_signals()
	_play_intro_animation()

func _setup_button_signals() -> void:
	## Bible B1.3: Check is_connected before connecting
	if _career_button and is_instance_valid(_career_button):
		if not _career_button.pressed.is_connected(_on_career_pressed):
			_career_button.pressed.connect(_on_career_pressed)
	
	if _arcade_button and is_instance_valid(_arcade_button):
		if not _arcade_button.pressed.is_connected(_on_arcade_pressed):
			_arcade_button.pressed.connect(_on_arcade_pressed)
	
	if _settings_button and is_instance_valid(_settings_button):
		if not _settings_button.pressed.is_connected(_on_settings_pressed):
			_settings_button.pressed.connect(_on_settings_pressed)
	
	if _exit_button and is_instance_valid(_exit_button):
		if not _exit_button.pressed.is_connected(_on_exit_pressed):
			_exit_button.pressed.connect(_on_exit_pressed)

func _play_intro_animation() -> void:
	if _animation_player and is_instance_valid(_animation_player):
		_animation_player.play("intro")

func _on_career_pressed() -> void:
	## Bible B1.3: Check validity before emit
	if is_instance_valid(self):
		career_pressed.emit()

func _on_arcade_pressed() -> void:
	if is_instance_valid(self):
		arcade_pressed.emit()

func _on_settings_pressed() -> void:
	if is_instance_valid(self):
		settings_pressed.emit()

func _on_exit_pressed() -> void:
	if is_instance_valid(self):
		exit_pressed.emit()

func _exit_tree() -> void:
	## Bible B1.3: Disconnect all signals
	if _career_button and is_instance_valid(_career_button):
		if _career_button.pressed.is_connected(_on_career_pressed):
			_career_button.pressed.disconnect(_on_career_pressed)
	
	if _arcade_button and is_instance_valid(_arcade_button):
		if _arcade_button.pressed.is_connected(_on_arcade_pressed):
			_arcade_button.pressed.disconnect(_on_arcade_pressed)
	
	if _settings_button and is_instance_valid(_settings_button):
		if _settings_button.pressed.is_connected(_on_settings_pressed):
			_settings_button.pressed.disconnect(_on_settings_pressed)
	
	if _exit_button and is_instance_valid(_exit_button):
		if _exit_button.pressed.is_connected(_on_exit_pressed):
			_exit_button.pressed.disconnect(_on_exit_pressed)
