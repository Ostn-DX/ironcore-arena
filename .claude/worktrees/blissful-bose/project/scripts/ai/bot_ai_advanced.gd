class_name BotAIAdvanced extends Node

## Advanced AI controller with tactical decision making.
## Implements role-based behaviors, tactical positioning, and squad coordination.

signal tactical_position_found(position: Vector2)
signal squad_command_issued(command: String, target: Variant)
signal state_changed(new_state: AIState, old_state: AIState)
signal target_acquired(target: Node)

enum AIState { IDLE, ENGAGING, RETREATING, REPOSITIONING, PURSUING }
enum AIRole { TANK, SNIPER, SCOUT, SUPPORT }

# Decision timing constants
const EVALUATION_RADIUS: float = 300.0
const EVALUATION_STEPS: int = 16
const DECISION_INTERVAL: int = 6  # Ticks between decisions
const PATH_RECALCULATION_INTERVAL: int = 30  # Ticks between path recalculation

# Movement constants
const ARRIVAL_DISTANCE: float = 20.0
const PATH_SMOOTHING: bool = true

# Role-specific configuration constants
const TANK_PREFERRED_DISTANCE: float = 150.0
const SNIPER_PREFERRED_DISTANCE: float = 400.0
const SCOUT_PREFERRED_DISTANCE: float = 250.0
const SUPPORT_PREFERRED_DISTANCE: float = 200.0

const TANK_WEAPON_RANGE: float = 250.0
const SNIPER_WEAPON_RANGE: float = 600.0
const SCOUT_WEAPON_RANGE: float = 300.0
const SUPPORT_WEAPON_RANGE: float = 350.0

# Target selection constants
const TARGET_SWITCH_THRESHOLD: float = 1.3  # New target must be 30% better
const MAX_TARGET_AGE: int = 60  # Ticks before forcing retarget

# State machine
var _current_state: AIState = AIState.IDLE
var _current_role: AIRole = AIRole.TANK

# Component references
var _bot: Node = null
var _ctx: AITacticalContext = null
var _pathfinder: Pathfinder = null
var _scorer: TacticalScorer = null

# Decision timing
var _decision_timer: int = 0
var _path_timer: int = 0
var _target_age: int = 0

# Current state data
var _current_path: PackedVector2Array = []
var _current_target: Node = null
var _move_target: Vector2 = Vector2.ZERO
var _last_known_enemy_pos: Vector2 = Vector2.ZERO

# Cached values for performance
var _cached_bot_pos: Vector2 = Vector2.ZERO
var _cached_enemies: Array[Node] = []
var _cached_allies: Array[Node] = []


## Initializes the AI with bot reference and context.
func initialize(bot: Node, ctx: AITacticalContext, pathfinder: Pathfinder) -> void:
    _bot = bot
    _ctx = ctx
    _pathfinder = pathfinder
    _scorer = TacticalScorer.new()
    
    _apply_role_weights()
    
    _decision_timer = _get_staggered_offset()
    _path_timer = _get_staggered_offset()


## Main decision entry point, called every simulation tick.
## Uses amortization to spread decision making across frames.
func make_decision(sim_tick: int) -> void:
    if _bot == null or _ctx == null:
        return
    
    # Cache bot position for this tick
    _cached_bot_pos = _bot.global_position if _bot.has_method("get_global_position") else Vector2.ZERO
    
    # Update cached enemy and ally lists periodically
    _cached_enemies = _ctx.get_enemies_of(_bot)
    _cached_allies = _ctx.get_allies_of(_bot)
    
    # Amortize: only decide every DECISION_INTERVAL ticks
    # Use sim_tick + bot.sim_id for staggered decisions
    var should_decide: bool = ((sim_tick + _get_bot_id()) % DECISION_INTERVAL) == 0
    
    if should_decide:
        _execute_decision_logic(sim_tick)
    
    # Always execute movement
    _execute_movement()
    
    # Increment target age
    _target_age += 1


## Executes the main decision logic.
func _execute_decision_logic(sim_tick: int) -> void:
    # Update state based on situation
    _update_state()
    
    # Select target if needed
    var new_target: Node = select_target(_cached_enemies)
    if new_target != _current_target:
        if new_target != null:
            target_acquired.emit(new_target)
        _current_target = new_target
        _target_age = 0
    
    # Execute role-specific behavior
    _execute_role_behavior()
    
    # Recalculate path if needed
    if _should_recalculate_path():
        _recalculate_path()


## Updates the AI state based on current situation.
func _update_state() -> void:
    var old_state: AIState = _current_state
    var new_state: AIState = _current_state
    
    var has_enemies: bool = not _cached_enemies.is_empty()
    var health_ratio: float = _get_bot_health_ratio()
    var should_retreat: bool = _ctx.squad_coordinator.should_retreat(_get_team_id()) if _ctx.squad_coordinator != null else false
    
    match _current_state:
        AIState.IDLE:
            if has_enemies:
                new_state = AIState.ENGAGING
        
        AIState.ENGAGING:
            if health_ratio < 0.3 or should_retreat:
                new_state = AIState.RETREATING
            elif not has_enemies:
                new_state = AIState.IDLE
            elif _should_pursue():
                new_state = AIState.PURSUING
        
        AIState.RETREATING:
            if health_ratio > 0.6 and not should_retreat:
                new_state = AIState.REPOSITIONING
        
        AIState.REPOSITIONING:
            if has_enemies and _is_in_good_position():
                new_state = AIState.ENGAGING
            elif not has_enemies:
                new_state = AIState.IDLE
        
        AIState.PURSUING:
            if health_ratio < 0.3:
                new_state = AIState.RETREATING
            elif not _should_pursue():
                new_state = AIState.ENGAGING
    
    if new_state != old_state:
        _current_state = new_state
        state_changed.emit(new_state, old_state)


## Selects best target from available enemies.
## Scores targets by distance, threat, and focus fire coordination.
func select_target(enemies: Array[Node]) -> Node:
    if enemies.is_empty():
        return null
    
    var best_target: Node = null
    var best_score: float = -999999.0
    var current_target_score: float = 0.0
    
    # Get focus target from squad coordinator
    var focus_target_id: int = -1
    if _ctx.squad_coordinator != null:
        focus_target_id = _ctx.squad_coordinator.get_team_focus_target(_get_team_id())
    
    # Sort enemies by sim_id for deterministic iteration
    var sorted_enemies: Array[Node] = enemies.duplicate()
    sorted_enemies.sort_custom(_sort_by_sim_id)
    
    for enemy: Node in sorted_enemies:
        if not _is_valid_target(enemy):
            continue
        
        var score: float = _score_target(enemy, focus_target_id)
        
        if enemy == _current_target:
            current_target_score = score
        
        if score > best_score:
            best_score = score
            best_target = enemy
    
    # Apply target switching threshold
    if _current_target != null and best_target != _current_target:
        if best_score < current_target_score * TARGET_SWITCH_THRESHOLD and _target_age < MAX_TARGET_AGE:
            best_target = _current_target
    
    return best_target


## Scores a single target for selection.
func _score_target(enemy: Node, focus_target_id: int) -> float:
    var score: float = 100.0
    
    var enemy_pos: Vector2 = _get_node_position(enemy)
    var dist: float = _cached_bot_pos.distance_to(enemy_pos)
    
    # Distance factor (prefer closer targets)
    score -= dist * 0.1
    
    # Focus fire bonus
    if focus_target_id >= 0 and _get_node_id(enemy) == focus_target_id:
        score += 50.0
    
    # Threat factor (lower health = higher threat priority)
    var enemy_health: float = _get_node_health_ratio(enemy)
    score += (1.0 - enemy_health) * 30.0
    
    # Role-specific targeting
    match _current_role:
        AIRole.TANK:
            # Tanks prefer closest targets
            score -= dist * 0.2
        AIRole.SNIPER:
            # Snipers prefer low health targets at range
            score += (1.0 - enemy_health) * 40.0
        AIRole.SCOUT:
            # Scouts prefer isolated targets
            var nearby_allies: int = _count_nearby_allies(enemy_pos, 150.0)
            score -= nearby_allies * 20.0
        AIRole.SUPPORT:
            # Support targets threats to allies
            score += _calculate_threat_to_allies(enemy) * 25.0
    
    return score


## Computes optimal movement goal based on role and situation.
func compute_move_goal() -> Vector2:
    var candidates: PackedVector2Array = _generate_candidates(_cached_bot_pos, EVALUATION_RADIUS, EVALUATION_STEPS)
    
    # Add cover points to candidates
    if _ctx != null:
        var nearby_cover: PackedVector2Array = _ctx.get_cover_points_near(_cached_bot_pos, EVALUATION_RADIUS)
        for cover_point: Vector2 in nearby_cover:
            candidates.append(cover_point)
    
    var best_pos: Vector2 = _cached_bot_pos
    var best_score: float = -999999.0
    
    var enemy_positions: PackedVector2Array = _nodes_to_positions(_cached_enemies)
    var ally_positions: PackedVector2Array = _nodes_to_positions(_cached_allies)
    var cover_points: PackedVector2Array = _ctx.get_cover_points_near(_cached_bot_pos, EVALUATION_RADIUS) if _ctx != null else PackedVector2Array()
    
    var preferred_dist: float = _get_preferred_distance()
    var weapon_range: float = _get_weapon_range()
    
    for candidate: Vector2 in candidates:
        var score: float = _scorer.score_position(
            _cached_bot_pos,
            candidate,
            enemy_positions,
            ally_positions,
            cover_points,
            preferred_dist,
            weapon_range
        )
        
        if score > best_score:
            best_score = score
            best_pos = candidate
    
    tactical_position_found.emit(best_pos)
    return best_pos


## Generates candidate positions for evaluation using deterministic spiral pattern.
func _generate_candidates(center: Vector2, radius: float, steps: int) -> PackedVector2Array:
    var candidates: PackedVector2Array = []
    
    # Golden angle for even distribution
    const GOLDEN_ANGLE: float = PI * (3.0 - sqrt(5.0))
    
    for i: int in range(steps):
        # Spiral pattern
        var t: float = float(i) / float(steps)
        var r: float = radius * sqrt(t)
        var theta: float = float(i) * GOLDEN_ANGLE
        
        var x: float = center.x + r * cos(theta)
        var y: float = center.y + r * sin(theta)
        
        var candidate: Vector2 = Vector2(x, y)
        
        # Clamp to arena bounds if available
        if _ctx != null and _ctx.arena_bounds.has_area():
            candidate = candidate.clamp(
                _ctx.arena_bounds.position,
                _ctx.arena_bounds.position + _ctx.arena_bounds.size
            )
        
        candidates.append(candidate)
    
    return candidates


## Executes role-specific behavior.
func _execute_role_behavior() -> void:
    match _current_state:
        AIState.IDLE:
            _behavior_idle()
        AIState.ENGAGING:
            _behavior_engaging()
        AIState.RETREATING:
            _behavior_retreating()
        AIState.REPOSITIONING:
            _behavior_repositioning()
        AIState.PURSUING:
            _behavior_pursuing()


## Idle behavior - wait for enemies or regroup.
func _behavior_idle() -> void:
    # Move towards allies if too isolated
    if _cached_allies.size() > 0:
        var avg_ally_pos: Vector2 = _calculate_average_position(_cached_allies)
        if _cached_bot_pos.distance_to(avg_ally_pos) > 300.0:
            _move_target = avg_ally_pos
        else:
            _move_target = _cached_bot_pos
    else:
        _move_target = _cached_bot_pos


## Engaging behavior - fight while maintaining optimal position.
func _behavior_engaging() -> void:
    if _current_target == null:
        _move_target = compute_move_goal()
        return
    
    var target_pos: Vector2 = _get_node_position(_current_target)
    var dist_to_target: float = _cached_bot_pos.distance_to(target_pos)
    var preferred_dist: float = _get_preferred_distance()
    
    match _current_role:
        AIRole.TANK:
            # Tank: shorter distance, higher cohesion, push objective
            if dist_to_target > preferred_dist * 0.8:
                _move_target = target_pos  # Move closer
            else:
                _move_target = compute_move_goal()
        
        AIRole.SNIPER:
            # Sniper: higher distance, strong cover + LOS
            if dist_to_target < preferred_dist * 0.7:
                _move_target = compute_move_goal()  # Back up
            else:
                _move_target = compute_move_goal()
        
        AIRole.SCOUT:
            # Scout: flank bias, seeks side angles
            _move_target = compute_move_goal()
        
        AIRole.SUPPORT:
            # Support: stays near allies, targets threats to allies
            if _cached_allies.size() > 0:
                var avg_ally_pos: Vector2 = _calculate_average_position(_cached_allies)
                var target_near_ally: Vector2 = target_pos.lerp(avg_ally_pos, 0.3)
                _move_target = target_near_ally
            else:
                _move_target = compute_move_goal()


## Retreating behavior - move to safety.
func _behavior_retreating() -> void:
    var retreat_pos: Vector2 = _cached_bot_pos
    
    # Move away from enemies
    if not _cached_enemies.is_empty():
        var avg_enemy_pos: Vector2 = _calculate_average_position(_cached_enemies)
        var away_dir: Vector2 = (_cached_bot_pos - avg_enemy_pos).normalized()
        retreat_pos = _cached_bot_pos + away_dir * 200.0
    
    # Move towards allies for protection
    if _cached_allies.size() > 0:
        var avg_ally_pos: Vector2 = _calculate_average_position(_cached_allies)
        retreat_pos = retreat_pos.lerp(avg_ally_pos, 0.4)
    
    # Clamp to arena bounds
    if _ctx != null and _ctx.arena_bounds.has_area():
        retreat_pos = retreat_pos.clamp(
            _ctx.arena_bounds.position,
            _ctx.arena_bounds.position + _ctx.arena_bounds.size
        )
    
    _move_target = retreat_pos


## Repositioning behavior - find better position.
func _behavior_repositioning() -> void:
    _move_target = compute_move_goal()


## Pursuing behavior - chase fleeing targets.
func _behavior_pursuing() -> void:
    if _current_target != null:
        _move_target = _get_node_position(_current_target)
    else:
        _move_target = _last_known_enemy_pos


## Executes movement along current path.
func _execute_movement() -> void:
    if _current_path.is_empty():
        return
    
    # Check if we've arrived at move target
    if _cached_bot_pos.distance_to(_move_target) < ARRIVAL_DISTANCE:
        _current_path.clear()
        return
    
    # Follow path (simplified - actual implementation would use physics movement)
    var next_point: Vector2 = _current_path[0]
    if _cached_bot_pos.distance_to(next_point) < ARRIVAL_DISTANCE:
        _current_path.remove_at(0)


## Sets the AI role and applies appropriate weights.
func set_role(role: AIRole) -> void:
    _current_role = role
    _apply_role_weights()


## Applies role-specific weights to the scorer.
func _apply_role_weights() -> void:
    if _scorer == null:
        return
    
    match _current_role:
        AIRole.TANK:
            # Tank: high cohesion, lower distance preference
            _scorer.set_weights(0.8, 0.4, 0.4, 0.8, 1.2, 0.3)
        
        AIRole.SNIPER:
            # Sniper: high distance, cover, and LOS
            _scorer.set_weights(1.5, 0.6, 1.2, 1.5, 0.3, 0.8)
        
        AIRole.SCOUT:
            # Scout: high flank, medium distance, low cohesion
            _scorer.set_weights(0.6, 1.5, 0.8, 0.8, 0.3, 1.0)
        
        AIRole.SUPPORT:
            # Support: high cohesion, medium everything else
            _scorer.set_weights(0.8, 0.5, 0.6, 0.9, 1.2, 0.5)


## Gets current state.
func get_state() -> AIState:
    return _current_state


## Gets current role.
func get_role() -> AIRole:
    return _current_role


## Gets current path for debug visualization.
func get_current_path() -> PackedVector2Array:
    return _current_path.duplicate()


## Gets current move target for debug visualization.
func get_move_target() -> Vector2:
    return _move_target


## Gets current target.
func get_current_target() -> Node:
    return _current_target


## Checks if a path recalculation is needed.
func _should_recalculate_path() -> bool:
    return _current_path.is_empty() or _path_timer <= 0


## Recalculates the path to the move target.
func _recalculate_path() -> void:
    if _pathfinder == null:
        return
    
    _current_path = _pathfinder.find_path(_cached_bot_pos, _move_target)
    _path_timer = PATH_RECALCULATION_INTERVAL


## Checks if we should pursue the current target.
func _should_pursue() -> bool:
    if _current_target == null:
        return false
    
    var target_pos: Vector2 = _get_node_position(_current_target)
    var dist: float = _cached_bot_pos.distance_to(target_pos)
    var target_health: float = _get_node_health_ratio(_current_target)
    
    # Pursue if target is low health and not too far
    return target_health < 0.3 and dist < _get_weapon_range() * 1.5


## Checks if we're in a good tactical position.
func _is_in_good_position() -> bool:
    if _current_target == null:
        return true
    
    var dist: float = _cached_bot_pos.distance_to(_get_node_position(_current_target))
    var preferred_dist: float = _get_preferred_distance()
    
    return absf(dist - preferred_dist) < preferred_dist * 0.3


## Returns the preferred engagement distance based on role.
func _get_preferred_distance() -> float:
    match _current_role:
        AIRole.TANK:
            return TANK_PREFERRED_DISTANCE
        AIRole.SNIPER:
            return SNIPER_PREFERRED_DISTANCE
        AIRole.SCOUT:
            return SCOUT_PREFERRED_DISTANCE
        AIRole.SUPPORT:
            return SUPPORT_PREFERRED_DISTANCE
    return 200.0


## Returns the weapon range based on role.
func _get_weapon_range() -> float:
    match _current_role:
        AIRole.TANK:
            return TANK_WEAPON_RANGE
        AIRole.SNIPER:
            return SNIPER_WEAPON_RANGE
        AIRole.SCOUT:
            return SCOUT_WEAPON_RANGE
        AIRole.SUPPORT:
            return SUPPORT_WEAPON_RANGE
    return 300.0


## Gets staggered offset for amortization.
func _get_staggered_offset() -> int:
    return _get_bot_id() % DECISION_INTERVAL


## Gets the bot's simulation ID.
func _get_bot_id() -> int:
    if _bot != null and _bot.has_method("get_sim_id"):
        return _bot.get_sim_id()
    return 0


## Gets the bot's team ID.
func _get_team_id() -> int:
    if _bot != null and _bot.has_method("get_team_id"):
        return _bot.get_team_id()
    return 0


## Gets the bot's health ratio.
func _get_bot_health_ratio() -> float:
    if _bot != null and _bot.has_method("get_health_ratio"):
        return _bot.get_health_ratio()
    return 1.0


## Checks if a target is valid.
func _is_valid_target(target: Node) -> bool:
    if target == null:
        return false
    if target.has_method("is_alive"):
        return target.is_alive()
    return true


## Gets a node's position safely.
func _get_node_position(node: Node) -> Vector2:
    if node != null and node.has_method("get_global_position"):
        return node.global_position
    return Vector2.ZERO


## Gets a node's simulation ID.
func _get_node_id(node: Node) -> int:
    if node != null and node.has_method("get_sim_id"):
        return node.get_sim_id()
    return -1


## Gets a node's health ratio.
func _get_node_health_ratio(node: Node) -> float:
    if node != null and node.has_method("get_health_ratio"):
        return node.get_health_ratio()
    return 1.0


## Counts allies near a position.
func _count_nearby_allies(pos: Vector2, radius: float) -> int:
    var count: int = 0
    for ally: Node in _cached_allies:
        if _get_node_position(ally).distance_to(pos) < radius:
            count += 1
    return count


## Calculates threat level an enemy poses to allies.
func _calculate_threat_to_allies(enemy: Node) -> float:
    var threat: float = 0.0
    var enemy_pos: Vector2 = _get_node_position(enemy)
    
    for ally: Node in _cached_allies:
        var ally_pos: Vector2 = _get_node_position(ally)
        var dist: float = enemy_pos.distance_to(ally_pos)
        threat += 1.0 / (dist + 1.0)  # Inverse distance
    
    return threat


## Calculates average position of nodes.
func _calculate_average_position(nodes: Array[Node]) -> Vector2:
    if nodes.is_empty():
        return Vector2.ZERO
    
    var total: Vector2 = Vector2.ZERO
    for node: Node in nodes:
        total += _get_node_position(node)
    
    return total / float(nodes.size())


## Converts node array to position array.
func _nodes_to_positions(nodes: Array[Node]) -> PackedVector2Array:
    var positions: PackedVector2Array = []
    for node: Node in nodes:
        positions.append(_get_node_position(node))
    return positions


## Sort function for deterministic iteration by sim_id.
func _sort_by_sim_id(a: Node, b: Node) -> bool:
    return _get_node_id(a) < _get_node_id(b)
