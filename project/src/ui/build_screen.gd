extends Control
## BuildScreen - Bot Arena 3 style with Shop, Inventory, My Bots
## WIRED UP: Signals connected to SceneFlowManager

signal back_pressed
signal test_battle_pressed
signal start_campaign_pressed

var selected_shop_category: String = ""
var selected_part: Dictionary = {}

var current_bot: Dictionary = {
	"id": "bot_1",
	"name": "Bot 1",
	"chassis": "chassis_light_t1",
	"armor": "arm_plate_t1",
	"weapon": "wpn_mg_t1"
}

@onready var shop_buttons: HBoxContainer = $MarginContainer/MainGrid/ShopPanel/ShopButtons
@onready var shop_list: ItemList = $MarginContainer/MainGrid/ShopPanel/ShopList
@onready var inventory_filter: OptionButton = $MarginContainer/MainGrid/InventoryPanel/InventoryFilter
@onready var inventory_list: ItemList = $MarginContainer/MainGrid/InventoryPanel/InventoryList
@onready var my_bots_list: ItemList = $MarginContainer/MainGrid/MyBotsPanel/MyBotsList
@onready var bot_name_edit: LineEdit = $MarginContainer/MainGrid/MyBotsPanel/BotNameEdit
@onready var item_name_label: Label = $MarginContainer/MainGrid/DescriptionPanel/ItemNameLabel
@onready var item_stats_label: Label = $MarginContainer/MainGrid/DescriptionPanel/ItemStatsLabel
@onready var item_description_label: Label = $MarginContainer/MainGrid/DescriptionPanel/ItemDescriptionLabel
@onready var manufacturer_label: Label = $MarginContainer/MainGrid/DescriptionPanel/ManufacturerLabel
@onready var preview_label: Label = $MarginContainer/MainGrid/DescriptionPanel/PreviewLabel
@onready var action_button: Button = $MarginContainer/MainGrid/DescriptionPanel/ActionButton
@onready var mount_button: Button = $MarginContainer/MainGrid/ActionsPanel/MountButton
@onready var unmount_button: Button = $MarginContainer/MainGrid/ActionsPanel/UnmountButton
@onready var enable_button: Button = $MarginContainer/MainGrid/ActionsPanel/EnableButton
@onready var disable_button: Button = $MarginContainer/MainGrid/ActionsPanel/DisableButton
@onready var team_color_picker: ColorPickerButton = $MarginContainer/MainGrid/ActionsPanel/TeamColorPicker
@onready var weight_label: Label = $MarginContainer/MainGrid/ActionsPanel/StatsContainer/WeightLabel
@onready var dps_label: Label = $MarginContainer/MainGrid/ActionsPanel/StatsContainer/DPSLabel
@onready var credits_label: Label = $MarginContainer/MainGrid/BottomBar/CreditsLabel
@onready var test_btn: Button = $MarginContainer/MainGrid/BottomBar/TestBtn
@onready var back_btn: Button = $MarginContainer/MainGrid/BottomBar/BackBtn

func _ready() -> void:
	print("BuildScreen: _ready() called")
	_setup_mouse_filters()
	_setup_shop_buttons()
	_load_inventory()
	_load_my_bots()
	_update_bot_display()
	_update_preview()
	
	# Connect button signals
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
		print("BuildScreen: Back button connected")
	else:
		push_warning("BuildScreen: back_btn is null!")
	
	if test_btn:
		test_btn.pressed.connect(_on_test_pressed)
		print("BuildScreen: Test button connected")
	else:
		push_warning("BuildScreen: test_btn is null!")
	
	# Debug: Print button states
	call_deferred("_debug_button_states")
	
	# Connect new action buttons
	if mount_button and not mount_button.pressed.is_connected(_on_mount_pressed):
		mount_button.pressed.connect(_on_mount_pressed)
	if unmount_button and not unmount_button.pressed.is_connected(_on_unmount_pressed):
		unmount_button.pressed.connect(_on_unmount_pressed)
	if enable_button and not enable_button.pressed.is_connected(_on_enable_pressed):
		enable_button.pressed.connect(_on_enable_pressed)
	if disable_button and not disable_button.pressed.is_connected(_on_disable_pressed):
		disable_button.pressed.connect(_on_disable_pressed)
	if team_color_picker and not team_color_picker.color_changed.is_connected(_on_color_changed):
		team_color_picker.color_changed.connect(_on_color_changed)
	if inventory_filter and not inventory_filter.item_selected.is_connected(_on_inventory_filter_changed):
		inventory_filter.item_selected.connect(_on_inventory_filter_changed)
	
	print("BuildScreen: Ready")

func _setup_mouse_filters() -> void:
	## Defensive: Ensure proper mouse_filter settings to prevent input blocking
	
	# Root should pass input to children
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Parent containers should pass input
	var margin = $MarginContainer
	var grid = $MarginContainer/MainGrid
	var bottom = $MarginContainer/MainGrid/BottomBar
	
	if margin:
		margin.mouse_filter = Control.MOUSE_FILTER_PASS
	if grid:
		grid.mouse_filter = Control.MOUSE_FILTER_PASS
	if bottom:
		bottom.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Labels should not block input
	if weight_label:
		weight_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if credits_label:
		credits_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if item_name_label:
		item_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if item_stats_label:
		item_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if item_description_label:
		item_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if manufacturer_label:
		manufacturer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if preview_label:
		preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dps_label:
		dps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Buttons should capture input
	if back_btn:
		back_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		back_btn.focus_mode = Control.FOCUS_ALL
	if test_btn:
		test_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		test_btn.focus_mode = Control.FOCUS_ALL
	if action_button:
		action_button.mouse_filter = Control.MOUSE_FILTER_STOP
		action_button.focus_mode = Control.FOCUS_ALL
	if mount_button:
		mount_button.mouse_filter = Control.MOUSE_FILTER_STOP
		mount_button.focus_mode = Control.FOCUS_ALL
	if unmount_button:
		unmount_button.mouse_filter = Control.MOUSE_FILTER_STOP
		unmount_button.focus_mode = Control.FOCUS_ALL
	if enable_button:
		enable_button.mouse_filter = Control.MOUSE_FILTER_STOP
		enable_button.focus_mode = Control.FOCUS_ALL
	if disable_button:
		disable_button.mouse_filter = Control.MOUSE_FILTER_STOP
		disable_button.focus_mode = Control.FOCUS_ALL
	
	# LineEdit should only focus on click
	if bot_name_edit:
		bot_name_edit.focus_mode = Control.FOCUS_CLICK
	
	print("BuildScreen: Mouse filters configured")

func on_show() -> void:
	# Called when screen becomes visible
	_load_inventory()
	_load_my_bots()
	_update_bot_display()
	visible = true

func on_hide() -> void:
	# Called when screen is hidden
	visible = false

func _on_back_pressed() -> void:
	print("BuildScreen: Back pressed")
	back_pressed.emit()

func _on_test_pressed() -> void:
	print("BuildScreen: Test battle pressed")
	# Save current bot before battle
	_save_current_bot()
	test_battle_pressed.emit()

func _debug_button_states() -> void:
	print("=== BuildScreen Button States ===")
	if back_btn:
		print("BackBtn: visible=", back_btn.visible, ", mouse_filter=", back_btn.mouse_filter, ", global_rect=", back_btn.get_global_rect())
	else:
		print("BackBtn: NULL")
	
	if test_btn:
		print("TestBtn: visible=", test_btn.visible, ", mouse_filter=", test_btn.mouse_filter, ", global_rect=", test_btn.get_global_rect())
	else:
		print("TestBtn: NULL")
	
	var margin = $MarginContainer
	var grid = $MarginContainer/MainGrid
	var bottom = $MarginContainer/MainGrid/BottomBar
	
	print("MarginContainer mouse_filter: ", margin.mouse_filter)
	print("MainGrid mouse_filter: ", grid.mouse_filter)
	print("BottomBar mouse_filter: ", bottom.mouse_filter)
	print("=================================")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("BuildScreen: Mouse click at ", event.position)
		if back_btn:
			print("  BackBtn rect: ", back_btn.get_global_rect(), ", contains: ", back_btn.get_global_rect().has_point(event.position))
		if test_btn:
			print("  TestBtn rect: ", test_btn.get_global_rect(), ", contains: ", test_btn.get_global_rect().has_point(event.position))

func _setup_shop_buttons() -> void:
	for child in shop_buttons.get_children():
		child.queue_free()
	
	for category in ["Chassis", "Armor", "Weapon/Heal"]:
		var btn: Button = Button.new()
		btn.text = category
		btn.pressed.connect(_on_shop_category.bind(category.to_lower().replace("/", "_")))
		shop_buttons.add_child(btn)

func _on_shop_category(category: String) -> void:
	selected_shop_category = category
	_load_shop()

func _load_shop() -> void:
	shop_list.clear()
	if not DataLoader or selected_shop_category.is_empty():
		return
	
	for part in DataLoader.get_all_parts():
		if not part is Dictionary:
			continue
		
		var part_cat: String = part.get("category", "")
		var match_cat: bool = false
		
		match selected_shop_category:
			"chassis":
				match_cat = (part_cat == "chassis")
			"armor":
				match_cat = (part_cat == "armor")
			"weapon_heal":
				match_cat = (part_cat == "weapon" or part_cat == "utility")
		
		if match_cat:
			var part_name: String = part.get("name", "Unknown")
			var cost: int = part.get("cost", 0)
			
			var display: String
			if GameState.is_arcade_mode():
				display = part_name + " - FREE"
			else:
				display = part_name + " - " + str(cost) + " CR"
			
			shop_list.add_item(display)
			shop_list.set_item_metadata(shop_list.get_item_count() - 1, part)

func _load_inventory() -> void:
	inventory_list.clear()
	if not DataLoader:
		return
	
	for part_id in GameState.owned_parts:
		var qty: int = GameState.owned_parts[part_id]
		if qty <= 0:
			continue
		
		var part: Dictionary = DataLoader.get_part(part_id)
		if part.is_empty():
			continue
		
		var part_name: String = part.get("name", "Unknown")
		inventory_list.add_item(part_name + " [" + str(qty) + "]")
		inventory_list.set_item_metadata(inventory_list.get_item_count() - 1, part)

func _load_my_bots() -> void:
	my_bots_list.clear()
	for loadout in GameState.loadouts:
		my_bots_list.add_item(loadout.get("name", "Unnamed"))
		my_bots_list.set_item_metadata(my_bots_list.get_item_count() - 1, loadout)

func _on_shop_selected(index: int) -> void:
	selected_part = shop_list.get_item_metadata(index)
	_update_preview()
	action_button.text = "Purchase"
	action_button.visible = not GameState.is_arcade_mode()

func _on_inventory_selected(index: int) -> void:
	selected_part = inventory_list.get_item_metadata(index)
	_update_preview()
	action_button.text = "Equip"
	action_button.visible = true

func _on_my_bot_selected(index: int) -> void:
	var bot: Dictionary = my_bots_list.get_item_metadata(index)
	# Convert arrays to single strings if needed
	current_bot["id"] = bot.get("id", "bot_1")
	current_bot["name"] = bot.get("name", "Bot 1")
	current_bot["chassis"] = _get_single_part(bot, "chassis")
	current_bot["armor"] = _get_single_part(bot, "armor")
	current_bot["weapon"] = _get_single_part(bot, "weapon")
	
	bot_name_edit.text = current_bot["name"]
	_update_bot_display()

func _get_single_part(bot: Dictionary, slot: String) -> String:
	## Get a single part ID from bot, handling both array and string formats
	var value = bot.get(slot, "")
	if value is Array:
		return value[0] if value.size() > 0 else ""
	elif value is String:
		return value
	return ""

func _update_preview() -> void:
	if selected_part.is_empty():
		preview_label.text = "Select an item to view details"
		action_button.visible = false
		return
	
	var text: String = ""
	text += selected_part.get("name", "Unknown") + "\n"
	text += "Type: " + selected_part.get("category", "").capitalize() + "\n"
	text += "Weight: %.1f kg\n" % selected_part.get("weight", 0.0)
	text += "Cost: %d CR\n" % selected_part.get("cost", 0)
	
	var stats: Dictionary = selected_part.get("stats", {})
	for stat_name in stats:
		text += "%s: %s\n" % [stat_name, str(stats[stat_name])]
	
	preview_label.text = text

func _on_action_pressed() -> void:
	if selected_part.is_empty():
		return
	
	if action_button.text == "Purchase":
		# Buy from shop
		var cost: int = selected_part.get("cost", 0)
		
		# In arcade mode, everything is free
		if GameState.is_arcade_mode():
			cost = 0
		
		if GameState.spend_credits(cost):
			GameState.add_part(selected_part.get("id", ""))
			_load_inventory()
			_load_shop()
			_update_preview()
			
	elif action_button.text == "Equip":
		# Equip to current bot
		var category: String = selected_part.get("category", "")
		var part_id: String = selected_part.get("id", "")

		match category:
			"chassis":
				current_bot["chassis"] = part_id
			"armor":
				current_bot["armor"] = part_id
			"weapon", "utility":
				current_bot["weapon"] = part_id	# Weapon or heal gun
				# Update GameState loadout with selected weapon ID
				_sync_weapon_to_gamestate(part_id)

		_update_bot_display()

func _update_bot_display() -> void:
	var weight: float = 0.0
	var max_weight: float = 0.0
	
	# Build equipped display
	var equipped_text: String = "CURRENT BOT: " + current_bot["name"] + "\n\n"
	
	# Calculate weight and build display
	for slot in ["chassis", "armor", "weapon"]:
		var part_id: String = current_bot.get(slot, "")
		if not part_id.is_empty():
			var part: Dictionary = DataLoader.get_part(part_id)
			if not part.is_empty():
				weight += part.get("weight", 0.0)
				if slot == "chassis":
					max_weight = part.get("stats", {}).get("weight_capacity", 0.0)
				
				equipped_text += slot.capitalize() + ": " + part.get("name", "Unknown") + "\n"
				equipped_text += "	Weight: %.1f kg\n" % part.get("weight", 0.0)
				if slot == "armor":
					var hp: int = part.get("stats", {}).get("hp", 0)
					equipped_text += "	HP: %d\n" % hp
				elif slot == "weapon":
					var stats: Dictionary = part.get("stats", {})
					var dmg: float = stats.get("damage_per_shot", part.get("damage_per_shot", 0))
					var fr: float = stats.get("fire_rate", part.get("fire_rate", 1.0))
					var r_max: float = stats.get("range_max", part.get("range_max", 0))
					var r_opt: float = stats.get("range_optimal", part.get("range_optimal", 0))
					var dmg_type: String = str(stats.get("damage_type", part.get("damage_type", "")))
					var dps_val: float = absf(dmg) * fr
					equipped_text += "	DPS: %.1f | Damage: %.1f | Rate: %.1f/s\n" % [dps_val, dmg, fr]
					equipped_text += "	Range: %.0f-%.0f | Type: %s\n" % [r_opt, r_max, dmg_type.capitalize()]
				equipped_text += "\n"
		else:
			equipped_text += slot.capitalize() + ": [Empty]\n\n"
	
	# Update preview with equipped info
	preview_label.text = equipped_text
	
	var status: String = "Weight: %.1f / %.1f kg" % [weight, max_weight]
	if weight > max_weight:
		status += " [OVER!]"
	weight_label.text = status
	credits_label.text = "Credits: %d" % GameState.credits

	# Calculate total DPS from equipped weapon
	var total_dps: float = 0.0
	var weapon_id: String = current_bot.get("weapon", "")
	if not weapon_id.is_empty() and DataLoader:
		var wpn: Dictionary = DataLoader.get_weapon(weapon_id)
		if not wpn.is_empty():
			var s: Dictionary = wpn.get("stats", wpn)
			var d: float = float(s.get("damage_per_shot", 0))
			var r: float = float(s.get("fire_rate", 1.0))
			total_dps = absf(d) * r
	if dps_label:
		dps_label.text = "DPS: %.1f" % total_dps


func _save_current_bot() -> void:
	## Save current bot configuration to GameState
	GameState.save_loadout(current_bot)


func _load_saved_bots() -> void:
	## Load saved bot configurations
	if GameState.loadouts.size() > 0:
		current_bot = GameState.loadouts[0].duplicate()


# New 5-box grid button handlers
func _on_mount_pressed() -> void:
	print("BuildScreen: Mount pressed")
	# TODO: Implement mount functionality

func _on_unmount_pressed() -> void:
	print("BuildScreen: Unmount pressed")
	# TODO: Implement unmount functionality

func _on_enable_pressed() -> void:
	print("BuildScreen: Enable pressed")
	# TODO: Implement enable functionality

func _on_disable_pressed() -> void:
	print("BuildScreen: Disable pressed")
	# TODO: Implement disable functionality

func _on_color_changed(color: Color) -> void:
	print("BuildScreen: Color changed to ", color)
	# TODO: Implement team color change

func _on_inventory_filter_changed(index: int) -> void:
	print("BuildScreen: Inventory filter changed to ", index)
	_load_inventory()


func _sync_weapon_to_gamestate(weapon_id: String) -> void:
	## Update the active loadout in GameState with the selected weapon ID.
	if not GameState:
		return
	var loadout_id: String = current_bot.get("id", "")
	if loadout_id.is_empty():
		return
	var loadout: Dictionary = GameState.get_loadout(loadout_id)
	if loadout.is_empty():
		return
	# Update weapons array in loadout
	loadout["weapons"] = [weapon_id]
	GameState.add_loadout(loadout)
