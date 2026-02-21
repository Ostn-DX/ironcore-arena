extends Control
class_name MainMenuRedesigned
## Redesigned main menu matching Outhold aesthetic
## Dark navy background, long shadows, teal accents, connected nodes

signal start_campaign_pressed
signal start_arcade_pressed
signal continue_pressed
signal shop_pressed
signal builder_pressed
signal settings_pressed
signal quit_pressed

# Colors (matching Outhold)
const COLOR_BG: Color = Color("#1A1F2E")
const COLOR_PANEL: Color = Color("#252B3D")
const COLOR_CARD: Color = Color("#2D3548")
const COLOR_ACCENT: Color = Color("#00D4FF")
const COLOR_TEXT: Color = Color.WHITE
const COLOR_TEXT_DIM: Color = Color("#A0AEC0")

# Node network decoration
var _decoration_nodes: Array[Dictionary] = []
var _node_lines: Array[Line2D] = []

func _ready() -> void:
	_setup_background()
	_setup_decorative_nodes()
	_setup_title()
	_setup_menu_buttons()
	_setup_save_info()
	_animate_entry()

func _setup_background() -> void:
	# Main dark background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_BG
	add_child(bg)
	
	# Subtle grid pattern
	var grid: Control = _create_grid_pattern()
	add_child(grid)

func _create_grid_pattern() -> Control:
	var container: Control = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.modulate.a = 0.05
	
	# Draw faint dots
	var spacing: int = 40
	for x in range(0, 1280, spacing):
		for y in range(0, 720, spacing):
			var dot: ColorRect = ColorRect.new()
			dot.size = Vector2(2, 2)
			dot.position = Vector2(x, y)
			dot.color = COLOR_ACCENT
			container.add_child(dot)
	
	return container

func _setup_decorative_nodes() -> void:
	# Create floating decorative nodes (like Outhold skill tree)
	# These are visual only, not interactive
	
	var node_positions: Array[Vector2] = [
		Vector2(100, 100), Vector2(250, 180), Vector2(180, 300),
		Vector2(1100, 150), Vector2(1000, 280), Vector2(1150, 400),
		Vector2(150, 550), Vector2(300, 620),
		Vector2(1050, 600), Vector2(1180, 520)
	]
	
	for pos in node_positions:
		var is_active: bool = randf() > 0.5
		_create_decorative_node(pos, is_active)
	
	# Draw connections between nearby nodes
	_create_node_connections()

func _create_decorative_node(pos: Vector2, is_active: bool) -> void:
	var container: Control = Control.new()
	container.position = pos
	container.size = Vector2(48, 48)
	
	# Shadow
	var shadow: ColorRect = ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.2)
	shadow.position = Vector2(4, 4)
	shadow.size = Vector2(48, 48)
	shadow.z_index = -1
	container.add_child(shadow)
	
	# Node body
	var body: Panel = Panel.new()
	body.size = Vector2(48, 48)
	
	var style := StyleBoxFlat.new()
	if is_active:
		style.bg_color = COLOR_ACCENT
		style.border_color = COLOR_ACCENT.lightened(0.3)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	else:
		style.bg_color = COLOR_PANEL
		style.border_color = COLOR_TEXT_DIM.darkened(0.3)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
	
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	body.add_theme_stylebox_override("panel", style)
	container.add_child(body)
	
	# Icon (simple shapes)
	var icon: Control = _create_node_icon(is_active)
	icon.position = Vector2(12, 12)
	container.add_child(icon)
	
	add_child(container)
	
	# Store for connection drawing
	_decoration_nodes.append({
		"position": pos + Vector2(24, 24),
		"active": is_active,
		"container": container
	})
	
	# Subtle floating animation
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(container, "position:y", pos.y - 5, 2.0 + randf())
	tween.tween_property(container, "position:y", pos.y + 5, 2.0 + randf())

func _create_node_icon(is_active: bool) -> Control:
	var icon_color: Color = COLOR_BG if is_active else COLOR_TEXT_DIM
	
	# Simple geometric icon
	var icon: Control = Control.new()
	icon.size = Vector2(24, 24)
	
	var shape: ColorRect = ColorRect.new()
	shape.size = Vector2(24, 24)
	shape.color = icon_color
	icon.add_child(shape)
	
	return icon

func _create_node_connections() -> void:
	# Draw lines between nearby nodes
	var max_distance: float = 200.0
	
	for i in range(_decoration_nodes.size()):
		for j in range(i + 1, _decoration_nodes.size()):
			var node_a: Dictionary = _decoration_nodes[i]
			var node_b: Dictionary = _decoration_nodes[j]
			
			var dist: float = node_a["position"].distance_to(node_b["position"])
			if dist < max_distance:
				var line: Line2D = Line2D.new()
				line.points = [node_a["position"], node_b["position"]]
				line.width = 2
				
				# Color based on if both are active
				if node_a["active"] and node_b["active"]:
					line.default_color = COLOR_ACCENT
					line.modulate.a = 0.3
				else:
					line.default_color = COLOR_TEXT_DIM
					line.modulate.a = 0.1
				
				# Lines go behind nodes
				line.z_index = -2
				add_child(line)
				_node_lines.append(line)

func _setup_title() -> void:
	# Main title with long shadow
	var title_container: Control = Control.new()
	title_container.position = Vector2(640, 80)
	title_container.size = Vector2(0, 0)
	add_child(title_container)
	
	# Title shadow (offset)
	var shadow: Label = Label.new()
	shadow.text = "IRONCORE"
	shadow.add_theme_font_size_override("font_size", 72)
	shadow.modulate = Color(0, 0, 0, 0.3)
	shadow.position = Vector2(4, 4)
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(shadow)
	
	# Title text
	var title: Label = Label.new()
	title.text = "IRONCORE"
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = COLOR_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(title)
	
	# Subtitle
	var subtitle: Label = Label.new()
	subtitle.text = "ARENA"
	subtitle.add_theme_font_size_override("font_size", 36)
	subtitle.modulate = COLOR_ACCENT
	subtitle.position = Vector2(0, 70)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(subtitle)

func _setup_menu_buttons() -> void:
	# Main button container - centered
	var container: VBoxContainer = VBoxContainer.new()
	container.position = Vector2(540, 220)
	container.size = Vector2(200, 400)
	container.add_theme_constant_override("separation", 16)
	add_child(container)
	
	# Continue button (if save exists)
	if _has_save_file():
		var continue_btn: UIButton = _create_menu_button("Continue", UIButton.ButtonStyle.PRIMARY)
		continue_btn.pressed.connect(_on_continue)
		container.add_child(continue_btn)
	
	# New Campaign
	var campaign_btn: UIButton = _create_menu_button("New Campaign", UIButton.ButtonStyle.SECONDARY)
	campaign_btn.pressed.connect(_on_new_campaign)
	container.add_child(campaign_btn)
	
	# Arcade Mode
	var arcade_btn: UIButton = _create_menu_button("Arcade Mode", UIButton.ButtonStyle.SECONDARY)
	arcade_btn.pressed.connect(_on_arcade)
	container.add_child(arcade_btn)
	
	# Separator
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	container.add_child(spacer)
	
	# Bot Builder
	var builder_btn: UIButton = _create_menu_button("Bot Builder", UIButton.ButtonStyle.GHOST)
	builder_btn.pressed.connect(_on_builder)
	container.add_child(builder_btn)
	
	# Shop
	var shop_btn: UIButton = _create_menu_button("Component Shop", UIButton.ButtonStyle.GHOST)
	shop_btn.pressed.connect(_on_shop)
	container.add_child(shop_btn)
	
	# Separator
	var spacer2: Control = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 16)
	container.add_child(spacer2)
	
	# Settings
	var settings_btn: UIButton = _create_menu_button("Settings", UIButton.ButtonStyle.GHOST)
	settings_btn.pressed.connect(_on_settings)
	container.add_child(settings_btn)
	
	# Quit
	var quit_btn: UIButton = _create_menu_button("Quit", UIButton.ButtonStyle.DANGER)
	quit_btn.pressed.connect(_on_quit)
	container.add_child(quit_btn)

func _create_menu_button(text: String, style: UIButton.ButtonStyle) -> UIButton:
	var btn: UIButton = UIButton.new()
	btn.text = text
	btn.button_style = style
	btn.custom_minimum_size = Vector2(200, 48)
	btn.add_theme_font_size_override("font_size", 18)
	return btn

func _setup_save_info() -> void:
	if not _has_save_file():
		return
	
	# Show save info at bottom
	var info_label: Label = Label.new()
	info_label.text = _get_save_summary()
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.modulate = COLOR_TEXT_DIM
	info_label.position = Vector2(20, 680)
	add_child(info_label)

func _has_save_file() -> bool:
	return FileAccess.file_exists("user://ironcore_save.json")

func _get_save_summary() -> String:
	if not GameState:
		return ""
	
	return "Tier %d | %d CR | %d arenas" % [
		GameState.current_tier + 1,
		GameState.credits,
		GameState.completed_arenas.size()
	]

func _animate_entry() -> void:
	# Fade in animation
	modulate.a = 0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

# Button handlers
func _on_continue() -> void:
	continue_pressed.emit()

func _on_new_campaign() -> void:
	start_campaign_pressed.emit()

func _on_arcade() -> void:
	start_arcade_pressed.emit()

func _on_shop() -> void:
	shop_pressed.emit()

func _on_builder() -> void:
	builder_pressed.emit()

func _on_settings() -> void:
	settings_pressed.emit()

func _on_quit() -> void:
	quit_pressed.emit()
	get_tree().quit()

func show_menu() -> void:
	visible = true
	_animate_entry()

func hide_menu() -> void:
	visible = false
