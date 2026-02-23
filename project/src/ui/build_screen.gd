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

@onready var shop_buttons: HBoxContainer = $MarginContainer/VBox/TopRow/ShopPanel/ShopButtons
@onready var shop_list: ItemList = $MarginContainer/VBox/TopRow/ShopPanel/ShopList
@onready var inventory_list: ItemList = $MarginContainer/VBox/TopRow/InventoryPanel/InventoryList
@onready var my_bots_list: ItemList = $MarginContainer/VBox/TopRow/MyBotsPanel/MyBotsList
@onready var preview_label: Label = $MarginContainer/VBox/PreviewPanel/PreviewLabel
@onready var action_button: Button = $MarginContainer/VBox/PreviewPanel/ActionButton
@onready var bot_name_edit: LineEdit = $MarginContainer/VBox/TopRow/MyBotsPanel/BotNameEdit
@onready var weight_label: Label = $MarginContainer/VBox/BottomBar/WeightLabel
@onready var credits_label: Label = $MarginContainer/VBox/BottomBar/CreditsLabel
@onready var test_btn: Button = $MarginContainer/VBox/BottomBar/TestBtn
@onready var back_btn: Button = $MarginContainer/VBox/BottomBar/BackBtn

func _ready() -> void:
	_setup_shop_buttons()
	_load_inventory()
	_load_my_bots()
	_update_bot_display()
	_update_preview()
	
	# Connect button signals
	back_btn.pressed.connect(_on_back_pressed)
	test_btn.pressed.connect(_on_test_pressed)
	
	print("BuildScreen: Ready")

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
				current_bot["weapon"] = part_id  # Weapon or heal gun
		
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
				equipped_text += "  Weight: %.1f kg\n" % part.get("weight", 0.0)
				if slot == "armor":
					var hp: int = part.get("stats", {}).get("hp", 0)
					equipped_text += "  HP: %d\n" % hp
				elif slot == "weapon":
					var stats: Dictionary = part.get("stats", {})
					var dmg: float = stats.get("damage_per_shot", 0)
					var range_max: float = stats.get("range_max", 0)
					equipped_text += "  Damage: %.1f, Range: %.0f\n" % [dmg, range_max]
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


func _save_current_bot() -> void:
	## Save current bot configuration to GameState
	GameState.save_loadout(current_bot)


func _load_saved_bots() -> void:
	## Load saved bot configurations
	if GameState.loadouts.size() > 0:
		current_bot = GameState.loadouts[0].duplicate()
