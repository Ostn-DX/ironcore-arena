extends Control
class_name AudioSettingsScreen
## AudioSettingsScreen — UI for adjusting audio settings.

signal back_pressed

@onready var _audio_manager = get_node("/root/AudioManager")

# Volume sliders
var master_slider: HSlider = null
var sfx_slider: HSlider = null
var music_slider: HSlider = null
var ui_slider: HSlider = null

# Value labels
var master_value: Label = null
var sfx_value: Label = null
var music_value: Label = null
var ui_value: Label = null

# Mute checkbox
var mute_checkbox: CheckBox = null


func _ready() -> void:
	_setup_ui()
	_load_current_settings()


func _setup_ui() -> void:
	## Setup the audio settings UI
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	add_child(bg)
	
	# Title
	var title: Label = Label.new()
	title.text = "AUDIO SETTINGS"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(440, 50)
	title.size = Vector2(400, 50)
	add_child(title)
	
	# Settings container
	var container: VBoxContainer = VBoxContainer.new()
	container.position = Vector2(340, 150)
	container.size = Vector2(600, 400)
	container.add_theme_constant_override("separation", 30)
	add_child(container)
	
	# Master volume
	master_slider = _create_volume_slider("Master Volume", container)
	master_slider.value_changed.connect(_on_master_changed)
	master_value = _create_value_label(container, master_slider)
	
	# SFX volume
	sfx_slider = _create_volume_slider("Sound Effects", container)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	sfx_value = _create_value_label(container, sfx_slider)
	
	# Music volume
	music_slider = _create_volume_slider("Music", container)
	music_slider.value_changed.connect(_on_music_changed)
	music_value = _create_value_label(container, music_slider)
	
	# UI volume
	ui_slider = _create_volume_slider("UI Sounds", container)
	ui_slider.value_changed.connect(_on_ui_changed)
	ui_value = _create_value_label(container, ui_slider)
	
	# Separator
	var separator: Control = Control.new()
	separator.custom_minimum_size = Vector2(0, 20)
	container.add_child(separator)
	
	# Mute checkbox
	mute_checkbox = CheckBox.new()
	mute_checkbox.text = "Mute All Audio"
	mute_checkbox.toggled.connect(_on_mute_toggled)
	container.add_child(mute_checkbox)
	
	# Test sounds button
	var test_btn: Button = Button.new()
	test_btn.text = "Test Sounds"
	test_btn.pressed.connect(_on_test_sounds)
	container.add_child(test_btn)
	
	# Back button
	var back_btn: Button = Button.new()
	back_btn.text = "Back"
	back_btn.position = Vector2(590, 620)
	back_btn.size = Vector2(100, 40)
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)


func _create_volume_slider(label_text: String, parent: Node) -> HSlider:
	## Create a volume slider row
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	
	var label: Label = Label.new()
	label.text = label_text
	label.size = Vector2(150, 30)
	row.add_child(label)
	
	var slider: HSlider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0
	slider.max_value = 100
	slider.value = 100
	slider.tick_count = 11
	slider.ticks_on_borders = true
	row.add_child(slider)
	
	return slider


func _create_value_label(parent: Node, slider: HSlider) -> Label:
	## Create a value display label
	var label: Label = Label.new()
	label.text = "100%"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.size = Vector2(60, 30)
	label.modulate = Color(0.7, 0.7, 0.7)
	
	# Add to slider's parent (the row)
	slider.get_parent().add_child(label)
	
	return label


func _load_current_settings() -> void:
	## Load current audio settings
	# Set slider values (convert 0-1 to 0-100)
	master_slider.value = _audio_manager.master_volume * 100
	sfx_slider.value = _audio_manager.sfx_volume * 100
	music_slider.value = _audio_manager.music_volume * 100
	ui_slider.value = _audio_manager.ui_volume * 100
	
	_update_value_labels()


func _update_value_labels() -> void:
	## Update value display labels
	master_value.text = "%d%%" % master_slider.value
	sfx_value.text = "%d%%" % sfx_slider.value
	music_value.text = "%d%%" % music_slider.value
	ui_value.text = "%d%%" % ui_slider.value


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_master_changed(value: float) -> void:
	var volume: float = value / 100.0
	
	_audio_manager.set_master_volume(volume)
	master_value.text = "%d%%" % value


func _on_sfx_changed(value: float) -> void:
	var volume: float = value / 100.0
	
	_audio_manager.set_sfx_volume(volume)
	sfx_value.text = "%d%%" % value


func _on_music_changed(value: float) -> void:
	var volume: float = value / 100.0
	
	_audio_manager.set_music_volume(volume)
	music_value.text = "%d%%" % value


func _on_ui_changed(value: float) -> void:
	var volume: float = value / 100.0
	
	_audio_manager.set_ui_volume(volume)
	ui_value.text = "%d%%" % value


func _on_mute_toggled(muted: bool) -> void:
	_audio_manager.mute_all(muted)


func _on_test_sounds() -> void:
	## Play test sounds
	
		_audio_manager.play_ui_click()
		await get_tree().create_timer(0.3).timeout
		_audio_manager.play_ui_confirm()
		await get_tree().create_timer(0.3).timeout
		_audio_manager.play_weapon_fire()


func _on_back() -> void:
	## Save settings and go back
	
		_audio_manager.play_ui_cancel()
	back_pressed.emit()
