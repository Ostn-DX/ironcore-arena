extends Node
class_name UIThemeGenerator
## UIThemeGenerator — generates UI themes and styles for the game.

# Color palette
const COLORS: Dictionary = {
	"background_dark": Color(0.05, 0.05, 0.08),
	"background_panel": Color(0.08, 0.08, 0.12),
	"background_hover": Color(0.12, 0.12, 0.18),
	
	"primary": Color(0.2, 0.6, 1.0),       # Blue
	"primary_hover": Color(0.3, 0.7, 1.0),
	"primary_pressed": Color(0.1, 0.5, 0.9),
	
	"secondary": Color(0.6, 0.6, 0.65),    # Gray
	"secondary_hover": Color(0.7, 0.7, 0.75),
	
	"accent": Color(1.0, 0.84, 0.0),       # Gold
	"success": Color(0.2, 0.9, 0.2),       # Green
	"danger": Color(0.9, 0.2, 0.2),        # Red
	"warning": Color(0.9, 0.7, 0.2),       # Yellow
	
	"text_primary": Color(0.95, 0.95, 0.95),
	"text_secondary": Color(0.7, 0.7, 0.7),
	"text_disabled": Color(0.4, 0.4, 0.4),
	
	"border": Color(0.25, 0.25, 0.3),
	"border_highlight": Color(0.4, 0.4, 0.5)
}

# Font sizes
const FONT_SIZES: Dictionary = {
	"title": 48,
	"subtitle": 32,
	"heading": 24,
	"body": 16,
	"small": 12,
	"button": 18
}


func generate_theme() -> Theme:
	## Generate a complete UI theme
	var theme: Theme = Theme.new()
	
	# Set up default font (will use system font if custom not available)
	var default_font: Font = SystemFont.new()
	theme.default_font = default_font
	
	# Button styles
	_setup_button_styles(theme)
	
	# Panel styles
	_setup_panel_styles(theme)
	
	# Label styles
	_setup_label_styles(theme)
	
	# Slider styles
	_setup_slider_styles(theme)
	
	# ProgressBar styles
	_setup_progress_styles(theme)
	
	# LineEdit styles
	_setup_line_edit_styles(theme)
	
	print("UIThemeGenerator: Theme generated")
	return theme


func _setup_button_styles(theme: Theme) -> void:
	## Setup button styles
	
	# Primary button (default)
	var btn_normal: StyleBoxFlat = StyleBoxFlat.new()
	btn_normal.bg_color = COLORS["primary"]
	btn_normal.border_width_left = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = COLORS["border_highlight"]
	btn_normal.corner_radius_top_left = 4
	btn_normal.corner_radius_top_right = 4
	btn_normal.corner_radius_bottom_left = 4
	btn_normal.corner_radius_bottom_right = 4
	btn_normal.shadow_size = 2
	btn_normal.shadow_color = Color(0, 0, 0, 0.3)
	
	var btn_hover: StyleBoxFlat = btn_normal.duplicate()
	btn_hover.bg_color = COLORS["primary_hover"]
	
	var btn_pressed: StyleBoxFlat = btn_normal.duplicate()
	btn_pressed.bg_color = COLORS["primary_pressed"]
	btn_pressed.shadow_size = 0
	
	var btn_disabled: StyleBoxFlat = btn_normal.duplicate()
	btn_disabled.bg_color = COLORS["secondary"]
	btn_disabled.border_color = COLORS["border"]
	
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	
	theme.set_color("font_color", "Button", COLORS["text_primary"])
	theme.set_color("font_hover_color", "Button", COLORS["text_primary"])
	theme.set_color("font_pressed_color", "Button", COLORS["text_primary"])
	theme.set_color("font_disabled_color", "Button", COLORS["text_disabled"])
	
	# Secondary button style
	var btn_secondary: StyleBoxFlat = btn_normal.duplicate()
	btn_secondary.bg_color = COLORS["secondary"]
	
	theme.set_stylebox("normal", "ButtonSecondary", btn_secondary)


func _setup_panel_styles(theme: Theme) -> void:
	## Setup panel styles
	
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = COLORS["background_panel"]
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = COLORS["border"]
	panel.corner_radius_top_left = 6
	panel.corner_radius_top_right = 6
	panel.corner_radius_bottom_left = 6
	panel.corner_radius_bottom_right = 6
	panel.shadow_size = 4
	panel.shadow_color = Color(0, 0, 0, 0.4)
	
	theme.set_stylebox("panel", "Panel", panel)
	
	# PanelContainer uses same style
	theme.set_stylebox("panel", "PanelContainer", panel)


func _setup_label_styles(theme: Theme) -> void:
	## Setup label styles
	
	theme.set_color("font_color", "Label", COLORS["text_primary"])
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	
	# Title label style (large)
	var title_font: FontVariation = FontVariation.new()
	title_font.variation_embolden = 1.0
	theme.set_font("font", "LabelTitle", title_font)
	theme.set_font_size("font_size", "LabelTitle", FONT_SIZES["title"])


func _setup_slider_styles(theme: Theme) -> void:
	## Setup slider styles
	
	var slider_bg: StyleBoxFlat = StyleBoxFlat.new()
	slider_bg.bg_color = COLORS["background_panel"]
	slider_bg.border_color = COLORS["border"]
	slider_bg.border_width_left = 1
	slider_bg.border_width_top = 1
	slider_bg.border_width_right = 1
	slider_bg.border_width_bottom = 1
	
	theme.set_stylebox("slider", "HSlider", slider_bg)
	
	var slider_grabber: StyleBoxFlat = StyleBoxFlat.new()
	slider_grabber.bg_color = COLORS["primary"]
	slider_grabber.corner_radius_top_left = 4
	slider_grabber.corner_radius_top_right = 4
	slider_grabber.corner_radius_bottom_left = 4
	slider_grabber.corner_radius_bottom_right = 4
	
	theme.set_stylebox("grabber", "HSlider", slider_grabber)
	theme.set_stylebox("grabber_highlight", "HSlider", slider_grabber)


func _setup_progress_styles(theme: Theme) -> void:
	## Setup progress bar styles
	
	var progress_bg: StyleBoxFlat = StyleBoxFlat.new()
	progress_bg.bg_color = COLORS["background_panel"]
	progress_bg.corner_radius_top_left = 3
	progress_bg.corner_radius_top_right = 3
	progress_bg.corner_radius_bottom_left = 3
	progress_bg.corner_radius_bottom_right = 3
	
	theme.set_stylebox("bg", "ProgressBar", progress_bg)
	
	var progress_fill: StyleBoxFlat = StyleBoxFlat.new()
	progress_fill.bg_color = COLORS["primary"]
	progress_fill.corner_radius_top_left = 3
	progress_fill.corner_radius_top_right = 3
	progress_fill.corner_radius_bottom_left = 3
	progress_fill.corner_radius_bottom_right = 3
	
	theme.set_stylebox("fill", "ProgressBar", progress_fill)


func _setup_line_edit_styles(theme: Theme) -> void:
	## Setup line edit styles
	
	var line_edit: StyleBoxFlat = StyleBoxFlat.new()
	line_edit.bg_color = COLORS["background_dark"]
	line_edit.border_color = COLORS["border"]
	line_edit.border_width_left = 1
	line_edit.border_width_top = 1
	line_edit.border_width_right = 1
	line_edit.border_width_bottom = 1
	line_edit.corner_radius_top_left = 3
	line_edit.corner_radius_top_right = 3
	line_edit.corner_radius_bottom_left = 3
	line_edit.corner_radius_bottom_right = 3
	
	theme.set_stylebox("normal", "LineEdit", line_edit)
	
	var line_edit_focus: StyleBoxFlat = line_edit.duplicate()
	line_edit_focus.border_color = COLORS["primary"]
	line_edit_focus.border_width_left = 2
	line_edit_focus.border_width_top = 2
	line_edit_focus.border_width_right = 2
	line_edit_focus.border_width_bottom = 2
	
	theme.set_stylebox("focus", "LineEdit", line_edit_focus)
	
	theme.set_color("font_color", "LineEdit", COLORS["text_primary"])
	theme.set_color("font_placeholder_color", "LineEdit", COLORS["text_secondary"])


# ============================================================================
# BACKGROUND GENERATION
# ============================================================================

func generate_menu_background(width: int = 1280, height: int = 720) -> Texture2D:
	## Generate a stylized menu background
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Fill with dark gradient
	for y in range(height):
		var t: float = float(y) / float(height)
		var color: Color = COLORS["background_dark"].lerp(COLORS["background_panel"], t * 0.5)
		for x in range(width):
			image.set_pixel(x, y, color)
	
	# Draw grid pattern
	var grid_color: Color = COLORS["border"]
	grid_color.a = 0.3
	
	var grid_size: int = 40
	for x in range(0, width, grid_size):
		for y in range(height):
			image.set_pixel(x, y, grid_color)
	
	for y in range(0, height, grid_size):
		for x in range(width):
			image.set_pixel(x, y, grid_color)
	
	# Draw some decorative hexagons
	_draw_hexagon_pattern(image, width, height)
	
	# Add vignette
	_apply_vignette(image, width, height)
	
	return ImageTexture.create_from_image(image)


func _draw_hexagon_pattern(image: Image, width: int, height: int) -> void:
	## Draw hexagonal pattern
	var hex_color: Color = COLORS["primary"]
	hex_color.a = 0.05
	
	var hex_size: int = 60
	var hex_height: int = int(hex_size * sqrt(3))
	
	for row in range(-1, height / hex_height + 2):
		for col in range(-1, width / (hex_size * 1.5) + 2):
			var x: float = col * hex_size * 1.5
			var y: float = row * hex_height + (col % 2) * hex_height / 2
			
			_draw_hexagon(image, int(x), int(y), hex_size, hex_color)


func _draw_hexagon(image: Image, cx: int, cy: int, size: int, color: Color) -> void:
	## Draw a single hexagon
	for x in range(cx - size, cx + size):
		for y in range(cy - size, cy + size):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				var dx: float = x - cx
				var dy: float = y - cy
				
				# Hexagon distance
				var dist: float = (abs(dx) + abs(dx * 0.5) + abs(dy)) / size
				if dist < 1.0 and dist > 0.9:
					image.set_pixel(x, y, color)


func _apply_vignette(image: Image, width: int, height: int) -> void:
	## Apply vignette effect
	var center_x: float = width / 2.0
	var center_y: float = height / 2.0
	var max_dist: float = sqrt(center_x * center_x + center_y * center_y)
	
	for x in range(width):
		for y in range(height):
			var dx: float = x - center_x
			var dy: float = y - center_y
			var dist: float = sqrt(dx * dx + dy * dy)
			
			var vignette: float = 1.0 - (dist / max_dist) * 0.4
			var pixel: Color = image.get_pixel(x, y)
			pixel = pixel.darkened((1.0 - vignette) * 0.5)
			image.set_pixel(x, y, pixel)


func save_background(texture: Texture2D, path: String) -> void:
	## Save background to file
	var image: Image = texture.get_image()
	image.save_png(path)
	print("UIThemeGenerator: Saved background to ", path)


# ============================================================================
# UTILITY
# ============================================================================

func apply_theme_to_control(control: Control) -> void:
	## Apply the generated theme to a control
	var theme: Theme = generate_theme()
	control.theme = theme
