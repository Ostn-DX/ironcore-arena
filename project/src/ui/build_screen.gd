extends Control
## BuildScreen — bot assembly with categorized shop and equipped parts display

var selected_part: Dictionary = {}
var current_category: String = "all"
var current_loadout: Dictionary = {
	"id": "",
	"name": "New Bot",
	"chassis": "",
	"weapons": [],
	"armor": [],
	"mobility": [],
	"sensors": [],
	"utilities": []
}
var current_weight: float = 0.0
var max_weight: float = 0.0

@onready var category_tabs: TabBar = $MarginContainer/MainHBox/LeftPanel/CategoryTabs
@onready var parts_list: ItemList = $MarginContainer/MainHBox/LeftPanel/PartsList
@onready var slots_container: VBoxContainer = $MarginContainer/MainHBox/CenterPanel/SlotsContainer
@onready var weight_label: Label = $MarginContainer/MainHBox/CenterPanel/WeightLabel
@onready var weight_bar: ProgressBar = $MarginContainer/MainHBox/CenterPanel/WeightBar
@onready var credits_label: Label = $MarginContainer/MainHBox/RightPanel/CreditsLabel
@onready var details_label: Label = $MarginContainer/MainHBox/RightPanel/DetailsPanel/DetailsLabel
@onready var equip_btn: Button = $MarginContainer/MainHBox/RightPanel/EquipBtn
@onready var remove_btn: Button = $MarginContainer/MainHBox/RightPanel/RemoveBtn
@onready var buy_btn: Button = $MarginContainer/MainHBox/RightPanel/BuyBtn
@onready var sell_btn: Button = $MarginContainer/MainHBox/RightPanel/SellBtn

const CATEGORIES: Array = ["all", "chassis", "weapon", "armor", "mobility", "sensor", "utility"]

func _ready() -> void:
	_setup_category_tabs()
	_load_parts()
	_create_default_loadout()
	_update_display()

func _setup_category_tabs() -> void:
	for cat in CATEGORIES:
		category_tabs.add_tab(cat.capitalize())
	category_tabs.tab_changed.connect(_on_category_changed)

func _on_category_changed(tab: int) -> void:
	current_category = CATEGORIES[tab]
	_load_parts()

func _load_parts() -> void:
	parts_list.clear()
	if not DataLoader:
		return
	
	var parts: Array = DataLoader.get_all_parts()
	for part in parts:
		if part is Dictionary:
			var category: String = part.get("category", "")
			if current_category != "all" and category != current_category:
				continue
			
			var display_text: String = part.get("name", "Unknown")
			if not GameState.is_arcade_mode():
				var owned: int = GameState.get_part_quantity(part.get("id", ""))
				display_text += " [%d]" % owned
			
			parts_list.add_item(display_text)
			parts_list.set_item_metadata(parts_list.get_item_count() - 1, part)

func _create_default_loadout() -> void:
	if not DataLoader:
		return
	var chassis: Dictionary = DataLoader.get_part("chassis_light_t1")
	if not chassis.is_empty():
		_equip_part(chassis)

func _equip_part(part: Dictionary) -> void:
	var category: String = part.get("category", "")
	var part_id: String = part.get("id", "")
	
	match category:
		"chassis":
			current_loadout["chassis"] = part_id
			_create_slot_display()
		"weapon":
			if current_loadout["weapons"].size() < _get_slot_count("weapon"):
				current_loadout["weapons"].append(part_id)
		"armor":
			if current_loadout["armor"].size() < _get_slot_count("armor"):
				current_loadout["armor"].append(part_id)
		"mobility":
			if current_loadout["mobility"].size() < _get_slot_count("mobility"):
				current_loadout["mobility"].append(part_id)
		"sensor":
			if current_loadout["sensors"].size() < _get_slot_count("sensor"):
				current_loadout["sensors"].append(part_id)
		"utility":
			if current_loadout["utilities"].size() < _get_slot_count("utility"):
				current_loadout["utilities"].append(part_id)
	
	_update_weight()
	_update_display()

func _get_slot_count(category: String) -> int:
	if current_loadout["chassis"].is_empty():
		return 0
	var chassis: Dictionary = DataLoader.get_part(current_loadout["chassis"])
	var slots: Dictionary = chassis.get("slots", {})
	return slots.get(category, 0)

func _create_slot_display() -> void:
	# Clear existing
	for child in slots_container.get_children():
		child.queue_free()
	
	if current_loadout["chassis"].is_empty():
		return
	
	var chassis: Dictionary = DataLoader.get_part(current_loadout["chassis"])
	var slots: Dictionary = chassis.get("slots", {})
	
	# Chassis info
	var chassis_label: Label = Label.new()
	chassis_label.text = "Chassis: " + chassis.get("name", "Unknown")
	chassis_label.add_theme_font_size_override("font_size", 16)
	slots_container.add_child(chassis_label)
	
	# Create sections for each category
	for category in ["weapon", "armor", "mobility", "sensor", "utility"]:
		var count: int = slots.get(category, 0)
		if count == 0:
			continue
		
		# Category header
		var header: Label = Label.new()
		header.text = category.capitalize() + " Slots (" + str(count) + "):"
		header.add_theme_font_size_override("font_size", 14)
		slots_container.add_child(header)
		
		# Slots for this category
		var slots_hbox: HBoxContainer = HBoxContainer.new()
		slots_container.add_child(slots_hbox)
		
		var equipped: Array = current_loadout.get(category, [])
		for i in range(count):
			var btn: Button = Button.new()
			btn.custom_minimum_size = Vector2(100, 50)
			
			if i < equipped.size():
				var part: Dictionary = DataLoader.get_part(equipped[i])
				btn.text = part.get("name", "Part").substr(0, 12)
				btn.modulate = Color(0.7, 1.0, 0.7)  # Green = equipped
			else:
				btn.text = "[Empty]"
				btn.modulate = Color(0.5, 0.5, 0.5)  # Gray = empty
			
			btn.pressed.connect(_on_slot_pressed.bind(category, i))
			slots_hbox.add_child(btn)

func _update_weight() -> void:
	current_weight = 0.0
	max_weight = 0.0
	
	if not current_loadout["chassis"].is_empty():
		var chassis: Dictionary = DataLoader.get_part(current_loadout["chassis"])
		max_weight = chassis.get("stats", {}).get("weight_capacity", 0.0)
	
	for category in ["chassis", "weapons", "armor", "mobility", "sensors", "utilities"]:
		var part_ids: Array
		if category == "chassis":
			part_ids = [current_loadout["chassis"]] if not current_loadout["chassis"].is_empty() else []
		else:
			part_ids = current_loadout[category]
		
		for part_id in part_ids:
			var part: Dictionary = DataLoader.get_part(part_id)
			current_weight += part.get("weight", 0.0)

func _update_display() -> void:
	weight_bar.max_value = max_weight if max_weight > 0.0 else 100.0
	weight_bar.value = current_weight
	
	var status: String = "Weight: %.1f / %.1f kg" % [current_weight, max_weight]
	if current_weight > max_weight:
		status += " [OVERWEIGHT]"
		weight_bar.modulate = Color(1, 0, 0)
	elif current_weight > max_weight * 0.9:
		weight_bar.modulate = Color(1, 0.5, 0)
	else:
		weight_bar.modulate = Color(1, 1, 1)
	
	weight_label.text = status
	credits_label.text = "Credits: %d" % GameState.credits
	
	# Rebuild slots to show equipped parts
	_create_slot_display()

func _on_part_selected(index: int) -> void:
	selected_part = parts_list.get_item_metadata(index)
	_update_details()

func _update_details() -> void:
	if selected_part.is_empty():
		return
	
	var text: String = ""
	text += "[b]" + selected_part.get("name", "Unknown") + "[/b]\n"
	text += "Type: " + selected_part.get("category", "").capitalize() + "\n"
	text += "Weight: %.1f kg\n" % selected_part.get("weight", 0.0)
	
	if not GameState.is_arcade_mode():
		text += "Cost: %d CR\n" % selected_part.get("cost", 0)
		text += "Owned: %d\n" % GameState.get_part_quantity(selected_part.get("id", ""))
	
	text += "\n" + selected_part.get("description", "")
	
	var stats: Dictionary = selected_part.get("stats", {})
	if not stats.is_empty():
		text += "\n\nStats:\n"
		for stat_name in stats:
			text += "  %s: %s\n" % [stat_name, str(stats[stat_name])]
	
	details_label.text = text
	
	# Update button visibility based on mode and selection
	var _category: String = selected_part.get("category", "")
	var is_arcade: bool = GameState.is_arcade_mode()
	
	buy_btn.visible = not is_arcade
	sell_btn.visible = not is_arcade
	equip_btn.visible = true
	remove_btn.visible = false

func _on_slot_pressed(category: String, index: int) -> void:
	var equipped: Array = current_loadout.get(category, [])
	if index < equipped.size():
		# Show remove option for equipped part
		selected_part = DataLoader.get_part(equipped[index])
		_update_details()
		remove_btn.visible = true
		equip_btn.visible = false

func _on_equip_pressed() -> void:
	if selected_part.is_empty():
		return
	_equip_part(selected_part)

func _on_remove_pressed() -> void:
	if selected_part.is_empty():
		return
	
	var category: String = selected_part.get("category", "")
	var part_id: String = selected_part.get("id", "")
	var equipped: Array = current_loadout.get(category, [])
	
	# Find and remove
	for i in range(equipped.size()):
		if equipped[i] == part_id:
			equipped.remove_at(i)
			break
	
	_update_weight()
	_update_display()

func _on_buy_pressed() -> void:
	if selected_part.is_empty() or GameState.is_arcade_mode():
		return
	
	var cost: int = selected_part.get("cost", 0)
	if GameState.spend_credits(cost):
		GameState.add_part(selected_part.get("id", ""))
		_update_display()
		_load_parts()

func _on_sell_pressed() -> void:
	if selected_part.is_empty() or GameState.is_arcade_mode():
		return
	
	var cost: int = selected_part.get("cost", 0)
	if GameState.remove_part(selected_part.get("id", "")):
		GameState.add_credits(cost / 2)  # Integer division intended
		_update_display()
		_load_parts()

func _on_save_pressed() -> void:
	if current_loadout["chassis"].is_empty():
		return
	if current_weight > max_weight:
		return
	
	if current_loadout["id"].is_empty():
		current_loadout["id"] = "loadout_%d" % Time.get_unix_time_from_system()
	
	GameState.add_loadout(current_loadout.duplicate())
	print("Saved: ", current_loadout["name"])

func _on_test_pressed() -> void:
	if current_loadout["chassis"].is_empty():
		return
	
	if current_loadout["id"].is_empty():
		current_loadout["id"] = "test_loadout"
	GameState.add_loadout(current_loadout.duplicate())
	GameState.set_active_loadouts([current_loadout["id"]])
	
	get_tree().change_scene_to_file("res://scenes/battle_screen.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
