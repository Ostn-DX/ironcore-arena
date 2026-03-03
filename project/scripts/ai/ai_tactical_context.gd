class_name AITacticalContext extends RefCounted

## Shared context for AI decision making.
## Provides access to simulation state, cover points, and team information.
## This is a RefCounted object to avoid memory management issues.

# Cached references
var simulation_manager: Node = null
var squad_coordinator: SquadCoordinator = null

# Spatial data
var all_cover_points: PackedVector2Array = []
var cover_point_metadata: Dictionary = {}  # Vector2 -> Dictionary with cover data

# Arena bounds
var arena_bounds: Rect2 = Rect2()

# Team data cache
var _team_bots: Dictionary = {}  # team_id -> Array[Node]
var _all_bots: Array[Node] = []
var _bot_team_map: Dictionary = {}  # bot -> team_id

# Spatial partitioning for efficient queries
var _spatial_grid: Dictionary = {}  # grid_key -> Array[Node]
var _grid_cell_size: float = 200.0
var _spatial_dirty: bool = true

# Performance optimization
var _cache_timestamp: int = 0
var _cache_validity: int = 5  # Ticks before cache refresh


## Initializes the context with required references.
func initialize(sim_mgr: Node, coordinator: SquadCoordinator) -> void:
    simulation_manager = sim_mgr
    squad_coordinator = coordinator


## Sets the cover points for the arena.
func set_cover_points(points: PackedVector2Array) -> void:
    all_cover_points = points
    
    # Initialize metadata for each cover point
    cover_point_metadata.clear()
    for point: Vector2 in points:
        cover_point_metadata[point] = {
            "strength": 1.0,  # How good is this cover
            "direction": Vector2.ZERO,  # Direction cover faces
            "occupied_by": -1,  # sim_id of occupying bot, -1 if free
            "last_occupied": 0  # Timestamp when last occupied
        }


## Sets arena bounds for position clamping.
func set_arena_bounds(bounds: Rect2) -> void:
    arena_bounds = bounds


## Registers a bot with the context.
func register_bot(bot: Node, team_id: int) -> void:
    if not _team_bots.has(team_id):
        _team_bots[team_id] = []
    
    var team_list: Array[Node] = _team_bots[team_id]
    if not team_list.has(bot):
        team_list.append(bot)
    
    if not _all_bots.has(bot):
        _all_bots.append(bot)
    
    _bot_team_map[bot] = team_id
    _spatial_dirty = true


## Unregisters a bot from the context.
func unregister_bot(bot: Node) -> void:
    var team_id: int = _bot_team_map.get(bot, -1)
    
    if team_id >= 0 and _team_bots.has(team_id):
        var team_list: Array[Node] = _team_bots[team_id]
        team_list.erase(bot)
    
    _all_bots.erase(bot)
    _bot_team_map.erase(bot)
    _spatial_dirty = true
    
    # Release any cover point this bot was occupying
    _release_cover_for_bot(bot)


## Gets all enemy bots for a given bot.
func get_enemies_of(bot: Node) -> Array[Node]:
    var bot_team: int = _bot_team_map.get(bot, -1)
    if bot_team < 0:
        return []
    
    var enemies: Array[Node] = []
    
    for team_id: int in _team_bots.keys():
        if team_id != bot_team:
            var team_bots: Array[Node] = _team_bots[team_id]
            for enemy: Node in team_bots:
                if _is_bot_alive(enemy):
                    enemies.append(enemy)
    
    return enemies


## Gets all allied bots for a given bot.
func get_allies_of(bot: Node) -> Array[Node]:
    var bot_team: int = _bot_team_map.get(bot, -1)
    if bot_team < 0:
        return []
    
    var allies: Array[Node] = []
    var team_bots: Array[Node] = _team_bots.get(bot_team, [])
    
    for ally: Node in team_bots:
        if ally != bot and _is_bot_alive(ally):
            allies.append(ally)
    
    return allies


## Gets all bots on a specific team.
func get_team_bots(team_id: int) -> Array[Node]:
    var bots: Array[Node] = _team_bots.get(team_id, [])
    var alive_bots: Array[Node] = []
    
    for bot: Node in bots:
        if _is_bot_alive(bot):
            alive_bots.append(bot)
    
    return alive_bots


## Gets all bots in the simulation.
func get_all_bots() -> Array[Node]:
    var alive_bots: Array[Node] = []
    
    for bot: Node in _all_bots:
        if _is_bot_alive(bot):
            alive_bots.append(bot)
    
    return alive_bots


## Gets cover points near a position.
func get_cover_points_near(pos: Vector2, radius: float) -> PackedVector2Array:
    var nearby: PackedVector2Array = []
    
    for cover_point: Vector2 in all_cover_points:
        if pos.distance_to(cover_point) <= radius:
            nearby.append(cover_point)
    
    return nearby


## Gets the best available cover point near a position.
func get_best_cover_near(
    pos: Vector2,
    radius: float,
    enemy_positions: PackedVector2Array,
    exclude_bot: Node = null
) -> Vector2:
    var best_cover: Vector2 = pos
    var best_score: float = -999999.0
    
    for cover_point: Vector2 in all_cover_points:
        var dist: float = pos.distance_to(cover_point)
        if dist > radius:
            continue
        
        # Check if cover is occupied
        var metadata: Dictionary = cover_point_metadata.get(cover_point, {})
        var occupied_by: int = metadata.get("occupied_by", -1)
        
        if occupied_by >= 0:
            var occupying_bot: Node = _get_bot_by_id(occupied_by)
            if occupying_bot != null and occupying_bot != exclude_bot:
                continue  # Cover is taken
        
        # Score this cover point
        var score: float = _score_cover_point(cover_point, enemy_positions)
        score -= dist * 0.1  # Prefer closer cover
        
        if score > best_score:
            best_score = score
            best_cover = cover_point
    
    return best_cover


## Claims a cover point for a bot.
func claim_cover_point(cover_point: Vector2, bot: Node) -> bool:
    if not cover_point_metadata.has(cover_point):
        return false
    
    var metadata: Dictionary = cover_point_metadata[cover_point]
    var occupied_by: int = metadata.get("occupied_by", -1)
    
    # Already occupied by someone else
    if occupied_by >= 0 and occupied_by != _get_bot_id(bot):
        return false
    
    metadata["occupied_by"] = _get_bot_id(bot)
    return true


## Releases a cover point.
func release_cover_point(cover_point: Vector2) -> void:
    if cover_point_metadata.has(cover_point):
        cover_point_metadata[cover_point]["occupied_by"] = -1


## Gets bots near a position using spatial partitioning.
func get_bots_near(pos: Vector2, radius: float) -> Array[Node]:
    _update_spatial_grid()
    
    var nearby: Array[Node] = []
    var radius_sq: float = radius * radius
    
    # Get relevant grid cells
    var min_cell: Vector2i = _world_to_grid(pos - Vector2(radius, radius))
    var max_cell: Vector2i = _world_to_grid(pos + Vector2(radius, radius))
    
    for x: int in range(min_cell.x, max_cell.x + 1):
        for y: int in range(min_cell.y, max_cell.y + 1):
            var cell_key: String = "%d,%d" % [x, y]
            var cell_bots: Array = _spatial_grid.get(cell_key, [])
            
            for bot: Node in cell_bots:
                var bot_pos: Vector2 = _get_bot_position(bot)
                if bot_pos.distance_squared_to(pos) <= radius_sq:
                    nearby.append(bot)
    
    return nearby


## Gets the team ID for a bot.
func get_bot_team(bot: Node) -> int:
    return _bot_team_map.get(bot, -1)


## Checks if a position is valid (inside arena bounds).
func is_valid_position(pos: Vector2) -> bool:
    if arena_bounds.has_area():
        return arena_bounds.has_point(pos)
    return true


## Clamps a position to arena bounds.
func clamp_position(pos: Vector2) -> Vector2:
    if arena_bounds.has_area():
        return pos.clamp(
            arena_bounds.position,
            arena_bounds.position + arena_bounds.size
        )
    return pos


## Updates the spatial grid for efficient queries.
func _update_spatial_grid() -> void:
    if not _spatial_dirty:
        return
    
    _spatial_grid.clear()
    
    for bot: Node in _all_bots:
        if not _is_bot_alive(bot):
            continue
        
        var pos: Vector2 = _get_bot_position(bot)
        var cell: Vector2i = _world_to_grid(pos)
        var cell_key: String = "%d,%d" % [cell.x, cell.y]
        
        if not _spatial_grid.has(cell_key):
            _spatial_grid[cell_key] = []
        
        _spatial_grid[cell_key].append(bot)
    
    _spatial_dirty = false


## Converts world position to grid cell.
func _world_to_grid(pos: Vector2) -> Vector2i:
    return Vector2i(
        floori(pos.x / _grid_cell_size),
        floori(pos.y / _grid_cell_size)
    )


## Scores a cover point based on enemy positions.
func _score_cover_point(cover_point: Vector2, enemy_positions: PackedVector2Array) -> float:
    var score: float = 0.0
    
    var metadata: Dictionary = cover_point_metadata.get(cover_point, {})
    var cover_strength: float = metadata.get("strength", 1.0)
    score += cover_strength * 50.0
    
    # Score based on how many enemies this cover protects against
    for enemy_pos: Vector2 in enemy_positions:
        # Simplified: closer enemies mean more valuable cover
        var dist: float = cover_point.distance_to(enemy_pos)
        score += 100.0 / (dist + 1.0)
    
    return score


## Releases cover point occupied by a bot.
func _release_cover_for_bot(bot: Node) -> void:
    var bot_id: int = _get_bot_id(bot)
    
    for cover_point: Vector2 in cover_point_metadata.keys():
        var metadata: Dictionary = cover_point_metadata[cover_point]
        if metadata.get("occupied_by", -1) == bot_id:
            metadata["occupied_by"] = -1


## Gets a bot by its simulation ID.
func _get_bot_by_id(sim_id: int) -> Node:
    for bot: Node in _all_bots:
        if _get_bot_id(bot) == sim_id:
            return bot
    return null


## Checks if a bot is alive.
func _is_bot_alive(bot: Node) -> bool:
    if bot == null:
        return false
    if bot.has_method("is_alive"):
        return bot.is_alive()
    return true


## Gets a bot's position.
func _get_bot_position(bot: Node) -> Vector2:
    if bot != null and bot.has_method("get_global_position"):
        return bot.global_position
    return Vector2.ZERO


## Gets a bot's simulation ID.
func _get_bot_id(bot: Node) -> int:
    if bot != null and bot.has_method("get_sim_id"):
        return bot.get_sim_id()
    return -1
