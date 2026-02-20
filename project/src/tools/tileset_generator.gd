extends Node
class_name TilesetGenerator
## TilesetGenerator — generates placeholder tilesets for arenas.

const TILE_SIZE: int = 32

# Arena themes
const THEMES: Dictionary = {
	"training_grounds": {
		"floor_base": Color(0.15, 0.18, 0.15),
		"floor_var1": Color(0.17, 0.20, 0.17),
		"floor_var2": Color(0.13, 0.16, 0.13),
		"wall": Color(0.4, 0.45, 0.4),
		"wall_highlight": Color(0.5, 0.55, 0.5),
		"spawn_player": Color(0.2, 0.6, 1.0),
		"spawn_enemy": Color(1.0, 0.3, 0.3),
		"grid": Color(0.25, 0.28, 0.25)
	},
	"scrapyard": {
		"floor_base": Color(0.25, 0.22, 0.18),
		"floor_var1": Color(0.28, 0.25, 0.20),
		"floor_var2": Color(0.22, 0.19, 0.15),
		"wall": Color(0.5, 0.45, 0.35),
		"wall_highlight": Color(0.6, 0.55, 0.45),
		"spawn_player": Color(0.2, 0.6, 1.0),
		"spawn_enemy": Color(1.0, 0.3, 0.3),
		"grid": Color(0.35, 0.30, 0.25)
	},
	"minefield": {
		"floor_base": Color(0.18, 0.20, 0.22),
		"floor_var1": Color(0.20, 0.22, 0.24),
		"floor_var2": Color(0.16, 0.18, 0.20),
		"wall": Color(0.45, 0.50, 0.55),
		"wall_highlight": Color(0.55, 0.60, 0.65),
		"spawn_player": Color(0.2, 0.6, 1.0),
		"spawn_enemy": Color(1.0, 0.3, 0.3),
		"grid": Color(0.30, 0.32, 0.35),
		"hazard": Color(0.9, 0.2, 0.2)
	},
	"chrometek": {
		"floor_base": Color(0.10, 0.12, 0.18),
		"floor_var1": Color(0.12, 0.14, 0.20),
		"floor_var2": Color(0.08, 0.10, 0.16),
		"wall": Color(0.25, 0.35, 0.50),
		"wall_highlight": Color(0.35, 0.45, 0.60),
		"spawn_player": Color(0.2, 0.8, 1.0),
		"spawn_enemy": Color(1.0, 0.4, 0.4),
		"grid": Color(0.20, 0.25, 0.35),
		"glow": Color(0.3, 0.7, 1.0)
	}
}


func generate_tileset(theme_name: String) -> Dictionary:
	## Generate a complete tileset for a theme
	if not THEMES.has(theme_name):
		push_error("TilesetGenerator: Unknown theme: " + theme_name)
		return {}
	
	var theme: Dictionary = THEMES[theme_name]
	var tileset: Dictionary = {}
	
	print("TilesetGenerator: Generating tileset for ", theme_name)
	
	# Floor tiles
	tileset["floor_0"] = generate_floor_tile(theme, 0)
	tileset["floor_1"] = generate_floor_tile(theme, 1)
	tileset["floor_2"] = generate_floor_tile(theme, 2)
	tileset["floor_grid"] = generate_grid_tile(theme)
	
	# Wall tiles
	tileset["wall_top"] = generate_wall_tile(theme, "top")
	tileset["wall_bottom"] = generate_wall_tile(theme, "bottom")
	tileset["wall_left"] = generate_wall_tile(theme, "left")
	tileset["wall_right"] = generate_wall_tile(theme, "right")
	tileset["wall_corner_tl"] = generate_corner_tile(theme, "tl")
	tileset["wall_corner_tr"] = generate_corner_tile(theme, "tr")
	tileset["wall_corner_bl"] = generate_corner_tile(theme, "bl")
	tileset["wall_corner_br"] = generate_corner_tile(theme, "br")
	
	# Spawn markers
	tileset["spawn_player"] = generate_spawn_tile(theme, true)
	tileset["spawn_enemy"] = generate_spawn_tile(theme, false)
	
	# Special tiles
	if theme_name == "minefield":
		tileset["hazard"] = generate_hazard_tile(theme)
	
	if theme_name == "chrometek":
		tileset["floor_glow"] = generate_glow_tile(theme)
	
	return tileset


func generate_floor_tile(theme: Dictionary, variation: int) -> Texture2D:
	## Generate a floor tile
	var image: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	
	var base_color: Color
	match variation:
		0: base_color = theme["floor_base"]
		1: base_color = theme["floor_var1"]
		2: base_color = theme["floor_var2"]
		_: base_color = theme["floor_base"]
	
	image.fill(base_color)
	
	# Add subtle noise
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			if randf() < 0.1:
				var noise: Color = base_color.lightened(randf_range(-0.05, 0.05))
				image.set_pixel(x, y, noise)
	
	return ImageTexture.create_from_image(image)


func generate_grid_tile(theme: Dictionary) -> Texture2D:
	## Generate a floor tile with grid lines
	var image: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var base_color: Color = theme["floor_base"]
	var grid_color: Color = theme["grid"]
	
	image.fill(base_color)
	
	# Draw grid lines
	for i in range(TILE_SIZE):
		# Horizontal line
		image.set_pixel(i, 0, grid_color)
		image.set_pixel(i, TILE_SIZE - 1, grid_color)
		# Vertical line
		image.set_pixel(0, i, grid_color)
		image.set_pixel(TILE_SIZE - 1, i, grid_color)
	
	return ImageTexture.create_from_image(image)


func generate_wall_tile(theme: Dictionary, side: String) -> Texture2D:
	## Generate a wall tile
	var image: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var wall_color: Color = theme["wall"]
	var highlight: Color = theme["wall_highlight"]
	
	image.fill(Color.TRANSPARENT)
	
	match side:
		"top":
			# Top wall
			for x in range(TILE_SIZE):
				for y in range(TILE_SIZE / 2, TILE_SIZE):
					var c: Color = wall_color
					if y == TILE_SIZE / 2:
						c = highlight
					image.set_pixel(x, y, c)
		"bottom":
			# Bottom wall
			for x in range(TILE_SIZE):
				for y in range(0, TILE_SIZE / 2):
					var c: Color = wall_color
					if y == TILE_SIZE / 2 - 1:
						c = highlight
					image.set_pixel(x, y, c)
		"left":
			# Left wall
			for x in range(TILE_SIZE / 2, TILE_SIZE):
				for y in range(TILE_SIZE):
					var c: Color = wall_color
					if x == TILE_SIZE / 2:
						c = highlight
					image.set_pixel(x, y, c)
		"right":
			# Right wall
			for x in range(0, TILE_SIZE / 2):
				for y in range(TILE_SIZE):
					var c: Color = wall_color
					if x == TILE_SIZE / 2 - 1:
						c = highlight
					image.set_pixel(x, y, c)
	
	return ImageTexture.create_from_image(image)


func generate_corner_tile(theme: Dictionary, corner: String) -> Texture2D:
	## Generate a corner tile
	var image: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var wall_color: Color = theme["wall"]
	var highlight: Color = theme["wall_highlight"]
	
	image.fill(Color.TRANSPARENT)
	
	# Draw corner based on type
	var cx: int = TILE_SIZE / 2
	var cy: int = TILE_SIZE / 2
	
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var dx: int = x - cx
			var dy: int = y - cy
			
			var should_fill: bool = false
			var is_highlight: bool = false
			
			match corner:
				"tl":  # Top-left
					should_fill = dx >= 0 or dy >= 0
					is_highlight = dx == 0 or dy == 0
				"tr":  # Top-right
					should_fill = dx < 0 or dy >= 0
					is_highlight = dx == -1 or dy == 0
				"bl":  # Bottom-left
					should_fill = dx >= 0 or dy < 0
					is_highlight = dx == 0 or dy == -1
				"br":  # Bottom-right
					should_fill = dx < 0 or dy < 0
					is_highlight = dx == -1 or dy == -1
			
			if should_fill:
				image.set_pixel(x, y, highlight if is_highlight else wall_color)
	
	return ImageTexture.create_from_image(image)


func generate_spawn_tile(theme: Dictionary, is_player: bool) -> Texture2D:
	## Generate a spawn marker tile
	var image: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var base_color: Color = theme["floor_base"]
	var spawn_color: Color = theme["spawn_player"] if is_player else theme["spawn_enemy"]
	
	image.fill(base_color)
	
	# Draw circle in center
	var center: Vector2i = Vector2i(TILE_SIZE / 2, TILE_SIZE / 2)
	var radius: int = TILE_SIZE / 3
	
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var dist: float = Vector2(x - center.x, y - center.y).length()
			if dist < radius:
				var alpha: float = 1.0 - (dist / radius)
				var c: Color = spawn_color
				c.a = alpha * 0.8
				image.set_pixel(x, y, c)
	
	# Draw icon
	var icon_color: Color = spawn_color.lightened(0.3)
	for i in range(-4, 5):
		image.set_pixel(center.x + i, center.y, icon_color)
		image.set_pixel(center.x, center.y + i, icon_color)
	
	return ImageTexture.create_from_image(image)


func generate_hazard_tile(theme: Dictionary) -> Texture2D:
	## Generate a hazard tile (minefield theme)
	var image: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var base_color: Color = theme["floor_base"]
	var hazard_color: Color = theme["hazard"]
	
	image.fill(base_color)
	
	# Draw warning stripes
	for i in range(0, TILE_SIZE * 2, 8):
		for j in range(4):
			var x: int = i + j - TILE_SIZE / 2
			if x >= 0 and x < TILE_SIZE:
				for y in range(TILE_SIZE):
					image.set_pixel(x, y, hazard_color)
	
	return ImageTexture.create_from_image(image)


func generate_glow_tile(theme: Dictionary) -> Texture2D:
	## Generate a glowing floor tile (chrometek theme)
	var image: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var base_color: Color = theme["floor_base"]
	var glow_color: Color = theme["glow"]
	
	image.fill(base_color)
	
	# Draw glow pattern
	var center: Vector2i = Vector2i(TILE_SIZE / 2, TILE_SIZE / 2)
	
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var dist: float = Vector2(x - center.x, y - center.y).length()
			if dist < TILE_SIZE / 2:
				var alpha: float = (1.0 - (dist / (TILE_SIZE / 2))) * 0.3
				var c: Color = glow_color
				c.a = alpha
				image.set_pixel(x, y, c)
	
	return ImageTexture.create_from_image(image)


func save_tileset(tileset: Dictionary, theme_name: String) -> void:
	## Save all tiles in a tileset
	var dir: String = "res://assets/tilesets/" + theme_name + "/"
	
	for tile_name in tileset:
		var texture: Texture2D = tileset[tile_name]
		var image: Image = texture.get_image()
		var path: String = dir + tile_name + ".png"
		image.save_png(path)
	
	print("TilesetGenerator: Saved tileset for ", theme_name)


func generate_all_mvp_tilesets() -> void:
	## Generate all MVP tilesets
	print("TilesetGenerator: Generating MVP tilesets...")
	
	# Generate Training Grounds (MVP)
	var training_grounds: Dictionary = generate_tileset("training_grounds")
	save_tileset(training_grounds, "training_grounds")
	
	print("TilesetGenerator: MVP tilesets generated!")
