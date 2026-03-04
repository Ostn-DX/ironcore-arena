class_name BattleBatchResult extends RefCounted

## Results container for a batch of battle simulations.
## This class aggregates individual match results and computes
## summary statistics across the entire batch.
##
## @tutorial: Created by HeadlessBattleRunner, call finalize() when complete

var config: BattleBatchConfig = null
## The configuration used for this batch

var match_results: Array[Dictionary] = []
## Individual results from each match

var summary: Dictionary = {}
## Computed summary statistics (populated by finalize())

var start_time: int = 0
## Batch start time in milliseconds

var end_time: int = 0
## Batch end time in milliseconds

var metadata: Dictionary = {}
## Additional metadata about the batch run

# Internal computed values
var _finalized: bool = false
## Whether finalize() has been called

var _win_counts: Dictionary = {}
## Cached win counts per team

var _aggregated_metrics: Dictionary = {}
## Cached aggregated metrics


func _init() -> void:
	## Initializes the result with current timestamp.
	start_time = Time.get_ticks_msec()
	metadata = {
		"godot_version": Engine.get_version_info(),
		"run_date": Time.get_datetime_string_from_system(),
		"platform": OS.get_name()
	}


## Finalizes the batch results and computes summary statistics.
## This should be called once all matches are complete.
##
## @example:
##     result.finalize()
##     print("Win rate: ", result.get_win_rate(0))
func finalize() -> void:
	if _finalized:
		return
	
	end_time = Time.get_ticks_msec()
	_finalized = true
	
	_compute_summary()
	_compute_win_counts()
	_aggregated_metrics = _aggregate_all_metrics()


## Computes the main summary dictionary.
func _compute_summary() -> void:
	var duration_sec: float = get_duration_sec()
	var match_count: int = match_results.size()
	
	summary = {
		"total_matches": match_count,
		"duration_ms": end_time - start_time,
		"duration_seconds": duration_sec,
		"matches_per_second": match_count / duration_sec if duration_sec > 0 else 0.0,
		"win_rates": _compute_all_win_rates(),
		"aggregate_metrics": _aggregated_metrics,
		"match_outcomes": _summarize_outcomes(),
		"tier": config.tier if config else 0,
		"arena_id": config.arena_id if config else "unknown",
		"config_summary": _summarize_config()
	}


## Computes win counts for each team.
func _compute_win_counts() -> void:
	_win_counts = {0: 0, 1: 0, -1: 0}
	
	for match in match_results:
		var winner: int = match.get("winner_team", -1)
		if _win_counts.has(winner):
			_win_counts[winner] += 1


## Computes win rates for all teams.
##
## @return: Dictionary with win rates per team
func _compute_all_win_rates() -> Dictionary:
	var total: int = match_results.size()
	if total == 0:
		return {0: 0.0, 1: 0.0, "draw": 0.0}
	
	var team_a_wins: int = _win_counts.get(0, 0)
	var team_b_wins: int = _win_counts.get(1, 0)
	var draws: int = _win_counts.get(-1, 0)
	
	return {
		0: float(team_a_wins) / total,
		1: float(team_b_wins) / total,
		"draw": float(draws) / total
	}


## Summarizes match outcomes.
##
## @return: Dictionary with outcome breakdown
func _summarize_outcomes() -> Dictionary:
	var outcomes := {
		"elimination": 0,
		"timeout": 0,
		"draw": 0,
		"unknown": 0
	}
	
	for match in match_results:
		var reason: String = match.get("end_reason", "unknown")
		if outcomes.has(reason):
			outcomes[reason] += 1
		else:
			outcomes.unknown += 1
	
	return outcomes


## Summarizes the batch configuration.
##
## @return: Dictionary with key config values
func _summarize_config() -> Dictionary:
	if config == null:
		return {}
	
	return {
		"seeds_count": config.seeds.size(),
		"matches_per_seed": config.matches_per_seed,
		"bots_per_team": config.bots_per_team,
		"tier": config.tier,
		"arena_id": config.arena_id,
		"total_matches_expected": config.get_total_matches()
	}


## Aggregates metrics from all matches.
##
## @return: Dictionary with aggregated statistics
func _aggregate_all_metrics() -> Dictionary:
	if match_results.is_empty():
		return {}
	
	# Collect all TTK values
	var all_ttk: Array[float] = []
	var all_durations: Array[float] = []
	var damage_by_weapon: Dictionary = {}
	var shots_by_weapon: Dictionary = {}
	var hits_by_weapon: Dictionary = {}
	var kills_by_weapon: Dictionary = {}
	
	for match in match_results:
		# Collect duration
		all_durations.append(match.get("duration_seconds", 0.0))
		
		# Collect TTK values
		var metrics: Dictionary = match.get("metrics", {})
		var ttk_dist: Dictionary = metrics.get("ttk_distribution", {})
		
		# Aggregate weapon stats
		var weapon_stats: Dictionary = metrics.get("weapon_stats", {})
		for weapon in weapon_stats.keys():
			var stats: Dictionary = weapon_stats[weapon]
			
			if not damage_by_weapon.has(weapon):
				damage_by_weapon[weapon] = 0.0
				damage_by_weapon[weapon] += stats.get("total_damage", 0.0)
			
			if not shots_by_weapon.has(weapon):
				shots_by_weapon[weapon] = 0
			shots_by_weapon[weapon] += stats.get("shots_fired", 0)
			
			if not hits_by_weapon.has(weapon):
				hits_by_weapon[weapon] = 0
			hits_by_weapon[weapon] += stats.get("shots_hit", 0)
			
			if not kills_by_weapon.has(weapon):
				kills_by_weapon[weapon] = 0
			kills_by_weapon[weapon] += stats.get("kills", 0)
	
	# Compute averages
	var avg_duration: float = _compute_average(all_durations)
	
	# Compute hit rates
	var hit_rates: Dictionary = {}
	for weapon in shots_by_weapon.keys():
		var shots: int = shots_by_weapon.get(weapon, 0)
		var hits: int = hits_by_weapon.get(weapon, 0)
		hit_rates[weapon] = float(hits) / shots if shots > 0 else 0.0
	
	return {
		"average_match_duration": avg_duration,
		"ttk_stats": _aggregate_ttk_stats(),
		"weapon_aggregates": {
			"total_damage": damage_by_weapon,
			"total_shots": shots_by_weapon,
			"total_hits": hits_by_weapon,
			"total_kills": kills_by_weapon,
			"hit_rates": hit_rates
		},
		"economy_stats": _aggregate_economy_stats(),
		"bot_performance": _aggregate_bot_performance()
	}


## Aggregates TTK statistics across all matches.
##
## @return: Dictionary with combined TTK stats
func _aggregate_ttk_stats() -> Dictionary:
	var all_ttk: Array[float] = []
	
	for match in match_results:
		var metrics: Dictionary = match.get("metrics", {})
		var ttk_dist: Dictionary = metrics.get("ttk_distribution", {})
		
		# We only have summary stats per match, not individual values
		# So we accumulate what we can
		var mean_ttk: float = ttk_dist.get("mean", 0.0)
		if mean_ttk > 0:
			all_ttk.append(mean_ttk)
	
	if all_ttk.is_empty():
		return {"mean": 0.0, "median": 0.0, "min": 0.0, "max": 0.0}
	
	all_ttk.sort()
	var sum: float = 0.0
	for v in all_ttk:
		sum += v
	
	return {
		"mean": sum / all_ttk.size(),
		"median": all_ttk[all_ttk.size() / 2],
		"min": all_ttk[0],
		"max": all_ttk[all_ttk.size() - 1],
		"sample_count": all_ttk.size()
	}


## Aggregates economy statistics.
##
## @return: Dictionary with economy aggregates
func _aggregate_economy_stats() -> Dictionary:
	var total_credits: float = 0.0
	var match_count: int = 0
	
	for match in match_results:
		var metrics: Dictionary = match.get("metrics", {})
		var econ: Dictionary = metrics.get("economy_stats", {})
		total_credits += econ.get("total_credits_earned", 0.0)
		match_count += 1
	
	var total_hours: float = 0.0
	for match in match_results:
		total_hours += match.get("duration_seconds", 0.0) / 3600.0
	
	return {
		"total_credits_earned": total_credits,
		"average_credits_per_match": total_credits / match_count if match_count > 0 else 0.0,
		"credits_per_hour": total_credits / total_hours if total_hours > 0 else 0.0
	}


## Aggregates bot performance statistics.
##
## @return: Dictionary with performance aggregates
func _aggregate_bot_performance() -> Dictionary:
	var all_kd_ratios: Array[float] = []
	var total_kills: int = 0
	var total_deaths: int = 0
	
	for match in match_results:
		var metrics: Dictionary = match.get("metrics", {})
		var bot_stats: Dictionary = metrics.get("bot_stats", {})
		var win_stats: Dictionary = metrics.get("win_stats", {})
		
		total_kills += win_stats.get("total_kills", 0)
		total_deaths += win_stats.get("total_deaths", 0)
		
		for bot_id in bot_stats.keys():
			var stats: Dictionary = bot_stats[bot_id]
			var kd: float = stats.get("kd_ratio", 0.0)
			if kd > 0:
				all_kd_ratios.append(kd)
	
	return {
		"average_kd_ratio": _compute_average(all_kd_ratios),
		"total_kills": total_kills,
		"total_deaths": total_deaths,
		"global_kd_ratio": float(total_kills) / total_deaths if total_deaths > 0 else 0.0
	}


## Computes average of an array.
##
## @param values: Array of float values
## @return: Average value
func _compute_average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	
	var sum: float = 0.0
	for v in values:
		sum += v
	
	return sum / values.size()


## Gets the win rate for a specific team.
##
## @param team_id: The team ID (0 or 1)
## @return: Win rate as a float (0.0 to 1.0)
## @example:
##     var team_a_win_rate = result.get_win_rate(0)
##     var team_b_win_rate = result.get_win_rate(1)
func get_win_rate(team_id: int) -> float:
	if not _finalized:
		finalize()
	
	var total: int = match_results.size()
	if total == 0:
		return 0.0
	
	var wins: int = _win_counts.get(team_id, 0)
	return float(wins) / total


## Gets the draw rate.
##
## @return: Draw rate as a float (0.0 to 1.0)
func get_draw_rate() -> float:
	return get_win_rate(-1)


## Gets the batch duration in seconds.
##
## @return: Duration in seconds
func get_duration_sec() -> float:
	return (end_time - start_time) / 1000.0


## Gets the average match duration.
##
## @return: Average duration in seconds
func get_average_match_duration() -> float:
	if match_results.is_empty():
		return 0.0
	
	var total: float = 0.0
	for match in match_results:
		total += match.get("duration_seconds", 0.0)
	
	return total / match_results.size()


## Gets the median TTK across all matches.
##
## @return: Median time-to-kill in seconds
func get_median_ttk() -> float:
	if not _finalized:
		finalize()
	
	var ttk_stats: Dictionary = _aggregated_metrics.get("ttk_stats", {})
	return ttk_stats.get("median", 0.0)


## Gets the credits per hour rate.
##
## @return: Average credits earned per hour
func get_credits_per_hour() -> float:
	if not _finalized:
		finalize()
	
	var econ_stats: Dictionary = _aggregated_metrics.get("economy_stats", {})
	return econ_stats.get("credits_per_hour", 0.0)


## Checks if the results indicate balanced gameplay.
##
## @param tolerance: Acceptable deviation from perfect balance (default 0.1 = 10%)
## @return: Dictionary with "balanced" boolean and "issues" array
func check_balance(tolerance: float = 0.1) -> Dictionary:
	if not _finalized:
		finalize()
	
	var issues: Array[String] = []
	
	# Check win rate balance
	var team_a_wr: float = get_win_rate(0)
	var team_b_wr: float = get_win_rate(1)
	var target_wr: float = 0.5
	
	if abs(team_a_wr - target_wr) > tolerance:
		issues.append("Team A win rate (%.2f) deviates from target (%.2f)" % [team_a_wr, target_wr])
	
	if abs(team_b_wr - target_wr) > tolerance:
		issues.append("Team B win rate (%.2f) deviates from target (%.2f)" % [team_b_wr, target_wr])
	
	# Check for excessive timeouts
	var outcomes: Dictionary = summary.get("match_outcomes", {})
	var timeout_rate: float = float(outcomes.get("timeout", 0)) / match_results.size() if match_results.size() > 0 else 0.0
	
	if timeout_rate > 0.2:
		issues.append("High timeout rate (%.1f%%) - matches may be too long" % (timeout_rate * 100))
	
	return {
		"balanced": issues.is_empty(),
		"issues": issues,
		"team_a_win_rate": team_a_wr,
		"team_b_win_rate": team_b_wr,
		"timeout_rate": timeout_rate
	}


## Exports results to a dictionary suitable for JSON serialization.
##
## @return: Complete results data
func export_to_dictionary() -> Dictionary:
	if not _finalized:
		finalize()
	
	return {
		"config": config.to_dictionary() if config else {},
		"summary": summary,
		"match_results": match_results,
		"metadata": metadata,
		"timing": {
			"start_time": start_time,
			"end_time": end_time,
			"duration_ms": end_time - start_time
		}
	}


## Gets match results filtered by a condition.
##
## @param filter_func: Callable that takes a match dictionary and returns bool
## @return: Filtered array of match results
func get_filtered_matches(filter_func: Callable) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for match in match_results:
		if filter_func.call(match):
			filtered.append(match)
	return filtered


## Gets matches that ended with a specific reason.
##
## @param reason: End reason string ("elimination", "timeout", "draw")
## @return: Array of matching match results
func get_matches_by_end_reason(reason: String) -> Array[Dictionary]:
	return get_filtered_matches(func(m): return m.get("end_reason", "") == reason)


## Gets matches won by a specific team.
##
## @param team_id: The winning team ID
## @return: Array of matching match results
func get_matches_won_by(team_id: int) -> Array[Dictionary]:
	return get_filtered_matches(func(m): return m.get("winner_team", -2) == team_id)
