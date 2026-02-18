extends RefCounted
## Bot entity — simulation data object.
## Pure data, no Node2D references. Simulation operates on these.

const TICKS_PER_SECOND: float = 60.0
const DT: float = 1.0 / TICKS_PER_SECOND

# Identity
var sim_id: int = -1
var team: int = 0  # 0 = player, 1 = enemy
var bot_name: String = "Bot"

# Physics
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var rotation: float = 0.0  # degrees
var radius: float = 20.0

# Stats
var max_hp: int = 100
var hp: int = 100
var base_speed: float = 100.0
var base_accel: float = 50.0
var base_turn_rate: float = 180.0

# Current effective stats (after modifiers)
var current_speed: float = 100.0
var current_accel: float = 50.0

# Weapon slots
var weapons: Array[Dictionary] = []  # {part_id, data, next_fire_tick, heat, overheated}
var weapon_cooldown_ticks: int = 0

# Sensors
var detection_range: float = 1200.0  # Increased so bots see each other across arena
var accuracy_bonus: float = 0.0

# AI state
var target_id: int = -1
var ai_profile: Dictionary = {}
var command_type: String = ""  # "move", "follow", "focus"
var command_target: Variant = null  # Vector2 or int (bot id)
var command_expiry_tick: int = -1
var command_cooldown_until: int = 0

# Status effects
var status_effects: Array[Dictionary] = []  # {type, magnitude, remaining_ticks, ...}

# Meta
var is_alive: bool = true
var chassis_size: float = 20.0


func _init(p_sim_id: int, p_team: int, p_position: Vector2) -> void:
	sim_id = p_sim_id
	team = p_team
	position = p_position


func setup_from_loadout(loadout: Dictionary, part_data: Dictionary) -> void:
	bot_name = loadout.get("name", "Bot")
	
	# Get chassis data
	var chassis_id: String = loadout.get("chassis", "")
	if chassis_id.is_empty() or not part_data.has(chassis_id):
		push_warning("Bot %d: invalid chassis %s" % [sim_id, chassis_id])
		return
	
	var chassis: Dictionary = part_data[chassis_id]
	var stats: Dictionary = chassis.get("stats", {})
	
	max_hp = stats.get("hp", 100)
	hp = max_hp
	base_speed = stats.get("base_speed", 100.0)
	base_accel = stats.get("base_accel", 50.0)
	base_turn_rate = stats.get("base_turn_rate", 180.0)
	chassis_size = stats.get("chassis_size", 20.0)
	radius = chassis_size * 0.5
	
	# Setup weapons
	for weapon_id in loadout.get("weapons", []):
		if part_data.has(weapon_id):
			var wpn_data: Dictionary = part_data[weapon_id]
			weapons.append({
				"part_id": weapon_id,
				"data": wpn_data,
				"next_fire_tick": 0,
				"heat": 0.0,
				"overheated": false
			})
	
	# Setup sensors
	for sensor_id in loadout.get("sensors", []):
		if part_data.has(sensor_id):
			var sen_data: Dictionary = part_data[sensor_id]
			var sen_stats: Dictionary = sen_data.get("stats", {})
			detection_range = max(detection_range, sen_stats.get("detection_range", 200.0))
			accuracy_bonus += sen_stats.get("accuracy_bonus", 0.0)
	
	# Apply mobility multipliers
	var speed_mult: float = 1.0
	var accel_mult: float = 1.0
	for mob_id in loadout.get("mobility", []):
		if part_data.has(mob_id):
			var mob_data: Dictionary = part_data[mob_id]
			var mob_stats: Dictionary = mob_data.get("stats", {})
			speed_mult *= mob_stats.get("speed_multiplier", 1.0)
			accel_mult *= mob_stats.get("accel_multiplier", 1.0)
	
	current_speed = base_speed * speed_mult
	current_accel = base_accel * accel_mult
	
	# AI profile
	var profile_id: String = loadout.get("ai_profile", "ai_balanced")
	ai_profile = _get_ai_profile(profile_id)


func _get_ai_profile(profile_id: String) -> Dictionary:
	var profiles: Dictionary = {
		"ai_balanced": {"w_dist": 0.3, "w_threat": 0.2, "w_hp": 0.2, "w_focus": 0.5, "preferred_range": "medium", "retreat_threshold": 0.15},
		"ai_aggressive": {"w_dist": 0.2, "w_threat": 0.1, "w_hp": 0.4, "w_focus": 0.5, "preferred_range": "close", "retreat_threshold": 0.10},
		"ai_defensive": {"w_dist": 0.4, "w_threat": 0.3, "w_hp": 0.1, "w_focus": 0.5, "preferred_range": "far", "retreat_threshold": 0.25},
		"ai_sniper": {"w_dist": 0.5, "w_threat": 0.2, "w_hp": 0.1, "w_focus": 0.4, "preferred_range": "far", "retreat_threshold": 0.20},
		"ai_brawler": {"w_dist": 0.1, "w_threat": 0.1, "w_hp": 0.5, "w_focus": 0.5, "preferred_range": "close", "retreat_threshold": 0.05},
		"ai_support": {"w_dist": 0.3, "w_threat": 0.3, "w_hp": 0.2, "w_focus": 0.3, "preferred_range": "medium", "retreat_threshold": 0.30}
	}
	return profiles.get(profile_id, profiles["ai_balanced"])


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	if hp <= 0:
		is_alive = false


func apply_status_effect(effect: Dictionary) -> void:
	status_effects.append(effect.duplicate())


func update_status_effects(current_tick: int) -> void:
	var i: int = status_effects.size() - 1
	while i >= 0:
		var effect: Dictionary = status_effects[i]
		effect["remaining_ticks"] -= 1
		
		# Apply per-tick damage (burn, etc.)
		if effect.get("tick_interval", 0) > 0:
			if current_tick % effect["tick_interval"] == 0:
				var damage: float = effect.get("magnitude", 0.0)
				if damage > 0:
					take_damage(int(damage))
		
		if effect["remaining_ticks"] <= 0:
			status_effects.remove_at(i)
		i -= 1


func get_effective_stats() -> Dictionary:
	var speed_mod: float = 1.0
	for effect in status_effects:
		if effect["type"] == "slow":
			speed_mod *= (1.0 - effect["magnitude"])
		elif effect["type"] == "stun":
			speed_mod = 0.0
	
	return {
		"speed": current_speed * speed_mod,
		"accel": current_accel,
		"can_fire": not _is_stunned()
	}


func _is_stunned() -> bool:
	for effect in status_effects:
		if effect["type"] == "stun":
			return true
	return false


func compute_dps() -> float:
	var total_dps: float = 0.0
	for w in weapons:
		var wpn: Dictionary = w["data"]
		var stats: Dictionary = wpn.get("stats", {})
		var damage: float = stats.get("damage_per_shot", 0.0)
		var fire_rate: float = stats.get("fire_rate", 1.0)
		total_dps += damage * fire_rate
	return total_dps
