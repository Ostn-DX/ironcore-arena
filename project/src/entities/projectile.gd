extends RefCounted
## Projectile entity — simulation data object.
## Ballistics, beams, and melee handled here.

const TICKS_PER_SECOND: float = 60.0
const DT: float = 1.0 / TICKS_PER_SECOND

var proj_id: int = -1
var team: int = 0
var source_bot_id: int = -1

# Physics
var position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var speed: float = 0.0
var radius: float = 4.0

# Combat
var damage: float = 0.0
var damage_type: String = "ballistic"  # ballistic, energy, explosive
var hit_chance: float = 1.0
var effects: Array[Dictionary] = []

# Lifetime
var spawn_tick: int = 0
var max_range: float = 1000.0
var distance_traveled: float = 0.0
var is_active: bool = true

# Type
var projectile_type: String = "ballistic"  # ballistic, beam, melee


func _init(p_proj_id: int, p_team: int, p_source_id: int, p_spawn_pos: Vector2, 
		p_direction: Vector2, p_weapon_data: Dictionary) -> void:
	proj_id = p_proj_id
	team = p_team
	source_bot_id = p_source_id
	position = p_spawn_pos
	direction = p_direction.normalized()
	
	var stats: Dictionary = p_weapon_data.get("stats", {})
	
	projectile_type = stats.get("projectile_type", "ballistic")
	damage = stats.get("damage_per_shot", 10.0)
	damage_type = _infer_damage_type(p_weapon_data)
	
	if projectile_type == "ballistic":
		speed = stats.get("projectile_speed", 300.0)
		max_range = stats.get("range_max", 1000.0)
		radius = 4.0
	elif projectile_type == "beam":
		speed = 99999.0  # Instant
		max_range = stats.get("range_max", 1000.0)
		radius = 2.0
	elif projectile_type == "melee":
		speed = 0.0
		max_range = stats.get("range_max", 50.0)
		radius = 10.0
	
	# Hit chance calculation (stored for resolution)
	var base_acc: float = stats.get("accuracy", 0.7)
	hit_chance = base_acc


func _infer_damage_type(weapon_data: Dictionary) -> String:
	var stats: Dictionary = weapon_data.get("stats", {})
	var proj_type: String = stats.get("projectile_type", "ballistic")
	
	if proj_type == "beam":
		return "energy"
	elif proj_type == "ballistic":
		return "ballistic"
	return "ballistic"


func update() -> bool:
	## Returns true if projectile should be destroyed
	if not is_active:
		return true
	
	if projectile_type == "melee":
		# Melee is instant, destroyed after one check
		return true
	
	if projectile_type == "beam":
		# Beam is instant raycast, destroyed after one check
		return true
	
	# Ballistic movement
	var move_dist: float = speed * DT
	position += direction * move_dist
	distance_traveled += move_dist
	
	# Check max range
	if distance_traveled >= max_range:
		return true
	
	return false


func check_collision(bot: Dictionary) -> bool:
	## Check collision with a bot (passed as dict with position, radius, team)
	if not is_active:
		return false
	if team == bot["team"]:
		return false
	
	var bot_pos: Vector2 = bot["position"]
	var bot_radius: float = bot["radius"]
	
	var dist_sq: float = position.distance_squared_to(bot_pos)
	var combined_radius: float = radius + bot_radius
	
	return dist_sq <= combined_radius * combined_radius


func resolve_hit(target_bot: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	## Returns hit result: {hit: bool, damage: int, effects: []}
	var result: Dictionary = {"hit": false, "damage": 0, "effects": []}
	
	if not is_active:
		return result
	
	# Roll for hit
	var roll: float = rng.randf()
	if roll > hit_chance:
		return result  # Miss
	
	result["hit"] = true
	
	# Calculate damage with falloff
	var actual_damage: float = damage
	var _dist: float = distance_traveled
	var _wpn_stats: Dictionary = {}  # Would need to pass this in properly
	
	# Apply resistances (simplified — would need target bot's armor data)
	var resistance: float = 0.0
	if damage_type == "ballistic":
		resistance = target_bot.get("resist_ballistic", 0.0)
	elif damage_type == "energy":
		resistance = target_bot.get("resist_energy", 0.0)
	elif damage_type == "explosive":
		resistance = target_bot.get("resist_explosive", 0.0)
	
	actual_damage *= (1.0 - clamp(resistance, 0.0, 0.9))
	result["damage"] = int(actual_damage)
	
	# Copy effects
	result["effects"] = effects.duplicate()
	
	is_active = false
	return result


func check_out_of_bounds(arena_size: Vector2) -> bool:
	return position.x < 0 or position.x > arena_size.x or \
		   position.y < 0 or position.y > arena_size.y
