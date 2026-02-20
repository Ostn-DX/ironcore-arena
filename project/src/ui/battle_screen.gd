extends Control
## BattleScreen — arena view, HUD, command input.
## Works with BattleManager and Arena to display battles.

@onready var battle_manager: BattleManager = $BattleManager

# Arena container (Arena scene will be instantiated here)
var arena: Arena = null
var arena_container: Node2D = null

# Bot and projectile containers (created under Arena)
var bots_container: Node2D = null
var projectiles_container: Node2D = null

# HUD
@onready var hud: Control = $BattleHUD

# Results Screen
var results_screen: ResultsScreen = null

# Visual representations
var bot_visuals: Dictionary = {}  # sim_id -> Node2D
var projectile_visuals: Dictionary = {}  # proj_id -> Node2D

# Input state
var selected_bot_id: int = -1
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO

# UI Elements
var countdown_label: Label = null

# Stored results for display
var _last_result: BattleManager.BattleResult = null
var _last_rewards: Dictionary = {}


func _ready() -> void:
    # Give BattleManager reference to this screen
    battle_manager.battle_screen = self
    
    _setup_signals()
    _setup_ui()
    
    # Start test battle after short delay
    await get_tree().create_timer(0.5).timeout
    _start_test_battle()


func _setup_signals() -> void:
    # BattleManager signals
    battle_manager.battle_started.connect(_on_battle_started)
    battle_manager.battle_state_changed.connect(_on_battle_state_changed)
    battle_manager.countdown_tick.connect(_on_countdown_tick)
    battle_manager.battle_ended.connect(_on_battle_ended)
    battle_manager.rewards_calculated.connect(_on_rewards_calculated)
    
    # SimulationManager signals (for visual updates)
    if SimulationManager:
        SimulationManager.entity_moved.connect(_on_entity_moved)
        SimulationManager.entity_damaged.connect(_on_entity_damaged)
        SimulationManager.entity_destroyed.connect(_on_entity_destroyed)
        SimulationManager.projectile_spawned.connect(_on_projectile_spawned)
        SimulationManager.projectile_destroyed.connect(_on_projectile_destroyed)
        SimulationManager.tick_processed.connect(_on_tick_processed)


func _setup_ui() -> void:
    # Create countdown label (hidden by default)
    countdown_label = Label.new()
    countdown_label.name = "CountdownLabel"
    countdown_label.text = "3"
    countdown_label.add_theme_font_size_override("font_size", 72)
    countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    countdown_label.position = Vector2(540, 260)
    countdown_label.size = Vector2(200, 200)
    countdown_label.visible = false
    add_child(countdown_label)
    
    # Create ResultsScreen
    var results_scene: PackedScene = preload("res://scenes/results_screen.tscn")
    results_screen = results_scene.instantiate()
    results_screen.continue_pressed.connect(_on_results_continue)
    results_screen.restart_pressed.connect(_on_results_restart)
    results_screen.edit_loadout_pressed.connect(_on_results_edit)
    results_screen.next_arena_pressed.connect(_on_results_next)
    add_child(results_screen)


func _setup_arena(arena_data: Dictionary) -> void:
    ## Create and setup the arena
    _clear_arena()
    
    # Create container for arena positioning
    arena_container = Node2D.new()
    arena_container.name = "ArenaContainer"
    add_child(arena_container)
    
    # Move container to center of screen based on arena size
    var dims: Array = arena_data.get("dimensions", [800, 600])
    var arena_size: Vector2 = Vector2(dims[0], dims[1])
    var screen_size: Vector2 = Vector2(1280, 720)
    
    # Center the arena in the battle screen
    arena_container.position = (screen_size - arena_size) / 2
    
    # Instance arena scene
    var arena_scene: PackedScene = preload("res://scenes/arena.tscn")
    arena = arena_scene.instantiate()
    arena_container.add_child(arena)
    
    # Setup arena with data
    arena.setup(arena_data)
    
    # Create bot and projectile containers under arena
    bots_container = Node2D.new()
    bots_container.name = "Bots"
    arena.add_child(bots_container)
    
    projectiles_container = Node2D.new()
    projectiles_container.name = "Projectiles"
    arena.add_child(projectiles_container)
    
    print("BattleScreen: Arena setup complete, size: ", arena_size)


func _clear_arena() -> void:
    ## Remove existing arena and containers
    if arena_container:
        arena_container.queue_free()
        arena_container = null
    arena = null
    bots_container = null
    projectiles_container = null


func _start_test_battle() -> void:
    ## Start battle with player's active loadouts using BattleManager
    _clear_visuals()
    _clear_battle_ui()
    
    # Get player's active loadouts
    var player_loadouts: Array = GameState.get_active_loadouts()
    if player_loadouts.is_empty():
        player_loadouts = _get_default_loadout()
    
    # Setup battle with first arena
    var success: bool = battle_manager.setup_battle("roxtan_park", player_loadouts)
    if success:
        # Setup arena visuals before starting battle
        _setup_arena(battle_manager.current_arena_data)
        battle_manager.start_battle()
    else:
        push_error("BattleScreen: Failed to setup battle")


func _get_default_loadout() -> Array[Dictionary]:
    return [{
        "id": "player_bot",
        "name": "Player Scout",
        "chassis": "akaumin_dl2_100",
        "weapons": ["raptor_dt_01"],
        "armor": ["santrin_auro"],
        "mobility": ["mob_wheels_t1"],
        "sensors": ["sen_basic_t1"],
        "utilities": [],
        "ai_profile": "ai_balanced"
    }]


func _clear_visuals() -> void:
    if bots_container:
        for child in bots_container.get_children():
            child.queue_free()
    if projectiles_container:
        for child in projectiles_container.get_children():
            child.queue_free()
    bot_visuals.clear()
    projectile_visuals.clear()


func _clear_battle_ui() -> void:
    ## Hide results screen
    if results_screen:
        results_screen.hide_results()
    
    if countdown_label:
        countdown_label.visible = false


# ============================================================================
# BATTLEMANAGER SIGNAL HANDLERS
# ============================================================================

func _on_battle_started(arena_id: String) -> void:
    print("BattleScreen: Battle started in arena: %s" % arena_id)
    var arena_data: Dictionary = battle_manager.get_current_arena()
    
    # Update title
    var title_label: Label = $BattleHUD/Title
    if title_label:
        title_label.text = arena_data.get("name", "IRONCORE ARENA")


func _on_battle_state_changed(new_state: BattleManager.BattleState, _old_state: BattleManager.BattleState) -> void:
    match new_state:
        BattleManager.BattleState.COUNTDOWN:
            countdown_label.visible = true
        BattleManager.BattleState.ACTIVE:
            countdown_label.visible = false
            # Create initial visuals for existing bots
            for bot_id in SimulationManager.bots:
                _create_bot_visual(SimulationManager.bots[bot_id])
        BattleManager.BattleState.ENDED:
            countdown_label.visible = false


func _on_countdown_tick(seconds_left: int) -> void:
    countdown_label.text = str(seconds_left)
    countdown_label.modulate = Color(1, 1, 1, 1)
    
    # Animate
    var tween: Tween = create_tween()
    tween.tween_property(countdown_label, "scale", Vector2(1.2, 1.2), 0.1)
    tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.1)


func _on_battle_ended(result: BattleManager.BattleResult) -> void:
    print("BattleScreen: Battle ended - Victory: %s, Grade: %s" % [result.victory, result.get_grade()])
    _last_result = result
    # Wait for rewards before showing results


func _on_rewards_calculated(rewards: Dictionary) -> void:
    print("BattleScreen: Rewards - Credits: %d (Base: %d, Bonus: %d)" % [
        rewards["credits"], rewards["base_credits"], rewards["bonus_credits"]
    ])
    _last_rewards = rewards
    
    # Show results screen with both result and rewards
    if _last_result:
        _show_result_screen(_last_result, rewards)


# ============================================================================
# VISUAL CREATION
# ============================================================================

func _create_bot_visual(bot) -> void:
    if not bots_container:
        return
    if bot_visuals.has(bot.sim_id):
        return  # Already exists
    
    # Main visual container
    var visual: Node2D = Node2D.new()
    visual.position = bot.position
    visual.rotation_degrees = bot.rotation
    visual.name = "Bot_%d" % bot.sim_id
    
    # Bot body (chassis)
    var body: ColorRect = ColorRect.new()
    body.size = Vector2(bot.radius * 2, bot.radius * 2)
    body.position = Vector2(-bot.radius, -bot.radius)
    
    # Color by team
    if bot.team == 0:
        body.color = Color(0.2, 0.6, 1.0)  # Blue for player
    else:
        body.color = Color(1.0, 0.3, 0.3)  # Red for enemy
    
    visual.add_child(body)
    
    # Turret (separate node that rotates independently)
    var turret: Node2D = Node2D.new()
    turret.name = "Turret"
    
    # Turret base
    var turret_base: ColorRect = ColorRect.new()
    turret_base.size = Vector2(bot.radius * 1.2, bot.radius * 1.2)
    turret_base.position = Vector2(-bot.radius * 0.6, -bot.radius * 0.6)
    turret_base.color = Color(0.4, 0.4, 0.4)
    turret.add_child(turret_base)
    
    # Gun barrel
    var barrel: ColorRect = ColorRect.new()
    barrel.size = Vector2(bot.radius * 1.8, 6)
    barrel.position = Vector2(0, -3)
    barrel.color = Color(0.6, 0.6, 0.6)
    turret.add_child(barrel)
    
    visual.add_child(turret)
    
    # HP bar background
    var hp_bg: ColorRect = ColorRect.new()
    hp_bg.size = Vector2(bot.radius * 2, 6)
    hp_bg.position = Vector2(-bot.radius, -bot.radius - 12)
    hp_bg.color = Color(0.2, 0.2, 0.2)
    visual.add_child(hp_bg)
    
    # HP bar fill
    var hp_fill: ColorRect = ColorRect.new()
    hp_fill.size = Vector2(bot.radius * 2, 6)
    hp_fill.position = Vector2(-bot.radius, -bot.radius - 12)
    hp_fill.color = Color(0.2, 0.9, 0.2)
    hp_fill.name = "HPBar"
    visual.add_child(hp_fill)
    
    # Bot ID label
    var label: Label = Label.new()
    label.text = str(bot.sim_id)
    label.position = Vector2(-10, bot.radius + 5)
    label.add_theme_font_size_override("font_size", 12)
    visual.add_child(label)
    
    bots_container.add_child(visual)
    bot_visuals[bot.sim_id] = visual


func _create_projectile_visual(proj_id: int, position: Vector2, direction: Vector2) -> void:
    if not projectiles_container:
        return
    
    var visual: ColorRect = ColorRect.new()
    visual.size = Vector2(8, 4)
    visual.position = position - Vector2(4, 2)
    visual.rotation = direction.angle()
    visual.color = Color(1.0, 0.8, 0.2)
    
    projectiles_container.add_child(visual)
    projectile_visuals[proj_id] = visual


# ============================================================================
# SIMULATION SIGNAL HANDLERS (Visual Updates)
# ============================================================================

func _on_entity_moved(sim_id: int, pos: Vector2, rot: float) -> void:
    if bot_visuals.has(sim_id):
        var visual: Node2D = bot_visuals[sim_id]
        visual.position = pos
        visual.rotation_degrees = rot
        
        # Update turret to face target
        if SimulationManager.bots.has(sim_id):
            var bot = SimulationManager.bots[sim_id]
            var turret = visual.get_node_or_null("Turret")
            if turret and bot.target_id != -1 and SimulationManager.bots.has(bot.target_id):
                var target = SimulationManager.bots[bot.target_id]
                if target.is_alive:
                    var target_angle: float = rad_to_deg((target.position - pos).angle())
                    turret.rotation_degrees = target_angle - rot


func _on_entity_damaged(sim_id: int, hp: int, max_hp: int) -> void:
    if bot_visuals.has(sim_id):
        var visual: Node2D = bot_visuals[sim_id]
        var hp_bar: ColorRect = visual.get_node_or_null("HPBar")
        if hp_bar:
            var hp_pct: float = float(hp) / float(max_hp)
            var max_width: float = visual.get_child(0).size.x
            hp_bar.size.x = max_width * hp_pct
            
            # Color change based on HP
            if hp_pct > 0.5:
                hp_bar.color = Color(0.2, 0.9, 0.2)
            elif hp_pct > 0.25:
                hp_bar.color = Color(0.9, 0.9, 0.2)
            else:
                hp_bar.color = Color(0.9, 0.2, 0.2)


func _on_entity_destroyed(sim_id: int, _team: int) -> void:
    if bot_visuals.has(sim_id):
        var visual: Node2D = bot_visuals[sim_id]
        
        # Visual effect for destruction
        if arena:
            var explosion: ColorRect = ColorRect.new()
            explosion.size = Vector2(40, 40)
            explosion.position = visual.position - Vector2(20, 20)
            explosion.color = Color(1.0, 0.5, 0.0, 0.8)
            arena.add_child(explosion)
            
            # Fade out
            var tween: Tween = create_tween()
            tween.tween_property(explosion, "modulate:a", 0.0, 0.5)
            tween.tween_callback(explosion.queue_free)
        
        # Remove bot visual
        visual.queue_free()
        bot_visuals.erase(sim_id)


func _on_projectile_spawned(proj_id: int, position: Vector2, direction: Vector2) -> void:
    _create_projectile_visual(proj_id, position, direction)


func _on_projectile_destroyed(proj_id: int) -> void:
    if projectile_visuals.has(proj_id):
        projectile_visuals[proj_id].queue_free()
        projectile_visuals.erase(proj_id)


func _on_tick_processed(_tick: int) -> void:
    # Update projectile positions
    for proj_id in SimulationManager.projectiles:
        var proj = SimulationManager.projectiles[proj_id]
        if projectile_visuals.has(proj_id):
            projectile_visuals[proj_id].position = proj.position - Vector2(4, 2)
    
    # Update HUD with battle info
    _update_hud()


func _update_hud() -> void:
    ## Update HUD elements with current battle state
    var summary: Dictionary = battle_manager.get_battle_summary()
    
    var instructions: Label = $BattleHUD/Instructions
    if instructions and battle_manager.is_battle_active():
        instructions.text = "%s | Time: %s | Enemies: %d/%d" % [
            summary["arena_name"],
            summary["time"],
            summary["enemy_alive"],
            summary["enemy_total"]
        ]


# ============================================================================
# RESULT SCREEN
# ============================================================================

func _show_result_screen(result: BattleManager.BattleResult, rewards: Dictionary) -> void:
    ## Show the dedicated results screen
    if results_screen:
        results_screen.show_results(result, rewards)


func _on_results_continue() -> void:
    ## Continue button pressed (retry if lost, continue if won)
    if _last_result and _last_result.victory:
        # Go to campaign/arena select
        print("BattleScreen: Continue to next arena")
        # TODO: Navigate to next arena
    else:
        # Retry same arena
        _start_test_battle()


func _on_results_restart() -> void:
    ## Restart current battle
    _start_test_battle()


func _on_results_edit() -> void:
    ## Edit loadout button pressed
    _on_go_to_build()


func _on_results_next() -> void:
    ## Next arena button pressed
    print("BattleScreen: Next arena requested")
    # TODO: Load next arena in campaign


# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input(event: InputEvent) -> void:
    if not battle_manager.is_battle_active():
        return
    
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _drag_start(event.position)
            else:
                _drag_end(event.position)


func _drag_start(screen_pos: Vector2) -> void:
    if not arena_container:
        return
    
    # Convert screen position to local arena position
    var world_pos: Vector2 = _screen_to_arena(screen_pos)
    
    # Find player bot under cursor
    for bot_id in SimulationManager.bots:
        var bot = SimulationManager.bots[bot_id]
        if bot.team != 0:  # Only player bots
            continue
        if not bot.is_alive:
            continue
        
        if world_pos.distance_to(bot.position) < bot.radius * 1.5:
            selected_bot_id = bot_id
            is_dragging = true
            drag_start_pos = screen_pos
            print("Selected bot: ", bot_id)
            return


func _drag_end(screen_pos: Vector2) -> void:
    if not is_dragging or selected_bot_id == -1:
        is_dragging = false
        selected_bot_id = -1
        return
    
    var world_pos: Vector2 = _screen_to_arena(screen_pos)
    
    # Determine command type based on what we dragged to
    var command_type: String = "move"
    var target: Variant = world_pos
    
    # Check if dragged to a bot
    for bot_id in SimulationManager.bots:
        if bot_id == selected_bot_id:
            continue
        var bot = SimulationManager.bots[bot_id]
        if not bot.is_alive:
            continue
        
        if world_pos.distance_to(bot.position) < bot.radius * 2.0:
            if bot.team == 0:
                command_type = "follow"
                target = bot_id
            else:
                command_type = "focus"
                target = bot_id
            break
    
    # Issue command through SimulationManager
    SimulationManager.issue_command(selected_bot_id, command_type, target)
    print("Issued command: ", command_type, " to ", target)
    
    is_dragging = false
    selected_bot_id = -1


func _screen_to_arena(screen_pos: Vector2) -> Vector2:
    ## Convert screen coordinates to arena local coordinates
    if not arena_container:
        return screen_pos
    
    # Account for arena container offset
    return screen_pos - arena_container.position


func _on_go_to_build() -> void:
    battle_manager.end_battle_early()
    get_tree().change_scene_to_file("res://scenes/build_screen.tscn")


# ============================================================================
# PUBLIC METHODS
# ============================================================================

func start_campaign_battle(arena_id: String) -> void:
    ## Start a specific campaign battle
    _clear_visuals()
    _clear_battle_ui()
    
    var player_loadouts: Array = GameState.get_active_loadouts()
    if player_loadouts.is_empty():
        player_loadouts = _get_default_loadout()
    
    var success: bool = battle_manager.setup_battle(arena_id, player_loadouts)
    if success:
        _setup_arena(battle_manager.current_arena_data)
        battle_manager.start_battle()
    else:
        push_error("BattleScreen: Failed to setup campaign battle")


func on_show() -> void:
    visible = true
    if battle_manager.is_battle_ended() or battle_manager.current_state == BattleManager.BattleState.SETUP:
        _start_test_battle()


func on_hide() -> void:
    visible = false
    battle_manager.end_battle_early()
