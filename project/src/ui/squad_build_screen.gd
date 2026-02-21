extends Control
## SquadBuildScreen — manage multiple bots with team weight cap

const MAX_BOTS: int = 4

var squad: Array[Dictionary] = []
var selected_bot_index: int = -1
var team_weight_cap: float = 500.0  # Set by arena

@onready var bot_list: ItemList = $MarginContainer/MainVBox/TopRow/BotListPanel/BotList
@onready var add_bot_btn: Button = $MarginContainer/MainVBox/TopRow/BotListPanel/AddBotBtn
@onready var remove_bot_btn: Button = $MarginContainer/MainVBox/TopRow/BotListPanel/RemoveBotBtn
@onready var chassis_list: ItemList = $MarginContainer/MainVBox/TopRow/PartsPanel/ChassisList
@onready var armor_list: ItemList = $MarginContainer/MainVBox/TopRow/PartsPanel/ArmorList
@onready var weapon_list: ItemList = $MarginContainer/MainVBox/TopRow/PartsPanel/WeaponList
@onready var team_weight_label: Label = $MarginContainer/MainVBox/BottomBar/TeamWeightLabel
@onready var test_battle_btn: Button = $MarginContainer/MainVBox/BottomBar/TestBattleBtn

func _ready() -> void:
	_load_squad()
	_load_parts()
	_update_display()

func _load_squad() -> void:
	# Load from GameState or create default
	if GameState.active_loadout_ids.is_empty():
		# Create default bot
		squad.append(_create_default_bot())
	else:
		# Load existing bots
		for loadout_id in GameState.active_loadout_ids:
			var loadout = GameState.get_loadout(loadout_id)
			if not loadout.is_empty():
				squad.append(loadout)

func _create_default_bot() -> Dictionary:
	return {
		"id": "bot_" + str(Time.get_unix_time_from_system()),
		"name": "Bot 1",
		"enabled": true,
		"chassis": "chassis_light_t1",
		"armor": "arm_plate_t1",
		"weapon": "wpn_mg_t1"
	}

func _load_parts() -> void:
	chassis_list.clear()
	armor_list.clear()
	weapon_list.clear()
	
	return

for part in DataLoader.get_all_parts():
	if not part is Dictionary:
		continue
	
	var category: String = part.get("category", "")
	var name: String = part.get("name", "Unknown")
	var cost: int = part.get("cost", 0)
	
	var display: String = name
	if not GameState.is_arcade_mode():
		display += " - " + str(cost) + " CR"
	
	match category:
		"chassis":
			chassis_list.add_item(display)
			chassis_list.set_item_metadata(chassis_list.get_item_count() - 1, part)
		"armor":
			armor_list.add_item(display)
			armor_list.set_item_metadata(armor_list.get_item_count() - 1, part)
		"weapon", "utility":
			weapon_list.add_item(display)
			weapon_list.set_item_metadata(weapon_list.get_item_count() - 1, part)

func _update_display() -> void:
	# Update bot list
	bot_list.clear()
	for i in range(squad.size()):
		var bot = squad[i]
		var status: String = "[ON] " if bot.get("enabled", true) else "[OFF] "
		bot_list.add_item(status + bot.get("name", "Unnamed"))
	
	# Calculate team weight
	var team_weight: float = _calculate_team_weight()
	var status_text: String = "Team Weight: %.1f / %.1f kg" % [team_weight, team_weight_cap]
	
	if team_weight > team_weight_cap:
		status_text += " [OVER!]"
		team_weight_label.modulate = Color(1, 0, 0)
	else:
		team_weight_label.modulate = Color(1, 1, 1)
	
	team_weight_label.text = status_text
	
	# Enable/disable test battle
	test_battle_btn.disabled = team_weight > team_weight_cap or _get_enabled_bot_count() == 0

func _calculate_team_weight() -> float:
	var total: float = 0.0
	for bot in squad:
		if not bot.get("enabled", true):
			continue
		
		for slot in ["chassis", "armor", "weapon"]:
			var part_id: String = bot.get(slot, "")
			if not part_id.is_empty():
				var part: Dictionary = DataLoader.get_part(part_id)
				if not part.is_empty():
					total += part.get("weight", 0.0)
	
	return total

func _get_enabled_bot_count() -> int:
	var count: int = 0
	for bot in squad:
		if bot.get("enabled", true):
			count += 1
	return count

func _on_bot_selected(index: int) -> void:
	selected_bot_index = index

func _on_add_bot() -> void:
	if squad.size() >= MAX_BOTS:
		return
	
	var new_bot: Dictionary = _create_default_bot()
	new_bot["name"] = "Bot " + str(squad.size() + 1)
	squad.append(new_bot)
	_update_display()

func _on_remove_bot() -> void:
	if selected_bot_index < 0 or selected_bot_index >= squad.size():
		return
	
	squad.remove_at(selected_bot_index)
	selected_bot_index = -1
	_update_display()

func _on_toggle_bot_enabled(index: int) -> void:
	if index < 0 or index >= squad.size():
		return
	
	var bot: Dictionary = squad[index]
	bot["enabled"] = not bot.get("enabled", true)
	_update_display()

func _on_chassis_selected(index: int) -> void:
	if selected_bot_index < 0:
		return
	
	var part: Dictionary = chassis_list.get_item_metadata(index)
	squad[selected_bot_index]["chassis"] = part.get("id", "")
	_update_display()

func _on_armor_selected(index: int) -> void:
	if selected_bot_index < 0:
		return
	
	var part: Dictionary = armor_list.get_item_metadata(index)
	squad[selected_bot_index]["armor"] = part.get("id", "")
	_update_display()

func _on_weapon_selected(index: int) -> void:
	if selected_bot_index < 0:
		return
	
	var part: Dictionary = weapon_list.get_item_metadata(index)
	squad[selected_bot_index]["weapon"] = part.get("id", "")
	_update_display()

func _on_test_battle() -> void:
	# Save squad and go to battle
	GameState.active_loadout_ids.clear()
	for bot in squad:
		GameState.add_loadout(bot)
		if bot.get("enabled", true):
			GameState.active_loadout_ids.append(bot["id"])
	
	get_tree().change_scene_to_file("res://scenes/battle_screen.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
