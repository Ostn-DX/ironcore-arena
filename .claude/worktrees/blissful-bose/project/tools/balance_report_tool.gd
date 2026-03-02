@tool
class_name BalanceReportTool extends EditorScript

## Editor tool for running balance reports from the Godot editor.
## This script can be executed directly in the editor to run
## batch simulations and generate balance reports.
##
## @tutorial: Run from Script Editor with Ctrl+Shift+X or File > Run

const DEFAULT_CONFIG_PATH: String = "res://balance_config.tres"
## Default path for saved configuration

const DEFAULT_SEED_COUNT: int = 5
## Default number of seeds

const DEFAULT_MATCHES_PER_SEED: int = 20
## Default matches per seed

const DEFAULT_BOTS_PER_TEAM: int = 5
## Default team size

## Main entry point for the editor tool.
## Runs the complete balance analysis workflow.
func _run() -> void:
	print("=" * 60)
	print("BalanceReportTool: Starting balance analysis...")
	print("=" * 60)
	
	var start_time: int = Time.get_ticks_msec()
	
	# Load or create configuration
	var config := _load_or_create_config()
	
	# Validate configuration
	var validation: Dictionary = config.validate()
	if not validation.valid:
		print("Configuration errors:")
		for error in validation.errors:
			print("  - " + error)
		return
	
	print("Configuration:")
	print("  Seeds: %s" % str(config.seeds))
	print("  Matches per seed: %d" % config.matches_per_seed)
	print("  Bots per team: %d" % config.bots_per_team)
	print("  Tier: %d" % config.tier)
	print("  Arena: %s" % config.arena_id)
	print("  Total matches: %d" % config.get_total_matches())
	
	# Create and run batch
	var runner := HeadlessBattleRunner.new()
	
	# Connect signals for progress reporting
	runner.match_completed.connect(_on_match_completed)
	runner.batch_completed.connect(_on_batch_completed)
	runner.match_progress.connect(_on_match_progress)
	
	print("\nRunning simulations...")
	var result := runner.run_batch(config)
	
	# Generate reports
	print("\nGenerating reports...")
	var writer := BalanceReportWriter.new()
	var report_dir: String = writer.generate_report_dir()
	
	if report_dir.is_empty():
		push_error("Failed to create report directory")
		return
	
	# Write main summary
	var summary_path: String = report_dir + "summary.json"
	writer.write_json(summary_path, result.export_to_dictionary())
	
	# Write match results
	var match_results_path: String = report_dir + "match_results.json"
	writer.write_json(match_results_path, {"matches": result.match_results})
	
	# Write CSV reports
	var report_formats: PackedStringArray = config.report_formats
	if "csv" in report_formats:
		writer.write_batch_report(result, PackedStringArray(["csv"]))
	
	# Write HTML report
	if "html" in report_formats:
		writer.write_batch_report(result, PackedStringArray(["html"]))
	
	# Generate recommendations
	print("\nAnalyzing balance and generating recommendations...")
	var recommender := TuningRecommender.new()
	var recommendations: Array[TuningRecommendation] = recommender.generate_recommendations(result)
	
	# Write recommendations
	var rec_path: String = report_dir + "tuning_recommendations.json"
	writer.write_recommendations(rec_path, recommendations)
	
	# Write recommendations as CSV
	if not recommendations.is_empty():
		var rec_csv_path: String = report_dir + "tuning_recommendations.csv"
		var rec_headers := PackedStringArray([
			"target_id", "target_type", "target_property",
			"current_value", "proposed_value", "change_percent",
			"confidence", "priority", "rationale"
		])
		var rec_rows: Array[Dictionary] = []
		for rec in recommendations:
			rec_rows.append({
				"target_id": rec.target_id,
				"target_type": rec.target_type,
				"target_property": rec.target_property,
				"current_value": rec.current_value,
				"proposed_value": rec.proposed_value,
				"change_percent": rec.change_percent,
				"confidence": rec.confidence,
				"priority": rec.priority,
				"rationale": rec.rationale
			})
		writer.write_csv(rec_csv_path, rec_rows, rec_headers)
	
	# Print recommendations summary
	print("\n" + "=" * 60)
	print("TUNING RECOMMENDATIONS")
	print("=" * 60)
	
	if recommendations.is_empty():
		print("No significant balance issues detected!")
	else:
		print("Found %d recommendations:\n" % recommendations.size())
		for i in range(min(recommendations.size(), 10)):
			var rec: TuningRecommendation = recommendations[i]
			print("%d. %s" % [i + 1, rec.get_summary()])
			print("   Confidence: %s" % rec.get_confidence_string())
			print("")
		
		if recommendations.size() > 10:
			print("... and %d more recommendations" % (recommendations.size() - 10))
	
	# Print analysis notes
	var notes: Array[String] = recommender.get_analysis_notes()
	if not notes.is_empty():
		print("\nAnalysis Notes:")
		for note in notes:
			print("  - " + note)
	
	# Check balance
	var balance_check: Dictionary = result.check_balance()
	print("\n" + "=" * 60)
	print("BALANCE CHECK")
	print("=" * 60)
	print("Team A Win Rate: %.1f%%" % (balance_check.team_a_win_rate * 100))
	print("Team B Win Rate: %.1f%%" % (balance_check.team_b_win_rate * 100))
	print("Timeout Rate: %.1f%%" % (balance_check.timeout_rate * 100))
	print("Status: %s" % ("BALANCED" if balance_check.balanced else "NEEDS ATTENTION"))
	
	if not balance_check.issues.is_empty():
		print("\nIssues:")
		for issue in balance_check.issues:
			print("  - " + issue)
	
	# Print summary statistics
	var end_time: int = Time.get_ticks_msec()
	var duration: float = (end_time - start_time) / 1000.0
	
	print("\n" + "=" * 60)
	print("SUMMARY")
	print("=" * 60)
	print("Total matches: %d" % result.match_results.size())
	print("Average match duration: %.1f seconds" % result.get_average_match_duration())
	print("Median TTK: %.1f seconds" % result.get_median_ttk())
	print("Credits/hour: %.0f" % result.get_credits_per_hour())
	print("Reports written to: %s" % report_dir)
	print("Total time: %.1f seconds" % duration)
	print("=" * 60)
	print("BalanceReportTool: Analysis complete!")
	print("=" * 60)


## Loads existing config or creates a default one.
##
## @return: BattleBatchConfig instance
func _load_or_create_config() -> BattleBatchConfig:
	if ResourceLoader.exists(DEFAULT_CONFIG_PATH):
		print("Loading existing config from: " + DEFAULT_CONFIG_PATH)
		var config := ResourceLoader.load(DEFAULT_CONFIG_PATH)
		if config is BattleBatchConfig:
			return config
		else:
			push_warning("Config file exists but is not BattleBatchConfig")
	
	print("Creating default configuration...")
	var config := BattleBatchConfig.new()
	
	# Generate deterministic seeds
	var seeds: Array[int] = []
	for i in range(DEFAULT_SEED_COUNT):
		seeds.append(12345 + i * 11111)
	config.seeds = PackedInt32Array(seeds)
	
	config.matches_per_seed = DEFAULT_MATCHES_PER_SEED
	config.bots_per_team = DEFAULT_BOTS_PER_TEAM
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
	
	# Save default config
	var save_error := ResourceSaver.save(config, DEFAULT_CONFIG_PATH)
	if save_error == OK:
		print("Saved default config to: " + DEFAULT_CONFIG_PATH)
	else:
		push_warning("Failed to save config: " + str(save_error))
	
	return config


## Callback for match completion.
##
## @param match_index: Index of completed match
## @param match_result: Match result dictionary
func _on_match_completed(match_index: int, match_result: Dictionary) -> void:
	if match_index % 10 == 0:
		print("  Completed match %d (winner: team %d)" % [match_index, match_result.get("winner_team", -1)])


## Callback for batch completion.
##
## @param results: BattleBatchResult
func _on_batch_completed(results: BattleBatchResult) -> void:
	print("  Batch completed: %d matches" % results.match_results.size())


## Callback for match progress.
##
## @param current: Current match number
## @param total: Total matches
func _on_match_progress(current: int, total: int) -> void:
	if current % 10 == 0 or current == total:
		var percent: float = float(current) / total * 100.0
		print("  Progress: %d/%d (%.0f%%)" % [current, total, percent])


## Runs a difficulty curve analysis across multiple tiers.
##
## @param start_tier: Starting tier level
## @param end_tier: Ending tier level
## @return: Dictionary with analysis results
func run_difficulty_curve_analysis(start_tier: int = 1, end_tier: int = 5) -> Dictionary:
	print("Running difficulty curve analysis (tiers %d-%d)..." % [start_tier, end_tier])
	
	var all_results: Array = []
	var runner := HeadlessBattleRunner.new()
	
	for tier in range(start_tier, end_tier + 1):
		print("\nAnalyzing tier %d..." % tier)
		
		var config := BattleBatchConfig.new()
		config.tier = tier
		config.seeds = PackedInt32Array([12345, 67890, 11111])
		config.matches_per_seed = 10
		config.bots_per_team = 5
		
		var result := runner.run_batch(config)
		all_results.append(result)
		
		print("  Tier %d: Win rate = %.2f, TTK = %.1f" % [
			tier,
			result.get_win_rate(0),
			result.get_median_ttk()
		])
	
	# Analyze curve
	var analyzer := DifficultyCurveAnalyzer.new()
	var curve := analyzer.compute_curve(all_results)
	var validation := analyzer.validate_curve(curve)
	
	# Write report
	var writer := BalanceReportWriter.new()
	var report_dir: String = writer.generate_report_dir()
	writer.write_difficulty_curve(report_dir + "difficulty_curve.json", curve)
	
	return {
		"curve": curve,
		"validation": validation,
		"report_dir": report_dir
	}


## Runs a weapon matchup comparison.
##
## @param weapon_a: First weapon ID
## @param weapon_b: Second weapon ID
## @return: BattleBatchResult from the comparison
func run_weapon_comparison(weapon_a: String, weapon_b: String) -> BattleBatchResult:
	print("Running weapon comparison: %s vs %s" % [weapon_a, weapon_b])
	
	var config := BattleBatchConfig.create_weapon_matchup(weapon_a, weapon_b)
	config.matches_per_seed = 50
	
	var runner := HeadlessBattleRunner.new()
	var result := runner.run_batch(config)
	
	print("Results:")
	print("  %s win rate: %.2f" % [weapon_a, result.get_win_rate(0)])
	print("  %s win rate: %.2f" % [weapon_b, result.get_win_rate(1)])
	print("  Median TTK: %.1f" % result.get_median_ttk())
	
	return result


## Exports the current configuration to a file.
##
## @param path: Path to save config
## @param config: Configuration to save
## @return: true if save succeeded
func export_config(path: String, config: BattleBatchConfig) -> bool:
	var error := ResourceSaver.save(config, path)
	if error == OK:
		print("Exported config to: " + path)
		return true
	else:
		push_error("Failed to export config: " + str(error))
		return false
