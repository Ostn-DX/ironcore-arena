class_name BalanceReportWriter extends RefCounted

## Writes balance reports to various output formats (JSON, CSV, HTML).
## This class handles all file I/O for balance analysis reports,
## including timestamped directories and multiple format outputs.
##
## @tutorial: Create instance, then call write_json() or write_csv() with data

const REPORT_SUBDIR: String = "reports/balance/"
## Default subdirectory for reports

const CSV_DELIMITER: String = ","
## CSV field delimiter

const DEFAULT_ENCODING: String = "UTF-8"
## File encoding

var _report_dir: String = ""
## Current report directory

var _write_count: int = 0
## Number of files written

var _errors: Array[String] = []
## Collection of write errors


## Writes a JSON report to the specified path.
##
## @param path: Full file path for the JSON output
## @param data: Dictionary to serialize to JSON
## @param pretty_print: If true, formats JSON with indentation
## @return: true if write succeeded, false otherwise
## @example:
##     var writer = BalanceReportWriter.new()
##     writer.write_json("res://reports/summary.json", {"wins": 10, "losses": 5})
func write_json(path: String, data: Dictionary, pretty_print: bool = true) -> bool:
	var json := JSON.new()
	var json_str: String
	
	if pretty_print:
		json_str = json.stringify(data, "\t")
	else:
		json_str = json.stringify(data)
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		_write_count += 1
		print("BalanceReportWriter: Wrote JSON to ", path)
		return true
	else:
		var error_msg := "Failed to write JSON: " + path + " (Error: " + str(FileAccess.get_open_error()) + ")"
		_errors.append(error_msg)
		push_error(error_msg)
		return false


## Writes a CSV report to the specified path.
##
## @param path: Full file path for the CSV output
## @param rows: Array of dictionaries, each representing a row
## @param headers: Column headers (also used as keys for row dictionaries)
## @return: true if write succeeded, false otherwise
## @example:
##     var writer = BalanceReportWriter.new()
##     var headers = PackedStringArray(["weapon", "damage", "hits"])
##     var rows = [{"weapon": "rifle", "damage": 100, "hits": 50}]
##     writer.write_csv("res://reports/weapons.csv", rows, headers)
func write_csv(path: String, rows: Array[Dictionary], headers: PackedStringArray) -> bool:
	if headers.is_empty():
		push_error("BalanceReportWriter: CSV headers cannot be empty")
		return false
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var error_msg := "Failed to write CSV: " + path + " (Error: " + str(FileAccess.get_open_error()) + ")"
		_errors.append(error_msg)
		push_error(error_msg)
		return false
	
	# Write headers
	file.store_csv_line(headers)
	
	# Write rows
	for row in rows:
		var values: PackedStringArray = []
		for header in headers:
			var value = row.get(header, "")
			# Handle special types
			if value is float:
				values.append("%.4f" % value)
			elif value is int:
				values.append(str(value))
			elif value is bool:
				values.append("true" if value else "false")
			elif value is Array or value is Dictionary:
				var json := JSON.new()
				values.append(json.stringify(value))
			else:
				values.append(str(value))
		file.store_csv_line(values)
	
	file.close()
	_write_count += 1
	print("BalanceReportWriter: Wrote CSV to ", path)
	return true


## Writes an HTML report with embedded data visualization.
##
## @param path: Full file path for the HTML output
## @param title: Report title
## @param data: Dictionary containing report data
## @return: true if write succeeded, false otherwise
func write_html(path: String, title: String, data: Dictionary) -> bool:
	var html_content := _generate_html_report(title, data)
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var error_msg := "Failed to write HTML: " + path + " (Error: " + str(FileAccess.get_open_error()) + ")"
		_errors.append(error_msg)
		push_error(error_msg)
		return false
	
	file.store_string(html_content)
	file.close()
	_write_count += 1
	print("BalanceReportWriter: Wrote HTML to ", path)
	return true


## Generates a timestamped report directory.
##
## @param base_path: Optional base path (defaults to user:// or res://)
## @return: Path to the created directory with trailing slash
## @example:
##     var writer = BalanceReportWriter.new()
##     var dir = writer.generate_report_dir()
##     # Returns: "user://reports/balance/2024-01-15_12-30-45/"
func generate_report_dir(base_path: String = "") -> String:
	var timestamp: String = Time.get_datetime_string_from_system().replace(":", "-")
	
	var base: String
	if base_path.is_empty():
		# Use user:// for runtime, res:// for editor
		if Engine.is_editor_hint():
			base = "res://"
		else:
			base = "user://"
	else:
		base = base_path
		if not base.ends_with("/"):
			base += "/"
	
	var dir: String = base + REPORT_SUBDIR + timestamp + "/"
	
	var error := DirAccess.make_dir_recursive_absolute(dir)
	if error != OK:
		push_error("Failed to create report directory: " + dir)
		return ""
	
	_report_dir = dir
	print("BalanceReportWriter: Created report directory: ", dir)
	return dir


## Writes a complete batch result report in all formats.
##
## @param result: The BattleBatchResult to report on
## @param formats: Array of formats to generate ("json", "csv", "html")
## @return: Dictionary with paths to generated files
func write_batch_report(result: BattleBatchResult, formats: PackedStringArray = PackedStringArray(["json", "csv"])) -> Dictionary:
	var output_paths := {}
	
	if _report_dir.is_empty():
		generate_report_dir()
	
	# Always write JSON summary
	if "json" in formats:
		var json_path: String = _report_dir + "summary.json"
		if write_json(json_path, result.export_to_dictionary()):
			output_paths.json = json_path
	
	# Write CSV data
	if "csv" in formats:
		# Match results CSV
		var match_csv_path: String = _report_dir + "match_results.csv"
		var match_headers := PackedStringArray([
			"seed", "match_index", "winner_team", "end_reason",
			"duration_seconds", "team_a_alive", "team_b_alive"
		])
		if write_csv(match_csv_path, result.match_results, match_headers):
			output_paths.match_csv = match_csv_path
		
		# Weapon stats CSV
		var weapon_rows := _extract_weapon_rows(result)
		if not weapon_rows.is_empty():
			var weapon_csv_path: String = _report_dir + "weapon_stats.csv"
			var weapon_headers := PackedStringArray([
				"weapon_id", "shots_fired", "shots_hit", "hit_rate",
				"total_damage", "kills", "damage_per_shot"
			])
			if write_csv(weapon_csv_path, weapon_rows, weapon_headers):
				output_paths.weapon_csv = weapon_csv_path
	
	# Write HTML report
	if "html" in formats:
		var html_path: String = _report_dir + "report.html"
		if write_html(html_path, "Balance Report", result.export_to_dictionary()):
			output_paths.html = html_path
	
	return output_paths


## Extracts weapon statistics as CSV rows.
##
## @param result: BattleBatchResult containing weapon data
## @return: Array of dictionaries for CSV export
func _extract_weapon_rows(result: BattleBatchResult) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	
	if result.summary.is_empty():
		return rows
	
	var aggregates: Dictionary = result.summary.get("aggregate_metrics", {})
	var weapon_data: Dictionary = aggregates.get("weapon_aggregates", {})
	
	var damage_data: Dictionary = weapon_data.get("total_damage", {})
	var shots_data: Dictionary = weapon_data.get("total_shots", {})
	var hits_data: Dictionary = weapon_data.get("total_hits", {})
	var kills_data: Dictionary = weapon_data.get("total_kills", {})
	var hit_rates: Dictionary = weapon_data.get("hit_rates", {})
	
	# Collect all weapon IDs
	var all_weapons: Array[String] = []
	for weapon in damage_data.keys():
		if not weapon in all_weapons:
			all_weapons.append(weapon)
	
	for weapon in all_weapons:
		var shots: int = shots_data.get(weapon, 0)
		var hits: int = hits_data.get(weapon, 0)
		var damage: float = damage_data.get(weapon, 0.0)
		
		rows.append({
			"weapon_id": weapon,
			"shots_fired": shots,
			"shots_hit": hits,
			"hit_rate": hit_rates.get(weapon, 0.0),
			"total_damage": damage,
			"kills": kills_data.get(weapon, 0),
			"damage_per_shot": damage / shots if shots > 0 else 0.0
		})
	
	return rows


## Generates HTML report content.
##
## @param title: Report title
## @param data: Report data dictionary
## @return: Complete HTML string
func _generate_html_report(title: String, data: Dictionary) -> String:
	var summary: Dictionary = data.get("summary", {})
	var config: Dictionary = data.get("config", {})
	
	var html := """<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>""" + title + """</title>
	<style>
		body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
		.container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
		h1 { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
		h2 { color: #555; margin-top: 30px; }
		.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
		.stat-card { background: #f9f9f9; padding: 15px; border-radius: 6px; border-left: 4px solid #4CAF50; }
		.stat-label { font-size: 12px; color: #666; text-transform: uppercase; }
		.stat-value { font-size: 24px; font-weight: bold; color: #333; margin-top: 5px; }
		table { width: 100%; border-collapse: collapse; margin: 20px 0; }
		th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
		th { background: #4CAF50; color: white; }
		tr:hover { background: #f5f5f5; }
		.win-rate-good { color: #4CAF50; }
		.win-rate-bad { color: #f44336; }
		.footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #999; font-size: 12px; }
	</style>
</head>
<body>
	<div class="container">
		<h1>""" + title + """</h1>
		<p>Generated: """ + Time.get_datetime_string_from_system() + """</p>
		
		<h2>Summary Statistics</h2>
		<div class="stats-grid">
			<div class="stat-card">
				<div class="stat-label">Total Matches</div>
				<div class="stat-value">""" + str(summary.get("total_matches", 0)) + """</div>
			</div>
			<div class="stat-card">
				<div class="stat-label">Duration</div>
				<div class="stat-value">""" + "%.1fs" % summary.get("duration_seconds", 0.0) + """</div>
			</div>
			<div class="stat-card">
				<div class="stat-label">Team A Win Rate</div>
				<div class="stat-value">""" + "%.1f%%" % (summary.get("win_rates", {}).get(0, 0.0) * 100) + """</div>
			</div>
			<div class="stat-card">
				<div class="stat-label">Team B Win Rate</div>
				<div class="stat-value">""" + "%.1f%%" % (summary.get("win_rates", {}).get(1, 0.0) * 100) + """</div>
			</div>
		</div>
		
		<h2>Configuration</h2>
		<table>
			<tr><th>Parameter</th><th>Value</th></tr>
			<tr><td>Tier</td><td>""" + str(config.get("tier", "N/A")) + """</td></tr>
			<tr><td>Arena</td><td>""" + str(config.get("arena_id", "N/A")) + """</td></tr>
			<tr><td>Bots Per Team</td><td>""" + str(config.get("bots_per_team", "N/A")) + """</td></tr>
			<tr><td>Seeds</td><td>""" + str(config.get("seeds_count", 0)) + """</td></tr>
			<tr><td>Matches Per Seed</td><td>""" + str(config.get("matches_per_seed", 0)) + """</td></tr>
		</table>
		
		<div class="footer">
			<p>Generated by Godot Balance Validation System</p>
		</div>
	</div>
</body>
</html>"""
	
	return html


## Gets the current report directory.
##
## @return: Path to current report directory
func get_report_dir() -> String:
	return _report_dir


## Gets the number of files successfully written.
##
## @return: Write count
func get_write_count() -> int:
	return _write_count


## Gets any errors that occurred during writing.
##
## @return: Array of error messages
func get_errors() -> Array[String]:
	return _errors


## Clears the error log.
func clear_errors() -> void:
	_errors.clear()


## Writes recommendations to JSON.
##
## @param path: Output file path
## @param recommendations: Array of TuningRecommendation objects
## @return: true if write succeeded
func write_recommendations(path: String, recommendations: Array) -> bool:
	var rec_data: Array[Dictionary] = []
	for rec in recommendations:
		if rec is TuningRecommendation:
			rec_data.append(rec.to_dictionary())
		elif rec is Dictionary:
			rec_data.append(rec)
	
	return write_json(path, {"recommendations": rec_data})


## Writes a difficulty curve report.
##
## @param path: Output file path
## @param curve: Difficulty curve data from DifficultyCurveAnalyzer
## @return: true if write succeeded
func write_difficulty_curve(path: String, curve: Dictionary) -> bool:
	return write_json(path, {"difficulty_curve": curve})


## Appends data to an existing CSV file.
##
## @param path: Path to existing CSV file
## @param rows: Rows to append
## @return: true if append succeeded
func append_csv(path: String, rows: Array[Dictionary]) -> bool:
	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if not file:
		return false
	
	file.seek_end()
	
	for row in rows:
		# We need to know the headers - read first line
		# For simplicity, just convert all values
		var values: PackedStringArray = []
		for key in row.keys():
			values.append(str(row[key]))
		file.store_csv_line(values)
	
	file.close()
	return true
