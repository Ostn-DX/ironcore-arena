class_name CombatResolver extends RefCounted
## Resolves a single weapon hit against a target bot.
## Handles damage types, armor resistance, range falloff, crits, status effects.
## All values clamped [0, 9999]. Pure function -- no side effects, uses passed RNG only.

const MAX_DAMAGE: float = 9999.0
const MIN_DAMAGE: float = 0.0

# Pre-computed resist key lookup to avoid string concat in hot path
const _RESIST_KEYS: Dictionary = {
	"ballistic": "resist_ballistic",
	"energy": "resist_energy",
	"explosive": "resist_explosive",
}


static func resolve_hit(weapon: WeaponData, target_bot: Dictionary, distance: float,
		rng: DeterministicRng) -> Dictionary:
	## Resolve a hit from weapon against target_bot at given distance.
	## target_bot must have: sim_id, hp, resist_ballistic, resist_energy, resist_explosive
	## Returns: {damage, type, crit, status, target_id, hit}

	var result: Dictionary = {
		"damage": 0.0,
		"type": weapon.damage_type,
		"crit": false,
		"status": "",
		"target_id": target_bot.get("sim_id", -1),
		"hit": false,
	}

	# Cache weapon properties locally to avoid repeated property access
	var wpn_accuracy: float = weapon.accuracy
	var wpn_ptype: String = weapon.projectile_type
	var wpn_range_optimal: float = weapon.range_optimal
	var wpn_range_max: float = weapon.range_max
	var wpn_range_min: float = weapon.range_min
	var wpn_damage: float = weapon.damage_per_shot
	var wpn_crit_chance: float = weapon.crit_chance

	# Accuracy check (beams always hit in range)
	if wpn_ptype != "beam" and wpn_ptype != "melee":
		var eff_accuracy: float = wpn_accuracy
		# Reduce accuracy beyond optimal range
		if distance > wpn_range_optimal and wpn_range_max > wpn_range_optimal:
			var range_ratio: float = (distance - wpn_range_optimal) / (wpn_range_max - wpn_range_optimal)
			eff_accuracy *= (1.0 - clampf(range_ratio, 0.0, 1.0) * 0.5)
		eff_accuracy += target_bot.get("accuracy_bonus", 0.0)
		eff_accuracy = clampf(eff_accuracy, 0.0, 1.0)

		var roll: float = rng.next_float01()
		if roll >= eff_accuracy:
			return result  # Miss

	result["hit"] = true

	# Base damage
	var base_dmg: float = wpn_damage

	# Range falloff: below min range = 0 damage; between optimal and max = linear falloff
	if distance < wpn_range_min:
		base_dmg = 0.0
	elif distance > wpn_range_optimal and wpn_range_max > wpn_range_optimal:
		var falloff: float = 1.0 - (distance - wpn_range_optimal) / (wpn_range_max - wpn_range_optimal)
		base_dmg *= clampf(falloff, 0.1, 1.0)

	# Crit check
	if wpn_crit_chance > 0.0:
		var crit_roll: float = rng.next_float01()
		if crit_roll < wpn_crit_chance:
			result["crit"] = true
			base_dmg *= weapon.crit_multiplier

	# Armor resistance (pre-computed key avoids string concat)
	var resist_key: String = _RESIST_KEYS.get(weapon.damage_type, "resist_ballistic")
	var resistance: float = target_bot.get(resist_key, 0.0)

	# Armor break status reduces resistance
	var armor_break_mag: float = target_bot.get("armor_break_magnitude", 0.0)
	resistance = maxf(0.0, resistance - armor_break_mag)
	resistance = clampf(resistance, 0.0, 0.9)

	var final_dmg: float = base_dmg * (1.0 - resistance)

	# Clamp damage
	final_dmg = clampf(final_dmg, MIN_DAMAGE, MAX_DAMAGE)
	# Guard against NaN from float math edge cases
	if is_nan(final_dmg) or is_inf(final_dmg):
		final_dmg = 0.0

	result["damage"] = final_dmg

	# Status effects
	var applied_effects: Array = []
	for effect_def in weapon.effects:
		var apply_chance: float = float(effect_def.get("apply_chance", 1.0))
		var effect_roll: float = rng.next_float01()
		if effect_roll < apply_chance:
			applied_effects.append(effect_def.duplicate())

	if applied_effects.size() > 0:
		result["status"] = applied_effects[0].get("type", "")
		result["applied_effects"] = applied_effects

	return result


static func resolve_splash(weapon: WeaponData, impact_pos: Vector2, targets: Array,
		source_bot_id: int, rng: DeterministicRng) -> Array:
	## Resolve AOE splash damage against multiple targets.
	## targets: Array of Dictionaries with position, sim_id, team, etc.
	## Returns array of damage event dicts.
	## NOTE: targets array is sorted in-place for determinism. Caller should
	## not rely on original ordering after this call.

	var events: Array = []
	if weapon.splash_radius <= 0.0:
		return events

	# Sort targets in-place by sim_id for deterministic ordering (avoids .duplicate())
	targets.sort_custom(func(a, b): return a.get("sim_id", 0) < b.get("sim_id", 0))

	# Cache weapon properties
	var splash_radius: float = weapon.splash_radius
	var splash_falloff: float = weapon.splash_falloff
	var wpn_damage: float = weapon.damage_per_shot
	var wpn_damage_type: String = weapon.damage_type
	var resist_key: String = _RESIST_KEYS.get(wpn_damage_type, "resist_ballistic")
	var wpn_effects: Array = weapon.effects

	for target in targets:
		if target.get("sim_id", -1) == source_bot_id:
			continue  # No self-damage
		var target_pos: Vector2 = target.get("position", Vector2.ZERO)
		var dist: float = impact_pos.distance_to(target_pos)
		if dist > splash_radius:
			continue

		# Splash damage falloff based on distance from center
		var falloff_ratio: float = dist / splash_radius
		# splash_falloff exponent: 1.0 = linear, 2.0 = quadratic
		var splash_mult: float = 1.0 - pow(falloff_ratio, splash_falloff)
		splash_mult = clampf(splash_mult, 0.0, 1.0)

		# Build a reduced-damage event
		var base_dmg: float = wpn_damage * splash_mult

		# Armor resistance (pre-computed key)
		var resistance: float = target.get(resist_key, 0.0)
		var armor_break_mag: float = target.get("armor_break_magnitude", 0.0)
		resistance = clampf(maxf(0.0, resistance - armor_break_mag), 0.0, 0.9)
		var final_dmg: float = base_dmg * (1.0 - resistance)
		final_dmg = clampf(final_dmg, MIN_DAMAGE, MAX_DAMAGE)
		if is_nan(final_dmg) or is_inf(final_dmg):
			final_dmg = 0.0

		var event: Dictionary = {
			"damage": final_dmg,
			"type": wpn_damage_type,
			"crit": false,
			"status": "",
			"target_id": target.get("sim_id", -1),
			"hit": true,
			"splash": true,
		}

		# Status effects on splash hits
		for effect_def in wpn_effects:
			var apply_chance: float = float(effect_def.get("apply_chance", 1.0))
			# Splash reduces apply chance by 50%
			var splash_chance: float = apply_chance * 0.5
			var effect_roll: float = rng.next_float01()
			if effect_roll < splash_chance:
				if not event.has("applied_effects"):
					event["applied_effects"] = []
				event["applied_effects"].append(effect_def.duplicate())
				if event["status"] == "":
					event["status"] = effect_def.get("type", "")

		events.append(event)

	return events
