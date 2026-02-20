extends Node
class_name BattleManager
## Manages combat simulation: spawning, updates, win/loss detection.
## Coordinates with Arena for spawn points and battle flow.

# Arena reference
var arena: Arena = null
var current_arena_data: Dictionary = {}

# Teams
var player_team: Array = []
var enemy_team: Array = []

# Battle state
enum BattleState { SETUP, COUNTDOWN, ACTIVE, PAUSED, ENDED }
var current_state: BattleState = BattleState.SETUP

# Battle tracking
var battle_time: float = 0.0
var player_commands_issued: int = 0
var stats: Dictionary = {}

# Battle result
class BattleResult:
	var victory: bool = false
	var time_seconds: float = 0.0
	var damage_dealt: int = 0
	var damage_taken: int = 0
	var shots_fired: int = 0
	var shots_hit: int = 0
	var enemies_destroyed: int = 0
	var player_bots_lost: int = 0
	var grade: String = "F"
	
	func get_grade() -> String:
		return grade
	
	func _calculate_grade() -> void:
		if not victory:
			grade = "F"
			return
		
		# Grade based on performance
		var score: float = 0.0
		if damage_taken > 0:
			score += (float(damage_dealt) / damage_taken) * 30
		if shots_fired > 0:
			score += (float(shots_hit) / shots_fired) * 30
		
		if time_seconds < 30:
			score += 40
		elif time_seconds < 60:
			score += 30
		elif time_seconds < 120:
			score += 20
		else:
			score += 10
		
		if score >= 90:
			grade = "S"
		elif score >= 80:
			grade = "A"
		elif score >= 65:
			grade = "B"
		elif score >= 50:
			grade = "C"
		else:
			grade = "D"

var _current_result: BattleResult = null

# Signals
signal battle_started(arena_id: String)
signal battle_state_changed(new_state: BattleState, old_state: BattleState)
signal countdown_tick(seconds_left: int)
signal battle_ended(result: BattleResult)
signal rewards_calculated(rewards: Dictionary)
signal bot_spawned(bot: Bot, team: int)
signal bot_destroyed(bot: Bot, team: int)

# References
var battle_screen: Control = null
var _countdown_timer: float = 0.0
var _countdown_value: int = 3

# Rewards
var _base_credits: int = 0
var _bonus_credits: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

# ============================================================================
# SETUP
# ============================================================================

func setup_battle(arena_id: String, player_loadouts: Array) -> bool:
	## Initialize battle with arena and player loadouts
	current_arena_data = DataLoader.get_arena(arena_id)
	if current_arena_data.is_empty():
		push_error("BattleManager: Invalid arena ID: %s" % arena_id)
		return false
	
	# Clear existing
	_clear_teams()
	
	# Get enemy configs from arena waves
	var enemy_configs: Array = _get_enemy_configs_from_arena()
	
	# Store arena ID for reference
	_arena_id = arena_id
	
	# Create arena instance if battle_screen hasn't already
	if battle_screen and battle_screen.has_method("_setup_arena"):
		battle_screen._setup_arena(current_arena_data)
	
	# Get spawn points from arena
	var arena_instance: Arena = null
	if battle_screen and battle_screen.arena:
		arena_instance = battle_screen.arena
	
	# Spawn player bots
	var player_spawns: Array[Vector2] = []
	if arena_instance:
		player_spawns = arena_instance.get_spawn_points(0, player_loadouts.size())
	else:
		player_spawns = _generate_spawn_points(0, player_loadouts.size())
	
	for i in range(player_loadouts.size()):
		var config: Dictionary = player_loadouts[i]
		var spawn_pos: Vector2 = player_spawns[i] if i < player_spawns.size() else Vector2(100 + i * 50, 300)
		var bot = _spawn_bot(config, 0, spawn_pos)
		if bot:
			player_team.append(bot)
	
	# Spawn enemy bots
	var enemy_spawns: Array[Vector2] = []
	if arena_instance:
		enemy_spawns = arena_instance.get_spawn_points(1, enemy_configs.size())
	else:
		enemy_spawns = _generate_spawn_points(1, enemy_configs.size())
	
	for i in range(enemy_configs.size()):
		var config: Dictionary = enemy_configs[i]
		var spawn_pos: Vector2 = enemy_spawns[i] if i < enemy_spawns.size() else Vector2(700 - i * 50, 300)
		var bot = _spawn_bot(config, 1, spawn_pos)
		if bot:
			enemy_team.append(bot)
	
	# Reset state
	current_state = BattleState.SETUP
	battle_time = 0.0
	player_commands_issued = 0
	stats = {
		"damage_dealt": 0, 
		"damage_taken": 0, 
		"shots_fired": 0, 
		"shots_hit": 0,
		"enemies_destroyed": 0,
		"player_bots_lost": 0
	}
	
	print("BattleManager: Battle setup complete - Arena: %s, Player bots: %d, Enemy bots: %d" % [
		arena_id, player_team.size(), enemy_team.size()
	])
	
	return true

var _arena_id: String = ""

func _get_enemy_configs_from_arena() -> Array:
	## Extract enemy configurations from arena wave data
	var enemies: Array = []
	var waves: Array = current_arena_data.get("waves", [])
	
	for wave in waves:
		var wave_enemies: Array = wave.get("enemies", [])
		for enemy_id in wave_enemies:
			# Get enemy data from DataLoader or enemy slice
			var enemy_data: Dictionary = _load_enemy_data(enemy_id)
			if not enemy_data.is_empty():
				enemies.append(enemy_data)
	
	return enemies

func _load_enemy_data(enemy_id: String) -> Dictionary:
	## Load enemy configuration from data files
	# Try to load from enemies slice
	var enemies_path: String = "res://data/slice/enemies_slice.json"
	if FileAccess.file_exists(enemies_path):
		var file: FileAccess = FileAccess.open(enemies_path, FileAccess.READ)
		var json: JSON = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var enemies: Array = json.data
			for enemy in enemies:
				if enemy is Dictionary and enemy.get("id") == enemy_id:
					return enemy
	
	# Fallback: create basic enemy from parts
	return _create_fallback_enemy(enemy_id)

func _create_fallback_enemy(enemy_id: String) -> Dictionary:
	## Create a basic enemy config if data not found
	var tier: int = 1
	if "_t2" in enemy_id:
		tier = 2
	elif "_t3" in enemy_id:
		tier = 3
	
	var config: Dictionary = {
		"id": enemy_id,
		"name": "Enemy Bot",
		"chassis": "akaumin_dl2_100",
		"plating": "santrin_auro",
		"weapon": "raptor_dt_01"
	}
	
	# Adjust based on enemy type
	if "scout" in enemy_id:
		config["chassis"] = "velox_mk1"
		config["weapon"] = "raptor_dt_01"
	elif "tank" in enemy_id:
		config["chassis"] = "aegis_ht5"
		config["plating"] = "titan_plate"
	elif "sniper" in enemy_id:
		config["weapon"] = "viper_sr_03"
	
	return config

func _generate_spawn_points(team: int, count: int) -> Array[Vector2]:
	## Generate fallback spawn positions
	var points: Array[Vector2] = []
	var size_data: Dictionary = current_arena_data.get("size", {"width": 800, "height": 600})
	var width: float = size_data.get("width", 800)
	var height: float = size_data.get("height", 600)
	var margin: float = 80.0
	
	if team == 0:  # Player - left side
		for i in range(count):
			var y: float = lerp(margin, height - margin, (i + 1.0) / (count + 1.0))
			points.append(Vector2(margin + 50, y))
	else:  # Enemy - right side
		for i in range(count):
			var y: float = lerp(margin, height - margin, (i + 1.0) / (count + 1.0))
			points.append(Vector2(width - margin - 50, y))
	
	return points

func _spawn_bot(config: Dictionary, team_id: int, spawn_pos: Vector2) -> Bot:
	## Spawn a single bot from configuration
	var bot: Bot = Bot.new()
	
	# Build bot from config
	var chassis_id: String = config.get("chassis", "akaumin_dl2_100")
	var plating_id: String = config.get("plating", config.get("armor", ["santrin_auro"])[0] if config.has("armor") else "santrin_auro")
	var weapon_id: String = config.get("weapon", config.get("weapons", ["raptor_dt_01"])[0] if config.has("weapons") else "raptor_dt_01")
	
	var success: bool = bot.build(chassis_id, plating_id, weapon_id)
	
	if not success:
		push_error("BattleManager: Failed to build bot with chassis=%s, plating=%s, weapon=%s" % [chassis_id, plating_id, weapon_id])
		bot.queue_free()
		return null
	
	bot.team = team_id
	bot.global_position = spawn_pos
	
	# Connect destruction signal
	if bot.has_signal("bot_destroyed"):
		bot.bot_destroyed.connect(_on_bot_destroyed.bind(bot))
	
	# Add to scene
	add_child(bot)
	
	# Also add to SimulationManager if available
	if SimulationManager:
		SimulationManager.register_bot(bot)
	
	bot_spawned.emit(bot, team_id)
	
	return bot

# ============================================================================
# BATTLE FLOW
# ============================================================================

func start_battle() -> void:
	## Start the battle countdown
	if current_state != BattleState.SETUP:
		push_warning("BattleManager: Cannot start battle from state: %s" % current_state)
		return
	
	_change_state(BattleState.COUNTDOWN)
	_countdown_timer = 3.0
	_countdown_value = 3
	
	battle_started.emit(_arena_id)

func _change_state(new_state: BattleState) -> void:
	var old_state: BattleState = current_state
	current_state = new_state
	battle_state_changed.emit(new_state, old_state)

func _process(delta: float) -> void:
	match current_state:
		BattleState.COUNTDOWN:
			_process_countdown(delta)
		BattleState.ACTIVE:
			_process_battle(delta)

func _process_countdown(delta: float) -> void:
	_countdown_timer -= delta
	var new_countdown: int = ceil(_countdown_timer)
	
	if new_countdown != _countdown_value:
		_countdown_value = new_countdown
		countdown_tick.emit(_countdown_value)
	
	if _countdown_timer <= 0:
		_change_state(BattleState.ACTIVE)
		battle_time = 0.0

func _process_battle(delta: float) -> void:
	battle_time += delta
	
	# Update bots
	for bot in player_team:
		if bot.state != Bot.State.DESTROYED:
			_update_bot(bot, delta)
	
	for bot in enemy_team:
		if bot.state != Bot.State.DESTROYED:
			_update_bot(bot, delta)
	
	# Check win/loss
	_check_battle_end()

func _update_bot(bot: Bot, delta: float) -> void:
	# AI evaluation for enemy bots
	if bot.team == 1 and bot.has_node("AI"):
		var ai = bot.get_node("AI") as BotAI
		if ai:
			ai.evaluate(delta)
	
	# Bot internal process
	bot._physics_process(delta)

# ============================================================================
# WIN/LOSS DETECTION
# ============================================================================

func _check_battle_end() -> void:
	var player_alive: int = _count_alive(player_team)
	var enemy_alive: int = _count_alive(enemy_team)
	
	if enemy_alive == 0:
		_end_battle(true)  # Victory
	elif player_alive == 0:
		_end_battle(false)  # Defeat

func _count_alive(team: Array) -> int:
	var count: int = 0
	for bot in team:
		if bot.state != Bot.State.DESTROYED:
			count += 1
	return count

func _end_battle(victory: bool) -> void:
	_change_state(BattleState.ENDED)
	
	_current_result = BattleResult.new()
	_current_result.victory = victory
	_current_result.time_seconds = battle_time
	_current_result.damage_dealt = stats.get("damage_dealt", 0)
	_current_result.damage_taken = stats.get("damage_taken", 0)
	_current_result.shots_fired = stats.get("shots_fired", 0)
	_current_result.shots_hit = stats.get("shots_hit", 0)
	_current_result.enemies_destroyed = stats.get("enemies_destroyed", 0)
	_current_result.player_bots_lost = stats.get("player_bots_lost", 0)
	_current_result._calculate_grade()
	
	# Calculate rewards
	_calculate_rewards()
	
	battle_ended.emit(_current_result)

func _calculate_rewards() -> void:
	## Calculate credits earned from battle
	if not _current_result:
		return
	
	if not _current_result.victory:
		_base_credits = 0
		_bonus_credits = 0
	else:
		# Base reward from arena
		_base_credits = current_arena_data.get("reward_credits", 100)
		
		# Bonus based on performance
		_bonus_credits = 0
		match _current_result.grade:
			"S": _bonus_credits = _base_credits
			"A": _bonus_credits = int(_base_credits * 0.5)
			"B": _bonus_credits = int(_base_credits * 0.25)
			_: _bonus_credits = 0
		
		# Time bonus
		if _current_result.time_seconds < 30:
			_bonus_credits += 50
	
	var rewards: Dictionary = {
		"credits": _base_credits + _bonus_credits,
		"base_credits": _base_credits,
		"bonus_credits": _bonus_credits,
		"grade": _current_result.grade
	}
	
	# Add to GameState
	if GameState:
		GameState.add_credits(rewards["credits"])
	
	rewards_calculated.emit(rewards)

func _on_bot_destroyed(bot: Bot) -> void:
	## Track bot destruction
	if bot.team == 0:
		stats["player_bots_lost"] = stats.get("player_bots_lost", 0) + 1
	else:
		stats["enemies_destroyed"] = stats.get("enemies_destroyed", 0) + 1
	
	bot_destroyed.emit(bot, bot.team)

# ============================================================================
# COMMANDS
# ============================================================================

func command_move(bot_index: int, position: Vector2) -> void:
	## Issue move command to player bot
	if current_state != BattleState.ACTIVE:
		return
	
	if bot_index < 0 or bot_index >= player_team.size():
		return
	
	var bot = player_team[bot_index]
	if bot.state != Bot.State.DESTROYED:
		# Implementation depends on Bot API
		if bot.has_method("move_to"):
			bot.move_to(position)
		player_commands_issued += 1

func command_attack(bot_index: int, target: Bot) -> void:
	## Issue attack command to player bot
	if current_state != BattleState.ACTIVE:
		return
	
	if bot_index < 0 or bot_index >= player_team.size():
		return
	
	var bot = player_team[bot_index]
	if bot.state != Bot.State.DESTROYED:
		if bot.has_method("attack"):
			bot.attack(target)
		player_commands_issued += 1

# ============================================================================
# UTILITY
# ============================================================================

func _clear_teams() -> void:
	## Clear all bots
	for bot in player_team:
		if is_instance_valid(bot):
			bot.queue_free()
	player_team.clear()
	
	for bot in enemy_team:
		if is_instance_valid(bot):
			bot.queue_free()
	enemy_team.clear()

func pause() -> void:
	## Pause battle
	if current_state == BattleState.ACTIVE:
		_change_state(BattleState.PAUSED)
		get_tree().paused = true

func resume() -> void:
	## Resume battle
	if current_state == BattleState.PAUSED:
		_change_state(BattleState.ACTIVE)
		get_tree().paused = false

func end_battle_early() -> void:
	## End battle immediately (for quitting)
	if current_state == BattleState.ACTIVE or current_state == BattleState.COUNTDOWN:
		_end_battle(false)

func is_battle_active() -> bool:
	return current_state == BattleState.ACTIVE

func is_battle_ended() -> bool:
	return current_state == BattleState.ENDED

func get_current_arena() -> Dictionary:
	return current_arena_data

func get_battle_summary() -> Dictionary:
	## Get summary for HUD
	return {
		"arena_name": current_arena_data.get("name", "Unknown"),
		"time": "%.1f" % battle_time,
		"player_alive": _count_alive(player_team),
		"player_total": player_team.size(),
		"enemy_alive": _count_alive(enemy_team),
		"enemy_total": enemy_team.size()
	}

func get_battle_stats() -> Dictionary:
	## Get full battle stats
	return {
		"time": battle_time,
		"commands": player_commands_issued,
		"player_alive": _count_alive(player_team),
		"player_total": player_team.size(),
		"enemy_alive": _count_alive(enemy_team),
		"enemy_total": enemy_team.size(),
		"damage_dealt": stats.get("damage_dealt", 0),
		"damage_taken": stats.get("damage_taken", 0),
		"shots_fired": stats.get("shots_fired", 0),
		"shots_hit": stats.get("shots_hit", 0)
	}
