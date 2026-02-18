extends Node
## SimulationManager singleton — runs combat simulation in _physics_process.
## Owns bot/projectile/hazard arrays. Exposes start_battle(), issue_command().
## Signals for tick events and battle end. Can run headless.

const TICKS_PER_SECOND: float = 60.0
const DT: float = 1.0 / TICKS_PER_SECOND
const MAX_TICKS: int = 10800  # 3 minutes

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

# Pools
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

# Cached part data
var _part_data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(delta: float) -> void:
	if not is_running or is_paused:
		return
	
	# Run one simulation tick per physics frame
	_run_tick()
	
	# Debug: print bot states every 2 seconds
	if current_tick % 120 == 0:
		for bot_id in bots:
			var bot = bots[bot_id]
			if bot.is_alive:
				print("Bot ", bot_id, " pos:", bot.position, " target:", bot.target_id, " vel:", bot.velocity)


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
	_next_bot_id = 1
	_next_proj_id = 1
	
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
	
	print("Simulation started: arena=%s, bots=%d, seed=%d" % [
		arena_data.get("id", "unknown"), bots.size(), seed_val
	])


func stop_battle() -> void:
	is_running = false
	bots.clear()
	projectiles.clear()


func pause() -> void:
	is_paused = true


func resume() -> void:
	is_paused = false


func issue_command(bot_id: int, command_type: String, target: Variant) -> bool:
	## Queue a command for next tick processing
	if not bots.has(bot_id):
		return false
	
	var bot = bots[bot_id]
	if not bot.is_alive:
		return false
	
	if current_tick < bot.command_cooldown_until:
		return false  # On cooldown
	
	_pending_commands.append({
		"bot_id": bot_id,
		"type": command_type,
		"target": target,
		"issued_tick": current_tick
	})
	
	if not headless:
		command_issued.emit(bot_id, command_type, target)
	
	return true


func _run_tick() -> void:
	if current_tick >= MAX_TICKS:
		_resolve_stalemate()
		return
	
	current_tick += 1
	
	# STEP 1: Process commands
	_process_commands()
	
	# STEP 2: AI
	_process_ai()
	
	# STEP 3: Movement
	_process_movement()
	
	# STEP 4: Weapons
	_process_weapons()
	
	# STEP 5: Projectiles
	_process_projectiles()
	
	# STEP 6: Status effects
	_process_status_effects()
	
	# STEP 7: Regeneration
	_process_regeneration()
	
	# STEP 8: Destruction check
	_process_destruction()
	
	# STEP 9: Victory check
	_process_victory()
	
	if not headless:
		tick_processed.emit(current_tick)


func _process_commands() -> void:
	for cmd in _pending_commands:
		var bot_id: int = cmd["bot_id"]
		if not bots.has(bot_id):
			continue
		
		var bot = bots[bot_id]
		if not bot.is_alive:
			continue
		
		# Set command
		bot.command_type = cmd["type"]
		bot.command_target = cmd["target"]
		bot.command_expiry_tick = current_tick + _get_command_duration(cmd["type"])
		bot.command_cooldown_until = current_tick + 30  # 0.5s cooldown
	
	_pending_commands.clear()
	
	# Expire old commands
	for bot_id in bots:
		var bot = bots[bot_id]
		if bot.command_expiry_tick > 0 and current_tick >= bot.command_expiry_tick:
			bot.command_type = ""
			bot.command_target = null
			bot.command_expiry_tick = -1


func _get_command_duration(cmd_type: String) -> int:
	match cmd_type:
		"move": return 360  # 6 seconds (was 2)
		"follow": return 480  # 8 seconds
		"focus": return 480  # 8 seconds
	return 180


func _process_ai() -> void:
	# Sort bots by sim_id for determinism
	var bot_ids: Array = bots.keys()
	bot_ids.sort()
	
	for bot_id in bot_ids:
		var bot = bots[bot_id]
		if not bot.is_alive:
			continue
		
		# If has active command, handle it
		if bot.command_type != "":
			_process_command_behavior(bot)
			continue
		
		# Otherwise run AI
		_ai_select_target(bot)
		_ai_compute_movement(bot)


func _process_command_behavior(bot) -> void:
	match bot.command_type:
		"move":
			if bot.command_target is Vector2:
				_ai_move_to_position(bot, bot.command_target)
		"follow":
			if bot.command_target is int and bots.has(bot.command_target):
				_ai_follow_bot(bot, bots[bot.command_target])
		"focus":
			if bot.command_target is int and bots.has(bot.command_target):
				bot.target_id = bot.command_target
				_ai_compute_movement(bot)


func _ai_select_target(bot) -> void:
	var best_target: int = -1
	var best_score: float = -999999.0
	
	for other_id in bots:
		if other_id == bot.sim_id:
			continue
		var other = bots[other_id]
		if not other.is_alive:
			continue
		if other.team == bot.team:
			continue
		
		var dist: float = bot.position.distance_to(other.position)
		if dist > bot.detection_range:
			continue
		
		var score: float = _compute_target_score(bot, other, dist)
		if score > best_score:
			best_score = score
			best_target = other_id
	
	bot.target_id = best_target


func _compute_target_score(bot, target, distance: float) -> float:
	var profile: Dictionary = bot.ai_profile
	var max_range: float = bot.detection_range
	
	var w_dist: float = profile.get("w_dist", 0.3)
	var w_threat: float = profile.get("w_threat", 0.2)
	var w_hp: float = profile.get("w_hp", 0.2)
	var w_focus: float = profile.get("w_focus", 0.5)
	
	var dist_score: float = 1.0 - clamp(distance / max_range, 0.0, 1.0)
	var threat_score: float = clamp(target.compute_dps() / 100.0, 0.0, 1.0)
	var hp_score: float = 1.0 - clamp(float(target.hp) / float(target.max_hp), 0.0, 1.0)
	var focus_score: float = 1.0 if target.sim_id == bot.target_id else 0.0
	
	return w_dist * dist_score + w_threat * threat_score + w_hp * hp_score + w_focus * focus_score


func _ai_compute_movement(bot) -> void:
	var target_pos: Vector2 = Vector2.ZERO
	var has_target: bool = false
	
	if bot.target_id != -1 and bots.has(bot.target_id):
		var target = bots[bot.target_id]
		if target.is_alive:
			target_pos = target.position
			has_target = true
	
	if not has_target:
		# No target, idle or return to spawn
		bot.velocity = bot.velocity.move_toward(Vector2.ZERO, bot.current_accel * DT)
		return
	
	var to_target: Vector2 = target_pos - bot.position
	var dist: float = to_target.length()
	var dir: Vector2 = to_target.normalized()
	
	# Get preferred range from weapons
	var optimal_range: float = _get_optimal_range(bot)
	var profile: Dictionary = bot.ai_profile
	var preferred: String = profile.get("preferred_range", "medium")
	
	var desired_vel: Vector2 = Vector2.ZERO
	
	if preferred == "close":
		if dist > optimal_range * 0.5:
			desired_vel = dir * bot.current_speed
		else:
			desired_vel = Vector2.ZERO
	elif preferred == "far":
		if dist < optimal_range * 0.7:
			desired_vel = -dir * bot.current_speed  # Kite back
		elif dist > optimal_range:
			desired_vel = dir * bot.current_speed
		else:
			desired_vel = Vector2.ZERO
	else:  # medium
		if dist > optimal_range * 1.2:
			desired_vel = dir * bot.current_speed
		elif dist < optimal_range * 0.8:
			desired_vel = -dir * bot.current_speed
		else:
			# Strafe
			var strafe_dir: Vector2 = Vector2(-dir.y, dir.x)
			if bot.sim_id % 2 == 0:
				strafe_dir = -strafe_dir
			desired_vel = strafe_dir * bot.current_speed * 0.5
	
	# Apply acceleration
	bot.velocity = bot.velocity.move_toward(desired_vel, bot.current_accel * DT)
	
	# Update rotation - face target if has one, otherwise face movement direction
	var target_rot: float = bot.rotation
	if bot.target_id != -1 and bots.has(bot.target_id) and bots[bot.target_id].is_alive:
		var target = bots[bot.target_id]
		target_rot = rad_to_deg((target.position - bot.position).angle())
	elif bot.velocity.length() > 1.0:
		target_rot = rad_to_deg(bot.velocity.angle())
	
	bot.rotation = _lerp_angle_deg(bot.rotation, target_rot, bot.base_turn_rate * DT / 180.0)


func _ai_move_to_position(bot, target_pos: Vector2) -> void:
	var to_target: Vector2 = target_pos - bot.position
	var dist: float = to_target.length()
	
	if dist < 10.0:
		bot.velocity = Vector2.ZERO
		return
	
	var dir: Vector2 = to_target.normalized()
	var desired_vel: Vector2 = dir * bot.current_speed
	bot.velocity = bot.velocity.move_toward(desired_vel, bot.current_accel * DT)


func _ai_follow_bot(bot, target_bot) -> void:
	var target_pos: Vector2 = target_bot.position
	var to_target: Vector2 = target_pos - bot.position
	var dist: float = to_target.length()
	
	if dist < bot.radius * 2.5:
		bot.velocity = bot.velocity.move_toward(Vector2.ZERO, bot.current_accel * DT)
	else:
		var dir: Vector2 = to_target.normalized()
		var desired_vel: Vector2 = dir * bot.current_speed
		bot.velocity = bot.velocity.move_toward(desired_vel, bot.current_accel * DT)


func _get_optimal_range(bot) -> float:
	var range_sum: float = 0.0
	var count: int = 0
	for w in bot.weapons:
		var wpn_data: Dictionary = w["data"]
		var stats: Dictionary = wpn_data.get("stats", {})
		range_sum += stats.get("range_optimal", 100.0)
		count += 1
	return range_sum / maxi(count, 1)


func _process_movement() -> void:
	var bot_ids: Array = bots.keys()
	bot_ids.sort()
	
	for bot_id in bot_ids:
		var bot = bots[bot_id]
		if not bot.is_alive:
			continue
		
		# Update position
		bot.position += bot.velocity * DT
		
		# Clamp to arena
		bot.position.x = clamp(bot.position.x, bot.radius, arena_size.x - bot.radius)
		bot.position.y = clamp(bot.position.y, bot.radius, arena_size.y - bot.radius)
		
		if not headless:
			entity_moved.emit(bot.sim_id, bot.position, bot.rotation)
	
	# Simple bot-bot collision (push apart)
	_resolve_bot_collisions()


func _resolve_bot_collisions() -> void:
	var bot_list: Array = bots.values()
	for i in range(bot_list.size()):
		for j in range(i + 1, bot_list.size()):
			var bot_a = bot_list[i]
			var bot_b = bot_list[j]
			if not bot_a.is_alive or not bot_b.is_alive:
				continue
			
			var dist_sq: float = bot_a.position.distance_squared_to(bot_b.position)
			var min_dist: float = bot_a.radius + bot_b.radius
			
			if dist_sq < min_dist * min_dist and dist_sq > 0.001:
				var dist: float = sqrt(dist_sq)
				var overlap: float = min_dist - dist
				var push_dir: Vector2 = (bot_a.position - bot_b.position).normalized()
				
				bot_a.position += push_dir * overlap * 0.5
				bot_b.position -= push_dir * overlap * 0.5


func _lerp_angle_deg(from: float, to: float, weight: float) -> float:
	var diff: float = fmod(to - from + 540.0, 360.0) - 180.0
	return from + diff * weight


func _process_weapons() -> void:
	var bot_ids: Array = bots.keys()
	bot_ids.sort()
	
	for bot_id in bot_ids:
		var bot = bots[bot_id]
		if not bot.is_alive:
			continue
		
		var stats = bot.get_effective_stats()
		if not stats["can_fire"]:
			continue
		
		for w in bot.weapons:
			if w["overheated"]:
				continue
			if current_tick < w["next_fire_tick"]:
				continue
			
			var wpn_data: Dictionary = w["data"]
			var wpn_stats: Dictionary = wpn_data.get("stats", {})
			
			# Check heat
			var heat_threshold: float = wpn_stats.get("overheat_threshold", 40.0)
			if w["heat"] >= heat_threshold:
				w["overheated"] = true
				continue
			
			# Check target in range
			if bot.target_id == -1 or not bots.has(bot.target_id):
				continue
			
			var target = bots[bot.target_id]
			if not target.is_alive:
				continue
			
			var dist: float = bot.position.distance_to(target.position)
			var range_max: float = wpn_stats.get("range_max", 100.0)
			var range_min: float = wpn_stats.get("range_min", 0.0)
			
			if dist < range_min or dist > range_max:
				continue
			
			# Fire!
			_fire_weapon(bot, w, target)
	
	# Dissipate heat
	for bot_id in bots:
		var bot = bots[bot_id]
		for w in bot.weapons:
			var wpn_data: Dictionary = w["data"]
			var wpn_stats: Dictionary = wpn_data.get("stats", {})
			var dissipation: float = wpn_stats.get("heat_dissipation_per_tick", 0.3)
			
			w["heat"] = maxf(0.0, w["heat"] - dissipation)
			
			if w["overheated"] and w["heat"] <= wpn_stats.get("overheat_threshold", 40.0) * 0.5:
				w["overheated"] = false


func _fire_weapon(bot, weapon_slot, target) -> void:
	var wpn_data: Dictionary = weapon_slot["data"]
	var wpn_stats: Dictionary = wpn_data.get("stats", {})
	
	var fire_rate: float = wpn_stats.get("fire_rate", 1.0)
	var cooldown_ticks: int = maxi(1, roundi(1.0 / fire_rate * TICKS_PER_SECOND))
	weapon_slot["next_fire_tick"] = current_tick + cooldown_ticks
	
	var heat_per_shot: float = wpn_stats.get("heat_per_shot", 2.0)
	weapon_slot["heat"] += heat_per_shot
	
	var proj_type: String = wpn_stats.get("projectile_type", "ballistic")
	
	if proj_type == "beam":
		# Instant hit
		_resolve_beam_hit(bot, target, wpn_data)
	else:
		# Spawn projectile
		var direction: Vector2 = (target.position - bot.position).normalized()
		_spawn_projectile(bot, direction, wpn_data)


func _resolve_beam_hit(bot, target, wpn_data) -> void:
	var wpn_stats: Dictionary = wpn_data.get("stats", {})
	var damage: float = wpn_stats.get("damage_per_shot", 10.0)
	
	# Apply resistances
	var resistance: float = target.get("resist_energy", 0.0)
	damage *= (1.0 - clamp(resistance, 0.0, 0.9))
	
	_apply_damage(target, int(damage), bot.sim_id)


func _spawn_projectile(bot, direction: Vector2, wpn_data: Dictionary) -> void:
	var proj = preload("res://src/entities/projectile.gd").new(
		_next_proj_id, bot.team, bot.sim_id, bot.position, direction, wpn_data
	)
	proj.spawn_tick = current_tick
	projectiles[_next_proj_id] = proj
	_next_proj_id += 1
	
	if not headless:
		projectile_spawned.emit(proj.proj_id, proj.position, direction)


func _process_projectiles() -> void:
	var to_destroy: Array[int] = []
	
	# Sort for determinism
	var proj_list: Array = projectiles.values()
	proj_list.sort_custom(func(a, b): return a.spawn_tick < b.spawn_tick if a.spawn_tick != b.spawn_tick else a.proj_id < b.proj_id)
	
	for proj in proj_list:
		if not proj.is_active:
			to_destroy.append(proj.proj_id)
			continue
		
		# Update position (returns true if max range reached)
		if proj.update():
			to_destroy.append(proj.proj_id)
			continue
		
		# Check out of bounds
		if proj.check_out_of_bounds(arena_size):
			to_destroy.append(proj.proj_id)
			continue
		
		# Check collisions with bots
		var hit: bool = false
		for bot_id in bots:
			var bot = bots[bot_id]
			if not bot.is_alive:
				continue
			if bot.team == proj.team:
				continue
			
			if proj.check_collision({"position": bot.position, "radius": bot.radius, "team": bot.team}):
				var result: Dictionary = proj.resolve_hit({
					"position": bot.position,
					"radius": bot.radius,
					"team": bot.team,
					"resist_ballistic": 0.0,
					"resist_energy": 0.0,
					"resist_explosive": 0.0
				}, rng._rng)
				
				if result["hit"]:
					_apply_damage(bot, result["damage"], proj.source_bot_id)
					for effect in result["effects"]:
						bot.apply_status_effect(effect)
				
				hit = true
				break
		
		if hit:
			to_destroy.append(proj.proj_id)
	
	# Destroy projectiles
	for proj_id in to_destroy:
		if projectiles.has(proj_id):
			projectiles.erase(proj_id)
			if not headless:
				projectile_destroyed.emit(proj_id)


func _apply_damage(bot, damage: int, source_id: int) -> void:
	if damage <= 0:
		return
	
	bot.take_damage(damage)
	
	if not headless:
		entity_damaged.emit(bot.sim_id, bot.hp, bot.max_hp)
		
		if not bot.is_alive:
			entity_destroyed.emit(bot.sim_id, bot.team)


func _process_status_effects() -> void:
	for bot_id in bots:
		var bot = bots[bot_id]
		if bot.is_alive:
			bot.update_status_effects(current_tick)


func _process_regeneration() -> void:
	# Simplified — would check for repair modules
	pass


func _process_destruction() -> void:
	# Already handled in _apply_damage
	pass


func _process_victory() -> void:
	var player_alive: int = 0
	var enemy_alive: int = 0
	
	for bot_id in bots:
		var bot = bots[bot_id]
		if bot.is_alive:
			if bot.team == 0:
				player_alive += 1
			else:
				enemy_alive += 1
	
	if enemy_alive == 0:
		_end_battle("PLAYER_WIN")
	elif player_alive == 0:
		_end_battle("PLAYER_LOSS")


func _resolve_stalemate() -> void:
	var player_hp_pct: float = 0.0
	var enemy_hp_pct: float = 0.0
	var player_count: int = 0
	var enemy_count: int = 0
	
	for bot_id in bots:
		var bot = bots[bot_id]
		var hp_pct: float = float(bot.hp) / float(bot.max_hp)
		if bot.team == 0:
			player_hp_pct += hp_pct
			player_count += 1
		else:
			enemy_hp_pct += hp_pct
			enemy_count += 1
	
	if player_count > 0:
		player_hp_pct /= player_count
	if enemy_count > 0:
		enemy_hp_pct /= enemy_count
	
	if player_hp_pct > enemy_hp_pct:
		_end_battle("PLAYER_WIN")
	else:
		_end_battle("PLAYER_LOSS")


func _end_battle(result: String) -> void:
	is_running = false
	print("Battle ended: %s at tick %d" % [result, current_tick])
	
	if not headless:
		battle_ended.emit(result, current_tick)


func _load_part_data() -> void:
	if DataLoader and DataLoader.has_method("get_core"):
		var core = DataLoader.get_core()
		if core and core.has_method("get_part"):
			_part_data = {}
			for part in core.get_all_parts():
				if part is Dictionary and part.has("id"):
					_part_data[part["id"]] = part


func _setup_arena(arena_data: Dictionary) -> void:
	var size: Dictionary = arena_data.get("size", {"width": 800, "height": 600})
	arena_size = Vector2(size.get("width", 800), size.get("height", 600))
	
	obstacles.clear()
	var loaded_obstacles: Array = arena_data.get("obstacles", [])
	for obs in loaded_obstacles:
		if obs is Dictionary:
			obstacles.append(obs)
	
	player_spawn_points.clear()
	for sp in arena_data.get("spawn_points_player", []):
		player_spawn_points.append(Vector2(sp.get("x", 100), sp.get("y", 300)))
	
	enemy_spawn_points.clear()
	for sp in arena_data.get("spawn_points_enemy", []):
		enemy_spawn_points.append(Vector2(sp.get("x", 700), sp.get("y", 300)))


func _spawn_team(loadouts: Array, team: int, spawn_points: Array[Vector2]) -> void:
	for i in range(loadouts.size()):
		if i >= spawn_points.size():
			push_warning("Not enough spawn points for team %d" % team)
			break
		
		var loadout: Dictionary = loadouts[i]
		var bot = preload("res://src/entities/bot.gd").new(_next_bot_id, team, spawn_points[i])
		bot.setup_from_loadout(loadout, _part_data)
		bots[_next_bot_id] = bot
		_next_bot_id += 1
		
		if not headless:
			entity_moved.emit(bot.sim_id, bot.position, bot.rotation)


# --- Debug / Utility ---

func get_battle_state() -> Dictionary:
	return {
		"tick": current_tick,
		"bots": bots.size(),
		"projectiles": projectiles.size(),
		"running": is_running
	}
