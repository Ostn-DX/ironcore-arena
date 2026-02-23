extends Node
## GameManager - Central game state coordinator
## Part of Studio Architecture: Core Systems

signal game_state_changed(new_state: GameState)
signal level_loaded(level_name: String)
signal game_paused(is_paused: bool)
signal game_quit_requested

enum GameState {
	MAIN_MENU,
	HANGAR,
	SHOP,
	ARENA_SELECT,
	BATTLE_LOADING,
	BATTLE_ACTIVE,
	BATTLE_PAUSED,
	BATTLE_ENDED,
	RESULTS_SCREEN,
	SETTINGS,
	QUITTING
}

# Current State
var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU
var current_level: String = ""
var play_time_seconds: float = 0.0

# Debug
var is_debug_mode: bool = OS.is_debug_build()
var is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("GameManager: Initialized")
	
	# Connect to EventBus
	EventBus.pause_requested.connect(_on_pause_requested)
	EventBus.resume_requested.connect(_on_resume_requested)

func _process(delta: float) -> void:
	if current_state == GameState.BATTLE_ACTIVE and not is_paused:
		play_time_seconds += delta

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	var old_state = current_state
	previous_state = old_state
	current_state = new_state
	
	_handle_state_exit(old_state)
	_handle_state_enter(new_state)
	
	emit_signal("game_state_changed", new_state)
	print("Game state: %s -> %s" % [_state_to_string(old_state), _state_to_string(new_state)])

func _handle_state_enter(state: GameState) -> void:
	match state:
		GameState.BATTLE_ACTIVE:
			is_paused = false
			get_tree().paused = false
		GameState.BATTLE_PAUSED:
			is_paused = true
			get_tree().paused = true
		GameState.QUITTING:
			_save_before_quit()
			emit_signal("game_quit_requested")

func _handle_state_exit(state: GameState) -> void:
	match state:
		GameState.BATTLE_ACTIVE:
			# Save battle stats, etc.
			pass

func _on_pause_requested() -> void:
	if current_state == GameState.BATTLE_ACTIVE:
		change_state(GameState.BATTLE_PAUSED)
		emit_signal("game_paused", true)

func _on_resume_requested() -> void:
	if current_state == GameState.BATTLE_PAUSED:
		change_state(GameState.BATTLE_ACTIVE)
		emit_signal("game_paused", false)

func load_scene(scene_path: String, params: Dictionary = {}) -> void:
	## Async scene loading with loading screen
	change_state(GameState.BATTLE_LOADING)
	
	# Show loading screen
	EventBus.transition_started.emit("loading")
	
	# Async load
	ResourceLoader.load_threaded_request(scene_path)
	
	while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	
	var packed_scene = ResourceLoader.load_threaded_get(scene_path)
	
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
		current_level = scene_path
		EventBus.scene_loaded.emit(scene_path.get_file().get_basename())
		EventBus.transition_completed.emit("loading")
	else:
		push_error("GameManager: Failed to load scene: %s" % scene_path)
		change_state(GameState.MAIN_MENU)

func quit_game() -> void:
	change_state(GameState.QUITTING)

func _save_before_quit() -> void:
	if SaveManager:
		SaveManager.save_game()

func get_play_time_formatted() -> String:
	var hours: int = int(play_time_seconds / 3600)
	var minutes: int = int((play_time_seconds % 3600) / 60)
	var seconds: int = int(play_time_seconds % 60)
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _state_to_string(state: GameState) -> String:
	return GameState.keys()[state]

# ============================================================================
# CONVENIENCE METHODS
# ============================================================================

func is_in_battle() -> bool:
	return current_state in [GameState.BATTLE_ACTIVE, GameState.BATTLE_PAUSED]

func can_pause() -> bool:
	return current_state == GameState.BATTLE_ACTIVE

func get_state_name() -> String:
	return _state_to_string(current_state)
