extends RefCounted
## Deterministic random number generator for simulation.
## Seeded from battle hash - same seed produces identical results.

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _seed: int = 0


func _init(p_seed: int = 0) -> void:
	_seed = p_seed
	_rng.seed = _seed


func reset() -> void:
	_rng.seed = _seed


func randf() -> float:
	return _rng.randf()


func randi_range(min_val: int, max_val: int) -> int:
	return _rng.randi_range(min_val, max_val)


func randf_range(min_val: float, max_val: float) -> float:
	return _rng.randf_range(min_val, max_val)


static func hash_battle_seed(arena_id: String, player_bots: Array, enemy_bots: Array) -> int:
	## Create deterministic seed from battle setup
	var hash_str: String = arena_id + "|"
	
	for bot in player_bots:
		hash_str += str(bot.get("id", "")) + ","
	
	hash_str += "|"
	
	for bot in enemy_bots:
		hash_str += str(bot.get("id", "")) + ","
	
	# Simple string hash
	var hash_val: int = 0
	for c in hash_str:
		hash_val = ((hash_val << 5) - hash_val) + c.unicode_at(0)
		hash_val = hash_val & 0xFFFFFFFF  # Keep positive
	
	return hash_val
