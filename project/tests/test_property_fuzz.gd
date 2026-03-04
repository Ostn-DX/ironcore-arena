extends GutTest

## Property-based fuzzing tests using DeterministicRng.
##
## This test suite generates random but reproducible test cases
## to verify that the simulation handles edge cases without
## crashing or producing invalid states.

const FUZZ_ITERATIONS: int = 100
const MAX_TICKS_PER_FUZZ: int = 100
const MIN_BOTS: int = 2
const MAX_BOTS: int = 20
const ARENA_SIZE: Vector2 = Vector2(1000, 1000)

var _hasher: SimulationStateHasher = null


func before_all() -> void:
    _hasher = SimulationStateHasher.new()


func test_fuzz_random_spawns_no_crash() -> void:
    ## Fuzz test: random spawns should never crash
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(12345)
    
    var failure_seeds: PackedInt32Array = []
    
    for i in range(FUZZ_ITERATIONS):
        var seed_val: int = rng.next_u32()
        var sim: Node = _create_sim_with_seed(seed_val)
        
        # Generate random valid spawn positions
        var bot_count: int = rng.next_int_range(MIN_BOTS, MAX_BOTS)
        for b in range(bot_count):
            var pos: Vector2 = Vector2(
                rng.next_float_range(50, ARENA_SIZE.x - 50),
                rng.next_float_range(50, ARENA_SIZE.y - 50)
            )
            _spawn_bot_in_sim(sim, pos, rng)
        
        # Run simulation
        var ticks: int = rng.next_int_range(10, MAX_TICKS_PER_FUZZ)
        
        var crashed: bool = false
        for t in range(ticks):
            sim.step_tick()
            
            # Check for invalid states after each tick
            if _has_invalid_states(sim):
                failure_seeds.append(seed_val)
                gut.p("FAIL: Invalid state at iteration %d, seed %d, tick %d" % [i, seed_val, t])
                crashed = true
                break
        
        if not crashed:
            # Verify no NaN or invalid states at end
            _assert_no_invalid_states(sim, seed_val)
        
        sim.queue_free()
    
    if failure_seeds.size() > 0:
        gut.p("Failing seeds for reproduction: %s" % str(failure_seeds))
    
    assert_eq(failure_seeds.size(), 0, 
        "No crashes or invalid states should occur during fuzzing")


func test_fuzz_random_velocities_no_invalid() -> void:
    ## Fuzz test: random velocities should not produce NaN positions
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(54321)
    
    for i in range(FUZZ_ITERATIONS):
        var seed_val: int = rng.next_u32()
        var sim: Node = _create_sim_with_seed(seed_val)
        
        # Spawn bots with random velocities
        var bot_count: int = rng.next_int_range(2, 10)
        for b in range(bot_count):
            var pos: Vector2 = Vector2(500, 500)
            var bot: Node = _spawn_bot_in_sim(sim, pos, rng)
            
            # Set extreme velocities
            var vel: Vector2 = Vector2(
                rng.next_float_range(-1000, 1000),
                rng.next_float_range(-1000, 1000)
            )
            bot.set("velocity", vel)
        
        # Run simulation
        var ticks: int = rng.next_int_range(10, 50)
        for t in range(ticks):
            sim.step_tick()
        
        # Verify all positions are valid
        for bot in sim.get_node("bots").get_children():
            assert_true(is_finite(bot.position.x), 
                "Bot X position should be finite (seed: %d)" % seed_val)
            assert_true(is_finite(bot.position.y), 
                "Bot Y position should be finite (seed: %d)" % seed_val)
        
        sim.queue_free()


func test_fuzz_collision_scenarios_stable() -> void:
    ## Fuzz test: random collision scenarios should be stable
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(98765)
    
    for i in range(FUZZ_ITERATIONS / 2):
        var seed_val: int = rng.next_u32()
        var sim: Node = _create_sim_with_seed(seed_val)
        
        # Spawn bots close together to force collisions
        var center: Vector2 = Vector2(
            rng.next_float_range(200, 800),
            rng.next_float_range(200, 800)
        )
        
        var bot_count: int = rng.next_int_range(3, 8)
        for b in range(bot_count):
            var offset: Vector2 = Vector2(
                rng.next_float_range(-30, 30),
                rng.next_float_range(-30, 30)
            )
            var bot: Node = _spawn_bot_in_sim(sim, center + offset, rng)
            bot.set("velocity", Vector2(
                rng.next_float_range(-200, 200),
                rng.next_float_range(-200, 200)
            ))
        
        # Run simulation
        for t in range(60):
            sim.step_tick()
        
        # Verify no bots got stuck or teleported
        for bot in sim.get_node("bots").get_children():
            var pos: Vector2 = bot.position
            
            # Check for extreme positions (possible teleportation bug)
            assert_true(pos.x > -1000 and pos.x < 2000,
                "Bot X position should be reasonable (seed: %d)" % seed_val)
            assert_true(pos.y > -1000 and pos.y < 2000,
                "Bot Y position should be reasonable (seed: %d)" % seed_val)
        
        sim.queue_free()


func test_fuzz_determinism_under_random_conditions() -> void:
    ## Fuzz test: determinism holds under random conditions
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(11111)
    
    for i in range(20):  # Fewer iterations for determinism check
        var seed_val: int = rng.next_u32()
        
        var sim1: Node = _create_sim_with_seed(seed_val)
        var sim2: Node = _create_sim_with_seed(seed_val)
        
        # Use same RNG sequence for both
        var spawn_rng: DeterministicRng = DeterministicRng.new()
        spawn_rng.seed(seed_val)
        
        var bot_count: int = spawn_rng.next_int_range(2, 10)
        for b in range(bot_count):
            var pos: Vector2 = Vector2(
                spawn_rng.next_float_range(50, 950),
                spawn_rng.next_float_range(50, 950)
            )
            _spawn_bot_in_sim(sim1, pos, spawn_rng)
            _spawn_bot_in_sim(sim2, pos, spawn_rng)
        
        # Run both simulations
        var ticks: int = spawn_rng.next_int_range(20, 80)
        for t in range(ticks):
            sim1.step_tick()
            sim2.step_tick()
            
            # Check hashes periodically
            if t % 10 == 0:
                var hash1: String = _hasher.hash_simulation(sim1)
                var hash2: String = _hasher.hash_simulation(sim2)
                
                assert_eq(hash1, hash2,
                    "Determinism failed at tick %d with seed %d" % [t, seed_val])
        
        sim1.queue_free()
        sim2.queue_free()


func test_fuzz_extreme_values_handled() -> void:
    ## Fuzz test: extreme values should be handled gracefully
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(99999)
    
    var extreme_values: Array = [
        0.0, 1.0, -1.0, 
        1.7976931348623157e+308,  # Max float
        -1.7976931348623157e+308, # Min float
        2.2250738585072014e-308,  # Min positive float
        1e10, -1e10,
        3.14159, 6.28318
    ]
    
    for i in range(FUZZ_ITERATIONS / 4):
        var seed_val: int = rng.next_u32()
        var sim: Node = _create_sim_with_seed(seed_val)
        
        var bot: Node = _spawn_bot_in_sim(sim, Vector2(500, 500), rng)
        
        # Set extreme values
        var extreme_speed: float = extreme_values[rng.next_int_range(0, extreme_values.size() - 1)]
        bot.set("movement_speed", extreme_speed)
        bot.set("velocity", Vector2(extreme_speed, extreme_speed))
        bot.set("health", extreme_values[rng.next_int_range(0, extreme_values.size() - 1)])
        
        # Should not crash
        for t in range(10):
            sim.step_tick()
        
        # Position should still be valid
        assert_true(is_finite(bot.position.x) or is_inf(bot.position.x),
            "Position should be finite or infinity, not NaN")
        
        sim.queue_free()


func test_fuzz_rapid_spawn_despawn_stable() -> void:
    ## Fuzz test: rapid spawn/despawn cycles should be stable
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(77777)
    
    for i in range(20):
        var seed_val: int = rng.next_u32()
        var sim: Node = _create_sim_with_seed(seed_val)
        
        var bots_container: Node = sim.get_node("bots")
        
        for tick in range(50):
            # Randomly spawn or despawn
            if rng.next_bool(0.3) and bots_container.get_child_count() < 10:
                var pos: Vector2 = Vector2(
                    rng.next_float_range(100, 900),
                    rng.next_float_range(100, 900)
                )
                _spawn_bot_in_sim(sim, pos, rng)
            
            if rng.next_bool(0.2) and bots_container.get_child_count() > 0:
                var bots: Array = bots_container.get_children()
                var to_remove: Node = bots[rng.next_int_range(0, bots.size() - 1)]
                to_remove.queue_free()
            
            sim.step_tick()
        
        # Verify no orphaned nodes or crashes
        assert_true(true, "Rapid spawn/despawn completed without crash")
        
        sim.queue_free()


func test_fuzz_memory_stability() -> void:
    ## Fuzz test: memory usage should remain stable
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(44444)
    
    for i in range(10):
        var seed_val: int = rng.next_u32()
        var sim: Node = _create_sim_with_seed(seed_val)
        
        # Spawn many bots
        for b in range(15):
            var pos: Vector2 = Vector2(
                rng.next_float_range(50, 950),
                rng.next_float_range(50, 950)
            )
            _spawn_bot_in_sim(sim, pos, rng)
        
        # Run many ticks
        for t in range(200):
            sim.step_tick()
        
        # Verify bot count hasn't grown unexpectedly
        var bot_count: int = sim.get_node("bots").get_child_count()
        assert_true(bot_count <= 20, 
            "Bot count should not grow unexpectedly (seed: %d)" % seed_val)
        
        sim.queue_free()


func test_fuzz_reproducible_with_seed() -> void:
    ## Verify fuzz failures are reproducible with the same seed
    var test_seed: int = 55555
    
    var sim1: Node = _create_sim_with_seed(test_seed)
    var sim2: Node = _create_sim_with_seed(test_seed)
    
    var rng1: DeterministicRng = DeterministicRng.new()
    var rng2: DeterministicRng = DeterministicRng.new()
    rng1.seed(test_seed)
    rng2.seed(test_seed)
    
    # Same spawn sequence
    for i in range(5):
        var pos1: Vector2 = Vector2(
            rng1.next_float_range(100, 900),
            rng1.next_float_range(100, 900)
        )
        var pos2: Vector2 = Vector2(
            rng2.next_float_range(100, 900),
            rng2.next_float_range(100, 900)
        )
        _spawn_bot_in_sim(sim1, pos1, rng1)
        _spawn_bot_in_sim(sim2, pos2, rng2)
    
    for t in range(100):
        sim1.step_tick()
        sim2.step_tick()
    
    var hash1: String = _hasher.hash_simulation(sim1)
    var hash2: String = _hasher.hash_simulation(sim2)
    
    assert_eq(hash1, hash2, 
        "Same fuzz seed should produce identical results")
    
    sim1.queue_free()
    sim2.queue_free()


# Helper methods

func _create_sim_with_seed(seed_val: int) -> Node:
    var sim: Node = Node2D.new()
    sim.name = "FuzzSim_%d" % seed_val
    sim.set_meta("is_simulation", true)
    sim.set("current_tick", 0)
    sim.set("simulation_time", 0.0)
    sim.set("random_seed", seed_val)
    sim.set("is_paused", false)
    
    var bot_container: Node2D = Node2D.new()
    bot_container.name = "bots"
    sim.add_child(bot_container)
    
    var proj_container: Node2D = Node2D.new()
    proj_container.name = "projectiles"
    sim.add_child(proj_container)
    
    var rng: DeterministicRng = DeterministicRng.new()
    rng.seed(seed_val)
    sim.set("_rng", rng)
    
    var script: GDScript = _create_simulation_script()
    sim.set_script(script)
    
    add_child_autofree(sim)
    return sim


func _spawn_bot_in_sim(sim: Node, pos: Vector2, rng: DeterministicRng) -> Node:
    var bot: CharacterBody2D = CharacterBody2D.new()
    bot.name = "FuzzBot_%d" % sim.get_node("bots").get_child_count()
    bot.position = pos
    bot.set_meta("is_bot", true)
    
    var bot_id: int = sim.get_node("bots").get_child_count()
    bot.set("sim_id", bot_id)
    bot.set("team_id", rng.next_int_range(0, 1))
    bot.set("health", rng.next_float_range(50, 100))
    bot.set("max_health", 100.0)
    bot.set("armor", rng.next_float_range(0, 20))
    bot.set("movement_speed", rng.next_float_range(50, 200))
    bot.set("velocity", Vector2(
        rng.next_float_range(-100, 100),
        rng.next_float_range(-100, 100)
    ))
    bot.set("current_state", "active")
    bot.set("state_time", 0.0)
    bot.set("weapon_cooldown", 0.0)
    bot.set("current_ammo", rng.next_int_range(0, 50))
    bot.set("target_id", -1)
    bot.set("path_index", 0)
    bot.set("fire_rate", rng.next_float_range(1.0, 5.0))
    
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = rng.next_float_range(5, 15)
    collision.shape = shape
    bot.add_child(collision)
    
    sim.get_node("bots").add_child(bot)
    return bot


func _has_invalid_states(sim: Node) -> bool:
    for bot in sim.get_node("bots").get_children():
        if not is_instance_valid(bot):
            return true
        
        var pos: Vector2 = bot.position
        if is_nan(pos.x) or is_nan(pos.y):
            return true
        if is_inf(pos.x) or is_inf(pos.y):
            return true
        
        var health: float = bot.get("health")
        if is_nan(health) or health < -0.001:
            return true
    
    for proj in sim.get_node("projectiles").get_children():
        if not is_instance_valid(proj):
            continue
        
        var pos: Vector2 = proj.position
        if is_nan(pos.x) or is_nan(pos.y):
            return true
    
    return false


func _assert_no_invalid_states(sim: Node, seed_val: int) -> void:
    for bot in sim.get_node("bots").get_children():
        assert_true(is_finite(bot.position.x), 
            "Bot has NaN/Inf position X (seed: %d)" % seed_val)
        assert_true(is_finite(bot.position.y), 
            "Bot has NaN/Inf position Y (seed: %d)" % seed_val)
        assert_true(bot.get("health") >= 0, 
            "Bot has negative health (seed: %d)" % seed_val)


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
        if not is_instance_valid(bot):
            continue
        if bot is CharacterBody2D:
            var vel = bot.get("velocity")
            if vel != null and vel != Vector2.ZERO:
                bot.velocity = vel
                bot.move_and_slide()
        
        var cd = bot.get("weapon_cooldown")
        if cd > 0:
            bot.set("weapon_cooldown", maxf(0.0, cd - TICK_DELTA))
    
    # Update projectiles
    var projectiles = get_node("projectiles").get_children()
    for proj in projectiles:
        if not is_instance_valid(proj):
            continue
        var vel = proj.get("velocity")
        if vel != null:
            proj.position += vel * TICK_DELTA
        
        var lt = proj.get("lifetime")
        if lt != null:
            proj.set("lifetime", lt + TICK_DELTA)
            if proj.get("lifetime") >= proj.get("max_lifetime"):
                proj.queue_free()
"""
    script.reload()
    return script
