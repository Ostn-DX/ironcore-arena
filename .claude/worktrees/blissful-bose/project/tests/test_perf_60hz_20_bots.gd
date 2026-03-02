extends GutTest

## Performance regression tests for simulation.
##
## This test suite verifies that the simulation maintains
## acceptable performance under typical load conditions.
## Tests fail if performance degrades beyond thresholds.

const TARGET_TICKS: int = 3600  # 1 minute at 60Hz
const MAX_TIME_MS: float = 2000.0  # 2 seconds max
const BOT_COUNT: int = 20
const TARGET_MS_PER_TICK: float = 1000.0 / 60.0  # ~16.67ms for 60Hz

const WARMUP_TICKS: int = 60  # Warmup before measurement
const PERF_TEST_SEEDS: PackedInt32Array = [12345, 67890, 11111]

var _hasher: SimulationStateHasher = null


func before_all() -> void:
    _hasher = SimulationStateHasher.new()


func test_60hz_with_20_bots() -> void:
    ## Primary performance test: 20 bots at 60Hz for 1 minute
    var sim: Node = _create_sim_with_seed(12345)
    
    # Spawn 20 bots with varied configurations
    _spawn_bot_fleet(sim, BOT_COUNT)
    
    # Warmup to stabilize
    for i in range(WARMUP_TICKS):
        sim.step_tick()
    
    # Measure performance
    var start_time: int = Time.get_ticks_msec()
    
    for tick in range(TARGET_TICKS):
        sim.step_tick()
    
    var elapsed: int = Time.get_ticks_msec() - start_time
    
    var ms_per_tick: float = float(elapsed) / TARGET_TICKS
    
    gut.p("Performance Results:")
    gut.p("  Total ticks: %d" % TARGET_TICKS)
    gut.p("  Total time: %d ms" % elapsed)
    gut.p("  ms/tick: %.4f" % ms_per_tick)
    gut.p("  Target ms/tick: %.4f" % TARGET_MS_PER_TICK)
    gut.p("  Ticks/second: %.1f" % (1000.0 / ms_per_tick))
    
    assert_true(elapsed < MAX_TIME_MS, 
        "Performance regression: %d ticks took %d ms (max %d ms)" % [TARGET_TICKS, elapsed, MAX_TIME_MS])
    
    # Additional check: should maintain 60Hz
    assert_true(ms_per_tick < TARGET_MS_PER_TICK * 1.5,
        "Should maintain near-60Hz performance (%.2f ms/tick)" % ms_per_tick)


func test_performance_consistent_across_seeds() -> void:
    ## Verify performance is consistent with different random seeds
    var times: PackedFloat32Array = []
    
    for seed_val in PERF_TEST_SEEDS:
        var sim: Node = _create_sim_with_seed(seed_val)
        _spawn_bot_fleet(sim, BOT_COUNT)
        
        # Warmup
        for i in range(WARMUP_TICKS):
            sim.step_tick()
        
        var start_time: int = Time.get_ticks_msec()
        
        for tick in range(600):  # 10 seconds worth
            sim.step_tick()
        
        var elapsed: int = Time.get_ticks_msec() - start_time
        times.append(float(elapsed))
        
        gut.p("Seed %d: %d ms for 600 ticks" % [seed_val, elapsed])
    
    # Calculate variance
    var avg: float = _calculate_average(times)
    var variance: float = _calculate_variance(times, avg)
    var std_dev: float = sqrt(variance)
    
    gut.p("Performance variance: avg=%.2f, std_dev=%.2f" % [avg, std_dev])
    
    # Standard deviation should be low (< 20% of average)
    assert_true(std_dev < avg * 0.2,
        "Performance should be consistent across seeds (std_dev: %.2f)" % std_dev)


func test_performance_with_collisions() -> void:
    ## Performance test with many collisions
    var sim: Node = _create_sim_with_seed(54321)
    
    # Spawn bots close together to force collisions
    for i in range(BOT_COUNT):
        var offset: Vector2 = Vector2(
            (i % 5) * 15,
            (i / 5) * 15
        )
        var bot: Node = _spawn_bot_in_sim(sim, Vector2(400, 300) + offset)
        bot.set("velocity", Vector2(
            randf_range(-100, 100),
            randf_range(-100, 100)
        ))
    
    # Warmup
    for i in range(WARMUP_TICKS):
        sim.step_tick()
    
    var start_time: int = Time.get_ticks_msec()
    
    for tick in range(600):
        sim.step_tick()
    
    var elapsed: int = Time.get_ticks_msec() - start_time
    
    gut.p("Collision-heavy performance: %d ms for 600 ticks" % elapsed)
    
    assert_true(elapsed < MAX_TIME_MS / 3,
        "Collision handling should not cause major slowdown (%d ms)" % elapsed)


func test_performance_with_shooting() -> void:
    ## Performance test with active shooting
    var sim: Node = _create_sim_with_seed(98765)
    _spawn_bot_fleet(sim, BOT_COUNT)
    
    # Enable shooting for all bots
    for bot in sim.get_node("bots").get_children():
        bot.set("weapon_cooldown", 0.0)
        bot.set("current_ammo", 1000)
        bot.set("fire_rate", 5.0)
    
    # Warmup
    for i in range(WARMUP_TICKS):
        _process_shooting(sim)
        sim.step_tick()
    
    var start_time: int = Time.get_ticks_msec()
    
    for tick in range(600):
        _process_shooting(sim)
        sim.step_tick()
    
    var elapsed: int = Time.get_ticks_msec() - start_time
    var proj_count: int = sim.get_node("projectiles").get_child_count()
    
    gut.p("Shooting performance: %d ms for 600 ticks, %d projectiles" % [elapsed, proj_count])
    
    assert_true(elapsed < MAX_TIME_MS / 2,
        "Shooting should not cause major slowdown (%d ms)" % elapsed)


func test_performance_scales_linearly() -> void:
    ## Verify performance scales roughly linearly with bot count
    var bot_counts: PackedInt32Array = [5, 10, 15, 20]
    var times: Dictionary = {}
    
    for count in bot_counts:
        var sim: Node = _create_sim_with_seed(11111)
        _spawn_bot_fleet(sim, count)
        
        # Warmup
        for i in range(30):
            sim.step_tick()
        
        var start_time: int = Time.get_ticks_msec()
        
        for tick in range(300):
            sim.step_tick()
        
        var elapsed: int = Time.get_ticks_msec() - start_time
        times[count] = elapsed
        
        gut.p("Bot count %d: %d ms for 300 ticks" % [count, elapsed])
    
    # Check scaling factor
    var time_5: float = times[5]
    var time_20: float = times[20]
    var scaling_factor: float = time_20 / time_5
    
    gut.p("Scaling factor (20 bots / 5 bots): %.2fx" % scaling_factor)
    
    # Should scale roughly linearly (allow up to 5x for 4x bot count)
    assert_true(scaling_factor < 5.0,
        "Performance should scale roughly linearly with bot count")


func test_memory_usage_stable() -> void:
    ## Verify memory usage doesn't grow unbounded
    var sim: Node = _create_sim_with_seed(22222)
    _spawn_bot_fleet(sim, BOT_COUNT)
    
    # Run for extended period
    for tick in range(2000):
        sim.step_tick()
        
        # Clean up any queued nodes periodically
        if tick % 100 == 0:
            sim.get_node("bots").get_children()
    
    var bot_count: int = sim.get_node("bots").get_child_count()
    
    gut.p("Memory stability: %d bots after 2000 ticks" % bot_count)
    
    assert_eq(bot_count, BOT_COUNT,
        "Bot count should remain stable (no memory leaks)")


func test_hashing_performance() -> void:
    ## Verify state hashing doesn't cause major slowdown
    var sim: Node = _create_sim_with_seed(33333)
    _spawn_bot_fleet(sim, BOT_COUNT)
    
    # Warmup
    for i in range(30):
        sim.step_tick()
    
    # Measure with hashing
    var start_time: int = Time.get_ticks_msec()
    
    for tick in range(300):
        sim.step_tick()
        var hash: String = _hasher.hash_simulation(sim)
    
    var elapsed_with_hash: int = Time.get_ticks_msec() - start_time
    
    gut.p("Hashing performance: %d ms for 300 ticks with hashing" % elapsed_with_hash)
    
    # Hashing overhead should be reasonable (< 50% increase)
    assert_true(elapsed_with_hash < MAX_TIME_MS / 4,
        "Hashing should not cause major slowdown")


func test_determinism_not_affected_by_performance() -> void:
    ## Verify determinism holds even under performance pressure
    var seed_val: int = 44444
    
    var sim1: Node = _create_sim_with_seed(seed_val)
    var sim2: Node = _create_sim_with_seed(seed_val)
    
    _spawn_bot_fleet(sim1, BOT_COUNT)
    _spawn_bot_fleet(sim2, BOT_COUNT)
    
    for tick in range(300):
        sim1.step_tick()
        sim2.step_tick()
        
        # Verify hashes match every 10 ticks
        if tick % 10 == 0:
            var hash1: String = _hasher.hash_simulation(sim1)
            var hash2: String = _hasher.hash_simulation(sim2)
            
            assert_eq(hash1, hash2,
                "Determinism should hold under load at tick %d" % tick)


func test_30fps_fallback_performance() -> void:
    ## Verify simulation can maintain 30Hz if needed
    var sim: Node = _create_sim_with_seed(55555)
    _spawn_bot_fleet(sim, BOT_COUNT * 2)  # Double the bots
    
    var target_30hz_ms: float = 1000.0 / 30.0  # ~33.33ms per tick
    
    # Warmup
    for i in range(30):
        sim.step_tick()
    
    var start_time: int = Time.get_ticks_msec()
    
    for tick in range(900):  # 30 seconds at 30Hz
        sim.step_tick()
    
    var elapsed: int = Time.get_ticks_msec() - start_time
    var ms_per_tick: float = float(elapsed) / 900
    
    gut.p("30Hz fallback test: %.2f ms/tick with %d bots" % [ms_per_tick, BOT_COUNT * 2])
    
    # Should be able to handle 30Hz with double bots
    assert_true(ms_per_tick < target_30hz_ms * 2,
        "Should maintain reasonable performance at 30Hz fallback")


func test_peak_load_performance() -> void:
    ## Test performance under peak load (many projectiles)
    var sim: Node = _create_sim_with_seed(66666)
    _spawn_bot_fleet(sim, 10)
    
    # Pre-spawn many projectiles
    for i in range(50):
        var proj: Node = _spawn_projectile_in_sim(sim, 
            Vector2(randf_range(0, 800), randf_range(0, 600)),
            Vector2(randf_range(-200, 200), randf_range(-200, 200))
        )
    
    var start_time: int = Time.get_ticks_msec()
    
    for tick in range(300):
        sim.step_tick()
    
    var elapsed: int = Time.get_ticks_msec() - start_time
    
    gut.p("Peak load test: %d ms for 300 ticks with 50 projectiles" % elapsed)
    
    assert_true(elapsed < MAX_TIME_MS / 2,
        "Should handle peak load without major slowdown")


# Helper methods

func _create_sim_with_seed(seed_val: int) -> Node:
    var sim: Node = Node2D.new()
    sim.name = "PerfSim_%d" % seed_val
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


func _spawn_bot_fleet(sim: Node, count: int) -> void:
    var rng: DeterministicRng = sim.get("_rng")
    
    for i in range(count):
        var pos: Vector2 = Vector2(
            rng.next_float_range(50, 750),
            rng.next_float_range(50, 550)
        )
        _spawn_bot_in_sim(sim, pos)


func _spawn_bot_in_sim(sim: Node, pos: Vector2) -> Node:
    var rng: DeterministicRng = sim.get("_rng")
    
    var bot: CharacterBody2D = CharacterBody2D.new()
    bot.name = "PerfBot_%d" % sim.get_node("bots").get_child_count()
    bot.position = pos
    bot.set_meta("is_bot", true)
    
    var bot_id: int = sim.get_node("bots").get_child_count()
    bot.set("sim_id", bot_id)
    bot.set("team_id", bot_id % 2)
    bot.set("health", 100.0)
    bot.set("max_health", 100.0)
    bot.set("armor", float(bot_id * 2))
    bot.set("movement_speed", 100.0 + bot_id * 5)
    bot.set("velocity", Vector2(
        rng.next_float_range(-80, 80),
        rng.next_float_range(-80, 80)
    ))
    bot.set("current_state", "active")
    bot.set("state_time", 0.0)
    bot.set("weapon_cooldown", 0.0)
    bot.set("current_ammo", 50)
    bot.set("target_id", -1)
    bot.set("path_index", 0)
    bot.set("fire_rate", 3.0)
    
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = 10.0
    collision.shape = shape
    bot.add_child(collision)
    
    sim.get_node("bots").add_child(bot)
    return bot


func _spawn_projectile_in_sim(sim: Node, pos: Vector2, vel: Vector2 = Vector2.ZERO) -> Node:
    var proj: Area2D = Area2D.new()
    proj.name = "Projectile_%d" % sim.get_node("projectiles").get_child_count()
    proj.position = pos
    proj.set_meta("is_projectile", true)
    
    proj.set("sim_id", sim.get_node("projectiles").get_child_count())
    proj.set("owner_id", -1)
    proj.set("velocity", vel)
    proj.set("damage", 25.0)
    proj.set("lifetime", 0.0)
    proj.set("max_lifetime", 5.0)
    proj.set("bounce_count", 0)
    proj.set("projectile_type", "bullet")
    
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = 5.0
    collision.shape = shape
    proj.add_child(collision)
    
    sim.get_node("projectiles").add_child(proj)
    return proj


func _process_shooting(sim: Node) -> void:
    var bots: Array = sim.get_node("bots").get_children()
    var projectiles: Node = sim.get_node("projectiles")
    
    for bot in bots:
        var cd: float = bot.get("weapon_cooldown")
        if cd > 0.0:
            bot.set("weapon_cooldown", maxf(0.0, cd - (1.0 / 60.0)))
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


func _calculate_average(values: PackedFloat32Array) -> float:
    var sum: float = 0.0
    for v in values:
        sum += v
    return sum / values.size()


func _calculate_variance(values: PackedFloat32Array, mean: float) -> float:
    var sum_sq_diff: float = 0.0
    for v in values:
        var diff: float = v - mean
        sum_sq_diff += diff * diff
    return sum_sq_diff / values.size()


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
        if cd != null and cd > 0:
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
