extends Control
class_name ResultsScreen
const BattleManager = preload("res://src/managers/BattleManager.gd")
const Arena = preload("res://src/entities/arena.gd")
## ResultsScreen - displays detailed battle results, stats, and rewards.
## Shown after battle ends with options to continue, restart, or edit loadout.

signal continue_pressed
signal restart_pressed
signal edit_loadout_pressed
signal next_arena_pressed

# UI Elements (created dynamically)
var background: Panel = null
var title_label: Label = null
var grade_label: Label = null
var stats_container: VBoxContainer = null
var rewards_container: HBoxContainer = null
var buttons_container: HBoxContainer = null

# Animation
var appear_tween: Tween = null

# Colors
const COLOR_VICTORY: Color = Color(0.2, 0.9, 0.2)
const COLOR_DEFEAT: Color = Color(0.9, 0.2, 0.2)
const COLOR_DRAW: Color = Color(0.9, 0.9, 0.2)
const COLOR_S_RANK: Color = Color(1.0, 0.84, 0.0)  # Gold
const COLOR_A_RANK: Color = Color(0.8, 0.9, 1.0)   # Silver-ish
const COLOR_B_RANK: Color = Color(0.8, 0.5, 0.3)   # Bronze-ish
const COLOR_DEFAULT: Color = Color(0.7, 0.7, 0.7)

# Current result data
var _current_result: Dictionary = {}
var _current_rewards: Dictionary = {}

func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP

# ============================================================================
# DISPLAY
# ============================================================================

func show_results(result: BattleManager.BattleResult, rewards: Dictionary) -> void:
	## Display battle results from BattleManager.BattleResult
	visible = true
	
	# Store for reference
	_current_rewards = rewards
	
	# Convert BattleResult to dictionary if needed
	if result:
		_current_result = result.to_dictionary()
		_current_result["result_type"] = result.result_type
	else:
		_current_result = {}
	
	# Clear previous
	for child in get_children():
		child.queue_free()
	
	# Create UI elements
	_create_background()
	_create_title_section()
	_create_grade_display()
	_create_condition_display()
	_create_stats_section()
	_create_rewards_section()
	_create_buttons()
	
	# Animate in
	_animate_appear()

func show_results_from_dict(result_dict: Dictionary, rewards: Dictionary) -> void:
	## Display results from a dictionary (alternative entry point)
	visible = true
	_current_result = result_dict
	_current_rewards = rewards
	
	# Clear previous
	for child in get_children():
		child.queue_free()
	
	# Create UI elements
	_create_background()
	_create_title_section()
	_create_grade_display()
	_create_condition_display()
	_create_stats_section()
	_create_rewards_section()
	_create_buttons()
	
	_animate_appear()

func _create_background() -> void:
	## Semi-transparent background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)
	add_child(bg)
	
	# Main panel
	background = Panel.new()
	background.set_anchors_preset(Control.PRESET_CENTER)
	background.size = Vector2(600, 650)
	# Position handled by anchor preset
	add_child(background)
	
	# Panel style
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.18)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.4, 0.4, 0.5)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	background.add_theme_stylebox_override("panel", panel_style)

func _create_title_section() -> void:
	## Victory/Defeat/Draw title
	var result_type = _current_result.get("result_type", 1)  # Default DEFEAT
	var is_victory: bool = result_type == BattleManager.BattleResult.ResultType.VICTORY
	var is_draw: bool = result_type == BattleManager.BattleResult.ResultType.DRAW or result_type == BattleManager.BattleResult.ResultType.TIMEOUT
	
	var title_text: String = "DEFEAT"
	var title_color: Color = COLOR_DEFEAT
	
	if is_victory:
		title_text = "VICTORY!"
		title_color = COLOR_VICTORY
	elif is_draw:
		title_text = "DRAW"
		title_color = COLOR_DRAW
	
	title_label = Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(440, 50)
	title_label.size = Vector2(400, 60)
	title_label.modulate = title_color
	add_child(title_label)

func _create_grade_display() -> void:
	## Large grade letter
	var grade: String = _current_result.get("grade", "F")
	var is_victory: bool = _current_result.get("victory", false)
	
	grade_label = Label.new()
	grade_label.text = grade
	grade_label.add_theme_font_size_override("font_size", 96)
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	grade_label.position = Vector2(0, 120)
	grade_label.size = Vector2(200, 100)
	
	# Color based on grade
	if is_victory:
		match grade:
			"S": grade_label.modulate = COLOR_S_RANK
			"A": grade_label.modulate = COLOR_A_RANK
			"B": grade_label.modulate = COLOR_B_RANK
			"C", "D": grade_label.modulate = COLOR_DEFAULT
			_: grade_label.modulate = Color(0.5, 0.5, 0.5)
	else:
		grade_label.modulate = COLOR_DEFEAT
	
	add_child(grade_label)
	
	# Grade label
	var grade_text: Label = Label.new()
	grade_text.text = "Grade"
	grade_text.add_theme_font_size_override("font_size", 16)
	grade_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_text.set_anchors_preset(Control.PRESET_CENTER_TOP)
	grade_text.position = Vector2(0, 210)
	grade_text.size = Vector2(200, 25)
	grade_text.modulate = Color(0.6, 0.6, 0.6)
	add_child(grade_text)

func _create_condition_display() -> void:
	## End condition text
	var result_type = _current_result.get("result_type", 1)
	var condition_text: String = "All enemies eliminated"
	
	match result_type:
		BattleManager.BattleResult.ResultType.VICTORY:
			condition_text = "All enemies eliminated"
		BattleManager.BattleResult.ResultType.DEFEAT:
			condition_text = "All player bots destroyed"
		BattleManager.BattleResult.ResultType.DRAW:
			condition_text = "Mutual destruction"
		BattleManager.BattleResult.ResultType.TIMEOUT:
			condition_text = "Time limit reached"
	
	var condition_label: Label = Label.new()
	condition_label.text = condition_text
	condition_label.add_theme_font_size_override("font_size", 16)
	condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	condition_label.position = Vector2(440, 245)
	condition_label.size = Vector2(400, 25)
	condition_label.modulate = Color(0.6, 0.6, 0.6)
	add_child(condition_label)

func _create_stats_section() -> void:
	## Container for stats
	stats_container = VBoxContainer.new()
	stats_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	stats_container.position = Vector2(0, 290)
	stats_container.size = Vector2(520, 220)
	stats_container.add_theme_constant_override("separation", 6)
	add_child(stats_container)
	
	# Section title
	var section_title: Label = Label.new()
	section_title.text = "Battle Statistics"
	section_title.add_theme_font_size_override("font_size", 20)
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(section_title)
	
	# Separator
	var separator: HSeparator = HSeparator.new()
	stats_container.add_child(separator)
	
	# Time row
	var time_seconds: float = _current_result.get("time_seconds", 0.0)
	_add_stat_row("Battle Time", _format_time(time_seconds))
	
	# Kills/Losses row
	var enemies_killed: int = _current_result.get("enemies_destroyed", 0)
	var player_lost: int = _current_result.get("player_bots_lost", 0)
	var kdr: float = _current_result.get("kdr", 0.0)
	_add_stat_row("K/D Ratio", "%.1f" % kdr, "%d / %d" % [enemies_killed, player_lost])
	
	# Accuracy
	var accuracy: float = _current_result.get("accuracy", 0.0)
	var shots_hit: int = _current_result.get("shots_hit", 0)
	var shots_fired: int = _current_result.get("shots_fired", 0)
	_add_stat_row("Accuracy", "%.1f%%" % accuracy, "%d / %d hits" % [shots_hit, shots_fired])
	
	# Damage
	var damage_dealt: int = _current_result.get("damage_dealt", 0)
	var damage_taken: int = _current_result.get("damage_taken", 0)
	var dmg_ratio: float = float(damage_dealt) / max(1, damage_taken)
	_add_stat_row("Damage", "%d dealt" % damage_dealt, "%d taken (%.1fx)" % [damage_taken, dmg_ratio])
	
	# Separator before performance
	stats_container.add_child(HSeparator.new())
	
	# Performance summary
	var grade: String = _current_result.get("grade", "F")
	var perf_text: String = "Performance: " + _get_grade_description(grade)
	var perf_label: Label = Label.new()
	perf_label.text = perf_text
	perf_label.add_theme_font_size_override("font_size", 14)
	perf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perf_label.modulate = Color(0.7, 0.7, 0.7)
	stats_container.add_child(perf_label)

func _get_grade_description(grade: String) -> String:
	match grade:
		"S": return "Legendary!"
		"A": return "Excellent"
		"B": return "Good"
		"C": return "Acceptable"
		"D": return "Needs Improvement"
		"F": return "Failed"
		_: return "Unknown"

func _add_stat_row(label: String, value: String, extra: String = "") -> void:
	## Add a stat row to the container
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label_node: Label = Label.new()
	label_node.text = label + ":"
	label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_node.add_theme_font_size_override("font_size", 16)
	row.add_child(label_node)
	
	var value_node: Label = Label.new()
	value_node.text = value
	value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_node.add_theme_font_size_override("font_size", 16)
	value_node.modulate = Color(0.9, 0.9, 0.9)
	row.add_child(value_node)
	
	if extra != "":
		var extra_node: Label = Label.new()
		extra_node.text = "  (" + extra + ")"
		extra_node.add_theme_font_size_override("font_size", 12)
		extra_node.modulate = Color(0.5, 0.5, 0.5)
		row.add_child(extra_node)
	
	stats_container.add_child(row)

func _create_rewards_section() -> void:
	## Rewards container
	rewards_container = HBoxContainer.new()
	rewards_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	rewards_container.position = Vector2(0, 530)
	rewards_container.size = Vector2(520, 80)
	rewards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(rewards_container)
	
	var is_victory: bool = _current_result.get("victory", false)
	
	if not is_victory:
		# No rewards on defeat
		var no_reward_label: Label = Label.new()
		no_reward_label.text = "No rewards for defeat"
		no_reward_label.add_theme_font_size_override("font_size", 18)
		no_reward_label.modulate = Color(0.5, 0.5, 0.5)
		rewards_container.add_child(no_reward_label)
		return
	
	# Credits container
	var credits_container: VBoxContainer = VBoxContainer.new()
	credits_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var credits_icon: Label = Label.new()
	credits_icon.text = "💰"
	credits_icon.add_theme_font_size_override("font_size", 32)
	credits_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_container.add_child(credits_icon)
	
	var credits_label: Label = Label.new()
	var total: int = _current_rewards.get("credits", 0)
	var base: int = _current_rewards.get("base_credits", 0)
	var bonus: int = _current_rewards.get("bonus_credits", 0)
	
	if bonus > 0:
		credits_label.text = "%d (+ %d bonus)" % [base, bonus]
	else:
		credits_label.text = str(total)
	
	credits_label.add_theme_font_size_override("font_size", 24)
	credits_label.modulate = Color(1.0, 0.84, 0.0)
	credits_container.add_child(credits_label)
	
	var credits_title: Label = Label.new()
	credits_title.text = "Credits Earned"
	credits_title.add_theme_font_size_override("font_size", 14)
	credits_title.modulate = Color(0.6, 0.6, 0.6)
	credits_container.add_child(credits_title)
	
	rewards_container.add_child(credits_container)

func _create_buttons() -> void:
	## Button container
	buttons_container = HBoxContainer.new()
	buttons_container.position = Vector2(340, 600)
	buttons_container.size = Vector2(600, 60)
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 15)
	add_child(buttons_container)
	
	var is_victory: bool = _current_result.get("victory", false)
	
	# Continue/Retry button
	var continue_btn: Button = Button.new()
	continue_btn.text = "Continue" if is_victory else "Retry"
	continue_btn.size = Vector2(120, 45)
	continue_btn.pressed.connect(_on_continue)
	buttons_container.add_child(continue_btn)
	
	# Restart button
	var restart_btn: Button = Button.new()
	restart_btn.text = "Restart"
	restart_btn.size = Vector2(120, 45)
	restart_btn.pressed.connect(_on_restart)
	buttons_container.add_child(restart_btn)
	
	# Edit loadout button
	var edit_btn: Button = Button.new()
	edit_btn.text = "Edit Bot"
	edit_btn.size = Vector2(120, 45)
	edit_btn.pressed.connect(_on_edit_loadout)
	buttons_container.add_child(edit_btn)
	
	# Next arena button (only on victory)
	if is_victory:
		var next_btn: Button = Button.new()
		next_btn.text = "Next →"
		next_btn.size = Vector2(100, 45)
		next_btn.pressed.connect(_on_next_arena)
		buttons_container.add_child(next_btn)

func _animate_appear() -> void:
	## Animate results screen appearing
	modulate.a = 0
	scale = Vector2(0.95, 0.95)
	
	appear_tween = create_tween()
	appear_tween.set_ease(Tween.EASE_OUT)
	appear_tween.set_trans(Tween.TRANS_BACK)
	appear_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	appear_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)

# ============================================================================
# BUTTON HANDLERS
# ============================================================================

func _on_continue() -> void:
	continue_pressed.emit()

func _on_restart() -> void:
	restart_pressed.emit()

func _on_edit_loadout() -> void:
	edit_loadout_pressed.emit()

func _on_next_arena() -> void:
	next_arena_pressed.emit()

# ============================================================================
# UTILITY
# ============================================================================

func _format_time(seconds: float) -> String:
	## Format seconds as MM:SS
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%d:%02d" % [mins, secs]

func hide_results() -> void:
	## Hide the results screen
	visible = false
	for child in get_children():
		child.queue_free()

func is_showing() -> bool:
	return visible
