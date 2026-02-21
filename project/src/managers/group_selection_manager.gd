extends Node
class_name GroupSelectionManager
## Manages group selection (box select) and control groups
## Attach to BattleScreen

signal units_selected(units: Array)
signal selection_cleared

# Selection state
var selected_units: Array[Node2D] = []
var selection_box: Control = null
var is_selecting: bool = false
var selection_start: Vector2 = Vector2.ZERO

# Control groups (1-9)
var control_groups: Dictionary = {}  # group_number -> Array[Node2D]

# Settings
@export var selection_box_color: Color = Color(0.0, 0.8, 1.0, 0.3)
@export var selection_box_border: Color = Color(0.0, 0.8, 1.0, 0.8)

func _ready() -> void:
	_create_selection_box()

func _create_selection_box() -> void:
	## Create the visual selection box
	selection_box = Control.new()
	selection_box.visible = false
	selection_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(selection_box)
	
	# Draw the box in _draw
	selection_box.draw.connect(_draw_selection_box)

func _draw_selection_box() -> void:
	if not is_selecting:
		return
	
	var rect: Rect2 = _get_selection_rect()
	
	# Fill
	selection_box.draw_rect(rect, selection_box_color)
	# Border
	selection_box.draw_rect(rect, selection_box_border, false, 2.0)

func _get_selection_rect() -> Rect2:
	var current_pos: Vector2 = get_viewport().get_mouse_position()
	var top_left: Vector2 = Vector2(
		min(selection_start.x, current_pos.x),
		min(selection_start.y, current_pos.y)
	)
	var size: Vector2 = Vector2(
		abs(current_pos.x - selection_start.x),
		abs(current_pos.y - selection_start.y)
	)
	return Rect2(top_left, size)

func _input(event: InputEvent) -> void:
	# Left click start selection
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check if clicking on UI or game world
				if not _is_mouse_over_ui():
					_start_selection()
			else:
				_end_selection()
		
		# Right click = issue command to selected units
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if selected_units.size() > 0:
				_issue_command_to_selection()
	
	# Drag selection box
	if event is InputEventMouseMotion and is_selecting:
		selection_box.queue_redraw()
	
	# Control groups (number keys)
	if event is InputEventKey and event.pressed:
		var key: int = event.keycode
		if key >= KEY_1 and key <= KEY_9:
			var group_num: int = key - KEY_0
			if Input.is_key_pressed(KEY_CTRL):
				# Ctrl+Number = assign group
				_assign_control_group(group_num)
			elif Input.is_key_pressed(KEY_SHIFT):
				# Shift+Number = add group to selection
				_select_control_group(group_num, true)
			else:
				# Number = select group
				_select_control_group(group_num, false)
		
		# Spacebar = center camera on selection
		elif key == KEY_SPACE:
			_center_on_selection()

func _is_mouse_over_ui() -> bool:
	## Check if mouse is over UI elements (not game world)
	# Get mouse position
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	# Check if over any UI panels
	# This is a simplified check - in practice you'd check specific UI nodes
	var ui_rects: Array[Rect2] = _get_ui_rects()
	for rect in ui_rects:
		if rect.has_point(mouse_pos):
			return true
	
	return false

func _get_ui_rects() -> Array[Rect2]:
	## Return array of UI element rectangles to avoid clicking through
	# This should be populated with your actual UI bounds
	return []

func _start_selection() -> void:
	## Start box selection
	is_selecting = true
	selection_start = get_viewport().get_mouse_position()
	
	# If not holding shift, clear current selection
	if not Input.is_key_pressed(KEY_SHIFT):
		clear_selection()
	
	selection_box.visible = true

func _end_selection() -> void:
	## Complete box selection
	if not is_selecting:
		return
	
	is_selecting = false
	selection_box.visible = false
	
	# Get selection rectangle
	var screen_rect: Rect2 = _get_selection_rect()
	
	# Convert to world rect if needed
	# For now, assume screen space
	
	# Select units in rectangle
	_select_units_in_rect(screen_rect)

func _select_units_in_rect(rect: Rect2) -> void:
	## Find and select units in the rectangle
	var units: Array[Node2D] = _get_selectable_units()
	
	for unit in units:
		if unit.visible and unit.is_inside_tree():
			# Get unit screen position
			var screen_pos: Vector2 = get_viewport().get_camera_2d().world_to_screen(unit.global_position)
			
			if rect.has_point(screen_pos):
				_select_unit(unit)
	
	units_selected.emit(selected_units)

func _get_selectable_units() -> Array[Node2D]:
	## Get all player-controlled units
	# This should query the battle manager or unit container
	var units: Array[Node2D] = []
	
	# Look for units in the bots_container
	var battle_screen = get_parent()
	if battle_screen and battle_screen.bots_container:
		for child in battle_screen.bots_container.get_children():
			if child.has_method("is_player_unit") and child.is_player_unit():
				units.append(child)
	
	return units

func _select_unit(unit: Node2D) -> void:
	## Add unit to selection
	if not selected_units.has(unit):
		selected_units.append(unit)
		# Visual feedback
		if unit.has_method("set_selected"):
			unit.set_selected(true)

func _deselect_unit(unit: Node2D) -> void:
	## Remove unit from selection
	selected_units.erase(unit)
	# Visual feedback
	if unit.has_method("set_selected"):
		unit.set_selected(false)

func clear_selection() -> void:
	## Clear all selected units
	for unit in selected_units:
		if unit.has_method("set_selected"):
			unit.set_selected(false)
	
	selected_units.clear()
	selection_cleared.emit()

func _issue_command_to_selection() -> void:
	## Issue move or attack command to selected units
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	# Convert to world position
	var camera: Camera2D = get_viewport().get_camera_2d()
	var world_pos: Vector2 = camera.get_global_mouse_position()
	
	# Check if clicking on enemy
	var target = _get_enemy_at_position(world_pos)
	
	if target:
		# Attack command
		for unit in selected_units:
			if unit.has_method("command_attack"):
				unit.command_attack(target)
	else:
		# Move command
		# Calculate formation positions
		var formation_positions: Array[Vector2] = _calculate_formation(world_pos, selected_units.size())
		
		for i in range(selected_units.size()):
			var unit = selected_units[i]
			if unit.has_method("command_move"):
				unit.command_move(formation_positions[i])

func _get_enemy_at_position(pos: Vector2) -> Node2D:
	## Check if position has an enemy unit
	var units: Array[Node2D] = _get_selectable_units()  ; All units
	
	for unit in units:
		if not unit.is_player_unit():
			var dist: float = unit.global_position.distance_to(pos)
			if dist < 30:  ; Selection radius
				return unit
	
	return null

func _calculate_formation(center: Vector2, count: int) -> Array[Vector2]:
	## Calculate formation positions for group movement
	var positions: Array[Vector2] = []
	var spacing: float = 50.0
	
	if count == 1:
		positions.append(center)
	elif count <= 4:
		# Line formation
		var start_x: float = center.x - ((count - 1) * spacing / 2)
		for i in range(count):
			positions.append(Vector2(start_x + i * spacing, center.y))
	else:
		# Grid formation
		var cols: int = ceili(sqrt(count))
		var start_x: float = center.x - ((cols - 1) * spacing / 2)
		var start_y: float = center.y - ((cols - 1) * spacing / 2)
		
		var idx: int = 0
		for row in range(cols):
			for col in range(cols):
				if idx < count:
					positions.append(Vector2(start_x + col * spacing, start_y + row * spacing))
					idx += 1
	
	return positions

func _assign_control_group(group_num: int) -> void:
	## Save current selection to control group
	control_groups[group_num] = selected_units.duplicate()
	print("Assigned ", selected_units.size(), " units to group ", group_num)

func _select_control_group(group_num: int, add_to_current: bool) -> void:
	## Select or add control group
	if not control_groups.has(group_num):
		return
	
	if not add_to_current:
		clear_selection()
	
	var group: Array = control_groups[group_num]
	for unit in group:
		if is_instance_valid(unit) and unit.is_inside_tree():
			_select_unit(unit)
	
	units_selected.emit(selected_units)

func _center_on_selection() -> void:
	## Center camera on selected units
	if selected_units.size() == 0:
		return
	
	# Calculate center of selection
	var center: Vector2 = Vector2.ZERO
	for unit in selected_units:
		center += unit.global_position
	center /= selected_units.size()
	
	# Move camera
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera and camera.has_method("center_on_position"):
		camera.center_on_position(center)

func get_selected_units() -> Array[Node2D]:
	return selected_units

func has_selection() -> bool:
	return selected_units.size() > 0
