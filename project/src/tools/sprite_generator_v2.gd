extends Node
class_name SpriteGeneratorV2
## SpriteGenerator V2 - generates sprites matching the Visual Design Blueprint.
## Retro-vector mechanical minimalism with soft arcade rendering.

const CHASSIS_SIZE: int = 48
const WEAPON_SIZE: int = 32

# Color Palette (from blueprint)
const PALETTE: Dictionary = {
	# Backgrounds - warm, earthy
	"bg_dark": Color(0.15, 0.14, 0.12),
	"bg_mid": Color(0.22, 0.20, 0.18),
	"bg_light": Color(0.30, 0.28, 0.25),
	
	# Units - muted mechanical
	"green": Color(0.35, 0.65, 0.45),    # Friendly
	"blue": Color(0.35, 0.55, 0.75),     # Heavy/defense
	"purple": Color(0.55, 0.40, 0.70),   # Elite
	"grey": Color(0.50, 0.52, 0.55),     # Neutral
	
	# Attack - saturated
	"yellow": Color(1.0, 0.85, 0.25),    # Attack
	"orange": Color(1.0, 0.60, 0.20),    # Projectiles
	
	# UI/Effects
	"health_green": Color(0.2, 0.9, 0.4),
	"health_yellow": Color(0.95, 0.85, 0.2),
	"health_red": Color(0.95, 0.3, 0.3),
	"white": Color(1.0, 1.0, 1.0),
	"black": Color(0.05, 0.05, 0.05)
}

# Team colors
const TEAM_COLORS: Dictionary = {
	"player": "green",
	"enemy": "yellow",
	"neutral": "grey"
}

# Lighting - single source upper left
const LIGHT_DIR: Vector2 = Vector2(-0.7, -0.7)  # Upper left
const SHADOW_DIR: Vector2 = Vector2(0.5, 0.5)   # Lower right

func _ready() -> void:
	pass

# ============================================================================
# CHASSIS SPRITES
# ============================================================================

func generate_chassis(chassis_type: String, team: String = "player") -> Image:
	## Generate chassis following blueprint spec
	var size: int = CHASSIS_SIZE
	if chassis_type == "tank":
		size = 56
	elif chassis_type == "scout":
		size = 40
	
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var base_color: Color = PALETTE[TEAM_COLORS[team]]
	var center: Vector2i = Vector2i(size / 2, size / 2)
	
	# Draw base shape (circular/rounded only)
	_draw_rounded_base(image, center, size, base_color, chassis_type)
	
	# Add single light source highlight (upper left)
	_draw_radial_highlight(image, center, size * 0.35, base_color.lightened(0.25))
	
	# Add shadow gradient (lower right)
	_draw_shadow_gradient(image, center, size, base_color.darkened(0.2))
	
	# Add panel lines (1 accent detail max)
	_draw_panel_line(image, center, size, base_color.darkened(0.3))
	
	# Add center detail
	_draw_center_detail(image, center, size, chassis_type, base_color)
	
	return image

func _draw_rounded_base(image: Image, center: Vector2i, size: int, color: Color, type: String) -> void:
	## All shapes must be circular or rounded - no sharp corners
	var radius: float = size * 0.45
	
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x - center.x, y - center.y).length()
			
			if type == "scout":
				# Diamond/circle hybrid - rounded diamond
				var diamond_dist: float = abs(x - center.x) + abs(y - center.y)
				dist = lerp(dist, diamond_dist * 0.7, 0.3)
			
			if dist < radius:
				image.set_pixel(x, y, color)

func _draw_radial_highlight(image: Image, center: Vector2i, radius: float, color: Color) -> void:
	# Soft radial highlight in upper left quadrant
	var highlight_center: Vector2i = Vector2i(center.x - radius * 0.3, center.y - radius * 0.3)
	
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var dist: float = Vector2(x - highlight_center.x, y - highlight_center.y).length()
			if dist < radius:
				var alpha: float = 1.0 - (dist / radius)
				alpha *= 0.4  ; Soft highlight
				var current: Color = image.get_pixel(x, y)
				if current.a > 0:
					image.set_pixel(x, y, current.lerp(color, alpha))

func _draw_shadow_gradient(image: Image, center: Vector2i, size: int, shadow_color: Color) -> void:
	# Shadow gradient in lower right
	var shadow_center: Vector2i = Vector2i(center.x + size * 0.25, center.y + size * 0.25)
	var radius: float = size * 0.4
	
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var dist: float = Vector2(x - shadow_center.x, y - shadow_center.y).length()
			if dist < radius:
				var alpha: float = 1.0 - (dist / radius)
				alpha *= 0.3
				var current: Color = image.get_pixel(x, y)
				if current.a > 0:
					image.set_pixel(x, y, current.lerp(shadow_color, alpha))

func _draw_panel_line(image: Image, center: Vector2i, size: int, line_color: Color) -> void:
	# Single panel line detail
	var radius: float = size * 0.35
	
	for angle_deg in range(0, 360, 45):
		if angle_deg % 90 == 0:  ; Only cardinal directions
			continue
		
		var angle: float = deg_to_rad(angle_deg)
		for r in range(radius * 0.5, radius * 0.9):
			var x: int = int(center.x + cos(angle) * r)
			var y: int = int(center.y + sin(angle) * r)
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				if image.get_pixel(x, y).a > 0:
					image.set_pixel(x, y, line_color)

func _draw_center_detail(image: Image, center: Vector2i, size: int, type: String, base_color: Color) -> void:
	# Center sensor/detail
	var detail_radius: int = size / 8
	var detail_color: Color = base_color.lightened(0.4)
	
	for x in range(center.x - detail_radius, center.x + detail_radius):
		for y in range(center.y - detail_radius, center.y + detail_radius):
			if Vector2(x - center.x, y - center.y).length() < detail_radius:
				image.set_pixel(x, y, detail_color)

# ============================================================================
# WEAPON SPRITES
# ============================================================================

func generate_weapon(weapon_type: String) -> Image:
	## Generate weapon sprite - mechanical, rounded, minimal
	var image: Image = Image.create(WEAPON_SIZE, WEAPON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var base_color: Color = PALETTE["grey"].darkened(0.1)
	var accent_color: Color = PALETTE["orange"]  ; Saturated for attack
	
	match weapon_type:
		"machine_gun":
			_draw_mg(image, base_color, accent_color)
		"cannon":
			_draw_cannon(image, base_color, accent_color)
		"launcher":
			_draw_launcher(image, base_color, accent_color)
		"beam":
			_draw_beam(image, base_color, PALETTE["orange"])
		"sniper":
			_draw_sniper(image, base_color, accent_color)
		_:
			_draw_mg(image, base_color, accent_color)
	
	return image

func _draw_mg(image: Image, base: Color, accent: Color) -> void:
	# Rounded machine gun
	var center: Vector2i = Vector2i(16, 20)
	
	# Body - rounded rectangle
	for x in range(8, 24):
		for y in range(14, 26):
			if abs(x - 16) < 6 and abs(y - 20) < 5:
				image.set_pixel(x, y, base)
	
	# Barrel - straight line
	for x in range(20, 30):
		for y in range(18, 22):
			image.set_pixel(x, y, base.lightened(0.1))
	
	# Muzzle - saturated glow
	for x in range(28, 32):
		for y in range(17, 23):
			image.set_pixel(x, y, accent)

func _draw_cannon(image: Image, base: Color, accent: Color) -> void:
	# Heavy cannon
	# Thick rounded barrel
	for x in range(4, 28):
		for y in range(12, 20):
			image.set_pixel(x, y, base)
	
	# Muzzle brake
	for x in range(24, 30):
		for y in range(10, 22):
			image.set_pixel(x, y, base.darkened(0.2))
	
	# Glow tip
	for x in range(28, 32):
		for y in range(14, 18):
			image.set_pixel(x, y, accent)

func _draw_launcher(image: Image, base: Color, accent: Color) -> void:
	# Missile launcher - tube shape
	# Main tube
	for x in range(6, 26):
		for y in range(10, 22):
			image.set_pixel(x, y, base)
	
	# Rim
	for x in range(22, 28):
		for y in range(8, 24):
			if abs(y - 16) < 7:
				image.set_pixel(x, y, base.lightened(0.15))
	
	# Inner glow
	for x in range(24, 27):
		for y in range(12, 20):
			image.set_pixel(x, y, accent.darkened(0.3))

func _draw_beam(image: Image, base: Color, glow: Color) -> void:
	# Beam weapon - energy focus
	# Emitter
	for x in range(4, 14):
		for y in range(12, 20):
			image.set_pixel(x, y, base)
	
	# Beam path - saturated
	for x in range(12, 32):
		for y in range(15, 17):
			image.set_pixel(x, y, glow)
	
	# Core white
	for x in range(14, 30):
		image.set_pixel(x, 15, PALETTE["white"])

func _draw_sniper(image: Image, base: Color, accent: Color) -> void:
	# Long rifle
	# Long barrel
	for x in range(2, 30):
		for y in range(15, 17):
			image.set_pixel(x, y, base)
	
	# Scope
	for x in range(10, 18):
		for y in range(10, 14):
			image.set_pixel(x, y, base.darkened(0.2))
	
	# Stock
	for x in range(2, 10):
		for y in range(14, 20):
			image.set_pixel(x, y, base.darkened(0.15))

# ============================================================================
# UTILITY
# ============================================================================

func generate_all_sprites() -> void:
	## Generate all MVP sprites
	print("SpriteGeneratorV2: Generating sprites...")
	
	var dir: String = "res://assets/sprites/v2/"
	DirAccess.make_dir_recursive_absolute(dir)
	
	# Chassis
	for type in ["scout", "fighter", "tank"]:
		for team in ["player", "enemy"]:
			var img: Image = generate_chassis(type, team)
			var path: String = dir + "chassis_" + type + "_" + team + ".png"
			img.save_png(path)
			print("  Saved: ", path)
	
	# Weapons
	for weapon in ["machine_gun", "cannon", "launcher", "beam", "sniper"]:
		var img: Image = generate_weapon(weapon)
		var path: String = dir + "weapon_" + weapon + ".png"
		img.save_png(path)
		print("  Saved: ", path)
	
	print("SpriteGeneratorV2: Done!")

func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t
