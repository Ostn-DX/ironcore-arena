extends RefCounted
class_name WeaponSystem
## WeaponSystem - ECS-style system called per-tick by SimulationManager.
## Handles: cooldown, heat, firing, projectile spawning, AOE splash, crits, burst fire.
## Returns event arrays (no signals in hot path). Fully deterministic.

const TIMESTEP: float = 1.0 / 60.0
const MAX_PROJECTILES: int = 500
const MAX_DAMAGE: float = 9999.0

# Projectile ID counter -- SimulationManager may reset this between battles
var _next_proj_id: int = 1

# Pre-allocated arrays reused each tick to reduce GC pressure
var _events: Array = []
var _dead_set: Dictionary = {}  # index -> true, O(1) lookup instead of Array.has()

# WeaponData cache: avoid re-creating WeaponData from dict every hit
var _wd_cache: Dictionary = {}  # weapon_id (String) -> WeaponData


func process_tick(bots: Array, projectiles: Array, rng: DeterministicRng,
		tick: int, dt: float, arena_bounds: Rect2) -> Array:
	## Main per-tick entry point. Returns array of event dictionaries.
	## bots: Array of bot Dictionaries/Objects sorted by sim_id
	## projectiles: mutable Array -- we append new and remove dead projectiles
	_events.clear()
	_dead_set.clear()

	# --- Phase 1: Cooldown and heat dissipation ---
	for bot in bots:
		if not _is_bot_alive(bot):
			continue
		_update_heat_and_cooldowns(bot, tick)

	# --- Phase 2: Fire resolution (spawn projectiles) ---
	for bot in bots:
		if not _is_bot_alive(bot):
			continue
		if _is_bot_stunned(bot):
			continue
		_try_fire_weapons(bot, bots, projectiles, rng, tick)

	# --- Phase 3: Update projectiles (move ballistics, instant beam/melee already resolved) ---
	var proj_size: int = projectiles.size()
	for i in range(proj_size):
		var proj: Dictionary = projectiles[i]
		if not proj.get("active", true):
			_dead_set[i] = true
			continue
		var ptype: String = proj.get("projectile_type", "ballistic")
		if ptype == "ballistic" or ptype == "aoe":
			_move_projectile(proj, dt)
			# Out of bounds check
			if _is_out_of_bounds(proj, arena_bounds):
				proj["active"] = false
				_dead_set[i] = true
				_events.append({"type": "projectile_expired", "proj_id": proj.get("proj_id", -1), "tick": tick})
				continue
			# Max range check
			if proj.get("distance_traveled", 0.0) >= proj.get("max_range", 9999.0):
				# AOE projectiles explode at max range
				if ptype == "aoe":
					_resolve_aoe_impact(proj, bots, rng, tick)
				proj["active"] = false
				_dead_set[i] = true
				_events.append({"type": "projectile_expired", "proj_id": proj.get("proj_id", -1), "tick": tick})
				continue

	# --- Phase 4: Hit detection (circle-circle, iterate bots by sim_id) ---
	for i in range(proj_size):
		if _dead_set.has(i):
			continue
		var proj: Dictionary = projectiles[i]
		if not proj.get("active", true):
			continue
		var ptype: String = proj.get("projectile_type", "ballistic")
		if ptype == "beam" or ptype == "melee":
			continue  # Already resolved on fire

		var proj_team: int = proj.get("team", -1)
		var proj_source: int = proj.get("source_bot_id", -1)

		for bot in bots:
			if not _is_bot_alive(bot):
				continue
			if _get_int_prop(bot, "team", -1) == proj_team:
				continue  # No friendly fire
			if _get_int_prop(bot, "sim_id", -1) == proj_source:
				continue

			if _check_collision(proj, bot):
				_resolve_projectile_hit(proj, bot, bots, rng, tick)
				proj["active"] = false
				_dead_set[i] = true
				break  # One hit per projectile

	# --- Phase 5: Cleanup dead projectiles (reverse order to keep indices valid) ---
	var dead_keys: Array = _dead_set.keys()
	dead_keys.sort()
	for idx in range(dead_keys.size() - 1, -1, -1):
		var di: int = dead_keys[idx]
		if di < projectiles.size():
			projectiles.remove_at(di)

	return _events


# ============================================================================
# HEAT AND COOLDOWN
# ============================================================================

func _update_heat_and_cooldowns(bot, tick: int) -> void:
	var weapons: Array = bot.get("weapons") if bot is Dictionary else bot.weapons
	for w in weapons:
		# Heat dissipation
		var weapon_data = _get_weapon_data(w)
		var dissipation: float = _get_float(weapon_data, "heat_dissipation_per_tick", 0.3)
		var current_heat: float = w.get("heat", 0.0)
		current_heat = maxf(0.0, current_heat - dissipation)
		w["heat"] = current_heat

		# Overheat recovery
		if w.get("overheated", false):
			# Check if overheat lockout period has passed
			var lockout_end: int = w.get("overheat_end_tick", 0)
			if tick >= lockout_end and current_heat <= 0.0:
				w["overheated"] = false

		# Burst tracking: advance burst fire within a burst sequence
		if w.get("burst_remaining", 0) > 0:
			var burst_delay: int = _get_int(weapon_data, "burst_delay_ticks", 0)
			if burst_delay == 0 or tick >= w.get("next_burst_tick", 0):
				w["burst_ready"] = true


# ============================================================================
# FIRING
# ============================================================================

func _try_fire_weapons(bot, all_bots: Array, projectiles: Array,
		rng: DeterministicRng, tick: int) -> void:
	var bot_pos: Vector2 = _get_position(bot)
	var bot_team: int = _get_int_prop(bot, "team", 0)
	var bot_id: int = _get_int_prop(bot, "sim_id", -1)
	var target_id: int = _get_int_prop(bot, "target_id", -1)

	# Find target bot
	var target = null
	if target_id >= 0:
		for b in all_bots:
			if _get_int_prop(b, "sim_id", -1) == target_id and _is_bot_alive(b):
				target = b
				break

	if target == null:
		return

	var target_pos: Vector2 = _get_position(target)
	var distance: float = bot_pos.distance_to(target_pos)
	var direction: Vector2 = (target_pos - bot_pos).normalized() if distance > 0.001 else Vector2.RIGHT

	var weapons: Array = bot.get("weapons") if bot is Dictionary else bot.weapons

	for w in weapons:
		var weapon_data = _get_weapon_data(w)
		if weapon_data == null:
			continue

		# Check weapon can fire
		if w.get("overheated", false):
			continue
		if tick < w.get("next_fire_tick", 0):
			continue
		# Burst: if mid-burst, check burst readiness
		if w.get("burst_remaining", 0) > 0 and not w.get("burst_ready", false):
			continue

		# Range check
		var range_max_val: float = _get_float(weapon_data, "range_max", 200.0)
		if distance > range_max_val:
			continue

		# Projectile cap
		if projectiles.size() >= MAX_PROJECTILES:
			continue

		# Resolve burst
		var burst_count: int = _get_int(weapon_data, "burst_count", 1)
		var is_new_burst: bool = w.get("burst_remaining", 0) <= 0

		if is_new_burst:
			w["burst_remaining"] = burst_count

		# Fire one shot of the burst (appends directly to _events)
		_fire_shot(bot, target, w, weapon_data, direction,
				distance, all_bots, projectiles, rng, tick)

		# Advance burst state
		w["burst_remaining"] = w.get("burst_remaining", 1) - 1
		w["burst_ready"] = false

		if w.get("burst_remaining", 0) <= 0:
			# Burst complete: set cooldown for next burst
			var cooldown: int = _get_int(weapon_data, "cooldown_ticks", 20)
			if cooldown <= 0:
				var fire_rate_val: float = _get_float(weapon_data, "fire_rate", 1.0)
				cooldown = int(roundf(60.0 / fire_rate_val)) if fire_rate_val > 0.0 else 9999
			w["next_fire_tick"] = tick + cooldown
		else:
			# More shots in burst: set burst delay
			var burst_delay: int = _get_int(weapon_data, "burst_delay_ticks", 0)
			w["next_burst_tick"] = tick + burst_delay

		# Heat accumulation
		var heat_per: float = _get_float(weapon_data, "heat_per_shot", 2.0)
		w["heat"] = w.get("heat", 0.0) + heat_per
		var threshold: float = _get_float(weapon_data, "overheat_threshold", 40.0)
		if w["heat"] >= threshold:
			w["overheated"] = true
			var lockout: int = _get_int(weapon_data, "overheat_lockout_ticks", 120)
			w["overheat_end_tick"] = tick + lockout


func _fire_shot(bot, target, w: Dictionary, weapon_data, shot_dir: Vector2,
		distance: float, all_bots: Array, projectiles: Array,
		rng: DeterministicRng, tick: int) -> void:
	var bot_pos: Vector2 = _get_position(bot)
	var bot_id: int = _get_int_prop(bot, "sim_id", -1)
	var bot_team: int = _get_int_prop(bot, "team", 0)
	var weapon_id: String = w.get("part_id", "")
	var ptype: String = _get_str(weapon_data, "projectile_type", "ballistic")

	# Apply spread angle
	var spread: float = _get_float(weapon_data, "spread_angle", 0.0)
	var actual_dir: Vector2 = shot_dir
	if spread > 0.0:
		var half_spread: float = deg_to_rad(spread * 0.5)
		var angle_offset: float = rng.next_float_range(-half_spread, half_spread)
		actual_dir = shot_dir.rotated(angle_offset)

	_events.append({
		"type": "shot_fired",
		"bot_id": bot_id,
		"weapon_id": weapon_id,
		"tick": tick,
		"projectile_type": ptype,
	})

	# Build weapon data for combat resolver (cached)
	var wd: WeaponData = _ensure_weapon_data_cached(weapon_data, weapon_id)

	if ptype == "beam" or ptype == "melee":
		# Instant resolution -- no projectile entity
		var target_dict: Dictionary = _bot_to_dict(target)
		var hit_result: Dictionary = CombatResolver.resolve_hit(wd, target_dict, distance, rng)

		if hit_result.get("hit", false):
			_events.append({
				"type": "hit",
				"source_id": bot_id,
				"target_id": hit_result.get("target_id", -1),
				"damage": hit_result.get("damage", 0.0),
				"damage_type": hit_result.get("type", ""),
				"crit": hit_result.get("crit", false),
				"weapon_id": weapon_id,
				"tick": tick,
			})
			# Apply damage to bot
			_apply_damage(target, hit_result.get("damage", 0.0))
			# Apply status effects
			if hit_result.has("applied_effects"):
				_apply_status_effects(target, hit_result["applied_effects"], tick)
			# Check kill
			if not _is_bot_alive(target):
				_events.append({
					"type": "kill",
					"source_id": bot_id,
					"target_id": hit_result.get("target_id", -1),
					"weapon_id": weapon_id,
					"tick": tick,
				})

		# Beam with splash (e.g. Arc Disruptor) -- chain to nearby targets
		if wd.splash_radius > 0.0 and ptype == "beam":
			var target_pos: Vector2 = _get_position(target)
			var splash_targets: Array = _collect_splash_targets(all_bots, target_pos, bot_id)
			var splash_results: Array = CombatResolver.resolve_splash(wd, target_pos, splash_targets, bot_id, rng)
			for se in splash_results:
				_events.append({
					"type": "hit",
					"source_id": bot_id,
					"target_id": se.get("target_id", -1),
					"damage": se.get("damage", 0.0),
					"damage_type": se.get("type", ""),
					"crit": false,
					"weapon_id": weapon_id,
					"tick": tick,
					"splash": true,
				})
				var splash_target = _find_bot_by_id(all_bots, se.get("target_id", -1))
				if splash_target != null:
					_apply_damage(splash_target, se.get("damage", 0.0))
					if se.has("applied_effects"):
						_apply_status_effects(splash_target, se["applied_effects"], tick)
					if not _is_bot_alive(splash_target):
						_events.append({
							"type": "kill",
							"source_id": bot_id,
							"target_id": se.get("target_id", -1),
							"weapon_id": weapon_id,
							"tick": tick,
						})
	else:
		# Ballistic / AOE: spawn projectile entity
		var proj: Dictionary = {
			"proj_id": _next_proj_id,
			"team": bot_team,
			"source_bot_id": bot_id,
			"weapon_id": weapon_id,
			"position": bot_pos,
			"direction": actual_dir,
			"speed": _get_float(weapon_data, "projectile_speed", 400.0),
			"radius": _get_float(weapon_data, "projectile_radius", 4.0),
			"max_range": _get_float(weapon_data, "range_max", 200.0),
			"distance_traveled": 0.0,
			"spawn_tick": tick,
			"active": true,
			"projectile_type": ptype,
			"weapon_data": weapon_data,
		}
		_next_proj_id += 1
		projectiles.append(proj)

		_events.append({
			"type": "projectile_spawned",
			"proj_id": proj["proj_id"],
			"position": bot_pos,
			"direction": actual_dir,
			"tick": tick,
		})


# ============================================================================
# PROJECTILE MOVEMENT AND COLLISION
# ============================================================================

func _move_projectile(proj: Dictionary, dt: float) -> void:
	var speed: float = proj.get("speed", 0.0)
	var dir: Vector2 = proj.get("direction", Vector2.RIGHT)
	var move_dist: float = speed * dt
	proj["position"] = proj.get("position", Vector2.ZERO) + dir * move_dist
	proj["distance_traveled"] = proj.get("distance_traveled", 0.0) + move_dist


func _check_collision(proj: Dictionary, bot) -> bool:
	var proj_pos: Vector2 = proj.get("position", Vector2.ZERO)
	var proj_radius: float = proj.get("radius", 4.0)
	var bot_pos: Vector2 = _get_position(bot)
	var bot_radius: float = _get_float_prop(bot, "radius", 20.0)
	var combined: float = proj_radius + bot_radius
	return proj_pos.distance_squared_to(bot_pos) <= combined * combined


func _is_out_of_bounds(proj: Dictionary, bounds: Rect2) -> bool:
	var pos: Vector2 = proj.get("position", Vector2.ZERO)
	return not bounds.has_point(pos)


# ============================================================================
# HIT RESOLUTION
# ============================================================================

func _resolve_projectile_hit(proj: Dictionary, target, all_bots: Array,
		rng: DeterministicRng, tick: int) -> void:
	var source_id: int = proj.get("source_bot_id", -1)
	var weapon_id: String = proj.get("weapon_id", "")
	var weapon_data = proj.get("weapon_data", {})
	var wd: WeaponData = _ensure_weapon_data_cached(weapon_data, weapon_id)
	var distance: float = proj.get("distance_traveled", 0.0)

	var target_dict: Dictionary = _bot_to_dict(target)
	var hit_result: Dictionary = CombatResolver.resolve_hit(wd, target_dict, distance, rng)

	if hit_result.get("hit", false):
		_events.append({
			"type": "hit",
			"source_id": source_id,
			"target_id": hit_result.get("target_id", -1),
			"damage": hit_result.get("damage", 0.0),
			"damage_type": hit_result.get("type", ""),
			"crit": hit_result.get("crit", false),
			"weapon_id": weapon_id,
			"tick": tick,
		})
		_apply_damage(target, hit_result.get("damage", 0.0))
		if hit_result.has("applied_effects"):
			_apply_status_effects(target, hit_result["applied_effects"], tick)
		if not _is_bot_alive(target):
			_events.append({
				"type": "kill",
				"source_id": source_id,
				"target_id": hit_result.get("target_id", -1),
				"weapon_id": weapon_id,
				"tick": tick,
			})

	# AOE splash on hit
	if proj.get("projectile_type", "") == "aoe" and wd.splash_radius > 0.0:
		_resolve_aoe_impact(proj, all_bots, rng, tick)


func _resolve_aoe_impact(proj: Dictionary, all_bots: Array,
		rng: DeterministicRng, tick: int) -> void:
	var weapon_data = proj.get("weapon_data", {})
	var weapon_id: String = proj.get("weapon_id", "")
	var wd: WeaponData = _ensure_weapon_data_cached(weapon_data, weapon_id)
	var source_id: int = proj.get("source_bot_id", -1)
	var impact_pos: Vector2 = proj.get("position", Vector2.ZERO)

	var splash_targets: Array = _collect_splash_targets(all_bots, impact_pos, source_id)
	var splash_results: Array = CombatResolver.resolve_splash(wd, impact_pos, splash_targets, source_id, rng)

	for se in splash_results:
		_events.append({
			"type": "hit",
			"source_id": source_id,
			"target_id": se.get("target_id", -1),
			"damage": se.get("damage", 0.0),
			"damage_type": se.get("type", ""),
			"crit": false,
			"weapon_id": weapon_id,
			"tick": tick,
			"splash": true,
		})
		var splash_target = _find_bot_by_id(all_bots, se.get("target_id", -1))
		if splash_target != null:
			_apply_damage(splash_target, se.get("damage", 0.0))
			if se.has("applied_effects"):
				_apply_status_effects(splash_target, se["applied_effects"], tick)
			if not _is_bot_alive(splash_target):
				_events.append({
					"type": "kill",
					"source_id": source_id,
					"target_id": se.get("target_id", -1),
					"weapon_id": weapon_id,
					"tick": tick,
				})


# ============================================================================
# HELPERS -- bot abstraction (works with both Dictionary and Object bots)
# ============================================================================

func _is_bot_alive(bot) -> bool:
	if bot is Dictionary:
		return bot.get("is_alive", true) and bot.get("hp", 0) > 0
	return bot.is_alive and bot.hp > 0


func _is_bot_stunned(bot) -> bool:
	var effects: Array = []
	if bot is Dictionary:
		effects = bot.get("status_effects", [])
	else:
		effects = bot.status_effects
	for e in effects:
		if e.get("type", "") == "stun":
			return true
	return false


func _get_position(bot) -> Vector2:
	if bot is Dictionary:
		return bot.get("position", Vector2.ZERO)
	return bot.position


func _get_int_prop(bot, key: String, default: int) -> int:
	if bot is Dictionary:
		return int(bot.get(key, default))
	return int(bot.get(key)) if bot.get(key) != null else default


func _get_float_prop(bot, key: String, default: float) -> float:
	if bot is Dictionary:
		return float(bot.get(key, default))
	return float(bot.get(key)) if bot.get(key) != null else default


func _get_weapon_data(w: Dictionary):
	## Extract the weapon data sub-dictionary or WeaponData resource from a weapon slot.
	var d = w.get("data", null)
	if d != null:
		return d
	return w


func _ensure_weapon_data(weapon_data) -> WeaponData:
	## Convert raw dict weapon data to WeaponData resource if needed.
	if weapon_data is WeaponData:
		return weapon_data
	if weapon_data is Dictionary:
		# May be nested under "stats" key (legacy parts_slice format)
		var d: Dictionary = weapon_data
		if d.has("stats") and d.get("category", "") == "weapon":
			# Flatten stats into top-level for from_dict
			var flat: Dictionary = d.duplicate()
			var stats: Dictionary = d["stats"]
			for key in stats:
				flat[key] = stats[key]
			return WeaponData.from_dict(flat)
		return WeaponData.from_dict(d)
	return WeaponData.new()


func _ensure_weapon_data_cached(weapon_data, cache_key: String) -> WeaponData:
	## Cached version: avoids re-creating WeaponData from dict every hit.
	## Falls back to _ensure_weapon_data for first access, then caches result.
	if weapon_data is WeaponData:
		return weapon_data
	if cache_key != "" and _wd_cache.has(cache_key):
		return _wd_cache[cache_key]
	var wd: WeaponData = _ensure_weapon_data(weapon_data)
	if cache_key != "":
		_wd_cache[cache_key] = wd
	return wd


func _get_float(data, key: String, default: float) -> float:
	if data is WeaponData:
		return float(data.get(key)) if data.get(key) != null else default
	if data is Dictionary:
		var val = data.get(key, null)
		if val == null:
			var stats: Dictionary = data.get("stats", {})
			val = stats.get(key, default)
		return float(val)
	return default


func _get_int(data, key: String, default: int) -> int:
	if data is WeaponData:
		return int(data.get(key)) if data.get(key) != null else default
	if data is Dictionary:
		var val = data.get(key, null)
		if val == null:
			var stats: Dictionary = data.get("stats", {})
			val = stats.get(key, default)
		return int(val)
	return default


func _get_str(data, key: String, default: String) -> String:
	if data is WeaponData:
		var val = data.get(key)
		return str(val) if val != null else default
	if data is Dictionary:
		var val = data.get(key, null)
		if val == null:
			var stats: Dictionary = data.get("stats", {})
			val = stats.get(key, default)
		return str(val)
	return default


func _bot_to_dict(bot) -> Dictionary:
	## Convert bot to dictionary for CombatResolver.
	if bot is Dictionary:
		return bot
	var d: Dictionary = {
		"sim_id": bot.sim_id,
		"hp": bot.hp,
		"position": bot.position,
		"team": bot.team,
		"radius": bot.radius,
		"accuracy_bonus": bot.accuracy_bonus if "accuracy_bonus" in bot else 0.0,
	}
	# Copy resistance values if available
	for key in ["resist_ballistic", "resist_energy", "resist_explosive", "armor_break_magnitude"]:
		if key in bot:
			d[key] = bot.get(key)
	return d


func _apply_damage(bot, amount: float) -> void:
	## Apply damage to bot (clamped, handles both Dict and Object).
	var dmg: int = int(clampf(amount, 0.0, MAX_DAMAGE))
	if bot is Dictionary:
		bot["hp"] = maxi(0, bot.get("hp", 0) - dmg)
		if bot["hp"] <= 0:
			bot["is_alive"] = false
	else:
		bot.take_damage(dmg)


func _apply_status_effects(bot, applied_effects: Array, tick: int) -> void:
	## Append status effects to bot's status_effects array.
	var effects_list: Array = []
	if bot is Dictionary:
		effects_list = bot.get("status_effects", [])
		if not bot.has("status_effects"):
			bot["status_effects"] = effects_list
	else:
		effects_list = bot.status_effects

	for effect_def in applied_effects:
		var new_effect: Dictionary = {
			"type": effect_def.get("type", ""),
			"magnitude": float(effect_def.get("magnitude", 0.0)),
			"remaining_ticks": int(effect_def.get("duration_ticks", 60)),
			"tick_interval": int(effect_def.get("tick_interval", 0)),
			"stacking": effect_def.get("stacking", "refresh"),
			"applied_tick": tick,
		}

		# Stacking rules
		var stacking_rule: String = new_effect["stacking"]
		var existing_idx: int = -1
		for i in range(effects_list.size()):
			if effects_list[i].get("type", "") == new_effect["type"]:
				existing_idx = i
				break

		if existing_idx >= 0:
			match stacking_rule:
				"replace":
					effects_list[existing_idx] = new_effect
				"refresh":
					effects_list[existing_idx]["remaining_ticks"] = new_effect["remaining_ticks"]
					effects_list[existing_idx]["applied_tick"] = tick
				"stack":
					var max_stacks: int = int(effect_def.get("max_stacks", 3))
					var stack_count: int = effects_list[existing_idx].get("stack_count", 1)
					if stack_count < max_stacks:
						effects_list[existing_idx]["magnitude"] += new_effect["magnitude"]
						effects_list[existing_idx]["stack_count"] = stack_count + 1
					effects_list[existing_idx]["remaining_ticks"] = new_effect["remaining_ticks"]
		else:
			new_effect["stack_count"] = 1
			effects_list.append(new_effect)


func _collect_splash_targets(all_bots: Array, center: Vector2, source_id: int) -> Array:
	## Build array of bot dicts for splash resolution.
	var targets: Array = []
	for bot in all_bots:
		if not _is_bot_alive(bot):
			continue
		targets.append(_bot_to_dict(bot))
	return targets


func _find_bot_by_id(bots: Array, target_id: int):
	for bot in bots:
		if _get_int_prop(bot, "sim_id", -1) == target_id:
			return bot
	return null


func reset() -> void:
	## Reset state between battles.
	_next_proj_id = 1
	_events.clear()
	_dead_set.clear()
	_wd_cache.clear()
