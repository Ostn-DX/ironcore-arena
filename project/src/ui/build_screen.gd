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

	# Wait one frame for layout to resolve, then verify buttons
	await get_tree().process_frame
	_verify_buttons()

	print("BuildScreen: _ready complete")

func _setup_container_filters() -> void:
	## Set all containers to PASS so clicks propagate to children.
	## Labels/decorative nodes to IGNORE so they don't eat clicks.

	# ROOT NODE — must be PASS, not default STOP!
	self.mouse_filter = Control.MOUSE_FILTER_PASS

	# Background — purely visual
	$Background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# All layout containers PASS (let clicks reach children)
	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/ShopPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/ShopPanel/ShopButtons.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/InventoryPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	$MarginContainer/VBox/TopRow/MyBotsPanel.mouse_filter = Control.MOUSE_FILTER_PASS

	# PreviewPanel — display only, no interactive children
	$MarginContainer/VBox/PreviewPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# BottomBar — holds Test Battle + Back buttons, MUST be PASS
	$MarginContainer/VBox/BottomBar.mouse_filter = Control.MOUSE_FILTER_PASS

	# ALL labels IGNORE (they default to STOP which eats clicks!)
	$MarginContainer/VBox/TopRow/ShopPanel/Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer/VBox/TopRow/InventoryPanel/Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer/VBox/TopRow/MyBotsPanel/Title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weight_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ItemLists — interactive controls, keep at STOP (default)
	# Do NOT set to PASS — they need STOP to handle their own item selection
	# shop_list, inventory_list, my_bots_list all default to STOP which is correct

	# BotNameEdit — interactive, keep at STOP (default) but don't let it steal focus
	bot_name_edit.focus_mode = Control.FOCUS_CLICK

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
	# Explicitly set these — match the working main menu pattern
	test_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	test_btn.focus_mode = Control.FOCUS_ALL
	test_btn.pressed.connect(_on_test_pressed)
	bottom_bar.add_child(test_btn)
	print("BuildScreen: Created Test Battle UIButton, mouse_filter=", test_btn.mouse_filter)

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
	# Explicitly set these — match the working main menu pattern
	back_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	back_btn.focus_mode = Control.FOCUS_ALL
	back_btn.pressed.connect(_on_back_pressed)
	bottom_bar.add_child(back_btn)
	print("BuildScreen: Created Back UIButton, mouse_filter=", back_btn.mouse_filter)

func _create_shop_buttons() -> void:
	## Create shop category buttons using UIButton

	var categories := ["Chassis", "Armor", "Weapon/Heal"]
	for category in categories:
		var btn: UIButton = UIButton.new()
		btn.text = category
		btn.button_style = UIButton.ButtonStyle.GHOST
		btn.custom_minimum_size = Vector2(80, 32)
		# Explicitly set these for every button
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_shop_category_selected.bind(category))
		shop_buttons.add_child(btn)
		print("BuildScreen: Created shop button: ", category)

	# Show all by default
	_show_shop_category("Chassis")

func _verify_buttons() -> void:
	## Debug: verify button state after layout resolves
	print("=== BuildScreen Button Verification ===")

	var bottom_bar: HBoxContainer = $MarginContainer/VBox/BottomBar
	print("  BottomBar: rect=", bottom_bar.get_global_rect(), " mouse_filter=", bottom_bar.mouse_filter)

	if test_btn and is_instance_valid(test_btn):
		print("  Test Battle: rect=", test_btn.get_global_rect(),
			" size=", test_btn.size,
			" mouse_filter=", test_btn.mouse_filter,
			" focus_mode=", test_btn.focus_mode,
			" visible=", test_btn.visible,
			" disabled=", test_btn.disabled)
	else:
		print("  ERROR: test_btn is null or invalid!")

	if back_btn and is_instance_valid(back_btn):
		print("  Back: rect=", back_btn.get_global_rect(),
			" size=", back_btn.size,
			" mouse_filter=", back_btn.mouse_filter,
			" focus_mode=", back_btn.focus_mode,
			" visible=", back_btn.visible,
			" disabled=", back_btn.disabled)
	else:
		print("  ERROR: back_btn is null or invalid!")

	# Check the full chain from root to buttons
	print("  Self: rect=", get_global_rect(), " mouse_filter=", mouse_filter)
	print("  MarginContainer: rect=", $MarginContainer.get_global_rect(), " mouse_filter=", $MarginContainer.mouse_filter)
	print("  VBox: rect=", $MarginContainer/VBox.get_global_rect(), " mouse_filter=", $MarginContainer/VBox.mouse_filter)
	print("=== End Verification ===")

func _gui_input(event: InputEvent) -> void:
	## Debug: detect if mouse events reach BuildScreen root
	if event is InputEventMouseButton and event.pressed:
		print("[BuildScreen._gui_input] Mouse click at ", event.position, " button=", event.button_index)

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
