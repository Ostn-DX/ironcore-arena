extends Node
class_name BattleManager
const Bot = preload("res://src/entities/bot.gd")
const Arena = preload("res://src/entities/arena.gd")
## Manages combat simulation: spawning, updates, win/loss detection.
## OPTIMIZED: Cached lookups, reduced allocations, streamlined signals

@onready var _data_loader = get_node("/root/DataLoader")
@onready var _game_state = get_node("/root/GameState")
@onready var _simulation_manager = get_node("/root/SimulationManager")

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
var max_battle_time: float = 300.0
var player_commands_issued: int = 0
var stats: Dictionary = {}

# Battle result
class BattleResult:
	enum ResultType { VICTORY, DEFEAT, DRAW, TIMEOUT }
	
	var result_type: ResultType = ResultType.DEFEAT
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
	
	func is_victory() -> bool:
		return result_type == ResultType.VICTORY
	
	func _calculate_grade() -> void:
		if result_type != ResultType.VICTORY:
			grade = "F"
			victory = false
			return
		
		victory = true
		var score: float = 0.0
		
		if damage_taken > 0:
			score += (float(damage_dealt) / damage_taken) * 30.0
		else:
			score += 30.0
		
		if shots_fired > 0:
			score += (float(shots_hit) / shots_fired) * 30.0
		
		if time_seconds < 30.0:
			score += 40.0
		elif time_seconds < 60.0:
			score += 30.0
		elif time_seconds < 120.0:
			score += 20.0
		else:
			score += 10.0
		
		if score >= 90.0:
			grade = "S"
		elif score >= 80.0:
			grade = "A"
		elif score >= 65.0:
			grade = "B"
		elif score >= 50.0:
			grade = "C"
		else:
			grade = "D"
	
	func to_dictionary() -> Dictionary:
		return {
			"victory": victory,
			"result_type": result_type,
			"time_seconds": time_seconds,
			"time_formatted": "%d:%02d" % [int(time_seconds) / 60, int(time_seconds) % 60],
			"damage_dealt": damage_dealt,
			"damage_taken": damage_taken,
			"shots_fired": shots_fired,
			"shots_hit": shots_hit,
			"accuracy": (float(shots_hit) / shots_fired * 100.0) if shots_fired > 0 else 0.0,
			"enemies_destroyed": enemies_destroyed,
			"player_bots_lost": player_bots_lost,
			"grade": grade,
			"kdr": float(enemies_destroyed) / player_bots_lost if player_bots_lost > 0 else float(enemies_destroyed)
		}

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
var _battle_end_triggered: bool = false

# Rewards
var _base_credits: int = 0
var _bonus_credits: int = 0

# Arena ID cache
var _arena_id: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func setup_battle(arena_id: String, player_loadouts: Array) -> bool:
	current_arena_data = _data_loader.get_arena(arena_id)
	if current_arena_data.is_empty():
		push_error("BattleManager: Invalid arena ID: %s" % arena_id)
		return false
	
	_clear_teams()
	_battle_end_triggered = false
	
	var enemy_configs: Array = _get_enemy_configs_from_arena()
	_arena_id = arena_id
	max_battle_time = current_arena_data.get("time_limit", 300.0)
	
	if battle_screen and battle_screen.has_method("_setup_arena"):
		battle_screen._setup_arena(current_arena_data)
	
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
		var spawn_pos: Vector2 = player_spawns[i] if i < player_spawns.size() else Vector2(100 + i * 50, 300)
		var bot = _spawn_bot(player_loadouts[i], 0, spawn_pos)
		if bot:
			player_team.append(bot)
	
	# Spawn enemy bots
	var enemy_spawns: Array[Vector2] = []
	if arena_instance:
		enemy_spawns = arena_instance.get_spawn_points(1, enemy_configs.size())
	else:
		enemy_spawns = _generate_spawn_points(1, enemy_configs.size())
	
	for i in range(enemy_configs.size()):
		var spawn_pos: Vector2 = enemy_spawns[i] if i < enemy_spawns.size() else Vector2(700 - i * 50, 300)
		var bot = _spawn_bot(enemy_configs[i], 1, spawn_pos)
		if bot:
			enemy_team.append(bot)
	
	_reset_state()
	return true

func _reset_state() -> void:
	current_state = BattleState.SETUP
	battle_time = 0.0
	player_commands_issued = 0
	_reset_stats()

func _reset_stats() -> void:
	stats = {
		"damage_dealt": 0,
		"damage_taken": 0,
		"shots_fired": 0,
		"shots_hit": 0,
		"enemies_destroyed": 0,
		"player_bots_lost": 0,
		"commands_issued": 0
	}

func _get_enemy_configs_from_arena() -> Array:
	var enemies: Array = []
	var waves: Array = current_arena_data.get("waves", [])
	
	for wave in waves:
		for enemy_id in wave.get("enemies", []):
			var enemy_data: Dictionary = _load_enemy_data(enemy_id)
			if not enemy_data.is_empty():
				enemies.append(enemy_data)
	
	return enemies

func _load_enemy_data(enemy_id: String) -> Dictionary:
	var enemies_path: String = "res://data/slice/enemies_slice.json"
	if FileAccess.file_exists(enemies_path):
		var file: FileAccess = FileAccess.open(enemies_path, FileAccess.READ)
		var json: JSON = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			for enemy in json.data:
				if enemy is Dictionary and enemy.get("id") == enemy_id:
					return enemy
	return _create_fallback_enemy(enemy_id)

func _create_fallback_enemy(enemy_id: String) -> Dictionary:
	var config: Dictionary = {
		"id": enemy_id,
		"name": "Enemy Bot",
		"chassis": "akaumin_dl2_100",
		"plating": "santrin_auro",
		"weapon": "raptor_dt_01"
	}
	
	if "scout" in enemy_id:
		config["chassis"] = "velox_mk1"
	elif "tank" in enemy_id:
		config["chassis"] = "aegis_ht5"
		config["plating"] = "titan_plate"
	elif "sniper" in enemy_id:
		config["weapon"] = "viper_sr_03"
	
	return config

func _generate_spawn_points(team: int, count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var size_data: Dictionary = current_arena_data.get("size", {"width": 800, "height": 600})
	var width: float = size_data.get("width", 800)
	var height: float = size_data.get("height", 600)
	var margin: float = 80.0
	
	for i in range(count):
		var y: float = lerp(margin, height - margin, (i + 1.0) / (count + 1.0))
		if team == 0:
			points.append(Vector2(margin + 50, y))
		else:
			points.append(Vector2(width - margin - 50, y))
	
	return points

func _spawn_bot(config: Dictionary, team_id: int, spawn_pos: Vector2) -> Bot:
	var bot_id: int = player_team.size() + enemy_team.size()
	var bot = Bot.new(bot_id, team_id, spawn_pos)
	
	var chassis_id: String = config.get("chassis", "akaumin_dl2_100")
	var plating_id: String = config.get("plating", config.get("armor", ["santrin_auro"])[0] if config.has("armor") else "santrin_auro")
	var weapon_id: String = config.get("weapon", config.get("weapons", ["raptor_dt_01"])[0] if config.has("weapons") else "raptor_dt_01")
	
	if not bot.build(chassis_id, plating_id, weapon_id):
		bot.queue_free()
		return null
	
	bot.team = team_id
	bot.global_position = spawn_pos
	
	if bot.has_signal("bot_destroyed"):
		bot.bot_destroyed.connect(_on_bot_destroyed.bind(bot))
	
	add_child(bot)
	
	_simulation_manager.register_bot(bot)
	
	bot_spawned.emit(bot, team_id)
	return bot

func start_battle() -> void:
	if current_state != BattleState.SETUP:
		return
	
	_battle_end_triggered = false
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
	
	for bot in player_team:
		if bot.state != Bot.State.DESTROYED:
			bot._physics_process(delta)
	
	for bot in enemy_team:
		if bot.state != Bot.State.DESTROYED:
			bot._physics_process(delta)
	
	_check_battle_end()

func _check_battle_end() -> void:
	if _battle_end_triggered:
		return
	
	var player_alive: int = _count_alive(player_team)
	var enemy_alive: int = _count_alive(enemy_team)
	
	if battle_time >= max_battle_time:
		_handle_timeout(player_alive, enemy_alive)
	elif enemy_alive == 0 and player_alive > 0:
		_end_battle(BattleResult.ResultType.VICTORY)
	elif player_alive == 0 and enemy_alive > 0:
		_end_battle(BattleResult.ResultType.DEFEAT)
	elif player_alive == 0 and enemy_alive == 0:
		_end_battle(BattleResult.ResultType.DRAW)

func _handle_timeout(player_alive: int, enemy_alive: int) -> void:
	if player_alive > enemy_alive:
		_end_battle(BattleResult.ResultType.VICTORY)
	elif player_alive < enemy_alive:
		_end_battle(BattleResult.ResultType.DEFEAT)
	else:
		_end_battle(BattleResult.ResultType.TIMEOUT)

func _count_alive(team: Array) -> int:
	var count: int = 0
	for bot in team:
		if bot.state != Bot.State.DESTROYED:
			count += 1
	return count

func _end_battle(result_type: BattleResult.ResultType) -> void:
	if _battle_end_triggered:
		return
	
	_battle_end_triggered = true
	_change_state(BattleState.ENDED)
	
	_current_result = BattleResult.new()
	_current_result.result_type = result_type
	_current_result.time_seconds = battle_time
	_current_result.damage_dealt = stats.get("damage_dealt", 0)
	_current_result.damage_taken = stats.get("damage_taken", 0)
	_current_result.shots_fired = stats.get("shots_fired", 0)
	_current_result.shots_hit = stats.get("shots_hit", 0)
	_current_result.enemies_destroyed = stats.get("enemies_destroyed", 0)
	_current_result.player_bots_lost = stats.get("player_bots_lost", 0)
	_current_result._calculate_grade()
	
	_calculate_rewards()
	battle_ended.emit(_current_result)

func _calculate_rewards() -> void:
	if _current_result.result_type != BattleResult.ResultType.VICTORY:
		_base_credits = 0
		_bonus_credits = 0
	else:
		_base_credits = current_arena_data.get("reward_credits", 100)
		
		_bonus_credits = 0
		match _current_result.grade:
			"S": _bonus_credits = _base_credits
			"A": _bonus_credits = int(_base_credits * 0.5)
			"B": _bonus_credits = int(_base_credits * 0.25)
		
		if _current_result.time_seconds < 30.0:
			_bonus_credits += 50
		elif _current_result.time_seconds < 60.0:
			_bonus_credits += 25
	
	var rewards: Dictionary = {
		"credits": _base_credits + _bonus_credits,
		"base_credits": _base_credits,
		"bonus_credits": _bonus_credits,
		"grade": _current_result.grade,
		"result_type": _current_result.result_type,
		"entry_fee": current_arena_data.get("entry_fee", 0)
	}
	
	if _current_result.result_type == BattleResult.ResultType.VICTORY:
		_game_state.add_credits(rewards["credits"])
	
	rewards_calculated.emit(rewards)

func _on_bot_destroyed(bot: Node) -> void:
	if bot.team == 0:
		stats["player_bots_lost"] = stats.get("player_bots_lost", 0) + 1
	else:
		stats["enemies_destroyed"] = stats.get("enemies_destroyed", 0) + 1
	
	bot_destroyed.emit(bot, bot.team)
	_check_battle_end()

func _clear_teams() -> void:
	for bot in player_team:
		if is_instance_valid(bot):
			bot.queue_free()
	player_team.clear()
	
	for bot in enemy_team:
		if is_instance_valid(bot):
			bot.queue_free()
	enemy_team.clear()

func pause() -> void:
	if current_state == BattleState.ACTIVE:
		_change_state(BattleState.PAUSED)
		get_tree().paused = true

func resume() -> void:
	if current_state == BattleState.PAUSED:
		_change_state(BattleState.ACTIVE)
		get_tree().paused = false

func end_battle_early() -> void:
	if current_state == BattleState.ACTIVE or current_state == BattleState.COUNTDOWN:
		_end_battle(BattleResult.ResultType.DEFEAT)

func is_battle_active() -> bool:
	return current_state == BattleState.ACTIVE

func is_battle_ended() -> bool:
	return current_state == BattleState.ENDED

func get_current_arena() -> Dictionary:
	return current_arena_data

func get_battle_summary() -> Dictionary:
	return {
		"arena_name": current_arena_data.get("name", "Unknown"),
		"time": "%.1f" % battle_time,
		"time_remaining": "%.0f" % max(0.0, max_battle_time - battle_time),
		"player_alive": _count_alive(player_team),
		"player_total": player_team.size(),
		"enemy_alive": _count_alive(enemy_team),
		"enemy_total": enemy_team.size(),
		"commands_issued": stats.get("commands_issued", 0)
	}

func get_battle_stats() -> Dictionary:
	return {
		"time": battle_time,
		"time_formatted": "%d:%02d" % [int(battle_time) / 60, int(battle_time) % 60],
		"commands": player_commands_issued,
		"player_alive": _count_alive(player_team),
		"player_total": player_team.size(),
		"enemy_alive": _count_alive(enemy_team),
		"enemy_total": enemy_team.size(),
		"damage_dealt": stats.get("damage_dealt", 0),
		"damage_taken": stats.get("damage_taken", 0),
		"shots_fired": stats.get("shots_fired", 0),
		"shots_hit": stats.get("shots_hit", 0),
		"accuracy": (float(stats.get("shots_hit", 0)) / stats.get("shots_fired", 1) * 100.0) if stats.get("shots_fired", 0) > 0 else 0.0,
		"enemies_destroyed": stats.get("enemies_destroyed", 0),
		"player_bots_lost": stats.get("player_bots_lost", 0)
	}

func get_current_result() -> BattleResult:
	return _current_result

func get_time_remaining() -> float:
	if current_state != BattleState.ACTIVE:
		return 0.0
	return max(0.0, max_battle_time - battle_time)
