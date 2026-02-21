extends Node2D
class_name Arena
## Arena — visual representation of the battle arena.
## Handles arena rendering, boundaries, obstacles, camera, and spawn points.

enum ArenaTheme { ROXTAN_PARK, JUNKYARD, CHROMETEK, METALMASH }

# Arena configuration
@export var arena_id: String = ""
var arena_data: Dictionary = {}
var arena_size: Vector2 = Vector2(800, 600)
var theme: ArenaTheme = ArenaTheme.ROXTAN_PARK

# Node references
@onready var background: ColorRect = $Background
@onready var walls: Node2D = $Walls
@onready var floor_details: Node2D = $FloorDetails
@onready var obstacles: Node2D = $Obstacles
@onready var camera: Camera2D = $RTSCamera
@onready var spawn_points: Node2D = $SpawnPoints

# Spawn markers (set by arena data or use defaults)
var player_spawn_markers: Array[Marker2D] = []
var enemy_spawn_markers: Array[Marker2D] = []

# Wall collision rects
var boundary_walls: Array[StaticBody2D] = []

# Camera settings
var camera_target: Node2D = null
var camera_smooth_speed: float = 5.0
var camera_zoom_default: float = 1.0
var camera_min_zoom: float = 0.6
var camera_max_zoom: float = 1.4

# Theme colors
const THEME_COLORS: Dictionary = {
	ArenaTheme.ROXTAN_PARK: {
		"bg": Color(0.12, 0.18, 0.12),
		"wall": Color(0.3, 0.4, 0.3),
		"floor_detail": Color(0.15, 0.22, 0.15),
		"grid": Color(0.2, 0.28, 0.2)
	},
	ArenaTheme.JUNKYARD: {
		"bg": Color(0.15, 0.12, 0.08),
		"wall": Color(0.4, 0.35, 0.25),
		"floor_detail": Color(0.2, 0.16, 0.1),
		"grid": Color(0.28, 0.22, 0.15)
	},
	ArenaTheme.CHROMETEK: {
		"bg": Color(0.08, 0.12, 0.18),
		"wall": Color(0.25, 0.35, 0.5),
		"floor_detail": Color(0.1, 0.16, 0.22),
		"grid": Color(0.15, 0.22, 0.32)
	},
	ArenaTheme.METALMASH: {
		"bg": Color(0.1, 0.08, 0.08),
		"wall": Color(0.5, 0.2, 0.15),
		"floor_detail": Color(0.18, 0.12, 0.1),
		"grid": Color(0.35, 0.18, 0.12)
	}
}

func _ready() -> void:
	_cache_spawn_markers()
	_apply_theme()

func _process(delta: float) -> void:
	_update_camera(delta)

# ============================================================================
# SETUP
# ============================================================================

func setup(arena: Dictionary) -> void:
	## Configure arena from arena data
	arena_data = arena
	arena_id = arena.get("id", "unknown")
	
	# Get dimensions from size object
	var size_data: Dictionary = arena.get("size", {"width": 800, "height": 600})
	arena_size = Vector2(size_data.get("width", 800), size_data.get("height", 600))
	
	# Determine theme from arena ID
	theme = _get_theme_from_arena_id(arena_id)
	
	# Build the arena
	_build_arena()
	
	print("Arena: Setup complete for '%s' (%dx%d) with theme %s" % [
		arena.get("name", arena_id), int(arena_size.x), int(arena_size.y), _theme_name()
	])

func _build_arena() -> void:
	## Build all arena visual elements
	_apply_theme()
	_create_background()
	_create_boundaries()
	_create_floor_details()
	_create_obstacles()
	_setup_camera()
	_update_spawn_markers_from_data()

func _cache_spawn_markers() -> void:
	## Cache references to spawn markers
	player_spawn_markers.clear()
	enemy_spawn_markers.clear()
	
	if not spawn_points:
		return
		
	for child in spawn_points.get_children():
		if child is Marker2D:
			if child.name.begins_with("PlayerSpawn"):
				player_spawn_markers.append(child)
			elif child.name.begins_with("EnemySpawn"):
				enemy_spawn_markers.append(child)

func _update_spawn_markers_from_data() -> void:
	## Update marker positions from arena data if available
	var player_spawns = arena_data.get("spawn_points_player", [])
	var enemy_spawns = arena_data.get("spawn_points_enemy", [])
	
	for i in range(min(player_spawns.size(), player_spawn_markers.size())):
		var data = player_spawns[i]
		player_spawn_markers[i].position = Vector2(data.get("x", 100), data.get("y", 200))
	
	for i in range(min(enemy_spawns.size(), enemy_spawn_markers.size())):
		var data = enemy_spawns[i]
		enemy_spawn_markers[i].position = Vector2(data.get("x", 700), data.get("y", 200))

func _get_theme_from_arena_id(id: String) -> ArenaTheme:
	## Determine theme from arena ID
	match id:
		"roxtan_park", "arena_training": return ArenaTheme.ROXTAN_PARK
		"torys_junkyard", "arena_scrapyard": return ArenaTheme.JUNKYARD
		"chrometek_rally", "arena_minefield": return ArenaTheme.CHROMETEK
		"metalmash_2057": return ArenaTheme.METALMASH
		_: return ArenaTheme.ROXTAN_PARK

func _theme_name() -> String:
	match theme:
		ArenaTheme.ROXTAN_PARK: return "Roxtan Park"
		ArenaTheme.JUNKYARD: return "Junkyard"
		ArenaTheme.CHROMETEK: return "Chrometek"
		ArenaTheme.METALMASH: return "MetalMash"
		_: return "Unknown"

# ============================================================================
# VISUAL BUILDING
# ============================================================================

func _apply_theme() -> void:
	## Apply theme colors to nodes
	var colors: Dictionary = THEME_COLORS[theme]
	
	if background:
		background.color = colors["bg"]

func _create_background() -> void:
	## Create the arena background
	if not background:
		background = ColorRect.new()
		background.name = "Background"
		add_child(background)
	
	background.position = Vector2.ZERO
	background.size = arena_size
	
	# Add grid pattern
	_add_grid_pattern()

func _add_grid_pattern() -> void:
	## Add subtle grid lines to background
	if not floor_details:
		return
	
	# Clear existing grid lines only (keep other decorations)
	for child in floor_details.get_children():
		if child.name.begins_with("GridLine"):
			child.queue_free()
	
	var colors: Dictionary = THEME_COLORS[theme]
	var grid_spacing: float = 50.0
	
	# Vertical lines
	for x in range(0, int(arena_size.x) + 1, int(grid_spacing)):
		var line: Line2D = Line2D.new()
		line.name = "GridLineV_%d" % x
		line.points = [Vector2(x, 0), Vector2(x, arena_size.y)]
		line.width = 1.0
		line.default_color = colors["grid"]
		line.modulate.a = 0.3
		floor_details.add_child(line)
	
	# Horizontal lines
	for y in range(0, int(arena_size.y) + 1, int(grid_spacing)):
		var line: Line2D = Line2D.new()
		line.name = "GridLineH_%d" % y
		line.points = [Vector2(0, y), Vector2(arena_size.x, y)]
		line.width = 1.0
		line.default_color = colors["grid"]
		line.modulate.a = 0.3
		floor_details.add_child(line)

func _create_boundaries() -> void:
	## Create wall boundaries with collision
	if not walls:
		walls = Node2D.new()
		walls.name = "Walls"
		add_child(walls)
	
	# Clear existing walls
	for wall in boundary_walls:
		if is_instance_valid(wall):
			wall.queue_free()
	boundary_walls.clear()
	
	for child in walls.get_children():
		child.queue_free()
	
	var colors: Dictionary = THEME_COLORS[theme]
	var wall_thickness: float = 20.0
	
	# Top wall
	_create_wall_segment(
		Vector2(arena_size.x / 2, -wall_thickness / 2),
		Vector2(arena_size.x + wall_thickness * 2, wall_thickness),
		colors["wall"]
	)
	
	# Bottom wall
	_create_wall_segment(
		Vector2(arena_size.x / 2, arena_size.y + wall_thickness / 2),
		Vector2(arena_size.x + wall_thickness * 2, wall_thickness),
		colors["wall"]
	)
	
	# Left wall
	_create_wall_segment(
		Vector2(-wall_thickness / 2, arena_size.y / 2),
		Vector2(wall_thickness, arena_size.y),
		colors["wall"]
	)
	
	# Right wall
	_create_wall_segment(
		Vector2(arena_size.x + wall_thickness / 2, arena_size.y / 2),
		Vector2(wall_thickness, arena_size.y),
		colors["wall"]
	)
	
	# Corner posts
	_create_corner_post(Vector2(0, 0), wall_thickness, colors["wall"])
	_create_corner_post(Vector2(arena_size.x, 0), wall_thickness, colors["wall"])
	_create_corner_post(Vector2(0, arena_size.y), wall_thickness, colors["wall"])
	_create_corner_post(Vector2(arena_size.x, arena_size.y), wall_thickness, colors["wall"])

func _create_wall_segment(center: Vector2, size: Vector2, color: Color) -> void:
	## Create a wall segment with visual and collision
	var wall_body: StaticBody2D = StaticBody2D.new()
	wall_body.position = center
	
	# Visual
	var visual: ColorRect = ColorRect.new()
	visual.size = size
	visual.position = -size / 2
	visual.color = color
	wall_body.add_child(visual)
	
	# Collision
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall_body.add_child(collision)
	
	walls.add_child(wall_body)
	boundary_walls.append(wall_body)

func _create_corner_post(pos: Vector2, size: float, color: Color) -> void:
	## Create a decorative corner post
	var post: StaticBody2D = StaticBody2D.new()
	post.position = pos
	
	# Visual
	var visual: ColorRect = ColorRect.new()
	visual.size = Vector2(size * 2, size * 2)
	visual.position = Vector2(-size, -size)
	visual.color = color.darkened(0.2)
	post.add_child(visual)
	
	# Corner detail
	var detail: ColorRect = ColorRect.new()
	detail.size = Vector2(size, size)
	detail.position = Vector2(-size / 2, -size / 2)
	detail.color = color.lightened(0.1)
	post.add_child(detail)
	
	# Collision
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(size * 2, size * 2)
	collision.shape = shape
	post.add_child(collision)
	
	walls.add_child(post)
	boundary_walls.append(post)

func _create_floor_details() -> void:
	## Add floor decorations based on theme
	if not floor_details:
		return
	
	# Clear non-grid decorations
	for child in floor_details.get_children():
		if not child.name.begins_with("GridLine"):
			child.queue_free()
	
	var colors: Dictionary = THEME_COLORS[theme]
	
	# Add theme-specific decorations
	match theme:
		ArenaTheme.JUNKYARD:
			_add_junkyard_debris()
		ArenaTheme.CHROMETEK:
			_add_chrometek_pylons()
		ArenaTheme.METALMASH:
			_add_metalmash_hazards()
		_:
			_add_park_ground_markings()

func _add_park_ground_markings() -> void:
	## Add park-style ground markings
	var colors: Dictionary = THEME_COLORS[theme]
	
	# Center circle
	var center_circle: Polygon2D = Polygon2D.new()
	center_circle.name = "DecorCenterCircle"
	var points: PackedVector2Array = []
	var radius: float = 60.0
	var center: Vector2 = arena_size / 2
	
	for i in range(32):
		var angle: float = (i / 32.0) * TAU
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	center_circle.polygon = points
	center_circle.color = colors["floor_detail"]
	floor_details.add_child(center_circle)
	
	# Corner markers
	var corner_size: float = 40.0
	for corner in [Vector2.ZERO, Vector2(arena_size.x, 0), 
				   Vector2(0, arena_size.y), arena_size]:
		var marker: ColorRect = ColorRect.new()
		marker.name = "DecorCorner"
		marker.size = Vector2(corner_size, corner_size)
		marker.position = corner - Vector2(corner_size if corner.x > 0 else 0, 
										  corner_size if corner.y > 0 else 0)
		marker.color = colors["floor_detail"]
		floor_details.add_child(marker)

func _add_junkyard_debris() -> void:
	## Add junkyard debris scattered around
	var colors: Dictionary = THEME_COLORS[theme]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(arena_id)
	
	for i in range(8):
		var debris: ColorRect = ColorRect.new()
		debris.name = "DecorDebris_%d" % i
		var size: Vector2 = Vector2(
			rng.randf_range(15, 40),
			rng.randf_range(15, 40)
		)
		var pos: Vector2 = Vector2(
			rng.randf_range(100, arena_size.x - 100),
			rng.randf_range(100, arena_size.y - 100)
		)
		
		debris.size = size
		debris.position = pos - size / 2
		debris.color = colors["wall"].darkened(rng.randf_range(0.1, 0.4))
		debris.rotation = rng.randf_range(0, PI)
		floor_details.add_child(debris)

func _add_chrometek_pylons() -> void:
	## Add glowing pylons for Chrometek
	var colors: Dictionary = THEME_COLORS[theme]
	var pylon_positions: Array[Vector2] = [
		arena_size * 0.25,
		arena_size * 0.75,
		Vector2(arena_size.x * 0.25, arena_size.y * 0.75),
		Vector2(arena_size.x * 0.75, arena_size.y * 0.25)
	]
	
	for i in range(pylon_positions.size()):
		var pos = pylon_positions[i]
		var pylon: ColorRect = ColorRect.new()
		pylon.name = "DecorPylon_%d" % i
		pylon.size = Vector2(20, 20)
		pylon.position = pos - Vector2(10, 10)
		pylon.color = colors["wall"].lightened(0.3)
		floor_details.add_child(pylon)
		
		# Glow effect
		var glow: ColorRect = ColorRect.new()
		glow.name = "DecorPylonGlow_%d" % i
		glow.size = Vector2(40, 40)
		glow.position = pos - Vector2(20, 20)
		glow.color = colors["wall"]
		glow.modulate.a = 0.3
		floor_details.add_child(glow)

func _add_metalmash_hazards() -> void:
	## Add hazard stripes for MetalMash
	var colors: Dictionary = THEME_COLORS[theme]
	var stripe_count: int = 6
	
	for i in range(stripe_count):
		var stripe: ColorRect = ColorRect.new()
		stripe.name = "DecorStripe_%d" % i
		stripe.size = Vector2(arena_size.x, 10)
		stripe.position = Vector2(0, (arena_size.y / (stripe_count + 1)) * (i + 1))
		stripe.color = colors["wall"] if i % 2 == 0 else Color.BLACK
		floor_details.add_child(stripe)

func _create_obstacles() -> void:
	## Create obstacles from arena data
	if not obstacles:
		obstacles = Node2D.new()
		obstacles.name = "Obstacles"
		add_child(obstacles)
	
	# Clear existing
	for child in obstacles.get_children():
		child.queue_free()
	
	var obstacle_data: Array = arena_data.get("obstacles", [])
	for obs in obstacle_data:
		_create_obstacle(obs)

func _create_obstacle(data: Dictionary) -> void:
	## Create a single obstacle
	var type: String = data.get("type", "box")
	var pos: Vector2 = Vector2(
		data.get("x", 0),
		data.get("y", 0)
	)
	var size: Vector2 = Vector2(
		data.get("width", 50),
		data.get("height", 50)
	)
	
	var obs_body: StaticBody2D = StaticBody2D.new()
	obs_body.position = pos
	
	var colors: Dictionary = THEME_COLORS[theme]
	
	# Visual based on type
	var visual: ColorRect = ColorRect.new()
	visual.size = size
	visual.position = -size / 2
	
	match type:
		"barrier", "wall":
			visual.color = colors["wall"].darkened(0.3)
		"cover":
			visual.color = colors["wall"].lightened(0.1)
		"hazard_mine":
			visual.color = Color(0.8, 0.2, 0.1)
			visual.size = Vector2(16, 16)
			visual.position = Vector2(-8, -8)
		_:
			visual.color = colors["wall"]
	
	obs_body.add_child(visual)
	
	# Only add collision for solid obstacles
	if type != "hazard_mine":
		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = size
		collision.shape = shape
		obs_body.add_child(collision)
	
	obstacles.add_child(obs_body)

# ============================================================================
# CAMERA
# ============================================================================

func _setup_camera() -> void:
	## Setup the RTS camera with arena bounds
	if not camera:
		camera = Camera2D.new()
		camera.name = "RTSCamera"
		add_child(camera)
	
	; Setup RTS camera bounds
	if camera.has_method("setup_arena_bounds"):
		camera.setup_arena_bounds(Rect2(Vector2.ZERO, arena_size))
	else:
		; Fallback for regular Camera2D
		camera.position = arena_size / 2
		camera.zoom = Vector2.ONE * camera_zoom_default
		camera.enabled = true
		camera.limit_left = -100
		camera.limit_top = -100
		camera.limit_right = int(arena_size.x + 100)
		camera.limit_bottom = int(arena_size.y + 100)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = camera_smooth_speed

func _update_camera(delta: float) -> void:
	## Update camera position and zoom
	if not camera:
		return
	
	# Smooth follow target
	if camera_target and is_instance_valid(camera_target):
		var target_pos: Vector2 = camera_target.global_position
		camera.position = camera.position.lerp(target_pos, camera_smooth_speed * delta)

func set_camera_target(target: Node2D) -> void:
	## Set a specific target for the camera to follow
	camera_target = target

func focus_on_position(pos: Vector2, zoom_level: float = 1.0) -> void:
	## Move camera to focus on a position
	camera_target = null
	if camera:
		camera.position = pos
		camera.zoom = Vector2.ONE * zoom_level

func reset_camera() -> void:
	## Reset camera to arena center with default zoom
	camera_target = null
	if camera:
		camera.position = arena_size / 2
		camera.zoom = Vector2.ONE * camera_zoom_default

func set_camera_bounds_enabled(enabled: bool) -> void:
	## Enable or disable camera bounds (useful for testing)
	if camera:
		camera.limit_smoothed = enabled

# ============================================================================
# SPAWN POINTS
# ============================================================================

func get_spawn_points(team: int, count: int) -> Array[Vector2]:
	## Get spawn positions for a team - returns Vector2 positions
	var points: Array[Vector2] = []
	
	if team == 0:  # Player
		for i in range(min(count, player_spawn_markers.size())):
			points.append(player_spawn_markers[i].position)
	else:  # Enemy
		for i in range(min(count, enemy_spawn_markers.size())):
			points.append(enemy_spawn_markers[i].position)
	
	# Fallback to generated positions if not enough markers
	if points.size() < count:
		var margin: float = 80.0
		if team == 0:
			for i in range(points.size(), count):
				var y: float = lerp(margin, arena_size.y - margin, (i + 1.0) / (count + 1.0))
				points.append(Vector2(margin + 50, y))
		else:
			for i in range(points.size(), count):
				var y: float = lerp(margin, arena_size.y - margin, (i + 1.0) / (count + 1.0))
				points.append(Vector2(arena_size.x - margin - 50, y))
	
	return points

func get_spawn_markers(team: int) -> Array[Marker2D]:
	## Get spawn markers for a team
	if team == 0:
		return player_spawn_markers
	return enemy_spawn_markers

func get_random_spawn_position(team: int) -> Vector2:
	## Get a random spawn position for a team
	var markers = player_spawn_markers if team == 0 else enemy_spawn_markers
	if markers.size() > 0:
		return markers[randi() % markers.size()].position
	
	# Fallback
	var margin: float = 100.0
	if team == 0:
		return Vector2(
			randf_range(margin, arena_size.x * 0.3),
			randf_range(margin, arena_size.y - margin)
		)
	else:
		return Vector2(
			randf_range(arena_size.x * 0.7, arena_size.x - margin),
			randf_range(margin, arena_size.y - margin)
		)

# ============================================================================
# UTILITY
# ============================================================================

func get_arena_bounds() -> Rect2:
	## Get the playable arena bounds
	return Rect2(Vector2.ZERO, arena_size)

func clamp_position_to_bounds(pos: Vector2, margin: float = 0.0) -> Vector2:
	## Clamp a position within arena bounds
	return pos.clamp(
		Vector2(margin, margin),
		Vector2(arena_size.x - margin, arena_size.y - margin)
	)

func is_position_valid(pos: Vector2, margin: float = 20.0) -> bool:
	## Check if a position is within valid arena bounds
	return pos.x >= margin and pos.x <= arena_size.x - margin \
	   and pos.y >= margin and pos.y <= arena_size.y - margin

func clear() -> void:
	## Clear all dynamic arena elements
	for child in obstacles.get_children():
		child.queue_free()
	for child in floor_details.get_children():
		if not child.name.begins_with("GridLine"):
			child.queue_free()
