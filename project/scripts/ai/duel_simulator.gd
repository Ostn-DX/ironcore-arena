extends RefCounted
class_name DuelSimulator
## Headless 1v1 duel simulation engine for balance testing.
## Uses xorshift32 RNG matching DeterministicRng. No Node dependencies.
## Two bots face off with a single weapon each; first to 0 HP loses.

const TIMESTEP: float = 1.0 / 60.0
const MAX_TICKS: int = 3600  # 60 seconds max per duel
const DEFAULT_HP: float = 100.0
const DEFAULT_ARMOR: float = 10.0
const BOT_RADIUS: float = 20.0


func run_duel(weapon_a: Dictionary, weapon_b: Dictionary, seed_val: int) -> Dictionary:
	## Simulate a single 1v1 duel between two bots with the given weapons.
	## Returns: { "winner": String, "ttk_a": float, "ttk_b": float, "ticks": int }

	# Init RNG
	var rng := _Rng.new(seed_val)

	# Build bot dictionaries
	var bot_a: Dictionary = _make_bot(1, weapon_a)
	var bot_b: Dictionary = _make_bot(2, weapon_b)

	# Place bots at mid-optimal range of both weapons
	var range_a: float = weapon_a.get("range_optimal", 100.0)
	var range_b: float = weapon_b.get("range_optimal", 100.0)
	var engagement_range: float = (range_a + range_b) / 2.0
	# Clamp engagement range within both weapons' max range
	var max_range_a: float = weapon_a.get("range_max", 200.0)
	var max_range_b: float = weapon_b.get("range_max", 200.0)
	engagement_range = minf(engagement_range, minf(max_range_a, max_range_b))
	engagement_range = maxf(engagement_range, 30.0)

	bot_a["position_x"] = 0.0
	bot_b["position_x"] = engagement_range
	var distance: float = engagement_range

	var ttk_a: float = -1.0  # Time-to-kill for weapon_a (when bot_b dies)
	var ttk_b: float = -1.0  # Time-to-kill for weapon_b (when bot_a dies)
	var tick: int = 0

	while tick < MAX_TICKS:
		# Update heat dissipation for both bots
		_dissipate_heat(bot_a, weapon_a, tick)
		_dissipate_heat(bot_b, weapon_b, tick)

		# Bot A fires at Bot B (processed first by sim_id order)
		if bot_a["hp"] > 0 and bot_b["hp"] > 0:
			if not _is_stunned(bot_a):
				_try_fire(bot_a, bot_b, weapon_a, distance, rng, tick)

		# Bot B fires at Bot A
		if bot_a["hp"] > 0 and bot_b["hp"] > 0:
			if not _is_stunned(bot_b):
				_try_fire(bot_b, bot_a, weapon_b, distance, rng, tick)

		# Tick status effects (burn damage)
		_tick_status_effects(bot_a, tick)
		_tick_status_effects(bot_b, tick)

		# Check kills
		if bot_b["hp"] <= 0 and ttk_a < 0:
			ttk_a = float(tick + 1) * TIMESTEP
		if bot_a["hp"] <= 0 and ttk_b < 0:
			ttk_b = float(tick + 1) * TIMESTEP

		if bot_a["hp"] <= 0 or bot_b["hp"] <= 0:
			break

		tick += 1

	var winner: String = "draw"
	if bot_b["hp"] <= 0 and bot_a["hp"] > 0:
		winner = str(weapon_a.get("id", "weapon_a"))
	elif bot_a["hp"] <= 0 and bot_b["hp"] > 0:
		winner = str(weapon_b.get("id", "weapon_b"))
	elif bot_a["hp"] <= 0 and bot_b["hp"] <= 0:
		# Both dead same tick: weapon_a wins (processed first = first kill)
		winner = str(weapon_a.get("id", "weapon_a"))

	return {
		"winner": winner,
		"ttk_a": ttk_a,
		"ttk_b": ttk_b,
		"ticks": tick + 1,
	}


func run_batch(weapon_a: Dictionary, weapon_b: Dictionary, num_runs: int, base_seed: int) -> Dictionary:
	## Run num_runs duels and aggregate results.
	var a_wins: int = 0
	var b_wins: int = 0
	var draws: int = 0
	var winner_ttks: Array = []
	var loser_ttks: Array = []
	var outlier_ticks: Array = []
	var id_a: String = str(weapon_a.get("id", "weapon_a"))
	var id_b: String = str(weapon_b.get("id", "weapon_b"))

	for i in range(num_runs):
		var result: Dictionary = run_duel(weapon_a, weapon_b, base_seed + i)
		var w: String = result["winner"]
		if w == id_a:
			a_wins += 1
			if result["ttk_a"] >= 0:
				winner_ttks.append(result["ttk_a"])
			if result["ttk_b"] >= 0:
				loser_ttks.append(result["ttk_b"])
		elif w == id_b:
			b_wins += 1
			if result["ttk_b"] >= 0:
				winner_ttks.append(result["ttk_b"])
			if result["ttk_a"] >= 0:
				loser_ttks.append(result["ttk_a"])
		else:
			draws += 1
		# Outliers: duels lasting > 45 seconds
		if result["ticks"] > 2700:
			outlier_ticks.append(result["ticks"])

	var avg_ttk_w: float = _avg(winner_ttks) if winner_ttks.size() > 0 else 0.0
	var avg_ttk_l: float = _avg(loser_ttks) if loser_ttks.size() > 0 else 0.0
	var ttk_var: float = _variance(winner_ttks) if winner_ttks.size() > 1 else 0.0

	return {
		"weapon_a_wins": a_wins,
		"weapon_b_wins": b_wins,
		"draws": draws,
		"avg_ttk_winner": avg_ttk_w,
		"avg_ttk_loser": avg_ttk_l,
		"ttk_variance": ttk_var,
		"outlier_ticks": outlier_ticks,
	}


# ============================================================================
# FIRING LOGIC
# ============================================================================

func _try_fire(attacker: Dictionary, defender: Dictionary, weapon: Dictionary,
		distance: float, rng: _Rng, tick: int) -> void:
	# Check overheat
	if attacker.get("overheated", false):
		if tick >= attacker.get("overheat_end_tick", 0) and attacker.get("heat", 0.0) <= 0.0:
			attacker["overheated"] = false
		else:
			return

	# Check cooldown
	if tick < attacker.get("next_fire_tick", 0):
		return

	# Range check
	var range_max: float = weapon.get("range_max", 200.0)
	if distance > range_max:
		return

	# Burst handling
	var burst_count: int = weapon.get("burst_count", 1)
	var is_new_burst: bool = attacker.get("burst_remaining", 0) <= 0

	if is_new_burst:
		attacker["burst_remaining"] = burst_count

	# Handle burst readiness
	if not is_new_burst and not attacker.get("burst_ready", true):
		return

	# Fire one shot
	_resolve_shot(attacker, defender, weapon, distance, rng, tick)

	# Advance burst state
	attacker["burst_remaining"] = attacker.get("burst_remaining", 1) - 1
	attacker["burst_ready"] = false

	if attacker.get("burst_remaining", 0) <= 0:
		# Burst complete
		var fire_rate: float = weapon.get("fire_rate", 1.0)
		var cooldown: int = int(round(60.0 / fire_rate)) if fire_rate > 0.0 else 9999
		attacker["next_fire_tick"] = tick + cooldown
	else:
		var burst_delay: int = weapon.get("burst_delay_ticks", 0)
		attacker["next_burst_tick"] = tick + burst_delay
		# Mark burst ready if no delay
		if burst_delay == 0:
			attacker["burst_ready"] = true

	# Heat
	var heat_per: float = weapon.get("heat_per_shot", 2.0)
	attacker["heat"] = attacker.get("heat", 0.0) + heat_per
	var threshold: float = weapon.get("overheat_threshold", 40.0)
	if attacker["heat"] >= threshold:
		attacker["overheated"] = true
		var lockout: int = weapon.get("overheat_lockout_ticks", 120)
		attacker["overheat_end_tick"] = tick + lockout


func _resolve_shot(attacker: Dictionary, defender: Dictionary, weapon: Dictionary,
		distance: float, rng: _Rng, tick: int) -> void:
	var ptype: String = weapon.get("projectile_type", "ballistic")
	var accuracy: float = weapon.get("accuracy", 0.7)

	# Accuracy check (beams/melee always hit in range)
	if ptype != "beam" and ptype != "melee":
		# Reduce accuracy beyond optimal range
		var range_optimal: float = weapon.get("range_optimal", 100.0)
		var range_max: float = weapon.get("range_max", 200.0)
		if distance > range_optimal and range_max > range_optimal:
			var range_ratio: float = (distance - range_optimal) / (range_max - range_optimal)
			accuracy *= (1.0 - min(max(range_ratio, 0.0), 1.0) * 0.5)
		accuracy = min(max(accuracy, 0.0), 1.0)
		var roll: float = rng.next_float01()
		if roll >= accuracy:
			return  # Miss

	# Base damage
	var base_dmg: float = weapon.get("damage_per_shot", 10.0)

	# Skip negative damage weapons (repair beams) in combat
	if base_dmg <= 0:
		return

	# Range falloff
	var range_min: float = weapon.get("range_min", 0.0)
	var range_optimal: float = weapon.get("range_optimal", 100.0)
	var range_max: float = weapon.get("range_max", 200.0)
	if distance < range_min:
		base_dmg = 0.0
	elif distance > range_optimal and range_max > range_optimal:
		var falloff: float = 1.0 - (distance - range_optimal) / (range_max - range_optimal)
		base_dmg *= max(min(falloff, 1.0), 0.1)

	# Crit check
	var crit_chance: float = weapon.get("crit_chance", 0.0)
	if crit_chance > 0.0:
		var crit_roll: float = rng.next_float01()
		if crit_roll < crit_chance:
			base_dmg *= weapon.get("crit_multiplier", 1.5)

	# Armor resistance
	var resist_key: String = "resist_" + weapon.get("damage_type", "ballistic")
	var resistance: float = defender.get(resist_key, 0.0)
	# Account for armor break
	var armor_break: float = defender.get("armor_break_magnitude", 0.0)
	resistance = max(0.0, resistance - armor_break)
	resistance = min(max(resistance, 0.0), 0.9)

	var final_dmg: float = base_dmg * (1.0 - resistance)
	final_dmg = max(min(final_dmg, 9999.0), 0.0)

	# Apply damage
	defender["hp"] = max(0.0, defender.get("hp", 100.0) - final_dmg)
	if defender["hp"] <= 0:
		defender["is_alive"] = false

	# Status effects
	var effects: Array = weapon.get("effects", [])
	for effect_def in effects:
		var apply_chance: float = effect_def.get("apply_chance", 1.0)
		var effect_roll: float = rng.next_float01()
		if effect_roll < apply_chance:
			_apply_effect(defender, effect_def, tick)


# ============================================================================
# STATUS EFFECTS
# ============================================================================

func _apply_effect(bot: Dictionary, effect_def: Dictionary, tick: int) -> void:
	var effects: Array = bot.get("status_effects", [])
	var etype: String = effect_def.get("type", "")
	var stacking: String = effect_def.get("stacking", "refresh")
	var new_effect: Dictionary = {
		"type": etype,
		"magnitude": effect_def.get("magnitude", 0.0),
		"remaining_ticks": effect_def.get("duration_ticks", 60),
		"tick_interval": effect_def.get("tick_interval", 0),
		"last_tick_at": tick,
		"applied_tick": tick,
	}

	var found: int = -1
	for i in range(effects.size()):
		if effects[i].get("type", "") == etype:
			found = i
			break

	if found >= 0:
		if stacking == "replace":
			effects[found] = new_effect
		elif stacking == "refresh":
			effects[found]["remaining_ticks"] = new_effect["remaining_ticks"]
			effects[found]["applied_tick"] = tick
		elif stacking == "stack":
			var max_stacks: int = effect_def.get("max_stacks", 3)
			var stack_count: int = effects[found].get("stack_count", 1)
			if stack_count < max_stacks:
				effects[found]["magnitude"] += new_effect["magnitude"]
				effects[found]["stack_count"] = stack_count + 1
			effects[found]["remaining_ticks"] = new_effect["remaining_ticks"]
	else:
		new_effect["stack_count"] = 1
		effects.append(new_effect)

	bot["status_effects"] = effects


func _tick_status_effects(bot: Dictionary, tick: int) -> void:
	var effects: Array = bot.get("status_effects", [])
	var to_remove: Array = []

	for i in range(effects.size()):
		var e: Dictionary = effects[i]
		e["remaining_ticks"] = e.get("remaining_ticks", 0) - 1

		# Periodic effects (burn)
		var interval: int = e.get("tick_interval", 0)
		if interval > 0 and e.get("type", "") == "burn":
			if (tick - e.get("applied_tick", 0)) % interval == 0:
				var burn_dmg: float = e.get("magnitude", 0.0)
				bot["hp"] = max(0.0, bot.get("hp", 100.0) - burn_dmg)
				if bot["hp"] <= 0:
					bot["is_alive"] = false

		# Armor break effect
		if e.get("type", "") == "armor_break":
			bot["armor_break_magnitude"] = e.get("magnitude", 0.0)

		if e.get("remaining_ticks", 0) <= 0:
			to_remove.append(i)
			if e.get("type", "") == "armor_break":
				bot["armor_break_magnitude"] = 0.0

	for idx in range(to_remove.size() - 1, -1, -1):
		effects.remove_at(to_remove[idx])

	bot["status_effects"] = effects


func _is_stunned(bot: Dictionary) -> bool:
	var effects: Array = bot.get("status_effects", [])
	for e in effects:
		if e.get("type", "") == "stun":
			return true
	return false


func _dissipate_heat(bot: Dictionary, weapon: Dictionary, tick: int) -> void:
	var dissipation: float = weapon.get("heat_dissipation_per_tick", 0.3)
	var current_heat: float = bot.get("heat", 0.0)
	current_heat = max(0.0, current_heat - dissipation)
	bot["heat"] = current_heat

	# Burst readiness
	if bot.get("burst_remaining", 0) > 0:
		var burst_delay: int = weapon.get("burst_delay_ticks", 0)
		if burst_delay == 0 or tick >= bot.get("next_burst_tick", 0):
			bot["burst_ready"] = true


# ============================================================================
# HELPERS
# ============================================================================

func _make_bot(sim_id: int, weapon: Dictionary) -> Dictionary:
	return {
		"sim_id": sim_id,
		"hp": DEFAULT_HP,
		"max_hp": DEFAULT_HP,
		"armor": DEFAULT_ARMOR,
		"is_alive": true,
		"radius": BOT_RADIUS,
		"position_x": 0.0,
		"heat": 0.0,
		"overheated": false,
		"overheat_end_tick": 0,
		"next_fire_tick": 0,
		"burst_remaining": 0,
		"burst_ready": true,
		"next_burst_tick": 0,
		"status_effects": [],
		"resist_ballistic": 0.1,
		"resist_energy": 0.1,
		"resist_explosive": 0.1,
		"armor_break_magnitude": 0.0,
		"weapon": weapon,
	}


func _avg(arr: Array) -> float:
	if arr.size() == 0:
		return 0.0
	var total: float = 0.0
	for v in arr:
		total += float(v)
	return total / float(arr.size())


func _variance(arr: Array) -> float:
	if arr.size() < 2:
		return 0.0
	var mean: float = _avg(arr)
	var sum_sq: float = 0.0
	for v in arr:
		var diff: float = float(v) - mean
		sum_sq += diff * diff
	return sum_sq / float(arr.size())


# ============================================================================
# INNER RNG CLASS -- matches xorshift32 from DeterministicRng
# ============================================================================

class _Rng:
	var _state: int = 1

	func _init(seed_val: int) -> void:
		_state = seed_val if seed_val != 0 else 1

	func next_u32() -> int:
		var x: int = _state
		x = x ^ ((x << 13) & 0xFFFFFFFF)
		x = x ^ ((x >> 17) & 0xFFFFFFFF)
		x = x ^ ((x << 5) & 0xFFFFFFFF)
		_state = x & 0xFFFFFFFF
		return _state

	func next_float01() -> float:
		return float(next_u32()) / 4294967296.0

	func next_float_range(min_val: float, max_val: float) -> float:
		return min_val + next_float01() * (max_val - min_val)
