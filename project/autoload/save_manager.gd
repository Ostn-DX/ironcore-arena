extends Node
## SaveManager - Persistent data management
## Part of Studio Architecture: Core Systems

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_deleted(slot: int)
signal save_error(error_message: String)

const SAVE_PATH: String = "user://saves/"
const SAVE_EXTENSION: String = ".sav"
const MAX_SAVE_SLOTS: int = 5
const SAVE_VERSION: String = "1.0.0"

var current_save_slot: int = 0
var current_save_data: Dictionary = {}
var is_saving: bool = false
var is_loading: bool = false

func _ready() -> void:
	_ensure_save_directory()
	print("SaveManager: Initialized")

func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir:
		push_error("SaveManager: Cannot access user directory")
		return
	
	if not dir.dir_exists("saves"):
		var err = dir.make_dir("saves")
		if err != OK:
			push_error("SaveManager: Failed to create saves directory")

func save_game(slot: int = 0) -> Error:
	if is_saving:
		push_warning("SaveManager: Save already in progress")
		return ERR_BUSY
	
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("SaveManager: Invalid save slot: %d" % slot)
		return ERR_INVALID_PARAMETER
	
	is_saving = true
	current_save_slot = slot
	
	# Collect all save data
	var save_data = _collect_save_data()
	
	# Serialize
	var json_string = JSON.stringify(save_data, "\t")
	
	# Write to file
	var file_path = _get_save_path(slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		is_saving = false
		var err = FileAccess.get_open_error()
		push_error("SaveManager: Failed to open save file: %s (Error: %d)" % [file_path, err])
		emit_signal("save_error", "Failed to open save file")
		return err
	
	file.store_string(json_string)
	file.close()
	
	is_saving = false
	current_save_data = save_data
	
	print("SaveManager: Game saved to slot %d" % slot)
	emit_signal("save_completed", slot)
	
	return OK

func load_game(slot: int = 0) -> Error:
	if is_loading:
		push_warning("SaveManager: Load already in progress")
		return ERR_BUSY
	
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		push_warning("SaveManager: Save file not found: %s" % file_path)
		return ERR_FILE_NOT_FOUND
	
	is_loading = true
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		is_loading = false
		var err = FileAccess.get_open_error()
		push_error("SaveManager: Failed to open save file: %s (Error: %d)" % [file_path, err])
		emit_signal("save_error", "Failed to open save file")
		return err
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		is_loading = false
		push_error("SaveManager: Failed to parse save file: %s" % json.get_error_message())
		emit_signal("save_error", "Corrupted save file")
		return ERR_INVALID_DATA
	
	var save_data = json.data
	
	# Version check
	if save_data.has("version"):
		if save_data.version != SAVE_VERSION:
			print("SaveManager: Save version mismatch (%s vs %s), attempting migration" % [save_data.version, SAVE_VERSION])
			save_data = _migrate_save_data(save_data)
	
	# Apply save data
	_apply_save_data(save_data)
	
	is_loading = false
	current_save_slot = slot
	current_save_data = save_data
	
	print("SaveManager: Game loaded from slot %d" % slot)
	emit_signal("load_completed", slot)
	
	return OK

func delete_save(slot: int) -> Error:
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		return ERR_FILE_NOT_FOUND
	
	var err = DirAccess.remove_absolute(file_path)
	if err != OK:
		push_error("SaveManager: Failed to delete save file: %s" % file_path)
		return err
	
	print("SaveManager: Save deleted from slot %d" % slot)
	emit_signal("save_deleted", slot)
	
	return OK

func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))

func get_save_info(slot: int) -> Dictionary:
	if not save_exists(slot):
		return {"exists": false}
	
	var file_path = _get_save_path(slot)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		return {"exists": false, "error": "Cannot read file"}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {"exists": true, "error": "Corrupted file"}
	
	var save_data = json.data
	
	return {
		"exists": true,
		"timestamp": save_data.get("timestamp", 0),
		"play_time": save_data.get("play_time", 0),
		"credits": save_data.get("credits", 0),
		"current_tier": save_data.get("current_tier", 0),
		"version": save_data.get("version", "unknown")
	}

func get_all_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	for i in range(MAX_SAVE_SLOTS):
		saves.append(get_save_info(i))
	return saves

func _get_save_path(slot: int) -> String:
	return SAVE_PATH + "save_%d%s" % [slot, SAVE_EXTENSION]

func _collect_save_data() -> Dictionary:
	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": GameManager.play_time_seconds if GameManager else 0.0,
	}
	
	# GameState data
	if GameState:
		save_data["credits"] = GameState.credits
		save_data["current_tier"] = GameState.current_tier
		save_data["unlocked_arenas"] = GameState.unlocked_arenas
		save_data["unlocked_components"] = GameState.unlocked_components
		save_data["loadouts"] = GameState.loadouts
		save_data["current_loadout_index"] = GameState.current_loadout_index
	else:
		push_warning("SaveManager: GameState not available")
	
	return save_data

func _apply_save_data(save_data: Dictionary) -> void:
	if not GameState:
		push_warning("SaveManager: Cannot apply save - GameState not available")
		return
	
	# Apply GameState data
	if save_data.has("credits"):
		GameState.credits = save_data.credits
	if save_data.has("current_tier"):
		GameState.current_tier = save_data.current_tier
	if save_data.has("unlocked_arenas"):
		GameState.unlocked_arenas = save_data.unlocked_arenas
	if save_data.has("unlocked_components"):
		GameState.unlocked_components = save_data.unlocked_components
	if save_data.has("loadouts"):
		GameState.loadouts = save_data.loadouts
	if save_data.has("current_loadout_index"):
		GameState.current_loadout_index = save_data.current_loadout_index
	
	# Apply play time
	if save_data.has("play_time") and GameManager:
		GameManager.play_time_seconds = save_data.play_time

func _migrate_save_data(old_data: Dictionary) -> Dictionary:
	## Handle save data migration between versions
	var version = old_data.get("version", "0.0.0")
	
	# Add migration logic here as versions change
	if version == "0.9.0":
		# Example: migrate from 0.9.0 to 1.0.0
		old_data["unlocked_components"] = []
		old_data["version"] = "1.0.0"
	
	return old_data

func auto_save() -> void:
	## Quick save to slot 0 (auto-save slot)
	save_game(0)

func export_save_to_json(slot: int) -> String:
	## Export save data as JSON string (for debugging/backup)
	var info = get_save_info(slot)
	if not info.exists:
		return "{}"
	
	var file_path = _get_save_path(slot)
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return "{}"
	
	return file.get_as_text()
