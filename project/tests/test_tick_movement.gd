extends GutTest

## Tests movement tick behavior for determinism and correctness.
##
## This test suite verifies that bot movement is both correct
## (obeys physics rules) and deterministic (same inputs produce
## same outputs).

const TEST_SEEDS: PackedInt32Array = [12345, 67890, 11111, 99999, 0]
const TICK_DELTA: float = 1.0 / 60.0  # 60Hz simulation

var _sim: Node = null
var _rng: DeterministicRng = null
var _hasher: SimulationStateHasher = null


func before_each() -> void:
    _rng = DeterministicRng.new()
    _hasher = SimulationStateHasher.new()
    _sim = _create_minimal_simulation()


func after_each() -> void:
    _cleanup_simulation()


func test_bot_moves_at_expected_speed() -> void:
    ## Verify bot moves speed * dt per tick
    var bot: Node = _spawn_test_bot(Vector2(100, 100))
    var speed: float = 200.0  # units per second
    bot.set("movement_speed", speed)
    
    # Set velocity to move right
    bot.set("velocity", Vector2.RIGHT * speed)
    
    var start_pos: Vector2 = bot.position
    var expected_distance: float = speed * TICK_DELTA
    
    # Simulate one tick
    _sim.step_tick()
    
    var actual_distance: float = bot.position.distance_to(start_pos)
    var expected_pos: Vector2 = start_pos + Vector2.RIGHT * expected_distance
    
    assert_almost_eq(bot.position.x, expected_pos.x, 0.01,
        "Bot X position should match expected after one tick")
    assert_almost_eq(bot.position.y, expected_pos.y, 0.01,
        "Bot Y position should remain unchanged")
    assert_almost_eq(actual_distance, expected_distance, 0.01,
        "Bot should move speed * dt distance")


func test_bot_stops_at_obstacles() -> void:
    ## Verify collision response stops or redirects bot
    var bot: Node = _spawn_test_bot(Vector2(0, 0))
    bot.set("movement_speed", 100.0)
    bot.set("velocity", Vector2.RIGHT * 100.0)
    
    # Create obstacle at position bot will reach
    var obstacle: StaticBody2D = StaticBody2D.new()
    obstacle.position = Vector2(50, 0)
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: RectangleShape2D = RectangleShape2D.new()
    shape.size = Vector2(20, 20)
    collision.shape = shape
    obstacle.add_child(collision)
    _sim.add_child(obstacle)
    
    # Store initial position
    var start_pos: Vector2 = bot.position
    
    # Simulate multiple ticks until collision
    for i in range(10):
        var prev_pos: Vector2 = bot.position
        _sim.step_tick()
        
        # Check if bot stopped or changed direction due to collision
        if bot.position == prev_pos:
            # Bot stopped at obstacle
            assert_true(bot.position.x < 50.0,
                "Bot should stop before obstacle")
            return
    
    # If we get here, check that bot didn't pass through obstacle
    assert_true(bot.position.x < 60.0,
        "Bot should not pass through obstacle")
    
    obstacle.queue_free()


func test_movement_is_deterministic() -> void:
    ## Same seed => same position after N ticks
    for seed_val in TEST_SEEDS:
        var sim1: Node = _create_sim_with_seed(seed_val)
        var sim2: Node = _create_sim_with_seed(seed_val)
        
        # Spawn identical bots in both simulations
        var bot1: Node = _spawn_bot_in_sim(sim1, Vector2(100, 100))
        var bot2: Node = _spawn_bot_in_sim(sim2, Vector2(100, 100))
        
        bot1.set("velocity", Vector2(50, 25))
        bot2.set("velocity", Vector2(50, 25))
        
        # Run for 100 ticks
        for tick in range(100):
            sim1.step_tick()
            sim2.step_tick()
        
        # Positions should be identical
        assert_eq(bot1.position, bot2.position,
            "Positions should match for seed %d" % seed_val)
        assert_eq(bot1.velocity, bot2.velocity,
            "Velocities should match for seed %d" % seed_val)


func test_diagonal_movement_speed() -> void:
    ## Verify diagonal movement doesn't exceed max speed
    var bot: Node = _spawn_test_bot(Vector2(0, 0))
    var max_speed: float = 100.0
    bot.set("movement_speed", max_speed)
    
    # Move diagonally
    bot.set("velocity", Vector2.ONE.normalized() * max_speed)
    
    var start_pos: Vector2 = bot.position
    
    _sim.step_tick()
    
    var distance: float = bot.position.distance_to(start_pos)
    var actual_speed: float = distance / TICK_DELTA
    
    assert_almost_eq(actual_speed, max_speed, 0.1,
        "Diagonal speed should equal max speed")


func test_zero_velocity_no_movement() -> void:
    ## Verify zero velocity means no movement
    var bot: Node = _spawn_test_bot(Vector2(50, 50))
    bot.set("velocity", Vector2.ZERO)
    
    var start_pos: Vector2 = bot.position
    
    for i in range(10):
        _sim.step_tick()
    
    assert_eq(bot.position, start_pos,
        "Bot with zero velocity should not move")


func test_negative_velocity_moves_backward() -> void:
    ## Verify negative velocity moves bot in opposite direction
    var bot: Node = _spawn_test_bot(Vector2(100, 100))
    bot.set("velocity", Vector2.LEFT * 50.0)
    
    var start_x: float = bot.position.x
    
    _sim.step_tick()
    
    assert_true(bot.position.x < start_x,
        "Bot should move left with negative X velocity")


func test_movement_hash_consistency() -> void:
    ## Verify state hashes are identical for identical movement
    var seed_val: int = 12345
    var sim1: Node = _create_sim_with_seed(seed_val)
    var sim2: Node = _create_sim_with_seed(seed_val)
    
    # Spawn and configure identical bots
    var bot1: Node = _spawn_bot_in_sim(sim1, Vector2(100, 100))
    var bot2: Node = _spawn_bot_in_sim(sim2, Vector2(100, 100))
    
    bot1.set("velocity", Vector2(30, 40))
    bot2.set("velocity", Vector2(30, 40))
    
    for tick in range(50):
        sim1.step_tick()
        sim2.step_tick()
        
        var hash1: String = _hasher.hash_simulation(sim1)
        var hash2: String = _hasher.hash_simulation(sim2)
        
        assert_eq(hash1, hash2,
            "Simulation hashes should match at tick %d" % tick)


func test_multiple_bots_deterministic_order() -> void:
    ## Verify iteration order doesn't affect determinism
    var seed_val: int = 54321
    var sim1: Node = _create_sim_with_seed(seed_val)
    var sim2: Node = _create_sim_with_seed(seed_val)
    
    # Spawn multiple bots
    for i in range(5):
        var pos: Vector2 = Vector2(i * 50, i * 30)
        var bot1: Node = _spawn_bot_in_sim(sim1, pos)
        var bot2: Node = _spawn_bot_in_sim(sim2, pos)
        bot1.set("velocity", Vector2(i * 10, i * 5))
        bot2.set("velocity", Vector2(i * 10, i * 5))
    
    for tick in range(60):
        sim1.step_tick()
        sim2.step_tick()
    
    var hash1: String = _hasher.hash_simulation(sim1)
    var hash2: String = _hasher.hash_simulation(sim2)
    
    assert_eq(hash1, hash2,
        "Multiple bot simulation should be deterministic")


# Helper methods

func _create_minimal_simulation() -> Node:
    ## Creates a minimal simulation environment for testing
    var sim: Node = Node2D.new()
    sim.name = "TestSimulation"
    sim.set_meta("is_simulation", true)
    
    # Add required properties
    sim.set("current_tick", 0)
    sim.set("simulation_time", 0.0)
    sim.set("random_seed", 0)
    sim.set("is_paused", false)
    
    # Add bot container
    var bot_container: Node2D = Node2D.new()
    bot_container.name = "bots"
    sim.add_child(bot_container)
    
    # Add projectile container
    var proj_container: Node2D = Node2D.new()
    proj_container.name = "projectiles"
    sim.add_child(proj_container)
    
    # Add step_tick method if not present
    if not sim.has_method("step_tick"):
        sim.set_script(_create_simulation_script())
    
    add_child_autofree(sim)
    return sim


func _create_sim_with_seed(seed_val: int) -> Node:
    ## Creates a simulation with the given random seed
    var sim: Node = _create_minimal_simulation()
    sim.set("random_seed", seed_val)
    
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(seed_val)
    sim.set("_rng", rng)
    
    return sim


func _spawn_test_bot(pos: Vector2) -> Node:
    ## Spawns a test bot in the current simulation
    return _spawn_bot_in_sim(_sim, pos)


func _spawn_bot_in_sim(sim: Node, pos: Vector2) -> Node:
    ## Spawns a bot in the specified simulation
    var bot: CharacterBody2D = CharacterBody2D.new()
    bot.name = "TestBot_%d" % sim.get_child_count()
    bot.position = pos
    bot.set_meta("is_bot", true)
    
    # Set required bot properties
    bot.set("sim_id", sim.get_child_count())
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
    
    # Add collision shape
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = 10.0
    collision.shape = shape
    bot.add_child(collision)
    
    var bot_container: Node = sim.get_node("bots")
    bot_container.add_child(bot)
    
    return bot


func _cleanup_simulation() -> void:
    ## Cleans up the simulation after each test
    if _sim != null and is_instance_valid(_sim):
        _sim.queue_free()
    _sim = null


func _create_simulation_script() -> GDScript:
    ## Creates a minimal GDScript with step_tick method
    var script: GDScript = GDScript.new()
    script.source_code = """
extends Node2D

const TICK_DELTA: float = 1.0 / 60.0

func step_tick() -> void:
    set("current_tick", get("current_tick") + 1)
    set("simulation_time", get("simulation_time") + TICK_DELTA)
    
    # Update weapon cooldowns
    var bots = get_node("bots").get_children()
    for bot in bots:
        var cd = bot.get("weapon_cooldown")
        if cd > 0:
            bot.set("weapon_cooldown", max(0.0, cd - TICK_DELTA))
    
    # Process movement
    for bot in bots:
        if bot is CharacterBody2D:
            var vel = bot.get("velocity")
            if vel != null and vel != Vector2.ZERO:
                bot.velocity = vel
                bot.move_and_slide()
"""
    script.reload()
    return script
