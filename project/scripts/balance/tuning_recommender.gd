class_name TuningRecommender extends RefCounted

## Generates tuning recommendations based on balance data analysis.
## This class analyzes batch results and produces actionable
## recommendations for game balance adjustments.
##
## @tutorial: Create instance, call generate_recommendations() with BattleBatchResult

# Threshold constants for analysis
const DPS_Z_THRESHOLD: float = 2.0
## Z-score threshold for DPS outliers (2.0 = 95% confidence)

const HIT_RATE_Z_THRESHOLD: float = 1.5
## Z-score threshold for hit rate outliers

const WIN_RATE_TARGET: float = 0.5
## Target win rate for balanced gameplay

const WIN_RATE_TOLERANCE: float = 0.1
## Acceptable deviation from target win rate

const TTK_TARGET: float = 15.0
## Target time-to-kill in seconds

const TTK_TOLERANCE: float = 5.0
## Acceptable deviation from target TTK

const CREDITS_PER_HOUR_TARGET: float = 5000.0
## Target credits per hour

const CREDITS_PER_HOUR_TOLERANCE: float = 1000.0
## Acceptable deviation from target credits/hour

const MIN_SAMPLE_SIZE: int = 100
## Minimum sample size for reliable recommendations

const MAX_RECOMMENDATIONS: int = 20
## Maximum number of recommendations to generate

# Analysis state
var _recommendations: Array[TuningRecommendation] = []
## Generated recommendations

var _analysis_notes: Array[String] = []
## Notes from analysis process


## Generates all recommendations from batch results.
##
## @param results: BattleBatchResult containing simulation data
## @return: Array of TuningRecommendation objects
## @example:
##     var recommender = TuningRecommender.new()
##     var recs = recommender.generate_recommendations(batch_result)
##     for rec in recs:
##         print(rec.get_summary())
func generate_recommendations(results: BattleBatchResult) -> Array[TuningRecommendation]:
	_recommendations.clear()
	_analysis_notes.clear()
	
	if results == null or results.match_results.is_empty():
		_analysis_notes.append("No match results available for analysis")
		return _recommendations
	
	if results.match_results.size() < MIN_SAMPLE_SIZE:
		_analysis_notes.append("Warning: Sample size (%d) below minimum (%d)" % [results.match_results.size(), MIN_SAMPLE_SIZE])
	
	_recommendations.append_array(_analyze_weapon_balance(results))
	_recommendations.append_array(_analyze_chassis_balance(results))
	_recommendations.append_array(_analyze_economy_balance(results))
	_recommendations.append_array(_analyze_win_rate_balance(results))
	_recommendations.append_array(_analyze_ttk_balance(results))
	
	# Sort by priority
	_recommendations.sort_custom(TuningRecommendation.sort_by_priority)
	
	# Limit number of recommendations
	if _recommendations.size() > MAX_RECOMMENDATIONS:
		_analysis_notes.append("Truncated recommendations from %d to %d" % [_recommendations.size(), MAX_RECOMMENDATIONS])
		_recommendations.resize(MAX_RECOMMENDATIONS)
	
	return _recommendations


## Analyzes weapon balance and generates recommendations.
##
## @param results: BattleBatchResult containing weapon data
## @return: Array of weapon-related recommendations
func _analyze_weapon_balance(results: BattleBatchResult) -> Array[TuningRecommendation]:
	var recs: Array[TuningRecommendation] = []
	
	if results.summary.is_empty():
		return recs
	
	var aggregates: Dictionary = results.summary.get("aggregate_metrics", {})
	var weapon_data: Dictionary = aggregates.get("weapon_aggregates", {})
	
	var damage_data: Dictionary = weapon_data.get("total_damage", {})
	var shots_data: Dictionary = weapon_data.get("total_shots", {})
	var hits_data: Dictionary = weapon_data.get("total_hits", {})
	var kills_data: Dictionary = weapon_data.get("total_kills", {})
	var hit_rates: Dictionary = weapon_data.get("hit_rates", {})
	
	# Compute DPS statistics
	var dps_data := _compute_dps_per_weapon(damage_data, results)
	var dps_stats := _compute_statistics_dict(dps_data)
	
	# Find DPS outliers
	for weapon_id in dps_data.keys():
		var dps: float = dps_data[weapon_id]
		var z_score: float = _compute_z_score(dps, dps_stats.mean, dps_stats.std)
		
		if abs(z_score) > DPS_Z_THRESHOLD:
			var rec := TuningRecommendation.new()
			rec.target_id = weapon_id
			rec.target_type = "weapon"
			rec.target_property = "damage_per_second"
			rec.current_value = dps
			rec.data_source = "dps_analysis"
			rec.sample_size = shots_data.get(weapon_id, 0)
			
			if z_score > 0:
				# DPS too high - nerf
				rec.proposed_value = dps_stats.mean + DPS_Z_THRESHOLD * dps_stats.std * 0.5
				rec.compute_change()
				rec.rationale = "DPS (%.1f) is %.1f std above mean (z=%.2f). Overperforming compared to other weapons." % [dps, z_score, z_score]
				rec.predicted_effect = "Reduce overperformance to bring in line with other weapons. Expected win rate normalization."
			else:
				# DPS too low - buff
				rec.proposed_value = dps_stats.mean - DPS_Z_THRESHOLD * dps_stats.std * 0.5
				rec.compute_change()
				rec.rationale = "DPS (%.1f) is %.1f std below mean (z=%.2f). Underperforming compared to other weapons." % [dps, abs(z_score), z_score]
				rec.predicted_effect = "Increase effectiveness to match other weapons. Expected usage rate increase."
			
			rec.confidence = clampf(abs(z_score) / 3.0, 0.0, 1.0)
			rec.priority = 2 if abs(z_score) > 2.5 else 3
			recs.append(rec)
	
	# Analyze hit rates
	var hit_rate_stats := _compute_statistics_dict(hit_rates)
	for weapon_id in hit_rates.keys():
		var hit_rate: float = hit_rates[weapon_id]
		var z_score: float = _compute_z_score(hit_rate, hit_rate_stats.mean, hit_rate_stats.std)
		
		if abs(z_score) > HIT_RATE_Z_THRESHOLD:
			var rec := TuningRecommendation.new()
			rec.target_id = weapon_id
			rec.target_type = "weapon"
			rec.target_property = "accuracy"
			rec.current_value = hit_rate
			rec.data_source = "hit_rate_analysis"
			rec.sample_size = shots_data.get(weapon_id, 0)
			
			if z_score > 0:
				rec.proposed_value = hit_rate_stats.mean + HIT_RATE_Z_THRESHOLD * hit_rate_stats.std * 0.3
				rec.compute_change()
				rec.rationale = "Hit rate (%.1f%%) is %.1f std above average (z=%.2f). May be too easy to use." % [hit_rate * 100, z_score, z_score]
				rec.predicted_effect = "Slight accuracy reduction to increase skill requirement."
			else:
				rec.proposed_value = hit_rate_stats.mean - HIT_RATE_Z_THRESHOLD * hit_rate_stats.std * 0.3
				rec.compute_change()
				rec.rationale = "Hit rate (%.1f%%) is %.1f std below average (z=%.2f). May be too difficult to use." % [hit_rate * 100, abs(z_score), z_score]
				rec.predicted_effect = "Slight accuracy improvement to improve usability."
			
			rec.confidence = clampf(abs(z_score) / 2.5, 0.0, 1.0)
			rec.priority = 4  # Lower priority than DPS
			recs.append(rec)
	
	return recs


## Analyzes chassis balance and generates recommendations.
##
## @param results: BattleBatchResult containing chassis data
## @return: Array of chassis-related recommendations
func _analyze_chassis_balance(results: BattleBatchResult) -> Array[TuningRecommendation]:
	var recs: Array[TuningRecommendation] = []
	
	# Extract chassis data from bot stats
	var chassis_performance: Dictionary = {}
	
	for match in results.match_results:
		var metrics: Dictionary = match.get("metrics", {})
		var bot_stats: Dictionary = metrics.get("bot_stats", {})
		
		for bot_id in bot_stats.keys():
			var stats: Dictionary = bot_stats[bot_id]
			var chassis_id: String = _extract_chassis_from_bot_id(bot_id)
			
			if not chassis_performance.has(chassis_id):
				chassis_performance[chassis_id] = {
					"kd_ratios": [],
					"damage_taken": [],
					"kills": [],
					"deaths": []
				}
			
			chassis_performance[chassis_id].kd_ratios.append(stats.get("kd_ratio", 0.0))
			chassis_performance[chassis_id].damage_taken.append(stats.get("damage_taken", 0.0))
			chassis_performance[chassis_id].kills.append(stats.get("kills", 0))
			chassis_performance[chassis_id].deaths.append(stats.get("deaths", 0))
	
	# Compute average performance per chassis
	var avg_kd: Dictionary = {}
	for chassis_id in chassis_performance.keys():
		var data: Dictionary = chassis_performance[chassis_id]
		avg_kd[chassis_id] = _average(data.kd_ratios)
	
	# Find outliers
	var kd_stats := _compute_statistics_dict(avg_kd)
	for chassis_id in avg_kd.keys():
		var kd: float = avg_kd[chassis_id]
		var z_score: float = _compute_z_score(kd, kd_stats.mean, kd_stats.std)
		
		if abs(z_score) > DPS_Z_THRESHOLD:
			var rec := TuningRecommendation.new()
			rec.target_id = chassis_id
			rec.target_type = "chassis"
			rec.target_property = "survivability"
			rec.current_value = kd
			rec.data_source = "kd_analysis"
			
			if z_score > 0:
				rec.proposed_value = kd_stats.mean + DPS_Z_THRESHOLD * kd_stats.std * 0.5
				rec.compute_change()
				rec.rationale = "K/D ratio (%.2f) is %.1f std above average (z=%.2f). Chassis may be too durable." % [kd, z_score, z_score]
				rec.predicted_effect = "Reduce durability to balance with other chassis options."
			else:
				rec.proposed_value = kd_stats.mean - DPS_Z_THRESHOLD * kd_stats.std * 0.5
				rec.compute_change()
				rec.rationale = "K/D ratio (%.2f) is %.1f std below average (z=%.2f). Chassis may be too fragile." % [kd, abs(z_score), z_score]
				rec.predicted_effect = "Increase durability to improve viability."
			
			rec.confidence = clampf(abs(z_score) / 3.0, 0.0, 1.0)
			rec.priority = 2
			recs.append(rec)
	
	return recs


## Analyzes economy balance and generates recommendations.
##
## @param results: BattleBatchResult containing economy data
## @return: Array of economy-related recommendations
func _analyze_economy_balance(results: BattleBatchResult) -> Array[TuningRecommendation]:
	var recs: Array[TuningRecommendation] = []
	
	var cph: float = results.get_credits_per_hour()
	
	if cph == 0:
		return recs
	
	var deviation: float = abs(cph - CREDITS_PER_HOUR_TARGET)
	var deviation_percent: float = (deviation / CREDITS_PER_HOUR_TARGET) * 100.0
	
	if deviation > CREDITS_PER_HOUR_TOLERANCE:
		var rec := TuningRecommendation.new()
		rec.target_id = "credit_system"
		rec.target_type = "economy"
		rec.target_property = "credits_per_hour"
		rec.current_value = cph
		rec.proposed_value = CREDITS_PER_HOUR_TARGET
		rec.compute_change()
		rec.data_source = "economy_analysis"
		rec.sample_size = results.match_results.size()
		
		if cph > CREDITS_PER_HOUR_TARGET:
			rec.rationale = "Credits/hour (%.0f) exceeds target (%.0f) by %.1f%%. Economy may be too generous." % [cph, CREDITS_PER_HOUR_TARGET, deviation_percent]
			rec.predicted_effect = "Reduce credit rewards to slow progression and extend play time."
		else:
			rec.rationale = "Credits/hour (%.0f) below target (%.0f) by %.1f%%. Economy may be too stingy." % [cph, CREDITS_PER_HOUR_TARGET, deviation_percent]
			rec.predicted_effect = "Increase credit rewards to improve player satisfaction."
		
		rec.confidence = clampf(deviation_percent / 50.0, 0.0, 1.0)
		rec.priority = 3
		recs.append(rec)
	
	return recs


## Analyzes win rate balance and generates recommendations.
##
## @param results: BattleBatchResult containing win rate data
## @return: Array of win rate related recommendations
func _analyze_win_rate_balance(results: BattleBatchResult) -> Array[TuningRecommendation]:
	var recs: Array[TuningRecommendation] = []
	
	var team_a_wr: float = results.get_win_rate(0)
	var team_b_wr: float = results.get_win_rate(1)
	
	var deviation_a: float = abs(team_a_wr - WIN_RATE_TARGET)
	var deviation_b: float = abs(team_b_wr - WIN_RATE_TARGET)
	
	if deviation_a > WIN_RATE_TOLERANCE:
		var rec := TuningRecommendation.new()
		rec.target_id = "team_a"
		rec.target_type = "general"
		rec.target_property = "win_rate"
		rec.current_value = team_a_wr
		rec.proposed_value = WIN_RATE_TARGET
		rec.change_percent = (WIN_RATE_TARGET - team_a_wr) * 100.0
		rec.change_absolute = WIN_RATE_TARGET - team_a_wr
		rec.data_source = "win_rate_analysis"
		rec.sample_size = results.match_results.size()
		
		if team_a_wr > WIN_RATE_TARGET:
			rec.rationale = "Team A win rate (%.1f%%) above target (%.1f%%). Team may have unfair advantage." % [team_a_wr * 100, WIN_RATE_TARGET * 100]
			rec.predicted_effect = "Investigate Team A loadout advantages."
		else:
			rec.rationale = "Team A win rate (%.1f%%) below target (%.1f%%). Team may be at unfair disadvantage." % [team_a_wr * 100, WIN_RATE_TARGET * 100]
			rec.predicted_effect = "Investigate Team A loadout disadvantages."
		
		rec.confidence = clampf(deviation_a / 0.2, 0.0, 1.0)
		rec.priority = 1  # High priority
		recs.append(rec)
	
	return recs


## Analyzes TTK balance and generates recommendations.
##
## @param results: BattleBatchResult containing TTK data
## @return: Array of TTK related recommendations
func _analyze_ttk_balance(results: BattleBatchResult) -> Array[TuningRecommendation]:
	var recs: Array[TuningRecommendation] = []
	
	var median_ttk: float = results.get_median_ttk()
	
	if median_ttk == 0:
		return recs
	
	var deviation: float = abs(median_ttk - TTK_TARGET)
	
	if deviation > TTK_TOLERANCE:
		var rec := TuningRecommendation.new()
		rec.target_id = "combat_system"
		rec.target_type = "general"
		rec.target_property = "time_to_kill"
		rec.current_value = median_ttk
		rec.proposed_value = TTK_TARGET
		rec.compute_change()
		rec.data_source = "ttk_analysis"
		rec.sample_size = results.match_results.size()
		
		if median_ttk < TTK_TARGET:
			rec.rationale = "Median TTK (%.1fs) below target (%.1fs). Combat may be too fast, reducing tactical depth." % [median_ttk, TTK_TARGET]
			rec.predicted_effect = "Increase TTK to allow more counterplay and strategic decisions."
		else:
			rec.rationale = "Median TTK (%.1fs) above target (%.1fs). Combat may be too slow, reducing excitement." % [median_ttk, TTK_TARGET]
			rec.predicted_effect = "Decrease TTK to increase combat intensity."
		
		rec.confidence = clampf(deviation / 10.0, 0.0, 1.0)
		rec.priority = 2
		recs.append(rec)
	
	return recs


## Computes DPS for each weapon.
##
## @param damage_data: Dictionary of weapon_id -> total damage
## @param results: BattleBatchResult for duration
## @return: Dictionary of weapon_id -> DPS
func _compute_dps_per_weapon(damage_data: Dictionary, results: BattleBatchResult) -> Dictionary:
	var dps_data: Dictionary = {}
	var total_seconds: float = results.get_duration_sec()
	
	if total_seconds <= 0:
		return dps_data
	
	for weapon_id in damage_data.keys():
		dps_data[weapon_id] = damage_data[weapon_id] / total_seconds
	
	return dps_data


## Computes statistics for a dictionary of float values.
##
## @param data: Dictionary with float values
## @return: Dictionary with mean, std, min, max
func _compute_statistics_dict(data: Dictionary) -> Dictionary:
	var values: Array = data.values()
	return _compute_statistics_array(values)


## Computes statistics for an array of float values.
##
## @param values: Array of float values
## @return: Dictionary with mean, std, min, max
func _compute_statistics_array(values: Array) -> Dictionary:
	if values.is_empty():
		return {"mean": 0.0, "std": 0.0, "min": 0.0, "max": 0.0}
	
	var sum: float = 0.0
	var min_val: float = values[0]
	var max_val: float = values[0]
	
	for v in values:
		var fv: float = float(v)
		sum += fv
		min_val = minf(min_val, fv)
		max_val = maxf(max_val, fv)
	
	var mean: float = sum / values.size()
	
	var variance_sum: float = 0.0
	for v in values:
		variance_sum += pow(float(v) - mean, 2)
	var std: float = sqrt(variance_sum / values.size())
	
	return {"mean": mean, "std": std, "min": min_val, "max": max_val}


## Computes z-score for a value.
##
## @param value: The value to compute z-score for
## @param mean: Population mean
## @param std: Population standard deviation
## @return: Z-score
func _compute_z_score(value: float, mean: float, std: float) -> float:
	if std <= 0:
		return 0.0
	return (value - mean) / std


## Computes average of an array.
##
## @param values: Array of float values
## @return: Average value
func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var sum: float = 0.0
	for v in values:
		sum += float(v)
	
	return sum / values.size()


## Extracts chassis ID from bot ID.
##
## @param bot_id: Bot identifier string
## @return: Chassis ID
func _extract_chassis_from_bot_id(bot_id: String) -> String:
	# Default extraction - override based on your naming convention
	var parts: PackedStringArray = bot_id.split("_")
	if parts.size() >= 2:
		return parts[0]
	return "unknown"


## Gets analysis notes from the recommendation process.
##
## @return: Array of note strings
func get_analysis_notes() -> Array[String]:
	return _analysis_notes


## Filters recommendations by type.
##
## @param target_type: Type to filter by ("weapon", "chassis", "economy", etc.)
## @return: Filtered array of recommendations
func get_recommendations_by_type(target_type: String) -> Array[TuningRecommendation]:
	var filtered: Array[TuningRecommendation] = []
	for rec in _recommendations:
		if rec.target_type == target_type:
			filtered.append(rec)
	return filtered


## Gets high priority recommendations only.
##
## @param max_priority: Maximum priority level to include (default 2)
## @return: Filtered array of high priority recommendations
func get_high_priority_recommendations(max_priority: int = 2) -> Array[TuningRecommendation]:
	var filtered: Array[TuningRecommendation] = []
	for rec in _recommendations:
		if rec.priority <= max_priority:
			filtered.append(rec)
	return filtered


## Exports all recommendations to a dictionary array.
##
## @return: Array of recommendation dictionaries
func export_to_array() -> Array[Dictionary]:
	var array: Array[Dictionary] = []
	for rec in _recommendations:
		array.append(rec.to_dictionary())
	return array
