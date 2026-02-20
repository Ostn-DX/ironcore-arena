extends PanelContainer
class_name BuildSlot
## Individual bot build slot in the builder
## Displays assembled bot, handles click to build/destroy

@onready var icon: TextureRect = $VBox/Icon
@onready var name_label: Label = $VBox/NameLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var weight_label: Label = $VBox/WeightLabel
@onready var remove_button: Button = $VBox/RemoveButton

var slot_index: int = 0
var current_bot: Bot = null
var is_empty: bool = true

# Signals
signal clicked
signal bot_assembled
signal bot_removed


func _ready():
	remove_button.pressed.connect(_on_remove_pressed)
	gui_input.connect(_on_gui_input)
	_update_empty_state()


## Build a bot in this slot
func build_bot(chassis_id: String, plating_id: String, weapon_id: String = "") -> bool:
	# Create bot instance
	var bot = Bot.new()
	var success = bot.build(chassis_id, plating_id, weapon_id)
	
	if not success:
		bot.queue_free()
		return false
	
	# Validate weight
	if not bot.is_weight_valid():
		bot.queue_free()
		return false
	
	# Clear existing
	if current_bot != null:
		current_bot.queue_free()
	
	current_bot = bot
	is_empty = false
	
	_update_display()
	bot_assembled.emit()
	
	return true


## Remove bot from slot
func remove_bot() -> void:
	if current_bot != null:
		current_bot.queue_free()
		current_bot = null
	
	is_empty = true
	_update_empty_state()
	bot_removed.emit()


## Check if slot has a bot
func has_bot() -> bool:
	return not is_empty and current_bot != null


## Get bot weight
func get_bot_weight() -> float:
	if current_bot == null:
		return 0.0
	return current_bot.total_weight


## Export bot configuration
func export_config() -> Dictionary:
	if current_bot == null:
		return {}
	
	return {
		"chassis": current_bot.chassis_data.get("id", ""),
		"plating": current_bot.plating_data.get("id", ""),
		"weapon": current_bot.weapon_data.get("id", "")
	}


## Update display with bot info
func _update_display() -> void:
	if current_bot == null:
		_update_empty_state()
		return
	
	var summary = current_bot.get_build_summary()
	
	name_label.text = summary.chassis
	stats_label.text = "HP: %.0f | SPD: %.1f | DPS: %.1f" % [
		summary.hp, summary.speed, summary.dps
	]
	weight_label.text = "Weight: %.0f/%.0f" % [summary.weight, summary.capacity]
	
	# Color by weight validity
	if summary.weight <= summary.capacity:
		weight_label.modulate = Color.WHITE
	else:
		weight_label.modulate = Color.RED
	
	# Load icon (placeholder)
	# icon.texture = load("res://assets/bots/%s.png" % summary.chassis)
	
	remove_button.visible = true


## Update for empty state
func _update_empty_state() -> void:
	name_label.text = "Slot %d (Empty)" % (slot_index + 1)
	stats_label.text = "Click to build"
	weight_label.text = ""
	remove_button.visible = false
	
	# Default icon
	# icon.texture = preload("res://assets/ui/empty_slot.png")


## GUI input handler
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit()


## Remove button handler
func _on_remove_pressed() -> void:
	remove_bot()
