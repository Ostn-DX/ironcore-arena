class_name CareerSubmenuScreen
extends Control

## Career Submenu - Continue / New Career / Load Career / Back
## Bible B1.3: All signal connections use safe patterns
## Keyboard navigation: Arrow keys, Enter/Space, Escape

signal continue_pressed
signal new_career_pressed
signal load_career_pressed
signal back_pressed
signal exit_pressed

# UI References - Bible B1.2: @onready caching
@onready var _continue_button: Button = %ContinueButton
@onready var _new_career_button: Button = %NewCareerButton
@onready var _load_career_button: Button = %LoadCareerButton
@onready var _back_button: Button = %BackButton
@onready var _settings_button: Button = %SettingsButton
@onready var _exit_button: Button = %ExitButton

# Keyboard navigation - Bible 4.1: Typed array
var _focusable_buttons: Array[Button] = []
var _focused_index: int = 0

func _ready() -> void:
	_setup_button_signals()
	_setup_keyboard_navigation()
	_update_button_states()

func _setup_button_signals() -> void:
	## Bible B1.3: Safe signal connections with is_connected check
	if _continue_button and is_instance_valid(_continue_button):
		if not _continue_button.pressed.is_connected(_on_continue_pressed):
			_continue_button.pressed.connect(_on_continue_pressed)
	
	if _new_career_button and is_instance_valid(_new_career_button):
		if not _new_career_button.pressed.is_connected(_on_new_career_pressed):
			_new_career_button.pressed.connect(_on_new_career_pressed)
	
	if _load_career_button and is_instance_valid(_load_career_button):
		if not _load_career_button.pressed.is_connected(_on_load_career_pressed):
			_load_career_button.pressed.connect(_on_load_career_pressed)
	
	if _back_button and is_instance_valid(_back_button):
		if not _back_button.pressed.is_connected(_on_back_pressed):
			_back_button.pressed.connect(_on_back_pressed)
	
	if _settings_button and is_instance_valid(_settings_button):
		if not _settings_button.pressed.is_connected(_on_settings_pressed):
			_settings_button.pressed.connect(_on_settings_pressed)
	
	if _exit_button and is_instance_valid(_exit_button):
		if not _exit_button.pressed.is_connected(_on_exit_pressed):
			_exit_button.pressed.connect(_on_exit_pressed)

func _setup_keyboard_navigation() -> void:
	## Build focus list for arrow key navigation
	_focusable_buttons.clear()
	
	## Only add visible/enabled buttons
	if _continue_button and is_instance_valid(_continue_button) and _continue_button.visible:
		_focusable_buttons.append(_continue_button)
	if _new_career_button and is_instance_valid(_new_career_button):
		_focusable_buttons.append(_new_career_button)
	if _load_career_button and is_instance_valid(_load_career_button):
		_focusable_buttons.append(_load_career_button)
	
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
				_on_back_pressed()
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

func _update_button_states() -> void:
	## Bible: Check SaveManager exists before accessing
	var has_save: bool = false
	if SaveManager and is_instance_valid(SaveManager):
		has_save = SaveManager.save_exists(0)
	
	if _continue_button and is_instance_valid(_continue_button):
		_continue_button.visible = has_save
		_continue_button.disabled = not has_save

func _on_continue_pressed() -> void:
	if is_instance_valid(self):
		continue_pressed.emit()

func _on_new_career_pressed() -> void:
	if is_instance_valid(self):
		new_career_pressed.emit()

func _on_load_career_pressed() -> void:
	if is_instance_valid(self):
		load_career_pressed.emit()

func _on_back_pressed() -> void:
	if is_instance_valid(self):
		back_pressed.emit()

func _on_settings_pressed() -> void:
	## Forward to EventBus for global settings
	if EventBus and is_instance_valid(EventBus):
		EventBus.menu_opened.emit("settings")

func _on_exit_pressed() -> void:
	if is_instance_valid(self):
		exit_pressed.emit()

func _exit_tree() -> void:
	## Bible B1.3: Disconnect all signals
	var buttons: Array[Button] = [_continue_button, _new_career_button, 
		_load_career_button, _back_button, _settings_button, _exit_button]
	
	for button in buttons:
		if button and is_instance_valid(button):
			## Disconnect all pressed signals
			for connection in button.pressed.get_connections():
				var callable: Callable = connection["callable"]
				if button.pressed.is_connected(callable):
					button.pressed.disconnect(callable)
