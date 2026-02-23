class_name BotSlot
extends PanelContainer

## Bot Slot Component - Displays a single bot in the builder
## Bible B1.3: All signal connections use safe patterns

signal selected
signal name_changed(new_name: String)
signal part_mounted(part_id: String)
signal part_unmounted(part_id: String)

# UI References - Bible B1.2: @onready caching
@onready var _visual_container: Control = %VisualContainer
@onready var _chassis_visual: TextureRect = %ChassisVisual
@onready var _armor_visual: TextureRect = %ArmorVisual
@onready var _weapon_visual: TextureRect = %WeaponVisual
@onready var _name_edit: LineEdit = %NameEdit
@onready var _enabled_checkbox: CheckBox = %EnabledCheckbox
@onready var _select_button: Button = %SelectButton

# State - Bible 4.1: Typed variables
var slot_index: int = 0
var is_enabled: bool = false
var loadout: Dictionary = {}
var _team_color: Color = Color.RED

func _ready() -> void:
	_setup_signals()
	_update_visuals()

func _setup_signals() -> void:
	## Bible B1.3: Safe signal connections
	if _select_button and is_instance_valid(_select_button):
		if not _select_button.pressed.is_connected(_on_select_pressed):
			_select_button.pressed.connect(_on_select_pressed)
	
	if _name_edit and is_instance_valid(_name_edit):
		if not _name_edit.text_changed.is_connected(_on_name_changed):
			_name_edit.text_changed.connect(_on_name_changed)
		if not _name_edit.focus_exited.is_connected(_on_name_edit_finished):
			_name_edit.focus_exited.connect(_on_name_edit_finished)
	
	if _enabled_checkbox and is_instance_valid(_enabled_checkbox):
		if not _enabled_checkbox.toggled.is_connected(_on_enabled_toggled):
			_enabled_checkbox.toggled.connect(_on_enabled_toggled)

func _on_select_pressed() -> void:
	if is_instance_valid(self):
		selected.emit()

func _on_name_changed(new_text: String) -> void:
	## Validate name length
	if new_text.length() > 20:
		new_text = new_text.substr(0, 20)
		if _name_edit and is_instance_valid(_name_edit):
			_name_edit.text = new_text

func _on_name_edit_finished() -> void:
	if _name_edit and is_instance_valid(_name_edit):
		var new_name: String = _name_edit.text.strip_edges()
		if new_name.is_empty():
			new_name = "Bot %d" % (slot_index + 1)
			_name_edit.text = new_name
		
		loadout["name"] = new_name
		
		if is_instance_valid(self):
			name_changed.emit(new_name)

func _on_enabled_toggled(toggled: bool) -> void:
	is_enabled = toggled
	_update_visuals()

func set_loadout(new_loadout: Dictionary) -> void:
	loadout = new_loadout.duplicate()
	_update_visuals()
	_update_name_edit()

func set_enabled(enabled: bool) -> void:
	is_enabled = enabled
	if _enabled_checkbox and is_instance_valid(_enabled_checkbox):
		_enabled_checkbox.button_pressed = enabled
	_update_visuals()

func set_team_color(color: Color) -> void:
	_team_color = color
	_update_visuals()

func _update_visuals() -> void:
	## Update visual state based on loadout
	var chassis_id: String = loadout.get("chassis", "")
	var armor_id: String = loadout.get("armor", "")
	var weapon_id: String = loadout.get("weapon", "")
	
	## Show/hide based on equipped parts
	if _chassis_visual and is_instance_valid(_chassis_visual):
		_chassis_visual.visible = not chassis_id.is_empty() and is_enabled
		if _chassis_visual.visible:
			_load_chassis_texture(chassis_id)
			_chassis_visual.modulate = _team_color
	
	if _armor_visual and is_instance_valid(_armor_visual):
		_armor_visual.visible = not armor_id.is_empty() and is_enabled
		if _armor_visual.visible:
			_load_armor_texture(armor_id)
			_armor_visual.modulate = _team_color
	
	if _weapon_visual and is_instance_valid(_weapon_visual):
		_weapon_visual.visible = not weapon_id.is_empty() and is_enabled
		if _weapon_visual.visible:
			_load_weapon_texture(weapon_id)
			_weapon_visual.modulate = _team_color

func _update_name_edit() -> void:
	if _name_edit and is_instance_valid(_name_edit):
		var bot_name: String = loadout.get("name", "Bot %d" % (slot_index + 1))
		_name_edit.text = bot_name

func _load_chassis_texture(chassis_id: String) -> void:
	if not DataLoader or not is_instance_valid(DataLoader):
		return
	
	var part: Dictionary = DataLoader.get_part_data(chassis_id)
	var texture_path: String = part.get("texture", "res://sprites/chassis_default.png")
	
	## Bible B3: Use load for dynamic paths
	var texture: Texture2D = load(texture_path)
	if texture and _chassis_visual and is_instance_valid(_chassis_visual):
		_chassis_visual.texture = texture

func _load_armor_texture(armor_id: String) -> void:
	if not DataLoader or not is_instance_valid(DataLoader):
		return
	
	var part: Dictionary = DataLoader.get_part_data(armor_id)
	var texture_path: String = part.get("texture", "res://sprites/armor_default.png")
	
	var texture: Texture2D = load(texture_path)
	if texture and _armor_visual and is_instance_valid(_armor_visual):
		_armor_visual.texture = texture

func _load_weapon_texture(weapon_id: String) -> void:
	if not DataLoader or not is_instance_valid(DataLoader):
		return
	
	var part: Dictionary = DataLoader.get_part_data(weapon_id)
	var texture_path: String = part.get("texture", "res://sprites/weapon_default.png")
	
	var texture: Texture2D = load(texture_path)
	if texture and _weapon_visual and is_instance_valid(_weapon_visual):
		_weapon_visual.texture = texture

func mount_part(part_id: String) -> void:
	if not DataLoader or not is_instance_valid(DataLoader):
		return
	
	var part: Dictionary = DataLoader.get_part_data(part_id)
	var part_type: String = part.get("type", "")
	
	match part_type:
		"chassis":
			loadout["chassis"] = part_id
		"armor":
			loadout["armor"] = part_id
		"weapon":
			loadout["weapon"] = part_id
	
	_update_visuals()
	
	if is_instance_valid(self):
		part_mounted.emit(part_id)

func unmount_selected_part() -> void:
	## Bible: Simple implementation - unmounts weapon first, then armor, then chassis
	if loadout.has("weapon"):
		var weapon_id: String = loadout["weapon"]
		loadout.erase("weapon")
		_update_visuals()
		part_unmounted.emit(weapon_id)
	elif loadout.has("armor"):
		var armor_id: String = loadout["armor"]
		loadout.erase("armor")
		_update_visuals()
		part_unmounted.emit(armor_id)
	elif loadout.has("chassis"):
		var chassis_id: String = loadout["chassis"]
		loadout.erase("chassis")
		_update_visuals()
		part_unmounted.emit(chassis_id)

func get_total_weight() -> int:
	var weight: int = 0
	
	if not DataLoader or not is_instance_valid(DataLoader):
		return weight
	
	for part_type in ["chassis", "armor", "weapon"]:
		if loadout.has(part_type):
			var part: Dictionary = DataLoader.get_part_data(loadout[part_type])
			weight += part.get("weight", 0)
	
	return weight

func get_total_dps() -> int:
	var dps: int = 0
	
	if not DataLoader or not is_instance_valid(DataLoader):
		return dps
	
	## Weapons provide DPS
	if loadout.has("weapon"):
		var weapon: Dictionary = DataLoader.get_part_data(loadout["weapon"])
		dps += weapon.get("damage", 0)
	
	return dps

func get_total_health() -> int:
	var health: int = 0
	
	if not DataLoader or not is_instance_valid(DataLoader):
		return health
	
	## Chassis provides base health
	if loadout.has("chassis"):
		var chassis: Dictionary = DataLoader.get_part_data(loadout["chassis"])
		health += chassis.get("health", 0)
	
	## Armor provides health bonus
	if loadout.has("armor"):
		var armor: Dictionary = DataLoader.get_part_data(loadout["armor"])
		health += armor.get("health", 0)
	
	return health

func _exit_tree() -> void:
	## Bible B1.3: Disconnect all signals
	if _select_button and is_instance_valid(_select_button):
		if _select_button.pressed.is_connected(_on_select_pressed):
			_select_button.pressed.disconnect(_on_select_pressed)
	
	if _name_edit and is_instance_valid(_name_edit):
		if _name_edit.text_changed.is_connected(_on_name_changed):
			_name_edit.text_changed.disconnect(_on_name_changed)
		if _name_edit.focus_exited.is_connected(_on_name_edit_finished):
			_name_edit.focus_exited.disconnect(_on_name_edit_finished)
	
	if _enabled_checkbox and is_instance_valid(_enabled_checkbox):
		if _enabled_checkbox.toggled.is_connected(_on_enabled_toggled):
			_enabled_checkbox.toggled.disconnect(_on_enabled_toggled)
