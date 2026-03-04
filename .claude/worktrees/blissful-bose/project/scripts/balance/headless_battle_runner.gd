class_name HeadlessBattleRunner extends Node

## Runs headless battle simulations for balance analysis.
## This class manages batch execution of battle simulations without rendering,
## collecting metrics for balance analysis and tuning recommendations.
##
## @tutorial: Create a BattleBatchConfig resource, then call run_batch(config)

signal match_completed(match_index: int, result: Dictionary)
## Emitted when a single match completes. Contains match index and result data.

signal batch_completed(results: BattleBatchResult)
## Emitted when the entire batch completes. Contains aggregated results.

signal match_progress(current: int, total: int)
## Emitted periodically to report batch progress.

const DEFAULT_MAX_TICKS: int = 10800
## Default maximum ticks per match (3 minutes at 60Hz)

const DEFAULT_TIMEOUT_TICKS: int = 21600
## Default timeout ticks (6 minutes at 60Hz)

const TICKS_PER_SECOND: int = 60
## Simulation tick rate

# Internal state
var _simulation_manager: Node = null
## Reference to the simulation manager node

var _metrics: BattleMetrics = null
## Metrics collector for current match

var _current_config: BattleBatchConfig = null
## Currently running batch configuration

var _active_bots: Array[Node] = []
## List of active bot nodes in current match

var _current_tick: int = 0
## Current simulation tick

var _match_start_tick: int = 0
## Tick when current match started

var _rng: RandomNumberGenerator = null
## Seeded random number generator for determinism

var _is_running: bool = false
## Whether a batch is currently running

var _should_abort: bool = false
## Flag to abort current batch

## Runs a batch of battles with the given configuration.
##
## @param config: The BattleBatchConfig containing simulation parameters
## @return: A BattleBatchResult containing all match results and aggregates
## @example:
##     var runner = HeadlessBattleRunner.new()
##     var config = BattleBatchConfig.new()
##     config.seeds = PackedInt32Array([12345, 67890])
##     config.matches_per_seed = 10
##     var result = runner.run_batch(config)
func run_batch(config: BattleBatchConfig) -> BattleBatchResult:
	if _is_running:
		push_warning("HeadlessBattleRunner: Batch already running, aborting previous")
		_should_abort = true
		await batch_completed
	
	_is_running = true
	_should_abort = false
	_current_config = config
	
	var result := BattleBatchResult.new()
	result.config = config
	
	var total_matches: int = config.get_total_matches()
	var current_match: int = 0
	
	print("HeadlessBattleRunner: Starting batch of %d matches" % total_matches)
	
	for seed in config.seeds:
		if _should_abort:
			break
			
		for match_idx in range(config.matches_per_seed):
			if _should_abort:
				break
			
			current_match += 1
			match_progress.emit(current_match, total_matches)
			
			var match_result := _run_single_match(seed, config, match_idx)
			result.match_results.append(match_result)
			match_completed.emit(current_match - 1, match_result)
			
			print("HeadlessBattleRunner: Match %d/%d completed (seed: %d)" % [current_match, total_matches, seed])
	
	result.finalize()
	batch_completed.emit(result)
	_is_running = false
	
	print("HeadlessBattleRunner: Batch completed in %.2f seconds" % (result.get_duration_sec()))
	
	return result


## Runs a single match with the given seed and configuration.
##
## @param seed: The random seed for deterministic simulation
## @param config: The batch configuration
## @param match_index: Index of this match within the seed group
## @return: Dictionary containing match results and metrics
func _run_single_match(seed: int, config: BattleBatchConfig, match_index: int = 0) -> Dictionary:
	# Initialize RNG with combined seed for uniqueness
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed + match_index * 1000
	
	# Reset and setup simulation
	_setup_simulation(seed, config)
	
	# Spawn teams
	_spawn_teams(config)
	
	# Initialize metrics
	_metrics = BattleMetrics.new()
	_metrics.match_start_time = Time.get_ticks_msec()
	
	# Run simulation loop
	_match_start_tick = _current_tick
	var winner: int = -1
	var end_reason: String = ""
	
	while _current_tick < config.max_ticks_per_match:
		# Process a single simulation tick
		_process_tick()
		
		# Check win condition
		var win_check := _check_win_condition()
		if win_check.has("winner"):
			winner = win_check.winner
			end_reason = win_check.get("reason", "unknown")
			break
		
		_current_tick += 1
	
	# Handle timeout
	if winner == -1:
		end_reason = "timeout"
		winner = _determine_winner_by_health()
	
	# Finalize metrics
	_metrics.match_end_time = Time.get_ticks_msec()
	var match_metrics := _metrics.finalize()
	
	# Build result dictionary
	var result := {
		"seed": seed,
		"match_index": match_index,
		"winner_team": winner,
		"end_reason": end_reason,
		"duration_ticks": _current_tick - _match_start_tick,
		"duration_seconds": float(_current_tick - _match_start_tick) / TICKS_PER_SECOND,
		"metrics": match_metrics,
		"team_a_alive": _count_alive_bots(0),
		"team_b_alive": _count_alive_bots(1),
		"team_a_health": _get_team_total_health(0),
		"team_b_health": _get_team_total_health(1)
	}
	
	# Cleanup
	_cleanup_match()
	
	return result


## Sets up the simulation manager for headless mode.
##
## @param seed: The random seed
## @param config: The batch configuration
func _setup_simulation(seed: int, config: BattleBatchConfig) -> void:
	_current_tick = 0
	_active_bots.clear()
	
	# Create or reset simulation manager
	if _simulation_manager == null:
		_simulation_manager = Node.new()
		_simulation_manager.name = "SimulationManager"
		add_child(_simulation_manager)
	
	# Clear any existing children
	for child in _simulation_manager.get_children():
		child.queue_free()
	
	_simulation_manager.get_children().clear()
	
	# Configure for headless mode
	Engine.max_fps = 0  # Uncapped for fastest simulation
	
	print("HeadlessBattleRunner: Simulation setup complete (seed: %d)" % seed)


## Spawns bots for both teams based on configuration.
##
## @param config: The batch configuration containing team loadouts
func _spawn_teams(config: BattleBatchConfig) -> void:
	# Spawn Team A
	for i in range(config.bots_per_team):
		var bot := _create_bot(0, i, config.team_a_loadout)
		if bot:
			_active_bots.append(bot)
			_simulation_manager.add_child(bot)
	
	# Spawn Team B
	for i in range(config.bots_per_team):
		var bot := _create_bot(1, i, config.team_b_loadout)
		if bot:
			_active_bots.append(bot)
			_simulation_manager.add_child(bot)
	
	print("HeadlessBattleRunner: Spawned %d bots (%d per team)" % [_active_bots.size(), config.bots_per_team])


## Creates a single bot instance.
##
## @param team_id: The team ID (0 or 1)
## @param bot_index: Index within the team
## @param loadout: Dictionary containing bot loadout configuration
## @return: The created bot node, or null if creation failed
func _create_bot(team_id: int, bot_index: int, loadout: Dictionary) -> Node:
	# This is a placeholder - actual implementation depends on your bot class
	# Returns a simulated bot node with required interface
	var bot := Node3D.new()
	bot.name = "Bot_T%d_%d" % [team_id, bot_index]
	
	# Set metadata for identification
	bot.set_meta("team_id", team_id)
	bot.set_meta("bot_id", "T%d_%d" % [team_id, bot_index])
	bot.set_meta("bot_index", bot_index)
	bot.set_meta("health", loadout.get("health", 100.0))
	bot.set_meta("max_health", loadout.get("health", 100.0))
	bot.set_meta("weapon_id", loadout.get("weapon_id", "default_weapon"))
	bot.set_meta("chassis_id", loadout.get("chassis_id", "default_chassis"))
	bot.set_meta("is_alive", true)
	bot.set_meta("shots_fired", 0)
	bot.set_meta("shots_hit", 0)
	bot.set_meta("damage_dealt", 0.0)
	bot.set_meta("movement_ticks", 0)
	bot.set_meta("idle_ticks", 0)
	bot.set_meta("last_position", Vector3.ZERO)
	
	# Random starting position
	var spawn_offset := Vector3(
		_rng.randf_range(-50, 50),
		0,
		_rng.randf_range(-50, 50)
	)
	bot.position = spawn_offset + (Vector3.RIGHT * 100 if team_id == 0 else Vector3.LEFT * 100)
	bot.set_meta("last_position", bot.position)
	
	return bot


## Processes a single simulation tick.
func _process_tick() -> void:
	for bot in _active_bots:
		if not bot.get_meta("is_alive", false):
			continue
		
		# Simulate bot behavior
		_simulate_bot_tick(bot)


## Simulates a single bot's behavior for one tick.
##
## @param bot: The bot node to simulate
func _simulate_bot_tick(bot: Node) -> void:
	var team_id: int = bot.get_meta("team_id", 0)
	var bot_id: String = bot.get_meta("bot_id", "unknown")
	
	# Find nearest enemy
	var target := _find_nearest_enemy(bot)
	
	if target:
		# Move towards target
		var direction: Vector3 = (target.position - bot.position).normalized()
		var speed: float = 5.0  # Units per second
		bot.position += direction * speed / TICKS_PER_SECOND
		
		bot.set_meta("movement_ticks", bot.get_meta("movement_ticks", 0) + 1)
		
		# Fire at target if in range
		var distance: float = bot.position.distance_to(target.position)
		if distance < 50.0:
			_fire_weapon(bot, target)
	else:
		# Idle behavior - patrol randomly
		bot.position += Vector3(
			_rng.randf_range(-1, 1),
			0,
			_rng.randf_range(-1, 1)
		).normalized() * 2.0 / TICKS_PER_SECOND
		bot.set_meta("idle_ticks", bot.get_meta("idle_ticks", 0) + 1)
	
	# Record movement event
	var moved: bool = bot.position != bot.get_meta("last_position", Vector3.ZERO)
	if moved:
		_metrics.record_event({
			"type": "movement",
			"bot_id": bot_id,
			"tick": _current_tick,
			"position": bot.position,
			"distance": bot.position.distance_to(bot.get_meta("last_position", Vector3.ZERO))
		})
		bot.set_meta("last_position", bot.position)


## Finds the nearest living enemy bot.
##
## @param bot: The bot searching for enemies
## @return: The nearest enemy bot node, or null if none found
func _find_nearest_enemy(bot: Node) -> Node:
	var team_id: int = bot.get_meta("team_id", 0)
	var nearest: Node = null
	var nearest_dist: float = 999999.0
	
	for other in _active_bots:
		if other == bot:
			continue
		if other.get_meta("team_id", 0) == team_id:
			continue
		if not other.get_meta("is_alive", false):
			continue
		
		var dist: float = bot.position.distance_to(other.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = other
	
	return nearest


## Simulates a weapon firing.
##
## @param shooter: The bot firing the weapon
## @param target: The target bot
func _fire_weapon(shooter: Node, target: Node) -> void:
	var weapon_id: String = shooter.get_meta("weapon_id", "default_weapon")
	var shooter_id: String = shooter.get_meta("bot_id", "unknown")
	var target_id: String = target.get_meta("bot_id", "unknown")
	
	shooter.set_meta("shots_fired", shooter.get_meta("shots_fired", 0) + 1)
	
	# Calculate hit probability based on distance
	var distance: float = shooter.position.distance_to(target.position)
	var hit_chance: float = clampf(1.0 - (distance / 100.0), 0.1, 0.9)
	
	var hit: bool = _rng.randf() < hit_chance
	
	_metrics.record_event({
		"type": "shot_fired",
		"weapon_id": weapon_id,
		"shooter_id": shooter_id,
		"target_id": target_id,
		"tick": _current_tick,
		"hit": hit,
		"distance": distance
	})
	
	if hit:
		shooter.set_meta("shots_hit", shooter.get_meta("shots_hit", 0) + 1)
		_apply_damage(shooter, target, weapon_id)


## Applies damage to a target bot.
##
## @param attacker: The attacking bot
## @param target: The target bot
## @param weapon_id: The weapon ID used
func _apply_damage(attacker: Node, target: Node, weapon_id: String) -> void:
	var damage: float = _get_weapon_damage(weapon_id)
	var current_health: float = target.get_meta("health", 100.0)
	var new_health: float = maxf(0.0, current_health - damage)
	
	target.set_meta("health", new_health)
	attacker.set_meta("damage_dealt", attacker.get_meta("damage_dealt", 0.0) + damage)
	
	_metrics.record_event({
		"type": "damage",
		"weapon_id": weapon_id,
		"attacker_id": attacker.get_meta("bot_id", "unknown"),
		"target_id": target.get_meta("bot_id", "unknown"),
		"damage": damage,
		"tick": _current_tick,
		"remaining_health": new_health
	})
	
	if new_health <= 0.0:
		_kill_bot(attacker, target)


## Gets the damage value for a weapon.
##
## @param weapon_id: The weapon identifier
## @return: The damage per hit
func _get_weapon_damage(weapon_id: String) -> float:
	# Default damage values - should be loaded from weapon database
	var damage_table := {
		"default_weapon": 10.0,
		"laser_rifle": 15.0,
		"plasma_cannon": 25.0,
		"machine_gun": 8.0,
		"sniper_rifle": 50.0,
		"shotgun": 12.0
	}
	return damage_table.get(weapon_id, 10.0)


## Kills a bot and records the event.
##
## @param killer: The bot that made the kill
## @param victim: The bot that died
func _kill_bot(killer: Node, victim: Node) -> void:
	victim.set_meta("is_alive", false)
	
	var time_to_kill: float = float(_current_tick - _match_start_tick) / TICKS_PER_SECOND
	
	_metrics.record_event({
		"type": "kill",
		"killer_id": killer.get_meta("bot_id", "unknown"),
		"victim_id": victim.get_meta("bot_id", "unknown"),
		"weapon_id": killer.get_meta("weapon_id", "unknown"),
		"tick": _current_tick,
		"time_to_kill": time_to_kill
	})


## Checks if the match has ended.
##
## @return: Dictionary with "winner" key if match ended, empty otherwise
func _check_win_condition() -> Dictionary:
	var team_a_alive: int = _count_alive_bots(0)
	var team_b_alive: int = _count_alive_bots(1)
	
	if team_a_alive == 0 and team_b_alive > 0:
		return {"winner": 1, "reason": "elimination"}
	elif team_b_alive == 0 and team_a_alive > 0:
		return {"winner": 0, "reason": "elimination"}
	elif team_a_alive == 0 and team_b_alive == 0:
		return {"winner": -1, "reason": "draw"}
	
	return {}


## Counts the number of living bots on a team.
##
## @param team_id: The team ID to count
## @return: Number of alive bots on the team
func _count_alive_bots(team_id: int) -> int:
	var count: int = 0
	for bot in _active_bots:
		if bot.get_meta("team_id", -1) == team_id and bot.get_meta("is_alive", false):
			count += 1
	return count


## Gets the total health of all bots on a team.
##
## @param team_id: The team ID
## @return: Sum of health for all bots on the team
func _get_team_total_health(team_id: int) -> float:
	var total: float = 0.0
	for bot in _active_bots:
		if bot.get_meta("team_id", -1) == team_id:
			total += bot.get_meta("health", 0.0)
	return total


## Determines the winner based on remaining health when timed out.
##
## @return: The winning team ID, or -1 for draw
func _determine_winner_by_health() -> int:
	var team_a_health: float = _get_team_total_health(0)
	var team_b_health: float = _get_team_total_health(1)
	
	if team_a_health > team_b_health:
		return 0
	elif team_b_health > team_a_health:
		return 1
	else:
		return -1


## Cleans up after a match ends.
func _cleanup_match() -> void:
	for bot in _active_bots:
		if is_instance_valid(bot):
			bot.queue_free()
	_active_bots.clear()
	_metrics = null


## Aborts the currently running batch.
func abort_batch() -> void:
	_should_abort = true
	print("HeadlessBattleRunner: Abort requested")


## Returns whether a batch is currently running.
##
## @return: True if a batch is in progress
func is_running() -> bool:
	return _is_running


## Gets the current batch progress.
##
## @return: Dictionary with current and total match counts
func get_progress() -> Dictionary:
	if not _is_running or _current_config == null:
		return {"current": 0, "total": 0}
	
	var total: int = _current_config.get_total_matches()
	# This is approximate since we don't track exact current match
	return {"current": 0, "total": total}
