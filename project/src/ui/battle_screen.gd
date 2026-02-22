extends Control
## BattleScreen — arena view, HUD, command input.
## OPTIMIZED: Removed debug prints, cached lookups, streamlined visual updates
## WIRED UP: Proper signal flow to SceneFlowManager

signal battle_ended(result: Dictionary)

@onready var battle_manager: BattleManager = $BattleManager
@onready var _simulation_manager = get_node("/root/SimulationManager")

# Arena
var arena: Arena = null
var arena_container: Node2D = null
var bots_container: Node2D = null
var projectiles_container: Node2D = null

# HUD
@onready var hud: Control = $BattleHUD

# Results
var results_screen: ResultsScreen = null

# Visuals
var bot_visuals: Dictionary = {}
var projectile_visuals: Dictionary = {}

# Input
var selected_bot_id: int = -1
var is_dragging: bool = false

# UI
var countdown_label: Label = null

# Results storage
var _last_result: BattleManager.BattleResult = null
var _last_rewards: Dictionary = {}

# Cached for performance
var _cached_bot_data: Dictionary = {}

func _ready() -> void:
	battle_manager.battle_screen = self
	_setup_signals()
	_setup_ui()
	
	# Don't auto-start battle here - wait for on_show
	print("BattleScreen: Ready")

func on_show() -> void:
	# Called when screen becomes visible
	visible = true
	_start_test_battle()

func on_hide() -> void:
	# Called when screen is hidden
	visible = false
	battle_manager.end_battle_early()

func _setup_signals() -> void:
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_state_changed.connect(_on_battle_state_changed)
	battle_manager.countdown_tick.connect(_on_countdown_tick)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.rewards_calculated.connect(_on_rewards_calculated)
	
	
		_simulation_manager.entity_moved.connect(_on_entity_moved)
		_simulation_manager.entity_damaged.connect(_on_entity_damaged)
		_simulation_manager.entity_destroyed.connect(_on_entity_destroyed)
		_simulation_manager.projectile_spawned.connect(_on_projectile_spawned)
		_simulation_manager.projectile_destroyed.connect(_on_projectile_destroyed)
		_simulation_manager.tick_processed.connect(_on_tick_processed)

func _setup_ui() -> void:
	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.text = "3"
	countdown_label.add_theme_font_size_override("font_size", 72)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.position = Vector2(540, 260)
	countdown_label.size = Vector2(200, 200)
	countdown_label.visible = false
	add_child(countdown_label)
	
	var results_scene: PackedScene = preload("res://scenes/results_screen.tscn")
	results_screen = results_scene.instantiate()
	results_screen.continue_pressed.connect(_on_results_continue)
	results_screen.restart_pressed.connect(_on_results_restart)
	results_screen.edit_loadout_pressed.connect(_on_results_edit)
	results_screen.next_arena_pressed.connect(_on_results_next)
	add_child(results_screen)

func _setup_arena(arena_data: Dictionary) -> void:
	_clear_arena()
	
	arena_container = Node2D.new()
	arena_container.name = "ArenaContainer"
	add_child(arena_container)
	
	var size_data: Dictionary = arena_data.get("size", {"width": 800, "height": 600})
	var arena_size: Vector2 = Vector2(size_data.get("width", 800), size_data.get("height", 600))
	arena_container.position = (Vector2(1280, 720) - arena_size) / 2
	
	var arena_scene: PackedScene = preload("res://scenes/arena.tscn")
	arena = arena_scene.instantiate()
	arena_container.add_child(arena)
	arena.setup(arena_data)
	
	bots_container = Node2D.new()
	bots_container.name = "Bots"
	arena.add_child(bots_container)
	
	projectiles_container = Node2D.new()
	projectiles_container.name = "Projectiles"
	arena.add_child(projectiles_container)

func _clear_arena() -> void:
	if arena_container:
		arena_container.queue_free()
	arena = null
	bots_container = null
	projectiles_container = null

func _start_test_battle() -> void:
	_clear_visuals()
	_clear_battle_ui()
	
	var player_loadouts: Array = GameState.get_active_loadouts()
	if player_loadouts.is_empty():
		player_loadouts = _get_default_loadout()
	
	if battle_manager.setup_battle("arena_boot_camp", player_loadouts):
		_setup_arena(battle_manager.current_arena_data)
		battle_manager.start_battle()

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
	_cached_bot_data.clear()

func _clear_battle_ui() -> void:
	if results_screen:
		results_screen.hide_results()
	if countdown_label:
		countdown_label.visible = false

func _on_battle_started(_arena_id: String) -> void:
	var arena_data: Dictionary = battle_manager.get_current_arena()
	var title_label: Label = $BattleHUD/Title
	if title_label:
		title_label.text = arena_data.get("name", "IRONCORE ARENA")

func _on_battle_state_changed(new_state: BattleManager.BattleState, _old_state: BattleManager.BattleState) -> void:
	match new_state:
		BattleManager.BattleState.COUNTDOWN:
			countdown_label.visible = true
		BattleManager.BattleState.ACTIVE:
			countdown_label.visible = false
			for bot_id in _simulation_manager.bots:
				_create_bot_visual(_simulation_manager.bots[bot_id])
		BattleManager.BattleState.ENDED:
			countdown_label.visible = false

func _on_countdown_tick(seconds_left: int) -> void:
	countdown_label.text = str(seconds_left)
	var tween: Tween = create_tween()
	tween.tween_property(countdown_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(countdown_label, "scale", Vector2.ONE, 0.1)

func _on_battle_ended(result: BattleManager.BattleResult) -> void:
	_last_result = result
	
	# Emit signal for SceneFlowManager
	var result_dict: Dictionary = {
		"victory": result.victory if result else false,
		"grade": result.grade if result else "F",
		"time_seconds": result.time_seconds if result else 0.0,
		"arena_id": "arena_training"
	}
	battle_ended.emit(result_dict)

func _on_rewards_calculated(rewards: Dictionary) -> void:
	_last_rewards = rewards
	if _last_result:
		results_screen.show_results(_last_result, rewards)

func _create_bot_visual(bot) -> void:
	if not bots_container or bot_visuals.has(bot.sim_id):
		return
	
	var visual: Node2D = Node2D.new()
	visual.position = bot.position
	visual.rotation_degrees = bot.rotation
	visual.name = "Bot_%d" % bot.sim_id
	
	# Body
	var body: ColorRect = ColorRect.new()
	body.size = Vector2(bot.radius * 2, bot.radius * 2)
	body.position = Vector2(-bot.radius, -bot.radius)
	body.color = Color(0.2, 0.6, 1.0) if bot.team == 0 else Color(1.0, 0.3, 0.3)
	visual.add_child(body)
	
	# Turret
	var turret: Node2D = Node2D.new()
	turret.name = "Turret"
	
	var turret_base: ColorRect = ColorRect.new()
	turret_base.size = Vector2(bot.radius * 1.2, bot.radius * 1.2)
	turret_base.position = Vector2(-bot.radius * 0.6, -bot.radius * 0.6)
	turret_base.color = Color(0.4, 0.4, 0.4)
	turret.add_child(turret_base)
	
	var barrel: ColorRect = ColorRect.new()
	barrel.size = Vector2(bot.radius * 1.8, 6)
	barrel.position = Vector2(0, -3)
	barrel.color = Color(0.6, 0.6, 0.6)
	turret.add_child(barrel)
	
	visual.add_child(turret)
	
	# HP bar
	var hp_bg: ColorRect = ColorRect.new()
	hp_bg.size = Vector2(bot.radius * 2, 6)
	hp_bg.position = Vector2(-bot.radius, -bot.radius - 12)
	hp_bg.color = Color(0.2, 0.2, 0.2)
	visual.add_child(hp_bg)
	
	var hp_fill: ColorRect = ColorRect.new()
	hp_fill.size = Vector2(bot.radius * 2, 6)
	hp_fill.position = Vector2(-bot.radius, -bot.radius - 12)
	hp_fill.color = Color(0.2, 0.9, 0.2)
	hp_fill.name = "HPBar"
	visual.add_child(hp_fill)
	
	# Selection indicator
	var selection: Node2D = load("res://src/ui/selection_indicator.gd").new()
	selection.name = "SelectionIndicator"
	selection.radius = bot.radius
	visual.add_child(selection)
	
	bots_container.add_child(visual)
	bot_visuals[bot.sim_id] = visual
	_cached_bot_data[bot.sim_id] = bot

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

func _on_entity_moved(sim_id: int, pos: Vector2, rot: float) -> void:
	if bot_visuals.has(sim_id):
		var visual: Node2D = bot_visuals[sim_id]
		visual.position = pos
		visual.rotation_degrees = rot
		
		var turret = visual.get_node_or_null("Turret")
		if turret and _cached_bot_data.has(sim_id):
			var bot = _cached_bot_data[sim_id]
			if bot.target_id != -1 and _simulation_manager.bots.has(bot.target_id):
				var target = _simulation_manager.bots[bot.target_id]
				if target.is_alive:
					turret.rotation_degrees = rad_to_deg((target.position - pos).angle()) - rot

func _on_entity_damaged(sim_id: int, hp: int, max_hp: int) -> void:
	if bot_visuals.has(sim_id):
		var visual: Node2D = bot_visuals[sim_id]
		var hp_bar: ColorRect = visual.get_node_or_null("HPBar")
		if hp_bar:
			var hp_pct: float = float(hp) / float(max_hp)
			hp_bar.size.x = visual.get_child(0).size.x * hp_pct
			
			if hp_pct > 0.5:
				hp_bar.color = Color(0.2, 0.9, 0.2)
			elif hp_pct > 0.25:
				hp_bar.color = Color(0.9, 0.9, 0.2)
			else:
				hp_bar.color = Color(0.9, 0.2, 0.2)

func _on_entity_destroyed(sim_id: int, _team: int) -> void:
	if bot_visuals.has(sim_id):
		var visual: Node2D = bot_visuals[sim_id]
		
		if arena:
			var explosion: ColorRect = ColorRect.new()
			explosion.size = Vector2(40, 40)
			explosion.position = visual.position - Vector2(20, 20)
			explosion.color = Color(1.0, 0.5, 0.0, 0.8)
			arena.add_child(explosion)
			
			var tween: Tween = create_tween()
			tween.tween_property(explosion, "modulate:a", 0.0, 0.5)
			tween.tween_callback(explosion.queue_free)
		
		visual.queue_free()
		bot_visuals.erase(sim_id)
		_cached_bot_data.erase(sim_id)

func _on_projectile_spawned(proj_id: int, position: Vector2, direction: Vector2) -> void:
	_create_projectile_visual(proj_id, position, direction)

func _on_projectile_destroyed(proj_id: int) -> void:
	if projectile_visuals.has(proj_id):
		projectile_visuals[proj_id].queue_free()
		projectile_visuals.erase(proj_id)

func _on_tick_processed(_tick: int) -> void:
	for proj_id in _simulation_manager.projectiles:
		var proj = _simulation_manager.projectiles[proj_id]
		if projectile_visuals.has(proj_id):
			projectile_visuals[proj_id].position = proj.position - Vector2(4, 2)
	
	_update_hud()

func _update_hud() -> void:
	var summary: Dictionary = battle_manager.get_battle_summary()
	var instructions: Label = $BattleHUD/Instructions
	if instructions and battle_manager.is_battle_active():
		instructions.text = "%s | Time: %s | Enemies: %d/%d" % [
			summary["arena_name"],
			summary["time"],
			summary["enemy_alive"],
			summary["enemy_total"]
		]

func _on_results_continue() -> void:
	if _last_result and _last_result.victory:
		pass  # TODO: Navigate to next arena
	else:
		_start_test_battle()

func _on_results_restart() -> void:
	_start_test_battle()

func _on_results_edit() -> void:
	battle_manager.end_battle_early()
	get_tree().change_scene_to_file("res://scenes/build_screen.tscn")

func _on_results_next() -> void:
	pass  # TODO: Load next arena

func _input(event: InputEvent) -> void:
	if not battle_manager.is_battle_active():
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start(event.position)
		else:
			_drag_end(event.position)

func _drag_start(screen_pos: Vector2) -> void:
	if not arena_container:
		return
	
	var world_pos: Vector2 = _screen_to_arena(screen_pos)
	
	for bot_id in _simulation_manager.bots:
		var bot = _simulation_manager.bots[bot_id]
		if bot.team == 0 and bot.is_alive and world_pos.distance_to(bot.position) < bot.radius * 1.5:
			selected_bot_id = bot_id
			is_dragging = true
			return

func _drag_end(screen_pos: Vector2) -> void:
	if not is_dragging or selected_bot_id == -1:
		is_dragging = false
		selected_bot_id = -1
		return
	
	var world_pos: Vector2 = _screen_to_arena(screen_pos)
	var command_type: String = "move"
	var target: Variant = world_pos
	
	for bot_id in _simulation_manager.bots:
		if bot_id == selected_bot_id:
			continue
		var bot = _simulation_manager.bots[bot_id]
		if not bot.is_alive:
			continue
		
		if world_pos.distance_to(bot.position) < bot.radius * 2.0:
			command_type = "follow" if bot.team == 0 else "focus"
			target = bot_id
			break
	
	_simulation_manager.issue_command(selected_bot_id, command_type, target)
	
	is_dragging = false
	selected_bot_id = -1

func _screen_to_arena(screen_pos: Vector2) -> Vector2:
	if not arena_container:
		return screen_pos
	return screen_pos - arena_container.position

func start_campaign_battle(arena_id: String) -> void:
	_clear_visuals()
	_clear_battle_ui()
	
	var player_loadouts: Array = GameState.get_active_loadouts()
	if player_loadouts.is_empty():
		player_loadouts = _get_default_loadout()
	
	if battle_manager.setup_battle(arena_id, player_loadouts):
		_setup_arena(battle_manager.current_arena_data)
		battle_manager.start_battle()


func on_hide() -> void:
	visible = false
	battle_manager.end_battle_early()

# ============================================================================
# SELECTION INDICATOR METHODS
# ============================================================================

func show_bot_selection(bot_id: int, is_group_leader: bool = false) -> void:
	## Show selection indicator for a bot
	if bot_visuals.has(bot_id):
		var visual: Node2D = bot_visuals[bot_id]
		var indicator: Node = visual.get_node_or_null("SelectionIndicator")
		if indicator:
			if is_group_leader:
				indicator.indicator_type = indicator.IndicatorType.GROUP_LEADER
			else:
				indicator.indicator_type = indicator.IndicatorType.SINGLE
			indicator.show_selection()

func hide_bot_selection(bot_id: int) -> void:
	## Hide selection indicator for a bot
	if bot_visuals.has(bot_id):
		var visual: Node2D = bot_visuals[bot_id]
		var indicator: Node = visual.get_node_or_null("SelectionIndicator")
		if indicator:
			indicator.hide_selection()

func show_bot_hover(bot_id: int) -> void:
	## Show hover indicator for a bot
	if bot_visuals.has(bot_id):
		var visual: Node2D = bot_visuals[bot_id]
		var indicator: Node = visual.get_node_or_null("SelectionIndicator")
		if indicator:
			indicator.show_hover()

func hide_bot_hover(bot_id: int) -> void:
	## Hide hover indicator for a bot
	if bot_visuals.has(bot_id):
		var visual: Node2D = bot_visuals[bot_id]
		var indicator: Node = visual.get_node_or_null("SelectionIndicator")
		if indicator:
			indicator.hide_hover()

func clear_all_selections() -> void:
	## Hide all selection indicators
	for bot_id in bot_visuals:
		hide_bot_selection(bot_id)
