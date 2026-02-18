extends Control
## BattleScreen — arena view, HUD, command input.

@onready var arena_container: Node2D = $ArenaContainer
@onready var bots_container: Node2D = $ArenaContainer/Bots
@onready var projectiles_container: Node2D = $ArenaContainer/Projectiles
@onready var hud: Control = $BattleHUD

# Visual representations
var bot_visuals: Dictionary = {}  # sim_id -> Node2D
var projectile_visuals: Dictionary = {}  # proj_id -> Node2D

# Camera
var camera: Camera2D = null

# Input state
var selected_bot_id: int = -1
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO

# Battle state
var battle_active: bool = false


func _ready() -> void:
	_setup_signals()
	
	# Start test battle after short delay
	await get_tree().create_timer(0.5).timeout
	_start_test_battle()


func _setup_signals() -> void:
	if SimulationManager:
		SimulationManager.entity_moved.connect(_on_entity_moved)
		SimulationManager.entity_damaged.connect(_on_entity_damaged)
		SimulationManager.entity_destroyed.connect(_on_entity_destroyed)
		SimulationManager.projectile_spawned.connect(_on_projectile_spawned)
		SimulationManager.projectile_destroyed.connect(_on_projectile_destroyed)
		SimulationManager.battle_ended.connect(_on_battle_ended)
		SimulationManager.tick_processed.connect(_on_tick_processed)


func _start_test_battle() -> void:
	## Start a test battle with simple bots
	_clear_visuals()
	_clear_battle_ui()
	
	# Get arena data - 1280x720 arena
	var arena_data: Dictionary = {
		"id": "test_arena",
		"size": {"width": 1280, "height": 720},
		"spawn_points_player": [{"x": 200, "y": 360}],  # Center left
		"spawn_points_enemy": [{"x": 1080, "y": 360}],  # Center right
		"obstacles": [],
		"seed": 12345
	}
	
	# Player loadout
	var player_loadouts: Array = [{
		"id": "player_bot",
		"name": "Player Scout",
		"chassis": "chassis_light_t1",
		"weapons": ["wpn_mg_t1"],
		"armor": [],
		"mobility": ["mob_wheels_t1"],
		"sensors": ["sen_basic_t1"],
		"utilities": [],
		"ai_profile": "ai_balanced"
	}]
	
	# Enemy loadout
	var enemy_loadouts: Array = [{
		"id": "enemy_bot",
		"name": "Enemy Scout",
		"chassis": "chassis_light_t1",
		"weapons": ["wpn_mg_t1"],
		"armor": [],
		"mobility": ["mob_wheels_t1"],
		"sensors": ["sen_basic_t1"],
		"utilities": [],
		"ai_profile": "ai_aggressive"
	}]
	
	SimulationManager.start_battle(arena_data, player_loadouts, enemy_loadouts, false)
	battle_active = true
	print("Battle started, bots count: ", SimulationManager.bots.size())
	
	# Create visual representations for existing bots
	for bot_id in SimulationManager.bots:
		print("Creating visual for bot: ", bot_id)
		_create_bot_visual(SimulationManager.bots[bot_id])


func _clear_visuals() -> void:
	for child in bots_container.get_children():
		child.queue_free()
	for child in projectiles_container.get_children():
		child.queue_free()
	bot_visuals.clear()
	projectile_visuals.clear()


func _clear_battle_ui() -> void:
	## Remove result labels and buttons from previous battle
	for child in get_children():
		if child is Label and child != $BattleHUD/Title and child != $BattleHUD/Instructions:
			child.queue_free()
		if child is Button:
			child.queue_free()


func _create_bot_visual(bot) -> void:
	print("Creating bot visual at position: ", bot.position, " team: ", bot.team)
	
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
	var visual: ColorRect = ColorRect.new()
	visual.size = Vector2(8, 4)
	visual.position = position - Vector2(4, 2)
	visual.rotation = direction.angle()
	visual.color = Color(1.0, 0.8, 0.2)
	
	projectiles_container.add_child(visual)
	projectile_visuals[proj_id] = visual


func _on_entity_moved(sim_id: int, position: Vector2, rotation: float) -> void:
	if bot_visuals.has(sim_id):
		var visual: Node2D = bot_visuals[sim_id]
		visual.position = position
		# Only rotate chassis, turret rotates separately toward target
		visual.rotation_degrees = rotation
		
		# Update turret to face target
		if SimulationManager.bots.has(sim_id):
			var bot = SimulationManager.bots[sim_id]
			var turret = visual.get_node_or_null("Turret")
			if turret and bot.target_id != -1 and SimulationManager.bots.has(bot.target_id):
				var target = SimulationManager.bots[bot.target_id]
				if target.is_alive:
					var target_angle: float = rad_to_deg((target.position - position).angle())
					turret.rotation_degrees = target_angle - rotation


func _on_entity_damaged(sim_id: int, hp: int, max_hp: int) -> void:
	if bot_visuals.has(sim_id):
		var visual: Node2D = bot_visuals[sim_id]
		var hp_bar: ColorRect = visual.get_node_or_null("HPBar")
		if hp_bar:
			var hp_pct: float = float(hp) / float(max_hp)
			hp_bar.size.x = visual.get_child(0).size.x * hp_pct
			
			# Color change based on HP
			if hp_pct > 0.5:
				hp_bar.color = Color(0.2, 0.9, 0.2)
			elif hp_pct > 0.25:
				hp_bar.color = Color(0.9, 0.9, 0.2)
			else:
				hp_bar.color = Color(0.9, 0.2, 0.2)


func _on_entity_destroyed(sim_id: int, team: int) -> void:
	if bot_visuals.has(sim_id):
		var visual: Node2D = bot_visuals[sim_id]
		
		# Visual effect for destruction
		var explosion: ColorRect = ColorRect.new()
		explosion.size = Vector2(40, 40)
		explosion.position = visual.position - Vector2(20, 20)
		explosion.color = Color(1.0, 0.5, 0.0, 0.8)
		arena_container.add_child(explosion)
		
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


func _on_battle_ended(result: String, tick_count: int) -> void:
	battle_active = false
	print("Battle ended: ", result, " in ", tick_count, " ticks")
	
	# Show result label
	var result_label: Label = Label.new()
	result_label.text = "RESULT: " + result + "\nTicks: " + str(tick_count)
	result_label.position = Vector2(540, 300)  # Center of 1280x720
	result_label.add_theme_font_size_override("font_size", 24)
	add_child(result_label)
	
	# Restart button
	var restart_btn: Button = Button.new()
	restart_btn.text = "Restart Battle"
	restart_btn.position = Vector2(580, 380)
	restart_btn.pressed.connect(_start_test_battle)
	add_child(restart_btn)


func _on_tick_processed(tick: int) -> void:
	# Update projectile positions
	for proj_id in SimulationManager.projectiles:
		var proj = SimulationManager.projectiles[proj_id]
		if projectile_visuals.has(proj_id):
			projectile_visuals[proj_id].position = proj.position - Vector2(4, 2)


func _input(event: InputEvent) -> void:
	if not battle_active:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_start(event.position)
			else:
				_drag_end(event.position)


func _drag_start(screen_pos: Vector2) -> void:
	# Convert to world position
	var world_pos: Vector2 = _screen_to_world(screen_pos)
	
	# Find bot under cursor
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
	
	var world_pos: Vector2 = _screen_to_world(screen_pos)
	
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
	
	# Issue command
	SimulationManager.issue_command(selected_bot_id, command_type, target)
	print("Issued command: ", command_type, " to ", target)
	
	is_dragging = false
	selected_bot_id = -1


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	# Simple conversion — arena is 1280x720
	return screen_pos.clamp(Vector2.ZERO, Vector2(1280, 720))


func on_show() -> void:
	visible = true
	if not battle_active:
		_start_test_battle()


func on_hide() -> void:
	visible = false
	SimulationManager.stop_battle()
	battle_active = false
