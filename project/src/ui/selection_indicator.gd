extends Node2D
class_name SelectionIndicator
## Visual indicator for selected bots/units
## Attach as child to bot visual node

enum IndicatorType { SINGLE, GROUP_LEADER, GROUP_MEMBER }

@export var indicator_type: IndicatorType = IndicatorType.SINGLE
@export var radius: float = 25.0
@export var color_player: Color = Color(0.2, 0.8, 1.0, 0.8)  # Cyan for player
@export var color_enemy: Color = Color(1.0, 0.3, 0.3, 0.8)   # Red for enemy
@export var color_group: Color = Color(1.0, 0.8, 0.0, 0.6)   # Gold for group

var is_selected: bool = false
var is_hovered: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	z_index = 10  # Draw on top
	visible = false

func _process(delta: float) -> void:
	if is_selected or is_hovered:
		pulse_time += delta * 3.0
		queue_redraw()

func _draw() -> void:
	if not is_selected and not is_hovered:
		return
	
	var base_color: Color = _get_color()
	
	# Pulsing alpha
	var pulse: float = (sin(pulse_time) + 1.0) * 0.5
	var alpha: float = 0.4 + pulse * 0.4
	
	match indicator_type:
		IndicatorType.SINGLE:
			_draw_single_selection(base_color, alpha)
		IndicatorType.GROUP_LEADER:
			_draw_group_leader(base_color, alpha)
		IndicatorType.GROUP_MEMBER:
			_draw_group_member(base_color, alpha)

func _get_color() -> Color:
	# Get parent bot's team color
	var parent = get_parent()
	if parent and parent.has_method("get_team"):
		var team: int = parent.get_team()
		if team == 0:
			return color_player
		else:
			return color_enemy
	return color_player

func _draw_single_selection(color: Color, alpha: float) -> void:
	## Draw simple circle selection
	var c: Color = color
	c.a = alpha
	
	# Outer ring
	draw_circle(Vector2.ZERO, radius + 4, c, false, 2.0)
	
	# Inner glow
	var glow: Color = c
	glow.a = alpha * 0.3
	draw_circle(Vector2.ZERO, radius, glow, true)

func _draw_group_leader(color: Color, alpha: float) -> void:
	## Draw diamond shape for group leader
	var c: Color = color_group
	c.a = alpha
	
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0, -radius - 6),
		Vector2(radius + 6, 0),
		Vector2(0, radius + 6),
		Vector2(-radius - 6, 0)
	])
	
	# Fill
	var fill: Color = c
	fill.a = alpha * 0.3
	draw_polygon(points, PackedColorArray([fill, fill, fill, fill]))
	
	# Border
	draw_polyline(points + PackedVector2Array([points[0]]), c, 2.0)

func _draw_group_member(color: Color, alpha: float) -> void:
	## Draw smaller circle for group members
	var c: Color = color_group
	c.a = alpha * 0.7
	
	# Dashed ring effect (using line segments)
	var segments: int = 8
	for i in range(segments):
		if i % 2 == 0:  # Skip every other segment for dashed effect
			continue
		var angle1: float = (i / float(segments)) * TAU
		var angle2: float = ((i + 1) / float(segments)) * TAU
		var start: Vector2 = Vector2(cos(angle1), sin(angle1)) * (radius + 2)
		var end: Vector2 = Vector2(cos(angle2), sin(angle2)) * (radius + 2)
		draw_line(start, end, c, 2.0)

func show_selection() -> void:
	is_selected = true
	visible = true
	queue_redraw()

func hide_selection() -> void:
	is_selected = false
	if not is_hovered:
		visible = false
	queue_redraw()

func show_hover() -> void:
	is_hovered = true
	visible = true
	queue_redraw()

func hide_hover() -> void:
	is_hovered = false
	if not is_selected:
		visible = false
	queue_redraw()

func set_group_leader(is_leader: bool) -> void:
	if is_leader:
		indicator_type = IndicatorType.GROUP_LEADER
	else:
		indicator_type = IndicatorType.GROUP_MEMBER
	queue_redraw()
