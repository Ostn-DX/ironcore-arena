extends Control
## BuildScreen — bot assembly with integrated shop
## Drag parts from inventory to chassis slots

# UI References (will be set in _ready or via @onready)
var parts_list: ItemList
var chassis_view: Control
var weight_bar: ProgressBar
var credits_label: Label
var part_details: Panel

# State
var selected_part: Dictionary = {}
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

# Slot UI elements
var slot_buttons: Dictionary = {}  # category -> Array[Button]

const SLOT_COLORS: Dictionary = {
	"weapon": Color(0.9, 0.3, 0.3),
	"armor": Color(0.3, 0.6, 0.9),
	"mobility": Color(0.3, 0.9, 0.3),
	"sensor": Color(0.9, 0.9, 0.3),
	"utility": Color(0.9, 0.3, 0.9)
}


func _ready() -> void:
	print("BuildScreen _ready() starting")
	_setup_ui()
	print("BuildScreen _setup_ui() done, loading parts")
	_load_parts()
	print("BuildScreen _load_parts() done, creating default loadout")
	_create_default_loadout()
	print("BuildScreen _create_default_loadout() done, updating display")
	_update_display()
	print("BuildScreen _ready() completed")


func _setup_ui() -> void:
	# Add background so we can see the screen is there
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	print("BuildScreen: Background added")
	
	# Main layout: 3 columns
	# Left: Parts inventory | Center: Chassis assembly | Right: Shop/Details
	
	var main_hbox: HBoxContainer = HBoxContainer.new()
	main_hbox.anchor_right = 1.0
	main_hbox.anchor_bottom = 1.0
	main_hbox.offset_top = 60  # Space for header
	main_hbox.offset_bottom = -60  # Space for footer
	main_hbox.add_theme_constant_override("separation", 20)
	add_child(main_hbox)
	
	# === LEFT COLUMN: Parts Inventory ===
	var left_panel: VBoxContainer = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(250, 0)
	main_hbox.add_child(left_panel)
	
	var inventory_label: Label = Label.new()
	inventory_label.text = "PARTS INVENTORY"
	inventory_label.add_theme_font_size_override("font_size", 18)
	left_panel.add_child(inventory_label)
	
	# Category filter buttons
	var filter_hbox: HBoxContainer = HBoxContainer.new()
	left_panel.add_child(filter_hbox)
	
	var categories: Array = ["All", "Chassis", "Weapon", "Armor", "Mobility", "Sensor", "Utility"]
	for cat in categories:
		var btn: Button = Button.new()
		btn.text = cat
		btn.pressed.connect(_on_filter_pressed.bind(cat.to_lower()))
		filter_hbox.add_child(btn)
	
	# Parts list
	parts_list = ItemList.new()
	parts_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parts_list.item_selected.connect(_on_part_selected)
	left_panel.add_child(parts_list)
	
	# === CENTER COLUMN: Chassis Assembly ===
	var center_panel: VBoxContainer = VBoxContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(center_panel)
	
	var assembly_label: Label = Label.new()
	assembly_label.text = "BOT ASSEMBLY"
	assembly_label.add_theme_font_size_override("font_size", 18)
	assembly_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_panel.add_child(assembly_label)
	
	# Loadout name
	var name_hbox: HBoxContainer = HBoxContainer.new()
	center_panel.add_child(name_hbox)
	
	var name_label: Label = Label.new()
	name_label.text = "Name:"
	name_hbox.add_child(name_label)
	
	var name_edit: LineEdit = LineEdit.new()
	name_edit.text = "New Bot"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect(_on_name_changed)
	name_hbox.add_child(name_edit)
	
	# Chassis view (where slots go)
	chassis_view = Control.new()
	chassis_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chassis_view.custom_minimum_size = Vector2(400, 400)
	center_panel.add_child(chassis_view)
	
	# === RIGHT COLUMN: Shop / Details ===
	var right_panel: VBoxContainer = VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(250, 0)
	main_hbox.add_child(right_panel)
	
	var shop_label: Label = Label.new()
	shop_label.text = "SHOP"
	shop_label.add_theme_font_size_override("font_size", 18)
	right_panel.add_child(shop_label)
	
	# Credits display
	credits_label = Label.new()
	credits_label.text = "Credits: 500"
	credits_label.add_theme_font_size_override("font_size", 16)
	right_panel.add_child(credits_label)
	
	# Part details panel
	part_details = Panel.new()
	part_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(part_details)
	
	var details_vbox: VBoxContainer = VBoxContainer.new()
	details_vbox.anchor_right = 1.0
	details_vbox.anchor_bottom = 1.0
	details_vbox.offset_left = 10
	details_vbox.offset_top = 10
	details_vbox.offset_right = -10
	details_vbox.offset_bottom = -10
	part_details.add_child(details_vbox)
	
	var details_label: Label = Label.new()
	details_label.text = "Select a part"
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_vbox.add_child(details_label)
	
	# === BOTTOM BAR ===
	var bottom_bar: HBoxContainer = HBoxContainer.new()
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.offset_top = -50
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(bottom_bar)
	
	# Weight bar
	var weight_label: Label = Label.new()
	weight_label.text = "Weight:"
	bottom_bar.add_child(weight_label)
	
	weight_bar = ProgressBar.new()
	weight_bar.custom_minimum_size = Vector2(200, 30)
	weight_bar.max_value = 100
	bottom_bar.add_child(weight_bar)
	
	# Action buttons
	var save_btn: Button = Button.new()
	save_btn.text = "Save Loadout"
	save_btn.pressed.connect(_on_save_loadout)
	bottom_bar.add_child(save_btn)
	
	var test_btn: Button = Button.new()
	test_btn.text = "Test Battle"
	test_btn.pressed.connect(_on_test_battle)
	bottom_bar.add_child(test_btn)
	
	var back_btn: Button = Button.new()
	back_btn.text = "Back to Campaign"
	back_btn.pressed.connect(_on_back_to_campaign)
	bottom_bar.add_child(back_btn)


func _load_parts() -> void:
	parts_list.clear()
	
	if not DataLoader:
		return
	
	var parts: Array = DataLoader.get_all_parts()
	for part in parts:
		if part is Dictionary:
			var name: String = part.get("name", "Unknown")
			var category: String = part.get("category", "")
			var cost: int = part.get("cost", 0)
			var owned: int = GameState.get_part_quantity(part.get("id", ""))
			
			var display_text: String
			if GameState.is_arcade_mode():
				display_text = "%s (%s)" % [name, category]
			else:
				display_text = "%s (%s) - %d CR [%d]" % [name, category, cost, owned]
			
			parts_list.add_item(display_text)
			parts_list.set_item_metadata(parts_list.get_item_count() - 1, part)


func _create_default_loadout() -> void:
	# Start with a basic chassis if DataLoader is ready
	if not DataLoader:
		return
	
	var starter_chassis: Dictionary = DataLoader.get_part("chassis_light_t1")
	if not starter_chassis.is_empty():
		_equip_part(starter_chassis)


func _equip_part(part: Dictionary) -> void:
	var category: String = part.get("category", "")
	var part_id: String = part.get("id", "")
	
	match category:
		"chassis":
			current_loadout["chassis"] = part_id
			_update_chassis_slots(part)
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


func _update_chassis_slots(chassis_part: Dictionary) -> void:
	# Clear existing slot buttons
	for child in chassis_view.get_children():
		child.queue_free()
	slot_buttons.clear()
	
	var slots: Dictionary = chassis_part.get("slots", {})
	var y_offset: float = 50
	
	for category in ["weapon", "armor", "mobility", "sensor", "utility"]:
		var count: int = slots.get(category, 0)
		if count == 0:
			continue
		
		# Category label
		var label: Label = Label.new()
		label.text = category.capitalize() + " Slots:"
		label.position = Vector2(10, y_offset)
		chassis_view.add_child(label)
		y_offset += 30
		
		# Slot buttons
		slot_buttons[category] = []
		for i in range(count):
			var btn: Button = Button.new()
			btn.custom_minimum_size = Vector2(80, 40)
			btn.position = Vector2(20 + i * 90, y_offset)
			btn.text = "Empty"
			
			# Color code by category
			var color: Color = SLOT_COLORS.get(category, Color.GRAY)
			btn.add_theme_color_override("font_color", color)
			
			btn.pressed.connect(_on_slot_pressed.bind(category, i))
			chassis_view.add_child(btn)
			slot_buttons[category].append(btn)
		
		y_offset += 60
	
	# Chassis visualization
	var chassis_bg: ColorRect = ColorRect.new()
	chassis_bg.color = Color(0.2, 0.2, 0.3)
	chassis_bg.size = Vector2(300, 40)
	chassis_bg.position = Vector2(50, 350)
	chassis_view.add_child(chassis_bg)
	
	var chassis_label: Label = Label.new()
	chassis_label.text = chassis_part.get("name", "Chassis")
	chassis_label.position = Vector2(120, 360)
	chassis_view.add_child(chassis_label)


func _update_weight() -> void:
	current_weight = 0.0
	max_weight = 0.0
	
	# Calculate max weight from chassis
	if not current_loadout["chassis"].is_empty():
		var chassis: Dictionary = DataLoader.get_part(current_loadout["chassis"])
		max_weight = chassis.get("stats", {}).get("weight_capacity", 0.0)
	
	# Calculate current weight
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
	# Update weight bar
	weight_bar.max_value = max_weight if max_weight > 0 else 100
	weight_bar.value = current_weight
	
	# Update weight bar text (built-in label)
	var weight_text: String = "%.1f / %.1f kg" % [current_weight, max_weight]
	weight_bar.tooltip_text = weight_text
	
	# Color based on weight
	if current_weight > max_weight:
		weight_bar.modulate = Color(1, 0, 0)  # Red = overweight
	elif current_weight > max_weight * 0.9:
		weight_bar.modulate = Color(1, 0.5, 0)  # Orange = near limit
	else:
		weight_bar.modulate = Color(1, 1, 1)  # White = OK
	
	# Update credits
	credits_label.text = "Credits: %d" % GameState.credits
	
	# Update slot buttons with equipped parts
	for category in slot_buttons:
		var equipped: Array = current_loadout.get(category, [])
		var buttons: Array = slot_buttons[category]
		
		for i in range(buttons.size()):
			if i < equipped.size():
				var part: Dictionary = DataLoader.get_part(equipped[i])
				buttons[i].text = part.get("name", "Part").substr(0, 10)
			else:
				buttons[i].text = "Empty"


func _on_filter_pressed(category: String) -> void:
	_load_parts_filtered(category)


func _load_parts_filtered(filter_category: String) -> void:
	parts_list.clear()
	
	if not DataLoader:
		return
	
	var parts: Array = DataLoader.get_all_parts()
	for part in parts:
		if part is Dictionary:
			var category: String = part.get("category", "")
			if filter_category != "all" and category != filter_category:
				continue
			
			var name: String = part.get("name", "Unknown")
			var cost: int = part.get("cost", 0)
			var owned: int = GameState.get_part_quantity(part.get("id", ""))
			
			var display_text: String = "%s - %d CR [%d]" % [name, cost, owned]
			parts_list.add_item(display_text)
			parts_list.set_item_metadata(parts_list.get_item_count() - 1, part)


func _on_part_selected(index: int) -> void:
	selected_part = parts_list.get_item_metadata(index)
	_update_part_details()


func _update_part_details() -> void:
	if selected_part.is_empty():
		return
	
	# Find the details label
	var details_vbox: VBoxContainer = part_details.get_child(0) if part_details.get_child_count() > 0 else null
	if not details_vbox:
		return
	
	var details_label: Label = details_vbox.get_child(0) if details_vbox.get_child_count() > 0 else null
	if not details_label:
		return
	
	var text: String = ""
	text += "[b]%s[/b]\n" % selected_part.get("name", "Unknown")
	text += "Type: %s\n" % selected_part.get("category", "").capitalize()
	text += "Weight: %.1f kg\n" % selected_part.get("weight", 0.0)
	text += "Cost: %d CR\n" % selected_part.get("cost", 0)
	text += "\n%s\n" % selected_part.get("description", "")
	
	var stats: Dictionary = selected_part.get("stats", {})
	if not stats.is_empty():
		text += "\nStats:\n"
		for stat_name in stats:
			text += "  %s: %s\n" % [stat_name, str(stats[stat_name])]
	
	details_label.text = text
	
	# Add buy/sell buttons (only in campaign mode)
	for child in details_vbox.get_children():
		if child is Button:
			child.queue_free()
	
	if GameState.is_arcade_mode():
		# In arcade mode, just show equip button
		var equip_btn_arcade: Button = Button.new()
		equip_btn_arcade.text = "Equip to Bot"
		equip_btn_arcade.pressed.connect(_on_equip_selected)
		details_vbox.add_child(equip_btn_arcade)
	else:
		# In campaign mode, show buy/sell/equip
		var part_id: String = selected_part.get("id", "")
		var owned: int = GameState.get_part_quantity(part_id)
		var cost: int = selected_part.get("cost", 0)
		
		if owned > 0:
			var sell_btn: Button = Button.new()
			sell_btn.text = "Sell (%d CR)" % (cost / 2)
			sell_btn.pressed.connect(_on_sell_part.bind(part_id))
			details_vbox.add_child(sell_btn)
		
		var buy_btn: Button = Button.new()
		buy_btn.text = "Buy (%d CR)" % cost
		buy_btn.pressed.connect(_on_buy_part.bind(part_id))
		details_vbox.add_child(buy_btn)
		
		# Equip button
		var equip_btn: Button = Button.new()
		equip_btn.text = "Equip to Bot"
		equip_btn.pressed.connect(_on_equip_selected)
		details_vbox.add_child(equip_btn)


func _on_buy_part(part_id: String) -> void:
	var part: Dictionary = DataLoader.get_part(part_id)
	if part.is_empty():
		return
	
	var cost: int = part.get("cost", 0)
	if GameState.spend_credits(cost):
		GameState.add_part(part_id)
		_update_display()
		_load_parts()  # Refresh to show new owned count
	else:
		print("Not enough credits!")


func _on_sell_part(part_id: String) -> void:
	var part: Dictionary = DataLoader.get_part(part_id)
	if part.is_empty():
		return
	
	var cost: int = part.get("cost", 0)
	var sell_price: int = cost / 2  # Integer division is intended
	
	if GameState.remove_part(part_id):
		GameState.add_credits(sell_price)
		_update_display()
		_load_parts()


func _on_equip_selected() -> void:
	if selected_part.is_empty():
		return
	_equip_part(selected_part)


func _on_slot_pressed(category: String, index: int) -> void:
	# Remove part from this slot if equipped
	var equipped: Array = current_loadout.get(category, [])
	if index < equipped.size():
		equipped.remove_at(index)
		_update_weight()
		_update_display()


func _on_name_changed(new_name: String) -> void:
	current_loadout["name"] = new_name


func _on_save_loadout() -> void:
	if current_loadout["chassis"].is_empty():
		print("Cannot save: no chassis equipped")
		return
	
	if current_weight > max_weight:
		print("Cannot save: overweight!")
		return
	
	# Generate ID if new
	if current_loadout["id"].is_empty():
		current_loadout["id"] = "loadout_%d" % Time.get_unix_time_from_system()
	
	GameState.add_loadout(current_loadout.duplicate())
	print("Loadout saved: ", current_loadout["name"])


func _on_test_battle() -> void:
	if current_loadout["chassis"].is_empty():
		print("Cannot test: no chassis equipped")
		return
	
	# Save current loadout as active
	if current_loadout["id"].is_empty():
		current_loadout["id"] = "test_loadout"
	GameState.add_loadout(current_loadout.duplicate())
	GameState.set_active_loadouts([current_loadout["id"]])
	
	# Go to battle
	UIManager.show_battle_screen()


func _on_back_to_campaign() -> void:
	UIManager.show_campaign_screen()


func on_show() -> void:
	print("BuildScreen on_show() called")
	visible = true
	_load_parts()
	_update_display()
	print("BuildScreen on_show() completed")


func on_hide() -> void:
	visible = false
