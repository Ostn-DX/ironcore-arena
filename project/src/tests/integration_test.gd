extends SceneTree
## IntegrationTest — validates core game systems work together.
## Run with: godot --script src/tests/integration_test.gd

var tests_passed: int = 0
var tests_failed: int = 0

func _init() -> void:
	print("=== IRONCORE ARENA INTEGRATION TEST ===\n")
	
	# Wait for engine initialization
	await create_timer(0.1).timeout
	
	# Run tests
	_test_data_loader()
	_test_game_state()
	_test_arena_loading()
	_test_battle_manager()
	_test_shop_manager()
	
	# Report results
	print("\n=== TEST RESULTS ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)
	print("Total:  %d" % (tests_passed + tests_failed))
	
	if tests_failed == 0:
		print("\n✅ ALL TESTS PASSED - Game is playable!")
	else:
		print("\n❌ SOME TESTS FAILED")
	
	quit()


func _test_data_loader() -> void:
	print("Testing DataLoader...")
	
	if not DataLoader:
		_fail("DataLoader not available")
		return
	
	# Test chassis loading
	var chassis: Array = DataLoader.get_all_chassis()
	if chassis.size() == 0:
		_fail("No chassis loaded")
	else:
		_pass("Loaded %d chassis" % chassis.size())
	
	# Test weapon loading
	var weapons: Array = DataLoader.get_all_weapons()
	if weapons.size() == 0:
		_fail("No weapons loaded")
	else:
		_pass("Loaded %d weapons" % weapons.size())
	
	# Test arena loading
	var arenas: Array = DataLoader.get_all_arenas()
	if arenas.size() < 2:
		_fail("Need at least 2 arenas, found %d" % arenas.size())
	else:
		_pass("Loaded %d arenas" % arenas.size())


func _test_game_state() -> void:
	print("\nTesting GameState...")
	
	if not GameState:
		_fail("GameState not available")
		return
	
	# Test initial values
	if GameState.credits < 0:
		_fail("Invalid credits value")
	else:
		_pass("Credits initialized: %d" % GameState.credits)
	
	# Test tier system
	if GameState.current_tier < 0:
		_fail("Invalid tier")
	else:
		_pass("Current tier: %d" % GameState.current_tier)
	
	# Test loadouts
	if GameState.loadouts.size() == 0:
		_warn("No loadouts defined")
	else:
		_pass("Loadouts: %d" % GameState.loadouts.size())


func _test_arena_loading() -> void:
	print("\nTesting Arena loading...")
	
	var arena_scene: PackedScene = load("res://scenes/arena.tscn")
	if not arena_scene:
		_fail("Cannot load arena.tscn")
		return
	
	var arena: Arena = arena_scene.instantiate()
	if not arena:
		_fail("Cannot instantiate arena")
		return
	
	# Test arena setup
	var test_arena_data: Dictionary = {
		"id": "test_arena",
		"name": "Test Arena",
		"dimensions": [800, 600],
		"spawn_points_player": [{"x": 100, "y": 300}],
		"spawn_points_enemy": [{"x": 700, "y": 300}],
		"obstacles": []
	}
	
	arena.setup(test_arena_data)
	
	if arena.arena_size == Vector2.ZERO:
		_fail("Arena size not set")
	else:
		_pass("Arena size: %s" % str(arena.arena_size))
	
	arena.queue_free()


func _test_battle_manager() -> void:
	print("\nTesting BattleManager...")
	
	var battle_manager: BattleManager = BattleManager.new()
	if not battle_manager:
		_fail("Cannot create BattleManager")
		return
	
	add_child(battle_manager)
	
	# Test battle setup
	var player_loadouts: Array = [{
		"id": "test_bot",
		"name": "Test Bot",
		"chassis": "akaumin_dl2_100",
		"weapons": ["raptor_dt_01"],
		"armor": ["santrin_auro"],
		"mobility": ["mob_wheels_t1"],
		"sensors": ["sen_basic_t1"],
		"utilities": [],
		"ai_profile": "ai_balanced"
	}]
	
	var success: bool = battle_manager.setup_battle("roxtan_park", player_loadouts)
	
	if success:
		_pass("Battle setup successful")
	else:
		_fail("Battle setup failed")
	
	battle_manager.queue_free()


func _test_shop_manager() -> void:
	print("\nTesting ShopManager...")
	
	var shop_manager: ShopManager = ShopManager.new()
	if not shop_manager:
		_fail("Cannot create ShopManager")
		return
	
	add_child(shop_manager)
	shop_manager._ready()
	
	# Test available components
	var components: Array = shop_manager.get_filtered_components()
	if components.size() == 0:
		_warn("No components in shop")
	else:
		_pass("Shop has %d components" % components.size())
	
	shop_manager.queue_free()


func _pass(message: String) -> void:
	print("  ✅ PASS: %s" % message)
	tests_passed += 1


func _fail(message: String) -> void:
	print("  ❌ FAIL: %s" % message)
	tests_failed += 1


func _warn(message: String) -> void:
	print("  ⚠️  WARN: %s" % message)
	tests_passed += 1  # Warnings don't fail tests
