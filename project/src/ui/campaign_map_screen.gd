extends Control
class_name CampaignMapScreen
## CampaignMapScreen — displays the campaign map with arena nodes.

signal arena_selected(arena_id: String)
signal back_pressed

# Campaign manager reference
var campaign_manager: CampaignManager = null

# UI Elements
var title_label: Label = null
var tier_label: Label = null
var arena_container: VBoxContainer = null
var info_panel: Panel = null
var info_name: Label = null
var info_stats: Label = null
var info_tips: Label = null
var play_button: Button = null

# Selected arena
var selected_arena_id: String = ""


func _ready() -> void:
	# Create campaign manager
	campaign_manager = CampaignManager.new()
	campaign_manager.name = "CampaignManager"
	add_child(campaign_manager)
	
	_setup_ui()
	_refresh_display()


func _setup_ui() -> void:
	## Setup the campaign map UI
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	add_child(bg)
	
	# Title
	title_label = Label.new()
	title_label.text = "CAMPAIGN MAP"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(440, 30)
	title_label.size = Vector2(400, 50)
	add_child(title_label)
	
	# Current tier label
	tier_label = Label.new()
	tier_label.text = "Current Tier: 1"
	tier_label.add_theme_font_size_override("font_size", 18)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.position = Vector2(440, 80)
	tier_label.size = Vector2(400, 30)
	tier_label.modulate = Color(0.7, 0.7, 0.7)
	add_child(tier_label)
	
	# Arena list container
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.position = Vector2(50, 130)
	scroll.size = Vector2(600, 500)
	add_child(scroll)
	
	arena_container = VBoxContainer.new()
	arena_container.theme_override_constants/separation = 10
	scroll.add_child(arena_container)
	
	# Info panel (right side)
	info_panel = Panel.new()
	info_panel.position = Vector2(700, 130)
	info_panel.size = Vector2(500, 400)
	add_child(info_panel)
	
	var info_title: Label = Label.new()
	info_title.text = "Arena Info"
	info_title.add_theme_font_size_override("font_size", 20)
	info_title.position = Vector2(710, 140)
	info_title.size = Vector2(480, 30)
	add_child(info_title)
	
	info_name = Label.new()
	info_name.text = "Select an arena"
	info_name.add_theme_font_size_override("font_size", 24)
	info_name.position = Vector2(710, 180)
	info_name.size = Vector2(480, 40)
	add_child(info_name)
	
	info_stats = Label.new()
	info_stats.text = ""
	info_stats.position = Vector2(710, 230)
	info_stats.size = Vector2(480, 150)
	add_child(info_stats)
	
	info_tips = Label.new()
	info_tips.text = ""
	info_tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_tips.position = Vector2(710, 390)
	info_tips.size = Vector2(480, 100)
	info_tips.modulate = Color(0.8, 0.8, 0.6)
	add_child(info_tips)
	
	# Play button
	play_button = Button.new()
	play_button.text = "Enter Arena"
	play_button.position = Vector2(850, 550)
	play_button.size = Vector2(200, 50)
	play_button.disabled = true
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)
	
	# Back button
	var back_btn: Button = Button.new()
	back_btn.text = "Back"
	back_btn.position = Vector2(50, 650)
	back_btn.size = Vector2(100, 40)
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)


func _refresh_display() -> void:
	## Refresh the arena list display
	# Clear existing
	for child in arena_container.get_children():
		child.queue_free()
	
	# Update tier label
	if campaign_manager:
		var tier: int = campaign_manager.get_current_tier()
		tier_label.text = "Current Tier: %d" % (tier + 1)
	
	# Get arena info
	var arenas: Array[Dictionary] = []
	if campaign_manager:
		arenas = campaign_manager.get_all_arena_info()
	
	# Create buttons for each arena
	for arena in arenas:
		_create_arena_button(arena)


func _create_arena_button(arena: Dictionary) -> void:
	## Create a button for an arena
	var btn: Button = Button.new()
	
	var status_icon: String = "🔒"
	if arena.get("is_completed", false):
		status_icon = "✅"
	elif arena.get("is_unlocked", false):
		status_icon = "⚔️"
	
	btn.text = "%s %s (Tier %d)" % [
		status_icon,
		arena.get("name", "Unknown"),
		arena.get("tier", 0) + 1
	]
	
	btn.custom_minimum_size = Vector2(0, 60)
	
	# Style based on status
	if arena.get("is_completed", false):
		btn.modulate = Color(0.5, 0.8, 0.5)
	elif not arena.get("is_unlocked", false):
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5)
	
	btn.pressed.connect(_on_arena_selected.bind(arena))
	arena_container.add_child(btn)


func _on_arena_selected(arena: Dictionary) -> void:
	## Handle arena selection
	selected_arena_id = arena.get("id", "")
	
	# Update info panel
	info_name.text = arena.get("name", "Unknown Arena")
	
	var stats_text: String = "Difficulty: %s\n" % arena.get("difficulty", "medium").capitalize()
	stats_text += "Enemies: %d\n" % arena.get("enemy_count", 1)
	stats_text += "Weight Limit: %d\n" % arena.get("weight_limit", 120)
	stats_text += "Par Time: %d seconds\n" % arena.get("par_time", 120)
	stats_text += "Reward: %d credits\n" % arena.get("base_reward", 100)
	stats_text += "Status: %s" % ("Completed" if arena.get("is_completed", false) else "Available")
	
	info_stats.text = stats_text
	
	# Show tips
	if campaign_manager:
		var tips: Array = campaign_manager.get_arena_tips(selected_arena_id)
		if tips.size() > 0:
			info_tips.text = "Tips:\n" + "\n".join(tips)
		else:
			info_tips.text = ""
	
	# Enable play button if unlocked
	play_button.disabled = not arena.get("is_unlocked", false)


func _on_play_pressed() -> void:
	## Enter the selected arena
	if selected_arena_id != "":
		arena_selected.emit(selected_arena_id)


func _on_back_pressed() -> void:
	## Go back to main menu
	back_pressed.emit()
