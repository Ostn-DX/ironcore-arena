extends Node
## SimulationManager singleton - runs combat simulation in _physics_process.
## Owns bot/projectile/hazard arrays. Exposes start_battle(), issue_command() .
## Signals for tick events and battle end. Can run headless.
## OPTIMIZED: Reduced debug prints, cached lookups, pool usage
## INTEGRATED: AI Combat System v1.0

# Preload AI system components
const SquadCoordinator = preload("res://scripts/ai/squad_coordinator.gd")
const AITacticalContext = preload("res://scripts/ai/ai_tactical_context.gd")
const Pathfinder = preload("res://scripts/ai/pathfinder.gd")
const AIDebugDraw = preload("res://scripts/ai/ai_debug_draw.gd")
const BotAIAdvanced = preload("res://scripts/ai/bot_ai_advanced.gd")
const Bot = preload("res://src/entities/bot.gd")

const TICKS_PER_SECOND: float = 60.0
const DT: float = 1.0 / TICKS_PER_SECOND
const MAX_TICKS: int = 10800  # 3 minutes

@onready var _data_loader = get_node("/root/DataLoader")

# Signals
signal tick_processed(tick: int)
signal entity_moved(sim_id: int, position: Vector2, rotation: float)
signal entity_damaged(sim_id: int, hp: int, max_hp: int)
signal entity_destroyed(sim_id: int, team: int)
signal projectile_spawned(proj_id: int, position: Vector2, direction: Vector2)
signal projectile_destroyed(proj_id: int)
signal battle_ended(result: String, tick_count: int)
signal command_issued(bot_id: int, command_type: String, target: Variant)

# Simulation state
var is_running: bool = false
var is_paused: bool = false
var headless: bool = false
var current_tick: int = 0

# Entities
var bots: Dictionary = {}  # sim_id -> Bot
var projectiles: Dictionary = {}  # proj_id -> Projectile
var obstacles: Array[Dictionary] = []
var arena_size: Vector2 = Vector2(800, 600)

# Pools - object reuse to reduce GC
var _next_bot_id: int = 1
var _next_proj_id: int = 1

# RNG
var rng: RefCounted = null

# Arena data
var current_arena: Dictionary = {}
var player_spawn_points: Array[Vector2] = []
var enemy_spawn_points: Array[Vector2] = []

# Commands queue (player inputs)
var _pending_commands: Array[Dictionary] = []

# Cached part data - loaded once per battle
var _part_data: Dictionary = {}

# Performance: Pre-allocated arrays for sorting
var _sorted_bot_ids: Array = []
var _sorted_proj_list: Array = []

# ============================================================================
# AI COMBAT SYSTEM INTEGRATION - Added by AGENT-001
# ============================================================================

## Enable AI debug visualization
@export var enable_ai_debug: bool = false

## Arena boundaries for position clamping and pathfinding
@export var arena_bounds: Rect2 = Rect2(-400, -300, 800, 600)

## Cover points for tactical AI (optional, can be set at runtime)
@export var cover_points: PackedVector2Array = []

## Squad coordinator for team-wide tactics
var _squad_coordinator = null

## Tactical context shared between all AI agents
var _tactical_context = null

## A* pathfinder for obstacle avoidance
var _pathfinder = null

## Debug visualization system
var _debug_draw = null

## Active team IDs for squad coordination
var _active_teams: Array[int] = [0, 1]

## Bot scene reference for spawning
@export var bot_scene: PackedScene = null

## Array of all bots for AI queries
var _bots_array: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_ai_system()

func _initialize_ai_system() -> void:
	if headless:
		return
	
	# Create squad coordinator
	_squad_coordinator = SquadCoordinator.new()
	_squad_coordinator.name = "SquadCoordinator"
	add_child(_squad_coordinator)
	
	# Create tactical context
	_tactical_context = AITacticalContext.new()
	_tactical_context.initialize(self, _squad_coordinator)
	_tactical_context.set_arena_bounds(arena_bounds)
	
	# Set cover points
	if not cover_points.is_empty():
		_tactical_context.set_cover_points(cover_points)
	
	# Create pathfinder
	_pathfinder = Pathfinder.new()
	_pathfinder.set_bounds(arena_bounds)
	
	# Create debug drawer
	if enable_ai_debug:
		_debug_draw = AIDebugDraw.new()
		_debug_draw.name = "AIDebugDraw"
		_debug_draw.enabled = true
		_debug_draw.set_squad_coordinator(_squad_coordinator)
		_debug_draw.set_tactical_context(_tactical_context)
		add_child(_debug_draw)

func _physics_process(_delta: float) -> void:
	if not is_running or is_paused:
		return
	
	current_tick += 1
	
	# Update AI systems
	if _squad_coordinator != null:
		for team_id in _active_teams:
			var team_bots: Array[Node] = _get_bots_by_team(team_id)
			var enemy_bots: Array[Node] = _get_enemy_bots(team_id)
			_squad_coordinator.update_team(team_id, team_bots, enemy_bots, current_tick)
	
	# Update bot AI controllers
	for bot in _bots_array:
		if bot.is_alive() and bot.has_method("get_ai_controller"):
			var ai = bot.get_ai_controller()
			if ai != null and ai.has_method("make_decision"):
				ai.make_decision(current_tick)
	
	_run_tick()
	
	# Update debug visualization
	if _debug_draw != null and _debug_draw.enabled:
		_debug_draw.queue_redraw()

func _get_bots_by_team(team_id: int) -> Array[Node]:
	var result: Array[Node] = []
	for bot in _bots_array:
		if bot.team == team_id:
			result.append(bot)
	return result

func _get_enemy_bots(team_id: int) -> Array[Node]:
	var result: Array[Node] = []
	for bot in _bots_array:
		if bot.team != team_id:
			result.append(bot)
	return result

func start_battle(arena_data: Dictionary, player_loadouts: Array, enemy_loadouts: Array, 
				  p_headless: bool = false) -> void:
	## Start a new battle simulation
	headless = p_headless
	current_arena = arena_data
	is_running = true
	is_paused = false
	current_tick = 0
	
	# Clear state
	bots.clear()
	projectiles.clear()
	_pending_commands.clear()
	_bots_array.clear()
	_next_bot_id = 1
	_next_proj_id = 1
	
	# Re-initialize AI with new bounds
	_initialize_ai_system()
	
	# Load part data
	_load_part_data()
	
	# Setup arena
	_setup_arena(arena_data)
	
	# Seed RNG
	var seed_val: int = arena_data.get("seed", hash(arena_data.get("id", "") + str(Time.get_unix_time_from_system())))
	rng = preload("res://src/systems/deterministic_rng.gd").new(seed_val)
	
	# Spawn bots
	_spawn_team(player_loadouts, 0, player_spawn_points)
	_spawn_team(enemy_loadouts, 1, enemy_spawn_points)

func stop_battle() -> void:
	is_running = false
	bots.clear()
	projectiles.clear()
	_pending_commands.clear()
	_bots_array.clear()

func _run_tick() -> void:
	if current_tick >= MAX_TICKS:
		battle_ended.emit("timeout", current_tick)
		stop_battle()
		return
	
	# Process pending commands
	_process_commands()
	
	# Update bots
	for bot_id in bots:
		var bot: Bot = bots[bot_id]
		if bot.is_alive():
			bot.process_tick(DT)
			tick_processed.emit(current_tick)

func _process_commands() -> void:
	for cmd in _pending_commands:
		command_issued.emit(cmd.bot_id, cmd.type, cmd.target)
	_pending_commands.clear()

func _load_part_data() -> void:
	_part_data = {
		"chassis": _data_loader.get_all_chassis(),
		"weapons": _data_loader.get_all_weapons(),
		"plating": _data_loader.get_all_plating()
	}

func _setup_arena(arena_data: Dictionary) -> void:
	arena_size = Vector2(
		arena_data.get("width", 800),
		arena_data.get("height", 600)
	)
	
	# Setup spawn points
	player_spawn_points.clear()
	enemy_spawn_points.clear()
	
	var spawn_config = arena_data.get("spawns", {})
	for spawn in spawn_config.get("player", []):
		player_spawn_points.append(Vector2(spawn.x, spawn.y))
	for spawn in spawn_config.get("enemy", []):
		enemy_spawn_points.append(Vector2(spawn.x, spawn.y))

func _spawn_team(loadouts: Array, team: int, spawn_points: Array) -> void:
	for i in range(loadouts.size()):
		if i >= spawn_points.size():
			break
		
		var loadout: Dictionary = loadouts[i]
		var spawn_pos: Vector2 = spawn_points[i]
		
		var bot = Bot.new(_next_bot_id, team, spawn_pos)
		bot.sim_id = _next_bot_id
		_next_bot_id += 1
		
		# Setup bot from loadout
		bot.setup(loadout, team, spawn_pos)
		
		# Note: Bot is RefCounted, not Node - AI controller attaches differently
		# AI will be managed by SimulationManager, not as child node
		
		bots[bot.sim_id] = bot
		_bots_array.append(bot)
		
		if _tactical_context != null:
			_tactical_context.register_bot(bot, team)

func issue_command(bot_id: int, cmd_type: String, target: Variant) -> void:
	_pending_commands.append({
		"bot_id": bot_id,
		"type": cmd_type,
		"target": target
	})

func get_bot(bot_id: int) -> Bot:
	return bots.get(bot_id, null)

func get_all_bots() -> Array[Bot]:
	return _bots_array.duplicate()

func get_sim_tick() -> int:
	return current_tick

func query_bots_in_radius(center: Vector2, radius: float) -> Array[Node]:
	var result: Array[Node] = []
	var radius_sq: float = radius * radius
	for bot in _bots_array:
		if center.distance_squared_to(bot.position) <= radius_sq:
			result.append(bot)
	return result

func query_visible_bots(viewer: Node, max_range: float, view_angle: float) -> Array[Node]:
	var result: Array[Node] = []
	var viewer_pos: Vector2 = viewer.position
	var viewer_forward: Vector2 = Vector2.RIGHT.rotated(viewer.rotation)
	var half_angle: float = view_angle * 0.5
	var range_sq: float = max_range * max_range
	
	for bot in _bots_array:
		if bot.team == viewer.team or not bot.is_alive():
			continue
		
		var to_bot: Vector2 = bot.position - viewer_pos
		var dist_sq: float = to_bot.length_squared()
		
		if dist_sq > range_sq:
			continue
		
		var angle: float = viewer_forward.angle_to(to_bot.normalized())
		if absf(angle) <= half_angle:
			result.append(bot)
	
	return result

func toggle_debug() -> void:
	if _debug_draw != null:
		_debug_draw.toggle()
