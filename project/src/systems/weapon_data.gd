class_name WeaponData extends Resource
## Data resource for a single weapon definition.
## All combat stats, projectile config, heat, crits, and status effects.
## Loaded from JSON via from_dict() factory method.

# Identity
@export var id: String = ""
@export var name: String = ""
@export var category: String = "weapon"
@export var tier: int = 1
@export var weight: float = 5.0
@export var cost: int = 100
@export var description: String = ""

# Core combat
@export var damage_per_shot: float = 10.0
@export var fire_rate: float = 1.0
@export var range_min: float = 0.0
@export var range_optimal: float = 100.0
@export var range_max: float = 200.0
@export var accuracy: float = 0.7

# Projectile
@export var projectile_type: String = "ballistic"
@export var damage_type: String = "ballistic"
@export var projectile_speed: float = 400.0
@export var projectile_radius: float = 4.0

# AOE
@export var splash_radius: float = 0.0
@export var splash_falloff: float = 1.0

# Heat
@export var heat_per_shot: float = 2.0
@export var heat_dissipation_per_tick: float = 0.3
@export var overheat_threshold: float = 40.0
@export var overheat_lockout_ticks: int = 120

# Crits
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.5

# Ammo
@export var ammo_capacity: int = -1
@export var reload_ticks: int = 0

# Burst
@export var burst_count: int = 1
@export var burst_delay_ticks: int = 0

# Spread
@export var spread_angle: float = 0.0

# Status effects: [{type, magnitude, duration_ticks, tick_interval, stacking, max_stacks, apply_chance}]
@export var effects: Array = []

# Tags for AI and filtering
@export var tags: Array = []

# AI hints
@export var ai_hints: Dictionary = {}

# Derived: cooldown in ticks between bursts (computed from fire_rate)
var cooldown_ticks: int = 20


static func from_dict(d: Dictionary) -> WeaponData:
	## Factory: build a WeaponData from a JSON-parsed dictionary.
	var w := WeaponData.new()
	w.id = str(d.get("id", ""))
	w.name = str(d.get("name", ""))
	w.category = str(d.get("category", "weapon"))
	w.tier = int(d.get("tier", 1))
	w.weight = float(d.get("weight", 5.0))
	w.cost = int(d.get("cost", 100))
	w.description = str(d.get("description", ""))

	w.damage_per_shot = float(d.get("damage_per_shot", 10.0))
	w.fire_rate = float(d.get("fire_rate", 1.0))
	w.range_min = float(d.get("range_min", 0.0))
	w.range_optimal = float(d.get("range_optimal", 100.0))
	w.range_max = float(d.get("range_max", 200.0))
	w.accuracy = float(d.get("accuracy", 0.7))

	w.projectile_type = str(d.get("projectile_type", "ballistic"))
	w.damage_type = str(d.get("damage_type", "ballistic"))
	w.projectile_speed = float(d.get("projectile_speed", 400.0))
	w.projectile_radius = float(d.get("projectile_radius", 4.0))

	w.splash_radius = float(d.get("splash_radius", 0.0))
	w.splash_falloff = float(d.get("splash_falloff", 1.0))

	w.heat_per_shot = float(d.get("heat_per_shot", 2.0))
	w.heat_dissipation_per_tick = float(d.get("heat_dissipation_per_tick", 0.3))
	w.overheat_threshold = float(d.get("overheat_threshold", 40.0))
	w.overheat_lockout_ticks = int(d.get("overheat_lockout_ticks", 120))

	w.crit_chance = float(d.get("crit_chance", 0.0))
	w.crit_multiplier = float(d.get("crit_multiplier", 1.5))

	w.ammo_capacity = int(d.get("ammo_capacity", -1))
	w.reload_ticks = int(d.get("reload_ticks", 0))

	w.burst_count = int(d.get("burst_count", 1))
	w.burst_delay_ticks = int(d.get("burst_delay_ticks", 0))

	w.spread_angle = float(d.get("spread_angle", 0.0))

	# Effects array -- validate each entry strictly
	var raw_effects: Array = d.get("effects", [])
	var allowed_effect_types: Array = ["slow", "stun", "burn", "emp", "armor_break"]
	var allowed_stacking: Array = ["replace", "refresh", "stack"]
	w.effects = []
	for e in raw_effects:
		if not (e is Dictionary):
			continue
		var etype: Variant = e.get("type", "")
		if not (etype is String) or not (etype in allowed_effect_types):
			continue
		var safe_effect: Dictionary = {
			"type": etype,
			"magnitude": clampf(float(e.get("magnitude", 0.0)), 0.0, 1.0),
			"duration_ticks": clampi(int(e.get("duration_ticks", 60)), 1, 600),
			"tick_interval": clampi(int(e.get("tick_interval", 0)), 0, 60),
			"stacking": str(e.get("stacking", "refresh")) if str(e.get("stacking", "refresh")) in allowed_stacking else "refresh",
			"max_stacks": clampi(int(e.get("max_stacks", 3)), 1, 5),
			"apply_chance": clampf(float(e.get("apply_chance", 1.0)), 0.01, 1.0),
		}
		w.effects.append(safe_effect)

	# Validate tags -- only allow known string values
	var raw_tags: Array = d.get("tags", [])
	w.tags = []
	var allowed_tags: Array = [
		"sustained_fire", "burst_fire", "sniper", "close_range",
		"area_damage", "support", "anti_armor", "anti_energy",
		"crowd_control", "high_heat", "low_heat", "starter"
	]
	for tag in raw_tags:
		if tag is String and tag in allowed_tags:
			w.tags.append(tag)

	# Validate ai_hints -- only allow known keys with safe types
	var raw_hints: Variant = d.get("ai_hints", {})
	w.ai_hints = {}
	if raw_hints is Dictionary:
		var allowed_ranges: Array = ["close", "medium", "far"]
		var allowed_roles: Array = ["tank", "sniper", "scout", "support"]
		var pr: Variant = raw_hints.get("preferred_range", "")
		if pr is String and pr in allowed_ranges:
			w.ai_hints["preferred_range"] = pr
		var ra: Variant = raw_hints.get("role_affinity", [])
		if ra is Array:
			var safe_roles: Array = []
			for role in ra:
				if role is String and role in allowed_roles:
					safe_roles.append(role)
			w.ai_hints["role_affinity"] = safe_roles

	# Derived: ticks between bursts from fire_rate
	if w.fire_rate > 0.0:
		w.cooldown_ticks = int(roundf(60.0 / w.fire_rate))
	else:
		w.cooldown_ticks = 9999

	return w


func is_valid() -> bool:
	## Validate required fields and value ranges.
	if id.is_empty() or not id.begins_with("wpn_"):
		return false
	if name.is_empty():
		return false
	if category != "weapon":
		return false
	if tier < 1 or tier > 5:
		return false
	if weight < 0.5 or weight > 80.0:
		return false
	if damage_per_shot < -500.0 or damage_per_shot > 500.0:
		return false
	if fire_rate < 0.1 or fire_rate > 10.0:
		return false
	if range_max < range_optimal:
		return false
	if accuracy < 0.0 or accuracy > 1.0:
		return false
	if not projectile_type in ["ballistic", "beam", "melee", "aoe"]:
		return false
	if not damage_type in ["ballistic", "energy", "explosive"]:
		return false
	if overheat_threshold < 10.0 or overheat_threshold > 200.0:
		return false
	if overheat_lockout_ticks < 30 or overheat_lockout_ticks > 600:
		return false
	if crit_chance < 0.0 or crit_chance > 0.5:
		return false
	if crit_multiplier < 1.0 or crit_multiplier > 3.0:
		return false
	if burst_count < 1 or burst_count > 10:
		return false
	if range_min < 0.0 or range_min > 100.0:
		return false
	if range_optimal < 10.0 or range_optimal > 800.0:
		return false
	if range_max < 20.0 or range_max > 1200.0:
		return false
	if splash_radius < 0.0 or splash_radius > 200.0:
		return false
	if splash_falloff < 0.5 or splash_falloff > 3.0:
		return false
	if spread_angle < 0.0 or spread_angle > 45.0:
		return false
	if projectile_speed < 0.0 or projectile_speed > 2000.0:
		return false
	if projectile_radius < 1.0 or projectile_radius > 30.0:
		return false
	if heat_per_shot < 0.0 or heat_per_shot > 50.0:
		return false
	if heat_dissipation_per_tick < 0.0 or heat_dissipation_per_tick > 5.0:
		return false
	if burst_delay_ticks < 0 or burst_delay_ticks > 30:
		return false
	if effects.size() > 3:
		return false
	return true


func get_dps() -> float:
	## Compute theoretical DPS (damage * fire_rate * burst_count, accuracy-adjusted).
	return absf(damage_per_shot) * fire_rate * burst_count * accuracy


func get_heat_per_second() -> float:
	## Heat generated per second at max fire rate.
	return heat_per_shot * fire_rate * burst_count


func get_sustained_heat_ratio() -> float:
	## Ratio of heat generation to dissipation. > 1.0 means will overheat.
	var dissipation_per_second: float = heat_dissipation_per_tick * 60.0
	if dissipation_per_second <= 0.0:
		return 999.0
	return get_heat_per_second() / dissipation_per_second


func is_healing() -> bool:
	## Negative damage_per_shot means this weapon heals (e.g. Repair Beam).
	return damage_per_shot < 0.0
