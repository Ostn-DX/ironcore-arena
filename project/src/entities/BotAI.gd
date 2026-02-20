extends RefCounted
class_name BotAI
## AI controller for autonomous bot behavior
## State machine: IDLE → ACQUIRING → ENGAGING → COOLDOWN

enum AIState { IDLE, ACQUIRING, ENGAGING, RETREATING }

var bot: Bot
var state: AIState = AIState.IDLE
var target: Bot = null

# AI parameters
var sensor_range: float = 400.0
var retreat_threshold: float = 0.25  # HP % to trigger retreat


func _init(bot_ref: Bot):
	bot = bot_ref


## Main AI update
func evaluate(delta: float) -> void:
	if bot.state == Bot.State.DESTROYED:
		return
	
	# State machine
	match state:
		AIState.IDLE:
			_evaluate_idle()
		
		AIState.ACQUIRING:
			_evaluate_acquiring()
		
		AIState.ENGAGING:
			_evaluate_engaging()
		
		AIState.RETREATING:
			_evaluate_retreating()


## IDLE: Look for targets
func _evaluate_idle() -> void:
	var candidates = _get_enemies_in_range(sensor_range)
	if candidates.size() > 0:
		target = _select_best_target(candidates)
		if target != null:
			state = AIState.ACQUIRING


## ACQUIRING: Move to attack range
func _evaluate_acquiring() -> void:
	if not _validate_target(target):
		state = AIState.IDLE
		target = null
		return
	
	# Check if in weapon range
	if bot.can_attack(target):
		bot.attack(target)
		state = AIState.ENGAGING
	else:
		# Move toward optimal attack position
		var move_pos = _calculate_attack_position(target)
		bot.move_to(move_pos)


## ENGAGING: Attack until dead or out of range
func _evaluate_engaging() -> void:
	# Check retreat condition
	if _should_retreat():
		state = AIState.RETREATING
		return
	
	if not _validate_target(target):
		state = AIState.ACQUIRING
		target = null
		return
	
	if not bot.can_attack(target):
		state = AIState.ACQUIRING
		return
	
	# Bot handles firing in its own state machine
	if bot.state == Bot.State.IDLE and bot.cooldown_timer <= 0:
		bot.attack(target)


## RETREATING: Run away to safe distance
func _evaluate_retreating() -> void:
	var safe_hp = bot.max_hp * 0.5
	var safe_distance = 300.0
	
	# Re-engage if healed or threat eliminated
	if bot.current_hp >= safe_hp or (target != null and target.state == Bot.State.DESTROYED):
		state = AIState.ACQUIRING
		return
	
	# Move away from enemies
	var enemies = _get_enemies_in_range(sensor_range)
	if enemies.size() > 0:
		var retreat_dir = Vector2.ZERO
		for enemy in enemies:
			var dir = (bot.global_position - enemy.global_position).normalized()
			retreat_dir += dir
		
		retreat_dir = retreat_dir.normalized()
		var retreat_pos = bot.global_position + retreat_dir * safe_distance
		bot.move_to(retreat_pos)


## Target validation
func _validate_target(t: Bot) -> bool:
	if t == null:
		return false
	if t.state == Bot.State.DESTROYED:
		return false
	if t.team == bot.team:
		return false
	return true


## Check if should retreat
func _should_retreat() -> bool:
	var hp_ratio = bot.current_hp / bot.max_hp
	if hp_ratio < retreat_threshold:
		return true
	
	# Also retreat if heavily outnumbered
	var nearby_enemies = _get_enemies_in_range(200.0).size()
	var nearby_allies = _get_allies_in_range(200.0).size()
	if nearby_enemies >= 3 and nearby_allies <= 1:
		return true
	
	return false


## Get enemies in range
func _get_enemies_in_range(range: float) -> Array:
	var enemies: Array = []
	# This would query the battle manager in practice
	# For now, placeholder
	return enemies


## Get allies in range
func _get_allies_in_range(range: float) -> Array:
	var allies: Array = []
	return allies


## Select best target using priority scoring
func _select_best_target(candidates: Array) -> Bot:
	var best_target: Bot = null
	var best_score: float = -999.0
	
	for candidate in candidates:
		var score = _evaluate_target(candidate)
		if score > best_score:
			best_score = score
			best_target = candidate
	
	return best_target


## Evaluate target priority (higher = better target)
func _evaluate_target(candidate: Bot) -> float:
	var distance = bot.global_position.distance_to(candidate.global_position)
	
	# Distance component (closer = higher priority)
	var distance_score = 1.0 - (distance / sensor_range)
	
	# Threat component (dangerous + healthy = higher priority)
	var threat_score = 0.0
	if candidate.get_dps() > 0:
		threat_score = candidate.get_dps() * (candidate.current_hp / candidate.max_hp)
		threat_score = clampf(threat_score / 100.0, 0.0, 1.0)  # Normalize
	
	# Health component (weakened = higher priority for cleanup)
	var health_score = 1.0 - (candidate.current_hp / candidate.max_hp)
	
	# Composite score with weights from design doc
	var score = (0.50 * distance_score) + (0.30 * threat_score) + (0.15 * health_score)
	
	return score


## Calculate optimal attack position
func _calculate_attack_position(target_bot: Bot) -> Vector2:
	if bot.weapon_data.is_empty():
		return target_bot.global_position
	
	var optimal_range = bot.weapon_data.get("range_optimal", 150.0)
	var direction = (target_bot.global_position - bot.global_position).normalized()
	
	# Position at optimal range from target
	return target_bot.global_position - direction * optimal_range


## Set manual command override
func set_manual_target(t: Bot) -> void:
	target = t
	state = AIState.ACQUIRING


## Release manual control
func release_manual() -> void:
	state = AIState.IDLE
	target = null
