extends SceneTree
## Schema Validation Runner — validates all data files against JSON schemas.
## Implementation: TASK-04
## NOTE: This is a convenience alias. The actual runner is:
##   project/tools/run_schema_validation.gd  (res://tools/run_schema_validation.gd)
## Run from project/ dir:
##   godot --headless --script res://tools/run_schema_validation.gd

func _init() -> void:
	print("ERROR: Run from the project/ directory using:")
	print("  godot --headless --script res://tools/run_schema_validation.gd")
	quit(1)
