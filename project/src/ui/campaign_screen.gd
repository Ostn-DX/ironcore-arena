extends Control
class_name CampaignScreen
## CampaignScreen - campaign map with arena selection.
## Displays tier progress and allows arena selection.

signal arena_selected(arena_id: String)
signal back_pressed

# UI References
@onready var title_label: Label = $MarginContainer/MainVBox/Header/Title
@onready var back_button: Button = $MarginContainer/MainVBox/Header/BackButton
@onready var current_tier_label: Label = $MarginContainer/MainVBox/TierInfo/CurrentTierLabel
@onready var arenas_completed_label: Label = $MarginContainer/MainVBox/TierInfo/ArenasCompletedLabel
@onready var arenas_grid: GridContainer = $MarginContainer/MainVBox/ScrollContainer/ArenasGrid

# Arena data
var arena_cards: Array[Dictionary] = []
var current_tier: int = 0

func _ready() -> void:
	_setup_ui()
	_load_campaign_data()

func _setup_ui() -> void:
	## Setup UI connections
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# Connect arena card buttons
	for i in range(arenas_grid.get_child_count()):
		var card = arenas_grid.get_child(i)
		var btn = card.get_node_or_null("VBox/SelectBtn")
		if btn:
			btn.pressed.connect(_on_arena_selected.bind(i))

func _load_campaign_data() -> void:
	## Load current campaign progress
	if GameState:
		current_tier = GameState.current_tier
		var completed = GameState.completed_arenas.size()
		
		current_tier_label.text = "Current Tier: %d" % (current_tier + 1)
		arenas_completed_label.text = "| Arenas: %d/6" % completed
		
		_update_arena_cards()

func _update_arena_cards() -> void:
	## Update arena card display based on progress
	if not GameState:
		return
		
	var arenas: Array[String] = [
		"arena_boot_camp",
		"arena_2",
		"arena_3",
		"arena_4",
		"arena_5",
		"arena_boss_1"
	]
	
	var arena_names: Array[String] = [
		"Boot Camp",
		"Light Skirmish",
		"First Blood",
		"Double Trouble",
		"Heavy Lifting",
		"BOSS: Gatekeeper"
	]
	
	var difficulties: Array[String] = [
		"★☆☆",
		"★★☆",
		"★★☆",
		"★★★",
		"★★★",
		"★★★★★"
	]
	
	for i in range(min(arenas_grid.get_child_count(), arenas.size())):
		var card = arenas_grid.get_child(i)
		var name_label = card.get_node_or_null("VBox/Name")
		var diff_label = card.get_node_or_null("VBox/Difficulty")
		var status_label = card.get_node_or_null("VBox/Status")
		var btn = card.get_node_or_null("VBox/SelectBtn")
		
		var arena_id = arenas[i]
		var is_completed = arena_id in GameState.completed_arenas
		var is_unlocked = _is_arena_unlocked(i)
		
		if name_label:
			name_label.text = arena_names[i]
		if diff_label:
			diff_label.text = difficulties[i]
		
		if status_label:
			if is_completed:
				status_label.text = "✓ Completed"
				status_label.modulate = Color(0.2, 0.9, 0.2)
			elif is_unlocked:
				status_label.text = "Available"
				status_label.modulate = Color(0.0, 0.8, 1.0)
			else:
				status_label.text = "Locked"
				status_label.modulate = Color(0.5, 0.5, 0.5)
		
		if btn:
			btn.disabled = not is_unlocked
			if is_completed:
				btn.text = "Replay"
			elif is_unlocked:
				btn.text = "Enter Arena"
			else:
				btn.text = "Locked"

func _is_arena_unlocked(index: int) -> bool:
	## Check if arena is unlocked
	# First arena always unlocked
	if index == 0:
		return true
	
	# Arena unlocked if previous arena completed
	var arenas: Array[String] = [
		"arena_boot_camp",
		"arena_2",
		"arena_3",
		"arena_4",
		"arena_5",
		"arena_boss_1"
	]
	
	if index > 0 and index < arenas.size():
		var prev_arena = arenas[index - 1]
		return prev_arena in GameState.completed_arenas
	
	return false

func _on_arena_selected(index: int) -> void:
	## Handle arena selection
	var arenas: Array[String] = [
		"arena_boot_camp",
		"arena_2",
		"arena_3",
		"arena_4",
		"arena_5",
		"arena_boss_1"
	]
	
	if index < arenas.size():
		print("CampaignScreen: Arena selected: ", arenas[index])
		arena_selected.emit(arenas[index])

func _on_back_pressed() -> void:
	## Handle back button
	print("CampaignScreen: Back pressed")
	back_pressed.emit()

func on_show() -> void:
	## Called when screen becomes visible
	_load_campaign_data()
	visible = true

func on_hide() -> void:
	## Called when screen is hidden
	visible = false
