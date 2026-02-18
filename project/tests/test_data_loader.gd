extends GutTest
## Tests for DataLoader — valid lookups, missing IDs, error cases.
## Implementation: TASK-03

const DataLoaderCore := preload("res://src/managers/data_loader.gd")

var _loader: RefCounted


func before_all() -> void:
	_loader = DataLoaderCore.new()
	_loader.load_all()


# --- Parts ---

func test_get_part_wpn_mg_t1_returns_non_null() -> void:
	var part: Variant = _loader.get_part("wpn_mg_t1")
	assert_not_null(part, "wpn_mg_t1 should exist")


func test_get_part_wpn_mg_t1_has_id() -> void:
	var part_v: Variant = _loader.get_part("wpn_mg_t1")
	assert_true(part_v is Dictionary, "wpn_mg_t1 should be a Dictionary")
	var part: Dictionary = part_v as Dictionary
	assert_eq(part["id"], "wpn_mg_t1")


func test_get_part_wpn_mg_t1_has_category() -> void:
	var part_v: Variant = _loader.get_part("wpn_mg_t1")
	assert_true(part_v is Dictionary, "wpn_mg_t1 should be a Dictionary")
	var part: Dictionary = part_v as Dictionary
	assert_eq(part["category"], "weapon")


func test_get_part_wpn_mg_t1_has_stats() -> void:
	var part_v: Variant = _loader.get_part("wpn_mg_t1")
	assert_true(part_v is Dictionary, "wpn_mg_t1 should be a Dictionary")
	var part: Dictionary = part_v as Dictionary

	assert_true(part.has("stats"), "wpn_mg_t1 should have stats")
	assert_true(part["stats"] is Dictionary, "stats should be a Dictionary")

	var stats: Dictionary = part["stats"] as Dictionary
	assert_true(stats.has("damage_per_shot"), "stats should have damage_per_shot")


func test_get_all_parts_count() -> void:
	var parts: Array = _loader.get_all_parts()
	assert_eq(parts.size(), 15, "Should have 15 parts in vertical slice")


# --- Arenas ---

func test_get_arena_training_returns_non_null() -> void:
	var arena: Variant = _loader.get_arena("arena_training")
	assert_not_null(arena, "arena_training should exist")


func test_get_arena_training_has_id() -> void:
	var arena_v: Variant = _loader.get_arena("arena_training")
	assert_true(arena_v is Dictionary, "arena_training should be a Dictionary")
	var arena: Dictionary = arena_v as Dictionary
	assert_eq(arena["id"], "arena_training")


func test_get_all_arenas_count() -> void:
	var arenas: Array = _loader.get_all_arenas()
	assert_eq(arenas.size(), 3, "Should have 3 arenas in vertical slice")


# --- Bots ---

func test_get_bot_starter_scout() -> void:
	var bot_v: Variant = _loader.get_bot("bot_starter_scout")
	assert_not_null(bot_v, "bot_starter_scout should exist")
	assert_true(bot_v is Dictionary, "bot_starter_scout should be a Dictionary")

	var bot: Dictionary = bot_v as Dictionary
	assert_eq(bot["chassis"], "chassis_light_t1")


func test_get_all_bots_count() -> void:
	var bots: Array = _loader.get_all_bots()
	assert_eq(bots.size(), 1)


# --- Enemies ---

func test_get_enemy_scout_t1() -> void:
	var enemy_v: Variant = _loader.get_enemy("enemy_scout_t1")
	assert_not_null(enemy_v, "enemy_scout_t1 should exist")
	assert_true(enemy_v is Dictionary, "enemy_scout_t1 should be a Dictionary")

	var enemy: Dictionary = enemy_v as Dictionary
	assert_eq(enemy["ai_profile"], "ai_aggressive")


func test_get_all_enemies_count() -> void:
	var enemies: Array = _loader.get_all_enemies()
	assert_eq(enemies.size(), 6)


# --- Campaign ---

func test_get_campaign_node_01() -> void:
	var node_v: Variant = _loader.get_campaign_node("node_01_training")
	assert_not_null(node_v, "node_01_training should exist")
	assert_true(node_v is Dictionary, "node_01_training should be a Dictionary")

	var node: Dictionary = node_v as Dictionary
	assert_eq(node["arena_id"], "arena_training")


func test_get_all_campaign_nodes_count() -> void:
	var nodes: Array = _loader.get_all_campaign_nodes()
	assert_eq(nodes.size(), 3)


# --- Economy ---

func test_economy_config_loaded() -> void:
	var econ: Dictionary = _loader.get_economy_config()
	assert_true(econ.size() > 0, "Economy config should not be empty")
	assert_eq(econ["starting_credits"], 200)


func test_economy_has_repair_cost() -> void:
	var econ: Dictionary = _loader.get_economy_config()
	assert_eq(econ["repair_cost_per_hp"], 0.5)


# --- Missing ID returns null ---

func test_missing_part_returns_null() -> void:
	assert_null(_loader.get_part("nonexistent_part"))


func test_missing_arena_returns_null() -> void:
	assert_null(_loader.get_arena("nonexistent_arena"))


func test_missing_bot_returns_null() -> void:
	assert_null(_loader.get_bot("nonexistent_bot"))


func test_missing_enemy_returns_null() -> void:
	assert_null(_loader.get_enemy("nonexistent_enemy"))


func test_missing_campaign_node_returns_null() -> void:
	assert_null(_loader.get_campaign_node("nonexistent_node"))


# --- Idempotent load ---

func test_load_all_idempotent() -> void:
	var count_before: int = _loader.get_all_parts().size()
	_loader.load_all()
	var count_after: int = _loader.get_all_parts().size()
	assert_eq(count_before, count_after, "Calling load_all() twice should not duplicate data")
