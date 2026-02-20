extends CanvasLayer
class_name TransitionManager
## TransitionManager — handles smooth transitions between screens.
## Fade, slide, and custom transition effects.

signal transition_started
signal transition_finished
signal transition_midpoint

# Transition types
enum TransitionType { FADE, SLIDE_LEFT, SLIDE_RIGHT, SLIDE_UP, SLIDE_DOWN, WIPE }

# Current state
var is_transitioning: bool = false
var transition_duration: float = 0.3

# Transition overlay
var overlay: ColorRect = null


func _ready() -> void:
	_setup_overlay()


func _setup_overlay() -> void:
	## Setup the transition overlay
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color.BLACK
	overlay.visible = false
	overlay.z_index = 100  # On top of everything
	add_child(overlay)


# ============================================================================
# TRANSITION METHODS
# ============================================================================

func fade_to_black(duration: float = 0.3, hold_time: float = 0.0) -> void:
	## Fade screen to black
	if is_transitioning:
		return
	
	is_transitioning = true
	transition_duration = duration
	transition_started.emit()
	
	overlay.visible = true
	overlay.modulate.a = 0
	
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, duration)
	
	if hold_time > 0:
		tween.tween_interval(hold_time)
	
	tween.finished.connect(_on_fade_to_black_complete)


func fade_from_black(duration: float = 0.3) -> void:
	## Fade screen from black to clear
	if not overlay.visible:
		return
	
	transition_duration = duration
	
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, duration)
	tween.finished.connect(_on_fade_from_black_complete)


func cross_fade(from_screen: Control, to_screen: Control, duration: float = 0.3) -> void:
	## Cross-fade between two screens
	if is_transitioning:
		return
	
	is_transitioning = true
	transition_started.emit()
	
	# Fade out current
	var fade_out: Tween = create_tween()
	fade_out.tween_property(from_screen, "modulate:a", 0.0, duration / 2)
	
	# Midpoint - swap screens
	await get_tree().create_timer(duration / 2).timeout
	transition_midpoint.emit()
	
	from_screen.visible = false
	to_screen.visible = true
	to_screen.modulate.a = 0
	
	# Fade in new
	var fade_in: Tween = create_tween()
	fade_in.tween_property(to_screen, "modulate:a", 1.0, duration / 2)
	fade_in.finished.connect(_on_transition_complete)


func slide_transition(screen: Control, direction: Vector2, duration: float = 0.3) -> void:
	## Slide a screen in/out
	if is_transitioning:
		return
	
	is_transitioning = true
	transition_started.emit()
	
	var start_pos: Vector2 = screen.position
	var end_pos: Vector2 = start_pos + direction * Vector2(1280, 720)
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(screen, "position", end_pos, duration)
	tween.finished.connect(_on_transition_complete)


func wipe_transition(from_screen: Control, to_screen: Control, direction: Vector2 = Vector2.RIGHT, duration: float = 0.4) -> void:
	## Wipe transition between screens
	if is_transitioning:
		return
	
	is_transitioning = true
	transition_started.emit()
	
	# Create wipe panel
	var wipe: Panel = Panel.new()
	wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	wipe.z_index = 99
	add_child(wipe)
	
	# Animate wipe
	var tween: Tween = create_tween()
	
	if direction == Vector2.RIGHT:
		wipe.position.x = -1280
		tween.tween_property(wipe, "position:x", 0, duration / 2)
		tween.tween_callback(func(): 
			from_screen.visible = false
			to_screen.visible = true
			transition_midpoint.emit()
		)
		tween.tween_property(wipe, "position:x", 1280, duration / 2)
	
	tween.finished.connect(func():
		wipe.queue_free()
		_on_transition_complete()
	)


func instant_transition(from_screen: Control, to_screen: Control) -> void:
	## Instant screen swap (no animation)
	from_screen.visible = false
	to_screen.visible = true
	to_screen.modulate.a = 1.0
	transition_finished.emit()


# ============================================================================
# UTILITY TRANSITIONS
# ============================================================================

func flash_screen(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	## Flash the screen with a color (for impacts, etc)
	var flash: ColorRect = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = color
	flash.modulate.a = 0.8
	flash.z_index = 99
	add_child(flash)
	
	var tween: Tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.finished.connect(flash.queue_free)


func pulse_overlay(color: Color = Color.BLACK, count: int = 3, speed: float = 0.2) -> void:
	## Pulse the overlay for dramatic effect
	overlay.color = color
	overlay.visible = true
	
	var tween: Tween = create_tween()
	tween.set_loops(count)
	tween.tween_property(overlay, "modulate:a", 0.5, speed)
	tween.tween_property(overlay, "modulate:a", 0.0, speed)
	
	tween.finished.connect(func():
		overlay.visible = false
	)


# ============================================================================
# CALLBACKS
# ============================================================================

func _on_fade_to_black_complete() -> void:
	transition_midpoint.emit()
	# Caller should handle scene swap and call fade_from_black()


func _on_fade_from_black_complete() -> void:
	overlay.visible = false
	is_transitioning = false
	transition_finished.emit()


func _on_transition_complete() -> void:
	is_transitioning = false
	transition_finished.emit()


# ============================================================================
# PUBLIC API
# ============================================================================

func is_busy() -> bool:
	return is_transitioning


func wait_for_transition() -> Signal:
	## Returns signal that fires when transition completes
	return transition_finished
