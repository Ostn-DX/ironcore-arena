extends Control
class_name BattleTutorialOverlay
## BattleTutorialOverlay — shows contextual tips during first battle.

signal tip_acknowledged

@onready var _audio_manager = get_node("/root/AudioManager")

# Battle tips
const BATTLE_TIPS: Array[Dictionary] = [
	{
		"trigger": "battle_start",
		"title": "Your First Battle!",
		"text": "This is your bot (BLUE) vs the enemy (RED).",
		"position": "center",
		"duration": 4.0
	},
	{
		"trigger": "countdown",
		"title": "Get Ready!",
		"text": "The battle starts in 3... 2... 1...",
		"position": "center",
		"duration": 3.0
	},
	{
		"trigger": "first_move",
		"title": "Try Moving",
		"text": "Click and drag your BLUE bot to a new position!",
		"position": "bottom",
		"duration": 6.0
	},
	{
		"trigger": "enemy_spotted",
		"title": "Enemy in Range!",
		"text": "Drag from your bot to the RED enemy to attack!",
		"position": "bottom",
		"duration": 6.0
	},
	{
		"trigger": "low_hp",
		"title": "Low Health!",
		"text": "Your bot is damaged! Try to keep distance from enemies.",
		"position": "center",
		"duration": 4.0
	}
]

# UI Elements
var tip_panel: Panel = null
var title_label: Label = null
var text_label: Label = null
var ok_button: Button = null

var current_tip: Dictionary = {}
var tip_active: bool = false


func _ready() -> void:
	_setup_ui()
	hide_tip()


func _setup_ui() -> void:
	## Setup the tip overlay UI
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_PASS
	
	# Tip panel (centered by default)
	tip_panel = Panel.new()
	tip_panel.size = Vector2(500, 150)
	tip_panel.position = Vector2(390, 285)  # Center of 1280x720
	add_child(tip_panel)
	
	# Title
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(400, 295)
	title_label.size = Vector2(480, 30)
	add_child(title_label)
	
	# Text
	text_label = Label.new()
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.position = Vector2(400, 330)
	text_label.size = Vector2(480, 60)
	add_child(text_label)
	
	# OK button
	ok_button = Button.new()
	ok_button.text = "Got it!"
	ok_button.position = Vector2(590, 395)
	ok_button.size = Vector2(100, 30)
	ok_button.pressed.connect(_on_ok_pressed)
	add_child(ok_button)


func show_tip(trigger: String, custom_title: String = "", custom_text: String = "") -> void:
	## Show a specific tip
	# Find tip by trigger
	var tip: Dictionary = {}
	
	if custom_title != "" and custom_text != "":
		tip = {
			"title": custom_title,
			"text": custom_text,
			"position": "center",
			"duration": 5.0
		}
	else:
		for t in BATTLE_TIPS:
			if t["trigger"] == trigger:
				tip = t
				break
	
	if tip.is_empty():
		return
	
	current_tip = tip
	tip_active = true
	
	# Set content
	title_label.text = tip["title"]
	text_label.text = tip["text"]
	
	# Position based on setting
	_position_tip(tip.get("position", "center"))
	
	# Show UI
	tip_panel.visible = true
	title_label.visible = true
	text_label.visible = true
	ok_button.visible = true
	
	# Auto-hide after duration if not acknowledged
	var duration: float = tip.get("duration", 5.0)
	await get_tree().create_timer(duration).timeout
	
	if tip_active:
		hide_tip()


func _position_tip(position: String) -> void:
	## Position the tip panel
	match position:
		"center":
			tip_panel.position = Vector2(390, 285)
			title_label.position = Vector2(400, 295)
			text_label.position = Vector2(400, 330)
			ok_button.position = Vector2(590, 395)
		"top":
			tip_panel.position = Vector2(390, 50)
			title_label.position = Vector2(400, 60)
			text_label.position = Vector2(400, 95)
			ok_button.position = Vector2(590, 160)
		"bottom":
			tip_panel.position = Vector2(390, 520)
			title_label.position = Vector2(400, 530)
			text_label.position = Vector2(400, 565)
			ok_button.position = Vector2(590, 630)
		_:
			# Default center
			tip_panel.position = Vector2(390, 285)


func hide_tip() -> void:
	## Hide the tip overlay
	tip_active = false
	tip_panel.visible = false
	title_label.visible = false
	text_label.visible = false
	ok_button.visible = false


func _on_ok_pressed() -> void:
	## Acknowledge the tip
	if _audio_manager:
		_audio_manager.play_ui_click()
	
	hide_tip()
	tip_acknowledged.emit()


func is_tip_active() -> bool:
	return tip_active
