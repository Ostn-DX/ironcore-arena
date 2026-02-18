class_name SchemaValidator
extends RefCounted
## Minimal JSON Schema validator supporting the subset used by IRONCORE ARENA schemas.
## Supported keywords: type, properties, required, items, enum, minimum, maximum,
## minLength, maxLength, minItems, maxItems, pattern, additionalProperties,
## patternProperties.

var errors: Array[String] = []


func validate(data: Variant, schema: Dictionary, path: String = "$") -> bool:
	errors.clear()
	_validate_node(data, schema, path)
	return errors.is_empty()


func _validate_node(data: Variant, schema: Dictionary, path: String) -> void:
	# --- type ---
	if schema.has("type"):
		if not _check_type(data, schema["type"], path):
			return  # Wrong type; skip further checks on this node.

	# --- enum ---
	if schema.has("enum"):
		_check_enum(data, schema["enum"], path)

	# --- numeric constraints ---
	if data is float or data is int:
		if schema.has("minimum"):
			if float(data) < float(schema["minimum"]):
				errors.append("%s: value %s < minimum %s" % [path, str(data), str(schema["minimum"])])
		if schema.has("maximum"):
			if float(data) > float(schema["maximum"]):
				errors.append("%s: value %s > maximum %s" % [path, str(data), str(schema["maximum"])])

	# --- string constraints ---
	if data is String:
		if schema.has("minLength"):
			if data.length() < int(schema["minLength"]):
				errors.append("%s: string length %d < minLength %d" % [path, data.length(), int(schema["minLength"])])
		if schema.has("maxLength"):
			if data.length() > int(schema["maxLength"]):
				errors.append("%s: string length %d > maxLength %d" % [path, data.length(), int(schema["maxLength"])])
		if schema.has("pattern"):
			var regex := RegEx.new()
			var err := regex.compile(schema["pattern"] as String)
			if err == OK:
				if not regex.search(data):
					errors.append("%s: string \"%s\" does not match pattern \"%s\"" % [path, data, schema["pattern"]])

	# --- object ---
	if data is Dictionary:
		# required
		if schema.has("required"):
			for field in schema["required"]:
				if not data.has(field):
					errors.append("%s: missing required field \"%s\"" % [path, field])

		# properties
		if schema.has("properties"):
			var props: Dictionary = schema["properties"]
			for key in data:
				if props.has(key):
					_validate_node(data[key], props[key], "%s.%s" % [path, key])

		# additionalProperties
		if schema.has("additionalProperties") and schema["additionalProperties"] == false:
			var allowed_keys := {}
			if schema.has("properties"):
				for k in schema["properties"]:
					allowed_keys[k] = true
			if schema.has("patternProperties"):
				# Collect keys that match any pattern
				for pat in schema["patternProperties"]:
					var regex := RegEx.new()
					if regex.compile(pat) == OK:
						for k in data:
							if regex.search(k):
								allowed_keys[k] = true
			for key in data:
				if not allowed_keys.has(key):
					errors.append("%s: additional property \"%s\" not allowed" % [path, key])

		# patternProperties
		if schema.has("patternProperties"):
			for pat in schema["patternProperties"]:
				var regex := RegEx.new()
				if regex.compile(pat) == OK:
					var sub_schema: Dictionary = schema["patternProperties"][pat]
					for key in data:
						if regex.search(key):
							_validate_node(data[key], sub_schema, "%s.%s" % [path, key])

	# --- array ---
	if data is Array:
		if schema.has("minItems"):
			if data.size() < int(schema["minItems"]):
				errors.append("%s: array size %d < minItems %d" % [path, data.size(), int(schema["minItems"])])
		if schema.has("maxItems"):
			if data.size() > int(schema["maxItems"]):
				errors.append("%s: array size %d > maxItems %d" % [path, data.size(), int(schema["maxItems"])])
		if schema.has("items"):
			var item_schema: Dictionary = schema["items"]
			for i in data.size():
				_validate_node(data[i], item_schema, "%s[%d]" % [path, i])


func _check_type(data: Variant, expected_type: String, path: String) -> bool:
	match expected_type:
		"object":
			if not data is Dictionary:
				errors.append("%s: expected object, got %s" % [path, _type_name(data)])
				return false
		"array":
			if not data is Array:
				errors.append("%s: expected array, got %s" % [path, _type_name(data)])
				return false
		"string":
			if not data is String:
				errors.append("%s: expected string, got %s" % [path, _type_name(data)])
				return false
		"integer":
			# Godot parses JSON integers as int OR float with .0
			if data is int:
				pass  # OK
			elif data is float:
				if not is_equal_approx(data, roundf(data)):
					errors.append("%s: expected integer, got float %s" % [path, str(data)])
					return false
			else:
				errors.append("%s: expected integer, got %s" % [path, _type_name(data)])
				return false
		"number":
			if not (data is int or data is float):
				errors.append("%s: expected number, got %s" % [path, _type_name(data)])
				return false
		"boolean":
			if not data is bool:
				errors.append("%s: expected boolean, got %s" % [path, _type_name(data)])
				return false
		"null":
			if data != null:
				errors.append("%s: expected null, got %s" % [path, _type_name(data)])
				return false
	return true


func _check_enum(data: Variant, allowed: Array, path: String) -> void:
	for val in allowed:
		if typeof(data) == typeof(val) and data == val:
			return
		# Handle int/float comparison for numeric enums
		if (data is int or data is float) and (val is int or val is float):
			if is_equal_approx(float(data), float(val)):
				return
	errors.append("%s: value \"%s\" not in enum %s" % [path, str(data), str(allowed)])


func _type_name(data: Variant) -> String:
	if data == null:
		return "null"
	if data is Dictionary:
		return "object"
	if data is Array:
		return "array"
	if data is String:
		return "string"
	if data is int:
		return "integer"
	if data is float:
		return "number"
	if data is bool:
		return "boolean"
	return "unknown"
