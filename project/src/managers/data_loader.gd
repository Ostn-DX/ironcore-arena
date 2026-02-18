extends RefCounted
## DataLoader core logic — JSON parsing and data caching.
## Loads all vertical-slice JSON files and indexes them by id.

const DATA_DIR: String = "res://data/slice/"

const _FILE_MAP: Dictionary = {
	"parts": "parts_slice.json",
	"bots": "bots_slice.json",
	"arenas": "arenas_slice.json",
	"enemies": "enemies_slice.json",
	"campaign": "campaign_slice.json",
	"economy": "economy_slice.json",
}

var parts_by_id: Dictionary = {}
var arenas_by_id: Dictionary = {}
var bots_by_id: Dictionary = {}
var enemies_by_id: Dictionary = {}
var campaign_by_id: Dictionary = {}
var economy_config: Dictionary = {}

var _loaded: bool = false


func load_all() -> void:
	if _loaded:
		return
	_load_array_file("parts", "parts_by_id")
	_load_array_file("arenas", "arenas_by_id")
	_load_array_file("bots", "bots_by_id")
	_load_array_file("enemies", "enemies_by_id")
	_load_array_file("campaign", "campaign_by_id")
	_load_economy()
	_loaded = true


# --- Parts ---

func get_part(id: String) -> Variant:
	return parts_by_id.get(id, null)

func get_all_parts() -> Array:
	return parts_by_id.values()


# --- Arenas ---

func get_arena(id: String) -> Variant:
	return arenas_by_id.get(id, null)

func get_all_arenas() -> Array:
	return arenas_by_id.values()


# --- Bots ---

func get_bot(id: String) -> Variant:
	return bots_by_id.get(id, null)

func get_all_bots() -> Array:
	return bots_by_id.values()


# --- Enemies ---

func get_enemy(id: String) -> Variant:
	return enemies_by_id.get(id, null)

func get_all_enemies() -> Array:
	return enemies_by_id.values()


# --- Campaign ---

func get_campaign_node(id: String) -> Variant:
	return campaign_by_id.get(id, null)

func get_all_campaign_nodes() -> Array:
	return campaign_by_id.values()


# --- Economy ---

func get_economy_config() -> Dictionary:
	return economy_config


# --- Internal helpers ---

func _load_array_file(key: String, dict_property: String) -> void:
	var rel: String = String(_FILE_MAP.get(key, ""))
	if rel.is_empty():
		push_error("DataLoader: missing file mapping for key: %s" % key)
		return

	var path: String = DATA_DIR + rel
	var json_text: String = _read_file(path)
	if json_text.is_empty():
		return

	var parsed_v: Variant = _parse_json(json_text, path)
	if parsed_v == null:
		return

	if not (parsed_v is Array):
		push_error("DataLoader: expected Array in '%s', got %s" % [path, typeof(parsed_v)])
		return

	var parsed: Array = parsed_v as Array
	var dict_v: Variant = get(dict_property)
	if not (dict_v is Dictionary):
		push_error("DataLoader: property '%s' is not a Dictionary" % dict_property)
		return

	var dict: Dictionary = dict_v as Dictionary
	for entry_v in parsed:
		if entry_v is Dictionary:
			var entry: Dictionary = entry_v as Dictionary
			if entry.has("id"):
				dict[String(entry["id"])] = entry
			else:
				push_error("DataLoader: entry in '%s' missing 'id' field" % path)
		else:
			push_error("DataLoader: non-dictionary entry in '%s'" % path)


func _load_economy() -> void:
	var rel: String = String(_FILE_MAP.get("economy", ""))
	if rel.is_empty():
		push_error("DataLoader: missing file mapping for key: economy")
		return

	var path: String = DATA_DIR + rel
	var json_text: String = _read_file(path)
	if json_text.is_empty():
		return

	var parsed_v: Variant = _parse_json(json_text, path)
	if parsed_v == null:
		return

	if not (parsed_v is Dictionary):
		push_error("DataLoader: expected Dictionary in '%s', got %s" % [path, typeof(parsed_v)])
		return

	economy_config = parsed_v as Dictionary


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
