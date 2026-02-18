extends Node
## DataLoader singleton — loads and caches all JSON content at startup.
## Delegates to src/managers/data_loader.gd (RefCounted) for core logic.

const DataLoaderCore := preload("res://src/managers/data_loader.gd")

var _core: RefCounted


func _ready() -> void:
	_core = DataLoaderCore.new()
	_core.load_all()


# --- Parts ---

func get_part(id: String) -> Variant:
	return _core.get_part(id)

func get_all_parts() -> Array:
	return _core.get_all_parts()


# --- Arenas ---

func get_arena(id: String) -> Variant:
	return _core.get_arena(id)

func get_all_arenas() -> Array:
	return _core.get_all_arenas()


# --- Bots ---

func get_bot(id: String) -> Variant:
	return _core.get_bot(id)

func get_all_bots() -> Array:
	return _core.get_all_bots()


# --- Enemies ---

func get_enemy(id: String) -> Variant:
	return _core.get_enemy(id)

func get_all_enemies() -> Array:
	return _core.get_all_enemies()


# --- Campaign ---

func get_campaign_node(id: String) -> Variant:
	return _core.get_campaign_node(id)

func get_all_campaign_nodes() -> Array:
	return _core.get_all_campaign_nodes()


# --- Economy ---

func get_economy_config() -> Dictionary:
	return _core.get_economy_config()


# --- Direct access (for tests or advanced use) ---

func get_core() -> RefCounted:
	return _core
