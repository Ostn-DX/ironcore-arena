@tool
extends EditorScript
## Standalone PNG Generator - Run from Godot Editor
## Generates all MVP sprites and tiles

func _run() -> void:
	print("=" * 50)
	print("IRONCORE ARENA - PNG Generator")
	print("=" * 50)
	
	# Create directories
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/v2/")
	DirAccess.make_dir_recursive_absolute("res://assets/tilesets/training_grounds/")
	
	# Generate chassis
	print("\n[1/3] Generating chassis sprites...")
	for chassis_type in ["scout", "fighter", "tank"]:
		for team in ["player", "enemy"]:
			var size: int = 40 if chassis_type == "scout" else (48 if chassis_type == "fighter" else 56)
			var img: Image = _create_chassis(chassis_type, team, size)
			var path: String = "res://assets/sprites/v2/chassis_%s_%s.png" % [chassis_type, team]
			img.save_png(path)
			print("  ✓ " + path)
	
	# Generate weapons
	print("\n[2/3] Generating weapon sprites...")
	for weapon_type in ["machine_gun", "cannon", "launcher", "beam", "sniper", "shotgun"]:
		var img: Image = _create_weapon(weapon_type)
		var path: String = "res://assets/sprites/v2/weapon_%s.png" % weapon_type
		img.save_png(path)
		print("  ✓ " + path)
	
	# Generate tiles
	print("\n[3/3] Generating tileset...")
	var tiles: Dictionary = {
		"floor_0.png": _create_floor(Color(0.15, 0.18, 0.15)),
		"floor_1.png": _create_floor(Color(0.17, 0.20, 0.17)),
		"floor_2.png": _create_floor(Color(0.13, 0.16, 0.13)),
		"floor_grid.png": _create_grid_floor(),
		"wall_top.png": _create_wall("top"),
		"wall_bottom.png": _create_wall("bottom"),
		"spawn_player.png": _create_spawn("player"),
		"spawn_enemy.png": _create_spawn("enemy"),
	}
	
	for filename in tiles:
		var path: String = "res://assets/tilesets/training_grounds/" + filename
		tiles[filename].save_png(path)
		print("  ✓ " + path)
	
	print("\n" + "=" * 50)
	print("COMPLETE!")
	print("=" * 50)

func _create_chassis(type: String, team: String, size: int) -> Image:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Colors
	var base: Color
	if team == "player":
		base = Color(0.18, 0.80, 0.44)  ; Green
	else:
		base = Color(0.95, 0.77, 0.06)  ; Yellow
	
	var center: int = size / 2
	var radius: float = size * 0.35
	
	# Shadow
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x - center - 3, y - center - 3).length()
			if dist < radius:
				img.set_pixel(x, y, Color(0, 0, 0, 0.25))
	
	# Base shape
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(x - center, y - center).length()
			if dist < radius:
				# Shading
				var shade: float = 1.0 - (dist / radius) * 0.2
				var col: Color = base * shade
				
				# Highlight upper left
				var highlight_dist: float = Vector2(x - center + radius*0.3, y - center + radius*0.3).length()
				if highlight_dist < radius * 0.4:
					col = col.lightened(0.3 * (1.0 - highlight_dist / (radius * 0.4)))
				
				img.set_pixel(x, y, col)
	
	# Center detail
	var detail_r: int = int(radius * 0.25)
	for x in range(center - detail_r, center + detail_r):
		for y in range(center - detail_r, center + detail_r):
			if Vector2(x - center, y - center).length() < detail_r:
				img.set_pixel(x, y, base.lightened(0.5))
	
	return img

func _create_weapon(type: String) -> Image:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var base: Color = Color(0.38, 0.43, 0.52)  ; Slate
	var accent: Color = Color(1.0, 0.42, 0.21)  ; Orange
	
	match type:
		"machine_gun":
			# Body
			for x in range(8, 16):
				for y in range(12, 20):
					img.set_pixel(x, y, base.darkened(0.1))
			# Barrel
			for x in range(16, 28):
				for y in range(15, 17):
					img.set_pixel(x, y, base)
			# Muzzle
			for x in range(28, 30):
				for y in range(14, 18):
					img.set_pixel(x, y, accent)
		
		"cannon":
			# Thick barrel
			for x in range(4, 24):
				for y in range(12, 20):
					img.set_pixel(x, y, base)
			# Muzzle
			for x in range(22, 28):
				for y in range(10, 22):
					img.set_pixel(x, y, base.darkened(0.2))
			# Tip
			for x in range(26, 30):
				for y in range(13, 19):
					img.set_pixel(x, y, accent.darkened(0.3))
		
		"launcher":
			# Tube
			for x in range(6, 22):
				for y in range(10, 22):
					img.set_pixel(x, y, base.darkened(0.1))
			# Rim
			for x in range(20, 26):
				for y in range(8, 24):
					img.set_pixel(x, y, base)
		
		"beam":
			# Emitter
			for x in range(4, 12):
				for y in range(12, 20):
					img.set_pixel(x, y, base)
			# Beam
			for x in range(12, 30):
				for y in range(15, 17):
					var alpha: float = 1.0 - (x - 12) / 18.0
					img.set_pixel(x, y, Color(accent.r, accent.g, accent.b, alpha))
			# Core
			for x in range(14, 28):
				img.set_pixel(x, 16, Color.WHITE)
		
		"sniper":
			# Long barrel
			for x in range(2, 28):
				for y in range(15, 17):
					img.set_pixel(x, y, base)
			# Scope
			for x in range(10, 18):
				for y in range(10, 14):
					img.set_pixel(x, y, base.darkened(0.2))
		
		"shotgun":
			# Double barrel
			for x in range(12, 24):
				for y in range(10, 13):
					img.set_pixel(x, y, base)
			for x in range(12, 24):
				for y in range(19, 22):
					img.set_pixel(x, y, base)
			# Body
			for x in range(4, 12):
				for y in range(10, 22):
					img.set_pixel(x, y, base.darkened(0.2))
	
	return img

func _create_floor(color: Color) -> Image:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return img

func _create_grid_floor() -> Image:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base: Color = Color(0.15, 0.18, 0.15)
	var line: Color = Color(0.20, 0.23, 0.20)
	
	img.fill(base)
	
	# Grid lines
	for i in range(0, 32, 8):
		for y in range(32):
			img.set_pixel(i, y, line)
		for x in range(32):
			img.set_pixel(x, i, line)
	
	return img

func _create_wall(side: String) -> Image:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color: Color = Color(0.4, 0.45, 0.4)  # Wall color
	
	if side == "top":
		# Lighter top
		color = color.lightened(0.1)
	else:
		# Darker bottom/sides
		color = color.darkened(0.1)
	
	img.fill(color)
	return img

func _create_spawn(team: String) -> Image:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var color: Color
	if team == "player":
		color = Color(0.2, 0.6, 1.0)  ; Blue
	else:
		color = Color(1.0, 0.3, 0.3)  ; Red
	
	var center: int = 16
	
	# Circle outline
	for x in range(32):
		for y in range(32):
			var dist: float = Vector2(x - center, y - center).length()
			if dist > 10 and dist < 13:
				img.set_pixel(x, y, color)
	
	# Inner symbol
	if team == "player":
		# Triangle
		for y in range(12, 22):
			var width: int = int((y - 12) * 0.8)
			for x in range(center - width, center + width):
				img.set_pixel(x, y, color)
	else:
		# X
		for i in range(-6, 6):
			img.set_pixel(center + i, center + i, color)
			img.set_pixel(center + i, center - i, color)
	
	return img
