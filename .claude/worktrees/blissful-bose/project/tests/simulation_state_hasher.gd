class_name SimulationStateHasher extends RefCounted

## Creates deterministic hash of simulation state for determinism verification.
##
## This class serializes simulation state in a deterministic order and
## computes SHA256 hashes to verify that simulations produce identical
## results given the same initial conditions and inputs.

## Precision for float quantization (1mm resolution)
const DEFAULT_PRECISION: float = 0.001

## Hash algorithm context
var _ctx: HashingContext = null


func _init() -> void:
    _ctx = HashingContext.new()


## Hashes entire simulation state.
##
## Serializes all relevant simulation data in a deterministic order
## and computes a SHA256 hash. This ensures that any difference in
## state will produce a different hash.
##
## [param sim] The simulation node to hash
## Returns: SHA256 hash as a hexadecimal string
func hash_simulation(sim: Node) -> String:
    if sim == null:
        push_error("SimulationStateHasher: Cannot hash null simulation")
        return ""
    
    _ctx.start(HashingContext.HASH_SHA256)
    
    # Hash simulation-level properties
    var sim_data: Dictionary = _extract_simulation_data(sim)
    var sim_str: String = _serialize_dict(sim_data)
    _ctx.update(sim_str.to_utf8_buffer())
    
    # Hash all bots in deterministic order (sorted by sim_id)
    var bots: Array = _get_sorted_bots(sim)
    for bot in bots:
        var bot_hash: String = hash_bot(bot)
        _ctx.update(bot_hash.to_utf8_buffer())
    
    # Hash all projectiles in deterministic order
    var projectiles: Array = _get_sorted_projectiles(sim)
    for proj in projectiles:
        var proj_hash: String = hash_projectile(proj)
        _ctx.update(proj_hash.to_utf8_buffer())
    
    # Hash all effects/particles in deterministic order
    var effects: Array = _get_sorted_effects(sim)
    for effect in effects:
        var effect_str: String = _serialize_effect(effect)
        _ctx.update(effect_str.to_utf8_buffer())
    
    var hash_result: PackedByteArray = _ctx.finish()
    return _bytes_to_hex(hash_result)


## Hashes a single bot state.
##
## Includes: sim_id, team, position (quantized), health, velocity, state,
## weapon cooldown, and any other relevant state.
##
## [param bot] The bot node to hash
## Returns: A string representation of the bot's state
func hash_bot(bot: Node) -> String:
    if bot == null:
        return "bot:null"
    
    var data: Dictionary = {}
    
    # Core identification
    data["id"] = _get_safe_int(bot, "sim_id", -1)
    data["team"] = _get_safe_int(bot, "team_id", 0)
    
    # Position and orientation (quantized to prevent FP drift)
    var pos: Vector2 = _get_safe_vector2(bot, "position", Vector2.ZERO)
    data["pos_x"] = _quantize(pos.x)
    data["pos_y"] = _quantize(pos.y)
    data["rotation"] = _quantize(_get_safe_float(bot, "rotation", 0.0))
    
    # Physics state
    var vel: Vector2 = _get_safe_vector2(bot, "velocity", Vector2.ZERO)
    data["vel_x"] = _quantize(vel.x)
    data["vel_y"] = _quantize(vel.y)
    
    # Combat state
    data["health"] = _quantize(_get_safe_float(bot, "health", 100.0))
    data["max_health"] = _quantize(_get_safe_float(bot, "max_health", 100.0))
    data["armor"] = _quantize(_get_safe_float(bot, "armor", 0.0))
    
    # Bot state machine state
    data["state"] = _get_safe_string(bot, "current_state", "idle")
    data["state_time"] = _quantize(_get_safe_float(bot, "state_time", 0.0))
    
    # Weapon state
    data["weapon_cd"] = _quantize(_get_safe_float(bot, "weapon_cooldown", 0.0))
    data["ammo"] = _get_safe_int(bot, "current_ammo", 0)
    
    # AI state (if applicable)
    data["target_id"] = _get_safe_int(bot, "target_id", -1)
    data["path_idx"] = _get_safe_int(bot, "path_index", 0)
    
    return _serialize_dict(data)


## Hashes a projectile state.
##
## Includes: sim_id, owner_id, position, velocity, damage, lifetime.
##
## [param proj] The projectile node to hash
## Returns: A string representation of the projectile's state
func hash_projectile(proj: Node) -> String:
    if proj == null:
        return "proj:null"
    
    var data: Dictionary = {}
    
    # Identification
    data["id"] = _get_safe_int(proj, "sim_id", -1)
    data["owner"] = _get_safe_int(proj, "owner_id", -1)
    
    # Position and velocity (quantized)
    var pos: Vector2 = _get_safe_vector2(proj, "position", Vector2.ZERO)
    data["pos_x"] = _quantize(pos.x)
    data["pos_y"] = _quantize(pos.y)
    
    var vel: Vector2 = _get_safe_vector2(proj, "velocity", Vector2.ZERO)
    data["vel_x"] = _quantize(vel.x)
    data["vel_y"] = _quantize(vel.y)
    
    # Combat properties
    data["damage"] = _quantize(_get_safe_float(proj, "damage", 0.0))
    data["lifetime"] = _quantize(_get_safe_float(proj, "lifetime", 0.0))
    data["max_lifetime"] = _quantize(_get_safe_float(proj, "max_lifetime", 5.0))
    data["bounces"] = _get_safe_int(proj, "bounce_count", 0)
    
    # Type info
    data["type"] = _get_safe_string(proj, "projectile_type", "bullet")
    
    return _serialize_dict(data)


## Serializes a dictionary to a deterministic string representation.
##
## Keys are sorted alphabetically to ensure consistent ordering.
## Values are formatted with consistent precision.
##
## [param dict] The dictionary to serialize
## Returns: A deterministic string representation
func _serialize_dict(dict: Dictionary) -> String:
    var keys: Array = dict.keys()
    keys.sort()
    
    var parts: PackedStringArray = []
    for key in keys:
        var value: Variant = dict[key]
        parts.append("%s=%s" % [key, _format_value(value)])
    
    return "{" + ",".join(parts) + "}"


## Quantizes a float value for deterministic comparison.
##
## Rounds the value to the nearest multiple of precision to eliminate
## floating-point drift that can occur across different platforms or
## compiler optimizations.
##
## [param value] The float value to quantize
## [param precision] The quantization step (default 0.001)
## Returns: The quantized value
func _quantize(value: float, precision: float = DEFAULT_PRECISION) -> float:
    return snappedf(value, precision)


## Formats a value for serialization.
##
## [param value] The value to format
## Returns: A string representation
func _format_value(value: Variant) -> String:
    match typeof(value):
        TYPE_FLOAT:
            # Use consistent float formatting
            return "%.6f" % value
        TYPE_VECTOR2:
            var v: Vector2 = value
            return "(%.6f,%.6f)" % [v.x, v.y]
        TYPE_VECTOR2I:
            var vi: Vector2i = value
            return "(%d,%d)" % [vi.x, vi.y]
        TYPE_ARRAY:
            var arr: Array = value
            var parts: PackedStringArray = []
            for item in arr:
                parts.append(_format_value(item))
            return "[" + ",".join(parts) + "]"
        _:
            return str(value)


## Extracts simulation-level data.
##
## [param sim] The simulation node
## Returns: Dictionary of simulation data
func _extract_simulation_data(sim: Node) -> Dictionary:
    var data: Dictionary = {}
    data["tick"] = _get_safe_int(sim, "current_tick", 0)
    data["time"] = _quantize(_get_safe_float(sim, "simulation_time", 0.0))
    data["seed"] = _get_safe_int(sim, "random_seed", 0)
    data["paused"] = _get_safe_bool(sim, "is_paused", false)
    data["bot_count"] = _get_safe_int(sim, "bot_count", 0)
    data["proj_count"] = _get_safe_int(sim, "projectile_count", 0)
    return data


## Gets bots sorted by sim_id for deterministic iteration.
##
## [param sim] The simulation node
## Returns: Array of bot nodes sorted by ID
func _get_sorted_bots(sim: Node) -> Array:
    var bots: Array = []
    
    # Try common bot container names
    var container_names: PackedStringArray = ["bots", "Bots", "bot_container", "BotContainer"]
    var container: Node = null
    
    for name in container_names:
        if sim.has_node(name):
            container = sim.get_node(name)
            break
    
    if container == null:
        # Search all children for bots
        for child in sim.get_children():
            if child.has_method("is_bot") or child.has_meta("is_bot"):
                bots.append(child)
    else:
        bots = container.get_children()
    
    # Sort by sim_id for deterministic order
    bots.sort_custom(func(a: Node, b: Node) -> bool:
        var id_a: int = _get_safe_int(a, "sim_id", 0)
        var id_b: int = _get_safe_int(b, "sim_id", 0)
        return id_a < id_b
    )
    
    return bots


## Gets projectiles sorted by sim_id for deterministic iteration.
##
## [param sim] The simulation node
## Returns: Array of projectile nodes sorted by ID
func _get_sorted_projectiles(sim: Node) -> Array:
    var projectiles: Array = []
    
    var container_names: PackedStringArray = ["projectiles", "Projectiles", "projectile_container"]
    var container: Node = null
    
    for name in container_names:
        if sim.has_node(name):
            container = sim.get_node(name)
            break
    
    if container != null:
        projectiles = container.get_children()
    else:
        for child in sim.get_children():
            if child.has_method("is_projectile") or child.has_meta("is_projectile"):
                projectiles.append(child)
    
    # Sort by sim_id for deterministic order
    projectiles.sort_custom(func(a: Node, b: Node) -> bool:
        var id_a: int = _get_safe_int(a, "sim_id", 0)
        var id_b: int = _get_safe_int(b, "sim_id", 0)
        return id_a < id_b
    )
    
    return projectiles


## Gets effects sorted for deterministic iteration.
##
## [param sim] The simulation node
## Returns: Array of effect nodes sorted by ID
func _get_sorted_effects(sim: Node) -> Array:
    var effects: Array = []
    
    var container_names: PackedStringArray = ["effects", "Effects", "particles", "Particles"]
    var container: Node = null
    
    for name in container_names:
        if sim.has_node(name):
            container = sim.get_node(name)
            break
    
    if container != null:
        effects = container.get_children()
    
    effects.sort_custom(func(a: Node, b: Node) -> bool:
        var id_a: int = _get_safe_int(a, "sim_id", 0)
        var id_b: int = _get_safe_int(b, "sim_id", 0)
        return id_a < id_b
    )
    
    return effects


## Serializes an effect for hashing.
##
## [param effect] The effect node
## Returns: String representation
func _serialize_effect(effect: Node) -> String:
    var data: Dictionary = {}
    data["id"] = _get_safe_int(effect, "sim_id", -1)
    data["type"] = _get_safe_string(effect, "effect_type", "unknown")
    data["lifetime"] = _quantize(_get_safe_float(effect, "lifetime", 0.0))
    
    var pos: Vector2 = _get_safe_vector2(effect, "position", Vector2.ZERO)
    data["pos_x"] = _quantize(pos.x)
    data["pos_y"] = _quantize(pos.y)
    
    return "effect:" + _serialize_dict(data)


## Converts bytes to hexadecimal string.
##
## [param bytes] The byte array
## Returns: Hexadecimal string
func _bytes_to_hex(bytes: PackedByteArray) -> String:
    var hex: String = ""
    for b in bytes:
        hex += "%02x" % b
    return hex


# Safe property getters with defaults

func _get_safe_int(node: Node, property: String, default: int) -> int:
    if node == null:
        return default
    if property in node:
        var val: Variant = node.get(property)
        if typeof(val) == TYPE_INT:
            return val
    return default


func _get_safe_float(node: Node, property: String, default: float) -> float:
    if node == null:
        return default
    if property in node:
        var val: Variant = node.get(property)
        if typeof(val) == TYPE_FLOAT:
            return val
    return default


func _get_safe_bool(node: Node, property: String, default: bool) -> bool:
    if node == null:
        return default
    if property in node:
        var val: Variant = node.get(property)
        if typeof(val) == TYPE_BOOL:
            return val
    return default


func _get_safe_string(node: Node, property: String, default: String) -> String:
    if node == null:
        return default
    if property in node:
        var val: Variant = node.get(property)
        if typeof(val) == TYPE_STRING:
            return val
    return default


func _get_safe_vector2(node: Node, property: String, default: Vector2) -> Vector2:
    if node == null:
        return default
    if property in node:
        var val: Variant = node.get(property)
        if typeof(val) == TYPE_VECTOR2:
            return val
    return default
