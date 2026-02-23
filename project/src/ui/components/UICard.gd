extends Control
class_name UICard
## Reusable card component with Outhold-style long shadow
## Flat design with 6px offset shadow

@export var card_color: Color = Color("#2D3548")
@export var shadow_color: Color = Color(0, 0, 0, 0.25)
@export var corner_radius: int = 8
@export var shadow_offset: Vector2 = Vector2(6, 6)
@export var show_shadow: bool = true

@export var border_color: Color = Color("#00D4FF")
@export var border_width: int = 0  # 0 = no border

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_visuals()

@export var is_hovered: bool = false:
	set(value):
		is_hovered = value
		_update_visuals()

var _shadow_rect: ColorRect
var _bg_panel: Panel
var _border_panel: Panel
var _content_container: Control

func _ready() -> void:
	_setup_shadow()
	_setup_background()
	_setup_content()
	_update_visuals()

func _setup_shadow() -> void:
	if not show_shadow:
		return
	
	_shadow_rect = ColorRect.new()
	_shadow_rect.name = "Shadow"
	_shadow_rect.color = shadow_color
	_shadow_rect.position = shadow_offset
	add_child(_shadow_rect)
	
	# Shadow goes behind everything
	_shadow_rect.z_index = -1

func _setup_background() -> void:
	_bg_panel = Panel.new()
	_bg_panel.name = "Background"
	_bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_panel)
	
	# Border panel (for selection highlight)
	if border_width > 0:
		_border_panel = Panel.new()
		_border_panel.name = "Border"
		_border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_border_panel.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_border_panel)
	
	_update_styleboxes()

func _setup_content() -> void:
	_content_container = Control.new()
	_content_container.name = "Content"
	_content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_container.margin_left = 12
	_content_container.margin_top = 12
	_content_container.margin_right = -12
	_content_container.margin_bottom = -12
	add_child(_content_container)

func _update_styleboxes() -> void:
	# Background style
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = card_color
	bg_style.corner_radius_top_left = corner_radius
	bg_style.corner_radius_top_right = corner_radius
	bg_style.corner_radius_bottom_left = corner_radius
	bg_style.corner_radius_bottom_right = corner_radius
	_bg_panel.add_theme_stylebox_override("panel", bg_style)
	
	# Border style
	if _border_panel and border_width > 0:
		var border_style := StyleBoxFlat.new()
		border_style.bg_color = Color(0, 0, 0, 0)  # Transparent fill
		border_style.border_color = border_color if is_selected else Color(0, 0, 0, 0)
		border_style.border_width_left = border_width
		border_style.border_width_top = border_width
		border_style.border_width_right = border_width
		border_style.border_width_bottom = border_width
		border_style.corner_radius_top_left = corner_radius
		border_style.corner_radius_top_right = corner_radius
		border_style.corner_radius_bottom_left = corner_radius
		border_style.corner_radius_bottom_right = corner_radius
		_border_panel.add_theme_stylebox_override("panel", border_style)

func _update_visuals() -> void:
	if _border_panel:
		_update_styleboxes()
	
	# Hover effect - slightly lighter
	if _bg_panel:
		var style: StyleBoxFlat = _bg_panel.get_theme_stylebox("panel").duplicate()
		if is_hovered:
			style.bg_color = card_color.lightened(0.1)
		else:
			style.bg_color = card_color
		_bg_panel.add_theme_stylebox_override("panel", style)

func set_content(node: Control) -> void:
	## Add a child node to the content area
	for child in _content_container.get_children():
		child.queue_free()
	_content_container.add_child(node)

func set_size_custom(size: Vector2) -> void:
	custom_minimum_size = size
	size = size
	
	if _shadow_rect:
		_shadow_rect.size = size

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_clicked()

func _on_clicked() -> void:
	## Override or connect to signal
	pass

func pulse_animation() -> void:
	## Subtle pulse for attention
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
