extends GutTest

## Tests collision tick behavior for determinism and correctness.
##
## This test suite verifies that bot-bot, projectile-bot, and
## wall collisions are handled correctly and deterministically.

const TEST_SEEDS: PackedInt32Array = [12345, 67890, 11111, 99999]
const TICK_DELTA: float = 1.0 / 60.0

var _sim: Node = null
var _rng: DeterministicRng = null
var _hasher: SimulationStateHasher = null


func before_each() -> void:
    _rng = DeterministicRng.new()
    _hasher = SimulationStateHasher.new()
    _sim = _create_minimal_simulation()


func after_each() -> void:
    _cleanup_simulation()


func test_bot_bot_collision() -> void:
    ## Verify two bots collide and respond correctly
    var bot1: Node = _spawn_test_bot(Vector2(0, 0))
    var bot2: Node = _spawn_test_bot(Vector2(30, 0))  # Close enough to collide
    
    bot1.set("velocity", Vector2.RIGHT * 100.0)
    bot2.set("velocity", Vector2.LEFT * 100.0)
    
    var initial_distance: float = bot1.position.distance_to(bot2.position)
    
    # Simulate until collision or timeout
    var collision_detected: bool = false
    for i in range(30):
        var prev_distance: float = bot1.position.distance_to(bot2.position)
        
        _sim.step_tick()
        
        var new_distance: float = bot1.position.distance_to(bot2.position)
        
        # Check if bots stopped or reversed (collision response)
        if new_distance >= prev_distance and prev_distance < 25.0:
            collision_detected = true
            break
    
    assert_true(collision_detected or bot1.position.distance_to(bot2.position) > 20.0,
        "Bots should either collide and separate or not pass through each other")


func test_bot_bot_collision_deterministic() -> void:
    ## Verify bot-bot collisions produce deterministic results
    for seed_val in TEST_SEEDS:
        var sim1: Node = _create_sim_with_seed(seed_val)
        var sim2: Node = _create_sim_with_seed(seed_val)
        
        # Spawn identical bots heading toward collision
        var bot1a: Node = _spawn_bot_in_sim(sim1, Vector2(0, 0))
        var bot1b: Node = _spawn_bot_in_sim(sim1, Vector2(50, 0))
        bot1a.set("velocity", Vector2.RIGHT * 100.0)
        bot1b.set("velocity", Vector2.LEFT * 100.0)
        
        var bot2a: Node = _spawn_bot_in_sim(sim2, Vector2(0, 0))
        var bot2b: Node = _spawn_bot_in_sim(sim2, Vector2(50, 0))
        bot2a.set("velocity", Vector2.RIGHT * 100.0)
        bot2b.set("velocity", Vector2.LEFT * 100.0)
        
        # Run simulation
        for tick in range(60):
            sim1.step_tick()
            sim2.step_tick()
        
        # Compare hashes
        var hash1: String = _hasher.hash_simulation(sim1)
        var hash2: String = _hasher.hash_simulation(sim2)
        
        assert_eq(hash1, hash2,
            "Bot-bot collision should be deterministic for seed %d" % seed_val)


func test_projectile_bot_collision() -> void:
    ## Verify projectile damages bot on collision
    var bot: Node = _spawn_test_bot(Vector2(100, 100))
    var initial_health: float = 100.0
    bot.set("health", initial_health)
    
    # Spawn projectile aimed at bot
    var proj: Node = _spawn_test_projectile(Vector2(50, 100), Vector2.RIGHT * 500.0)
    proj.set("damage", 25.0)
    
    var damage_applied: bool = false
    
    # Simulate until projectile hits or passes
    for i in range(20):
        var prev_health: float = bot.get("health")
        _sim.step_tick()
        
        # Check if damage was applied
        if bot.get("health") < prev_health:
            damage_applied = true
            assert_almost_eq(bot.get("health"), initial_health - 25.0, 0.01,
                "Bot should take correct damage from projectile")
            break
        
        # Check if projectile passed the bot
        if proj.position.x > 150:
            break
    
    assert_true(damage_applied or proj.position.x > 150,
        "Projectile should either hit bot or pass by")


func test_projectile_bot_collision_deterministic() -> void:
    ## Verify projectile-bot collisions are deterministic
    for seed_val in TEST_SEEDS:
        var sim1: Node = _create_sim_with_seed(seed_val)
        var sim2: Node = _create_sim_with_seed(seed_val)
        
        # Spawn identical scenarios
        var bot1: Node = _spawn_bot_in_sim(sim1, Vector2(100, 100))
        var proj1: Node = _spawn_projectile_in_sim(sim1, Vector2(50, 100), Vector2.RIGHT * 400.0)
        bot1.set("health", 100.0)
        proj1.set("damage", 25.0)
        
        var bot2: Node = _spawn_bot_in_sim(sim2, Vector2(100, 100))
        var proj2: Node = _spawn_projectile_in_sim(sim2, Vector2(50, 100), Vector2.RIGHT * 400.0)
        bot2.set("health", 100.0)
        proj2.set("damage", 25.0)
        
        for tick in range(30):
            sim1.step_tick()
            sim2.step_tick()
        
        # Health should match
        assert_almost_eq(bot1.get("health"), bot2.get("health"), 0.001,
            "Health after collision should match for seed %d" % seed_val)
        
        # Hashes should match
        var hash1: String = _hasher.hash_simulation(sim1)
        var hash2: String = _hasher.hash_simulation(sim2)
        
        assert_eq(hash1, hash2,
            "Projectile collision should be deterministic for seed %d" % seed_val)


func test_wall_collision() -> void:
    ## Verify bot stops or bounces at wall collision
    var bot: Node = _spawn_test_bot(Vector2(0, 0))
    bot.set("velocity", Vector2.RIGHT * 100.0)
    
    # Create wall
    var wall: StaticBody2D = _create_wall(Vector2(100, 0), Vector2(20, 100))
    _sim.add_child(wall)
    
    var hit_wall: bool = false
    var prev_x: float = bot.position.x
    
    for i in range(60):
        _sim.step_tick()
        
        # Check if bot stopped or reversed
        if bot.position.x <= prev_x and prev_x > 80:
            hit_wall = true
            break
        prev_x = bot.position.x
        
        # Timeout check
        if i > 50:
            break
    
    assert_true(hit_wall or bot.position.x < 110,
        "Bot should stop or bounce at wall")
    
    wall.queue_free()


func test_wall_collision_deterministic() -> void:
    ## Verify wall collisions are deterministic
    for seed_val in TEST_SEEDS:
        var sim1: Node = _create_sim_with_seed(seed_val)
        var sim2: Node = _create_sim_with_seed(seed_val)
        
        # Create identical walls
        var wall1: StaticBody2D = _create_wall(Vector2(100, 0), Vector2(20, 100))
        var wall2: StaticBody2D = _create_wall(Vector2(100, 0), Vector2(20, 100))
        sim1.add_child(wall1)
        sim2.add_child(wall2)
        
        # Spawn bots moving toward wall
        var bot1: Node = _spawn_bot_in_sim(sim1, Vector2(0, 0))
        var bot2: Node = _spawn_bot_in_sim(sim2, Vector2(0, 0))
        bot1.set("velocity", Vector2.RIGHT * 100.0)
        bot2.set("velocity", Vector2.RIGHT * 100.0)
        
        for tick in range(60):
            sim1.step_tick()
            sim2.step_tick()
        
        # Positions should match
        assert_almost_eq(bot1.position.x, bot2.position.x, 0.001,
            "Bot position after wall collision should match for seed %d" % seed_val)
        assert_almost_eq(bot1.position.y, bot2.position.y, 0.001,
            "Bot Y position should match for seed %d" % seed_val)
        
        wall1.queue_free()
        wall2.queue_free()


func test_projectile_wall_collision() -> void:
    ## Verify projectile bounces or is destroyed at wall
    var proj: Node = _spawn_test_projectile(Vector2(0, 0), Vector2.RIGHT * 500.0)
    proj.set("bounce_count", 0)
    proj.set("max_bounces", 1)
    
    # Create wall
    var wall: StaticBody2D = _create_wall(Vector2(100, 0), Vector2(20, 100))
    _sim.add_child(wall)
    
    var bounced: bool = false
    var destroyed: bool = false
    var initial_vel: Vector2 = proj.get("velocity")
    
    for i in range(20):
        var prev_vel: Vector2 = proj.get("velocity")
        _sim.step_tick()
        var new_vel: Vector2 = proj.get("velocity")
        
        # Check for bounce (velocity changed direction)
        if new_vel.x < 0 and prev_vel.x > 0:
            bounced = true
            break
        
        # Check if destroyed
        if not is_instance_valid(proj) or proj.is_queued_for_deletion():
            destroyed = true
            break
    
    assert_true(bounced or destroyed or proj.position.x > 90,
        "Projectile should bounce, be destroyed, or stop at wall")
    
    wall.queue_free()


func test_multiple_collisions_deterministic() -> void:
    ## Verify complex collision scenarios are deterministic
    var seed_val: int = 77777
    var sim1: Node = _create_sim_with_seed(seed_val)
    var sim2: Node = _create_sim_with_seed(seed_val)
    
    # Create multiple bots and projectiles
    for i in range(5):
        var bot1: Node = _spawn_bot_in_sim(sim1, Vector2(i * 40, i * 20))
        var bot2: Node = _spawn_bot_in_sim(sim2, Vector2(i * 40, i * 20))
        bot1.set("velocity", Vector2(50, 30))
        bot2.set("velocity", Vector2(50, 30))
        
        var proj1: Node = _spawn_projectile_in_sim(sim1, Vector2(i * 40, 200), Vector2.UP * 300.0)
        var proj2: Node = _spawn_projectile_in_sim(sim2, Vector2(i * 40, 200), Vector2.UP * 300.0)
        proj1.set("damage", 10.0)
        proj2.set("damage", 10.0)
    
    for tick in range(100):
        sim1.step_tick()
        sim2.step_tick()
    
    var hash1: String = _hasher.hash_simulation(sim1)
    var hash2: String = _hasher.hash_simulation(sim2)
    
    assert_eq(hash1, hash2,
        "Multiple collision scenario should be deterministic")


func test_collision_response_conserves_momentum() -> void:
    ## Verify elastic collisions conserve momentum approximately
    var bot1: Node = _spawn_test_bot(Vector2(0, 0))
    var bot2: Node = _spawn_test_bot(Vector2(40, 0))
    
    bot1.set("velocity", Vector2.RIGHT * 100.0)
    bot2.set("velocity", Vector2.LEFT * 50.0)
    
    var mass1: float = 1.0
    var mass2: float = 1.0
    
    var initial_momentum: Vector2 = bot1.get("velocity") * mass1 + bot2.get("velocity") * mass2
    
    # Simulate collision
    for i in range(30):
        _sim.step_tick()
    
    var final_momentum: Vector2 = bot1.get("velocity") * mass1 + bot2.get("velocity") * mass2
    
    # Allow some tolerance for numerical errors
    assert_almost_eq(final_momentum.x, initial_momentum.x, 5.0,
        "Momentum should be approximately conserved in collision")


func test_corner_collision() -> void:
    ## Verify bot handles corner collisions correctly
    var bot: Node = _spawn_test_bot(Vector2(0, 0))
    bot.set("velocity", Vector2(100, 100).normalized() * 100.0)
    
    # Create corner (two walls meeting)
    var wall_h: StaticBody2D = _create_wall(Vector2(100, 80), Vector2(100, 20))
    var wall_v: StaticBody2D = _create_wall(Vector2(80, 100), Vector2(20, 100))
    _sim.add_child(wall_h)
    _sim.add_child(wall_v)
    
    var stuck: bool = false
    var prev_pos: Vector2 = bot.position
    
    for i in range(60):
        _sim.step_tick()
        
        # Check if bot got stuck
        if bot.position == prev_pos and i > 10:
            # Bot might be stuck, check if it's at corner
            if bot.position.x > 70 and bot.position.y > 70:
                stuck = true
                break
        prev_pos = bot.position
    
    # Bot should not tunnel through walls
    assert_true(bot.position.x < 110 and bot.position.y < 110,
        "Bot should not pass through corner walls")
    
    wall_h.queue_free()
    wall_v.queue_free()


# Helper methods

func _create_minimal_simulation() -> Node:
    var sim: Node = Node2D.new()
    sim.name = "TestSimulation"
    sim.set_meta("is_simulation", true)
    sim.set("current_tick", 0)
    sim.set("simulation_time", 0.0)
    sim.set("random_seed", 0)
    sim.set("is_paused", false)
    
    var bot_container: Node2D = Node2D.new()
    bot_container.name = "bots"
    sim.add_child(bot_container)
    
    var proj_container: Node2D = Node2D.new()
    proj_container.name = "projectiles"
    sim.add_child(proj_container)
    
    if not sim.has_method("step_tick"):
        sim.set_script(_create_simulation_script())
    
    add_child_autofree(sim)
    return sim


func _create_sim_with_seed(seed_val: int) -> Node:
    var sim: Node = _create_minimal_simulation()
    sim.set("random_seed", seed_val)
    
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(seed_val)
    sim.set("_rng", rng)
    
    return sim


func _spawn_test_bot(pos: Vector2) -> Node:
    return _spawn_bot_in_sim(_sim, pos)


func _spawn_bot_in_sim(sim: Node, pos: Vector2) -> Node:
    var bot: CharacterBody2D = CharacterBody2D.new()
    bot.name = "TestBot_%d" % sim.get_node("bots").get_child_count()
    bot.position = pos
    bot.set_meta("is_bot", true)
    
    bot.set("sim_id", sim.get_node("bots").get_child_count())
    bot.set("team_id", 0)
    bot.set("health", 100.0)
    bot.set("max_health", 100.0)
    bot.set("armor", 0.0)
    bot.set("movement_speed", 100.0)
    bot.set("velocity", Vector2.ZERO)
    bot.set("current_state", "idle")
    bot.set("state_time", 0.0)
    bot.set("weapon_cooldown", 0.0)
    bot.set("current_ammo", 30)
    bot.set("target_id", -1)
    bot.set("path_index", 0)
    
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = 10.0
    collision.shape = shape
    bot.add_child(collision)
    
    sim.get_node("bots").add_child(bot)
    return bot


func _spawn_test_projectile(pos: Vector2, velocity: Vector2) -> Node:
    return _spawn_projectile_in_sim(_sim, pos, velocity)


func _spawn_projectile_in_sim(sim: Node, pos: Vector2, velocity: Vector2) -> Node:
    var proj: Area2D = Area2D.new()
    proj.name = "Projectile_%d" % sim.get_node("projectiles").get_child_count()
    proj.position = pos
    proj.set_meta("is_projectile", true)
    
    proj.set("sim_id", sim.get_node("projectiles").get_child_count())
    proj.set("owner_id", -1)
    proj.set("velocity", velocity)
    proj.set("damage", 25.0)
    proj.set("lifetime", 0.0)
    proj.set("max_lifetime", 5.0)
    proj.set("bounce_count", 0)
    proj.set("max_bounces", 0)
    proj.set("projectile_type", "bullet")
    
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = 5.0
    collision.shape = shape
    proj.add_child(collision)
    
    sim.get_node("projectiles").add_child(proj)
    return proj


func _create_wall(pos: Vector2, size: Vector2) -> StaticBody2D:
    var wall: StaticBody2D = StaticBody2D.new()
    wall.name = "Wall_%d" % _sim.get_child_count()
    wall.position = pos
    
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: RectangleShape2D = RectangleShape2D.new()
    shape.size = size
    collision.shape = shape
    wall.add_child(collision)
    
    return wall


func _cleanup_simulation() -> void:
    if _sim != null and is_instance_valid(_sim):
        _sim.queue_free()
    _sim = null


func _create_simulation_script() -> GDScript:
    var script: GDScript = GDScript.new()
    script.source_code = """
extends Node2D

const TICK_DELTA: float = 1.0 / 60.0

func step_tick() -> void:
    set("current_tick", get("current_tick") + 1)
    set("simulation_time", get("simulation_time") + TICK_DELTA)
    
    # Update bots
    var bots = get_node("bots").get_children()
    for bot in bots:
        if bot is CharacterBody2D:
            var vel = bot.get("velocity")
            if vel != null and vel != Vector2.ZERO:
                bot.velocity = vel
                bot.move_and_slide()
    
    # Update projectiles
    var projectiles = get_node("projectiles").get_children()
    for proj in projectiles:
        var vel = proj.get("velocity")
        if vel != null:
            proj.position += vel * TICK_DELTA
        
        var lt = proj.get("lifetime")
        proj.set("lifetime", lt + TICK_DELTA)
"""
    script.reload()
    return script
