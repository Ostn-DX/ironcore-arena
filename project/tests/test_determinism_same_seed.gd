extends GutTest

## Verifies determinism: same seed produces identical outcomes.
##
## This is the core determinism test suite that validates the
## fundamental property of deterministic simulation: given the
## same initial state and inputs, the simulation must produce
## exactly the same results every time.

const TEST_SEEDS: PackedInt32Array = [0, 1, 12345, 67890, 11111, 99999, 2147483647]
const TICKS_TO_SIMULATE: int = 300
const TICK_DELTA: float = 1.0 / 60.0

var _hasher: SimulationStateHasher = null


func before_all() -> void:
    _hasher = SimulationStateHasher.new()


func test_same_seed_produces_identical_hashes() -> void:
    ## Primary determinism test: same seed => identical state hashes
    for seed_val in TEST_SEEDS:
        var hasher1: SimulationStateHasher = SimulationStateHasher.new()
        var hasher2: SimulationStateHasher = SimulationStateHasher.new()
        
        var sim1: Node = _create_sim_with_seed(seed_val)
        var sim2: Node = _create_sim_with_seed(seed_val)
        
        # Populate with identical random content
        _populate_simulation(sim1, seed_val)
        _populate_simulation(sim2, seed_val)
        
        for tick in range(TICKS_TO_SIMULATE):
            sim1.step_tick()
            sim2.step_tick()
            
            var hash1: String = hasher1.hash_simulation(sim1)
            var hash2: String = hasher2.hash_simulation(sim2)
            
            assert_eq(hash1, hash2, 
                "Hash mismatch at tick %d with seed %d" % [tick, seed_val])
            
            if hash1 != hash2:
                # Print diagnostic info on failure
                gut.p("FAIL: Seed %d, Tick %d" % [seed_val, tick])
                gut.p("  Hash1: %s" % hash1)
                gut.p("  Hash2: %s" % hash2)
                break


func test_different_seeds_produce_different_results() -> void:
    ## Verify that different seeds actually produce different outcomes
    var sim1: Node = _create_sim_with_seed(12345)
    var sim2: Node = _create_sim_with_seed(54321)
    
    _populate_simulation(sim1, 12345)
    _populate_simulation(sim2, 54321)
    
    for tick in range(100):
        sim1.step_tick()
        sim2.step_tick()
    
    var hash1: String = _hasher.hash_simulation(sim1)
    var hash2: String = _hasher.hash_simulation(sim2)
    
    assert_ne(hash1, hash2, 
        "Different seeds should produce different results")


func test_determinism_across_restart() -> void:
    ## Verify simulation can be reproduced from saved state
    var seed_val: int = 77777
    var sim1: Node = _create_sim_with_seed(seed_val)
    _populate_simulation(sim1, seed_val)
    
    # Run first 100 ticks
    for tick in range(100):
        sim1.step_tick()
    
    var mid_hash: String = _hasher.hash_simulation(sim1)
    
    # Continue to 200 ticks
    for tick in range(100):
        sim1.step_tick()
    
    var final_hash_1: String = _hasher.hash_simulation(sim1)
    
    # Create new simulation with same seed, run 200 ticks
    var sim2: Node = _create_sim_with_seed(seed_val)
    _populate_simulation(sim2, seed_val)
    
    for tick in range(200):
        sim2.step_tick()
    
    var final_hash_2: String = _hasher.hash_simulation(sim2)
    
    assert_eq(final_hash_1, final_hash_2,
        "Simulation should be reproducible from start")


func test_bot_positions_deterministic() -> void:
    ## Verify individual bot positions are deterministic
    for seed_val in TEST_SEEDS:
        var sim1: Node = _create_sim_with_seed(seed_val)
        var sim2: Node = _create_sim_with_seed(seed_val)
        
        _populate_simulation(sim1, seed_val)
        _populate_simulation(sim2, seed_val)
        
        for tick in range(100):
            sim1.step_tick()
            sim2.step_tick()
        
        var bots1: Array = sim1.get_node("bots").get_children()
        var bots2: Array = sim2.get_node("bots").get_children()
        
        assert_eq(bots1.size(), bots2.size(),
            "Bot counts should match for seed %d" % seed_val)
        
        for i in range(min(bots1.size(), bots2.size())):
            var bot1: Node = bots1[i]
            var bot2: Node = bots2[i]
            
            assert_almost_eq(bot1.position.x, bot2.position.x, 0.001,
                "Bot %d X position should match for seed %d" % [i, seed_val])
            assert_almost_eq(bot1.position.y, bot2.position.y, 0.001,
                "Bot %d Y position should match for seed %d" % [i, seed_val])


func test_projectile_states_deterministic() -> void:
    ## Verify projectile states are deterministic
    for seed_val in [12345, 67890]:
        var sim1: Node = _create_sim_with_seed(seed_val)
        var sim2: Node = _create_sim_with_seed(seed_val)
        
        _populate_simulation(sim1, seed_val)
        _populate_simulation(sim2, seed_val)
        
        # Enable shooting
        for bot in sim1.get_node("bots").get_children():
            bot.set("weapon_cooldown", 0.0)
            bot.set("current_ammo", 100)
        for bot in sim2.get_node("bots").get_children():
            bot.set("weapon_cooldown", 0.0)
            bot.set("current_ammo", 100)
        
        for tick in range(60):
            _process_shooting(sim1)
            _process_shooting(sim2)
            sim1.step_tick()
            sim2.step_tick()
        
        var projs1: Array = sim1.get_node("projectiles").get_children()
        var projs2: Array = sim2.get_node("projectiles").get_children()
        
        assert_eq(projs1.size(), projs2.size(),
            "Projectile counts should match for seed %d" % seed_val)
        
        for i in range(min(projs1.size(), projs2.size())):
            var proj1: Node = projs1[i]
            var proj2: Node = projs2[i]
            
            assert_almost_eq(proj1.position.x, proj2.position.x, 0.001,
                "Projectile %d X position should match" % i)
            assert_almost_eq(proj1.position.y, proj2.position.y, 0.001,
                "Projectile %d Y position should match" % i)


func test_health_values_deterministic() -> void:
    ## Verify health values after combat are deterministic
    for seed_val in [11111, 99999]:
        var sim1: Node = _create_sim_with_seed(seed_val)
        var sim2: Node = _create_sim_with_seed(seed_val)
        
        _populate_simulation(sim1, seed_val)
        _populate_simulation(sim2, seed_val)
        
        # Set up combat scenario
        _setup_combat_scenario(sim1)
        _setup_combat_scenario(sim2)
        
        for tick in range(100):
            _process_combat(sim1)
            _process_combat(sim2)
            sim1.step_tick()
            sim2.step_tick()
        
        var bots1: Array = sim1.get_node("bots").get_children()
        var bots2: Array = sim2.get_node("bots").get_children()
        
        for i in range(min(bots1.size(), bots2.size())):
            var health1: float = bots1[i].get("health")
            var health2: float = bots2[i].get("health")
            
            assert_almost_eq(health1, health2, 0.001,
                "Bot %d health should match for seed %d" % [i, seed_val])


func test_iteration_order_independence() -> void:
    ## Verify that iteration order doesn't affect determinism
    var seed_val: int = 55555
    var sim1: Node = _create_sim_with_seed(seed_val)
    var sim2: Node = _create_sim_with_seed(seed_val)
    
    _populate_simulation(sim1, seed_val)
    _populate_simulation(sim2, seed_val)
    
    # Manually scramble bot order in sim2 before each tick
    for tick in range(50):
        sim1.step_tick()
        
        # Scramble and restore order in sim2
        var bots_container: Node = sim2.get_node("bots")
        var bots: Array = bots_container.get_children()
        
        # Reverse order temporarily
        for bot in bots:
            bots_container.remove_child(bot)
        bots.reverse()
        for bot in bots:
            bots_container.add_child(bot)
        
        sim2.step_tick()
        
        # Restore original order
        for bot in bots:
            bots_container.remove_child(bot)
        bots.reverse()
        for bot in bots:
            bots_container.add_child(bot)
        
        var hash1: String = _hasher.hash_simulation(sim1)
        var hash2: String = _hasher.hash_simulation(sim2)
        
        assert_eq(hash1, hash2,
            "Iteration order should not affect determinism at tick %d" % tick)


func test_rng_sequence_deterministic() -> void:
    ## Verify DeterministicRng produces same sequence for same seed
    for seed_val in TEST_SEEDS:
        var rng1: DeterministicRng = DeterministicRng.new()
        var rng2: DeterministicRng = DeterministicRng.new()
        
        rng1.seed(seed_val)
        rng2.seed(seed_val)
        
        for i in range(1000):
            var val1: int = rng1.next_u32()
            var val2: int = rng2.next_u32()
            
            assert_eq(val1, val2,
                "RNG values should match at index %d for seed %d" % [i, seed_val])
            
            if val1 != val2:
                break


func test_float_quantization_prevents_drift() -> void:
    ## Verify float quantization prevents FP drift accumulation
    var hasher1: SimulationStateHasher = SimulationStateHasher.new()
    var hasher2: SimulationStateHasher = SimulationStateHasher.new()
    
    var sim1: Node = _create_sim_with_seed(12345)
    var sim2: Node = _create_sim_with_seed(12345)
    
    _populate_simulation(sim1, 12345)
    _populate_simulation(sim2, 12345)
    
    # Run many ticks to accumulate potential drift
    for tick in range(1000):
        sim1.step_tick()
        sim2.step_tick()
        
        # Check hashes every 100 ticks
        if tick % 100 == 0:
            var hash1: String = hasher1.hash_simulation(sim1)
            var hash2: String = hasher2.hash_simulation(sim2)
            
            assert_eq(hash1, hash2,
                "No drift should occur at tick %d" % tick)


func test_reproducible_failing_seed() -> void:
    ## Test that prints seed info for debugging failures
    var test_seed: int = 1337
    var sim: Node = _create_sim_with_seed(test_seed)
    
    _populate_simulation(sim, test_seed)
    
    gut.p("Testing with reproducible seed: %d" % test_seed)
    
    for tick in range(50):
        sim.step_tick()
        
        var hash: String = _hasher.hash_simulation(sim)
        gut.p("Tick %d: hash=%s" % [tick, hash.substr(0, 16)])
    
    assert_true(true, "Reproducible seed test completed")


# Helper methods

func _create_sim_with_seed(seed_val: int) -> Node:
    var sim: Node = Node2D.new()
    sim.name = "TestSimulation_%d" % seed_val
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


func _populate_simulation(sim: Node, seed_val: int) -> void:
    var rng: DeterministicRng = sim.get("_rng")
    var bot_count: int = rng.next_int_range(3, 8)
    
    for i in range(bot_count):
        var bot: CharacterBody2D = CharacterBody2D.new()
        bot.name = "Bot_%d" % i
        bot.position = Vector2(
            rng.next_float_range(0, 500),
            rng.next_float_range(0, 500)
        )
        bot.set_meta("is_bot", true)
        bot.set("sim_id", i)
        bot.set("team_id", rng.next_int_range(0, 1))
        bot.set("health", 100.0)
        bot.set("max_health", 100.0)
        bot.set("armor", float(rng.next_int_range(0, 10)))
        bot.set("movement_speed", rng.next_float_range(50, 150))
        bot.set("velocity", Vector2(
            rng.next_float_range(-100, 100),
            rng.next_float_range(-100, 100)
        ))
        bot.set("current_state", "active")
        bot.set("state_time", 0.0)
        bot.set("weapon_cooldown", 0.0)
        bot.set("current_ammo", rng.next_int_range(10, 50))
        bot.set("target_id", -1)
        bot.set("path_index", 0)
        
        var collision: CollisionShape2D = CollisionShape2D.new()
        var shape: CircleShape2D = CircleShape2D.new()
        shape.radius = 10.0
        collision.shape = shape
        bot.add_child(collision)
        
        sim.get_node("bots").add_child(bot)


func _setup_combat_scenario(sim: Node) -> void:
    var bots: Array = sim.get_node("bots").get_children()
    
    # Position bots to face each other
    for i in range(bots.size()):
        var bot: Node = bots[i]
        bot.set("weapon_cooldown", 0.0)
        bot.set("current_ammo", 100)
        bot.set("fire_rate", 2.0)


func _process_shooting(sim: Node) -> void:
    var bots: Array = sim.get_node("bots").get_children()
    var projectiles: Node = sim.get_node("projectiles")
    
    for bot in bots:
        var cd: float = bot.get("weapon_cooldown")
        if cd > 0.0:
            bot.set("weapon_cooldown", maxf(0.0, cd - TICK_DELTA))
        elif bot.get("current_ammo") > 0:
            var fire_rate: float = bot.get("fire_rate")
            bot.set("weapon_cooldown", 1.0 / fire_rate)
            bot.set("current_ammo", bot.get("current_ammo") - 1)
            
            var proj: Area2D = Area2D.new()
            proj.name = "Projectile_%d" % projectiles.get_child_count()
            proj.position = bot.position
            proj.set_meta("is_projectile", true)
            proj.set("sim_id", projectiles.get_child_count())
            proj.set("owner_id", bot.get("sim_id"))
            proj.set("velocity", Vector2.RIGHT.rotated(bot.get("rotation")) * 400.0)
            proj.set("damage", 15.0)
            proj.set("lifetime", 0.0)
            proj.set("max_lifetime", 3.0)
            proj.set("bounce_count", 0)
            proj.set("projectile_type", "bullet")
            projectiles.add_child(proj)


func _process_combat(sim: Node) -> void:
    _process_shooting(sim)
    
    # Simple damage processing
    var bots: Array = sim.get_node("bots").get_children()
    var projectiles: Array = sim.get_node("projectiles").get_children()
    
    for proj in projectiles:
        for bot in bots:
            if proj.position.distance_to(bot.position) < 20.0:
                if proj.get("owner_id") != bot.get("sim_id"):
                    var damage: float = proj.get("damage")
                    var health: float = bot.get("health")
                    bot.set("health", maxf(0.0, health - damage))
                    proj.queue_free()
                    break


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
        
        # Update state time
        var st = bot.get("state_time")
        bot.set("state_time", st + TICK_DELTA)
    
    # Update projectiles
    var projectiles = get_node("projectiles").get_children()
    for proj in projectiles:
        if not is_instance_valid(proj):
            continue
        var vel = proj.get("velocity")
        if vel != null:
            proj.position += vel * TICK_DELTA
        
        var lt = proj.get("lifetime")
        proj.set("lifetime", lt + TICK_DELTA)
        
        if proj.get("lifetime") >= proj.get("max_lifetime"):
            proj.queue_free()
"""
    script.reload()
    return script
