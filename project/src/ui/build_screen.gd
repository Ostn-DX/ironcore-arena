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
	
	# CRITICAL FIX: Set all containers to PASS mouse input
	_setup_mouse_filters()
	
	print("BuildScreen: Ready - Mouse filters configured")
	
	# DEBUG: Check if signals are connected
	print("BuildScreen: Test Battle signal connected: ", test_btn.pressed.is_connected(_on_test_pressed))
	print("BuildScreen: Back signal connected: ", back_btn.pressed.is_connected(_on_back_pressed))
	
	# Ensure buttons can receive focus
	test_btn.focus_mode = Control.FOCUS_ALL
	back_btn.focus_mode = Control.FOCUS_ALL
	
	# LAST RESORT: Replace buttons with fresh ones
	call_deferred("_replace_broken_buttons")

func _setup_mouse_filters() -> void:
	## Fix mouse filters for entire UI hierarchy
	
	# Root and background
	mouse_filter = Control.MOUSE_FILTER_PASS
	$Background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# All containers should PASS
	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/ShopPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/ShopPanel/ShopButtons.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/InventoryPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/MyBotsPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Preview panel - critical fix
	$MarginContainer/VBox/PreviewPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Bottom bar
	$MarginContainer/VBox/BottomBar.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# All buttons must STOP to capture input
	test_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	back_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	action_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# ItemLists should PASS (not steal button clicks)
	shop_list.mouse_filter = Control.MOUSE_FILTER_PASS
	inventory_list.mouse_filter = Control.MOUSE_FILTER_PASS
	my_bots_list.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Labels should IGNORE
	$MarginContainer/VBox/TopRow/ShopPanel/Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer/VBox/TopRow/InventoryPanel/Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer/VBox/TopRow/MyBotsPanel/Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weight_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _replace_broken_buttons() -> void:
	## Replace scene buttons with programmatically created ones
	print("BuildScreen: Replacing broken buttons...")
	
	# Get parent container
	var bottom_bar = $MarginContainer/VBox/BottomBar
	
	# Hide old buttons instead of removing
	if test_btn:
		test_btn.visible = false
	if back_btn:
		back_btn.visible = false
	
	# Create new Test Battle button
	var new_test_btn: Button = Button.new()
	new_test_btn.text = "Test Battle"
	new_test_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	new_test_btn.focus_mode = Control.FOCUS_ALL
	new_test_btn.pressed.connect(_on_test_pressed)
	new_test_btn.top_level = true  # Don't be affected by parent transforms/filters
	new_test_btn.position = Vector2(580, 680)  # Absolute position
	add_child(new_test_btn)
	
	# Create new Back button
	var new_back_btn: Button = Button.new()
	new_back_btn.text = "Back"
	new_back_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	new_back_btn.focus_mode = Control.FOCUS_ALL
	new_back_btn.pressed.connect(_on_back_pressed)
	new_back_btn.top_level = true
	new_back_btn.position = Vector2(680, 680)
	add_child(new_back_btn)
	
	print("BuildScreen: Buttons replaced successfully at positions ", new_test_btn.position, " and ", new_back_btn.position)

func _setup_shop_buttons() -> void:
	var categories := ["Chassis", "Armor", "Weapon/Heal"]
	for category in categories:
		var btn: Button = Button.new()
		btn.text = category
		btn.pressed.connect(_on_shop_category_selected.bind(category))
		btn.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure shop buttons work too
		shop_buttons.add_child(btn)
	
	# Show all by default
	_show_shop_category("Chassis")

func _on_shop_category_selected(category: String) -> void:
	selected_shop_category = category
	_show_shop_category(category)

func _show_shop_category(category: String) -> void:
	shop_list.clear()
	
	var parts: Array = DataLoader.get_parts_by_category(category)
	for part in parts:
		var price: int = part.get("price", 0)
		var display_text: String = "%s (%d CR)" % [part.name, price]
		shop_list.add_item(display_text)
		shop_list.set_item_metadata(shop_list.get_item_count() - 1, part)

func _on_shop_selected(index: int) -> void:
	selected_part = shop_list.get_item_metadata(index)
	_update_preview()

func _on_inventory_selected(index: int) -> void:
	var part: Dictionary = inventory_list.get_item_metadata(index)
	selected_part = part
	_update_preview()

func _on_my_bot_selected(index: int) -> void:
	pass  # TODO: Load bot config

func _on_name_changed(new_text: String) -> void:
	current_bot.name = new_text

func _on_action_pressed() -> void:
	if selected_part.is_empty():
		return
	
	if action_button.text == "Purchase":
		var price: int = selected_part.get("price", 0)
		if GameState.spend_credits(price):
			GameState.add_part_to_inventory(selected_part.id)
			_load_inventory()
			_update_preview()
	elif action_button.text == "Equip":
		var slot: String = selected_part.get("slot", "")
		if not slot.is_empty():
			current_bot[slot] = selected_part.id
			_update_bot_display()
			_update_preview()

func _load_inventory() -> void:
	inventory_list.clear()
	
	for part_id in GameState.inventory:
		var part: Dictionary = DataLoader.get_part(part_id)
		if not part.is_empty():
			inventory_list.add_item(part.name)
			inventory_list.set_item_metadata(inventory_list.get_item_count() - 1, part)

func _load_my_bots() -> void:
	my_bots_list.clear()
	
	for bot_id in GameState.my_bots:
		var bot: Dictionary = GameState.my_bots[bot_id]
		my_bots_list.add_item(bot.get("name", "Unnamed Bot"))
		my_bots_list.set_item_metadata(my_bots_list.get_item_count() - 1, bot)

func _update_bot_display() -> void:
	var chassis: Dictionary = DataLoader.get_part(current_bot.chassis)
	var armor: Dictionary = DataLoader.get_part(current_bot.armor)
	var weapon: Dictionary = DataLoader.get_part(current_bot.weapon)
	
	var total_weight: float = chassis.get("weight", 0.0) + armor.get("weight", 0.0) + weapon.get("weight", 0.0)
	var max_weight: float = chassis.get("max_weight", 100.0)
	
	weight_label.text = "Weight: %.1f / %.1f kg" % [total_weight, max_weight]
	credits_label.text = "Credits: %d" % GameState.credits
	bot_name_edit.text = current_bot.name

func _update_preview() -> void:
	if selected_part.is_empty():
		preview_label.text = "Select an item"
		action_button.visible = false
		return
	
	var description: String = selected_part.get("description", "No description")
	var stats: Dictionary = selected_part.get("stats", {})
	
	var stats_text: String = ""
	for stat_name in stats:
		stats_text += "\n%s: %s" % [stat_name.capitalize(), str(stats[stat_name])]
	
	preview_label.text = "%s\n%s" % [description, stats_text]
	
	# Determine action button state
	var is_owned: bool = selected_part.id in GameState.inventory
	var can_afford: bool = GameState.credits >= selected_part.get("price", 0)
	
	if is_owned:
		action_button.text = "Equip"
		action_button.visible = true
		action_button.disabled = false
	elif can_afford:
		action_button.text = "Purchase"
		action_button.visible = true
		action_button.disabled = false
	else:
		action_button.text = "Can't Afford"
		action_button.visible = true
		action_button.disabled = true

func _on_test_pressed() -> void:
	print("BuildScreen: Test Battle pressed!")
	GameState.save_build(current_bot)
	test_battle_pressed.emit()

func _on_back_pressed() -> void:
	print("BuildScreen: Back pressed!")
	GameState.save_build(current_bot)
	back_pressed.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("BuildScreen _gui_input: button=", event.button_index, " pressed=", event.pressed, " pos=", event.position)

func on_show() -> void:
	_update_bot_display()
	_load_inventory()
