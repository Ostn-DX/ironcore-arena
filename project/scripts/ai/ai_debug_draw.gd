class_name AIDebugDraw extends Node2D

## Debug visualization for AI decisions.
## Draws paths, positions, cover points, and tactical information.

# Toggle flags for different debug visualizations
@export var enabled: bool = false
@export var draw_paths: bool = true
@export var draw_positions: bool = true
@export var draw_cover: bool = true
@export var draw_targets: bool = true
@export var draw_states: bool = true
@export var draw_squad_info: bool = true

# Visual settings
@export var path_color: Color = Color(0.0, 1.0, 0.0, 0.7)
@export var path_line_width: float = 2.0
@export var position_color: Color = Color(1.0, 0.5, 0.0, 0.8)
@export var position_radius: float = 8.0
@export var cover_color: Color = Color(0.0, 0.5, 1.0, 0.6)
@export var cover_radius: float = 12.0
@export var target_line_color: Color = Color(1.0, 0.0, 0.0, 0.7)
@export var target_line_width: float = 2.0
@export var text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var font_size: int = 12

# State colors
var _state_colors: Dictionary = {
    BotAIAdvanced.AIState.IDLE: Color(0.5, 0.5, 0.5, 0.8),
    BotAIAdvanced.AIState.ENGAGING: Color(1.0, 0.0, 0.0, 0.8),
    BotAIAdvanced.AIState.RETREATING: Color(1.0, 0.5, 0.0, 0.8),
    BotAIAdvanced.AIState.REPOSITIONING: Color(0.0, 0.5, 1.0, 0.8),
    BotAIAdvanced.AIState.PURSUING: Color(1.0, 1.0, 0.0, 0.8)
}

# Role colors
var _role_colors: Dictionary = {
    BotAIAdvanced.AIRole.TANK: Color(0.8, 0.2, 0.2, 0.9),
    BotAIAdvanced.AIRole.SNIPER: Color(0.2, 0.8, 0.2, 0.9),
    BotAIAdvanced.AIRole.SCOUT: Color(0.8, 0.8, 0.2, 0.9),
    BotAIAdvanced.AIRole.SUPPORT: Color(0.2, 0.5, 0.8, 0.9)
}

# Registered AI controllers
var _ai_controllers: Array[BotAIAdvanced] = []

# Squad coordinator reference
var _squad_coordinator: SquadCoordinator = null

# Tactical context reference
var _tactical_context: AITacticalContext = null

# Cached font for text rendering
var _font: Font = null


func _ready() -> void:
    # Get default font
    _font = ThemeDB.fallback_font
    
    # Set z-index to render on top
    z_index = 100


## Registers an AI controller for debug visualization.
func register_ai(ai: BotAIAdvanced) -> void:
    if not _ai_controllers.has(ai):
        _ai_controllers.append(ai)


## Unregisters an AI controller.
func unregister_ai(ai: BotAIAdvanced) -> void:
    _ai_controllers.erase(ai)


## Sets the squad coordinator for squad info visualization.
func set_squad_coordinator(coordinator: SquadCoordinator) -> void:
    _squad_coordinator = coordinator


## Sets the tactical context for cover point visualization.
func set_tactical_context(ctx: AITacticalContext) -> void:
    _tactical_context = ctx


## Clears all registered AI controllers.
func clear() -> void:
    _ai_controllers.clear()


func _draw() -> void:
    if not enabled:
        return
    
    # Draw cover points first (background layer)
    if draw_cover and _tactical_context != null:
        _draw_cover_points()
    
    # Draw AI controller debug info
    for ai: BotAIAdvanced in _ai_controllers:
        if ai == null or not is_instance_valid(ai):
            continue
        
        if draw_paths:
            _draw_ai_path(ai)
        
        if draw_positions:
            _draw_ai_position(ai)
        
        if draw_targets:
            _draw_ai_target(ai)
        
        if draw_states:
            _draw_ai_state(ai)
    
    # Draw squad info
    if draw_squad_info and _squad_coordinator != null:
        _draw_squad_info()


## Draws cover points from the tactical context.
func _draw_cover_points() -> void:
    if _tactical_context == null:
        return
    
    var cover_points: PackedVector2Array = _tactical_context.all_cover_points
    
    for cover_point: Vector2 in cover_points:
        # Draw cover point marker
        draw_circle(cover_point, cover_radius, cover_color)
        draw_arc(cover_point, cover_radius, 0.0, TAU, 16, Color.WHITE, 1.0)
        
        # Draw direction indicator if available
        var metadata: Dictionary = _tactical_context.cover_point_metadata.get(cover_point, {})
        var direction: Vector2 = metadata.get("direction", Vector2.ZERO)
        
        if direction != Vector2.ZERO:
            var end_point: Vector2 = cover_point + direction * cover_radius * 1.5
            draw_line(cover_point, end_point, Color.WHITE, 1.5)
        
        # Draw occupancy indicator
        var occupied_by: int = metadata.get("occupied_by", -1)
        if occupied_by >= 0:
            draw_circle(cover_point, cover_radius * 0.5, Color.RED)


## Draws the path for an AI controller.
func _draw_ai_path(ai: BotAIAdvanced) -> void:
    var path: PackedVector2Array = ai.get_current_path()
    
    if path.size() < 2:
        return
    
    # Draw path line
    for i: int in range(path.size() - 1):
        var start: Vector2 = path[i]
        var end: Vector2 = path[i + 1]
        draw_line(start, end, path_color, path_line_width)
    
    # Draw path points
    for i: int in range(path.size()):
        var point: Vector2 = path[i]
        var alpha: float = 1.0 - (float(i) / float(path.size())) * 0.5
        var point_color: Color = path_color
        point_color.a = alpha
        draw_circle(point, 4.0, point_color)
    
    # Draw move target
    var move_target: Vector2 = ai.get_move_target()
    if move_target != Vector2.ZERO:
        draw_circle(move_target, 6.0, Color.YELLOW)
        draw_arc(move_target, 10.0, 0.0, TAU, 16, Color.YELLOW, 1.0)


## Draws the current position and role indicator for an AI.
func _draw_ai_position(ai: BotAIAdvanced) -> void:
    var bot: Node = ai.get_parent()
    if bot == null or not is_instance_valid(bot):
        return
    
    var bot_pos: Vector2 = bot.global_position if bot.has_method("get_global_position") else Vector2.ZERO
    var role: BotAIAdvanced.AIRole = ai.get_role()
    
    # Draw role indicator
    var role_color: Color = _role_colors.get(role, Color.WHITE)
    draw_circle(bot_pos, position_radius, role_color)
    draw_arc(bot_pos, position_radius + 2.0, 0.0, TAU, 16, Color.WHITE, 1.5)
    
    # Draw role letter
    var role_letter: String = _get_role_letter(role)
    if _font != null:
        draw_string(
            _font,
            bot_pos + Vector2(-4.0, 4.0),
            role_letter,
            HORIZONTAL_ALIGNMENT_CENTER,
            -1,
            font_size,
            Color.BLACK
        )


## Draws the target line for an AI controller.
func _draw_ai_target(ai: BotAIAdvanced) -> void:
    var target: Node = ai.get_current_target()
    if target == null or not is_instance_valid(target):
        return
    
    var bot: Node = ai.get_parent()
    if bot == null or not is_instance_valid(bot):
        return
    
    var bot_pos: Vector2 = bot.global_position if bot.has_method("get_global_position") else Vector2.ZERO
    var target_pos: Vector2 = target.global_position if target.has_method("get_global_position") else Vector2.ZERO
    
    # Draw line to target
    draw_line(bot_pos, target_pos, target_line_color, target_line_width)
    
    # Draw target marker
    draw_circle(target_pos, 8.0, Color.RED)
    draw_arc(target_pos, 12.0, 0.0, TAU, 16, Color.RED, 2.0)


## Draws the state indicator for an AI controller.
func _draw_ai_state(ai: BotAIAdvanced) -> void:
    var bot: Node = ai.get_parent()
    if bot == null or not is_instance_valid(bot):
        return
    
    var bot_pos: Vector2 = bot.global_position if bot.has_method("get_global_position") else Vector2.ZERO
    var state: BotAIAdvanced.AIState = ai.get_state()
    
    # Draw state indicator above bot
    var state_color: Color = _state_colors.get(state, Color.WHITE)
    var indicator_pos: Vector2 = bot_pos + Vector2(0.0, -25.0)
    
    draw_rect(
        Rect2(indicator_pos - Vector2(20.0, 8.0), Vector2(40.0, 16.0)),
        state_color,
        true
    )
    draw_rect(
        Rect2(indicator_pos - Vector2(20.0, 8.0), Vector2(40.0, 16.0)),
        Color.WHITE,
        false,
        1.0
    )
    
    # Draw state text
    if _font != null:
        var state_name: String = _get_state_name(state)
        draw_string(
            _font,
            indicator_pos + Vector2(0.0, 4.0),
            state_name,
            HORIZONTAL_ALIGNMENT_CENTER,
            -1,
            font_size - 2,
            Color.BLACK
        )


## Draws squad-wide information.
func _draw_squad_info() -> void:
    if _squad_coordinator == null:
        return
    
    # This would require access to team data
    # For now, draw a summary at the top-left corner
    var info_pos: Vector2 = Vector2(20.0, 30.0)
    
    if _font != null:
        draw_string(
            _font,
            info_pos,
            "AI Debug Info",
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            font_size + 2,
            text_color
        )
        
        var registered_count: int = _ai_controllers.size()
        draw_string(
            _font,
            info_pos + Vector2(0.0, 20.0),
            "Registered AI: %d" % registered_count,
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            font_size,
            text_color
        )


## Gets a single letter representation of a role.
func _get_role_letter(role: BotAIAdvanced.AIRole) -> String:
    match role:
        BotAIAdvanced.AIRole.TANK:
            return "T"
        BotAIAdvanced.AIRole.SNIPER:
            return "S"
        BotAIAdvanced.AIRole.SCOUT:
            return "C"
        BotAIAdvanced.AIRole.SUPPORT:
            return "P"
    return "?"


## Gets the display name for a state.
func _get_state_name(state: BotAIAdvanced.AIState) -> String:
    match state:
        BotAIAdvanced.AIState.IDLE:
            return "IDLE"
        BotAIAdvanced.AIState.ENGAGING:
            return "ENGAGE"
        BotAIAdvanced.AIState.RETREATING:
            return "RETREAT"
        BotAIAdvanced.AIState.REPOSITIONING:
            return "REPOS"
        BotAIAdvanced.AIState.PURSUING:
            return "PURSUE"
    return "UNKNOWN"


## Toggles debug drawing on/off.
func toggle() -> void:
    enabled = not enabled
    queue_redraw()


## Sets all draw options at once.
func set_draw_options(
    paths: bool,
    positions: bool,
    cover: bool,
    targets: bool,
    states: bool,
    squad: bool
) -> void:
    draw_paths = paths
    draw_positions = positions
    draw_cover = cover
    draw_targets = targets
    draw_states = states
    draw_squad_info = squad
    queue_redraw()
