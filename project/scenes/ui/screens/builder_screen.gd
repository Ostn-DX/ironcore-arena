class_name BuilderScreen
extends Control

## Builder Screen - 5-box grid for bot assembly
## Bible B1.3: All signal connections use safe patterns
## Bible B3: Resource caching with preload

signal back_pressed
signal deploy_pressed
signal item_selected(item_id: String)
signal bot_selected(bot_index: int)

# Bible B3: Preload constants
const BOT_SLOT_SCENE: PackedScene = preload("res://scenes/ui/components/bot_slot.tscn")

# UI References - Bible B1.2: @onready caching
@onready var _back_button: Button = %BackButton
@onready var _deploy_button: Button = %DeployButton

# Box 1: Shop
@onready var _shop_panel: PanelContainer = %ShopPanel
@onready var _shop_list: ItemList = %ShopList
@onready var _shop_category_dropdown: OptionButton = %ShopCategoryDropdown

# Box 2: Inventory
@onready var _inventory_panel: PanelContainer = %InventoryPanel
@onready var _inventory_filter: OptionButton = %InventoryFilter
@onready var _inventory_list: ItemList = %InventoryList

# Box 3: Player Bots
@onready var _bots_panel: PanelContainer = %BotsPanel
@onready var _bots_container: VBoxContainer = %BotsContainer

# Box 4: Item Description
@onready var _description_panel: PanelContainer = %DescriptionPanel
@onready var _item_icon: TextureRect = %ItemIcon
@onready var _item_name_label: Label = %ItemNameLabel
@onready var _item_stats_label: Label = %ItemStatsLabel
@onready var _item_description_label: Label = %ItemDescriptionLabel
@onready var _manufacturer_label: Label = %ManufacturerLabel

# Box 5: Actions
@onready var _actions_panel: PanelContainer = %ActionsPanel
@onready var _mount_button: Button = %MountButton
@onready var _unmount_button: Button = %UnmountButton
@onready var _enable_button: Button = %EnableButton
@onready var _disable_button: Button = %DisableButton
@onready var _team_color_picker: ColorPickerButton = %TeamColorPicker
@onready var _weight_label: Label = %WeightLabel
@onready var _dps_label: Label = %DPSLabel

# State - Bible 4.1: Typed variables
var _selected_inventory_item: String = ""
var _selected_bot_index: int = -1
var _selected_bot_slot = null
var _bot_slots: Array = []

func _ready() -> void:
	_setup_button_signals()
	_setup_filter_dropdowns()
	_populate_shop()
	_populate_inventory()
	_populate_bots()
	_update_action_buttons()

func _setup_button_signals() -> void:
	## Bible B1.3: Safe signal connections
	if _back_button and is_instance_valid(_back_button):
		if not _back_button.pressed.is_connected(_on_back_pressed):
			_back_button.pressed.connect(_on_back_pressed)
	
	if _deploy_button and is_instance_valid(_deploy_button):
		if not _deploy_button.pressed.is_connected(_on_deploy_pressed):
			_deploy_button.pressed.connect(_on_deploy_pressed)
	
	if _mount_button and is_instance_valid(_mount_button):
		if not _mount_button.pressed.is_connected(_on_mount_pressed):
			_mount_button.pressed.connect(_on_mount_pressed)
	
	if _unmount_button and is_instance_valid(_unmount_button):
		if not _unmount_button.pressed.is_connected(_on_unmount_pressed):
			_unmount_button.pressed.connect(_on_unmount_pressed)
	
	if _enable_button and is_instance_valid(_enable_button):
		if not _enable_button.pressed.is_connected(_on_enable_pressed):
			_enable_button.pressed.connect(_on_enable_pressed)
	
	if _disable_button and is_instance_valid(_disable_button):
		if not _disable_button.pressed.is_connected(_on_disable_pressed):
			_disable_button.pressed.connect(_on_disable_pressed)
	
	if _inventory_filter and is_instance_valid(_inventory_filter):
		if not _inventory_filter.item_selected.is_connected(_on_inventory_filter_changed):
			_inventory_filter.item_selected.connect(_on_inventory_filter_changed)
	
	if _shop_category_dropdown and is_instance_valid(_shop_category_dropdown):
		if not _shop_category_dropdown.item_selected.is_connected(_on_shop_category_changed):
			_shop_category_dropdown.item_selected.connect(_on_shop_category_changed)
	
	if _inventory_list and is_instance_valid(_inventory_list):
		if not _inventory_list.item_selected.is_connected(_on_inventory_item_selected):
			_inventory_list.item_selected.connect(_on_inventory_item_selected)
	
	if _team_color_picker and is_instance_valid(_team_color_picker):
		if not _team_color_picker.color_changed.is_connected(_on_team_color_changed):
			_team_color_picker.color_changed.connect(_on_team_color_changed)

func _setup_filter_dropdowns() -> void:
	## Setup inventory filter dropdown
	if _inventory_filter and is_instance_valid(_inventory_filter):
		_inventory_filter.clear()
		_inventory_filter.add_item("All")
		_inventory_filter.add_item("Chassis")
		_inventory_filter.add_item("Weapons")
		_inventory_filter.add_item("Armor")
		_inventory_filter.select(0)
	
	## Setup shop category dropdown
	if _shop_category_dropdown and is_instance_valid(_shop_category_dropdown):
		_shop_category_dropdown.clear()
		_shop_category_dropdown.add_item("All")
		_shop_category_dropdown.add_item("Chassis")
		_shop_category_dropdown.add_item("Weapons")
		_shop_category_dropdown.add_item("Armor")
		_shop_category_dropdown.select(0)

func _populate_shop() -> void:
	if not _shop_list or not is_instance_valid(_shop_list):
		return
	
	_shop_list.clear()
	
	## Bible: Check DataLoader exists
	if not DataLoader or not is_instance_valid(DataLoader):
		return
	
	var parts: Dictionary = DataLoader.get_all_parts()
	for part_id in parts:
		var part: Dictionary = parts[part_id]
		_shop_list.add_item(part.get("name", part_id))
		_shop_list.set_item_metadata(_shop_list.item_count - 1, part_id)

func _populate_inventory() -> void:
	if not _inventory_list or not is_instance_valid(_inventory_list):
		return
	
	_inventory_list.clear()
	
	## Bible: Check GameState exists
	if not GameState or not is_instance_valid(GameState):
		return
	
	var filter_type: String = _get_selected_filter_type()
	
	for part_id in GameState.owned_parts:
		var quantity: int = GameState.owned_parts[part_id]
		if quantity > 0:
			## Apply filter
			if filter_type != "All":
				var part_type: String = _get_part_type(part_id)
				if part_type != filter_type:
					continue
			
			_inventory_list.add_item("%s (x%d)" % [part_id, quantity])
			_inventory_list.set_item_metadata(_inventory_list.item_count - 1, part_id)

func _populate_bots() -> void:
	## Clear existing slots
	for slot in _bot_slots:
		if slot and is_instance_valid(slot):
			slot.queue_free()
	_bot_slots.clear()
	
	## Bible: Check GameState
	if not GameState or not is_instance_valid(GameState):
		return
	
	## Create slots for each loadout
	for i in range(5):  # Max 5 bots
		var slot = BOT_SLOT_SCENE.instantiate()
		slot.slot_index = i
		
		## Bible B1.3: Safe signal connection
		if not slot.selected.is_connected(_on_bot_slot_selected.bind(i)):
			slot.selected.connect(_on_bot_slot_selected.bind(i))
		if not slot.name_changed.is_connected(_on_bot_name_changed.bind(i)):
			slot.name_changed.connect(_on_bot_name_changed.bind(i))
		
		_bots_container.add_child(slot)
		_bot_slots.append(slot)
		
		## Load bot data if exists
		if i < GameState.loadouts.size():
			var loadout: Dictionary = GameState.loadouts[i]
			slot.set_loadout(loadout)
			slot.set_enabled(true)
		else:
			slot.set_enabled(false)

func _get_selected_filter_type() -> String:
	if _inventory_filter and is_instance_valid(_inventory_filter):
		var index: int = _inventory_filter.selected
		return _inventory_filter.get_item_text(index)
	return "All"

func _get_part_type(part_id: String) -> String:
	if not DataLoader or not is_instance_valid(DataLoader):
		return "Unknown"
	
	var part: Dictionary = DataLoader.get_part_data(part_id)
	return part.get("type", "Unknown")

func _on_inventory_filter_changed(_index: int) -> void:
	_populate_inventory()

func _on_shop_category_changed(_index: int) -> void:
	_populate_shop()

func _on_inventory_item_selected(index: int) -> void:
	if _inventory_list and is_instance_valid(_inventory_list):
		_selected_inventory_item = _inventory_list.get_item_metadata(index)
		_update_item_description(_selected_inventory_item)
		_update_action_buttons()

func _on_bot_slot_selected(index: int) -> void:
	_selected_bot_index = index
	_selected_bot_slot = _bot_slots[index] if index >= 0 and index < _bot_slots.size() else null
	_update_action_buttons()
	_update_bot_stats()

func _on_bot_name_changed(index: int, new_name: String) -> void:
	## Bible: Check GameState exists
	if GameState and is_instance_valid(GameState):
		if index < GameState.loadouts.size():
			GameState.loadouts[index]["name"] = new_name
			GameState.save_game()

func _update_item_description(item_id: String) -> void:
	if not DataLoader or not is_instance_valid(DataLoader):
		return
	
	var part: Dictionary = DataLoader.get_part_data(item_id)
	
	if _item_name_label and is_instance_valid(_item_name_label):
		_item_name_label.text = part.get("name", item_id)
	
	if _item_stats_label and is_instance_valid(_item_stats_label):
		var stats: String = ""
		if part.has("damage"):
			stats += "Damage: %d\n" % part["damage"]
		if part.has("armor"):
			stats += "Armor: %d\n" % part["armor"]
		if part.has("weight"):
			stats += "Weight: %d\n" % part["weight"]
		if part.has("health"):
			stats += "Health: %d\n" % part["health"]
		_item_stats_label.text = stats
	
	if _item_description_label and is_instance_valid(_item_description_label):
		_item_description_label.text = part.get("description", "No description available.")
	
	if _manufacturer_label and is_instance_valid(_manufacturer_label):
		var manufacturer: String = part.get("manufacturer", "Unknown")
		_manufacturer_label.text = "Manufactured by: " + manufacturer

func _update_action_buttons() -> void:
	var has_item_selected: bool = _selected_inventory_item != ""
	var has_bot_selected: bool = _selected_bot_slot != null and is_instance_valid(_selected_bot_slot)
	var bot_is_enabled: bool = has_bot_selected and _selected_bot_slot.is_enabled
	
	if _mount_button and is_instance_valid(_mount_button):
		_mount_button.disabled = not (has_item_selected and bot_is_enabled)
	
	if _unmount_button and is_instance_valid(_unmount_button):
		_unmount_button.disabled = not has_bot_selected
	
	if _enable_button and is_instance_valid(_enable_button):
		_enable_button.disabled = not (has_bot_selected and not bot_is_enabled)
	
	if _disable_button and is_instance_valid(_disable_button):
		_disable_button.disabled = not (has_bot_selected and bot_is_enabled)
	
	if _deploy_button and is_instance_valid(_deploy_button):
		## Check if at least one bot is enabled
		var has_enabled_bot: bool = false
		for slot in _bot_slots:
			if slot and slot.is_enabled:
				has_enabled_bot = true
				break
		_deploy_button.disabled = not has_enabled_bot

func _update_bot_stats() -> void:
	var total_weight: int = 0
	var total_dps: int = 0
	
	for slot in _bot_slots:
		if slot and slot.is_enabled and slot.loadout:
			total_weight += slot.get_total_weight()
			total_dps += slot.get_total_dps()
	
	if _weight_label and is_instance_valid(_weight_label):
		_weight_label.text = "Weight: %d" % total_weight
	
	if _dps_label and is_instance_valid(_dps_label):
		_dps_label.text = "DPS: %d" % total_dps

func _on_mount_pressed() -> void:
	if _selected_bot_slot and is_instance_valid(_selected_bot_slot):
		_selected_bot_slot.mount_part(_selected_inventory_item)
		_update_bot_stats()
		_populate_inventory()  ## Refresh quantities

func _on_unmount_pressed() -> void:
	if _selected_bot_slot and is_instance_valid(_selected_bot_slot):
		_selected_bot_slot.unmount_selected_part()
		_update_bot_stats()
		_populate_inventory()

func _on_enable_pressed() -> void:
	if _selected_bot_slot and is_instance_valid(_selected_bot_slot):
		_selected_bot_slot.set_enabled(true)
		_update_action_buttons()
		_update_bot_stats()

func _on_disable_pressed() -> void:
	if _selected_bot_slot and is_instance_valid(_selected_bot_slot):
		_selected_bot_slot.set_enabled(false)
		_update_action_buttons()
		_update_bot_stats()

func _on_team_color_changed(color: Color) -> void:
	## Apply team color to all enabled bots
	for slot in _bot_slots:
		if slot and slot.is_enabled:
			slot.set_team_color(color)

func _on_back_pressed() -> void:
	## Save before leaving
	if GameState and is_instance_valid(GameState):
		GameState.save_game()
	
	if is_instance_valid(self):
		back_pressed.emit()

func _on_deploy_pressed() -> void:
	## Save before deploying
	if GameState and is_instance_valid(GameState):
		GameState.save_game()
	
	if is_instance_valid(self):
		deploy_pressed.emit()

func _exit_tree() -> void:
	## Bible B1.3: Disconnect all signals
	var buttons: Array[Button] = [_back_button, _deploy_button, _mount_button, 
		_unmount_button, _enable_button, _disable_button]
	
	for button in buttons:
		if button and is_instance_valid(button):
			for connection in button.pressed.get_connections():
				var callable: Callable = connection["callable"]
				if button.pressed.is_connected(callable):
					button.pressed.disconnect(callable)
	
	## Disconnect bot slots
	for slot in _bot_slots:
		if slot and is_instance_valid(slot):
			for connection in slot.selected.get_connections():
				var callable: Callable = connection["callable"]
				if slot.selected.is_connected(callable):
					slot.selected.disconnect(callable)
