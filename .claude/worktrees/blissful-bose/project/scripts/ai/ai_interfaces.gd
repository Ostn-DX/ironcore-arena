## @file ai/ai_interfaces.gd
## @brief AI component interfaces and data structures for tactical decision making.
## @description
## This file defines the interfaces and data structures used by AI components
## to make tactical decisions. All AI implementations should use these interfaces
## to ensure consistent behavior and interoperability.
##
## ARCHITECTURE:
## - AITacticalContext: Input data for AI decisions
## - AIDecisionResult: Output from AI decision making
## - AIControllerBase: Base class for AI controllers
## - TacticalEvaluator: Interface for threat/priority evaluation
## - PathfindingInterface: Interface for movement pathfinding
##
## IMPLEMENTATION NOTES:
## - All AI code must be deterministic (see determinism_contract.md)
## - AI decisions happen at fixed intervals (AI_DECISION_INTERVAL ticks)
## - Each bot has its own AI controller instance
## - AI controllers query SimulationManager for world state

class_name AIInterfaces
extends RefCounted

# =============================================================================
# DATA STRUCTURES
# =============================================================================

## Complete tactical context for AI decision making.
## This structure contains all information an AI needs to make decisions.
class AITacticalContext:
	extends RefCounted
	
	# -------------------------------------------------------------------------
	# Self Information
	# -------------------------------------------------------------------------
	## The bot this AI is controlling
	var self_bot: Node = null
	
	## This bot's sim_id
	var self_id: int = -1
	
	## This bot's team
	var self_team: int = SimConstants.TEAM_NONE
	
	## This bot's current position
	var self_position: Vector2 = Vector2.ZERO
	
	## This bot's forward direction
	var self_forward: Vector2 = Vector2.RIGHT
	
	## This bot's current health
	var self_health: float = 100.0
	
	## This bot's maximum health
	var self_max_health: float = 100.0
	
	## This bot's current state
	var self_state: SimConstants.BotState = SimConstants.BotState.IDLE
	
	## This bot's role
	var self_role: String = "assault"
	
	## Remaining fire cooldown
	var fire_cooldown: float = 0.0
	
	## Current velocity
	var velocity: Vector2 = Vector2.ZERO
	
	# -------------------------------------------------------------------------
	# Environmental Information
	# -------------------------------------------------------------------------
	## Current simulation tick
	var current_tick: int = 0
	
	## Current game phase
	var game_phase: SimConstants.GamePhase = SimConstants.GamePhase.SETUP
	
	## Remaining match time (seconds, -1 if unlimited)
	var match_time_remaining: float = -1.0
	
	## Arena bounds
	var arena_min: Vector2 = Vector2(-1024, -1024)
	var arena_max: Vector2 = Vector2(1024, 1024)
	
	# -------------------------------------------------------------------------
	# Nearby Entities (populated by spatial queries)
	# -------------------------------------------------------------------------
	## All visible enemy bots (sorted by distance, closest first)
	var visible_enemies: Array[Node] = []
	
	## All enemy bots within threat range (not necessarily visible)
	var nearby_enemies: Array[Node] = []
	
	## All friendly bots within support range
	var nearby_allies: Array[Node] = []
	
	## All projectiles that could hit this bot
	var incoming_projectiles: Array[Node] = []
	
	# -------------------------------------------------------------------------
	# Tactical Information
	# -------------------------------------------------------------------------
	## Last known enemy positions (for tracking unseen enemies)
	## Format: {int: Dictionary} - enemy_id -> {position: Vector2, tick: int}
	var enemy_memory: Dictionary = {}
	
	## Current tactical objective (if any)
	var current_objective: AITacticalObjective = null
	
	## Time since last damage taken
	var time_since_damage: float = 999.0
	
	## Current kill/death count for this bot
	var kills: int = 0
	var deaths: int = 0
	
	# -------------------------------------------------------------------------
	# Methods
	# -------------------------------------------------------------------------
	
	## Check if self is at low health.
	## @param threshold: Health percentage threshold (0.0 to 1.0)
	## @return: true if health is below threshold
	func is_low_health(threshold: float = 0.3) -> bool:
		return self_health / self_max_health < threshold
	
	
	## Check if self is in immediate danger.
	## @return: true if health is critical or many enemies nearby
	func is_in_danger() -> bool:
		if is_low_health(0.25):
			return true
		if visible_enemies.size() >= 3:
			return true
		if incoming_projectiles.size() > 0:
			return true
		return false
	
	
	## Get the closest visible enemy.
	## @return: Closest enemy bot or null
	func get_closest_visible_enemy() -> Node:
		if visible_enemies.is_empty():
			return null
		return visible_enemies[0]
	
	
	## Get the most threatening enemy.
	## @return: Most threatening enemy bot or null
	func get_most_threatening_enemy() -> Node:
		if visible_enemies.is_empty():
			return null
		
		var most_threatening: Node = null
		var highest_threat: float = -1.0
		
		for enemy in visible_enemies:
			var threat: float = calculate_threat(enemy)
			if threat > highest_threat:
				highest_threat = threat
				most_threatening = enemy
		
		return most_threatening
	
	
	## Calculate threat level of an enemy.
	## @param enemy: Enemy bot to evaluate
	## @return: Threat score (higher = more dangerous)
	func calculate_threat(enemy: Node) -> float:
		var threat: float = 0.0
		
		# Distance factor (closer = more threatening)
		var distance: float = self_position.distance_to(enemy.position)
		threat += 1000.0 / (distance + 1.0)
		
		# Health factor (healthier enemies are more threatening)
		threat += enemy.health
		
		# Aim factor (if enemy is aiming at us, more threatening)
		var to_self: Vector2 = (self_position - enemy.position).normalized()
		var enemy_forward: Vector2 = enemy.get_forward() if enemy.has_method("get_forward") else Vector2.RIGHT
		var aim_alignment: float = enemy_forward.dot(to_self)
		if aim_alignment > 0.9:
			threat *= 2.0
		
		return threat
	
	
	## Get average ally position.
	## @return: Average position of nearby allies, or self position if none
	func get_ally_center() -> Vector2:
		if nearby_allies.is_empty():
			return self_position
		
		var center: Vector2 = Vector2.ZERO
		for ally in nearby_allies:
			center += ally.position
		return center / nearby_allies.size()
	
	
	## Check if position is safe (no enemies can see it).
	## @param pos: Position to check
	## @return: true if no visible enemy has line of sight
	func is_position_safe(pos: Vector2) -> bool:
		for enemy in visible_enemies:
			var to_pos: Vector2 = (pos - enemy.position).normalized()
			var enemy_forward: Vector2 = enemy.get_forward() if enemy.has_method("get_forward") else Vector2.RIGHT
			var angle: float = absf(enemy_forward.angle_to(to_pos))
			var distance: float = enemy.position.distance_to(pos)
			
			if angle < SimConstants.BOT_VISION_ANGLE * 0.5 and distance < SimConstants.BOT_VISION_RANGE:
				return false
		
		return true


## Result of an AI decision.
## This structure contains all actions the AI wants to take.
class AIDecisionResult:
	extends RefCounted
	
	# -------------------------------------------------------------------------
	# Movement
	# -------------------------------------------------------------------------
	## Target position to move toward
	var move_target: Vector2 = Vector2.ZERO
	
	## Whether to move at all
	var should_move: bool = false
	
	## Movement urgency (affects pathfinding preferences)
	var movement_urgency: float = 1.0
	
	# -------------------------------------------------------------------------
	# Combat
	# -------------------------------------------------------------------------
	## Target position to aim at
	var aim_target: Vector2 = Vector2.ZERO
	
	## Whether to fire
	var should_fire: bool = false
	
	## Target enemy (if any) - for tracking
	var target_enemy: Node = null
	
	# -------------------------------------------------------------------------
	# Tactical
	# -------------------------------------------------------------------------
	## Desired tactical state
	var desired_state: SimConstants.BotState = SimConstants.BotState.IDLE
	
	## Priority of this decision (for debugging)
	var decision_priority: float = 0.0
	
	## Name of the decision made (for debugging)
	var decision_name: String = "none"
	
	# -------------------------------------------------------------------------
	# Methods
	# -------------------------------------------------------------------------
	
	## Create a "do nothing" decision.
	## @return: Idle decision result
	static func idle() -> AIDecisionResult:
		var result: AIDecisionResult = AIDecisionResult.new()
		result.desired_state = SimConstants.BotState.IDLE
		result.decision_name = "idle"
		return result
	
	
	## Create a "move to position" decision.
	## @param target: Position to move to
	## @param urgency: Movement urgency (0.0 to 2.0)
	## @return: Move decision result
	static func move_to(target: Vector2, urgency: float = 1.0) -> AIDecisionResult:
		var result: AIDecisionResult = AIDecisionResult.new()
		result.move_target = target
		result.should_move = true
		result.movement_urgency = urgency
		result.desired_state = SimConstants.BotState.MOVING
		result.decision_name = "move_to"
		return result
	
	
	## Create an "attack enemy" decision.
	## @param enemy: Enemy to attack
	## @return: Attack decision result
	static func attack(enemy: Node) -> AIDecisionResult:
		var result: AIDecisionResult = AIDecisionResult.new()
		result.target_enemy = enemy
		result.aim_target = enemy.position
		result.should_fire = true
		result.should_move = true
		result.move_target = enemy.position
		result.desired_state = SimConstants.BotState.ATTACKING
		result.decision_name = "attack"
		return result
	
	
	## Create a "flee to safety" decision.
	## @param safe_position: Position to flee toward
	## @return: Flee decision result
	static func flee(safe_position: Vector2) -> AIDecisionResult:
		var result: AIDecisionResult = AIDecisionResult.new()
		result.move_target = safe_position
		result.should_move = true
		result.movement_urgency = 2.0  # High urgency
		result.should_fire = false
		result.desired_state = SimConstants.BotState.FLEEING
		result.decision_name = "flee"
		return result
	
	
	## Create a "hold position" decision.
	## @param position: Position to hold
	## @param aim_at: Where to aim
	## @param fire: Whether to fire
	## @return: Hold decision result
	static func hold_position(position: Vector2, aim_at: Vector2, fire: bool = false) -> AIDecisionResult:
		var result: AIDecisionResult = AIDecisionResult.new()
		result.move_target = position
		result.should_move = false
		result.aim_target = aim_at
		result.should_fire = fire
		result.desired_state = SimConstants.BotState.IDLE
		result.decision_name = "hold_position"
		return result


## Tactical objective for coordinated AI behavior.
class AITacticalObjective:
	extends RefCounted
	
	## Objective type
	var objective_type: ObjectiveType = ObjectiveType.HOLD_POSITION
	
	## Target position
	var target_position: Vector2 = Vector2.ZERO
	
	## Target entity (if applicable)
	var target_entity: Node = null
	
	## Priority of this objective (higher = more important)
	var priority: float = 1.0
	
	## Time when objective expires (-1 for no expiry)
	var expiry_tick: int = -1
	
	## Objective assigned by (for coordination)
	var assigned_by: int = -1
	
	## Objective types
	enum ObjectiveType {
		HOLD_POSITION,    ## Defend a specific position
		ATTACK_POSITION,  ## Attack/move to a position
		DEFEND_ENTITY,    ## Protect a specific bot
		ATTACK_ENTITY,    ## Focus fire on specific enemy
		PATROL,           ## Follow a patrol path
		RETREAT,          ## Fall back to safe area
		CUSTOM            ## User-defined objective
	}
	
	## Check if objective is still valid.
	## @param current_tick: Current simulation tick
	## @return: true if objective hasn't expired
	func is_valid(current_tick: int) -> bool:
		if expiry_tick >= 0 and current_tick > expiry_tick:
			return false
		if objective_type == ObjectiveType.ATTACK_ENTITY and target_entity != null:
			if target_entity.has_method("is_alive") and not target_entity.is_alive():
				return false
		if objective_type == ObjectiveType.DEFEND_ENTITY and target_entity != null:
			if target_entity.has_method("is_alive") and not target_entity.is_alive():
				return false
		return true


## Perceived enemy information (for memory/tracking).
class AIEnemyInfo:
	extends RefCounted
	
	## Enemy bot reference
	var bot: Node = null
	
	## Last known position
	var last_position: Vector2 = Vector2.ZERO
	
	## Last known velocity
	var last_velocity: Vector2 = Vector2.ZERO
	
	## Tick when last seen
	var last_seen_tick: int = 0
	
	## Last known health
	var last_health: float = 100.0
	
	## Estimated current position (based on last known + velocity)
	func get_estimated_position(current_tick: int) -> Vector2:
		var ticks_since_seen: int = current_tick - last_seen_tick
		var time_since_seen: float = ticks_since_seen * SimConstants.TIMESTEP
		return last_position + last_velocity * time_since_seen
	
	
	## Check if memory is still fresh.
	## @param current_tick: Current simulation tick
	## @return: true if within memory duration
	func is_fresh(current_tick: int) -> bool:
		var ticks_since_seen: int = current_tick - last_seen_tick
		var time_since_seen: float = ticks_since_seen * SimConstants.TIMESTEP
		return time_since_seen < SimConstants.AI_MEMORY_DURATION


# =============================================================================
# INTERFACE CLASSES
# =============================================================================

## Base class for AI controllers.
## Extend this to implement custom AI behavior.
## @abstract
class AIControllerBase:
	extends Node
	
	# -------------------------------------------------------------------------
	# Configuration
	# -------------------------------------------------------------------------
	## AI personality/decision making weights
	var aggression: float = 0.5       ## 0.0 = defensive, 1.0 = aggressive
	var caution: float = 0.5          ## 0.0 = reckless, 1.0 = careful
	var teamwork: float = 0.5         ## 0.0 = solo, 1.0 = team-focused
	
	# -------------------------------------------------------------------------
	# Internal State
	# -------------------------------------------------------------------------
	var _controlled_bot: Node = null
	var _sim_manager: Node = null
	var _last_decision_tick: int = -999
	var _current_decision: AIDecisionResult = null
	var _tactical_context: AITacticalContext = null
	var _enemy_memory: Dictionary = {}  ## {int: AIEnemyInfo}
	
	# -------------------------------------------------------------------------
	# Required Overrides
	# -------------------------------------------------------------------------
	
	## Make a tactical decision based on current context.
	## This is the main AI logic entry point.
	## @param context: Current tactical situation
	## @return: Decision result with actions to take
	## @virtual
	func make_decision(_context: AITacticalContext) -> AIDecisionResult:
		push_error("AIControllerBase.make_decision() must be overridden")
		return AIDecisionResult.idle()
	
	
	## Get the name of this AI controller (for debugging).
	## @return: Human-readable AI name
	## @virtual
	func get_ai_name() -> String:
		return "BaseAI"
	
	
	# -------------------------------------------------------------------------
	# Public API
	# -------------------------------------------------------------------------
	
	## Initialize the AI controller.
	## @param bot: The bot this AI will control
	## @param sim_manager: Reference to simulation manager
	func initialize(bot: Node, sim_manager: Node) -> void:
		_controlled_bot = bot
		_sim_manager = sim_manager
		_tactical_context = AITacticalContext.new()
		_current_decision = AIDecisionResult.idle()
		_on_initialize()
	
	
	## Process AI decision making.
	## Called by simulation manager at AI_DECISION_INTERVAL.
	## @param dt: Fixed timestep
	func process_ai(dt: float) -> void:
		if _controlled_bot == null or _sim_manager == null:
			return
		
		var current_tick: int = _sim_manager.get_sim_tick()
		
		# Only make decisions at intervals
		if current_tick - _last_decision_tick < SimConstants.AI_DECISION_INTERVAL:
			return
		
		_last_decision_tick = current_tick
		
		# Build tactical context
		_build_tactical_context()
		
		# Make decision
		_current_decision = make_decision(_tactical_context)
		
		# Apply decision to bot
		_apply_decision(_current_decision)
		
		# Update enemy memory
		_update_enemy_memory()
	
	
	## Get the current decision.
	## @return: Current AI decision result
	func get_current_decision() -> AIDecisionResult:
		return _current_decision
	
	
	## Get the controlled bot.
	## @return: Bot node or null
	func get_controlled_bot() -> Node:
		return _controlled_bot
	
	
	## Set AI personality parameters.
	## @param aggression_val: Aggression level (0.0 to 1.0)
	## @param caution_val: Caution level (0.0 to 1.0)
	## @param teamwork_val: Teamwork level (0.0 to 1.0)
	func set_personality(aggression_val: float, caution_val: float, teamwork_val: float) -> void:
		aggression = clampf(aggression_val, 0.0, 1.0)
		caution = clampf(caution_val, 0.0, 1.0)
		teamwork = clampf(teamwork_val, 0.0, 1.0)
	
	
	# -------------------------------------------------------------------------
	# Protected Methods (override in subclasses)
	# -------------------------------------------------------------------------
	
	## Called after initialization. Override for setup.
	## @virtual
	func _on_initialize() -> void:
		pass
	
	
	## Build the tactical context from current world state.
	## Override to add custom context information.
	## @virtual
	func _build_tactical_context() -> void:
		if _tactical_context == null:
			_tactical_context = AITacticalContext.new()
		
		var bot = _controlled_bot
		var sim = _sim_manager
		
		# Self info
		_tactical_context.self_bot = bot
		_tactical_context.self_id = bot.sim_id
		_tactical_context.self_team = bot.team
		_tactical_context.self_position = bot.position
		_tactical_context.self_forward = bot.get_forward() if bot.has_method("get_forward") else Vector2.RIGHT
		_tactical_context.self_health = bot.health
		_tactical_context.self_max_health = bot.max_health
		_tactical_context.self_state = bot.get_state() if bot.has_method("get_state") else SimConstants.BotState.IDLE
		_tactical_context.self_role = bot.get_role() if bot.has_method("get_role") else "unknown"
		_tactical_context.current_tick = sim.get_sim_tick()
		_tactical_context.game_phase = sim.get_game_phase()
		_tactical_context.match_time_remaining = sim.get_match_time_remaining()
		
		# Spatial queries (deterministic - sorted by sim_id internally)
		_tactical_context.visible_enemies = sim.query_visible_bots(
			bot, 
			SimConstants.BOT_VISION_RANGE, 
			SimConstants.BOT_VISION_ANGLE
		)
		
		_tactical_context.nearby_enemies = sim.query_bots_in_radius(
			bot.position, 
			SimConstants.AI_THREAT_RANGE
		)
		_tactical_context.nearby_enemies = _filter_enemies(_tactical_context.nearby_enemies)
		
		_tactical_context.nearby_allies = sim.query_bots_in_radius(
			bot.position, 
			SimConstants.AI_SUPPORT_RANGE
		)
		_tactical_context.nearby_allies = _filter_allies(_tactical_context.nearby_allies)
		
		# Enemy memory
		_tactical_context.enemy_memory = _enemy_memory
	
	
	## Apply a decision to the controlled bot.
	## Override to customize how decisions are applied.
	## @param decision: Decision to apply
	## @virtual
	func _apply_decision(decision: AIDecisionResult) -> void:
		if decision.should_move:
			_controlled_bot.set_move_target(decision.move_target)
		
		_controlled_bot.set_aim_target(decision.aim_target)
		_controlled_bot.set_fire(decision.should_fire)
	
	
	# -------------------------------------------------------------------------
	# Private Methods
	# -------------------------------------------------------------------------
	
	func _filter_enemies(bots: Array[Node]) -> Array[Node]:
		var result: Array[Node] = []
		for bot in bots:
			if bot.team != _controlled_bot.team and bot.is_alive():
				result.append(bot)
		return result
	
	
	func _filter_allies(bots: Array[Node]) -> Array[Node]:
		var result: Array[Node] = []
		for bot in bots:
			if bot.team == _controlled_bot.team and bot.sim_id != _controlled_bot.sim_id and bot.is_alive():
				result.append(bot)
		return result
	
	
	func _update_enemy_memory() -> void:
		var current_tick: int = _sim_manager.get_sim_tick()
		
		# Update memory for visible enemies
		for enemy in _tactical_context.visible_enemies:
			var info: AIEnemyInfo
			if _enemy_memory.has(enemy.sim_id):
				info = _enemy_memory[enemy.sim_id]
			else:
				info = AIEnemyInfo.new()
				_enemy_memory[enemy.sim_id] = info
			
			info.bot = enemy
			info.last_position = enemy.position
			info.last_health = enemy.health
			info.last_seen_tick = current_tick
		
		# Remove stale memories
		var to_remove: Array[int] = []
		for enemy_id in _enemy_memory.keys():
			var info: AIEnemyInfo = _enemy_memory[enemy_id]
			if not info.is_fresh(current_tick):
				to_remove.append(enemy_id)
		
		for enemy_id in to_remove:
			_enemy_memory.erase(enemy_id)


## Interface for tactical evaluation functions.
## Implement this to provide custom threat/priority evaluation.
class TacticalEvaluator:
	extends RefCounted
	
	## Evaluate threat level of an enemy.
	## @param self_bot: The evaluating bot
	## @param enemy: Enemy to evaluate
	## @param context: Tactical context
	## @return: Threat score (higher = more threatening)
	func evaluate_threat(self_bot: Node, enemy: Node, context: AITacticalContext) -> float:
		var threat: float = 0.0
		
		# Distance factor
		var distance: float = self_bot.position.distance_to(enemy.position)
		threat += 1000.0 / (distance + 1.0)
		
		# Health factor
		threat += enemy.health
		
		# Weapon cooldown factor (if enemy can fire soon, more threatening)
		if enemy.has_method("get_fire_cooldown"):
			var cooldown: float = enemy.get_fire_cooldown()
			if cooldown <= 0.0:
				threat *= 1.5
		
		return threat
	
	
	## Evaluate priority of a target.
	## @param self_bot: The evaluating bot
	## @param target: Target to evaluate
	## @param context: Tactical context
	## @return: Priority score (higher = higher priority)
	func evaluate_target_priority(self_bot: Node, target: Node, context: AITacticalContext) -> float:
		var priority: float = evaluate_threat(self_bot, target, context)
		
		# Low health targets are higher priority (easier kills)
		var health_percent: float = target.health / target.max_health
		if health_percent < 0.3:
			priority *= 1.3
		
		return priority
	
	
	## Evaluate value of a position.
	## @param position: Position to evaluate
	## @param context: Tactical context
	## @return: Position score (higher = better position)
	func evaluate_position(position: Vector2, context: AITacticalContext) -> float:
		var score: float = 0.0
		
		# Distance to cover (prefer positions near walls/cover)
		var dist_to_center: float = position.length()
		score += dist_to_center * 0.1  # Slight preference for edges
		
		# Distance to allies (prefer staying near team)
		var ally_center: Vector2 = context.get_ally_center()
		var dist_to_allies: float = position.distance_to(ally_center)
		score -= dist_to_allies * 0.2  # Prefer staying together
		
		# Visibility to enemies (prefer positions with few visible enemies)
		for enemy in context.visible_enemies:
			var can_see: bool = _has_line_of_sight(position, enemy.position)
			if can_see:
				score -= 50.0  # Penalty for being visible
		
		return score
	
	
	func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
		# Simple line of sight check (can be overridden for raycasting)
		var distance: float = from.distance_to(to)
		return distance < SimConstants.BOT_VISION_RANGE


## Interface for pathfinding.
## Implement this to provide custom movement pathfinding.
class PathfindingInterface:
	extends RefCounted
	
	## Find a path from start to end.
	## @param start: Starting position
	## @param end: Target position
	## @param context: Tactical context (for obstacle awareness)
	## @return: Array of Vector2 waypoints (empty if no path)
	func find_path(start: Vector2, end: Vector2, context: AITacticalContext) -> Array[Vector2]:
		# Default: direct path (no obstacles)
		return [end]
	
	
	## Find a safe retreat position.
	## @param current_pos: Current position
	## @param context: Tactical context
	## @return: Safe position or current_pos if none found
	func find_retreat_position(current_pos: Vector2, context: AITacticalContext) -> Vector2:
		var best_pos: Vector2 = current_pos
		var best_score: float = -INF
		
		# Try several directions
		var directions: Array[Vector2] = [
			Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN,
			Vector2(1, 1).normalized(), Vector2(1, -1).normalized(),
			Vector2(-1, 1).normalized(), Vector2(-1, -1).normalized()
		]
		
		for dir in directions:
			var test_pos: Vector2 = current_pos + dir * 200.0
			test_pos = SimConstants.clamp_to_arena(test_pos)
			
			var score: float = 0.0
			
			# Prefer positions far from enemies
			for enemy in context.visible_enemies:
				var dist: float = test_pos.distance_to(enemy.position)
				score += dist
			
			# Prefer positions near allies
			for ally in context.nearby_allies:
				var dist: float = test_pos.distance_to(ally.position)
				score -= dist * 0.5
			
			if score > best_score:
				best_score = score
				best_pos = test_pos
		
		return best_pos
	
	
	## Find flanking position around a target.
	## @param target_pos: Target to flank
	## @param context: Tactical context
	## @return: Flanking position
	func find_flank_position(target_pos: Vector2, context: AITacticalContext) -> Vector2:
		var self_pos: Vector2 = context.self_position
		var to_target: Vector2 = (target_pos - self_pos).normalized()
		
		# Try flanking at 90 degrees
		var flank_dir: Vector2 = Vector2(-to_target.y, to_target.x)
		var flank_pos: Vector2 = target_pos + flank_dir * 300.0
		
		return SimConstants.clamp_to_arena(flank_pos)
