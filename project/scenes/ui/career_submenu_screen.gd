class_name CareerSubmenuScreen
extends Control

## Career Submenu - Continue / New Career / Load Career / Back
## Bible B1.3: All signal connections use safe patterns

signal continue_pressed
signal new_career_pressed
signal load_career_pressed
signal back_pressed

# UI References - Bible B1.2: @onready caching
@onready var _continue_button: Button = %ContinueButton
@onready var _new_career_button: Button = %NewCareerButton
@onready var _load_career_button: Button = %LoadCareerButton
@onready var _back_button: Button = %BackButton
@onready var _settings_button: Button = %SettingsButton
@onready var _exit_button: Button = %ExitButton

func _ready() -> void:
	_setup_button_signals()
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
