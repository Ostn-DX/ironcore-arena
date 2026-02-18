extends Control
## BuildScreen — simplified Bot Arena 3 style
## One chassis, one armor, one weapon

var selected_chassis: Dictionary = {}
var selected_armor: Dictionary = {}
var selected_weapon: Dictionary = {}

var current_loadout: Dictionary = {
	"id": "",
	"name": "New Bot",
	"chassis": "",
	"armor": "",
	"weapon": ""
}

var current_weight: float = 0.0
var max_weight: float = 0.0

@onready var chassis_list: ItemList = $MarginContainer/MainHBox/LeftPanel/ChassisList
@onready var armor_list: ItemList = $MarginContainer/MainHBox/CenterPanel/ArmorList
@onready var weapon_list: ItemList = $MarginContainer/MainHBox/RightPanel/WeaponList

@onready var chassis_info: Label = $MarginContainer/MainHBox/LeftPanel/ChassisInfo
@onready var armor_info: Label = $MarginContainer/MainHBox/CenterPanel/ArmorInfo
@onready var weapon_info: Label = $MarginContainer/MainHBox/RightPanel/WeaponInfo

@onready var weight_label: Label = $MarginContainer/MainHBox/BottomBar/WeightLabel
@onready var credits_label: Label = $MarginContainer/MainHBox/BottomBar/CreditsLabel
@onready var test_btn: Button = $MarginContainer/MainHBox/BottomBar/TestBtn
@onready var back_btn: Button = $MarginContainer/MainHBox/BottomBar/BackBtn

func _ready() -> void:
	_load_parts()
	_set_default_loadout()
	_update_display()

func _load_parts() -> void:
	chassis_list.clear()
	armor_list.clear()
	weapon_list.clear()
	
	if not DataLoader:
		return
	
	for part in DataLoader.get_all_parts():
		if not part is Dictionary:
			continue
		
		var category: String = part.get("category", "")
		var name: String = part.get("name", "Unknown")
		var cost: int = part.get("cost", 0)
		var owned: int = GameState.get_part_quantity(part.get("id", "")) if not GameState.is_arcade_mode() else 99
		
		var display: String = name + "\n" + str(cost) + " CR"
		if not GameState.is_arcade_mode():
			display += " [" + str(owned) + "]"
		
		match category:
			"chassis":
				chassis_list.add_item(display)
				chassis_list.set_item_metadata(chassis_list.get_item_count() - 1, part)
			"armor":
				armor_list.add_item(display)
				armor_list.set_item_metadata(armor_list.get_item_count() - 1, part)
			"weapon":
				weapon_list.add_item(display)
				weapon_list.set_item_metadata(weapon_list.get_item_count() - 1, part)

func _set_default_loadout() -> void:
	if not DataLoader:
		return
	
	# Find first available parts
	for part in DataLoader.get_all_parts():
		if not part is Dictionary:
			continue
		var cat: String = part.get("category", "")
		var id: String = part.get("id", "")
		
		if cat == "chassis" and current_loadout["chassis"].is_empty():
			current_loadout["chassis"] = id
		elif cat == "armor" and current_loadout["armor"].is_empty():
			current_loadout["armor"] = id
		elif cat == "weapon" and current_loadout["weapon"].is_empty():
			current_loadout["weapon"] = id

func _update_display() -> void:
	# Calculate weight
	current_weight = 0.0
	max_weight = 0.0
	
	# Chassis info
	if not current_loadout["chassis"].is_empty():
		var chassis: Dictionary = DataLoader.get_part(current_loadout["chassis"])
		var c_stats: Dictionary = chassis.get("stats", {})
		max_weight = c_stats.get("weight_capacity", 0.0)
		current_weight += chassis.get("weight", 0.0)
		
		chassis_info.text = "CHASSIS: " + chassis.get("name", "")
		chassis_info.text += "\nWeight Limit: %.0f kg" % max_weight
		chassis_info.text += "\nCost: %d CR" % chassis.get("cost", 0)
	
	# Armor info
	if not current_loadout["armor"].is_empty():
		var armor: Dictionary = DataLoader.get_part(current_loadout["armor"])
		var a_stats: Dictionary = armor.get("stats", {})
		current_weight += armor.get("weight", 0.0)
		
		armor_info.text = "ARMOR: " + armor.get("name", "")
		armor_info.text += "\nHP: %d" % a_stats.get("hp", 0)
		armor_info.text += "\nWeight: %.1f kg" % armor.get("weight", 0.0)
		armor_info.text += "\nCost: %d CR" % armor.get("cost", 0)
	
	# Weapon info
	if not current_loadout["weapon"].is_empty():
		var weapon: Dictionary = DataLoader.get_part(current_loadout["weapon"])
		var w_stats: Dictionary = weapon.get("stats", {})
		current_weight += weapon.get("weight", 0.0)
		
		var damage: float = w_stats.get("damage_per_shot", 0.0)
		var fire_rate: float = w_stats.get("fire_rate", 1.0)
		var dpm: float = damage * fire_rate * 60.0
		
		weapon_info.text = "WEAPON: " + weapon.get("name", "")
		weapon_info.text += "\nDamage: %.1f" % damage
		weapon_info.text += "\nRange: %.0f" % w_stats.get("range_max", 0.0)
		weapon_info.text += "\nDPM: %.0f" % dpm
		weapon_info.text += "\nWeight: %.1f kg" % weapon.get("weight", 0.0)
		weapon_info.text += "\nCost: %d CR" % weapon.get("cost", 0)
	
	# Weight bar
	var weight_text: String = "Weight: %.1f / %.1f kg" % [current_weight, max_weight]
	if current_weight > max_weight:
		weight_text += " [OVER!]"
		weight_label.modulate = Color(1, 0, 0)
	else:
		weight_label.modulate = Color(1, 1, 1)
	weight_label.text = weight_text
	
	# Credits
	credits_label.text = "Credits: %d" % GameState.credits
	
	# Enable/disable test button
	test_btn.disabled = current_weight > max_weight or current_loadout["chassis"].is_empty()

func _on_chassis_selected(index: int) -> void:
	var part: Dictionary = chassis_list.get_item_metadata(index)
	current_loadout["chassis"] = part.get("id", "")
	_update_display()

func _on_armor_selected(index: int) -> void:
	var part: Dictionary = armor_list.get_item_metadata(index)
	current_loadout["armor"] = part.get("id", "")
	_update_display()

func _on_weapon_selected(index: int) -> void:
	var part: Dictionary = weapon_list.get_item_metadata(index)
	current_loadout["weapon"] = part.get("id", "")
	_update_display()

func _on_test_pressed() -> void:
	if current_loadout["chassis"].is_empty():
		return
	if current_weight > max_weight:
		return
	
	# Save and go to battle
	current_loadout["id"] = "test_bot"
	GameState.add_loadout(current_loadout.duplicate())
	GameState.set_active_loadouts(["test_bot"])
	
	get_tree().change_scene_to_file("res://scenes/battle_screen.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
