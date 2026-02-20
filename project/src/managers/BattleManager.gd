extends Node2D
class_name BattleManager
## Manages combat simulation: spawning, updates, win/loss

# Arena and teams
var arena_data: Dictionary = {}
var player_team: Array = []
var enemy_team: Array = []

# Battle state
enum BattleState { SETUP, ACTIVE, PAUSED, VICTORY, DEFEAT }
var state: BattleState = BattleState.SETUP

# Battle tracking
var battle_time: float = 0.0
var player_commands_issued: int = 0
var stats: Dictionary = {}

# Signals
signal battle_started
signal battle_ended(result: String)  # "victory" or "defeat"
signal bot_spawned(bot: Bot, team: int)
signal bot_destroyed(bot: Bot, team: int)


func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE


## Initialize battle with arena and team configs
func setup_battle(arena_id: String, player_configs: Array, enemy_configs: Array) -> bool:
	arena_data = DataLoader.get_arena(arena_id)
	if arena_data.is_empty():
		push_error("BattleManager: Invalid arena ID: %s" % arena_id)
		return false
	
	# Clear existing
	_clear_teams()
	
	# Spawn player team
	for config in player_configs:
		var bot = _spawn_bot(config, 0)
		if bot:
			player_team.append(bot)
	
	# Spawn enemy team
	for config in enemy_configs:
		var bot = _spawn_bot(config, 1)
		if bot:
			enemy_team.append(bot)
	
	state = BattleState.SETUP
	return true


## Spawn a single bot
func _spawn_bot(config: Dictionary, team_id: int) -> Bot:
	var bot = Bot.new()
	var success = bot.build(
		config.get("chassis", ""),
		config.get("plating", ""),
		config.get("weapon", "")
	)
	
	if not success:
		bot.queue_free()
		return null
	
	bot.team = team_id
	bot.bot_destroyed.connect(_on_bot_destroyed)
	
	# Position bot (simplified spawn logic)
	var spawn_pos = _get_spawn_position(team_id, player_team.size() if team_id == 0 else enemy_team.size())
	bot.global_position = spawn_pos
	
	add_child(bot)
	bot_spawned.emit(bot, team_id)
	
	return bot


## Get spawn position
func _get_spawn_position(team: int, index: int) -> Vector2:
	var dims = arena_data.get("dimensions", [600, 400])
	var width = dims[0]
	var height = dims[1]
	
	if team == 0:
		return Vector2(100 + index * 50, height / 2)
	else:
		return Vector2(width - 100 - index * 50, height / 2)


## Start the battle
func start_battle() -> void:
	if state != BattleState.SETUP:
		return
	
	state = BattleState.ACTIVE
	battle_time = 0.0
	player_commands_issued = 0
	stats = {"damage_dealt": 0, "damage_taken": 0, "shots_fired": 0, "shots_hit": 0}
	
	battle_started.emit()


## Main battle loop
func _physics_process(delta: float) -> void:
	if state != BattleState.ACTIVE:
		return
	
	battle_time += delta
	
	# Update all bots
	for bot in player_team:
		if bot.state != Bot.State.DESTROYED:
			_update_bot(bot, delta)
	
	for bot in enemy_team:
		if bot.state != Bot.State.DESTROYED:
			_update_bot(bot, delta)
	
	# Check win/loss conditions
	_check_battle_end()


## Update single bot
func _update_bot(bot: Bot, delta: float) -> void:
	# AI evaluation for enemy bots
	if bot.team == 1 and bot.has_node("AI"):
		var ai = bot.get_node("AI") as BotAI
		ai.evaluate(delta)
	
	# Track bot's internal process
	bot._physics_process(delta)


## Check for battle end conditions
func _check_battle_end() -> void:
	var player_alive = _count_alive(player_team)
	var enemy_alive = _count_alive(enemy_team)
	
	if enemy_alive == 0:
		_end_battle("victory")
	elif player_alive == 0:
		_end_battle("defeat")


## Count alive bots
func _count_alive(team: Array) -> int:
	var count = 0
	for bot in team:
		if bot.state != Bot.State.DESTROYED:
			count += 1
	return count


## End battle with result
func _end_battle(result: String) -> void:
	state = BattleState.VICTORY if result == "victory" else BattleState.DEFEAT
	battle_ended.emit(result)


## Handle bot destruction
func _on_bot_destroyed(bot: Bot) -> void:
	bot_destroyed.emit(bot, bot.team)


## Clear all teams
func _clear_teams() -> void:
	for bot in player_team:
		bot.queue_free()
	player_team.clear()
	
	for bot in enemy_team:
		bot.queue_free()
	enemy_team.clear()


## Issue move command to player bot
func command_move(bot_index: int, position: Vector2) -> void:
	if state != BattleState.ACTIVE:
		return
	
	if bot_index < 0 or bot_index >= player_team.size():
		return
	
	var bot = player_team[bot_index]
	if bot.state != Bot.State.DESTROYED:
		bot.move_to(position)
		player_commands_issued += 1


## Issue attack command to player bot
func command_attack(bot_index: int, target: Bot) -> void:
	if state != BattleState.ACTIVE:
		return
	
	if bot_index < 0 or bot_index >= player_team.size():
		return
	
	var bot = player_team[bot_index]
	if bot.state != Bot.State.DESTROYED:
		bot.attack(target)
		player_commands_issued += 1


## Pause/unpause battle
func pause() -> void:
	if state == BattleState.ACTIVE:
		state = BattleState.PAUSED
		get_tree().paused = true

func resume() -> void:
	if state == BattleState.PAUSED:
		state = BattleState.ACTIVE
		get_tree().paused = false


## Get battle stats for results screen
func get_battle_stats() -> Dictionary:
	return {
		"time": battle_time,
		"commands": player_commands_issued,
		"player_alive": _count_alive(player_team),
		"player_total": player_team.size(),
		"enemy_alive": _count_alive(enemy_team),
		"enemy_total": enemy_team.size()
	}
