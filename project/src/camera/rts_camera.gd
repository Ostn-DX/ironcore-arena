extends Camera2D
class_name RTSCamera
## RTS-style camera with zoom, pan, and edge scrolling
## For Ironcore Arena - supports large battlefields

# Camera settings
@export var min_zoom: float = 0.3
@export var max_zoom: float = 1.5
@export var zoom_step: float = 0.1
@export var zoom_speed: float = 8.0
@export var pan_speed: float = 500.0
@export var edge_scroll_margin: int = 50
@export var edge_scroll_speed: float = 800.0

# Arena bounds (set by Arena scene)
var arena_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(800, 600))

# Target values for smooth interpolation
var target_zoom: Vector2 = Vector2.ONE
var target_position: Vector2 = Vector2.ZERO

# Input state
var is_panning: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	; Set initial zoom based on arena size
	_calculate_initial_zoom()
	target_zoom = zoom
	target_position = position
	
	; Enable processing
	set_process(true)
	set_process_input(true)

func _calculate_initial_zoom() -> void:
	## Calculate starting zoom to see the whole arena
	var viewport_size: Vector2 = get_viewport_rect().size
	var arena_size: Vector2 = arena_bounds.size
	
	; Calculate zoom to fit arena with some padding
	var zoom_x: float = viewport_size.x / arena_size.x * 0.9
	var zoom_y: float = viewport_size.y / arena_size.y * 0.9
	var fit_zoom: float = min(zoom_x, zoom_y)
	
	; Clamp to valid range
	fit_zoom = clampf(fit_zoom, min_zoom, max_zoom)
	
	zoom = Vector2(fit_zoom, fit_zoom)
	target_zoom = zoom

func setup_arena_bounds(bounds: Rect2) -> void:
	## Called by Arena to set the playable area
	arena_bounds = bounds
	_calculate_initial_zoom()
	
	; Center camera on arena
	target_position = arena_bounds.get_center()
	position = target_position

func _process(delta: float) -> void:
	; Smooth zoom interpolation
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)
	
	; Smooth position interpolation
	position = position.lerp(target_position, pan_speed * delta)
	
	; Clamp to bounds
	_clamp_to_bounds()

func _input(event: InputEvent) -> void:
	; Mouse wheel zoom
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_in()
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_out()
			MOUSE_BUTTON_MIDDLE:
				; Middle click to start panning
				if event.pressed:
					is_panning = true
					last_mouse_pos = event.position
				else:
					is_panning = false
	
	; Middle click drag panning
	if event is InputEventMouseMotion and is_panning:
		var delta: Vector2 = event.position - last_mouse_pos
		target_position -= delta / zoom.x  ; Account for zoom in pan calculation
		last_mouse_pos = event.position
	
	; Edge scrolling
	if event is InputEventMouseMotion:
		_handle_edge_scroll(event.position, get_viewport_rect().size)

func _zoom_in() -> void:
	var new_zoom: float = min(target_zoom.x + zoom_step, max_zoom)
	target_zoom = Vector2(new_zoom, new_zoom)

func _zoom_out() -> void:
	var new_zoom: float = max(target_zoom.x - zoom_step, min_zoom)
	target_zoom = Vector2(new_zoom, new_zoom)

func _handle_edge_scroll(mouse_pos: Vector2, viewport_size: Vector2) -> void:
	## Move camera when mouse is near screen edges
	var scroll_dir: Vector2 = Vector2.ZERO
	
	; Check left edge
	if mouse_pos.x < edge_scroll_margin:
		scroll_dir.x = -1
	; Check right edge
	elif mouse_pos.x > viewport_size.x - edge_scroll_margin:
		scroll_dir.x = 1
	
	; Check top edge
	if mouse_pos.y < edge_scroll_margin:
		scroll_dir.y = -1
	; Check bottom edge
	elif mouse_pos.y > viewport_size.y - edge_scroll_margin:
		scroll_dir.y = 1
	
	; Apply edge scrolling
	if scroll_dir != Vector2.ZERO:
		target_position += scroll_dir * edge_scroll_speed * get_process_delta_time() / zoom.x

func _clamp_to_bounds() -> void:
	## Keep camera within arena bounds (with margin for zoom)
	if arena_bounds.size == Vector2.ZERO:
		return
	
	var viewport_size: Vector2 = get_viewport_rect().size / zoom
	var half_viewport: Vector2 = viewport_size / 2
	
	; Calculate clamp bounds
	var min_x: float = arena_bounds.position.x + half_viewport.x
	var max_x: float = arena_bounds.end.x - half_viewport.x
	var min_y: float = arena_bounds.position.y + half_viewport.y
	var max_y: float = arena_bounds.end.y - half_viewport.y
	
	; Handle case where arena is smaller than viewport
	if min_x > max_x:
		min_x = max_x = arena_bounds.get_center().x
	if min_y > max_y:
		min_y = max_y = arena_bounds.get_center().y
	
	; Clamp target position
	target_position.x = clampf(target_position.x, min_x, max_x)
	target_position.y = clampf(target_position.y, min_y, max_y)

func center_on_position(pos: Vector2) -> void:
	## Center camera on specific position
	target_position = pos

func center_on_unit(unit: Node2D) -> void:
	## Center camera on a unit
	if unit:
		target_position = unit.global_position

func get_world_mouse_position() -> Vector2:
	## Get mouse position in world coordinates
	return get_global_mouse_position()

func get_visible_rect() -> Rect2:
	## Get the visible world area
	var viewport_size: Vector2 = get_viewport_rect().size / zoom
	var half_size: Vector2 = viewport_size / 2
	return Rect2(position - half_size, viewport_size)
