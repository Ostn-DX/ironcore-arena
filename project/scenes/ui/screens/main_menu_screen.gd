class_name MainMenuScreen
extends Control

## Main Menu - Entry point for Ironcore Arena
## Bible B1.3: All signal connections use safe patterns
## Keyboard navigation: Arrow keys, Enter/Space, Escape

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

# Keyboard navigation - Bible 4.1: Typed array
var _focusable_buttons: Array[Button] = []
var _focused_index: int = 0

func _ready() -> void:
	## Bible B1.3: Safe signal connections
	_setup_button_signals()
	_setup_keyboard_navigation()
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

func _setup_keyboard_navigation() -> void:
	## Build focus list for arrow key navigation
	_focusable_buttons.clear()
	
	if _career_button and is_instance_valid(_career_button):
		_focusable_buttons.append(_career_button)
	if _arcade_button and is_instance_valid(_arcade_button):
		_focusable_buttons.append(_arcade_button)
	
	## Set initial focus
	if _focusable_buttons.size() > 0:
		_focused_index = 0
		_focusable_buttons[0].grab_focus()

func _input(event: InputEvent) -> void:
	## Keyboard navigation handler
	if not visible:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				_navigate_focus(-1)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_navigate_focus(1)
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_activate_focused()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_on_exit_pressed()
				get_viewport().set_input_as_handled()

func _navigate_focus(direction: int) -> void:
	## Move focus up/down through buttons
	if _focusable_buttons.size() == 0:
		return
	
	_focused_index += direction
	_focused_index = clamp(_focused_index, 0, _focusable_buttons.size() - 1)
	_focusable_buttons[_focused_index].grab_focus()

func _activate_focused() -> void:
	## Activate the currently focused button
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button and is_instance_valid(focused):
		focused.emit_signal("pressed")

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
