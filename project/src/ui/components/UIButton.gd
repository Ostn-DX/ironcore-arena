extends Button
class_name UIButton
## Outhold-style button with long shadow
## Flat design, rounded corners, glow on hover

enum ButtonStyle {
	PRIMARY,
	SECONDARY,
	DANGER,
	SUCCESS,
	GHOST
}

@export var button_style: ButtonStyle = ButtonStyle.PRIMARY
@export var corner_radius: int = 8
@export var shadow_offset: Vector2 = Vector2(4, 4)

var _colors: Dictionary = {
	ButtonStyle.PRIMARY: Color("#2D3548"),
	ButtonStyle.SECONDARY: Color("#252B3D"),
	ButtonStyle.DANGER: Color("#FF5A5A"),
	ButtonStyle.SUCCESS: Color("#06D6A0"),
	ButtonStyle.GHOST: Color(0, 0, 0, 0)
}

var _accent_colors: Dictionary = {
	ButtonStyle.PRIMARY: Color("#00D4FF"),
	ButtonStyle.SECONDARY: Color("#A0AEC0"),
	ButtonStyle.DANGER: Color("#FF5A5A"),
	ButtonStyle.SUCCESS: Color("#06D6A0"),
	ButtonStyle.GHOST: Color("#00D4FF")
}

var _shadow_rect: ColorRect
var _is_pressed_down: bool = false

func _ready() -> void:
	flat = true
	_setup_shadow()
	_update_style()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _setup_shadow() -> void:
	_shadow_rect = ColorRect.new()
	_shadow_rect.name = "Shadow"
	_shadow_rect.color = Color(0, 0, 0, 0.25)
	_shadow_rect.position = shadow_offset
	_shadow_rect.size = size
	_shadow_rect.z_index = -1
	add_child(_shadow_rect)

func _update_style() -> void:
	var base_color: Color = _colors[button_style]
	var accent: Color = _accent_colors[button_style]
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = base_color
	normal_style.corner_radius_top_left = corner_radius
	normal_style.corner_radius_top_right = corner_radius
	normal_style.corner_radius_bottom_left = corner_radius
	normal_style.corner_radius_bottom_right = corner_radius
	if button_style == ButtonStyle.GHOST:
		normal_style.border_color = accent
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
	add_theme_stylebox_override("normal", normal_style)
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = base_color.lightened(0.15)
	add_theme_stylebox_override("hover", hover_style)
	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = base_color.darkened(0.1)
	add_theme_stylebox_override("pressed", pressed_style)
	var text_color: Color = Color.WHITE
	if button_style == ButtonStyle.SUCCESS or button_style == ButtonStyle.DANGER:
		text_color = Color("#1A1F2E")
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_hover_color", text_color.lightened(0.2))
	add_theme_color_override("font_pressed_color", text_color.darkened(0.1))

func _on_mouse_entered() -> void:
	if _shadow_rect and not _is_pressed_down:
		var tween: Tween = create_tween()
		tween.tween_property(_shadow_rect, "position", shadow_offset * 0.7, 0.1)
		tween.parallel().tween_property(_shadow_rect, "modulate:a", 0.15, 0.1)

func _on_mouse_exited() -> void:
	if _shadow_rect and not _is_pressed_down:
		var tween: Tween = create_tween()
		tween.tween_property(_shadow_rect, "position", shadow_offset, 0.1)
		tween.parallel().tween_property(_shadow_rect, "modulate:a", 0.25, 0.1)

func _on_button_down() -> void:
	_is_pressed_down = true
	if _shadow_rect:
		var tween: Tween = create_tween()
		tween.tween_property(_shadow_rect, "position", Vector2.ZERO, 0.05)
		tween.parallel().tween_property(_shadow_rect, "modulate:a", 0, 0.05)

func _on_button_up() -> void:
	_is_pressed_down = false
	if _shadow_rect:
		var tween: Tween = create_tween()
		tween.tween_property(_shadow_rect, "position", shadow_offset, 0.1)
		tween.parallel().tween_property(_shadow_rect, "modulate:a", 0.25, 0.1)

func _resized() -> void:
	if _shadow_rect:
		_shadow_rect.size = size
