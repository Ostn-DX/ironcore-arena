class_name SquadCoordinator extends Node

## Coordinates team-wide tactics and communication.
## Manages focus fire, retreat decisions, and squad commands.

signal focus_target_changed(team_id: int, target_id: int)
signal retreat_called(team_id: int)
signal regroup_called(team_id: int)
signal command_issued(team_id: int, command: String, target: Variant)

# Threshold constants
const RETREAT_RATIO_THRESHOLD: float = 0.4
const RETREAT_HEALTH_THRESHOLD: float = 0.35
const FOCUS_FIRE_TIMEOUT: int = 180  # Ticks
const RETREAT_COOLDOWN: int = 120  # Ticks between retreat calls
const REGROUP_DISTANCE_THRESHOLD: float = 500.0

# Focus fire selection constants
const FOCUS_DAMAGE_BONUS: float = 1.3  # 30% damage bonus for focus fire

# Internal state
var _team_focus_targets: Dictionary = {}      # team_id -> target_sim_id
var _focus_target_timers: Dictionary = {}     # team_id -> remaining_ticks
var _team_retreat_status: Dictionary = {}     # team_id -> bool
var _retreat_cooldowns: Dictionary = {}       # team_id -> remaining_ticks
var _team_regroup_status: Dictionary = {}     # team_id -> bool
var _team_strength_history: Dictionary = {}   # team_id -> Array[float] (last N readings)

# Configuration
var _history_size: int = 10
var _update_interval: int = 10  # Ticks between updates
var _update_timer: int = 0


## Updates team coordination state.
## Called periodically to evaluate and update squad tactics.
func update_team(
    team_id: int,
    bots: Array[Node],
    enemies: Array[Node],
    sim_tick: int
) -> void:
    _update_timer += 1
    if _update_timer < _update_interval:
        return
    _update_timer = 0
    
    # Sort bots by sim_id for deterministic iteration
    var sorted_bots: Array[Node] = bots.duplicate()
    sorted_bots.sort_custom(_sort_by_sim_id)
    
    # Update focus fire target
    _update_focus_target(team_id, sorted_bots, enemies)
    
    # Check retreat conditions
    _update_retreat_status(team_id, sorted_bots, enemies)
    
    # Update regroup status
    _update_regroup_status(team_id, sorted_bots)
    
    # Decrement timers
    _decrement_timers(team_id)


## Updates the focus fire target for a team.
func _update_focus_target(team_id: int, bots: Array[Node], enemies: Array[Node]) -> void:
    if enemies.is_empty():
        _clear_focus_target(team_id)
        return
    
    # Check if current focus target is still valid
    var current_focus: int = _team_focus_targets.get(team_id, -1)
    var current_timer: int = _focus_target_timers.get(team_id, 0)
    
    if current_focus >= 0 and current_timer > 0:
        # Verify target still exists and is alive
        var target_still_valid: bool = false
        for enemy: Node in enemies:
            if _get_node_id(enemy) == current_focus and _is_node_alive(enemy):
                target_still_valid = true
                break
        
        if target_still_valid:
            _focus_target_timers[team_id] = current_timer - _update_interval
            return
    
    # Select new focus target
    var new_focus: int = _select_focus_target(bots, enemies)
    
    if new_focus != current_focus:
        _team_focus_targets[team_id] = new_focus
        focus_target_changed.emit(team_id, new_focus)
    
    _focus_target_timers[team_id] = FOCUS_FIRE_TIMEOUT


## Selects the best focus fire target.
func _select_focus_target(bots: Array[Node], enemies: Array[Node]) -> int:
    var best_target: int = -1
    var best_score: float = -999999.0
    
    # Sort enemies by sim_id for deterministic iteration
    var sorted_enemies: Array[Node] = enemies.duplicate()
    sorted_enemies.sort_custom(_sort_by_sim_id)
    
    for enemy: Node in sorted_enemies:
        if not _is_node_alive(enemy):
            continue
        
        var score: float = _score_focus_target(enemy, bots)
        
        if score > best_score:
            best_score = score
            best_target = _get_node_id(enemy)
    
    return best_target


## Scores a potential focus fire target.
func _score_focus_target(enemy: Node, bots: Array[Node]) -> float:
    var score: float = 100.0
    var enemy_pos: Vector2 = _get_node_position(enemy)
    var enemy_health: float = _get_node_health_ratio(enemy)
    
    # Prefer low health targets (easier to kill)
    score += (1.0 - enemy_health) * 50.0
    
    # Prefer targets that many allies can hit
    var allies_in_range: int = 0
    for bot: Node in bots:
        var bot_pos: Vector2 = _get_node_position(bot)
        var dist: float = bot_pos.distance_to(enemy_pos)
        var weapon_range: float = _get_bot_weapon_range(bot)
        
        if dist <= weapon_range:
            allies_in_range += 1
    
    score += allies_in_range * 20.0
    
    # Prefer central targets (more splash damage potential)
    var avg_bot_pos: Vector2 = _calculate_average_position(bots)
    var centrality: float = 1.0 / (enemy_pos.distance_to(avg_bot_pos) + 1.0)
    score += centrality * 30.0
    
    # Prefer high threat targets
    var threat: float = _calculate_enemy_threat(enemy, bots)
    score += threat * 25.0
    
    return score


## Updates retreat status for a team.
func _update_retreat_status(team_id: int, bots: Array[Node], enemies: Array[Node]) -> void:
    var should_retreat: bool = false
    
    # Check cooldown
    var cooldown: int = _retreat_cooldowns.get(team_id, 0)
    if cooldown > 0:
        _retreat_cooldowns[team_id] = maxi(0, cooldown - _update_interval)
    
    # Calculate strength ratio
    var strength_ratio: float = _calculate_strength_ratio(team_id, bots, enemies)
    
    # Store in history
    if not _team_strength_history.has(team_id):
        _team_strength_history[team_id] = []
    
    var history: Array = _team_strength_history[team_id]
    history.append(strength_ratio)
    if history.size() > _history_size:
        history.pop_front()
    
    # Check if we should retreat
    if strength_ratio < RETREAT_RATIO_THRESHOLD:
        # Check if ratio has been low for a while (avoid panic retreat)
        var avg_ratio: float = _calculate_average(history)
        if avg_ratio < RETREAT_RATIO_THRESHOLD:
            should_retreat = true
    
    # Check individual bot health
    var low_health_count: int = 0
    for bot: Node in bots:
        if _get_node_health_ratio(bot) < RETREAT_HEALTH_THRESHOLD:
            low_health_count += 1
    
    if low_health_count > bots.size() / 2:
        should_retreat = true
    
    # Apply retreat with cooldown
    if should_retreat and cooldown <= 0:
        _team_retreat_status[team_id] = true
        _retreat_cooldowns[team_id] = RETREAT_COOLDOWN
        retreat_called.emit(team_id)
    elif strength_ratio > RETREAT_RATIO_THRESHOLD * 1.5:
        # Cancel retreat if situation improves
        _team_retreat_status[team_id] = false


## Updates regroup status for a team.
func _update_regroup_status(team_id: int, bots: Array[Node]) -> void:
    if bots.size() < 2:
        _team_regroup_status[team_id] = false
        return
    
    # Calculate team spread
    var avg_pos: Vector2 = _calculate_average_position(bots)
    var max_dist: float = 0.0
    
    for bot: Node in bots:
        var dist: float = _get_node_position(bot).distance_to(avg_pos)
        max_dist = maxf(max_dist, dist)
    
    # Request regroup if too spread out
    var should_regroup: bool = max_dist > REGROUP_DISTANCE_THRESHOLD
    
    if should_regroup and not _team_regroup_status.get(team_id, false):
        regroup_called.emit(team_id)
    
    _team_regroup_status[team_id] = should_regroup


## Decrements timers for a team.
func _decrement_timers(team_id: int) -> void:
    var focus_timer: int = _focus_target_timers.get(team_id, 0)
    if focus_timer > 0:
        _focus_target_timers[team_id] = maxi(0, focus_timer - _update_interval)


## Clears the focus target for a team.
func _clear_focus_target(team_id: int) -> void:
    if _team_focus_targets.has(team_id):
        _team_focus_targets.erase(team_id)
    if _focus_target_timers.has(team_id):
        _focus_target_timers.erase(team_id)


## Gets the current focus target for a team.
## Returns the target's sim_id, or -1 if no focus target.
func get_team_focus_target(team_id: int) -> int:
    return _team_focus_targets.get(team_id, -1)


## Checks if team should retreat.
func should_retreat(team_id: int) -> bool:
    return _team_retreat_status.get(team_id, false)


## Checks if team should regroup.
func should_regroup(team_id: int) -> bool:
    return _team_regroup_status.get(team_id, false)


## Issues a squad command.
func issue_command(team_id: int, command: String, target: Variant = null) -> void:
    command_issued.emit(team_id, command, target)


## Calculates team strength ratio (allies vs enemies in range).
func _calculate_strength_ratio(team_id: int, bots: Array[Node], enemies: Array[Node]) -> float:
    if enemies.is_empty():
        return 1.0  # Full strength if no enemies
    
    if bots.is_empty():
        return 0.0  # No strength if no bots
    
    var team_strength: float = 0.0
    var enemy_strength: float = 0.0
    
    # Calculate team strength based on health and count
    for bot: Node in bots:
        var health_ratio: float = _get_node_health_ratio(bot)
        team_strength += 0.5 + health_ratio * 0.5  # Base 0.5 for presence
    
    # Calculate enemy strength
    for enemy: Node in enemies:
        var health_ratio: float = _get_node_health_ratio(enemy)
        enemy_strength += 0.5 + health_ratio * 0.5
    
    return team_strength / enemy_strength


## Calculates threat level of an enemy to a group of bots.
func _calculate_enemy_threat(enemy: Node, bots: Array[Node]) -> float:
    var threat: float = 0.0
    var enemy_pos: Vector2 = _get_node_position(enemy)
    
    # Base threat on enemy health (more health = more threat)
    threat += _get_node_health_ratio(enemy) * 20.0
    
    # Add threat based on proximity to allies
    for bot: Node in bots:
        var bot_pos: Vector2 = _get_node_position(bot)
        var dist: float = enemy_pos.distance_to(bot_pos)
        threat += 50.0 / (dist + 1.0)
    
    return threat


## Calculates average of an array of floats.
func _calculate_average(values: Array) -> float:
    if values.is_empty():
        return 0.0
    
    var total: float = 0.0
    for value: float in values:
        total += value
    
    return total / float(values.size())


## Calculates average position of nodes.
func _calculate_average_position(nodes: Array[Node]) -> Vector2:
    if nodes.is_empty():
        return Vector2.ZERO
    
    var total: Vector2 = Vector2.ZERO
    for node: Node in nodes:
        total += _get_node_position(node)
    
    return total / float(nodes.size())


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


## Checks if a node is alive.
func _is_node_alive(node: Node) -> bool:
    if node == null:
        return false
    if node.has_method("is_alive"):
        return node.is_alive()
    return true


## Gets a node's health ratio.
func _get_node_health_ratio(node: Node) -> float:
    if node != null and node.has_method("get_health_ratio"):
        return node.get_health_ratio()
    return 1.0


## Gets a bot's weapon range.
func _get_bot_weapon_range(bot: Node) -> float:
    if bot != null and bot.has_method("get_weapon_range"):
        return bot.get_weapon_range()
    return 300.0


## Sort function for deterministic iteration by sim_id.
func _sort_by_sim_id(a: Node, b: Node) -> bool:
    var id_a: int = _get_node_id(a)
    var id_b: int = _get_node_id(b)
    return id_a < id_b
