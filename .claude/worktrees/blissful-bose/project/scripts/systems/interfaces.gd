## @file shared/interfaces.gd
## @brief Core interface definitions for Bot and SimulationManager.
## @description
## This file defines the interface contracts that all Bot implementations and
## the SimulationManager must follow. These interfaces ensure interoperability
## between different AI implementations and the simulation core.
##
## IMPLEMENTATION NOTES:
## - All Bot implementations must extend SimBotBase or implement ISimBot directly
## - All AI components receive ISimulationManager reference for queries
## - All methods must be deterministic - see determinism_contract.md
## - Type hints are mandatory for all public methods

class_name SimInterfaces
extends RefCounted

# =============================================================================
# INTERFACE DOCUMENTATION
# =============================================================================

##
## ISimBot Interface Contract
## ==========================
##
## All bot implementations MUST provide these properties and methods:
##
## REQUIRED PROPERTIES (with @export for editor visibility):
## -----------------------------------------------------------------------------
## @export var sim_id: int                    ## Unique identifier for this bot
## @export var team: int                      ## Team ID (use SimConstants.TEAM_*)
## @export var position: Vector2              ## Current world position
## @export var health: float                  ## Current health (0.0 to max_health)
## @export var max_health: float              ## Maximum health capacity
##
## REQUIRED METHODS (must be deterministic):
## -----------------------------------------------------------------------------
## func process_tick(dt: float) -> void
##     Called every simulation tick. Update bot state here.
##     @param dt: Fixed timestep (SimConstants.TIMESTEP)
##
## func set_move_target(pos: Vector2) -> void
##     Set the movement target position.
##     @param pos: Target world position (will be clamped to arena)
##
## func set_aim_target(pos: Vector2) -> void
##     Set the aim target position (where bot is looking/shooting).
##     @param pos: Target world position for aiming
##
## func set_fire(active: bool) -> void
##     Set firing state.
##     @param active: true to fire, false to stop firing
##
## func get_role() -> String
##     Get the bot's tactical role identifier.
##     @return: Role string (e.g., "assault", "sniper", "support")
##
## func is_alive() -> bool
##     Check if bot is alive and active.
##     @return: true if health > 0
##
## func take_damage(amount: float, source_id: int) -> void
##     Apply damage to this bot.
##     @param amount: Damage amount to apply
##     @param source_id: sim_id of the attacker (for kill tracking)
##
## func get_position() -> Vector2
##     Get current position (for interface consistency).
##     @return: Current world position
##
## func get_forward() -> Vector2
##     Get forward direction vector.
##     @return: Normalized forward direction
##
## OPTIONAL PROPERTIES (with defaults):
## -----------------------------------------------------------------------------
## var velocity: Vector2 = Vector2.ZERO       ## Current velocity
## var rotation: float = 0.0                  ## Current rotation in radians
## var fire_cooldown: float = 0.0             ## Remaining fire cooldown
## var move_speed: float = 200.0              ## Movement speed override
##

##
## ISimulationManager Interface Contract
## =====================================
##
## The simulation manager MUST provide these query methods:
##
## REQUIRED METHODS (must be deterministic):
## -----------------------------------------------------------------------------
## func get_sim_tick() -> int
##     Get the current simulation tick number.
##     @return: Current tick (increments by 1 each TIMESTEP)
##
## func get_all_bots() -> Array[Node]
##     Get all active bots in the simulation.
##     @return: Array of all bot nodes implementing ISimBot
##
## func get_bots_by_team(team_id: int) -> Array[Node]
##     Get all bots belonging to a specific team.
##     @param team_id: Team ID to filter by
##     @return: Array of bot nodes on the specified team
##
## func get_enemy_bots(team_id: int) -> Array[Node]
##     Get all bots that are enemies of the specified team.
##     @param team_id: Friendly team ID
##     @return: Array of enemy bot nodes
##
## func get_projectiles() -> Array[Node]
##     Get all active projectiles.
##     @return: Array of active projectile nodes
##
## func get_rng() -> DeterministicRng
##     Get the deterministic random number generator.
##     @return: Reference to the simulation's RNG
##
## func get_bot_by_id(bot_id: int) -> Node
##     Get a specific bot by its sim_id.
##     @param bot_id: The bot's unique sim_id
##     @return: Bot node or null if not found
##
## func query_bots_in_radius(center: Vector2, radius: float) -> Array[Node]
##     Spatial query: get all bots within radius of center.
##     @param center: Query center position
##     @param radius: Query radius
##     @return: Array of bots within the radius
##
## func query_visible_bots(viewer: Node, max_range: float, view_angle: float) -> Array[Node]
##     Get all bots visible from viewer's position.
##     @param viewer: The bot doing the viewing
##     @param max_range: Maximum visibility range
##     @param view_angle: Total view cone angle in radians
##     @return: Array of visible enemy bots
##
## func get_game_phase() -> SimConstants.GamePhase
##     Get current game phase.
##     @return: Current game phase enum value
##
## func get_match_time_remaining() -> float
##     Get remaining match time in seconds.
##     @return: Time remaining, or -1.0 if no time limit
##
## func get_score(team_id: int) -> int
##     Get current score for a team.
##     @param team_id: Team to query
##     @return: Current score (kills, points, etc.)
##

# =============================================================================
# BASE CLASSES (Abstract)
# =============================================================================

## Base class for all simulation bots.
## Extend this class and override required methods.
## @abstract
class SimBotBase:
	extends Node2D
	
	# -------------------------------------------------------------------------
	# REQUIRED EXPORTS (must be set in editor or _ready)
	# -------------------------------------------------------------------------
	@export var sim_id: int = -1
	@export var team: int = SimConstants.TEAM_NONE
	@export var health: float = SimConstants.BOT_DEFAULT_HEALTH
	@export var max_health: float = SimConstants.BOT_DEFAULT_MAX_HEALTH
	
	# -------------------------------------------------------------------------
	# INTERNAL STATE (do not modify directly from outside)
	# -------------------------------------------------------------------------
	var _move_target: Vector2 = Vector2.ZERO
	var _aim_target: Vector2 = Vector2.ZERO
	var _fire_active: bool = false
	var _fire_cooldown: float = 0.0
	var _ai_controller: Node = null
	var _state: SimConstants.BotState = SimConstants.BotState.IDLE
	
	# -------------------------------------------------------------------------
	# REQUIRED OVERRIDES
	# -------------------------------------------------------------------------
	
	## Process one simulation tick. MUST be deterministic.
	## @param dt: Fixed timestep duration
	## @virtual
	func process_tick(_dt: float) -> void:
		push_error("SimBotBase.process_tick() must be overridden")
	
	
	## Get the bot's tactical role.
	## @return: Role identifier string
	## @virtual
	func get_role() -> String:
		push_error("SimBotBase.get_role() must be overridden")
		return "unknown"
	
	
	# -------------------------------------------------------------------------
	# PUBLIC API (called by AI controllers)
	# -------------------------------------------------------------------------
	
	## Set movement target position.
	## @param pos: Target world position
	func set_move_target(pos: Vector2) -> void:
		_move_target = SimConstants.clamp_to_arena(pos)
		if _state == SimConstants.BotState.IDLE:
			_state = SimConstants.BotState.MOVING
	
	
	## Set aim target position.
	## @param pos: World position to aim at
	func set_aim_target(pos: Vector2) -> void:
		_aim_target = pos
	
	
	## Set firing state.
	## @param active: true to fire, false to stop
	func set_fire(active: bool) -> void:
		_fire_active = active
	
	
	## Check if bot is alive.
	## @return: true if health > 0
	func is_alive() -> bool:
		return health > 0.0
	
	
	## Apply damage to this bot.
	## @param amount: Damage amount
	## @param source_id: Attacker's sim_id
	func take_damage(amount: float, source_id: int) -> void:
		if not is_alive():
			return
		
		health = maxf(0.0, health - amount)
		
		if health <= 0.0:
			_state = SimConstants.BotState.DEAD
			_on_death(source_id)
	
	
	## Get current position.
	## @return: World position
	func get_position() -> Vector2:
		return position
	
	
	## Get forward direction vector.
	## @return: Normalized forward vector
	func get_forward() -> Vector2:
		return Vector2.RIGHT.rotated(rotation)
	
	
	## Get current state.
	## @return: Current BotState enum value
	func get_state() -> SimConstants.BotState:
		return _state
	
	
	## Get the AI controller assigned to this bot.
	## @return: AI controller node or null
	func get_ai_controller() -> Node:
		return _ai_controller
	
	
	## Assign an AI controller to this bot.
	## @param controller: AI controller node
	func set_ai_controller(controller: Node) -> void:
		_ai_controller = controller
	
	
	# -------------------------------------------------------------------------
	# PROTECTED METHODS (override in subclasses)
	# -------------------------------------------------------------------------
	
	## Called when bot dies. Override for death effects.
	## @param killer_id: sim_id of the killer
	## @virtual
	func _on_death(_killer_id: int) -> void:
		pass


## Base class for simulation managers.
## Extend this to implement the simulation coordinator.
## @abstract
class SimulationManagerBase:
	extends Node
	
	# -------------------------------------------------------------------------
	# INTERNAL STATE
	# -------------------------------------------------------------------------
	var _current_tick: int = 0
	var _bots: Dictionary = {}  ## {int: Node} - sim_id to bot mapping
	var _projectiles: Array[Node] = []
	var _rng: RefCounted = null  ## DeterministicRng instance
	var _game_phase: SimConstants.GamePhase = SimConstants.GamePhase.SETUP
	var _team_scores: Dictionary = {}  ## {int: int} - team to score mapping
	
	# -------------------------------------------------------------------------
	# REQUIRED OVERRIDES
	# -------------------------------------------------------------------------
	
	## Initialize the simulation. Called once before first tick.
	## @virtual
	func initialize_simulation() -> void:
		push_error("SimulationManagerBase.initialize_simulation() must be overridden")
	
	
	## Process one simulation tick. MUST be deterministic.
	## @param dt: Fixed timestep duration
	## @virtual
	func process_simulation_tick(_dt: float) -> void:
		push_error("SimulationManagerBase.process_simulation_tick() must be overridden")
	
	
	# -------------------------------------------------------------------------
	# PUBLIC QUERY API (called by AI controllers and bots)
	# -------------------------------------------------------------------------
	
	## Get current simulation tick.
	## @return: Current tick number
	func get_sim_tick() -> int:
		return _current_tick
	
	
	## Get all active bots.
	## @return: Array of all bot nodes
	func get_all_bots() -> Array[Node]:
		var result: Array[Node] = []
		result.assign(_bots.values())
		return result
	
	
	## Get bots by team.
	## @param team_id: Team to filter by
	## @return: Array of bots on the specified team
	func get_bots_by_team(team_id: int) -> Array[Node]:
		var result: Array[Node] = []
		for bot in _bots.values():
			if bot.team == team_id:
				result.append(bot)
		return result
	
	
	## Get enemy bots for a team.
	## @param team_id: Friendly team
	## @return: Array of enemy bots
	func get_enemy_bots(team_id: int) -> Array[Node]:
		var result: Array[Node] = []
		for bot in _bots.values():
			if bot.team != team_id and bot.team != SimConstants.TEAM_NONE:
				result.append(bot)
		return result
	
	
	## Get all active projectiles.
	## @return: Array of projectile nodes
	func get_projectiles() -> Array[Node]:
		return _projectiles.duplicate()
	
	
	## Get the deterministic RNG.
	## @return: RNG reference (DeterministicRng type)
	func get_rng() -> RefCounted:
		return _rng
	
	
	## Get bot by sim_id.
	## @param bot_id: Bot's unique ID
	## @return: Bot node or null
	func get_bot_by_id(bot_id: int) -> Node:
		return _bots.get(bot_id, null)
	
	
	## Query bots in radius.
	## @param center: Query center
	## @param radius: Query radius
	## @return: Array of bots within radius
	func query_bots_in_radius(center: Vector2, radius: float) -> Array[Node]:
		var result: Array[Node] = []
		var radius_sq: float = radius * radius
		
		for bot in _bots.values():
			if center.distance_squared_to(bot.position) <= radius_sq:
				result.append(bot)
		
		return result
	
	
	## Query visible enemy bots.
	## @param viewer: Bot doing the viewing
	## @param max_range: Maximum visibility range
	## @param view_angle: Total view cone angle
	## @return: Array of visible enemy bots
	func query_visible_bots(viewer: Node, max_range: float, view_angle: float) -> Array[Node]:
		var result: Array[Node] = []
		var viewer_pos: Vector2 = viewer.position
		var viewer_forward: Vector2 = viewer.get_forward()
		var half_angle: float = view_angle * 0.5
		var range_sq: float = max_range * max_range
		
		for bot in _bots.values():
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
	
	
	## Get current game phase.
	## @return: Current game phase
	func get_game_phase() -> SimConstants.GamePhase:
		return _game_phase
	
	
	## Get match time remaining.
	## @return: Time in seconds, or -1.0 if unlimited
	## @virtual
	func get_match_time_remaining() -> float:
		return -1.0
	
	
	## Get team score.
	## @param team_id: Team to query
	## @return: Current score
	func get_score(team_id: int) -> int:
		return _team_scores.get(team_id, 0)
	
	
	# -------------------------------------------------------------------------
	# REGISTRATION API (called during setup)
	# -------------------------------------------------------------------------
	
	## Register a bot with the simulation.
	## @param bot: Bot node to register
	## @return: true if registration succeeded
	func register_bot(bot: Node) -> bool:
		if bot.sim_id < 0:
			push_error("Cannot register bot with invalid sim_id")
			return false
		
		if _bots.has(bot.sim_id):
			push_error("Bot with sim_id %d already registered" % bot.sim_id)
			return false
		
		_bots[bot.sim_id] = bot
		return true
	
	
	## Unregister a bot.
	## @param bot_id: sim_id of bot to remove
	func unregister_bot(bot_id: int) -> void:
		_bots.erase(bot_id)
	
	
	## Register a projectile.
	## @param projectile: Projectile node to register
	func register_projectile(projectile: Node) -> void:
		_projectiles.append(projectile)
	
	
	## Unregister a projectile.
	## @param projectile: Projectile to remove
	func unregister_projectile(projectile: Node) -> void:
		_projectiles.erase(projectile)


## Interface for deterministic random number generation.
## All random operations in the simulation must use this.
## @abstract
class DeterministicRng:
	extends RefCounted
	
	var _seed: int = SimConstants.DEFAULT_RNG_SEED
	var _state: int = 0
	var _call_count: int = 0
	
	## Initialize with a seed.
	## @param seed_value: RNG seed
	func initialize(seed_value: int) -> void:
		_seed = seed_value
		_state = seed_value
		_call_count = 0
	
	
	## Get a deterministic random float in range [0.0, 1.0).
	## @return: Random float value
	func random_float() -> float:
		_call_count += 1
		# Linear congruential generator for determinism
		_state = (_state * 1103515245 + 12345) & 0x7FFFFFFF
		return float(_state) / 2147483648.0
	
	
	## Get a deterministic random integer in range [min_val, max_val].
	## @param min_val: Minimum value (inclusive)
	## @param max_val: Maximum value (inclusive)
	## @return: Random integer
	func random_int(min_val: int, max_val: int) -> int:
		var range_size: int = max_val - min_val + 1
		return min_val + int(random_float() * range_size)
	
	
	## Get deterministic random bool with given probability.
	## @param probability: Chance of returning true (0.0 to 1.0)
	## @return: Random boolean
	func random_bool(probability: float = 0.5) -> bool:
		return random_float() < probability
	
	
	## Get deterministic random Vector2 in unit circle.
	## @return: Random normalized vector
	func random_direction() -> Vector2:
		var angle: float = random_float() * TAU
		return Vector2(cos(angle), sin(angle))
	
	
	## Get current seed.
	## @return: Current RNG seed
	func get_seed() -> int:
		return _seed
	
	
	## Get number of calls made to this RNG.
	## @return: Call count (useful for debugging determinism)
	func get_call_count() -> int:
		return _call_count
	
	
	## Serialize RNG state for save/replay.
	## @return: Dictionary with seed, state, and call_count
	func serialize() -> Dictionary:
		return {
			"seed": _seed,
			"state": _state,
			"call_count": _call_count
		}
	
	
	## Deserialize RNG state.
	## @param data: Dictionary from serialize()
	func deserialize(data: Dictionary) -> void:
		_seed = data.get("seed", SimConstants.DEFAULT_RNG_SEED)
		_state = data.get("state", _seed)
		_call_count = data.get("call_count", 0)
