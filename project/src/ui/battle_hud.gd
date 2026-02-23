class_name BattleHUD
extends Control
const BattleManager = preload("res://src/managers/BattleManager.gd")
## BattleHUD - heads-up display during battles.
## Shows battle status, team info, and controls.

signal pause_requested
signal surrender_requested

# HUD Elements
var time_label: Label = null
var team_status_container: HBoxContainer = null
var player_status: VBoxContainer = null
var enemy_status: VBoxContainer = null
var command_bar: ProgressBar = null
var pause_button: Button = null

# Battle state reference
var battle_manager: BattleManager = null

# Colors
const COLOR_PLAYER: Color = Color(0.2, 0.6, 1.0)
const COLOR_ENEMY: Color = Color(1.0, 0.3, 0.3)
const COLOR_WARNING: Color = Color(1.0, 0.8, 0.2)
const COLOR_DANGER: Color = Color(1.0, 0.2, 0.2)


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	## Setup the battle HUD UI
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	
	# Top bar - Time and controls
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.position = Vector2(20, 10)
	top_bar.size = Vector2(1240, 50)
	add_child(top_bar)
	
	# Pause button
	pause_button = Button.new()
	pause_button.text = "⏸"
	pause_button.add_theme_font_size_override("font_size", 24)
	pause_button.size = Vector2(50, 40)
	pause_button.pressed.connect(_on_pause_pressed)
	top_bar.add_child(pause_button)
	
	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)
	
	# Time display
	var time_container: VBoxContainer = VBoxContainer.new()
	time_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(time_container)
	
	var time_title: Label = Label.new()
	time_title.text = "BATTLE TIME"
	time_title.add_theme_font_size_override("font_size", 12)
	time_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_container.add_child(time_title)
	
	time_label = Label.new()
	time_label.text = "00:00"
	time_label.add_theme_font_size_override("font_size", 28)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.modulate = COLOR_PLAYER
	time_container.add_child(time_label)
	
	# Spacer
	var spacer2: Control = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer2)
	
	# Surrender button
	var surrender_btn: Button = Button.new()
	surrender_btn.text = "⚐"
	surrender_btn.add_theme_font_size_override("font_size", 20)
	surrender_btn.size = Vector2(50, 40)
	surrender_btn.tooltip_text = "Surrender"
	surrender_btn.pressed.connect(_on_surrender_pressed)
	top_bar.add_child(surrender_btn)
	
	# Team status panel (bottom)
	var status_panel: Panel = Panel.new()
	status_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	status_panel.position = Vector2(10, 660)
	status_panel.size = Vector2(1260, 50)
	add_child(status_panel)
	
	team_status_container = HBoxContainer.new()
	team_status_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	team_status_container.position = Vector2(10, 5)
	team_status_container.size = Vector2(1240, 40)
	team_status_container.alignment = BoxContainer.ALIGNMENT_CENTER
	team_status_container.add_theme_constant_override("separation", 100)
	add_child(team_status_container)
	
	# Player team status
	player_status = VBoxContainer.new()
	player_status.alignment = BoxContainer.ALIGNMENT_CENTER
	team_status_container.add_child(player_status)
	
	var player_label: Label = Label.new()
	player_label.text = "YOUR SQUAD"
	player_label.add_theme_font_size_override("font_size", 12)
	player_label.modulate = COLOR_PLAYER
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_status.add_child(player_label)
	
	var player_count: Label = Label.new()
	player_count.name = "CountLabel"
	player_count.text = "0 / 0"
	player_count.add_theme_font_size_override("font_size", 20)
	player_count.modulate = COLOR_PLAYER
	player_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_status.add_child(player_count)
	
	# VS label
	var vs_label: Label = Label.new()
	vs_label.text = "VS"
	vs_label.add_theme_font_size_override("font_size", 24)
	vs_label.modulate = Color(0.5, 0.5, 0.5)
	team_status_container.add_child(vs_label)
	
	# Enemy team status
	enemy_status = VBoxContainer.new()
	enemy_status.alignment = BoxContainer.ALIGNMENT_CENTER
	team_status_container.add_child(enemy_status)
	
	var enemy_label: Label = Label.new()
	enemy_label.text = "ENEMIES"
	enemy_label.add_theme_font_size_override("font_size", 12)
	enemy_label.modulate = COLOR_ENEMY
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_status.add_child(enemy_label)
	
	var enemy_count: Label = Label.new()
	enemy_count.name = "CountLabel"
	enemy_count.text = "0 / 0"
	enemy_count.add_theme_font_size_override("font_size", 20)
	enemy_count.modulate = COLOR_ENEMY
	enemy_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_status.add_child(enemy_count)
	
	# Instructions bar (bottom center)
	var instructions_bg: ColorRect = ColorRect.new()
	instructions_bg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	instructions_bg.position = Vector2(340, 620)
	instructions_bg.size = Vector2(600, 30)
	instructions_bg.color = Color(0, 0, 0, 0.5)
	add_child(instructions_bg)
	
	var instructions: Label = Label.new()
	instructions.text = "Drag BLUE bot to move • Drag to RED enemy to attack"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	instructions.position = Vector2(340, 625)
	instructions.size = Vector2(600, 25)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(instructions)


# ============================================================================
# UPDATE METHODS
# ============================================================================

func update_time(seconds: float, is_overtime: bool = false) -> void:
	## Update the time display
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	time_label.text = "%02d:%02d" % [mins, secs]
	
	if is_overtime:
		time_label.modulate = COLOR_WARNING
	else:
		time_label.modulate = COLOR_PLAYER


func update_team_status(player_alive: int, player_total: int, enemy_alive: int, enemy_total: int) -> void:
	## Update team status display
	var player_label: Label = player_status.get_node_or_null("CountLabel")
	if player_label:
		player_label.text = "%d / %d" % [player_alive, player_total]
		
		# Color based on health
		if player_alive == 1 and player_total > 1:
			player_label.modulate = COLOR_WARNING
		elif player_alive == 0:
			player_label.modulate = COLOR_DANGER
		else:
			player_label.modulate = COLOR_PLAYER
	
	var enemy_label: Label = enemy_status.get_node_or_null("CountLabel")
	if enemy_label:
		enemy_label.text = "%d / %d" % [enemy_alive, enemy_total]


func update_from_summary(summary: Dictionary) -> void:
	## Update HUD from battle summary
	if summary.has("time"):
		time_label.text = summary["time"]
	
	if summary.has("player_alive") and summary.has("player_total"):
		if summary.has("enemy_alive") and summary.has("enemy_total"):
			update_team_status(
				summary["player_alive"],
				summary["player_total"],
				summary["enemy_alive"],
				summary["enemy_total"]
			)


func set_battle_manager(manager: BattleManager) -> void:
	## Set the battle manager reference
	battle_manager = manager


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_pause_pressed() -> void:
	pause_requested.emit()


func _on_surrender_pressed() -> void:
	surrender_requested.emit()


# ============================================================================
# VISUAL FEEDBACK
# ============================================================================

func flash_time_warning() -> void:
	## Flash the time label for time warning
	var tween: Tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(time_label, "modulate", COLOR_WARNING, 0.2)
	tween.tween_property(time_label, "modulate", COLOR_PLAYER, 0.2)


func show_victory_flash() -> void:
	## Show victory flash effect
	var flash: ColorRect = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = COLOR_PLAYER
	flash.modulate.a = 0.3
	add_child(flash)
	
	var tween: Tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.finished.connect(flash.queue_free)


func show_defeat_flash() -> void:
	## Show defeat flash effect
	var flash: ColorRect = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = COLOR_DANGER
	flash.modulate.a = 0.3
	add_child(flash)
	
	var tween: Tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.finished.connect(flash.queue_free)
