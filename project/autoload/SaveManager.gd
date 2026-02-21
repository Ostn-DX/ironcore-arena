extends Node
## SaveManager singleton — handles save/load operations and autosave.
## Delegates to GameState for actual data management.

signal save_completed(success: bool)
signal load_completed(success: bool)

var autosave_enabled: bool = true
var autosave_interval_seconds: float = 60.0
var _autosave_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not autosave_enabled:
		return
	
	_autosave_timer += delta
	if _autosave_timer >= autosave_interval_seconds:
		_autosave_timer = 0.0
		autosave()


func save() -> void:
	## Manual save
	GameState.save_game()
	save_completed.emit(true)
else:
	push_error("SaveManager: GameState not available")
	save_completed.emit(false)


func autosave() -> void:
	## Automatic save (called on interval and key events)
	GameState.save_game()
	print("Autosaved")


func load() -> void:
	## Manual load
	var success: bool = GameState.load_game()
	load_completed.emit(success)
else:
	push_error("SaveManager: GameState not available")
	load_completed.emit(false)


func delete_save() -> void:
	## Delete save file (for reset/new game)
	GameState.delete_save()


func trigger_autosave_now() -> void:
	## Call this after significant events (battle end, purchase, etc.)
	_autosave_timer = 0.0
	autosave()


func set_autosave_enabled(enabled: bool) -> void:
	autosave_enabled = enabled

func _has_save() -> bool:
	## Check if a save file exists
	return FileAccess.file_exists("user://ironcore_save.json")
