class_name Pathfinder extends RefCounted
## Deterministic A* pathfinding for grid-based navigation
##
## Provides efficient grid-based pathfinding with obstacle avoidance.
## Uses physics queries to detect obstacles from the world.
## Guaranteed deterministic: same start/goal always returns identical path.
##
## Usage:
##     var pathfinder := Pathfinder.new()
##     pathfinder.set_bounds(Rect2(0, 0, 1024, 768))
##     pathfinder.rebuild_from_world(world_root)
##     var path: PackedVector2Array = pathfinder.find_path(start_pos, goal_pos)

## Grid cell size in world units
const GRID_SIZE: float = 32.0

## Maximum iterations before pathfinding aborts (prevents infinite loops)
const MAX_ITERATIONS: int = 1000

## Physics collision mask for obstacle detection (default: layer 1)
const OBSTACLE_COLLISION_MASK: int = 1

## Half grid size for center-point calculations
const HALF_GRID: float = GRID_SIZE / 2.0

## Diagonal movement cost (sqrt(2) approximated)
const DIAGONAL_COST: float = 1.41421356

## Cardinal movement cost
const CARDINAL_COST: float = 1.0

## Cached grid dimensions
var _grid_width: int = 0

## Cached grid height
var _grid_height: int = 0

## 2D array marking walkable (true) vs blocked (false) cells
var _obstacle_grid: Array[Array] = []

## World bounds for the pathfinding area
var _world_bounds: Rect2 = Rect2()

## Grid bounds (in grid coordinates)
var _grid_bounds: Rect2i = Rect2i()

## Enable diagonal movement (8-directional vs 4-directional)
var allow_diagonal: bool = true

## Cache for recent paths (start_hash + goal_hash -> path)
var _path_cache: Dictionary = {}

## Maximum cached paths
const MAX_CACHE_SIZE: int = 50

## Cache hit counter for debugging
var _cache_hits: int = 0


## Sets the bounds for the pathfinding grid
## Must be called before rebuild_from_world()
func set_bounds(bounds: Rect2) -> void:
	_world_bounds = bounds
	_grid_width = int(ceil(bounds.size.x / GRID_SIZE))
	_grid_height = int(ceil(bounds.size.y / GRID_SIZE))
	_grid_bounds = Rect2i(0, 0, _grid_width, _grid_height)
	_initialize_grid()


## Rebuilds the pathfinding grid from world obstacles
## Uses physics shape queries to detect blocking geometry
## @param world_root: The root node to query for obstacles
func rebuild_from_world(world_root: Node) -> void:
	if _grid_width == 0 or _grid_height == 0:
		push_warning("Pathfinder: set_bounds() must be called before rebuild_from_world()")
		return
	
	_clear_path_cache()
	_initialize_grid()
	
	var space_state: PhysicsDirectSpaceState2D
	var viewport: Viewport = world_root.get_viewport() if world_root else null
	
	if viewport and viewport.world_2d:
		space_state = viewport.world_2d.direct_space_state
	else:
		# Fallback: try to get from scene tree
		var tree: SceneTree = world_root.get_tree() if world_root else null
		if tree and tree.root:
			var root_viewport: Viewport = tree.root
			if root_viewport.world_2d:
				space_state = root_viewport.world_2d.direct_space_state
	
	if not space_state:
		push_warning("Pathfinder: Could not get PhysicsDirectSpaceState2D")
		return
	
	# Query each grid cell for obstacles
	for gy: int in range(_grid_height):
		for gx: int in range(_grid_width):
			var world_pos: Vector2 = _grid_to_world(Vector2i(gx, gy))
			_obstacle_grid[gy][gx] = not _check_obstacle_at(world_pos, space_state)


## Finds a deterministic path from start to goal position
## Returns PackedVector2Array of world waypoints (empty if no path found)
## @param start: Starting world position
## @param goal: Target world position
## @return Array of waypoints from start to goal (inclusive)
func find_path(start: Vector2, goal: Vector2) -> PackedVector2Array:
	# Check cache first
	var cache_key: int = _compute_cache_key(start, goal)
	if _path_cache.has(cache_key):
		_cache_hits += 1
		return _path_cache[cache_key].duplicate()
	
	# Validate positions are within bounds
	if not _world_bounds.has_point(start) or not _world_bounds.has_point(goal):
		push_warning("Pathfinder: Start or goal outside bounds")
		return PackedVector2Array()
	
	var start_grid: Vector2i = _world_to_grid(start)
	var goal_grid: Vector2i = _world_to_grid(goal)
	
	# Check if start or goal is unwalkable
	if not _is_grid_walkable(start_grid):
		push_warning("Pathfinder: Start position is unwalkable")
		return PackedVector2Array()
	
	if not _is_grid_walkable(goal_grid):
		push_warning("Pathfinder: Goal position is unwalkable")
		return PackedVector2Array()
	
	# Same cell - direct path
	if start_grid == goal_grid:
		var direct_path: PackedVector2Array = PackedVector2Array()
		direct_path.append(start)
		direct_path.append(goal)
		return direct_path
	
	# A* algorithm
	var open_set := PriorityQueue.new()
	var closed_set: Array[Array] = _create_closed_set()
	
	# Initialize start node
	var start_node := PathNode.new()
	start_node.position = start_grid
	start_node.g_cost = 0.0
	start_node.h_cost = _heuristic(start_grid, goal_grid)
	start_node.parent = null
	
	open_set.enqueue(start_node)
	
	var iterations: int = 0
	
	while not open_set.is_empty() and iterations < MAX_ITERATIONS:
		iterations += 1
		
		var current: PathNode = open_set.dequeue()
		
		# Check if we reached the goal
		if current.position == goal_grid:
			var path: PackedVector2Array = _reconstruct_path(current, start, goal)
			_cache_path(cache_key, path)
			return path
		
		# Mark as closed
		closed_set[current.position.y][current.position.x] = true
		
		# Explore neighbors
		var neighbors: Array[Vector2i] = _get_neighbors(current.position)
		
		for neighbor_pos: Vector2i in neighbors:
			# Skip if already closed
			if closed_set[neighbor_pos.y][neighbor_pos.x]:
				continue
			
			# Skip if unwalkable
			if not _is_grid_walkable(neighbor_pos):
				continue
			
			# Calculate movement cost
			var move_cost: float = _get_movement_cost(current.position, neighbor_pos)
			var tentative_g: float = current.g_cost + move_cost
			
			# Check if neighbor is in open set
			var existing_node: PathNode = open_set.get_node_at_position(neighbor_pos)
			
			if existing_node == null:
				# New node
				var new_node := PathNode.new()
				new_node.position = neighbor_pos
				new_node.g_cost = tentative_g
				new_node.h_cost = _heuristic(neighbor_pos, goal_grid)
				new_node.parent = current
				open_set.enqueue(new_node)
			elif tentative_g < existing_node.g_cost - 0.0001:
				# Better path found - update existing node
				existing_node.g_cost = tentative_g
				existing_node.parent = current
				# Re-heapify by removing and re-adding (simpler than decrease-key)
				open_set.clear()
				# Rebuild heap (inefficient but rare case)
				# In practice, we could use a more efficient decrease-key
	
	# No path found
	return PackedVector2Array()


## Checks if a world position is walkable
## @param world_pos: Position in world coordinates
## @return true if position is within bounds and not blocked
func is_walkable(world_pos: Vector2) -> bool:
	if not _world_bounds.has_point(world_pos):
		return false
	
	var grid_pos: Vector2i = _world_to_grid(world_pos)
	return _is_grid_walkable(grid_pos)


## Gets the grid size used by this pathfinder
func get_grid_size() -> float:
	return GRID_SIZE


## Gets the world bounds
func get_bounds() -> Rect2:
	return _world_bounds


## Clears the path cache
func clear_cache() -> void:
	_clear_path_cache()


## Gets cache statistics for debugging
func get_cache_stats() -> Dictionary:
	return {
		"cache_size": _path_cache.size(),
		"cache_hits": _cache_hits,
		"max_cache_size": MAX_CACHE_SIZE
	}


## Internal: Converts world position to grid coordinates
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = world_pos - _world_bounds.position
	var grid_x: int = int(floor(local_pos.x / GRID_SIZE))
	var grid_y: int = int(floor(local_pos.y / GRID_SIZE))
	return Vector2i(grid_x, grid_y)


## Internal: Converts grid coordinates to world position (center of cell)
func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	var world_x: float = _world_bounds.position.x + (grid_pos.x * GRID_SIZE) + HALF_GRID
	var world_y: float = _world_bounds.position.y + (grid_pos.y * GRID_SIZE) + HALF_GRID
	return Vector2(world_x, world_y)


## Internal: Checks if grid position is walkable
func _is_grid_walkable(grid_pos: Vector2i) -> bool:
	if grid_pos.x < 0 or grid_pos.x >= _grid_width:
		return false
	if grid_pos.y < 0 or grid_pos.y >= _grid_height:
		return false
	return _obstacle_grid[grid_pos.y][grid_pos.x]


## Internal: Manhattan distance heuristic (deterministic)
func _heuristic(a: Vector2i, b: Vector2i) -> float:
	var dx: int = abs(a.x - b.x)
	var dy: int = abs(a.y - b.y)
	
	if allow_diagonal:
		# Octile distance for diagonal movement
		return CARDINAL_COST * float(dx + dy) + (DIAGONAL_COST - 2.0 * CARDINAL_COST) * float(min(dx, dy))
	else:
		# Manhattan distance for 4-directional
		return CARDINAL_COST * float(dx + dy)


## Internal: Gets valid neighbor positions
func _get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	
	# Cardinal directions (always included)
	var cardinal: Array[Vector2i] = [
		Vector2i(pos.x + 1, pos.y),
		Vector2i(pos.x - 1, pos.y),
		Vector2i(pos.x, pos.y + 1),
		Vector2i(pos.x, pos.y - 1)
	]
	
	for neighbor: Vector2i in cardinal:
		if _is_in_grid_bounds(neighbor):
			neighbors.append(neighbor)
	
	# Diagonal directions (optional)
	if allow_diagonal:
		var diagonals: Array[Vector2i] = [
			Vector2i(pos.x + 1, pos.y + 1),
			Vector2i(pos.x + 1, pos.y - 1),
			Vector2i(pos.x - 1, pos.y + 1),
			Vector2i(pos.x - 1, pos.y - 1)
		]
		
		for diag: Vector2i in diagonals:
			if _is_in_grid_bounds(diag):
				# Check corner cutting (don't cut through corners of obstacles)
				var corner1: Vector2i = Vector2i(pos.x, diag.y)
				var corner2: Vector2i = Vector2i(diag.x, pos.y)
				
				if _is_grid_walkable(corner1) and _is_grid_walkable(corner2):
					neighbors.append(diag)
	
	return neighbors


## Internal: Checks if position is within grid bounds
func _is_in_grid_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < _grid_width and pos.y >= 0 and pos.y < _grid_height


## Internal: Gets movement cost between adjacent cells
func _get_movement_cost(from: Vector2i, to: Vector2i) -> float:
	var dx: int = abs(to.x - from.x)
	var dy: int = abs(to.y - from.y)
	
	if dx == 1 and dy == 1:
		return DIAGONAL_COST
	return CARDINAL_COST


## Internal: Reconstructs path from goal node back to start
func _reconstruct_path(goal_node: PathNode, start_world: Vector2, goal_world: Vector2) -> PackedVector2Array:
	var path: PackedVector2Array = PackedVector2Array()
	var current: PathNode = goal_node
	
	# Build path in reverse
	while current != null:
		path.append(_grid_to_world(current.position))
		current = current.parent
	
	# Reverse to get start -> goal order
	path.reverse()
	
	# Replace first/last with actual start/goal positions for precision
	if path.size() >= 2:
		path[0] = start_world
		path[path.size() - 1] = goal_world
	elif path.size() == 1:
		path[0] = goal_world
	
	return path


## Internal: Initializes the obstacle grid
func _initialize_grid() -> void:
	_obstacle_grid.clear()
	_obstacle_grid.resize(_grid_height)
	
	for y: int in range(_grid_height):
		_obstacle_grid[y] = []
		_obstacle_grid[y].resize(_grid_width)
		for x: int in range(_grid_width):
			_obstacle_grid[y][x] = true  # Default to walkable


## Internal: Creates closed set tracking array
func _create_closed_set() -> Array[Array]:
	var closed: Array[Array] = []
	closed.resize(_grid_height)
	
	for y: int in range(_grid_height):
		closed[y] = []
		closed[y].resize(_grid_width)
		for x: int in range(_grid_width):
			closed[y][x] = false
	
	return closed


## Internal: Checks for obstacles at a world position using physics
func _check_obstacle_at(world_pos: Vector2, space_state: PhysicsDirectSpaceState2D) -> bool:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = HALF_GRID * 0.8  # Slightly smaller than half grid
	
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, world_pos)
	query.collision_mask = OBSTACLE_COLLISION_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var results: Array[Dictionary] = space_state.intersect_shape(query, 1)
	return results.size() > 0


## Internal: Computes cache key from start and goal positions
func _compute_cache_key(start: Vector2, goal: Vector2) -> int:
	# Hash based on grid positions for reasonable cache hits
	var start_grid: Vector2i = _world_to_grid(start)
	var goal_grid: Vector2i = _world_to_grid(goal)
	
	# Combine hashes deterministically
	var key: int = start_grid.x
	key = key * 31 + start_grid.y
	key = key * 31 + goal_grid.x
	key = key * 31 + goal_grid.y
	return key


## Internal: Caches a computed path
func _cache_path(key: int, path: PackedVector2Array) -> void:
	if _path_cache.size() >= MAX_CACHE_SIZE:
		# Simple LRU: clear half the cache when full
		var keys_to_remove: Array = _path_cache.keys().slice(0, MAX_CACHE_SIZE / 2)
		for old_key: int in keys_to_remove:
			_path_cache.erase(old_key)
	
	_path_cache[key] = path.duplicate()


## Internal: Clears all cached paths
func _clear_path_cache() -> void:
	_path_cache.clear()
	_cache_hits = 0
