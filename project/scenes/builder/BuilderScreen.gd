extends Control
class_name BuilderScreen
## Builder UI - drag-and-drop bot assembly
## Team of 5 bots, weight validation, stat preview

@onready var _game_state = get_node("/root/GameState")
@onready var _data_loader = get_node("/root/DataLoader")

@onready var chassis_list: ItemList = $Panel/ChassisList
@onready var plating_list: ItemList = $Panel/PlatingList  
@onready var weapon_list: ItemList = $Panel/WeaponList
@onready var bot_slots: HBoxContainer = $BotSlots
@onready var weight_label: Label = $Stats/WeightLabel
@onready var team_weight_bar: ProgressBar = $Stats/TeamWeightBar
@onready var start_button: Button = $Actions/StartButton
@onready var save_button: Button = $Actions/SaveButton
@onready var back_button: Button = $Actions/BackButton

# Current build state
var current_team: Array = []  # Array of BuildSlot
var selected_chassis: String = ""
var selected_plating: String = ""
var selected_weapon: String = ""

# Arena weight limit (set when entering builder)
var arena_weight_limit: float = 120.0

# Signals
signal build_completed(team_config: Array)
signal build_saved(build_name: String)
signal exited


func _ready():
	_populate_component_lists()
	_create_bot_slots()
	_update_weight_display()
	
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect list selections
	chassis_list.item_selected.connect(_on_chassis_selected)
	plating_list.item_selected.connect(_on_plating_selected)
	weapon_list.item_selected.connect(_on_weapon_selected)


## Populate component lists from DataLoader
func _populate_component_lists() -> void:
	chassis_list.clear()
	plating_list.clear()
	weapon_list.clear()
	
	# Load all unlocked components
	var tier = _game_state.current_tier
	
	# Chassis
	for chassis in _data_loader.get_chassis_by_tier(tier):
		var idx = chassis_list.add_item("%s (T%d)" % [chassis.name, chassis.tier])
		chassis_list.set_item_metadata(idx, chassis.id)
	
	# Plating  
	for plating in _data_loader.get_plating_by_tier(tier):
		var idx = plating_list.add_item("%s (T%d)" % [plating.name, plating.tier])
		plating_list.set_item_metadata(idx, plating.id)
	
	# Weapons
	for weapon in _data_loader.get_weapons_by_tier(tier):
		var idx = weapon_list.add_item("%s (T%d)" % [weapon.name, weapon.tier])
		weapon_list.set_item_metadata(idx, weapon.id)


## Create 5 bot slot UI elements
func _create_bot_slots() -> void:
	for i in range(5):
		var slot = BuildSlot.new()
		slot.slot_index = i
		slot.clicked.connect(_on_slot_clicked.bind(i))
		slot.bot_assembled.connect(_on_bot_assembled.bind(i))
		bot_slots.add_child(slot)
		current_team.append(slot)


## Calculate total team weight
func _calculate_team_weight() -> float:
	var total: float = 0.0
	for slot in current_team:
		if slot.has_bot():
			total += slot.get_bot_weight()
	return total


## Update weight display UI
func _update_weight_display() -> void:
	var weight = _calculate_team_weight()
	var ratio = weight / arena_weight_limit
	
	weight_label.text = "Team Weight: %.0f / %.0f" % [weight, arena_weight_limit]
	team_weight_bar.value = ratio * 100.0
	
	# Color coding
	if ratio <= 1.0:
		team_weight_bar.modulate = Color.GREEN
		start_button.disabled = false
	else:
		team_weight_bar.modulate = Color.RED
		start_button.disabled = true
		start_button.tooltip_text = "Team exceeds weight limit!"


## Selection handlers
func _on_chassis_selected(index: int) -> void:
	selected_chassis = chassis_list.get_item_metadata(index)

func _on_plating_selected(index: int) -> void:
	selected_plating = plating_list.get_item_metadata(index)

func _on_weapon_selected(index: int) -> void:
	selected_weapon = weapon_list.get_item_metadata(index)


## Slot clicked - assemble bot with selected parts
func _on_slot_clicked(index: int) -> void:
	var slot = current_team[index]
	
	# Validate selections
	if selected_chassis.is_empty() or selected_plating.is_empty():
		_show_error("Select chassis and plating first!")
		return
	
	# Build bot
	var success = slot.build_bot(selected_chassis, selected_plating, selected_weapon)
	
	if success:
		_update_weight_display()
	else:
		_show_error("Invalid build! Check weight capacity.")


## Bot assembled in slot
func _on_bot_assembled(index: int) -> void:
	_update_weight_display()


## Start battle button
func _on_start_pressed() -> void:
	var team_config = _export_team_config()
	if team_config.size() == 0:
		_show_error("Build at least one bot!")
		return
	
	build_completed.emit(team_config)


## Save build button
func _on_save_pressed() -> void:
	# TODO: Save dialog
	build_saved.emit("Quick Save")


## Back button
func _on_back_pressed() -> void:
	exited.emit()


## Export team configuration for battle
func _export_team_config() -> Array:
	var config: Array = []
	for slot in current_team:
		if slot.has_bot():
			config.append(slot.export_config())
	return config


## Show error popup
func _show_error(message: String) -> void:
	# Simple error display - could be a popup
	push_warning("Builder Error: %s" % message)
