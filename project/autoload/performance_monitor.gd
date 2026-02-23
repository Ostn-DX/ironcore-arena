extends Node
class_name PerformanceMonitor
## PerformanceMonitor - RTX 4080 optimization and monitoring
## Part of Studio Architecture: Technical Systems

signal performance_warning(metric: String, value: float, threshold: float)
signal performance_critical(metric: String, value: float)
signal fps_dropped(current_fps: float, target_fps: float)
signal vram_warning(used_percent: float)

# Configuration
@export var target_fps: float = 144.0
@export var min_acceptable_fps: float = 60.0
@export var warning_fps: float = 55.0
@export var warning_frame_time_ms: float = 20.0
@export var warning_vram_percent: float = 0.85
@export var critical_vram_percent: float = 0.95

@export var enable_logging: bool = true
@export var log_interval_seconds: float = 30.0

# State
var _frame_times: Array[float] = []
var _max_frame_history: int = 120  # 2 seconds at 60fps
var _last_log_time: float = 0.0
var _warning_count: Dictionary = {}

# Metrics
current_fps: float = 0.0
average_fps: float = 0.0
p99_frame_time_ms: float = 0.0
p95_frame_time_ms: float = 0.0
process_time_ms: float = 0.0
physics_time_ms: float = 0.0
static_memory_mb: float = 0.0
max_memory_mb: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("PerformanceMonitor: Initialized (Target: %d FPS)" % int(target_fps))
	
	# Connect to EventBus for game state changes
	if EventBus:
		EventBus.game_state_changed.connect(_on_game_state_changed)

func _process(delta: float) -> void:
	_update_frame_times(delta)
	_update_metrics()
	_check_thresholds()
	
	# Periodic logging
	if enable_logging and Time.get_ticks_msec() / 1000.0 - _last_log_time > log_interval_seconds:
		_log_performance()
		_last_log_time = Time.get_ticks_msec() / 1000.0

func _update_frame_times(delta: float) -> void:
	var frame_time_ms: float = delta * 1000.0
	_frame_times.append(frame_time_ms)
	
	if _frame_times.size() > _max_frame_history:
		_frame_times.pop_front()

func _update_metrics() -> void:
	# Godot performance monitors
	current_fps = Performance.get_monitor(Performance.TIME_FPS)
	process_time_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000
	physics_time_ms = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
	static_memory_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024 / 1024
	max_memory_mb = Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1024 / 1024
	
	# Calculated metrics
	average_fps = _calculate_average_fps()
	p99_frame_time_ms = _get_percentile_frame_time(0.99)
	p95_frame_time_ms = _get_percentile_frame_time(0.95)

func _calculate_average_fps() -> float:
	if _frame_times.is_empty():
		return 0.0
	var total_time = _frame_times.reduce(func(acc, t): return acc + t, 0.0)
	return 1000.0 / (total_time / _frame_times.size())

func _get_percentile_frame_time(percentile: float) -> float:
	if _frame_times.is_empty():
		return 0.0
	
	var sorted = _frame_times.duplicate()
	sorted.sort()
	var index = int(sorted.size() * percentile)
	return sorted[clamp(index, 0, sorted.size() - 1)]

func _check_thresholds() -> void:
	# FPS check
	if current_fps < warning_fps and current_fps > 0:
		_emit_warning("fps", current_fps, warning_fps)
		fps_dropped.emit(current_fps, target_fps)
	
	# Frame time check
	if process_time_ms > warning_frame_time_ms:
		_emit_warning("frame_time", process_time_ms, warning_frame_time_ms)
	
	# VRAM check (if we can estimate it)
	var vram_percent = _estimate_vram_usage()
	if vram_percent > warning_vram_percent:
		vram_warning.emit(vram_percent)
		if vram_percent > critical_vram_percent:
			performance_critical.emit("vram", vram_percent)

func _estimate_vram_usage() -> float:
	## Estimate VRAM usage based on Godot's texture memory
	## This is an approximation - actual VRAM includes meshes, shaders, etc.
	var texture_memory = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	# RTX 4080 Super has 16GB VRAM
	var total_vram: float = 16.0 * 1024.0 * 1024.0 * 1024.0  # 16GB in bytes
	return texture_memory / total_vram

func _emit_warning(metric: String, value: float, threshold: float) -> void:
	# Throttle warnings (max once per 5 seconds per metric)
	var now: float = Time.get_ticks_msec() / 1000.0
	if _warning_count.has(metric) and now - _warning_count[metric] < 5.0:
		return
	
	_warning_count[metric] = now
	performance_warning.emit(metric, value, threshold)

func _log_performance() -> void:
	var summary = get_performance_summary()
	print("Performance: %.1f FPS | Frame: %.2fms (p99: %.2f) | Memory: %.1f MB" % [
		summary.current_fps,
		summary.process_ms,
		summary.p99_frame_time_ms,
		summary.static_memory_mb
	])

func _on_game_state_changed(new_state: int) -> void:
	# Adjust monitoring based on game state
	match new_state:
		GameManager.GameState.BATTLE_ACTIVE:
			# More frequent monitoring during gameplay
			pass
		GameManager.GameState.MAIN_MENU:
			# Lower priority monitoring in menus
			pass

# ============================================================================
# PUBLIC API
# ============================================================================

func get_performance_summary() -> Dictionary:
	return {
		"current_fps": current_fps,
		"average_fps": average_fps,
		"target_fps": target_fps,
		"p99_frame_time_ms": p99_frame_time_ms,
		"p95_frame_time_ms": p95_frame_time_ms,
		"process_ms": process_time_ms,
		"physics_ms": physics_time_ms,
		"static_memory_mb": static_memory_mb,
		"max_memory_mb": max_memory_mb,
		"vram_estimate_percent": _estimate_vram_usage() * 100,
		"timestamp": Time.get_unix_time_from_system()
	}

func is_performance_acceptable() -> bool:
	return current_fps >= min_acceptable_fps

func get_bottleneck() -> String:
	## Identify what's limiting performance
	if process_time_ms > 16.6:
		return "cpu"  # Game logic
	elif physics_time_ms > 5.0:
		return "physics"
	else:
		return "gpu"  # Rendering

func export_report() -> String:
	var summary = get_performance_summary()
	var report: String = "Performance Report\n"
	report += "==================\n"
	report += "FPS: %.1f (Target: %.1f)\n" % [summary.current_fps, target_fps]
	report += "Frame Time: %.2fms (p99: %.2fms)\n" % [summary.process_ms, summary.p99_frame_time_ms]
	report += "Memory: %.1f MB\n" % summary.static_memory_mb
	report += "VRAM: %.1f%%\n" % summary.vram_estimate_percent
	report += "Bottleneck: %s\n" % get_bottleneck()
	return report
