extends RefCounted
class_name UIThemeGenerator
## Generates UI themes and textures for the game

const COLOR_BG: Color = Color("#1A1F2E")
const COLOR_PANEL: Color = Color("#252B3D")
const COLOR_ACCENT: Color = Color("#00D4FF")
const COLOR_TEXT: Color = Color.WHITE


func generate_theme() -> Theme:
	## Generate a complete UI theme
	var theme := Theme.new()
	
	# Button styles
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = COLOR_PANEL
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	
	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = COLOR_PANEL.lightened(0.1)
	
	var btn_pressed := btn_normal.duplicate()
	btn_pressed.bg_color = COLOR_PANEL.darkened(0.1)
	
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	
	# Panel styles
	var panel := StyleBoxFlat.new()
	panel.bg_color = COLOR_PANEL
	panel.corner_radius_top_left = 12
	panel.corner_radius_top_right = 12
	panel.corner_radius_bottom_left = 12
	panel.corner_radius_bottom_right = 12
	
	theme.set_stylebox("panel", "Panel", panel)
	
	return theme


func generate_menu_background() -> Texture2D:
	## Generate menu background texture
	var image := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	image.fill(COLOR_BG)
	
	# Add some visual interest - gradient
	for y in range(720):
		var t: float = float(y) / 720.0
		var color: Color = COLOR_BG.lerp(COLOR_PANEL.darkened(0.5), t * 0.3)
		for x in range(1280):
			image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)


func generate_button_texture(width: int, height: int, color: Color) -> Texture2D:
	## Generate a button texture
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
