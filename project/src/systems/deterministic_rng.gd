class_name DeterministicRng extends RefCounted

## Deterministic random number generator using xorshift32 algorithm.
##
## This RNG produces the same sequence of numbers given the same seed,
## ensuring reproducible behavior across different runs and platforms.
## Uses 32-bit unsigned integer arithmetic with proper masking.

## Maximum value for 32-bit unsigned integer (2^32)
const U32_MAX: int = 4294967296

## Internal state of the RNG
var _state: int = 0


func _init(initial_seed: int = 0) -> void:
	if initial_seed != 0:
		seed(initial_seed)
	else:
		_state = 1


## Seeds the RNG with the given value.
##
## A seed of 0 is automatically converted to 1 since xorshift
## requires a non-zero state.
##
## [param value] The seed value (any 32-bit integer)
func seed(value: int) -> void:
    _state = value if value != 0 else 1


## Returns the next unsigned 32-bit integer.
##
## Uses the xorshift32 algorithm which provides good statistical
## properties while being fast and simple.
##
## Returns: A pseudo-random integer in range [0, 2^32 - 1]
func next_u32() -> int:
    # xorshift32 algorithm with proper 32-bit masking
    var x: int = _state
    x = x ^ ((x << 13) & 0xFFFFFFFF)
    x = x ^ ((x >> 17) & 0xFFFFFFFF)
    x = x ^ ((x << 5) & 0xFFFFFFFF)
    _state = x & 0xFFFFFFFF
    return _state


## Returns a float in range [0, 1).
##
## Uses 32-bit precision division for consistent results.
##
## Returns: A pseudo-random float in range [0.0, 1.0)
func next_float01() -> float:
    return float(next_u32()) / float(U32_MAX)


## Returns a float in range [min_val, max_val).
##
## [param min_val] The minimum value (inclusive)
## [param max_val] The maximum value (exclusive)
## Returns: A pseudo-random float in the specified range
func next_float_range(min_val: float, max_val: float) -> float:
    return min_val + next_float01() * (max_val - min_val)


## Returns a random integer in range [min_val, max_val] (inclusive).
##
## [param min_val] The minimum value (inclusive)
## [param max_val] The maximum value (inclusive)
## Returns: A pseudo-random integer in the specified range
func next_int_range(min_val: int, max_val: int) -> int:
    if min_val > max_val:
        push_warning("DeterministicRng: min_val > max_val, swapping values")
        var temp: int = min_val
        min_val = max_val
        max_val = temp
    var range_size: int = max_val - min_val + 1
    return min_val + int(next_u32() % range_size)


## Returns a random boolean with given probability of being true.
##
## [param probability] Probability of returning true (0.0 to 1.0)
## Returns: true with the given probability
func next_bool(probability: float = 0.5) -> bool:
    return next_float01() < probability


## Returns a random Vector2 within the specified bounds.
##
## [param min_x] Minimum X value
## [param max_x] Maximum X value
## [param min_y] Minimum Y value
## [param max_y] Maximum Y value
## Returns: A random Vector2 within the bounds
func next_vector2_range(min_x: float, max_x: float, min_y: float, max_y: float) -> Vector2:
    return Vector2(
        next_float_range(min_x, max_x),
        next_float_range(min_y, max_y)
    )


## Returns a random Vector2 within a rectangle.
##
## [param rect] The rectangle defining the bounds
## Returns: A random Vector2 within the rectangle
func next_vector2_in_rect(rect: Rect2) -> Vector2:
    return Vector2(
        next_float_range(rect.position.x, rect.position.x + rect.size.x),
        next_float_range(rect.position.y, rect.position.y + rect.size.y)
    )


## Returns a random element from the given array.
##
## [param arr] The array to pick from
## Returns: A random element, or null if array is empty
func pick_random(arr: Array) -> Variant:
    if arr.is_empty():
        return null
    return arr[next_int_range(0, arr.size() - 1)]


## Shuffles the given array in-place using Fisher-Yates algorithm.
##
## [param arr] The array to shuffle
func shuffle(arr: Array) -> void:
    var n: int = arr.size()
    for i in range(n - 1, 0, -1):
        var j: int = next_int_range(0, i)
        var temp: Variant = arr[i]
        arr[i] = arr[j]
        arr[j] = temp


## Returns the current internal state for serialization.
##
## Returns: The current RNG state
func get_state() -> int:
    return _state


## Sets the internal state for deserialization.
##
## [param state] The state to restore
func set_state(state: int) -> void:
    _state = state & 0xFFFFFFFF


# --- Convenience aliases (matches task spec) ---

## Alias for next_u32().
func next_int() -> int:
    return next_u32()

## Alias for next_float01().
func next_float() -> float:
    return next_float01()

## Alias for next_float_range().
func next_range(min_val: float, max_val: float) -> float:
    return next_float_range(min_val, max_val)
