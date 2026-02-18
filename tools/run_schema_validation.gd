UTYextends SceneTree
## Schema Validation Runner — validates all data files against JSON schemas.
## Usage: godot --headless --script res://tools/run_schema_validation.gd
## Exit 0 = all valid, Exit 1 = any invalid.

# Data file -> schema mapping.
# Keys are relative to res://data/, values relative to res://schemas/.
const FILE_MAP: Dictionary = {
	"slice/parts_slice.json": "parts.schema.json",
	"slice/bots_slice.json": "bot_loadout.schema.json",
	"slice/arenas_slice.json": "arena.schema.json",
	"slice/enemies_slice.json": "enemy_build.schema.json",
	"slice/campaign_slice.json": "campaign_node.schema.json",
	"slice/economy_slice.json": "economy.schema.json",
	"balance/envelopes_t1_t5.json": "balance_envelopes.schema.json",
}


func _init() -> void:
	var validator := SchemaValidator.new()
	var total := 0
	var passed := 0
	var failed := 0

	print("")
	print("=== IRONCORE ARENA — Schema Validation ===")
	print("")

	for data_rel in FILE_MAP:
		var schema_rel: String = FILE_MAP[data_rel]
		var data_path := "res://data/%s" % data_rel
		var schema_path := "res://schemas/%s" % schema_rel
		var display_name: String = data_rel.get_file()
		total += 1

		# Load schema
		var schema_text := _load_text(schema_path)
		if schema_text.is_empty():
			print("  ✖ %s  — could not load schema %s" % [display_name, schema_rel])
			failed += 1
			continue

		var schema_json = JSON.new()
		var schema_err := schema_json.parse(schema_text)
		if schema_err != OK:
			print("  ✖ %s  — schema parse error: %s" % [display_name, schema_json.get_error_message()])
			failed += 1
			continue

		var schema: Dictionary = schema_json.data

		# Load data
		var data_text := _load_text(data_path)
		if data_text.is_empty():
			print("  ✖ %s  — could not load data file" % display_name)
			failed += 1
			continue

		var data_json = JSON.new()
		var data_err := data_json.parse(data_text)
		if data_err != OK:
			print("  ✖ %s  — JSON parse error: %s" % [display_name, data_json.get_error_message()])
			failed += 1
			continue

		var data: Variant = data_json.data

		# Validate — arrays need per-element validation against the item schema.
		var file_errors: Array[String] = []

		if data is Array:
			# Each element is validated against the schema (which describes a single item).
			for i in data.size():
				validator.validate(data[i], schema, "$[%d]" % i)
				file_errors.append_array(validator.errors)
		else:
			validator.validate(data, schema, "$")
			file_errors.append_array(validator.errors)

		if file_errors.is_empty():
			print("  ✔ %s valid" % display_name)
			passed += 1
		else:
			print("  ✖ %s  — %d error(s):" % [display_name, file_errors.size()])
			for e in file_errors:
				print("      %s" % e)
			failed += 1

	print("")
	print("Results: %d/%d passed, %d failed" % [passed, total, failed])
	print("")

	if failed > 0:
		print("SCHEMA VALIDATION FAILED")
		quit(1)
	else:
		print("SCHEMA VALIDATION TOOL READY")
		quit(0)


func _load_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text
