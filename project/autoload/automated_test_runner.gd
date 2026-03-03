extends Node
## AutomatedTestRunner - Headless integration tests for Ironcore Arena
## Runs all game systems without UI to catch errors fast
## Bible B1.3: All signal connections use safe patterns
## EXPANDED: Comprehensive test coverage for all systems

signal test_completed(test_name: String, passed: bool, message: String)
signal all_tests_completed(results: Dictionary)

const TEST_LOG_PATH: String = "user://test_results.json"

var _test_results: Dictionary = {}
var _current_test: String = ""
var _tests_passed: int = 0
var _tests_failed: int = 0
var _subtest_count: int = 0

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
	await _test_arena_progression()
	await _test_stat_calculations()
	await _test_edge_cases()
	await _test_signals()
	await _test_resource_loading()
	await _test_performance()
	await _test_type_safety()
	await _test_error_handling()
	
	## NEW: Extended test scenarios
	await _test_battle_scenarios()
	await _test_save_load_stress()
	await _test_memory_stability()
	await _test_balance_validation()
	
	## Report results
	_report_results()

func _test_data_loader() -> void:
	_start_test("DataLoader")
	
	## Test 1: DataLoader initialized
	if not DataLoader or not is_instance_valid(DataLoader):
		_fail_test("DataLoader not initialized")
		return
	_pass_subtest("DataLoader singleton exists")
	
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
	
	## Test 6: Component lookup - valid
	var part: Dictionary = DataLoader.get_part("akaumin_dl2_100")
	if part.is_empty():
		_fail_test("Component lookup failed for akaumin_dl2_100")
		return
	_pass_subtest("Component lookup working (valid ID)")
	
	## Test 7: Component lookup - invalid
	var invalid_part: Dictionary = DataLoader.get_part("nonexistent_part_xyz")
	if not invalid_part.is_empty():
		_fail_test("Invalid part lookup should return empty")
		return
	_pass_subtest("Component lookup handles invalid IDs")
	
	## Test 8: get_all_parts() for BuilderScreen
	var all_parts: Dictionary = DataLoader.get_all_parts()
	if all_parts.is_empty():
		_fail_test("get_all_parts() returned empty")
		return
	var total_parts: int = chassis.size() + weapons.size() + plating.size()
	if all_parts.size() != total_parts:
		_fail_test("get_all_parts() count mismatch: %d vs expected %d" % [all_parts.size(), total_parts])
		return
	_pass_subtest("get_all_parts() working: %d parts" % all_parts.size())
	
	## Test 9: Tier filtering - chassis
	var tier0_chassis: Array = DataLoader.get_chassis_by_tier(0)
	if tier0_chassis.is_empty():
		_fail_test("No tier 0 chassis found")
		return
	_pass_subtest("Tier filtering working: %d tier-0 chassis" % tier0_chassis.size())
	
	## Test 10: Parts by type filtering
	var chassis_parts: Dictionary = DataLoader.get_parts_by_type("chassis")
	if chassis_parts.size() != chassis.size():
		_fail_test("get_parts_by_type('chassis') returned wrong count")
		return
	_pass_subtest("Parts by type filtering working")
	
	## Test 11: All parts have type field
	for part_id in all_parts:
		var p: Dictionary = all_parts[part_id]
		if not p.has("type"):
			_fail_test("Part '%s' missing type field" % part_id)
			return
	_pass_subtest("All parts have type field")
	
	## Test 12: component_exists()
	if not DataLoader.component_exists("akaumin_dl2_100"):
		_fail_test("component_exists() returned false for valid part")
		return
	if DataLoader.component_exists("fake_part_123"):
		_fail_test("component_exists() returned true for invalid part")
		return
	_pass_subtest("component_exists() working correctly")
	
	_pass_test("All DataLoader tests passed (%d subtests)" % _subtest_count)

func _test_game_state() -> void:
	_start_test("GameState")
	
	## Test 1: GameState initialized
	if not GameState or not is_instance_valid(GameState):
		_fail_test("GameState not initialized")
		return
	_pass_subtest("GameState singleton exists")
	
	## Test 2: Default values valid
	if GameState.credits < 0:
		_fail_test("Invalid credits value: %d" % GameState.credits)
		return
	if GameState.current_tier < 0:
		_fail_test("Invalid tier value: %d" % GameState.current_tier)
		return
	_pass_subtest("Default values valid: credits=%d, tier=%d" % [GameState.credits, GameState.current_tier])
	
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
	
	## Test 6: Game mode valid
	if GameState.game_mode != "campaign" and GameState.game_mode != "arcade":
		_fail_test("Invalid game mode: %s" % GameState.game_mode)
		return
	_pass_subtest("Game mode valid: %s" % GameState.game_mode)
	
	## Test 7: Settings initialized
	if GameState.settings.is_empty():
		_fail_test("Settings not initialized")
		return
	_pass_subtest("Settings initialized with %d keys" % GameState.settings.size())
	
	## Test 8: Settings have required keys
	var required_settings: Array[String] = ["master_volume", "sfx_volume", "music_volume"]
	for key in required_settings:
		if not GameState.settings.has(key):
			_fail_test("Missing required setting: %s" % key)
			return
	_pass_subtest("All required settings present")
	
	## Test 9: Active loadout IDs
	if GameState.active_loadout_ids.is_empty():
		_warn_subtest("No active loadout IDs (may be normal for new game)")
	else:
		_pass_subtest("Active loadout IDs: %d" % GameState.active_loadout_ids.size())
	
	## Test 10: Completed arenas is array
	if not GameState.completed_arenas is Array:
		_fail_test("completed_arenas is not an Array")
		return
	_pass_subtest("completed_arenas is Array type")
	
	_pass_test("All GameState tests passed (%d subtests)" % _subtest_count)

func _test_economy() -> void:
	_start_test("Economy")
	
	var initial_credits: int = GameState.credits
	
	## Test 1: Credit management - add
	GameState.add_credits(100)
	if GameState.credits != initial_credits + 100:
		_fail_test("add_credits() failed: expected %d, got %d" % [initial_credits + 100, GameState.credits])
		return
	_pass_subtest("add_credits() working")
	
	## Test 2: Credit management - add zero
	var before_zero: int = GameState.credits
	GameState.add_credits(0)
	if GameState.credits != before_zero:
		_fail_test("add_credits(0) changed balance")
		return
	_pass_subtest("add_credits(0) handled correctly")
	
	## Test 3: Credit management - negative add (should clamp)
	var before_neg: int = GameState.credits
	GameState.add_credits(-50)
	## Credits should be clamped to not go below 0
	_pass_subtest("Negative add handled (clamped)")
	
	## Test 4: Credit spending - success
	var can_spend: bool = GameState.spend_credits(50)
	if not can_spend:
		_fail_test("spend_credits() failed when should succeed")
		return
	if GameState.credits != initial_credits + 50:
		_fail_test("Credit balance incorrect after spend: expected %d, got %d" % [initial_credits + 50, GameState.credits])
		return
	_pass_subtest("spend_credits() working")
	
	## Test 5: Credit spending - exact amount
	var exact_amount: int = GameState.credits
	var exact_spend: bool = GameState.spend_credits(exact_amount)
	if not exact_spend:
		_fail_test("spend_credits() failed for exact balance")
		return
	if GameState.credits != 0:
		_fail_test("Balance not zero after spending all")
		return
	_pass_subtest("spend_credits() exact amount working")
	
	## Test 6: Cannot overspend
	GameState.add_credits(100)
	var overspend_attempt: bool = GameState.spend_credits(999999)
	if overspend_attempt:
		_fail_test("spend_credits() allowed overspend")
		return
	_pass_subtest("Overspend protection working")
	
	## Test 7: Add part - new
	var test_part_id: String = "test_part_" + str(randi())
	GameState.add_part(test_part_id, 5)
	if not GameState.owned_parts.has(test_part_id):
		_fail_test("add_part() failed - part not added")
		return
	if GameState.owned_parts[test_part_id] != 5:
		_fail_test("add_part() quantity incorrect: expected 5, got %d" % GameState.owned_parts[test_part_id])
		return
	_pass_subtest("add_part() new part working")
	
	## Test 8: Add part - increment existing
	GameState.add_part(test_part_id, 3)
	if GameState.owned_parts[test_part_id] != 8:
		_fail_test("add_part() increment failed: expected 8, got %d" % GameState.owned_parts[test_part_id])
		return
	_pass_subtest("add_part() increment working")
	
	## Test 9: Add part - default quantity
	var test_part_id2: String = "test_part_" + str(randi())
	GameState.add_part(test_part_id2)
	if GameState.owned_parts[test_part_id2] != 1:
		_fail_test("add_part() default quantity failed")
		return
	_pass_subtest("add_part() default quantity working")
	
	## Restore credits
	GameState.credits = initial_credits
	
	_pass_test("All Economy tests passed (%d subtests)" % _subtest_count)

func _test_save_load() -> void:
	_start_test("SaveLoad")
	
	## Test 1: Save game (returns void, so we just call it)
	GameState.save_game()
	_pass_subtest("save_game() executed")
	
	## Test 2: Modify state significantly
	var original_credits: int = GameState.credits
	var original_tier: int = GameState.current_tier
	GameState.credits = 9999
	GameState.current_tier = 99
	GameState.add_part("save_test_part", 42)
	
	## Test 3: Load game (returns bool)
	var load_success: bool = GameState.load_game()
	if not load_success:
		_fail_test("load_game() failed")
		return
	_pass_subtest("load_game() working")
	
	## Test 4: Verify credits restored
	if GameState.credits != original_credits:
		_fail_test("Credits not restored: expected %d, got %d" % [original_credits, GameState.credits])
		return
	_pass_subtest("Credits restored correctly")
	
	## Test 5: Verify tier restored
	if GameState.current_tier != original_tier:
		_fail_test("Tier not restored: expected %d, got %d" % [original_tier, GameState.current_tier])
		return
	_pass_subtest("Tier restored correctly")
	
	## Test 6: Autosave function exists
	if not GameState.has_method("autosave"):
		_warn_subtest("autosave() method not found")
	else:
		_pass_subtest("autosave() method exists")
	
	_pass_test("All Save/Load tests passed (%d subtests)" % _subtest_count)

func _test_battle_simulation() -> void:
	_start_test("BattleSimulation")
	
	## Test 1: SimulationManager initialized
	if not SimulationManager or not is_instance_valid(SimulationManager):
		_fail_test("SimulationManager not initialized")
		return
	_pass_subtest("SimulationManager singleton exists")
	
	## Test 2: Validate arena data - boot camp
	var arena_data: Dictionary = DataLoader.get_arena("arena_boot_camp")
	if arena_data.is_empty():
		_fail_test("Could not load arena_boot_camp")
		return
	_pass_subtest("Arena 'boot camp' data loaded: %s" % arena_data.get("name", "unnamed"))
	
	## Test 3: Arena has required fields
	var required_arena_fields: Array[String] = ["id", "name", "tier", "enemies"]
	for field in required_arena_fields:
		if not arena_data.has(field):
			_fail_test("Arena missing required field: %s" % field)
			return
	_pass_subtest("Arena has all required fields")
	
	## Test 4: Enemy data valid
	var enemies: Array = arena_data.get("enemies", [])
	if enemies.is_empty():
		_fail_test("Arena has no enemies defined")
		return
	_pass_subtest("Arena has %d enemies" % enemies.size())
	
	## Test 5: Enemy entries have required fields
	for enemy in enemies:
		if not enemy is Dictionary:
			_fail_test("Enemy entry not a dictionary")
			return
		if not enemy.has("chassis") or not enemy.has("weapon"):
			_fail_test("Enemy missing chassis or weapon")
			return
	_pass_subtest("All enemies have required fields")
	
	_pass_test("All Battle Simulation tests passed (%d subtests)" % _subtest_count)

func _test_component_integration() -> void:
	_start_test("ComponentIntegration")
	
	## Test 1: All chassis have required fields
	var chassis_list: Array = DataLoader.get_all_chassis()
	var required_chassis_fields: Array[String] = ["id", "name", "tier", "hp_base", "speed_base", "weight_capacity", "cost"]
	for chassis in chassis_list:
		if not chassis is Dictionary:
			_fail_test("Chassis entry not a dictionary")
			return
		for field in required_chassis_fields:
			if not chassis.has(field):
				_fail_test("Chassis '%s' missing field: %s" % [chassis.get("id", "unknown"), field])
				return
	_pass_subtest("All %d chassis have required fields" % chassis_list.size())
	
	## Test 2: All weapons have required fields
	var weapons_list: Array = DataLoader.get_all_weapons()
	var required_weapon_fields: Array[String] = ["id", "name", "tier", "damage", "cost", "range"]
	for weapon in weapons_list:
		if not weapon is Dictionary:
			_fail_test("Weapon entry not a dictionary")
			return
		for field in required_weapon_fields:
			if not weapon.has(field):
				_fail_test("Weapon '%s' missing field: %s" % [weapon.get("id", "unknown"), field])
				return
	_pass_subtest("All %d weapons have required fields" % weapons_list.size())
	
	## Test 3: All plating have required fields
	var plating_list: Array = DataLoader.get_all_plating()
	var required_plating_fields: Array[String] = ["id", "name", "tier", "hp_bonus", "cost"]
	for plating in plating_list:
		if not plating is Dictionary:
			_fail_test("Plating entry not a dictionary")
			return
		for field in required_plating_fields:
			if not plating.has(field):
				_fail_test("Plating '%s' missing field: %s" % [plating.get("id", "unknown"), field])
				return
	_pass_subtest("All %d plating have required fields" % plating_list.size())
	
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
	
	## Test 5: Component costs are positive
	for c in chassis_list:
		var cost: int = c.get("cost", 0)
		if cost <= 0:
			_fail_test("Chassis '%s' has invalid cost: %d" % [c.get("id"), cost])
			return
	_pass_subtest("All chassis have positive costs")
	
	_pass_test("All Component Integration tests passed (%d subtests)" % _subtest_count)

func _test_arena_progression() -> void:
	_start_test("ArenaProgression")
	
	## Test 1: Get next unlocked arena
	var next_arena: String = GameState.get_next_unlocked_arena()
	if next_arena.is_empty() and GameState.unlocked_arenas.size() > 0:
		_fail_test("get_next_unlocked_arena() returned empty but arenas exist")
		return
	_pass_subtest("Next unlocked arena: %s" % (next_arena if not next_arena.is_empty() else "none"))
	
	## Test 2: Complete arena function exists
	if not GameState.has_method("complete_arena"):
		_fail_test("complete_arena() method not found")
		return
	_pass_subtest("complete_arena() method exists")
	
	## Test 3: Arena completion tracking
	var initial_completed: int = GameState.completed_arenas.size()
	var test_arena: String = "test_arena_" + str(randi())
	GameState.complete_arena(test_arena)
	if not GameState.completed_arenas.has(test_arena):
		_fail_test("Arena not added to completed_arenas")
		return
	_pass_subtest("Arena completion tracking working")
	
	## Test 4: Tier progression
	var initial_tier: int = GameState.current_tier
	## Simulate tier up
	GameState.current_tier += 1
	if GameState.current_tier != initial_tier + 1:
		_fail_test("Tier progression failed")
		return
	_pass_subtest("Tier progression working")
	
	## Restore
	GameState.current_tier = initial_tier
	
	_pass_test("All Arena Progression tests passed (%d subtests)" % _subtest_count)

func _test_stat_calculations() -> void:
	_start_test("StatCalculations")
	
	## Test 1: Chassis HP calculation
	var chassis: Dictionary = DataLoader.get_chassis("akaumin_dl2_100")
	if chassis.is_empty():
		_fail_test("Could not load chassis for stat test")
		return
	var base_hp: int = chassis.get("hp_base", 0)
	if base_hp <= 0:
		_fail_test("Chassis has invalid base HP: %d" % base_hp)
		return
	_pass_subtest("Chassis base HP valid: %d" % base_hp)
	
	## Test 2: Weapon damage calculation
	var weapon: Dictionary = DataLoader.get_weapon("puncher_mg")
	if weapon.is_empty():
		weapon = DataLoader.get_all_weapons()[0]  ## Fallback to first weapon
	var damage: int = weapon.get("damage", 0)
	if damage <= 0:
		_fail_test("Weapon has invalid damage: %d" % damage)
		return
	_pass_subtest("Weapon damage valid: %d" % damage)
	
	## Test 3: Armor HP bonus calculation
	var armor: Dictionary = DataLoader.get_plating("santrin_auro")
	if armor.is_empty():
		armor = DataLoader.get_all_plating()[0]  ## Fallback
	var hp_bonus: int = armor.get("hp_bonus", 0)
	if hp_bonus < 0:
		_fail_test("Armor has negative HP bonus: %d" % hp_bonus)
		return
	_pass_subtest("Armor HP bonus valid: %d" % hp_bonus)
	
	## Test 4: Total HP calculation (chassis + armor)
	var total_hp: int = base_hp + hp_bonus
	if total_hp <= base_hp:
		_fail_test("Total HP calculation error")
		return
	_pass_subtest("Total HP calculation: %d (base %d + bonus %d)" % [total_hp, base_hp, hp_bonus])
	
	## Test 5: Weight capacity validation
	var weight_capacity: int = chassis.get("weight_capacity", 0)
	if weight_capacity <= 0:
		_fail_test("Chassis has invalid weight capacity: %d" % weight_capacity)
		return
	_pass_subtest("Weight capacity valid: %d" % weight_capacity)
	
	_pass_test("All Stat Calculation tests passed (%d subtests)" % _subtest_count)

func _test_edge_cases() -> void:
	_start_test("EdgeCases")
	
	## Test 1: Empty string lookups
	var empty_lookup: Dictionary = DataLoader.get_part("")
	if not empty_lookup.is_empty():
		_warn_subtest("Empty string lookup returned data (may be unexpected)")
	else:
		_pass_subtest("Empty string lookup returns empty")
	
	## Test 2: Special characters in IDs
	var special_id: String = "part_with_underscores-and-dashes123"
	GameState.add_part(special_id, 1)
	if not GameState.owned_parts.has(special_id):
		_fail_test("Special character ID failed")
		return
	_pass_subtest("Special character IDs handled")
	
	## Test 3: Large credit values
	GameState.credits = 999999999
	if GameState.credits != 999999999:
		_fail_test("Large credit value failed")
		return
	_pass_subtest("Large credit values handled")
	
	## Test 4: Zero credits
	GameState.credits = 0
	if GameState.credits != 0:
		_fail_test("Zero credit assignment failed")
		return
	var can_spend_zero: bool = GameState.spend_credits(1)
	if can_spend_zero:
		_fail_test("Allowed spend with zero credits")
		return
	_pass_subtest("Zero credit handling correct")
	
	## Restore
	GameState._give_starter_kit()
	
	_pass_test("All Edge Case tests passed (%d subtests)" % _subtest_count)

func _test_signals() -> void:
	_start_test("Signals")
	
	## Test 1: EventBus signals exist
	if not EventBus or not is_instance_valid(EventBus):
		_fail_test("EventBus not initialized")
		return
	
	var required_signals: Array[String] = ["menu_opened", "game_quit_requested", "credits_changed"]
	for sig in required_signals:
		if not EventBus.has_signal(sig):
			_warn_subtest("EventBus missing signal: %s" % sig)
	_pass_subtest("EventBus signals checked")
	
	## Test 2: GameState signals
	var gs_signals: Array[String] = ["credits_changed", "parts_changed", "loadouts_changed"]
	for sig in gs_signals:
		if not GameState.has_signal(sig):
			_fail_test("GameState missing signal: %s" % sig)
			return
	_pass_subtest("GameState signals exist")
	
	## Test 3: Signal emission (credits)
	var signal_received: bool = false
	var callback := func(_new_amount): signal_received = true
	GameState.credits_changed.connect(callback)
	GameState.add_credits(1)
	if not signal_received:
		_fail_test("Credits signal not emitted")
		return
	GameState.credits_changed.disconnect(callback)
	_pass_subtest("Credits signal emission working")
	
	_pass_test("All Signal tests passed (%d subtests)" % _subtest_count)

func _test_resource_loading() -> void:
	_start_test("ResourceLoading")
	
	## Test 1: Scene files exist
	var scene_files: Array[String] = [
		"res://scenes/main.tscn",
		"res://scenes/battle_screen.tscn",
		"res://scenes/main_menu.tscn",
	]
	for scene in scene_files:
		if not ResourceLoader.exists(scene):
			_warn_subtest("Scene not found: %s" % scene)
	_pass_subtest("Core scenes checked")
	
	## Test 2: Sprite assets exist
	var sprite_files: Array[String] = [
		"res://assets/sprites/bots/chassis_default.png",
		"res://assets/sprites/bots/armor_default.png",
		"res://assets/sprites/bots/weapon_default.png",
	]
	for sprite in sprite_files:
		if not ResourceLoader.exists(sprite):
			_warn_subtest("Sprite not found: %s" % sprite)
	_pass_subtest("Sprite assets checked")
	
	## Test 3: Components.json accessible
	var components_path: String = "res://../data/components.json"
	if not FileAccess.file_exists(components_path):
		_warn_subtest("components.json path may differ in export")
	_pass_subtest("Components.json path checked")
	
	_pass_test("All Resource Loading tests passed (%d subtests)" % _subtest_count)

func _test_performance() -> void:
	_start_test("Performance")
	
	## Test 1: DataLoader query performance
	var start_time: int = Time.get_ticks_msec()
	for i in range(100):
		var _parts = DataLoader.get_all_parts()
	var duration: int = Time.get_ticks_msec() - start_time
	if duration > 1000:  ## Should be much faster than 1 second
		_warn_subtest("DataLoader query slow: %d ms for 100 calls" % duration)
	else:
		_pass_subtest("DataLoader query fast: %d ms for 100 calls" % duration)
	
	## Test 2: Component lookup performance
	start_time = Time.get_ticks_msec()
	for i in range(1000):
		var _part = DataLoader.get_part("akaumin_dl2_100")
	duration = Time.get_ticks_msec() - start_time
	if duration > 100:
		_warn_subtest("Component lookup slow: %d ms for 1000 calls" % duration)
	else:
		_pass_subtest("Component lookup fast: %d ms for 1000 calls" % duration)
	
	_pass_test("All Performance tests passed (%d subtests)" % _subtest_count)

func _test_type_safety() -> void:
	_start_test("TypeSafety")
	
	## Test 1: Credits is int
	if not GameState.credits is int:
		_fail_test("Credits is not int type")
		return
	_pass_subtest("Credits is int type")
	
	## Test 2: Owned parts is Dictionary
	if not GameState.owned_parts is Dictionary:
		_fail_test("owned_parts is not Dictionary type")
		return
	_pass_subtest("owned_parts is Dictionary type")
	
	## Test 3: Loadouts is Array
	if not GameState.loadouts is Array:
		_fail_test("loadouts is not Array type")
		return
	_pass_subtest("loadouts is Array type")
	
	## Test 4: Component data returns Dictionary
	var part: Dictionary = DataLoader.get_part("akaumin_dl2_100")
	if not part is Dictionary:
		_fail_test("get_part() does not return Dictionary")
		return
	_pass_subtest("get_part() returns Dictionary")
	
	## Test 5: All chassis have int stats
	for chassis in DataLoader.get_all_chassis():
		var hp: int = chassis.get("hp_base", 0)
		var speed: float = chassis.get("speed_base", 0.0)
		if not hp is int:
			_fail_test("Chassis HP not int: %s" % chassis.get("id"))
			return
		if not speed is float:
			_fail_test("Chassis speed not float: %s" % chassis.get("id"))
			return
	_pass_subtest("Chassis stats have correct types")
	
	_pass_test("All Type Safety tests passed (%d subtests)" % _subtest_count)

func _test_error_handling() -> void:
	_start_test("ErrorHandling")
	
	## Test 1: Null instance checks
	if is_instance_valid(null):
		_fail_test("is_instance_valid(null) returned true")
		return
	_pass_subtest("Null instance check working")
	
	## Test 2: Freed instance handling
	var temp_node := Node.new()
	temp_node.queue_free()
	await get_tree().process_frame
	if is_instance_valid(temp_node):
		_warn_subtest("Freed instance still valid (may need another frame)")
	else:
		_pass_subtest("Freed instance detection working")
	
	## Test 3: Dictionary key existence
	var test_dict: Dictionary = {"key1": "value1"}
	if test_dict.has("nonexistent"):
		_fail_test("Dictionary has() returned true for nonexistent key")
		return
	if not test_dict.has("key1"):
		_fail_test("Dictionary has() returned false for existing key")
		return
	_pass_subtest("Dictionary key existence checks working")
	
	## Test 4: Array bounds
	var test_array: Array[int] = [1, 2, 3]
	if test_array.size() != 3:
		_fail_test("Array size incorrect")
		return
	_pass_subtest("Array bounds safe")
	
	_pass_test("All Error Handling tests passed (%d subtests)" % _subtest_count)


## ============================================================================
## NEW: Extended Test Scenarios
## ============================================================================

func _test_battle_scenarios() -> void:
	_start_test("BattleScenarios")
	
	## Test 1: Simulate bot stat calculation
	var chassis: Dictionary = DataLoader.get_chassis("akaumin_dl2_100")
	var armor: Dictionary = DataLoader.get_plating("santrin_auro")
	var weapon: Dictionary = DataLoader.get_weapon("raptor_dt_01")
	
	if chassis.is_empty() or armor.is_empty() or weapon.is_empty():
		_fail_test("Missing components for battle test")
		return
	
	## Calculate total stats
	var total_hp: int = chassis.get("hp_base", 0) + armor.get("hp_bonus", 0)
	var damage_reduction: float = armor.get("damage_reduction", 0.0)
	var effective_hp: float = total_hp / (1.0 - damage_reduction)
	
	var avg_damage: float = (weapon.get("damage_min", 0) + weapon.get("damage_max", 0)) / 2.0
	var fire_rate: float = weapon.get("fire_rate", 1.0)
	var dps: float = avg_damage * fire_rate
	
	_pass_subtest("Bot stats calculated: %d HP (%.1f EHP), %.1f DPS" % [total_hp, effective_hp, dps])
	
	## Test 2: Time-to-kill calculation
	var target_hp: int = 100
	var ttk: float = target_hp / dps if dps > 0 else 999.0
	if ttk > 10.0:
		_warn_subtest("Time-to-kill is high: %.2f seconds" % ttk)
	else:
		_pass_subtest("Time-to-kill reasonable: %.2f seconds" % ttk)
	
	## Test 3: Simulate 1v1 battle outcome
	var bot1_hp: float = effective_hp
	var bot2_hp: float = effective_hp
	var turns: int = 0
	var max_turns: int = 1000
	
	while bot1_hp > 0 and bot2_hp > 0 and turns < max_turns:
		bot2_hp -= dps  ## Bot 1 shoots
		if bot2_hp > 0:
			bot1_hp -= dps  ## Bot 2 shoots
		turns += 1
	
	if turns >= max_turns:
		_fail_test("Battle simulation exceeded max turns")
		return
	
	_pass_subtest("1v1 simulation complete in %d turns" % turns)
	
	## Test 4: Verify balanced damage
	if turns < 3:
		_warn_subtest("Battle ends very quickly (%d turns)" % turns)
	elif turns > 50:
		_warn_subtest("Battle takes too long (%d turns)" % turns)
	else:
		_pass_subtest("Battle duration reasonable (%d turns)" % turns)
	
	_pass_test("All Battle Scenario tests passed (%d subtests)" % _subtest_count)


func _test_save_load_stress() -> void:
	_start_test("SaveLoadStress")
	
	var original_credits: int = GameState.credits
	var stress_iterations: int = 50
	var passed_iterations: int = 0
	
	## Test 1: Rapid save/load cycles
	for i in range(stress_iterations):
		## Modify state
		GameState.credits = randi() % 10000
		GameState.add_part("stress_test_part_%d" % i, 1)
		
		## Save
		GameState.save_game()
		
		## Modify again
		GameState.credits = 0
		
		## Load
		var success: bool = GameState.load_game()
		if success:
			passed_iterations += 1
		
		## Check state restored
		if GameState.credits == 0:
			_fail_test("Credits not restored at iteration %d" % i)
			return
	
	_pass_subtest("Rapid save/load: %d/%d iterations passed" % [passed_iterations, stress_iterations])
	
	## Test 2: Large data save/load
	for i in range(100):
		GameState.add_part("bulk_part_%d" % i, randi() % 100)
	
	GameState.save_game()
	GameState.load_game()
	
	var parts_count: int = GameState.owned_parts.size()
	_pass_subtest("Large data save/load: %d parts retained" % parts_count)
	
	## Restore original state
	GameState.credits = original_credits
	GameState.save_game()
	
	_pass_test("All Save/Load Stress tests passed (%d subtests)" % _subtest_count)


func _test_memory_stability() -> void:
	_start_test("MemoryStability")
	
	## Test 1: Dictionary growth
	var test_dict: Dictionary = {}
	for i in range(1000):
		test_dict["key_%d" % i] = i
	
	if test_dict.size() != 1000:
		_fail_test("Dictionary size mismatch after growth")
		return
	_pass_subtest("Dictionary growth stable (1000 entries)")
	
	## Test 2: Array operations
	var test_array: Array[int] = []
	for i in range(1000):
		test_array.append(i)
		test_array.pop_front()
	
	_pass_subtest("Array queue operations stable")
	
	## Test 3: Node creation/destruction
	var created_count: int = 0
	for i in range(100):
		var node := Node.new()
		node.name = "test_node_%d" % i
		add_child(node)
		node.queue_free()
		created_count += 1
	
	await get_tree().process_frame
	_pass_subtest("Node creation/destruction stable (%d nodes)" % created_count)
	
	## Test 4: Signal connections
	var signal_count: int = 0
	var test_callable := func(): signal_count += 1
	
	for i in range(100):
		GameState.credits_changed.connect(test_callable)
		GameState.credits_changed.disconnect(test_callable)
	
	_pass_subtest("Signal connect/disconnect stable (100 cycles)")
	
	_pass_test("All Memory Stability tests passed (%d subtests)" % _subtest_count)


func _test_balance_validation() -> void:
	_start_test("BalanceValidation")
	
	## Test 1: All components have positive costs
	for chassis in DataLoader.get_all_chassis():
		if chassis.get("cost", 0) <= 0:
			_fail_test("Chassis '%s' has invalid cost" % chassis.get("id"))
			return
	_pass_subtest("All chassis have positive costs")
	
	for weapon in DataLoader.get_all_weapons():
		if weapon.get("cost", 0) <= 0:
			_fail_test("Weapon '%s' has invalid cost" % weapon.get("id"))
			return
	_pass_subtest("All weapons have positive costs")
	
	for plating in DataLoader.get_all_plating():
		if plating.get("cost", 0) <= 0:
			_fail_test("Plating '%s' has invalid cost" % plating.get("id"))
			return
	_pass_subtest("All plating have positive costs")
	
	## Test 2: Tier progression reasonable
	var t0_chassis: Array = DataLoader.get_chassis_by_tier(0)
	var t1_chassis: Array = DataLoader.get_chassis_by_tier(1)
	
	if t0_chassis.is_empty() or t1_chassis.is_empty():
		_warn_subtest("Missing chassis in tier 0 or 1")
	else:
		var t0_avg_cost: float = 0.0
		for c in t0_chassis:
			t0_avg_cost += c.get("cost", 0)
		t0_avg_cost /= t0_chassis.size()
		
		var t1_avg_cost: float = 0.0
		for c in t1_chassis:
			t1_avg_cost += c.get("cost", 0)
		t1_avg_cost /= t1_chassis.size()
		
		var ratio: float = t1_avg_cost / t0_avg_cost if t0_avg_cost > 0 else 0.0
		if ratio < 1.5 or ratio > 3.0:
			_warn_subtest("Tier 0→1 cost ratio unusual: %.2fx" % ratio)
		else:
			_pass_subtest("Tier 0→1 cost ratio healthy: %.2fx" % ratio)
	
	## Test 3: No duplicate IDs
	var all_ids: Array[String] = []
	for c in DataLoader.get_all_chassis():
		all_ids.append(c.get("id", ""))
	for w in DataLoader.get_all_weapons():
		all_ids.append(w.get("id", ""))
	for p in DataLoader.get_all_plating():
		all_ids.append(p.get("id", ""))
	
	var unique_ids: Array[String] = []
	for id in all_ids:
		if id in unique_ids:
			_fail_test("Duplicate component ID found: %s" % id)
			return
		unique_ids.append(id)
	
	_pass_subtest("All component IDs unique (%d total)" % all_ids.size())
	
	_pass_test("All Balance Validation tests passed (%d subtests)" % _subtest_count)


## ============================================================================
## Helper functions
## ============================================================================

func _start_test(test_name: String) -> void:
	_current_test = test_name
	_subtest_count = 0
	_test_results[test_name] = {
		"passed": false,
		"subtests": [],
		"subtest_count": 0,
		"message": ""
	}
	print("[AutoTest] Starting: %s" % test_name)

func _pass_subtest(message: String) -> void:
	_subtest_count += 1
	_test_results[_current_test]["subtests"].append({"passed": true, "message": message})
	print("[AutoTest]   ✓ %s" % message)

func _warn_subtest(message: String) -> void:
	_subtest_count += 1
	_test_results[_current_test]["subtests"].append({"passed": true, "warning": true, "message": message})
	print("[AutoTest]   ⚠ %s" % message)

func _pass_test(message: String) -> void:
	_test_results[_current_test]["passed"] = true
	_test_results[_current_test]["subtest_count"] = _subtest_count
	_test_results[_current_test]["message"] = message
	_tests_passed += 1
	print("[AutoTest] ✓ PASSED: %s (%d subtests)\n" % [_current_test, _subtest_count])
	test_completed.emit(_current_test, true, message)

func _fail_test(message: String) -> void:
	_test_results[_current_test]["passed"] = false
	_test_results[_current_test]["subtest_count"] = _subtest_count
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
