extends Node
class_name SpriteGenerator
## SpriteGenerator - generates placeholder sprites for MVP.
## Creates simple geometric bot sprites programmatically.

const SPRITE_SIZE: int = 64

# Chassis colors by tier
const TIER_COLORS: Dictionary = {
	0: Color(0.6, 0.6, 0.65),  # Gray (T1)
	1: Color(0.2, 0.7, 0.9),   # Cyan (T2)
	2: Color(1.0, 0.5, 0.1),   # Orange (T3)
	3: Color(0.7, 0.3, 0.9)    # Purple (T4)
}

# Team colors
const TEAM_PLAYER: Color = Color(0.2, 0.6, 1.0)
const TEAM_ENEMY: Color = Color(1.0, 0.3, 0.3)


func _ready() -> void:
	pass


# ============================================================================
# CHASSIS SPRITES
# ============================================================================

func generate_chassis_sprite(chassis_type: String, tier: int = 0) -> Texture2D:
	## Generate a chassis sprite
	var image: Image = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var base_color: Color = TIER_COLORS.get(tier, TIER_COLORS[0])
	var size: int = _get_chassis_size(chassis_type)
	
	var center: Vector2i = Vector2i(SPRITE_SIZE / 2, SPRITE_SIZE / 2)
	var half_size: int = size / 2
	
	# Draw base shape
	for x in range(center.x - half_size, center.x + half_size):
		for y in range(center.y - half_size, center.y + half_size):
			if _is_in_chassis_shape(x - center.x, y - center.y, chassis_type, half_size):
				# Base color
				var pixel_color: Color = base_color
				
				# Add shading
				var dist_from_center: float = Vector2(x - center.x, y - center.y).length()
				if dist_from_center > half_size * 0.7:
					pixel_color = pixel_color.darkened(0.2)
				elif dist_from_center < half_size * 0.3:
					pixel_color = pixel_color.lightened(0.1)
				
				image.set_pixel(x, y, pixel_color)
	
	# Draw detail lines
	_draw_chassis_details(image, chassis_type, center, half_size, base_color)
	
	return ImageTexture.create_from_image(image)


func _get_chassis_size(chassis_type: String) -> int:
	match chassis_type:
		"scout": return 28
		"fighter": return 36
		"tank": return 44
		_: return 32


func _is_in_chassis_shape(local_x: int, local_y: int, chassis_type: String, half_size: int) -> bool:
	## Check if pixel is inside chassis shape
	match chassis_type:
		"scout":
			# Diamond shape
			return abs(local_x) + abs(local_y) < half_size
		"fighter":
			# Circle
			return Vector2(local_x, local_y).length() < half_size
		"tank":
			# Square with rounded corners
			return abs(local_x) < half_size and abs(local_y) < half_size * 0.8
		_:
			return Vector2(local_x, local_y).length() < half_size


func _draw_chassis_details(image: Image, chassis_type: String, center: Vector2i, half_size: int, color: Color) -> void:
	## Draw detail lines on chassis
	var detail_color: Color = color.lightened(0.3)
	
	match chassis_type:
		"scout":
			# Speed lines
			for i in range(3):
				var y: int = center.y - 4 + i * 4
				for x in range(center.x - half_size + 4, center.x + half_size - 4):
					if x % 4 == 0:
						image.set_pixel(x, y, detail_color)
		"fighter":
			# Center circle
			_draw_circle(image, center, half_size / 3, detail_color)
		"tank":
			# Armor plates
			for x in range(center.x - half_size + 4, center.x + half_size - 4, 8):
				for y in range(center.y - half_size + 4, center.y + half_size - 4, 8):
					image.set_pixel(x, y, detail_color)


# ============================================================================
# WEAPON SPRITES
# ============================================================================

func generate_weapon_sprite(weapon_type: String, tier: int = 0) -> Texture2D:
	## Generate a weapon sprite
	var image: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var base_color: Color = TIER_COLORS.get(tier, TIER_COLORS[0])
	
	match weapon_type:
		"machine_gun":
			_draw_machine_gun(image, base_color)
		"cannon":
			_draw_cannon(image, base_color)
		"launcher":
			_draw_launcher(image, base_color)
		"beam":
			_draw_beam(image, base_color)
		"sniper":
			_draw_sniper(image, base_color)
		"shotgun":
			_draw_shotgun(image, base_color)
		_:
			_draw_machine_gun(image, base_color)
	
	return ImageTexture.create_from_image(image)


func _draw_machine_gun(image: Image, color: Color) -> void:
	## Draw machine gun
	var dark: Color = color.darkened(0.3)
	var light: Color = color.lightened(0.2)
	
	# Barrel
	for x in range(16, 28):
		for y in range(14, 18):
			image.set_pixel(x, y, color)
	
	# Muzzle
	for x in range(28, 30):
		for y in range(13, 19):
			image.set_pixel(x, y, light)
	
	# Body
	for x in range(8, 16):
		for y in range(12, 20):
			image.set_pixel(x, y, dark)
	
	# Handle
	for x in range(4, 10):
		for y in range(18, 24):
			image.set_pixel(x, y, color)


func _draw_cannon(image: Image, color: Color) -> void:
	## Draw cannon
	var dark: Color = color.darkened(0.3)
	
	# Thick barrel
	for x in range(12, 28):
		for y in range(12, 20):
			image.set_pixel(x, y, color)
	
	# Muzzle brake
	for x in range(26, 30):
		for y in range(10, 22):
			image.set_pixel(x, y, dark)
	
	# Body
	for x in range(4, 14):
		for y in range(10, 22):
			image.set_pixel(x, y, dark)


func _draw_launcher(image: Image, color: Color) -> void:
	## Draw missile launcher
	var dark: Color = color.darkened(0.3)
	
	# Tube
	for x in range(8, 26):
		for y in range(10, 22):
			image.set_pixel(x, y, dark)
	
	# Rim
	for x in range(24, 28):
		for y in range(8, 24):
			image.set_pixel(x, y, color)
	
	# Back
	for x in range(4, 10):
		for y in range(12, 20):
			image.set_pixel(x, y, color)


func _draw_beam(image: Image, color: Color) -> void:
	## Draw beam weapon
	var glow: Color = color.lightened(0.4)
	
	# Emitter
	for x in range(4, 12):
		for y in range(12, 20):
			image.set_pixel(x, y, color)
	
	# Beam path
	for x in range(12, 30):
		for y in range(14, 18):
			image.set_pixel(x, y, glow)
	
	# Core
	for x in range(12, 30):
		image.set_pixel(x, 15, Color.WHITE)


func _draw_sniper(image: Image, color: Color) -> void:
	## Draw sniper rifle
	var dark: Color = color.darkened(0.3)
	
	# Long barrel
	for x in range(8, 30):
		for y in range(15, 17):
			image.set_pixel(x, y, color)
	
	# Scope
	for x in range(10, 18):
		for y in range(10, 14):
			image.set_pixel(x, y, dark)
	
	# Stock
	for x in range(2, 10):
		for y in range(14, 20):
			image.set_pixel(x, y, dark)


func _draw_shotgun(image: Image, color: Color) -> void:
	## Draw shotgun
	var dark: Color = color.darkened(0.3)
	
	# Double barrel
	for x in range(12, 26):
		for y in range(10, 14):
			image.set_pixel(x, y, color)
		for y in range(18, 22):
			image.set_pixel(x, y, color)
	
	# Body
	for x in range(4, 14):
		for y in range(10, 22):
			image.set_pixel(x, y, dark)


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func _draw_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	## Draw a circle
	for x in range(center.x - radius, center.x + radius):
		for y in range(center.y - radius, center.y + radius):
			if Vector2i(x - center.x, y - center.y).length() < radius:
				image.set_pixel(x, y, color)


func save_sprite(texture: Texture2D, path: String) -> void:
	## Save a sprite to disk
	var image: Image = texture.get_image()
	image.save_png(path)
	print("SpriteGenerator: Saved sprite to ", path)


func generate_all_mvp_sprites() -> void:
	## Generate all MVP sprites
	print("SpriteGenerator: Generating MVP sprites...")
	
	var dir: String = "res://assets/sprites/"
	
	# Generate chassis
	for chassis_type in ["scout", "fighter", "tank"]:
		var texture: Texture2D = generate_chassis_sprite(chassis_type, 0)
		save_sprite(texture, dir + "chassis_" + chassis_type + "_t1.png")
	
	# Generate weapons
	for weapon_type in ["machine_gun", "cannon", "launcher"]:
		var texture: Texture2D = generate_weapon_sprite(weapon_type, 0)
		save_sprite(texture, dir + "weapon_" + weapon_type + "_t1.png")
	
	print("SpriteGenerator: MVP sprites generated!")
