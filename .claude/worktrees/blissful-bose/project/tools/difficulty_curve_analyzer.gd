class_name DifficultyCurveAnalyzer extends RefCounted

## Analyzes difficulty progression across multiple tiers.
## This class computes win rates, TTK, and economic metrics
## for each tier to validate difficulty curve design.
##
## @tutorial: Pass batch results from multiple tiers to compute_curve()

const DEFAULT_TIER_RANGE: int = 10
## Default maximum tier level

const WIN_RATE_TARGET: float = 0.5
## Target win rate for balanced gameplay

const WIN_RATE_TOLERANCE: float = 0.1
## Acceptable deviation from target win rate

const TTK_GROWTH_TARGET: float = 1.1
## Target TTK growth factor per tier (10% increase)

# Computed curve data
var _tier_data: Dictionary = {}
## Raw data organized by tier

var _curve_validated: bool = false
## Whether curve has been validated

var _validation_results: Dictionary = {}
## Cached validation results


## Computes the difficulty curve from batch results.
##
## @param results: Array of BattleBatchResult objects or result dictionaries
## @return: Dictionary with tier -> metrics mapping
## @example:
##     var analyzer = DifficultyCurveAnalyzer.new()
##     var curve = analyzer.compute_curve([tier1_result, tier2_result, tier3_result])
##     print(curve.tier_win_rates)
func compute_curve(results: Array) -> Dictionary:
	_tier_data.clear()
	_curve_validated = false
	
	# Initialize tier data structure
	for tier in range(1, DEFAULT_TIER_RANGE + 1):
		_tier_data[tier] = {
			"win_rates": [],
			"ttk_values": [],
			"credits_per_hour": [],
			"match_counts": [],
			"durations": []
		}
	
	# Collect data from all results
	for result in results:
		var tier: int = _extract_tier(result)
		if tier < 1 or tier > DEFAULT_TIER_RANGE:
			continue
		
		var win_rate: float = _extract_win_rate(result)
		var ttk: float = _extract_median_ttk(result)
		var cph: float = _extract_credits_per_hour(result)
		var match_count: int = _extract_match_count(result)
		var duration: float = _extract_duration(result)
		
		_tier_data[tier].win_rates.append(win_rate)
		_tier_data[tier].ttk_values.append(ttk)
		_tier_data[tier].credits_per_hour.append(cph)
		_tier_data[tier].match_counts.append(match_count)
		_tier_data[tier].durations.append(duration)
	
	# Compute averages for each tier
	var curve := {
		"tier_win_rates": {},
		"tier_ttk": {},
		"tier_credits_per_hour": {},
		"tier_match_counts": {},
		"tier_avg_duration": {},
		"difficulty_score": {},
		"raw_data": _tier_data
	}
	
	for tier in range(1, DEFAULT_TIER_RANGE + 1):
		var data: Dictionary = _tier_data[tier]
		
		# Skip tiers with no data
		if data.win_rates.is_empty():
			continue
		
		curve.tier_win_rates[tier] = _average(data.win_rates)
		curve.tier_ttk[tier] = _average(data.ttk_values)
		curve.tier_credits_per_hour[tier] = _average(data.credits_per_hour)
		curve.tier_match_counts[tier] = _sum_int(data.match_counts)
		curve.tier_avg_duration[tier] = _average(data.durations)
		
		# Compute composite difficulty score
		curve.difficulty_score[tier] = _compute_difficulty_score(
			curve.tier_win_rates[tier],
			curve.tier_ttk[tier],
			tier
		)
	
	return curve


## Validates that the difficulty curve follows expected patterns.
##
## @param curve: Curve data from compute_curve()
## @param strict_mode: If true, applies stricter validation thresholds
## @return: Dictionary with "valid" boolean and "issues" array
## @example:
##     var validation = analyzer.validate_curve(curve)
##     if not validation.valid:
##         print("Issues found: ", validation.issues)
func validate_curve(curve: Dictionary, strict_mode: bool = false) -> Dictionary:
	_curve_validated = true
	var issues: Array[String] = []
	var warnings: Array[String] = []
	
	var win_rates: Dictionary = curve.get("tier_win_rates", {})
	var ttks: Dictionary = curve.get("tier_ttk", {})
	var credits: Dictionary = curve.get("tier_credits_per_hour", {})
	
	var tiers: Array = win_rates.keys()
	tiers.sort()
	
	if tiers.size() < 2:
		return {"valid": false, "issues": ["Need at least 2 tiers for validation"], "warnings": []}
	
	var tolerance: float = WIN_RATE_TOLERANCE * (0.5 if strict_mode else 1.0)
	
	# Check win rate decreases with tier (player gets relatively weaker)
	for i in range(1, tiers.size()):
		var prev_tier: int = tiers[i - 1]
		var curr_tier: int = tiers[i]
		
		var prev_wr: float = win_rates[prev_tier]
		var curr_wr: float = win_rates[curr_tier]
		
		# Win rate should generally decrease as tier increases
		# Allow small increases due to variance
		if curr_wr > prev_wr + tolerance:
			issues.append("Win rate increases from tier %d (%.2f) to tier %d (%.2f)" % [prev_tier, prev_wr, curr_tier, curr_wr])
		elif curr_wr > prev_wr:
			warnings.append("Minor win rate increase from tier %d (%.2f) to tier %d (%.2f)" % [prev_tier, prev_wr, curr_tier, curr_wr])
		
		# Check for extreme win rates
		if curr_wr < 0.1:
			issues.append("Tier %d has very low win rate (%.2f) - may be too difficult" % [curr_tier, curr_wr])
		if curr_wr > 0.9:
			issues.append("Tier %d has very high win rate (%.2f) - may be too easy" % [curr_tier, curr_wr])
	
	# Check TTK progression (should generally increase with tier)
	var ttk_tiers: Array = ttks.keys()
	ttk_tiers.sort()
	
	for i in range(1, ttk_tiers.size()):
		var prev_tier: int = ttk_tiers[i - 1]
		var curr_tier: int = ttk_tiers[i]
		
		var prev_ttk: float = ttks[prev_tier]
		var curr_ttk: float = ttks[curr_tier]
		
		if prev_ttk > 0 and curr_ttk > 0:
			var growth: float = curr_ttk / prev_ttk
			if growth < 0.9:  # TTK decreased significantly
				warnings.append("TTK decreased from tier %d (%.1fs) to tier %d (%.1fs)" % [prev_tier, prev_ttk, curr_tier, curr_ttk])
	
	# Check credits per hour (should be relatively stable or slightly increasing)
	var credit_tiers: Array = credits.keys()
	credit_tiers.sort()
	
	for i in range(1, credit_tiers.size()):
		var prev_tier: int = credit_tiers[i - 1]
		var curr_tier: int = credit_tiers[i]
		
		var prev_cph: float = credits[prev_tier]
		var curr_cph: float = credits[curr_tier]
		
		if prev_cph > 0:
			var change: float = (curr_cph - prev_cph) / prev_cph
			if change < -0.3:  # Credits dropped more than 30%
				warnings.append("Credits/hour dropped significantly from tier %d (%.0f) to tier %d (%.0f)" % [prev_tier, prev_cph, curr_tier, curr_cph])
	
	_validation_results = {
		"valid": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"tier_count": tiers.size()
	}
	
	return _validation_results


## Gets the recommended tier for a target win rate.
##
## @param curve: Curve data from compute_curve()
## @param target_win_rate: Desired win rate (default 0.5)
## @return: Recommended tier level
func get_recommended_tier(curve: Dictionary, target_win_rate: float = 0.5) -> int:
	var win_rates: Dictionary = curve.get("tier_win_rates", {})
	
	var best_tier: int = 1
	var best_diff: float = 999.0
	
	for tier in win_rates.keys():
		var diff: float = abs(win_rates[tier] - target_win_rate)
		if diff < best_diff:
			best_diff = diff
			best_tier = tier
	
	return best_tier


## Computes the difficulty slope between two tiers.
##
## @param curve: Curve data from compute_curve()
## @param from_tier: Starting tier
## @param to_tier: Ending tier
## @return: Dictionary with slope metrics
func compute_difficulty_slope(curve: Dictionary, from_tier: int, to_tier: int) -> Dictionary:
	var win_rates: Dictionary = curve.get("tier_win_rates", {})
	var ttks: Dictionary = curve.get("tier_ttk", {})
	
	if not win_rates.has(from_tier) or not win_rates.has(to_tier):
		return {"error": "Tier data not available"}
	
	var wr_slope: float = (win_rates[to_tier] - win_rates[from_tier]) / (to_tier - from_tier)
	var ttk_slope: float = 0.0
	
	if ttks.has(from_tier) and ttks.has(to_tier) and ttks[from_tier] > 0:
		ttk_slope = (ttks[to_tier] - ttks[from_tier]) / (to_tier - from_tier)
	
	return {
		"win_rate_slope": wr_slope,
		"ttk_slope": ttk_slope,
		"tiers_spanned": to_tier - from_tier,
		"difficulty_increasing": wr_slope < 0
	}


## Exports curve data for visualization.
##
## @param curve: Curve data from compute_curve()
## @return: Array of dictionaries suitable for CSV export
func export_for_visualization(curve: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	
	var win_rates: Dictionary = curve.get("tier_win_rates", {})
	var ttks: Dictionary = curve.get("tier_ttk", {})
	var credits: Dictionary = curve.get("tier_credits_per_hour", {})
	var scores: Dictionary = curve.get("difficulty_score", {})
	
	var tiers: Array = win_rates.keys()
	tiers.sort()
	
	for tier in tiers:
		rows.append({
			"tier": tier,
			"win_rate": win_rates.get(tier, 0.0),
			"median_ttk": ttks.get(tier, 0.0),
			"credits_per_hour": credits.get(tier, 0.0),
			"difficulty_score": scores.get(tier, 0.0)
		})
	
	return rows


## Extracts tier from a result object.
##
## @param result: BattleBatchResult or dictionary
## @return: Tier number
func _extract_tier(result) -> int:
	if result is BattleBatchResult:
		return result.config.tier if result.config else 0
	elif result is Dictionary:
		var config: Dictionary = result.get("config", {})
		return config.get("tier", 0)
	return 0


## Extracts win rate from a result object.
##
## @param result: BattleBatchResult or dictionary
## @return: Win rate (0.0 to 1.0)
func _extract_win_rate(result) -> float:
	if result is BattleBatchResult:
		return result.get_win_rate(0)  # Team A win rate
	elif result is Dictionary:
		var summary: Dictionary = result.get("summary", {})
		var win_rates: Dictionary = summary.get("win_rates", {})
		return win_rates.get(0, 0.0)
	return 0.0


## Extracts median TTK from a result object.
##
## @param result: BattleBatchResult or dictionary
## @return: Median TTK in seconds
func _extract_median_ttk(result) -> float:
	if result is BattleBatchResult:
		return result.get_median_ttk()
	elif result is Dictionary:
		var summary: Dictionary = result.get("summary", {})
		var agg: Dictionary = summary.get("aggregate_metrics", {})
		var ttk_stats: Dictionary = agg.get("ttk_stats", {})
		return ttk_stats.get("median", 0.0)
	return 0.0


## Extracts credits per hour from a result object.
##
## @param result: BattleBatchResult or dictionary
## @return: Credits per hour
func _extract_credits_per_hour(result) -> float:
	if result is BattleBatchResult:
		return result.get_credits_per_hour()
	elif result is Dictionary:
		var summary: Dictionary = result.get("summary", {})
		var agg: Dictionary = summary.get("aggregate_metrics", {})
		var econ: Dictionary = agg.get("economy_stats", {})
		return econ.get("credits_per_hour", 0.0)
	return 0.0


## Extracts match count from a result object.
##
## @param result: BattleBatchResult or dictionary
## @return: Number of matches
func _extract_match_count(result) -> int:
	if result is BattleBatchResult:
		return result.match_results.size()
	elif result is Dictionary:
		var summary: Dictionary = result.get("summary", {})
		return summary.get("total_matches", 0)
	return 0


## Extracts duration from a result object.
##
## @param result: BattleBatchResult or dictionary
## @return: Duration in seconds
func _extract_duration(result) -> float:
	if result is BattleBatchResult:
		return result.get_duration_sec()
	elif result is Dictionary:
		var summary: Dictionary = result.get("summary", {})
		return summary.get("duration_seconds", 0.0)
	return 0.0


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


## Sums an array of integers.
##
## @param values: Array of int values
## @return: Sum
func _sum_int(values: Array) -> int:
	var sum: int = 0
	for v in values:
		sum += int(v)
	return sum


## Computes composite difficulty score.
##
## @param win_rate: Win rate (0.0 to 1.0)
## @param ttk: Median time-to-kill
## @param tier: Tier level
## @return: Composite difficulty score
func _compute_difficulty_score(win_rate: float, ttk: float, tier: int) -> float:
	# Lower win rate = higher difficulty
	var win_rate_factor: float = (1.0 - win_rate) * 100.0
	
	# Higher TTK = higher difficulty (longer fights)
	var ttk_factor: float = ttk * 5.0
	
	# Base tier factor
	var tier_factor: float = tier * 10.0
	
	return win_rate_factor + ttk_factor + tier_factor


## Gets the last validation results.
##
## @return: Dictionary with validation results
func get_last_validation() -> Dictionary:
	return _validation_results


## Checks if a specific tier transition is smooth.
##
## @param curve: Curve data from compute_curve()
## @param from_tier: Starting tier
## @param to_tier: Ending tier
## @return: true if transition is smooth
func is_smooth_transition(curve: Dictionary, from_tier: int, to_tier: int) -> bool:
	var win_rates: Dictionary = curve.get("tier_win_rates", {})
	
	if not win_rates.has(from_tier) or not win_rates.has(to_tier):
		return false
	
	var wr_diff: float = abs(win_rates[to_tier] - win_rates[from_tier])
	
	# Transition is smooth if win rate change is gradual
	return wr_diff < 0.15  # Less than 15% change
