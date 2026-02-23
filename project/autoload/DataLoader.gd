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
		return part
	
	part = get_plating(id)
	if not part.is_empty():
		return part
	
	part = get_weapon(id)
	if not part.is_empty():
		return part
	
	return {}
