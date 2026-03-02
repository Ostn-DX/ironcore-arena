class_name HotReloadWatcher extends Node

## Watches for asset changes and triggers hot reload.
## Polls watched directories for file modifications.
## Only active in editor builds by default.

signal assets_changed

## Polling interval in seconds
const POLL_INTERVAL: float = 1.0

## Default paths to watch for changes
const WATCH_PATHS: PackedStringArray = [
    "res://assets/registry/",
    "res://assets/atlases/"
]

## File extensions to monitor
const WATCH_EXTENSIONS: PackedStringArray = [
    ".json",
    ".tres",
    ".png",
    ".jpg",
    ".jpeg",
    ".webp"
]

## Whether hot reload is enabled
@export var enabled: bool = true

## Whether to only enable in editor
@export var editor_only: bool = true

## Custom paths to watch (in addition to defaults)
@export var custom_watch_paths: PackedStringArray = []

## Enable verbose logging
@export var verbose: bool = false

var _registry: AssetRegistry = null
var _timer: float = 0.0
var _last_modified_times: Dictionary = {}  ## file_path -> modification_time
var _last_file_hashes: Dictionary = {}     ## file_path -> content_hash (optional)
var _is_initialized: bool = false
var _watched_paths: PackedStringArray = []


func _ready() -> void:
    _initialize()


func _initialize() -> void:
    if _is_initialized:
        return
    
    # Check if we should run
    if editor_only and not Engine.is_editor_hint():
        if verbose:
            print("HotReloadWatcher: Disabled in non-editor build")
        enabled = false
        set_process(false)
        return
    
    if not enabled:
        set_process(false)
        return
    
    # Build watch paths list
    _watched_paths = WATCH_PATHS.duplicate()
    for path in custom_watch_paths:
        if not path in _watched_paths:
            _watched_paths.append(path)
    
    # Get registry reference
    _registry = _get_registry()
    if not _registry:
        push_warning("HotReloadWatcher: AssetRegistry not found, hot reload disabled")
        enabled = false
        set_process(false)
        return
    
    # Initialize modification times
    _scan_all_files()
    
    _is_initialized = true
    set_process(true)
    
    print("HotReloadWatcher: Initialized, watching ", _watched_paths.size(), " paths")


func _process(delta: float) -> void:
    if not enabled:
        return
    
    _timer += delta
    if _timer >= POLL_INTERVAL:
        _timer = 0.0
        _check_for_changes()


## Checks all watched paths for file changes.
func _check_for_changes() -> void:
    var changed_files: PackedStringArray = []
    
    for path in _watched_paths:
        var dir := DirAccess.open(path)
        if not dir:
            if verbose:
                push_warning("HotReloadWatcher: Cannot open directory: " + path)
            continue
        
        dir.list_dir_begin()
        var file_name := dir.get_next()
        
        while file_name != "":
            # Skip directories
            if dir.current_is_dir():
                file_name = dir.get_next()
                continue
            
            # Check extension
            var has_valid_extension := false
            for ext in WATCH_EXTENSIONS:
                if file_name.ends_with(ext):
                    has_valid_extension = true
                    break
            
            if not has_valid_extension:
                file_name = dir.get_next()
                continue
            
            var full_path := path + file_name
            var modified := FileAccess.get_modified_time(full_path)
            
            if _last_modified_times.has(full_path):
                if _last_modified_times[full_path] != modified:
                    changed_files.append(full_path)
                    if verbose:
                        print("HotReloadWatcher: Change detected in ", full_path)
            
            _last_modified_times[full_path] = modified
            file_name = dir.get_next()
        
        dir.list_dir_end()
    
    # Reload if changes detected
    if changed_files.size() > 0:
        if verbose:
            print("HotReloadWatcher: ", changed_files.size(), " file(s) changed")
        _perform_reload()


## Scans all watched directories and records initial file states.
func _scan_all_files() -> void:
    _last_modified_times.clear()
    
    for path in _watched_paths:
        var dir := DirAccess.open(path)
        if not dir:
            continue
        
        dir.list_dir_begin()
        var file_name := dir.get_next()
        
        while file_name != "":
            if dir.current_is_dir():
                file_name = dir.get_next()
                continue
            
            var full_path := path + file_name
            var modified := FileAccess.get_modified_time(full_path)
            _last_modified_times[full_path] = modified
            
            file_name = dir.get_next()
        
        dir.list_dir_end()
    
    if verbose:
        print("HotReloadWatcher: Scanned ", _last_modified_times.size(), " files")


## Performs the actual reload operation.
func _perform_reload() -> void:
    if not _registry:
        _registry = _get_registry()
    
    if _registry:
        print("HotReloadWatcher: Changes detected, reloading assets...")
        _registry.reload()
        assets_changed.emit()
    else:
        push_warning("HotReloadWatcher: Cannot reload, AssetRegistry not available")


## Forces an immediate reload.
func force_reload() -> void:
    if not _is_initialized:
        _initialize()
    
    _perform_reload()


## Adds a custom path to watch.
## @param path The directory path to watch
func add_watch_path(path: String) -> void:
    if not path in _watched_paths:
        _watched_paths.append(path)
        if verbose:
            print("HotReloadWatcher: Added watch path: " + path)


## Removes a watch path.
## @param path The directory path to remove
func remove_watch_path(path: String) -> void:
    if path in _watched_paths:
        _watched_paths.remove_at(_watched_paths.find(path))
        if verbose:
            print("HotReloadWatcher: Removed watch path: " + path)


## Gets all currently watched paths.
## @return PackedStringArray of watched paths
func get_watch_paths() -> PackedStringArray:
    return _watched_paths.duplicate()


## Clears all watch paths.
func clear_watch_paths() -> void:
    _watched_paths.clear()


## Resets to default watch paths.
func reset_watch_paths() -> void:
    _watched_paths = WATCH_PATHS.duplicate()
    for path in custom_watch_paths:
        if not path in _watched_paths:
            _watched_paths.append(path)


## Enables or disables the watcher.
## @param enable Whether to enable watching
func set_enabled(enable: bool) -> void:
    enabled = enable
    set_process(enabled)
    
    if enabled and not _is_initialized:
        _initialize()


## Checks if the watcher is enabled.
## @return true if enabled
func is_enabled() -> bool:
    return enabled


## Sets the polling interval.
## @param interval The interval in seconds (minimum 0.1)
func set_poll_interval(interval: float) -> void:
    # Use a class variable instead of const
    _poll_interval = max(0.1, interval)


var _poll_interval: float = POLL_INTERVAL


## Gets the current polling interval.
## @return The interval in seconds
func get_poll_interval() -> float:
    return _poll_interval


## Gets the number of files being watched.
## @return Number of tracked files
func get_watched_file_count() -> int:
    return _last_modified_times.size()


## Gets a list of all watched files.
## @return PackedStringArray of file paths
func get_watched_files() -> PackedStringArray:
    var files := PackedStringArray()
    for file in _last_modified_times.keys():
        files.append(file)
    return files


## Manually adds a file to watch.
## @param file_path The file path to watch
func watch_file(file_path: String) -> void:
    if FileAccess.file_exists(file_path):
        var modified := FileAccess.get_modified_time(file_path)
        _last_modified_times[file_path] = modified


## Stops watching a specific file.
## @param file_path The file path to stop watching
func unwatch_file(file_path: String) -> void:
    if _last_modified_times.has(file_path):
        _last_modified_times.erase(file_path)


## Gets the AssetRegistry singleton.
func _get_registry() -> AssetRegistry:
    if Engine.has_singleton("AssetRegistry"):
        return Engine.get_singleton("AssetRegistry") as AssetRegistry
    
    var root := get_tree().root
    return root.find_child("AssetRegistry", true, false) as AssetRegistry


## Pauses watching without disabling.
func pause() -> void:
    set_process(false)


## Resumes watching after pause.
func resume() -> void:
    if enabled:
        set_process(true)


## Checks if a specific file has been modified since last check.
## @param file_path The file to check
## @return true if modified
func is_file_modified(file_path: String) -> bool:
    if not FileAccess.file_exists(file_path):
        return false
    
    var current_modified := FileAccess.get_modified_time(file_path)
    
    if _last_modified_times.has(file_path):
        return _last_modified_times[file_path] != current_modified
    
    return true


## Gets the last modification time for a file.
## @param file_path The file to query
## @return The modification time, or 0 if not tracked
func get_file_modified_time(file_path: String) -> int:
    return _last_modified_times.get(file_path, 0)


## Refreshes the file list (useful if files were added externally).
func refresh_file_list() -> void:
    _scan_all_files()
