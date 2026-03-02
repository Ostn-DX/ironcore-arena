class_name BattleMetrics extends RefCounted

## Collects and aggregates battle statistics for balance analysis.
## This class tracks all combat events, movement patterns, and performance
## metrics during a single match or across multiple matches.
##
## @tutorial: Create instance at match start, call record_event() for each event,
##            then call finalize() at match end to get summary statistics.

const MAX_TTK_BUCKETS: int = 50
## Maximum number of buckets for TTK histogram

const TICKS_PER_SECOND: int = 60
## Simulation tick rate for time calculations

# Event storage
var damage_events: Array[Dictionary] = []
## Raw damage event data

var kill_events: Array[Dictionary] = []
## Raw kill event data

var shot_events: Array[Dictionary] = []
## Raw shot fired event data

var movement_events: Array[Dictionary] = []
## Raw movement event data

var credit_events: Array[Dictionary] = []
## Raw credit earning/spending events

var ability_events: Array[Dictionary] = []
## Raw ability usage events

# Time tracking
var match_start_time: int = 0
## Match start time in milliseconds

var match_end_time: int = 0
## Match end time in milliseconds

# Per-bot tracking
var movement_time: Dictionary = {}
## bot_id -> ticks spent moving

var idle_time: Dictionary = {}
## bot_id -> ticks spent idle

var combat_time: Dictionary = {}
## bot_id -> ticks in combat

var position_history: Dictionary = {}
## bot_id -> Array of positions for heatmap

# Aggregates
var total_damage_dealt: Dictionary = {}
## weapon_id -> total damage

var total_damage_taken: Dictionary = {}
## bot_id -> total damage taken

var total_shots_fired: Dictionary = {}
## weapon_id -> count

var total_hits: Dictionary = {}
## weapon_id -> count

var ttk_values: Array[float] = []
## Time-to-kill values for each kill (seconds)

var credits_earned: Dictionary = {}
## bot_id -> total credits earned

var credits_spent: Dictionary = {}
## bot_id -> total credits spent

var abilities_used: Dictionary = {}
## ability_id -> usage count

var weapon_kills: Dictionary = {}
## weapon_id -> kill count

var bot_kills: Dictionary = {}
## bot_id -> kill count

var bot_deaths: Dictionary = {}
## bot_id -> death count

var damage_by_distance: Dictionary = {}
## distance_range -> total damage

# Computed statistics (populated by finalize)
var _finalized: bool = false
## Whether finalize() has been called

var _summary_cache: Dictionary = {}
## Cached summary from finalize()


## Records a battle event.
##
## @param evt: Event dictionary with at least a "type" key.
##             Supported types: "damage", "kill", "shot_fired", "movement",
##             "credit", "ability", "death"
## @example:
##     metrics.record_event({
##         "type": "damage",
##         "weapon_id": "laser_rifle",
##         "attacker_id": "bot_1",
##         "target_id": "bot_2",
##         "damage": 15.0,
##         "tick": 120
##     })
func record_event(evt: Dictionary) -> void:
	if _finalized:
		push_warning("BattleMetrics: Recording event after finalize() called")
	
	var event_type: String = evt.get("type", "")
	
	match event_type:
		"damage":
			damage_events.append(evt)
			_aggregate_damage(evt)
		"kill":
			kill_events.append(evt)
			_aggregate_kill(evt)
		"death":
			_aggregate_death(evt)
		"shot_fired":
			shot_events.append(evt)
			_aggregate_shot(evt)
		"movement":
			movement_events.append(evt)
			_aggregate_movement(evt)
		"credit":
			credit_events.append(evt)
			_aggregate_credit(evt)
		"ability":
			ability_events.append(evt)
			_aggregate_ability(evt)
		_:
			push_warning("BattleMetrics: Unknown event type: %s" % event_type)


## Finalizes metrics and returns a summary dictionary.
## This should be called once at the end of a match.
##
## @return: Dictionary containing all aggregated statistics
## @example:
##     var summary = metrics.finalize()
##     print("Average TTK: ", summary.ttk_distribution.mean)
func finalize() -> Dictionary:
	if _finalized:
		return _summary_cache
	
	_finalized = true
	
	_summary_cache = {
		"damage_stats": _compute_damage_stats(),
		"hit_rates": _compute_hit_rates(),
		"ttk_distribution": _compute_ttk_distribution(),
		"movement_stats": _compute_movement_stats(),
		"win_stats": _compute_win_stats(),
		"economy_stats": _compute_economy_stats(),
		"weapon_stats": _compute_weapon_stats(),
		"bot_stats": _compute_bot_stats(),
		"engagement_stats": _compute_engagement_stats(),
		"match_duration_ticks": _get_match_duration_ticks(),
		"match_duration_seconds": _get_match_duration_seconds(),
		"total_events": _get_total_event_count()
	}
	
	return _summary_cache


## Aggregates a damage event.
##
## @param evt: Damage event dictionary
func _aggregate_damage(evt: Dictionary) -> void:
	var weapon: String = evt.get("weapon_id", "unknown")
	var damage: float = evt.get("damage", 0.0)
	var attacker: String = evt.get("attacker_id", "unknown")
	var target: String = evt.get("target_id", "unknown")
	var distance: float = evt.get("distance", 0.0)
	
	# Track damage by weapon
	if not total_damage_dealt.has(weapon):
		total_damage_dealt[weapon] = 0.0
	total_damage_dealt[weapon] += damage
	
	# Track damage taken by bot
	if not total_damage_taken.has(target):
		total_damage_taken[target] = 0.0
	total_damage_taken[target] += damage
	
	# Track damage by distance ranges
	var dist_range: String = _get_distance_range(distance)
	if not damage_by_distance.has(dist_range):
		damage_by_distance[dist_range] = 0.0
	damage_by_distance[dist_range] += damage


## Aggregates a kill event.
##
## @param evt: Kill event dictionary
func _aggregate_kill(evt: Dictionary) -> void:
	var ttk: float = evt.get("time_to_kill", 0.0)
	var weapon: String = evt.get("weapon_id", "unknown")
	var killer: String = evt.get("killer_id", "unknown")
	
	if ttk > 0:
		ttk_values.append(ttk)
	
	# Track kills by weapon
	if not weapon_kills.has(weapon):
		weapon_kills[weapon] = 0
	weapon_kills[weapon] += 1
	
	# Track kills by bot
	if not bot_kills.has(killer):
		bot_kills[killer] = 0
	bot_kills[killer] += 1


## Aggregates a death event.
##
## @param evt: Death event dictionary
func _aggregate_death(evt: Dictionary) -> void:
	var victim: String = evt.get("victim_id", "unknown")
	
	if not bot_deaths.has(victim):
		bot_deaths[victim] = 0
	bot_deaths[victim] += 1


## Aggregates a shot fired event.
##
## @param evt: Shot event dictionary
func _aggregate_shot(evt: Dictionary) -> void:
	var weapon: String = evt.get("weapon_id", "unknown")
	var hit: bool = evt.get("hit", false)
	
	if not total_shots_fired.has(weapon):
		total_shots_fired[weapon] = 0
	total_shots_fired[weapon] += 1
	
	if hit:
		if not total_hits.has(weapon):
			total_hits[weapon] = 0
		total_hits[weapon] += 1


## Aggregates a movement event.
##
## @param evt: Movement event dictionary
func _aggregate_movement(evt: Dictionary) -> void:
	var bot_id: String = evt.get("bot_id", "unknown")
	var tick: int = evt.get("tick", 0)
	
	if not movement_time.has(bot_id):
		movement_time[bot_id] = 0
	movement_time[bot_id] += 1
	
	# Track position for heatmap
	if not position_history.has(bot_id):
		position_history[bot_id] = []
	position_history[bot_id].append({
		"tick": tick,
		"position": evt.get("position", Vector3.ZERO)
	})


## Aggregates a credit event.
##
## @param evt: Credit event dictionary
func _aggregate_credit(evt: Dictionary) -> void:
	var bot_id: String = evt.get("bot_id", "unknown")
	var amount: float = evt.get("amount", 0.0)
	var is_earned: bool = evt.get("earned", true)
	
	if is_earned:
		if not credits_earned.has(bot_id):
			credits_earned[bot_id] = 0.0
		credits_earned[bot_id] += amount
	else:
		if not credits_spent.has(bot_id):
			credits_spent[bot_id] = 0.0
		credits_spent[bot_id] += amount


## Aggregates an ability event.
##
## @param evt: Ability event dictionary
func _aggregate_ability(evt: Dictionary) -> void:
	var ability_id: String = evt.get("ability_id", "unknown")
	
	if not abilities_used.has(ability_id):
		abilities_used[ability_id] = 0
	abilities_used[ability_id] += 1


## Computes damage statistics.
##
## @return: Dictionary with damage stats per weapon
func _compute_damage_stats() -> Dictionary:
	var stats := {}
	
	for weapon in total_damage_dealt.keys():
		var total: float = total_damage_dealt[weapon]
		var dps: float = _compute_dps(weapon)
		var kills: int = weapon_kills.get(weapon, 0)
		
		stats[weapon] = {
			"total_damage": total,
			"dps": dps,
			"kills": kills,
			"damage_per_kill": total / kills if kills > 0 else 0.0
		}
	
	return stats


## Computes hit rates for all weapons.
##
## @return: Dictionary with hit rate per weapon
func _compute_hit_rates() -> Dictionary:
	var rates := {}
	
	for weapon in total_shots_fired.keys():
		var shots: int = total_shots_fired.get(weapon, 0)
		var hits: int = total_hits.get(weapon, 0)
		rates[weapon] = {
			"hit_rate": float(hits) / float(shots) if shots > 0 else 0.0,
			"shots_fired": shots,
			"shots_hit": hits,
			"shots_missed": shots - hits
		}
	
	return rates


## Computes DPS for a weapon.
##
## @param weapon: Weapon ID
## @return: Calculated DPS value
func _compute_dps(weapon: String) -> float:
	var total_damage: float = total_damage_dealt.get(weapon, 0.0)
	var match_duration: float = _get_match_duration_seconds()
	
	if match_duration <= 0:
		return 0.0
	
	return total_damage / match_duration


## Computes TTK (Time To Kill) distribution statistics.
##
## @return: Dictionary with TTK statistics
func _compute_ttk_distribution() -> Dictionary:
	if ttk_values.is_empty():
		return {
			"mean": 0.0,
			"median": 0.0,
			"min": 0.0,
			"max": 0.0,
			"std": 0.0,
			"count": 0,
			"histogram": {}
		}
	
	var sorted := ttk_values.duplicate()
	sorted.sort()
	
	var sum: float = 0.0
	for v in sorted:
		sum += v
	
	var mean: float = sum / sorted.size()
	var median: float = sorted[sorted.size() / 2]
	var min_val: float = sorted[0]
	var max_val: float = sorted[sorted.size() - 1]
	
	# Calculate standard deviation
	var variance_sum: float = 0.0
	for v in sorted:
		variance_sum += pow(v - mean, 2)
	var std: float = sqrt(variance_sum / sorted.size())
	
	# Build histogram
	var histogram := _build_ttk_histogram(sorted)
	
	return {
		"mean": mean,
		"median": median,
		"min": min_val,
		"max": max_val,
		"std": std,
		"count": sorted.size(),
		"histogram": histogram
	}


## Builds TTK histogram.
##
## @param sorted_values: Sorted array of TTK values
## @return: Dictionary with bucketed counts
func _build_ttk_histogram(sorted_values: Array[float]) -> Dictionary:
	if sorted_values.is_empty():
		return {}
	
	var min_val: float = sorted_values[0]
	var max_val: float = sorted_values[sorted_values.size() - 1]
	var range_val: float = max_val - min_val
	
	if range_val <= 0:
		return {"0-1": sorted_values.size()}
	
	var bucket_size: float = range_val / MAX_TTK_BUCKETS
	var histogram := {}
	
	for val in sorted_values:
		var bucket: int = int((val - min_val) / bucket_size)
		bucket = clampi(bucket, 0, MAX_TTK_BUCKETS - 1)
		var bucket_key: String = "%.1f-%.1f" % [min_val + bucket * bucket_size, min_val + (bucket + 1) * bucket_size]
		
		if not histogram.has(bucket_key):
			histogram[bucket_key] = 0
		histogram[bucket_key] += 1
	
	return histogram


## Computes movement statistics.
##
## @return: Dictionary with movement stats
func _compute_movement_stats() -> Dictionary:
	var total_movement_ticks: int = 0
	var total_idle_ticks: int = 0
	var bot_count: int = 0
	
	for bot_id in movement_time.keys():
		total_movement_ticks += movement_time[bot_id]
		bot_count += 1
	
	for bot_id in idle_time.keys():
		total_idle_ticks += idle_time[bot_id]
	
	var match_duration: int = _get_match_duration_ticks()
	var total_bot_ticks: int = bot_count * match_duration if match_duration > 0 else 1
	
	return {
		"total_movement_ticks": total_movement_ticks,
		"total_idle_ticks": total_idle_ticks,
		"movement_percentage": float(total_movement_ticks) / total_bot_ticks * 100.0,
		"idle_percentage": float(total_idle_ticks) / total_bot_ticks * 100.0,
		"bots_tracked": bot_count
	}


## Computes win statistics.
##
## @return: Dictionary with win-related stats
func _compute_win_stats() -> Dictionary:
	var total_kills: int = kill_events.size()
	var total_deaths: int = bot_deaths.size()
	
	return {
		"total_kills": total_kills,
		"total_deaths": total_deaths,
		"kd_ratio": float(total_kills) / total_deaths if total_deaths > 0 else 0.0
	}


## Computes economy statistics.
##
## @return: Dictionary with economy stats
func _compute_economy_stats() -> Dictionary:
	var total_earned: float = 0.0
	var total_spent: float = 0.0
	var bot_count: int = 0
	
	for bot_id in credits_earned.keys():
		total_earned += credits_earned[bot_id]
		bot_count += 1
	
	for bot_id in credits_spent.keys():
		total_spent += credits_spent[bot_id]
	
	var match_duration_hours: float = _get_match_duration_seconds() / 3600.0
	
	return {
		"total_credits_earned": total_earned,
		"total_credits_spent": total_spent,
		"net_credits": total_earned - total_spent,
		"credits_per_hour": total_earned / match_duration_hours if match_duration_hours > 0 else 0.0,
		"credits_per_bot_per_hour": (total_earned / bot_count) / match_duration_hours if bot_count > 0 and match_duration_hours > 0 else 0.0,
		"bots_tracked": bot_count
	}


## Computes weapon statistics.
##
## @return: Dictionary with comprehensive weapon stats
func _compute_weapon_stats() -> Dictionary:
	var stats := {}
	
	for weapon in total_shots_fired.keys():
		var shots: int = total_shots_fired.get(weapon, 0)
		var hits: int = total_hits.get(weapon, 0)
		var damage: float = total_damage_dealt.get(weapon, 0.0)
		var kills: int = weapon_kills.get(weapon, 0)
		
		stats[weapon] = {
			"shots_fired": shots,
			"shots_hit": hits,
			"shots_missed": shots - hits,
			"hit_rate": float(hits) / shots if shots > 0 else 0.0,
			"total_damage": damage,
			"kills": kills,
			"damage_per_shot": damage / shots if shots > 0 else 0.0,
			"kills_per_shot": float(kills) / shots if shots > 0 else 0.0
		}
	
	return stats


## Computes per-bot statistics.
##
## @return: Dictionary with stats per bot
func _compute_bot_stats() -> Dictionary:
	var stats := {}
	
	# Collect all bot IDs
	var all_bots: Array[String] = []
	for bot_id in bot_kills.keys():
		if not bot_id in all_bots:
			all_bots.append(bot_id)
	for bot_id in bot_deaths.keys():
		if not bot_id in all_bots:
			all_bots.append(bot_id)
	
	for bot_id in all_bots:
		var kills: int = bot_kills.get(bot_id, 0)
		var deaths: int = bot_deaths.get(bot_id, 0)
		var damage_taken: float = total_damage_taken.get(bot_id, 0.0)
		var credits: float = credits_earned.get(bot_id, 0.0)
		var movement: int = movement_time.get(bot_id, 0)
		
		stats[bot_id] = {
			"kills": kills,
			"deaths": deaths,
			"kd_ratio": float(kills) / deaths if deaths > 0 else float(kills),
			"damage_taken": damage_taken,
			"credits_earned": credits,
			"movement_ticks": movement
		}
	
	return stats


## Computes engagement statistics.
##
## @return: Dictionary with engagement stats
func _compute_engagement_stats() -> Dictionary:
	return {
		"damage_by_distance": damage_by_distance,
		"abilities_used": abilities_used,
		"total_engagements": damage_events.size()
	}


## Gets the match duration in ticks.
##
## @return: Duration in simulation ticks
func _get_match_duration_ticks() -> int:
	if match_end_time > match_start_time:
		return int((match_end_time - match_start_time) / 1000.0 * TICKS_PER_SECOND)
	return 0


## Gets the match duration in seconds.
##
## @return: Duration in seconds
func _get_match_duration_seconds() -> float:
	return float(_get_match_duration_ticks()) / TICKS_PER_SECOND


## Gets total event count.
##
## @return: Total number of recorded events
func _get_total_event_count() -> int:
	return damage_events.size() + kill_events.size() + shot_events.size() + movement_events.size()


## Gets distance range string for bucketing.
##
## @param distance: Distance in units
## @return: Range string like "0-10" or "50-100"
func _get_distance_range(distance: float) -> String:
	if distance < 10:
		return "0-10"
	elif distance < 25:
		return "10-25"
	elif distance < 50:
		return "25-50"
	elif distance < 100:
		return "50-100"
	else:
		return "100+"


## Returns position history for heatmap generation.
##
## @return: Dictionary of bot_id -> position array
func get_position_history() -> Dictionary:
	return position_history


## Exports metrics to a dictionary format suitable for JSON serialization.
##
## @return: Complete metrics data as dictionary
func export_to_dictionary() -> Dictionary:
	if not _finalized:
		finalize()
	
	return {
		"summary": _summary_cache,
		"raw_events": {
			"damage_count": damage_events.size(),
			"kill_count": kill_events.size(),
			"shot_count": shot_events.size(),
			"movement_count": movement_events.size(),
			"credit_count": credit_events.size()
		},
		"aggregates": {
			"total_damage_dealt": total_damage_dealt,
			"total_shots_fired": total_shots_fired,
			"total_hits": total_hits,
			"weapon_kills": weapon_kills,
			"bot_kills": bot_kills,
			"bot_deaths": bot_deaths,
			"credits_earned": credits_earned,
			"abilities_used": abilities_used
		}
	}
