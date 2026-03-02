## @file shared/determinism_helpers.gd
## @brief Utility functions for deterministic operations.
## @description
## This file provides helper functions for common deterministic operations
## that are needed throughout the simulation. Use these instead of built-in
## functions that may have non-deterministic behavior.

class_name DeterminismHelpers
extends RefCounted

# =============================================================================
# DICTIONARY OPERATIONS
# =============================================================================

## Get dictionary keys sorted deterministically.
## @param dict: Dictionary to get keys from
## @return: Sorted array of keys
static func get_sorted_keys(dict: Dictionary) -> Array:
	var keys: Array = dict.keys()
	keys.sort()
	return keys


## Get dictionary values sorted by their keys.
## @param dict: Dictionary to get values from
## @return: Array of values sorted by key
static func get_sorted_values_by_key(dict: Dictionary) -> Array:
	var result: Array = []
	for key in get_sorted_keys(dict):
		result.append(dict[key])
	return result


## Get dictionary values sorted by a property.
## @param dict: Dictionary containing objects
## @param property_name: Property to sort by (must be comparable)
## @return: Array of values sorted by property
static func get_sorted_values(dict: Dictionary, property_name: String) -> Array:
	var values: Array = []
	values.assign(dict.values())
	
	values.sort_custom(func(a, b) -> bool:
		if not a.has_method("get") and not property_name in a:
			return false
		if not b.has_method("get") and not property_name in b:
			return true
		
		var val_a = a.get(property_name) if a.has_method("get") else a[property_name]
		var val_b = b.get(property_name) if b.has_method("get") else b[property_name]
		
		if val_a is float and val_b is float:
			if not SimConstants.floats_equal(val_a, val_b):
				return val_a < val_b
			# Tie-breaker: sim_id if available
			if a.has_method("get") and a.has("sim_id") and b.has("sim_id"):
				return a.sim_id < b.sim_id
			return false
		
		if val_a != val_b:
			return val_a < val_b
		
		# Tie-breaker: sim_id if available
		if a.has_method("get") and a.has("sim_id") and b.has("sim_id"):
			return a.sim_id < b.sim_id
		
		return false
	)
	
	return values


## Iterate over dictionary in deterministic order.
## Usage: for key in DeterminismHelpers.iterate_dict(my_dict):
## @param dict: Dictionary to iterate
## @return: Array of keys in sorted order
static func iterate_dict(dict: Dictionary) -> Array:
	return get_sorted_keys(dict)


# =============================================================================
# FLOAT OPERATIONS
# =============================================================================

## Fix float precision to a fixed number of decimal places.
## @param value: Float value to fix
## @param decimal_places: Number of decimal places to keep
## @return: Float with fixed precision
static func fix_precision(value: float, decimal_places: int = SimConstants.FLOAT_PRECISION_DIGITS) -> float:
	var multiplier: float = pow(10.0, decimal_places)
	return roundf(value * multiplier) / multiplier


## Compare two floats with epsilon.
## @param a: First float
## @param b: Second float
## @param epsilon: Comparison epsilon (default from constants)
## @return: true if floats are equal within epsilon
static func floats_equal(a: float, b: float, epsilon: float = SimConstants.FLOAT_EPSILON) -> bool:
	return absf(a - b) <= epsilon


## Check if float is effectively zero.
## @param value: Float to check
## @param epsilon: Comparison epsilon
## @return: true if value is close to zero
static func is_effectively_zero(value: float, epsilon: float = SimConstants.FLOAT_EPSILON) -> bool:
	return absf(value) <= epsilon


## Safe division that returns default on division by zero.
## @param numerator: Numerator
## @param denominator: Denominator
## @param default_value: Value to return if denominator is zero
## @return: numerator / denominator or default_value
static func safe_divide(numerator: float, denominator: float, default_value: float = 0.0) -> float:
	if is_effectively_zero(denominator):
		return default_value
	return numerator / denominator


## Clamp float to valid range, handling NaN.
## @param value: Value to clamp
## @param min_val: Minimum value
## @param max_val: Maximum value
## @param default_value: Value to use if input is NaN
## @return: Clamped value
static func safe_clamp(value: float, min_val: float, max_val: float, default_value: float = 0.0) -> float:
	if is_nan(value):
		return default_value
	return clampf(value, min_val, max_val)


# =============================================================================
# VECTOR OPERATIONS
# =============================================================================

## Safely normalize a vector, returning default if zero-length.
## @param vec: Vector to normalize
## @param default: Default value if vec is zero
## @return: Normalized vector or default
static func safe_normalize(vec: Vector2, default: Vector2 = Vector2.RIGHT) -> Vector2:
	if vec.length_squared() <= SimConstants.FLOAT_EPSILON:
		return default
	return vec.normalized()


## Get angle between two vectors in range [0, PI].
## @param a: First vector
## @param b: Second vector
## @return: Angle in radians
static func angle_between(a: Vector2, b: Vector2) -> float:
	var dot: float = a.dot(b)
	var len_product: float = a.length() * b.length()
	
	if len_product <= SimConstants.FLOAT_EPSILON:
		return 0.0
	
	var cos_angle: float = clampf(dot / len_product, -1.0, 1.0)
	return acos(cos_angle)


# =============================================================================
# SORTING OPERATIONS
# =============================================================================

## Sort array of nodes by sim_id deterministically.
## @param nodes: Array of nodes to sort
## @return: Sorted array (new array, input not modified)
static func sort_by_sim_id(nodes: Array) -> Array:
	var result: Array = nodes.duplicate()
	result.sort_custom(func(a: Node, b: Node) -> bool:
		var id_a: int = a.sim_id if "sim_id" in a else 0
		var id_b: int = b.sim_id if "sim_id" in b else 0
		return id_a < id_b
	)
	return result


## Sort array of nodes by distance to a point.
## @param nodes: Array of nodes
## @param point: Reference point
## @return: Sorted array (closest first)
static func sort_by_distance(nodes: Array, point: Vector2) -> Array:
	var result: Array = nodes.duplicate()
	result.sort_custom(func(a: Node, b: Node) -> bool:
		var pos_a: Vector2 = a.position if "position" in a else Vector2.ZERO
		var pos_b: Vector2 = b.position if "position" in b else Vector2.ZERO
		
		var dist_a: float = pos_a.distance_squared_to(point)
		var dist_b: float = pos_b.distance_squared_to(point)
		
		if not floats_equal(dist_a, dist_b):
			return dist_a < dist_b
		
		# Tie-breaker: sim_id
		var id_a: int = a.sim_id if "sim_id" in a else 0
		var id_b: int = b.sim_id if "sim_id" in b else 0
		return id_a < id_b
	)
	return result


## Sort array with custom comparator and automatic tie-breaking.
## @param array: Array to sort
## @param comparator: Custom comparison function
## @param tie_breaker_property: Property to use for tie-breaking (default "sim_id")
## @return: Sorted array
static func sort_with_tie_breaker(array: Array, comparator: Callable, tie_breaker_property: String = "sim_id") -> Array:
	var result: Array = array.duplicate()
	
	result.sort_custom(func(a, b) -> bool:
		var cmp_result: int = comparator.call(a, b)
		
		if cmp_result < 0:
			return true
		if cmp_result > 0:
			return false
		
		# Tie - use tie-breaker property
		if tie_breaker_property in a and tie_breaker_property in b:
			return a.get(tie_breaker_property) < b.get(tie_breaker_property)
		
		return false
	)
	
	return result


# =============================================================================
# HASHING AND CHECKSUMS
# =============================================================================

## Hash combine function (FNV-like).
## @param seed: Current hash value
## @param value: Value to mix in
## @return: Combined hash
static func hash_combine(seed: int, value: int) -> int:
	return (seed ^ value) * 16777619


## Hash a float to an integer.
## @param value: Float to hash
## @param precision: Decimal places to consider
## @return: Integer hash
static func hash_float(value: float, precision: int = SimConstants.FLOAT_PRECISION_DIGITS) -> int:
	return int(roundf(value * pow(10.0, precision)))


## Hash a Vector2 to an integer.
## @param vec: Vector to hash
## @return: Integer hash
static func hash_vector2(vec: Vector2) -> int:
	var h: int = 0
	h = hash_combine(h, hash_float(vec.x))
	h = hash_combine(h, hash_float(vec.y))
	return h


## Compute simple checksum for an array of nodes.
## @param nodes: Array of nodes to checksum
## @param tick: Current tick (included in checksum)
## @return: Checksum value
static func compute_nodes_checksum(nodes: Array, tick: int) -> int:
	var checksum: int = tick
	
	# Sort by sim_id for determinism
	var sorted_nodes: Array = sort_by_sim_id(nodes)
	
	for node in sorted_nodes:
		if "sim_id" in node:
			checksum = hash_combine(checksum, node.sim_id)
		if "position" in node:
			checksum = hash_combine(checksum, hash_vector2(node.position))
		if "health" in node:
			checksum = hash_combine(checksum, hash_float(node.health))
		if "team" in node:
			checksum = hash_combine(checksum, node.team)
	
	return checksum


# =============================================================================
# RANDOM SELECTION (Deterministic)
# =============================================================================

## Select a random element from array using deterministic RNG.
## @param array: Array to select from
## @param rng: Deterministic RNG
## @return: Random element or null if array is empty
static func random_select(array: Array, rng: SimInterfaces.DeterministicRng):
	if array.is_empty():
		return null
	var index: int = rng.random_int(0, array.size() - 1)
	return array[index]


## Shuffle array deterministically.
## @param array: Array to shuffle
## @param rng: Deterministic RNG
## @return: New shuffled array (input not modified)
static func deterministic_shuffle(array: Array, rng: SimInterfaces.DeterministicRng) -> Array:
	var result: Array = array.duplicate()
	var n: int = result.size()
	
	for i in range(n - 1, 0, -1):
		var j: int = rng.random_int(0, i)
		var temp = result[i]
		result[i] = result[j]
		result[j] = temp
	
	return result


## Weighted random selection.
## @param items: Array of items
## @param weights: Array of weights (same size as items)
## @param rng: Deterministic RNG
## @return: Selected item or null
static func weighted_random_select(items: Array, weights: Array[float], rng: SimInterfaces.DeterministicRng):
	if items.is_empty() or weights.is_empty() or items.size() != weights.size():
		return null
	
	var total_weight: float = 0.0
	for w in weights:
		total_weight += w
	
	if total_weight <= 0.0:
		return items[0]
	
	var random_value: float = rng.random_float() * total_weight
	var cumulative: float = 0.0
	
	for i in range(items.size()):
		cumulative += weights[i]
		if random_value <= cumulative:
			return items[i]
	
	return items[items.size() - 1]
