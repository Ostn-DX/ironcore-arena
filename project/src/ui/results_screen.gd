extends Control
class_name ResultsScreen
## ResultsScreen - displays battle results, stats, and rewards.
## Shown after battle ends with options to continue, restart, or edit loadout.

signal continue_pressed
signal restart_pressed
signal edit_loadout_pressed
signal next_arena_pressed

# UI References (from scene)
@onready var background: ColorRect = $Background
@onready var main_panel: Panel = $MainPanel
@onready var title_label: Label = $MainPanel/VBox/TitleLabel
@onready var grade_label: Label = $MainPanel/VBox/GradeLabel
@onready var condition_label: Label = $MainPanel/VBox/ConditionLabel
@onready var stats_section: VBoxContainer = $MainPanel/VBox/StatsSection
@onready var rewards_section: HBoxContainer = $MainPanel/VBox/RewardsSection
@onready var continue_btn: Button = $MainPanel/VBox/ButtonsRow/ContinueBtn
@onready var restart_btn: Button = $MainPanel/VBox/ButtonsRow/RestartBtn
@onready var edit_btn: Button = $MainPanel/VBox/ButtonsRow/EditBtn
@onready var next_btn: Button = $MainPanel/VBox/ButtonsRow/NextBtn

# Animation
var appear_tween: Tween = null

# Colors
const COLOR_VICTORY: Color = Color(0.2, 0.9, 0.2)
const COLOR_DEFEAT: Color = Color(0.9, 0.2, 0.2)
const COLOR_DRAW: Color = Color(0.9, 0.9, 0.2)
const COLOR_S_RANK: Color = Color(1.0, 0.84, 0.0)
const COLOR_A_RANK: Color = Color(0.8, 0.9, 1.0)
const COLOR_B_RANK: Color = Color(0.8, 0.5, 0.3)
const COLOR_DEFAULT: Color = Color(0.7, 0.7, 0.7)

# Current result data
var _current_result: Dictionary = {}
var _current_rewards: Dictionary = {}

func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	_setup_signals()

func _setup_signals() -> void:
	## Connect button signals
	if continue_btn:
		continue_btn.pressed.connect(_on_continue)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart)
	if edit_btn:
		edit_btn.pressed.connect(_on_edit_loadout)
	if next_btn:
		next_btn.pressed.connect(_on_next_arena)

func set_results(result: Dictionary) -> void:
	## Display results from a dictionary
	visible = true
	_current_result = result
	_current_rewards = result.get("rewards", {})
	
	_update_display()
	_animate_appear()

func _update_display() -> void:
	## Update all UI elements with result data
	var is_victory = _current_result.get("victory", false)
	var is_draw = _current_result.get("result_type", -1) == 2
	var grade = _current_result.get("grade", "F")
	
	# Title
	if is_victory:
		title_label.text = "VICTORY!"
		title_label.modulate = COLOR_VICTORY
	elif is_draw:
		title_label.text = "DRAW"
		title_label.modulate = COLOR_DRAW
	else:
		title_label.text = "DEFEAT"
		title_label.modulate = COLOR_DEFEAT
	
	# Grade
	grade_label.text = grade
	match grade:
		"S": grade_label.modulate = COLOR_S_RANK
		"A": grade_label.modulate = COLOR_A_RANK
		"B": grade_label.modulate = COLOR_B_RANK
		"C", "D": grade_label.modulate = COLOR_DEFAULT
		_: grade_label.modulate = COLOR_DEFEAT if not is_victory else COLOR_DEFAULT
	
	# Condition
	var result_type = _current_result.get("result_type", 1)
	match result_type:
		0: condition_label.text = "All enemies eliminated"
		1: condition_label.text = "All player bots destroyed"
		2: condition_label.text = "Mutual destruction"
		3: condition_label.text = "Time limit reached"
		_: condition_label.text = "Battle ended"
	
	# Stats
	var time_value = stats_section.get_node_or_null("TimeRow/Value")
	if time_value:
		time_value.text = _format_time(_current_result.get("time_seconds", 0))
	
	var kdr_value = stats_section.get_node_or_null("KDRRow/Value")
	if kdr_value:
		var kills = _current_result.get("enemies_destroyed", 0)
		var losses = _current_result.get("player_bots_lost", 0)
		kdr_value.text = "%d / %d" % [kills, losses]
	
	var acc_value = stats_section.get_node_or_null("AccuracyRow/Value")
	if acc_value:
		acc_value.text = "%.1f%%" % _current_result.get("accuracy", 0)
	
	var dmg_value = stats_section.get_node_or_null("DamageRow/Value")
	if dmg_value:
		dmg_value.text = "%d dealt" % _current_result.get("damage_dealt", 0)
	
	# Rewards
	var credits_value = rewards_section.get_node_or_null("CreditsValue")
	if credits_value:
		var credits = _current_rewards.get("credits", 0)
		credits_value.text = str(credits)
	
	# Buttons
	if continue_btn:
		continue_btn.text = "Continue" if is_victory else "Retry"
	if next_btn:
		next_btn.visible = is_victory

func _animate_appear() -> void:
	## Animate results screen appearing
	main_panel.modulate.a = 0
	main_panel.scale = Vector2(0.95, 0.95)
	
	appear_tween = create_tween()
	appear_tween.set_ease(Tween.EASE_OUT)
	appear_tween.set_trans(Tween.TRANS_BACK)
	appear_tween.tween_property(main_panel, "modulate:a", 1.0, 0.3)
	appear_tween.parallel().tween_property(main_panel, "scale", Vector2.ONE, 0.3)

func _format_time(seconds: float) -> String:
	## Format seconds as MM:SS
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%d:%02d" % [mins, secs]

func _on_continue() -> void:
	continue_pressed.emit()

func _on_restart() -> void:
	restart_pressed.emit()

func _on_edit_loadout() -> void:
	edit_loadout_pressed.emit()

func _on_next_arena() -> void:
	next_arena_pressed.emit()

func hide_results() -> void:
	## Hide the results screen
	visible = false

func is_showing() -> bool:
	return visible
