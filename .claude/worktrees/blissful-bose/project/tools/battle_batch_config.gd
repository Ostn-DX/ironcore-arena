class_name BattleBatchConfig extends Resource

## Configuration resource for a batch of battle simulations.
## This resource defines all parameters for running headless balance tests,
## including seeds, match counts, team compositions, and output settings.
##
## @tutorial: Save as .tres file for reuse in EditorScript runs

@export var seeds: PackedInt32Array = PackedInt32Array([12345, 67890, 11111])
## Array of random seeds for deterministic simulation.
## Each seed will run matches_per_seed times.

@export var matches_per_seed: int = 10
## Number of matches to run per seed.
## Higher values give more statistically significant results.

@export var bots_per_team: int = 5
## Number of bots on each team.
## Default 5v5 matches.

@export var tier: int = 1
## Difficulty tier being tested (1-10).
## Used for difficulty curve analysis.

@export var arena_id: String = "arena_default"
## Identifier for the arena/level configuration.
## Different arenas may have different balance implications.

@export var output_dir: String = "res://reports/balance/"
## Directory where reports will be written.
## Will be created if it doesn't exist.

@export var max_ticks_per_match: int = 10800
## Maximum simulation ticks per match (default: 3 minutes at 60Hz).
## Matches exceeding this will end in timeout.

@export var timeout_ticks: int = 21600
## Hard timeout limit (default: 6 minutes at 60Hz).
## Simulation will force-end regardless of state.

@export var team_a_loadout: Dictionary = {}
## Loadout configuration for Team A bots.
## Example: {"weapon_id": "laser_rifle", "health": 100, "chassis_id": "light"}

@export var team_b_loadout: Dictionary = {}
## Loadout configuration for Team B bots.
## Example: {"weapon_id": "plasma_cannon", "health": 150, "chassis_id": "heavy"}

@export var enable_detailed_logging: bool = false
## If true, logs detailed per-tick information.
## Significantly increases output size.

@export var collect_heatmap_data: bool = false
## If true, collects position heatmap data for analysis.
## Useful for analyzing map balance.

@export var report_formats: PackedStringArray = PackedStringArray(["json", "csv"])
## Output formats to generate. Options: "json", "csv", "html"

@export var balance_targets: Dictionary = {}
## Target values for balance validation.
## Example: {"win_rate_min": 0.45, "win_rate_max": 0.55, "ttk_target": 15.0}

@export var bot_difficulty: float = 1.0
## Difficulty multiplier for bot AI (0.5 = easy, 1.0 = normal, 2.0 = hard).

@export var simulation_speed: float = 1.0
## Simulation speed multiplier (higher = faster but less accurate).
## Values above 10.0 may cause physics issues.


## Calculates the total number of matches in this batch.
##
## @return: Total match count (seeds.size() * matches_per_seed)
## @example:
##     var config = BattleBatchConfig.new()
##     config.seeds = PackedInt32Array([1, 2, 3])
##     config.matches_per_seed = 5
##     print(config.get_total_matches())  # Prints: 15
func get_total_matches() -> int:
	return seeds.size() * matches_per_seed


## Gets the estimated duration of this batch in seconds.
##
## @param avg_match_duration: Average match duration in seconds
## @return: Estimated total duration in seconds
func get_estimated_duration(avg_match_duration: float = 60.0) -> float:
	return get_total_matches() * avg_match_duration / simulation_speed


## Validates the configuration.
##
## @return: Dictionary with "valid" boolean and "errors" array
func validate() -> Dictionary:
	var errors: Array[String] = []
	
	if seeds.is_empty():
		errors.append("At least one seed is required")
	
	if matches_per_seed <= 0:
		errors.append("matches_per_seed must be positive")
	
	if bots_per_team <= 0:
		errors.append("bots_per_team must be positive")
	
	if max_ticks_per_match <= 0:
		errors.append("max_ticks_per_match must be positive")
	
	if timeout_ticks < max_ticks_per_match:
		errors.append("timeout_ticks must be >= max_ticks_per_match")
	
	if tier < 1 or tier > 10:
		errors.append("tier must be between 1 and 10")
	
	return {
		"valid": errors.is_empty(),
		"errors": errors
	}


## Creates a default configuration for quick testing.
##
## @return: A BattleBatchConfig with sensible defaults
static func create_default() -> BattleBatchConfig:
	var config := BattleBatchConfig.new()
	config.seeds = PackedInt32Array([12345, 67890, 11111])
	config.matches_per_seed = 10
	config.bots_per_team = 5
	config.tier = 1
	config.arena_id = "arena_default"
	config.team_a_loadout = {
		"weapon_id": "laser_rifle",
		"chassis_id": "medium",
		"health": 100.0
	}
	config.team_b_loadout = {
		"weapon_id": "laser_rifle",
		"chassis_id": "medium",
		"health": 100.0
	}
	return config


## Creates a mirror match configuration (identical teams).
##
## @param loadout: The loadout to use for both teams
## @return: A BattleBatchConfig with symmetric teams
static func create_mirror_match(loadout: Dictionary = {}) -> BattleBatchConfig:
	var config := create_default()
	
	var default_loadout := {
		"weapon_id": "laser_rifle",
		"chassis_id": "medium",
		"health": 100.0
	}
	
	var final_loadout := default_loadout.duplicate()
	final_loadout.merge(loadout, true)
	
	config.team_a_loadout = final_loadout.duplicate()
	config.team_b_loadout = final_loadout.duplicate()
	
	return config


## Creates a configuration for testing specific weapon matchups.
##
## @param weapon_a: Weapon ID for Team A
## @param weapon_b: Weapon ID for Team B
## @return: A BattleBatchConfig configured for weapon testing
static func create_weapon_matchup(weapon_a: String, weapon_b: String) -> BattleBatchConfig:
	var config := create_default()
	config.team_a_loadout = {
		"weapon_id": weapon_a,
		"chassis_id": "medium",
		"health": 100.0
	}
	config.team_b_loadout = {
		"weapon_id": weapon_b,
		"chassis_id": "medium",
		"health": 100.0
	}
	return config


## Creates a configuration for difficulty curve analysis.
##
## @param start_tier: Starting tier level
## @param end_tier: Ending tier level
## @return: Array of BattleBatchConfig for each tier
static func create_difficulty_curve(start_tier: int = 1, end_tier: int = 10) -> Array[BattleBatchConfig]:
	var configs: Array[BattleBatchConfig] = []
	
	for tier in range(start_tier, end_tier + 1):
		var config := create_default()
		config.tier = tier
		config.bots_per_team = 5
		# Scale difficulty with tier
		config.bot_difficulty = 0.5 + (tier / 10.0) * 1.5
		configs.append(config)
	
	return configs


## Serializes the configuration to a dictionary.
##
## @return: Dictionary representation of this config
func to_dictionary() -> Dictionary:
	return {
		"seeds": Array(seeds),
		"matches_per_seed": matches_per_seed,
		"bots_per_team": bots_per_team,
		"tier": tier,
		"arena_id": arena_id,
		"output_dir": output_dir,
		"max_ticks_per_match": max_ticks_per_match,
		"timeout_ticks": timeout_ticks,
		"team_a_loadout": team_a_loadout,
		"team_b_loadout": team_b_loadout,
		"enable_detailed_logging": enable_detailed_logging,
		"collect_heatmap_data": collect_heatmap_data,
		"report_formats": Array(report_formats),
		"balance_targets": balance_targets,
		"bot_difficulty": bot_difficulty,
		"simulation_speed": simulation_speed
	}


## Loads configuration from a dictionary.
##
## @param data: Dictionary containing configuration values
## @return: This instance for method chaining
func from_dictionary(data: Dictionary) -> BattleBatchConfig:
	if data.has("seeds"):
		seeds = PackedInt32Array(data.seeds)
	if data.has("matches_per_seed"):
		matches_per_seed = data.matches_per_seed
	if data.has("bots_per_team"):
		bots_per_team = data.bots_per_team
	if data.has("tier"):
		tier = data.tier
	if data.has("arena_id"):
		arena_id = data.arena_id
	if data.has("output_dir"):
		output_dir = data.output_dir
	if data.has("max_ticks_per_match"):
		max_ticks_per_match = data.max_ticks_per_match
	if data.has("timeout_ticks"):
		timeout_ticks = data.timeout_ticks
	if data.has("team_a_loadout"):
		team_a_loadout = data.team_a_loadout
	if data.has("team_b_loadout"):
		team_b_loadout = data.team_b_loadout
	if data.has("enable_detailed_logging"):
		enable_detailed_logging = data.enable_detailed_logging
	if data.has("collect_heatmap_data"):
		collect_heatmap_data = data.collect_heatmap_data
	if data.has("report_formats"):
		report_formats = PackedStringArray(data.report_formats)
	if data.has("balance_targets"):
		balance_targets = data.balance_targets
	if data.has("bot_difficulty"):
		bot_difficulty = data.bot_difficulty
	if data.has("simulation_speed"):
		simulation_speed = data.simulation_speed
	
	return self
