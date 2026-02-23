extends RefCounted
## DataLoader core logic - JSON parsing and data caching.
## Loads component database and provides indexed access.

const COMPONENTS_PATH: String = "res://../data/components.json"

var chassis_by_id: Dictionary = {}
var plating_by_id: Dictionary = {}
var weapons_by_id: Dictionary = {}
var arenas_by_id: Dictionary = {}

var _loaded: bool = false


func load_all() -> void:
	if _loaded:
		return
	
	var json_text: String = _read_file(COMPONENTS_PATH)
	if json_text.is_empty():
		push_error("DataLoader: failed to load components.json")
		return
	
	var parsed: Variant = _parse_json(json_text, COMPONENTS_PATH)
	if parsed == null or not (parsed is Dictionary):
		push_error("DataLoader: components.json is invalid")
		return
	
	var data: Dictionary = parsed as Dictionary
	
	# Index chassis
	if data.has("chassis"):
		for entry in data["chassis"]:
			if entry is Dictionary and entry.has("id"):
				chassis_by_id[String(entry["id"])] = entry
	
	# Index plating
	if data.has("plating"):
		for entry in data["plating"]:
			if entry is Dictionary and entry.has("id"):
				plating_by_id[String(entry["id"])] = entry
	
	# Index weapons
	if data.has("weapons"):
		for entry in data["weapons"]:
			if entry is Dictionary and entry.has("id"):
				weapons_by_id[String(entry["id"])] = entry
	
	# Index arenas
	if data.has("arenas"):
		for entry in data["arenas"]:
			if entry is Dictionary and entry.has("id"):
				arenas_by_id[String(entry["id"])] = entry
	
	_loaded = true
	print("DataLoader: Loaded %d chassis, %d plating, %d weapons, %d arenas" % [
		chassis_by_id.size(), plating_by_id.size(), weapons_by_id.size(), arenas_by_id.size()
	])


# --- Chassis ---

func get_chassis(id: String) -> Dictionary:
	return chassis_by_id.get(id, {})

func get_all_chassis() -> Array:
	return chassis_by_id.values()

func get_chassis_by_tier(tier: int) -> Array:
	var result: Array = []
	for chassis in chassis_by_id.values():
		if chassis is Dictionary and chassis.get("tier", -1) == tier:
			result.append(chassis)
	return result


# --- Plating ---

func get_plating(id: String) -> Dictionary:
	return plating_by_id.get(id, {})

func get_all_plating() -> Array:
	return plating_by_id.values()

func get_plating_by_tier(tier: int) -> Array:
	var result: Array = []
	for plating in plating_by_id.values():
		if plating is Dictionary and plating.get("tier", -1) == tier:
			result.append(plating)
	return result


# --- Weapons ---

func get_weapon(id: String) -> Dictionary:
	return weapons_by_id.get(id, {})

func get_all_weapons() -> Array:
	return weapons_by_id.values()

func get_weapons_by_tier(tier: int) -> Array:
	var result: Array = []
	for weapon in weapons_by_id.values():
		if weapon is Dictionary and weapon.get("tier", -1) == tier:
			result.append(weapon)
	return result


# --- Arenas ---

func get_arena(id: String) -> Dictionary:
	return arenas_by_id.get(id, {})

func get_all_arenas() -> Array:
	return arenas_by_id.values()

func get_arenas_by_tier(tier: int) -> Array:
	var result: Array = []
	for arena in arenas_by_id.values():
		if arena is Dictionary and arena.get("tier", -1) == tier:
			result.append(arena)
	return result


# --- Component helpers ---

func get_components_unlocked_at_tier(tier: int) -> Dictionary:
	return {
		"chassis": get_chassis_by_tier(tier),
		"plating": get_plating_by_tier(tier),
		"weapons": get_weapons_by_tier(tier)
	}

func component_exists(id: String) -> bool:
	return chassis_by_id.has(id) or plating_by_id.has(id) or weapons_by_id.has(id)


# --- Internal helpers ---

func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: file not found: %s" % path)
		return ""

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataLoader: cannot open file: %s (error %d)" % [path, FileAccess.get_open_error()])
		return ""

	return file.get_as_text()


func _parse_json(text: String, path: String) -> Variant:
	var json: JSON = JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("DataLoader: JSON parse error in '%s' at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()
		])
		return null
	return json.data
