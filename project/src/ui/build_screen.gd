extends Control
## BuildScreen - Bot Arena 3 style with Shop, Inventory, My Bots
## REBUILT: Using UIButton for proper hit detection

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

# References to scene nodes
@onready var shop_buttons: HBoxContainer = $MarginContainer/VBox/TopRow/ShopPanel/ShopButtons
@onready var shop_list: ItemList = $MarginContainer/VBox/TopRow/ShopPanel/ShopList
@onready var inventory_list: ItemList = $MarginContainer/VBox/TopRow/InventoryPanel/InventoryList
@onready var my_bots_list: ItemList = $MarginContainer/VBox/TopRow/MyBotsPanel/MyBotsList
@onready var preview_label: Label = $MarginContainer/VBox/PreviewPanel/PreviewLabel
@onready var bot_name_edit: LineEdit = $MarginContainer/VBox/TopRow/MyBotsPanel/BotNameEdit
@onready var weight_label: Label = $MarginContainer/VBox/PreviewPanel/WeightLabel
@onready var credits_label: Label = $MarginContainer/VBox/PreviewPanel/CreditsLabel

# UIButton references (created programmatically)
var test_btn: UIButton
var back_btn: UIButton
var action_button: UIButton

const UIButton = preload("res://src/ui/components/UIButton.gd")

func _ready() -> void:
	print("BuildScreen: _ready started")
	
	# Setup mouse filters on containers
	_setup_container_filters()
	
	# Create UIButtons
	_create_action_buttons()
	_create_shop_buttons()
	
	# Load data
	_load_inventory()
	_load_my_bots()
	_update_bot_display()
	_update_preview()
	
	print("BuildScreen: _ready complete")

func _setup_container_filters() -> void:
	## Set all containers to PASS, labels to IGNORE

	# ROOT NODE — must be PASS, not default STOP!
	self.mouse_filter = Control.MOUSE_FILTER_PASS

	# Background
	$Background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# All containers PASS
	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/ShopPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/ShopPanel/ShopButtons.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/InventoryPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/MyBotsPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/PreviewPanel.mouse_filter = Control.MOUSE_FILTER_PASS

	# BottomBar — holds Test Battle + Back buttons, MUST be PASS
	$MarginContainer/VBox/BottomBar.mouse_filter = Control.MOUSE_FILTER_PASS

	# Labels IGNORE
	$MarginContainer/VBox/TopRow/ShopPanel/Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer/VBox/TopRow/InventoryPanel/Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer/VBox/TopRow/MyBotsPanel/Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# ItemLists PASS
	shop_list.mouse_filter = Control.MOUSE_FILTER_PASS
	inventory_list.mouse_filter = Control.MOUSE_FILTER_PASS
	my_bots_list.mouse_filter = Control.MOUSE_FILTER_PASS

func _create_action_buttons() -> void:
	## Create Test Battle and Back UIButtons
	
	var bottom_bar: HBoxContainer = $MarginContainer/VBox/BottomBar
	
	# Clear any old buttons
	for child in bottom_bar.get_children():
		child.queue_free()
	
	# Create Test Battle button
	test_btn = UIButton.new()
	test_btn.text = "Test Battle"
	test_btn.button_style = UIButton.ButtonStyle.SECONDARY
	test_btn.custom_minimum_size = Vector2(120, 40)
	test_btn.size = Vector2(120, 40)
	test_btn.pressed.connect(_on_test_pressed)
	bottom_bar.add_child(test_btn)
	print("BuildScreen: Created Test Battle UIButton")
	
	# Spacer
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_bar.add_child(spacer)
	
	# Create Back button
	back_btn = UIButton.new()
	back_btn.text = "Back"
	back_btn.button_style = UIButton.ButtonStyle.GHOST
	back_btn.custom_minimum_size = Vector2(80, 40)
	back_btn.size = Vector2(80, 40)
	back_btn.pressed.connect(_on_back_pressed)
	bottom_bar.add_child(back_btn)
	print("BuildScreen: Created Back UIButton")

func _create_shop_buttons() -> void:
	## Create shop category buttons using UIButton
	
	var categories := ["Chassis", "Armor", "Weapon/Heal"]
	for category in categories:
		var btn: UIButton = UIButton.new()
		btn.text = category
		btn.button_style = UIButton.ButtonStyle.GHOST
		btn.custom_minimum_size = Vector2(80, 32)
		btn.pressed.connect(_on_shop_category_selected.bind(category))
		shop_buttons.add_child(btn)
		print("BuildScreen: Created shop button: ", category)
	
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
		return
	
	var description: String = selected_part.get("description", "No description")
	var stats: Dictionary = selected_part.get("stats", {})
	
	var stats_text: String = ""
	for stat_name in stats:
		stats_text += "\n%s: %s" % [stat_name.capitalize(), str(stats[stat_name])]
	
	preview_label.text = "%s\n%s" % [description, stats_text]

func _on_test_pressed() -> void:
	print("BuildScreen: Test Battle pressed!")
	GameState.save_build(current_bot)
	test_battle_pressed.emit()

func _on_back_pressed() -> void:
	print("BuildScreen: Back pressed!")
	GameState.save_build(current_bot)
	back_pressed.emit()

func on_show() -> void:
	_update_bot_display()
	_load_inventory()
