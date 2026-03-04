class_name TestFixtures extends RefCounted

## Helper class for creating test scenarios and fixtures.
##
## This class provides static factory methods for creating
## common test scenarios, reducing boilerplate in test files.

const DEFAULT_BOT_RADIUS: float = 10.0
const DEFAULT_BOT_SPEED: float = 100.0
const DEFAULT_BOT_HEALTH: float = 100.0
const DEFAULT_ARENA_SIZE: Vector2 = Vector2(800, 600)


## Creates a simple arena scene with basic setup.
##
## [param size] The size of the arena (default 800x600)
## [param with_walls] Whether to add boundary walls
## Returns: Configured arena node
static func create_simple_arena(size: Vector2 = DEFAULT_ARENA_SIZE, with_walls: bool = true) -> Node2D:
    var arena: Node2D = Node2D.new()
    arena.name = "TestArena"
    arena.set_meta("is_arena", true)
    
    # Add bot container
    var bot_container: Node2D = Node2D.new()
    bot_container.name = "bots"
    arena.add_child(bot_container)
    
    # Add projectile container
    var proj_container: Node2D = Node2D.new()
    proj_container.name = "projectiles"
    arena.add_child(proj_container)
    
    # Add effects container
    var effects_container: Node2D = Node2D.new()
    effects_container.name = "effects"
    arena.add_child(effects_container)
    
    # Add walls if requested
    if with_walls:
        _add_boundary_walls(arena, size)
    
    return arena


## Creates a bot with the specified loadout.
##
## [param loadout] Dictionary with bot configuration:
##   - position: Vector2 (default: Vector2.ZERO)
##   - team_id: int (default: 0)
##   - health: float (default: 100.0)
##   - speed: float (default: 100.0)
##   - armor: float (default: 0.0)
##   - radius: float (default: 10.0)
##   - weapon: String (default: "rifle")
## Returns: Configured bot node
static func create_bot_with_loadout(loadout: Dictionary = {}) -> CharacterBody2D:
    var bot: CharacterBody2D = CharacterBody2D.new()
    
    # Set position
    var pos: Vector2 = loadout.get("position", Vector2.ZERO)
    bot.position = pos
    
    # Set name
    var bot_name: String = loadout.get("name", "TestBot")
    bot.name = bot_name
    bot.set_meta("is_bot", true)
    
    # Core properties
    bot.set("sim_id", loadout.get("sim_id", -1))
    bot.set("team_id", loadout.get("team_id", 0))
    bot.set("health", loadout.get("health", DEFAULT_BOT_HEALTH))
    bot.set("max_health", loadout.get("max_health", DEFAULT_BOT_HEALTH))
    bot.set("armor", loadout.get("armor", 0.0))
    bot.set("movement_speed", loadout.get("speed", DEFAULT_BOT_SPEED))
    bot.set("velocity", loadout.get("velocity", Vector2.ZERO))
    
    # State properties
    bot.set("current_state", loadout.get("state", "idle"))
    bot.set("state_time", 0.0)
    bot.set("target_id", loadout.get("target_id", -1))
    bot.set("path_index", loadout.get("path_index", 0))
    
    # Combat properties
    bot.set("weapon_cooldown", 0.0)
    bot.set("current_ammo", loadout.get("ammo", 30))
    bot.set("fire_rate", loadout.get("fire_rate", 3.0))
    
    # Add collision shape
    var radius: float = loadout.get("radius", DEFAULT_BOT_RADIUS)
    _add_circle_collision(bot, radius)
    
    # Add weapon if specified
    if loadout.has("weapon"):
        var weapon: Node = create_test_weapon(loadout["weapon"])
        bot.add_child(weapon)
    
    return bot


## Creates a standard test bot with default settings.
##
## [param position] Bot spawn position
## [param team_id] Team identifier
## [param sim_id] Simulation-unique ID
## Returns: Configured bot node
static func create_standard_bot(position: Vector2 = Vector2.ZERO, team_id: int = 0, sim_id: int = -1) -> CharacterBody2D:
    var loadout: Dictionary = {
        "position": position,
        "team_id": team_id,
        "sim_id": sim_id,
        "health": 100.0,
        "speed": 100.0,
        "state": "active"
    }
    return create_bot_with_loadout(loadout)


## Creates a test weapon node.
##
## [param weapon_type] Type of weapon:
##   - "rifle": Standard rifle (damage: 25, fire_rate: 3)
##   - "sniper": High damage, slow fire (damage: 80, fire_rate: 0.5)
##   - "smg": Low damage, fast fire (damage: 12, fire_rate: 10)
##   - "shotgun": Spread shot (damage: 15x5, fire_rate: 1)
## Returns: Configured weapon node
static func create_test_weapon(weapon_type: String = "rifle") -> Node:
    var weapon: Node = Node.new()
    weapon.name = "Weapon_%s" % weapon_type.capitalize()
    weapon.set_meta("is_weapon", true)
    
    match weapon_type.to_lower():
        "rifle":
            weapon.set("damage", 25.0)
            weapon.set("fire_rate", 3.0)
            weapon.set("projectile_speed", 500.0)
            weapon.set("ammo_capacity", 30)
            weapon.set("reload_time", 2.0)
        "sniper":
            weapon.set("damage", 80.0)
            weapon.set("fire_rate", 0.5)
            weapon.set("projectile_speed", 1000.0)
            weapon.set("ammo_capacity", 5)
            weapon.set("reload_time", 3.0)
        "smg":
            weapon.set("damage", 12.0)
            weapon.set("fire_rate", 10.0)
            weapon.set("projectile_speed", 400.0)
            weapon.set("ammo_capacity", 50)
            weapon.set("reload_time", 2.5)
        "shotgun":
            weapon.set("damage", 15.0)
            weapon.set("pellet_count", 5)
            weapon.set("fire_rate", 1.0)
            weapon.set("projectile_speed", 350.0)
            weapon.set("ammo_capacity", 8)
            weapon.set("reload_time", 4.0)
        _:
            # Default to rifle
            weapon.set("damage", 25.0)
            weapon.set("fire_rate", 3.0)
            weapon.set("projectile_speed", 500.0)
            weapon.set("ammo_capacity", 30)
            weapon.set("reload_time", 2.0)
    
    weapon.set("weapon_type", weapon_type)
    return weapon


## Creates a test projectile.
##
## [param owner] The bot that fired this projectile
## [param velocity] Projectile velocity vector
## [param damage] Damage dealt on hit
## Returns: Configured projectile node
static func create_projectile(owner: Node = null, velocity: Vector2 = Vector2.ZERO, damage: float = 25.0) -> Area2D:
    var proj: Area2D = Area2D.new()
    proj.name = "TestProjectile"
    proj.set_meta("is_projectile", true)
    
    if owner != null:
        proj.position = owner.position + Vector2.RIGHT.rotated(owner.get("rotation")) * 20.0
        proj.set("owner_id", owner.get("sim_id"))
    else:
        proj.position = Vector2.ZERO
        proj.set("owner_id", -1)
    
    proj.set("velocity", velocity)
    proj.set("damage", damage)
    proj.set("lifetime", 0.0)
    proj.set("max_lifetime", 5.0)
    proj.set("bounce_count", 0)
    proj.set("max_bounces", 0)
    proj.set("projectile_type", "bullet")
    
    # Add collision
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = 5.0
    collision.shape = shape
    proj.add_child(collision)
    
    return proj


## Creates a wall/obstacle.
##
## [param position] Wall center position
## [param size] Wall dimensions
## [param rotation] Wall rotation in radians
## Returns: Configured wall node
static func create_wall(position: Vector2 = Vector2.ZERO, size: Vector2 = Vector2(100, 20), rotation: float = 0.0) -> StaticBody2D:
    var wall: StaticBody2D = StaticBody2D.new()
    wall.name = "Wall"
    wall.position = position
    wall.rotation = rotation
    wall.set_meta("is_wall", true)
    
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: RectangleShape2D = RectangleShape2D.new()
    shape.size = size
    collision.shape = shape
    wall.add_child(collision)
    
    return wall


## Creates a team vs team scenario.
##
## [param team_size] Number of bots per team
## [param arena_size] Size of the arena
## Returns: Arena node with bots configured for team battle
static func create_team_battle_scenario(team_size: int = 5, arena_size: Vector2 = DEFAULT_ARENA_SIZE) -> Node2D:
    var arena: Node2D = create_simple_arena(arena_size, true)
    
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(12345)
    
    # Spawn team 0 on left side
    for i in range(team_size):
        var pos: Vector2 = Vector2(
            rng.next_float_range(50, arena_size.x * 0.3),
            rng.next_float_range(50, arena_size.y - 50)
        )
        var bot: CharacterBody2D = create_standard_bot(pos, 0, i)
        arena.get_node("bots").add_child(bot)
    
    # Spawn team 1 on right side
    for i in range(team_size):
        var pos: Vector2 = Vector2(
            rng.next_float_range(arena_size.x * 0.7, arena_size.x - 50),
            rng.next_float_range(50, arena_size.y - 50)
        )
        var bot: CharacterBody2D = create_standard_bot(pos, 1, team_size + i)
        arena.get_node("bots").add_child(bot)
    
    return arena


## Creates a free-for-all scenario.
##
## [param bot_count] Total number of bots
## [param arena_size] Size of the arena
## [param seed] Random seed for spawn positions
## Returns: Arena node with randomly positioned bots
static func create_ffa_scenario(bot_count: int = 10, arena_size: Vector2 = DEFAULT_ARENA_SIZE, seed: int = 12345) -> Node2D:
    var arena: Node2D = create_simple_arena(arena_size, true)
    
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(seed)
    
    for i in range(bot_count):
        var pos: Vector2 = Vector2(
            rng.next_float_range(50, arena_size.x - 50),
            rng.next_float_range(50, arena_size.y - 50)
        )
        var bot: CharacterBody2D = create_standard_bot(pos, i % 2, i)
        arena.get_node("bots").add_child(bot)
    
    return arena


## Creates a collision test scenario.
##
## [param bot_count] Number of bots to spawn close together
## [param center] Center position for the cluster
## [param spread] Maximum distance from center
## Returns: Arena node with clustered bots
static func create_collision_scenario(bot_count: int = 5, center: Vector2 = Vector2(400, 300), spread: float = 50.0) -> Node2D:
    var arena: Node2D = create_simple_arena(DEFAULT_ARENA_SIZE, false)
    
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(98765)
    
    for i in range(bot_count):
        var offset: Vector2 = Vector2(
            rng.next_float_range(-spread, spread),
            rng.next_float_range(-spread, spread)
        )
        var bot: CharacterBody2D = create_standard_bot(center + offset, 0, i)
        bot.set("velocity", Vector2(
            rng.next_float_range(-100, 100),
            rng.next_float_range(-100, 100)
        ))
        arena.get_node("bots").add_child(bot)
    
    return arena


## Creates a shooting test scenario with targets.
##
## [param shooter_pos] Position of the shooting bot
## [param target_positions] Array of target positions
## Returns: Arena node with shooter and targets
static func create_shooting_scenario(shooter_pos: Vector2 = Vector2(100, 300), target_positions: Array = []) -> Node2D:
    var arena: Node2D = create_simple_arena(DEFAULT_ARENA_SIZE, false)
    
    # Create shooter
    var shooter: CharacterBody2D = create_standard_bot(shooter_pos, 0, 0)
    shooter.set("current_ammo", 100)
    shooter.set("weapon_cooldown", 0.0)
    shooter.set("fire_rate", 5.0)
    arena.get_node("bots").add_child(shooter)
    
    # Create targets
    if target_positions.is_empty():
        target_positions = [Vector2(300, 300), Vector2(500, 300), Vector2(700, 300)]
    
    for i in range(target_positions.size()):
        var target: CharacterBody2D = create_standard_bot(target_positions[i], 1, i + 1)
        target.set("health", 100.0)
        arena.get_node("bots").add_child(target)
    
    return arena


## Creates a minimal simulation for unit tests.
##
## [param seed] Random seed for the simulation
## Returns: Minimal simulation node
static func create_minimal_simulation(seed: int = 0) -> Node:
    var sim: Node = Node2D.new()
    sim.name = "MinimalSimulation"
    sim.set_meta("is_simulation", true)
    sim.set("current_tick", 0)
    sim.set("simulation_time", 0.0)
    sim.set("random_seed", seed)
    sim.set("is_paused", false)
    
    var bot_container: Node2D = Node2D.new()
    bot_container.name = "bots"
    sim.add_child(bot_container)
    
    var proj_container: Node2D = Node2D.new()
    proj_container.name = "projectiles"
    sim.add_child(proj_container)
    
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(seed)
    sim.set("_rng", rng)
    
    return sim


## Adds a circle collision shape to a node.
##
## [param node] The node to add collision to
## [param radius] Circle radius
static func _add_circle_collision(node: Node, radius: float) -> void:
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = radius
    collision.shape = shape
    node.add_child(collision)


## Adds boundary walls to an arena.
##
## [param arena] The arena node
## [param size] Arena dimensions
static func _add_boundary_walls(arena: Node2D, size: Vector2) -> void:
    var wall_thickness: float = 20.0
    
    # Top wall
    var top_wall: StaticBody2D = create_wall(
        Vector2(size.x / 2, -wall_thickness / 2),
        Vector2(size.x + wall_thickness * 2, wall_thickness)
    )
    arena.add_child(top_wall)
    
    # Bottom wall
    var bottom_wall: StaticBody2D = create_wall(
        Vector2(size.x / 2, size.y + wall_thickness / 2),
        Vector2(size.x + wall_thickness * 2, wall_thickness)
    )
    arena.add_child(bottom_wall)
    
    # Left wall
    var left_wall: StaticBody2D = create_wall(
        Vector2(-wall_thickness / 2, size.y / 2),
        Vector2(wall_thickness, size.y)
    )
    arena.add_child(left_wall)
    
    # Right wall
    var right_wall: StaticBody2D = create_wall(
        Vector2(size.x + wall_thickness / 2, size.y / 2),
        Vector2(wall_thickness, size.y)
    )
    arena.add_child(right_wall)


## Utility: Creates a DeterministicRng with the given seed.
##
## [param seed] The seed value
## Returns: Configured DeterministicRng
static func create_rng(seed: int = 0) -> DeterministicRng:
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(seed)
    return rng


## Utility: Creates a spawn position grid.
##
## [param count] Number of positions to generate
## [param arena_size] Size of the arena
## [param margin] Margin from edges
## Returns: Array of Vector2 positions
static func create_spawn_grid(count: int, arena_size: Vector2 = DEFAULT_ARENA_SIZE, margin: float = 50.0) -> Array:
    var positions: Array = []
    
    var cols: int = int(ceil(sqrt(count)))
    var rows: int = int(ceil(float(count) / cols))
    
    var available_width: float = arena_size.x - margin * 2
    var available_height: float = arena_size.y - margin * 2
    
    var spacing_x: float = available_width / (cols + 1)
    var spacing_y: float = available_height / (rows + 1)
    
    for i in range(count):
        var col: int = i % cols
        var row: int = i / cols
        
        var pos: Vector2 = Vector2(
            margin + spacing_x * (col + 1),
            margin + spacing_y * (row + 1)
        )
        positions.append(pos)
    
    return positions
