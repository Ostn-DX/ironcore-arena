extends Node
## GameState singleton — holds player profile: owned parts, credits,
## loadouts, completed arenas, campaign progress. Emits signals on change.

signal credits_changed(new_amount: int)
signal parts_changed()
signal loadouts_changed()
signal arena_completed(arena_id: String)
signal campaign_progress_changed()

# Player economy
var credits: int = 500:
	set(value):
		credits = maxi(0, value)
		credits_changed.emit(credits)

# Owned parts: part_id -> quantity
var owned_parts: Dictionary = {}

# Part HP tracking for damaged parts (optional for repair mechanics)
var part_hp: Dictionary = {}

# Bot loadouts
var loadouts: Array[Dictionary] = []

# Progress
var completed_arenas: Array[String] = []
var campaign_progress: Dictionary = {"main": []}

# Current active loadout IDs for battle
var active_loadout_ids: Array[String] = []

# Settings
var settings: Dictionary = {
	"master_volume": 0.8,
	"sfx_volume": 1.0,
	"music_volume": 0.5,
	"ui_scale": 1.0,
	"sim_speed": 1.0,
	"colorblind_mode": "none"
}

# Game mode: "campaign" or "arcade"
var game_mode: String = "campaign"

const SAVE_PATH: String = "user://ironcore_save.json"
const CURRENT_VERSION: String = "0.1.0"


func _ready() -> void:
	load_game()
	
	# Give starter parts if new game
	if owned_parts.is_empty():
		_give_starter_kit()


func _give_starter_kit() -> void:
	## Give new player starting equipment
	credits = 500
	
	# Starter parts
	owned_parts = {
		"chassis_light_t1": 2,
		"wpn_mg_t1": 4,
		"arm_plate_t1": 2,
		"mob_wheels_t1": 2,
		"sen_basic_t1": 2,
		"utl_repair_t1": 1
	}
	
	# Default loadout
	loadouts = [
		{
			"id": "loadout_1",
			"name": "Starter Scout",
			"chassis": "chassis_light_t1",
			"weapons": ["wpn_mg_t1"],
			"armor": [],
			"mobility": ["mob_wheels_t1"],
			"sensors": ["sen_basic_t1"],
			"utilities": [],
			"ai_profile": "ai_balanced"
		}
	]
	
	active_loadout_ids = ["loadout_1"]
	
	parts_changed.emit()
	loadouts_changed.emit()
	save_game()


func add_credits(amount: int) -> void:
	credits += amount


func spend_credits(amount: int) -> bool:
	if credits >= amount:
		credits -= amount
		return true
	return false


func add_part(part_id: String, quantity: int = 1) -> void:
	if not owned_parts.has(part_id):
		owned_parts[part_id] = 0
	owned_parts[part_id] += quantity
	parts_changed.emit()


func remove_part(part_id: String, quantity: int = 1) -> bool:
	if not owned_parts.has(part_id) or owned_parts[part_id] < quantity:
		return false
	owned_parts[part_id] -= quantity
	if owned_parts[part_id] <= 0:
		owned_parts.erase(part_id)
	parts_changed.emit()
	return true


func has_part(part_id: String, quantity: int = 1) -> bool:
	return owned_parts.get(part_id, 0) >= quantity


func get_part_quantity(part_id: String) -> int:
	return owned_parts.get(part_id, 0)


func add_loadout(loadout: Dictionary) -> void:
	# Validate loadout has required fields
	if not loadout.has("id") or not loadout.has("name"):
		push_error("Invalid loadout: missing id or name")
		return
	
	# Remove existing loadout with same ID
	for i in range(loadouts.size()):
		if loadouts[i].get("id") == loadout["id"]:
			loadouts.remove_at(i)
			break
	
	loadouts.append(loadout)
	loadouts_changed.emit()


func remove_loadout(loadout_id: String) -> bool:
	for i in range(loadouts.size()):
		if loadouts[i].get("id") == loadout_id:
			loadouts.remove_at(i)
			loadouts_changed.emit()
			return true
	return false


func get_loadout(loadout_id: String) -> Dictionary:
	for loadout in loadouts:
		if loadout.get("id") == loadout_id:
			return loadout
	return {}


func set_active_loadouts(loadout_ids: Array[String]) -> void:
	active_loadout_ids = loadout_ids.duplicate()


func get_active_loadouts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in active_loadout_ids:
		var loadout = get_loadout(id)
		if not loadout.is_empty():
			result.append(loadout)
	return result


func complete_arena(arena_id: String) -> void:
	if not completed_arenas.has(arena_id):
		completed_arenas.append(arena_id)
		arena_completed.emit(arena_id)


func is_arena_completed(arena_id: String) -> bool:
	return completed_arenas.has(arena_id)


func unlock_campaign_node(node_id: String) -> void:
	var main_path: Array = campaign_progress.get("main", [])
	if not main_path.has(node_id):
		main_path.append(node_id)
		campaign_progress["main"] = main_path
		campaign_progress_changed.emit()


func set_game_mode(mode: String) -> void:
	game_mode = mode
	if mode == "arcade":
		# Arcade: free purchases, unlimited credits
		credits = 999999
	else:
		# Campaign: normal economy, give starter kit if new
		if owned_parts.is_empty():
			_give_starter_kit()

func _unlock_all_parts() -> void:
	## DEPRECATED: Arcade mode now just sets credits high for free purchases
	pass

func is_arcade_mode() -> bool:
	return game_mode == "arcade"

func is_campaign_mode() -> bool:
	return game_mode == "campaign"


# --- Save / Load ---

func save_game() -> void:
	var save_data: Dictionary = {
		"version": CURRENT_VERSION,
		"credits": credits,
		"owned_parts": owned_parts,
		"part_hp": part_hp,
		"loadouts": loadouts,
		"active_loadout_ids": active_loadout_ids,
		"completed_arenas": completed_arenas,
		"campaign_progress": campaign_progress,
		"settings": settings
	}
	
	var json_text: String = JSON.stringify(save_data, "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		print("Game saved to ", SAVE_PATH)
	else:
		push_error("Failed to save game: ", FileAccess.get_open_error())


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, starting new game")
		return false
	
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to load save: ", FileAccess.get_open_error())
		return false
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var err: int = json.parse(json_text)
	if err != OK:
		push_error("Save file JSON parse error: ", json.get_error_message())
		return false
	
	var data: Dictionary = json.data
	
	# Version check / migration could go here
	var version: String = data.get("version", "0.0.0")
	
	credits = data.get("credits", 500)
	owned_parts = data.get("owned_parts", {})
	part_hp = data.get("part_hp", {})
	
	# Convert loaded arrays to typed arrays
	var loaded_loadouts: Array = data.get("loadouts", [])
	loadouts.clear()
	for item in loaded_loadouts:
		if item is Dictionary:
			loadouts.append(item)
	
	var loaded_active_ids: Array = data.get("active_loadout_ids", [])
	active_loadout_ids.clear()
	for item in loaded_active_ids:
		if item is String:
			active_loadout_ids.append(item)
	
	var loaded_completed: Array = data.get("completed_arenas", [])
	completed_arenas.clear()
	for item in loaded_completed:
		if item is String:
			completed_arenas.append(item)
	
	campaign_progress = data.get("campaign_progress", {"main": []})
	settings = data.get("settings", settings)
	
	print("Game loaded, version: ", version)
	return true


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save file deleted")
