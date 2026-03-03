class_name CareerHubScreen
extends Control

## Career Hub - Main career screen with mission and bot management
## Bible B1.3: All signal connections use safe patterns

signal next_mission_pressed
signal missions_pressed
signal bot_management_pressed
signal back_pressed

# UI References - Bible B1.2: @onready caching
@onready var _next_mission_button: Button = %NextMissionButton
@onready var _missions_button: Button = %MissionsButton
@onready var _bot_management_button: Button = %BotManagementButton
@onready var _back_button: Button = %BackButton
@onready var _settings_button: Button = %SettingsButton
@onready var _exit_button: Button = %ExitButton
@onready var _career_info_label: Label = %CareerInfoLabel

func _ready() -> void:
	_setup_button_signals()
	_update_career_info()

func _setup_button_signals() -> void:
	## Bible B1.3: Safe signal connections
	if _next_mission_button and is_instance_valid(_next_mission_button):
		if not _next_mission_button.pressed.is_connected(_on_next_mission_pressed):
			_next_mission_button.pressed.connect(_on_next_mission_pressed)
	
	if _missions_button and is_instance_valid(_missions_button):
		if not _missions_button.pressed.is_connected(_on_missions_pressed):
			_missions_button.pressed.connect(_on_missions_pressed)
	
	if _bot_management_button and is_instance_valid(_bot_management_button):
		if not _bot_management_button.pressed.is_connected(_on_bot_management_pressed):
			_bot_management_button.pressed.connect(_on_bot_management_pressed)
	
	if _back_button and is_instance_valid(_back_button):
		if not _back_button.pressed.is_connected(_on_back_pressed):
			_back_button.pressed.connect(_on_back_pressed)
	
	if _settings_button and is_instance_valid(_settings_button):
		if not _settings_button.pressed.is_connected(_on_settings_pressed):
			_settings_button.pressed.connect(_on_settings_pressed)
	
	if _exit_button and is_instance_valid(_exit_button):
		if not _exit_button.pressed.is_connected(_on_exit_pressed):
			_exit_button.pressed.connect(_on_exit_pressed)

func _update_career_info() -> void:
	## Bible: Check GameState exists before accessing
	if not GameState or not is_instance_valid(GameState):
		return
	
	var info: String = "Career Progress\n"
	info += "Credits: %d\n" % GameState.credits
	info += "Tier: %d\n" % GameState.current_tier
	info += "Completed: %d arenas" % GameState.completed_arenas.size()
	
	if _career_info_label and is_instance_valid(_career_info_label):
		_career_info_label.text = info

func _on_next_mission_pressed() -> void:
	if is_instance_valid(self):
		next_mission_pressed.emit()

func _on_missions_pressed() -> void:
	if is_instance_valid(self):
		missions_pressed.emit()

func _on_bot_management_pressed() -> void:
	if is_instance_valid(self):
		bot_management_pressed.emit()

func _on_back_pressed() -> void:
	if is_instance_valid(self):
		back_pressed.emit()

func _on_settings_pressed() -> void:
	if EventBus and is_instance_valid(EventBus):
		EventBus.menu_opened.emit("settings")

func _on_exit_pressed() -> void:
	if EventBus and is_instance_valid(EventBus):
		EventBus.game_quit_requested.emit()

func _exit_tree() -> void:
	## Bible B1.3: Disconnect all signals
	var buttons: Array[Button] = [_next_mission_button, _missions_button,
		_bot_management_button, _back_button, _settings_button, _exit_button]
	
	for button in buttons:
		if button and is_instance_valid(button):
			for connection in button.pressed.get_connections():
				var callable: Callable = connection["callable"]
				if button.pressed.is_connected(callable):
					button.pressed.disconnect(callable)
