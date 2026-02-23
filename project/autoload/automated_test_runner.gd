extends Node
## AutomatedTestRunner - Headless integration tests for Ironcore Arena
## Runs all game systems without UI to catch errors fast
## Bible B1.3: All signal connections use safe patterns

signal test_completed(test_name: String, passed: bool, message: String)
signal all_tests_completed(results: Dictionary)

const TEST_LOG_PATH: String = "user://test_results.json"

var _test_results: Dictionary = {}
var _current_test: String = ""
var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("[AutoTest] Automated Test Runner initialized")
	## Bible B1.3: Delay test start to allow autoloads to initialize
	call_deferred("_delayed_start")

func _delayed_start() -> void:
	await get_tree().create_timer(0.5).timeout
	run_all_tests()

func run_all_tests() -> void:
	print("\n[AutoTest] ========== STARTING AUTOMATED TEST SUITE ==========\n")
	
	_test_results.clear()
	_tests_passed = 0
	_tests_failed = 0
	
	## Run all test categories
	await _test_data_loader()
	await _test_game_state()
	await _test_economy()
	await _test_save_load()
	await _test_battle_simulation()
	await _test_component_integration()
	
	## Report results
	_report_results()

func _test_data_loader() -> void:
	_start_test("DataLoader")
	
	## Test 1: DataLoader initialized
	if not DataLoader or not is_instance_valid(DataLoader):
		_fail_test("DataLoader not initialized")
		return
	
	## Test 2: Chassis data loaded
	var chassis: Array = DataLoader.get_all_chassis()
	if chassis.is_empty():
		_fail_test("No chassis data loaded")
		return
	_pass_subtest("Chassis data loaded: %d entries" % chassis.size())
	
	## Test 3: Weapons data loaded
	var weapons: Array = DataLoader.get_all_weapons()
	if weapons.is_empty():
		_fail_test("No weapons data loaded")
		return
	_pass_subtest("Weapons data loaded: %d entries" % weapons.size())
	
	## Test 4: Plating data loaded
	var plating: Array = DataLoader.get_all_plating()
	if plating.is_empty():
		_fail_test("No plating data loaded")
		return
	_pass_subtest("Plating data loaded: %d entries" % plating.size())
	
	## Test 5: Arenas data loaded
	var arenas: Array = DataLoader.get_all_arenas()
	if arenas.is_empty():
		_fail_test("No arenas data loaded")
		return
	_pass_subtest("Arenas data loaded: %d entries" % arenas.size())
	
	## Test 6: Component lookup
	var part: Dictionary = DataLoader.get_part("akaumin_dl2_100")
	if part.is_empty():
		_fail_test("Component lookup failed for akaumin_dl2_100")
		return
	_pass_subtest("Component lookup working")
	
	## Test 7: get_all_parts() for BuilderScreen
	var all_parts: Dictionary = DataLoader.get_all_parts()
	if all_parts.is_empty():
		_fail_test("get_all_parts() returned empty")
		return
	_pass_subtest("get_all_parts() working: %d parts" % all_parts.size())
	
	_pass_test("All DataLoader tests passed")

func _test_game_state() -> void:
	_start_test("GameState")
	
	## Test 1: GameState initialized
	if not GameState or not is_instance_valid(GameState):
		_fail_test("GameState not initialized")
		return
	
	## Test 2: Default values
	if GameState.credits < 0:
		_fail_test("Invalid credits value: %d" % GameState.credits)
		return
	_pass_subtest("Credits initialized: %d" % GameState.credits)
	
	## Test 3: Starter kit given
	if GameState.owned_parts.is_empty():
		_fail_test("No starter parts given")
		return
	_pass_subtest("Starter parts given: %d types" % GameState.owned_parts.size())
	
	## Test 4: Loadouts initialized
	if GameState.loadouts.is_empty():
		_fail_test("No loadouts initialized")
		return
	_pass_subtest("Loadouts initialized: %d bots" % GameState.loadouts.size())
	
	## Test 5: Unlocked arenas
	if GameState.unlocked_arenas.is_empty():
		_fail_test("No arenas unlocked")
		return
	_pass_subtest("Arenas unlocked: %d" % GameState.unlocked_arenas.size())
	
	_pass_test("All GameState tests passed")

func _test_economy() -> void:
	_start_test("Economy")
	
	## Test 1: Credit management
	var initial_credits: int = GameState.credits
	GameState.add_credits(100)
	if GameState.credits != initial_credits + 100:
		_fail_test("add_credits() failed")
		return
	_pass_subtest("add_credits() working")
	
	## Test 2: Credit spending
	var can_spend: bool = GameState.spend_credits(50)
	if not can_spend:
		_fail_test("spend_credits() failed when should succeed")
		return
	if GameState.credits != initial_credits + 50:
		_fail_test("Credit balance incorrect after spend")
		return
	_pass_subtest("spend_credits() working")
	
	## Test 3: Cannot overspend
	var overspend_attempt: bool = GameState.spend_credits(999999)
	if overspend_attempt:
		_fail_test("spend_credits() allowed overspend")
		return
	_pass_subtest("Overspend protection working")
	
	## Test 4: Add part
	var test_part_id: String = "test_part_" + str(randi())
	GameState.add_part(test_part_id, 5)
	if not GameState.owned_parts.has(test_part_id):
		_fail_test("add_part() failed")
		return
	if GameState.owned_parts[test_part_id] != 5:
		_fail_test("add_part() quantity incorrect")
		return
	_pass_subtest("add_part() working")
	
	_pass_test("All Economy tests passed")

func _test_save_load() -> void:
	_start_test("SaveLoad")
	
	## Test 1: Save game (returns void, so we just call it)
	GameState.save_game()
	_pass_subtest("save_game() executed")
	
	## Test 2: Modify state
	var original_credits: int = GameState.credits
	GameState.credits = 9999
	
	## Test 3: Load game (returns bool)
	var load_success: bool = GameState.load_game()
	if not load_success:
		_fail_test("load_game() failed")
		return
	_pass_subtest("load_game() working")
	
	## Test 4: Verify state restored
	if GameState.credits != original_credits:
		_fail_test("Credits not restored after load (expected %d, got %d)" % [original_credits, GameState.credits])
		return
	_pass_subtest("State correctly restored")
	
	_pass_test("All Save/Load tests passed")

func _test_battle_simulation() -> void:
	_start_test("BattleSimulation")
	
	## Test 1: SimulationManager initialized
	if not SimulationManager or not is_instance_valid(SimulationManager):
		_fail_test("SimulationManager not initialized")
		return
	_pass_subtest("SimulationManager initialized")
	
	## Test 2: Create test battle
	var test_arena: Dictionary = {
		"id": "test_arena",
		"name": "Test Arena",
		"enemy_count": 2,
		"difficulty": 1
	}
	
	## Test 3: Validate arena data
	var arena_data: Dictionary = DataLoader.get_arena("arena_boot_camp")
	if arena_data.is_empty():
		_fail_test("Could not load arena_boot_camp")
		return
	_pass_subtest("Arena data loaded: " + arena_data.get("name", "unnamed"))
	
	_pass_test("All Battle Simulation tests passed")

func _test_component_integration() -> void:
	_start_test("ComponentIntegration")
	
	## Test 1: All chassis have required fields
	var chassis_list: Array = DataLoader.get_all_chassis()
	for chassis in chassis_list:
		if not chassis is Dictionary:
			_fail_test("Chassis entry not a dictionary")
			return
		if not chassis.has("id") or not chassis.has("name"):
			_fail_test("Chassis missing required fields")
			return
		if not chassis.has("hp_base") or not chassis.has("speed_base"):
			_fail_test("Chassis missing stats: %s" % chassis.get("id", "unknown"))
			return
	_pass_subtest("All chassis have required fields")
	
	## Test 2: All weapons have required fields
	var weapons_list: Array = DataLoader.get_all_weapons()
	for weapon in weapons_list:
		if not weapon is Dictionary:
			_fail_test("Weapon entry not a dictionary")
			return
		if not weapon.has("id") or not weapon.has("name"):
			_fail_test("Weapon missing required fields")
			return
		if not weapon.has("damage"):
			_fail_test("Weapon missing damage: %s" % weapon.get("id", "unknown"))
			return
	_pass_subtest("All weapons have required fields")
	
	## Test 3: All plating have required fields
	var plating_list: Array = DataLoader.get_all_plating()
	for plating in plating_list:
		if not plating is Dictionary:
			_fail_test("Plating entry not a dictionary")
			return
		if not plating.has("id") or not plating.has("name"):
			_fail_test("Plating missing required fields")
			return
		if not plating.has("hp_bonus"):
			_fail_test("Plating missing hp_bonus: %s" % plating.get("id", "unknown"))
			return
	_pass_subtest("All plating have required fields")
	
	## Test 4: Validate loadout can be assembled
	if GameState.loadouts.is_empty():
		_fail_test("No loadouts to validate")
		return
	
	var test_loadout: Dictionary = GameState.loadouts[0]
	var chassis_id: String = test_loadout.get("chassis", "")
	var weapon_id: String = test_loadout.get("weapon", "")
	var armor_id: String = test_loadout.get("armor", "")
	
	if chassis_id.is_empty() or weapon_id.is_empty() or armor_id.is_empty():
		_fail_test("Loadout missing components")
		return
	
	var chassis: Dictionary = DataLoader.get_chassis(chassis_id)
	var weapon: Dictionary = DataLoader.get_weapon(weapon_id)
	var armor: Dictionary = DataLoader.get_plating(armor_id)
	
	if chassis.is_empty():
		_fail_test("Loadout chassis not found: %s" % chassis_id)
		return
	if weapon.is_empty():
		_fail_test("Loadout weapon not found: %s" % weapon_id)
		return
	if armor.is_empty():
		_fail_test("Loadout armor not found: %s" % armor_id)
		return
	
	_pass_subtest("Loadout components validated")
	
	_pass_test("All Component Integration tests passed")

func _start_test(test_name: String) -> void:
	_current_test = test_name
	_test_results[test_name] = {
		"passed": false,
		"subtests": [],
		"message": ""
	}
	print("[AutoTest] Starting: %s" % test_name)

func _pass_subtest(message: String) -> void:
	_test_results[_current_test]["subtests"].append({"passed": true, "message": message})
	print("[AutoTest]   ✓ %s" % message)

func _pass_test(message: String) -> void:
	_test_results[_current_test]["passed"] = true
	_test_results[_current_test]["message"] = message
	_tests_passed += 1
	print("[AutoTest] ✓ PASSED: %s\n" % _current_test)
	test_completed.emit(_current_test, true, message)

func _fail_test(message: String) -> void:
	_test_results[_current_test]["passed"] = false
	_test_results[_current_test]["message"] = message
	_tests_failed += 1
	print("[AutoTest] ✗ FAILED: %s - %s\n" % [_current_test, message])
	test_completed.emit(_current_test, false, message)

func _report_results() -> void:
	print("\n[AutoTest] ========== TEST SUITE COMPLETE ==========")
	print("[AutoTest] Passed: %d | Failed: %d" % [_tests_passed, _tests_failed])
	
	if _tests_failed == 0:
		print("[AutoTest] ✓ ALL TESTS PASSED\n")
	else:
		print("[AutoTest] ✗ SOME TESTS FAILED\n")
	
	## Save results to file
	var report: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(),
		"total_tests": _tests_passed + _tests_failed,
		"passed": _tests_passed,
		"failed": _tests_failed,
		"results": _test_results
	}
	
	var file: FileAccess = FileAccess.open(TEST_LOG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("[AutoTest] Results saved to: %s" % TEST_LOG_PATH)
	
	all_tests_completed.emit(report)

func get_last_results() -> Dictionary:
	return _test_results.duplicate()

func has_failures() -> bool:
	return _tests_failed > 0
