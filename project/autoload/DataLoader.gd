extends Node
## DataLoader singleton - loads and caches all game data at startup.
## Provides indexed access to chassis, plating, weapons, and arenas.

const DataLoaderCore := preload("res://src/managers/data_loader.gd")

var _core: RefCounted


func _ready() -> void:
	_core = DataLoaderCore.new()
	_core.load_all()


# --- Chassis ---

func get_chassis(id: String) -> Dictionary:
	return _core.get_chassis(id)

func get_all_chassis() -> Array:
	return _core.get_all_chassis()

func get_chassis_by_tier(tier: int) -> Array:
	return _core.get_chassis_by_tier(tier)


# --- Plating ---

func get_plating(id: String) -> Dictionary:
	return _core.get_plating(id)

func get_all_plating() -> Array:
	return _core.get_all_plating()

func get_plating_by_tier(tier: int) -> Array:
	return _core.get_plating_by_tier(tier)


# --- Weapons ---

func get_weapon(id: String) -> Dictionary:
	return _core.get_weapon(id)

func get_all_weapons() -> Array:
	return _core.get_all_weapons()

func get_weapons_by_tier(tier: int) -> Array:
	return _core.get_weapons_by_tier(tier)


# --- Arenas ---

func get_arena(id: String) -> Dictionary:
	return _core.get_arena(id)

func get_all_arenas() -> Array:
	return _core.get_all_arenas()

func get_arenas_by_tier(tier: int) -> Array:
	return _core.get_arenas_by_tier(tier)


# --- Component helpers ---

func get_components_unlocked_at_tier(tier: int) -> Dictionary:
	return _core.get_components_unlocked_at_tier(tier)

func component_exists(id: String) -> bool:
	return _core.component_exists(id)

func get_part(id: String) -> Dictionary:
	## Get any part by ID - routes to correct type
	var part: Dictionary = get_chassis(id)
	if not part.is_empty():
		part["type"] = "chassis"
		return part
	
	part = get_plating(id)
	if not part.is_empty():
		part["type"] = "armor"
		return part
	
	part = get_weapon(id)
	if not part.is_empty():
		part["type"] = "weapon"
		return part
	
	return {}


## NEW: BuilderScreen compatibility methods

func get_all_parts() -> Dictionary:
	## Returns all parts unified as id -> data dictionary
	## Used by BuilderScreen for shop and inventory
	var all_parts: Dictionary = {}
	
	# Add all chassis
	for id in _core.chassis_by_id:
		var part: Dictionary = _core.chassis_by_id[id].duplicate()
		part["type"] = "chassis"
		all_parts[id] = part
	
	# Add all plating (armor)
	for id in _core.plating_by_id:
		var part: Dictionary = _core.plating_by_id[id].duplicate()
		part["type"] = "armor"
		all_parts[id] = part
	
	# Add all weapons
	for id in _core.weapons_by_id:
		var part: Dictionary = _core.weapons_by_id[id].duplicate()
		part["type"] = "weapon"
		all_parts[id] = part
	
	return all_parts


func get_part_data(id: String) -> Dictionary:
	## Alias for get_part() with guaranteed type field
	## Used by BuilderScreen for item details
	var part: Dictionary = get_part(id)
	
	# Ensure type field exists
	if not part.has("type"):
		part["type"] = "unknown"
	
	# Ensure required fields for BuilderScreen
	if not part.has("name"):
		part["name"] = id.capitalize()
	
	if not part.has("description"):
		part["description"] = "No description available."
	
	if not part.has("manufacturer"):
		part["manufacturer"] = "Unknown"
	
	# Add default stats if missing
	if not part.has("weight"):
		part["weight"] = 10
	
	if not part.has("damage") and part["type"] == "weapon":
		part["damage"] = 10
	
	if not part.has("armor") and part["type"] == "armor":
		part["armor"] = 5
	
	if not part.has("health") and part["type"] == "chassis":
		part["health"] = 100
	
	return part


func get_parts_by_type(part_type: String) -> Dictionary:
	## Filter parts by type: "chassis", "armor", or "weapon"
	var all_parts: Dictionary = get_all_parts()
	var filtered: Dictionary = {}
	
	for id in all_parts:
		if all_parts[id].get("type", "") == part_type:
			filtered[id] = all_parts[id]
	
	return filtered
