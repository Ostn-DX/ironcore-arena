# Reusable Patterns: IronCore Arena Combat Framework

> Machine-readable pattern library extracted from the IronCore Arena weapon/combat
> system. Each pattern is self-contained and can be applied to a new game system
> by an automated agent without human guidance, provided the prerequisites are met
> and auto_apply_safe conditions hold.

---

# Pattern 1: Modular Stat Loading

## Metadata
- version: 1.0
- applies_to: [weapon systems, item systems, ability systems, unit stat systems, equipment systems]
- auto_apply_safe: true
- requires_human_review:
  - When the JSON schema introduces fields that affect game economy (cost, drop_rate)
  - When adding a new allowed enum value to an existing validated field
  - When the Resource class is subclassed or inherited by other systems

## Problem

Game systems need data-driven stat definitions that are:
1. Editable by designers without code changes (JSON files).
2. Validated at load time so invalid data never reaches runtime.
3. Accessible as typed GDScript Resources with computed derived fields.
4. Loaded once and cached via an autoload singleton.

Without this pattern, stats are scattered across code, hard to balance, and prone to
runtime errors from malformed data.

## Prerequisites

- Godot 4.x project with GDScript
- An autoload singleton node for data loading (e.g., `DataLoader`)
- A `data/` directory for JSON files
- The `FileAccess` and `JSON` classes available (standard Godot)

## Template

### GDScript Resource Class

```gdscript
class_name {SystemName}Data extends Resource
## Data resource for a single {system_name} definition.
## Loaded from JSON via from_dict() factory method.

# Identity
@export var id: String = ""
@export var name: String = ""
@export var category: String = "{system_name}"
@export var tier: int = 1

# --- Domain-specific stat groups ---
# Group 1: Core stats
@export var stat_a: float = 0.0
@export var stat_b: float = 0.0

# Group 2: Secondary stats
@export var stat_c: int = 0

# Group 3: Sub-objects (validated arrays)
@export var effects: Array = []

# Group 4: Tags and hints
@export var tags: Array = []
@export var ai_hints: Dictionary = {}

# Derived (computed, not stored in JSON)
var derived_stat: float = 0.0


static func from_dict(d: Dictionary) -> {SystemName}Data:
	## Factory: build a {SystemName}Data from a JSON-parsed dictionary.
	var obj := {SystemName}Data.new()
	obj.id = str(d.get("id", ""))
	obj.name = str(d.get("name", ""))
	obj.category = str(d.get("category", "{system_name}"))
	obj.tier = int(d.get("tier", 1))

	obj.stat_a = float(d.get("stat_a", 0.0))
	obj.stat_b = float(d.get("stat_b", 0.0))
	obj.stat_c = int(d.get("stat_c", 0))

	# Validate sub-objects strictly
	var raw_effects: Array = d.get("effects", [])
	var allowed_types: Array = ["type_a", "type_b", "type_c"]
	obj.effects = []
	for e in raw_effects:
		if not (e is Dictionary):
			continue
		var etype: Variant = e.get("type", "")
		if not (etype is String) or not (etype in allowed_types):
			continue
		var safe: Dictionary = {
			"type": etype,
			"magnitude": clampf(float(e.get("magnitude", 0.0)), 0.0, 1.0),
			"duration": clampi(int(e.get("duration", 60)), 1, 600),
		}
		obj.effects.append(safe)

	# Validate tags against allowlist
	var raw_tags: Array = d.get("tags", [])
	var allowed_tags: Array = ["tag_a", "tag_b", "tag_c"]
	obj.tags = []
	for tag in raw_tags:
		if tag is String and tag in allowed_tags:
			obj.tags.append(tag)

	# Compute derived stats
	if obj.stat_b > 0.0:
		obj.derived_stat = obj.stat_a * obj.stat_b
	else:
		obj.derived_stat = 0.0

	return obj


func is_valid() -> bool:
	## Validate required fields and value ranges.
	if id.is_empty() or not id.begins_with("{prefix}_"):
		return false
	if name.is_empty():
		return false
	if category != "{system_name}":
		return false
	if tier < 1 or tier > 5:
		return false
	if stat_a < 0.0 or stat_a > 999.0:
		return false
	if effects.size() > 3:
		return false
	return true
```

### JSON Schema Template

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "array",
  "items": {
    "type": "object",
    "required": ["id", "name", "category", "tier"],
    "properties": {
      "id": {
        "type": "string",
        "pattern": "^{prefix}_[a-z0-9_]+$"
      },
      "name": { "type": "string", "minLength": 1 },
      "category": { "type": "string", "enum": ["{system_name}"] },
      "tier": { "type": "integer", "minimum": 1, "maximum": 5 },
      "stat_a": { "type": "number", "minimum": 0, "maximum": 999 },
      "stat_b": { "type": "number", "minimum": 0, "maximum": 999 },
      "stat_c": { "type": "integer", "minimum": 0 },
      "effects": {
        "type": "array",
        "maxItems": 3,
        "items": {
          "type": "object",
          "required": ["type"],
          "properties": {
            "type": { "type": "string", "enum": ["type_a", "type_b", "type_c"] },
            "magnitude": { "type": "number", "minimum": 0, "maximum": 1 },
            "duration": { "type": "integer", "minimum": 1, "maximum": 600 }
          }
        }
      },
      "tags": {
        "type": "array",
        "items": { "type": "string", "enum": ["tag_a", "tag_b", "tag_c"] }
      }
    }
  }
}
```

### JSON Data File Template

```json
[
  {
    "id": "{prefix}_example_t1",
    "name": "Example Item",
    "category": "{system_name}",
    "tier": 1,
    "stat_a": 10.0,
    "stat_b": 2.0,
    "stat_c": 5,
    "effects": [
      {
        "type": "type_a",
        "magnitude": 0.5,
        "duration": 120
      }
    ],
    "tags": ["tag_a"]
  }
]
```

## Integration Steps

1. Create `project/src/systems/{system_name}_data.gd` with the Resource class above.
2. Create `project/data/{system_name}/{system_name}s.json` with the JSON data array.
3. Optionally create `project/schemas/{system_name}.schema.json` for external validation.
4. In the DataLoader core class (`project/src/managers/data_loader.gd`), add:
   ```gdscript
   var _{system_name}_cache: Dictionary = {}  # id -> {SystemName}Data
   var _{system_name}_list: Array = []

   func _load_{system_name}s() -> void:
       var file := FileAccess.open("res://data/{system_name}/{system_name}s.json", FileAccess.READ)
       if file == null:
           push_error("Cannot open {system_name}s.json")
           return
       var json := JSON.new()
       if json.parse(file.get_as_text()) != OK:
           push_error("JSON parse error: " + json.get_error_message())
           return
       for entry in json.data:
           var obj := {SystemName}Data.from_dict(entry)
           if obj.is_valid():
               _{system_name}_cache[obj.id] = obj
               _{system_name}_list.append(obj)
           else:
               push_warning("Invalid {system_name}: " + str(entry.get("id", "unknown")))

   func get_{system_name}(id: String) -> {SystemName}Data:
       return _{system_name}_cache.get(id, null)

   func get_all_{system_name}s() -> Array:
       return _{system_name}_list.duplicate()

   func get_{system_name}s_by_tier(tier: int) -> Array:
       var result: Array = []
       for obj in _{system_name}_list:
           if obj.tier == tier:
               result.append(obj)
       return result
   ```
5. In the DataLoader autoload wrapper (`project/autoload/DataLoader.gd`), add pass-through methods:
   ```gdscript
   func get_{system_name}(id: String):
       return _core.get_{system_name}(id)

   func get_all_{system_name}s() -> Array:
       return _core.get_all_{system_name}s()
   ```
6. Call `_load_{system_name}s()` inside `DataLoaderCore.load_all()`.

## Validation Checklist

- [ ] JSON file parses without errors
- [ ] All entries pass `is_valid()` after `from_dict()`
- [ ] Unknown JSON fields do not crash `from_dict()` (tested with extra keys)
- [ ] Empty dictionary input produces valid defaults without crash
- [ ] Sub-object arrays (effects) are deep-copied, not shared references
- [ ] Invalid enum values in effects/tags are silently dropped
- [ ] Numeric fields are clamped to safe ranges during parsing
- [ ] `DataLoader.get_{system_name}(id)` returns correct resource after load
- [ ] `DataLoader.get_all_{system_name}s()` returns all valid entries
- [ ] Derived stats are computed correctly from base stats

## Known Risks

- Adding a new field to JSON without updating `from_dict()` silently ignores the field.
  Always update both in tandem.
- Float precision: `from_dict()` uses `float()` casts. For integer-only fields, use `int()`.
- Allowlists for enums (tags, effect types) must be updated in code when new values are added
  to JSON. This is intentional -- it prevents typo injection from data files.

## Examples (from this codebase)

- Resource class: `project/src/systems/weapon_data.gd` (WeaponData)
- JSON data: `project/data/weapons/weapons.json` (12 weapon variants)
- DataLoader integration: `project/autoload/DataLoader.gd` (pass-through to core)
- Validation tests: `project/tests/test_weapon_data.gd` (40+ test cases)

---

# Pattern 2: Deterministic Simulation Unit

## Metadata
- version: 1.0
- applies_to: [combat systems, movement systems, physics simulations, card game resolvers, turn-based systems, multiplayer game state]
- auto_apply_safe: false
- requires_human_review:
  - Always review when integrating into an existing simulation loop
  - When the system makes RNG calls (verify call order is deterministic)
  - When the system iterates over dictionaries or unordered collections

## Problem

Game simulations must produce identical results given the same seed so that:
1. Replays work (store seed + inputs, replay produces same output).
2. Multiplayer can use lockstep or rollback networking.
3. Balance testing produces reproducible results.
4. Debug scenarios are repeatable.

Without this pattern, floating-point drift, non-deterministic iteration order, or
accidental use of system RNG breaks reproducibility.

## Prerequisites

- A `DeterministicRng` class using xorshift32 (or equivalent seedable PRNG)
- A fixed-timestep tick loop (not frame-rate dependent)
- All entities addressable by a sortable integer ID (`sim_id`)
- No use of Godot's `randf()`, `randi()`, `RandomNumberGenerator`, `Time.get_*()`,
  or physics engine results in the simulation path

## Template

### DeterministicRng Class

```gdscript
class_name DeterministicRng extends RefCounted
## Deterministic RNG using xorshift32. Same seed = same sequence.

const U32_MAX: int = 4294967296
var _state: int = 0

func _init(initial_seed: int = 0) -> void:
	if initial_seed != 0:
		seed(initial_seed)
	else:
		_state = 1

func seed(value: int) -> void:
	_state = value if value != 0 else 1

func next_u32() -> int:
	var x: int = _state
	x = x ^ ((x << 13) & 0xFFFFFFFF)
	x = x ^ ((x >> 17) & 0xFFFFFFFF)
	x = x ^ ((x << 5) & 0xFFFFFFFF)
	_state = x & 0xFFFFFFFF
	return _state

func next_float01() -> float:
	return float(next_u32()) / float(U32_MAX)

func next_float_range(min_val: float, max_val: float) -> float:
	return min_val + next_float01() * (max_val - min_val)

func next_int_range(min_val: int, max_val: int) -> int:
	var range_size: int = max_val - min_val + 1
	return min_val + int(next_u32() % range_size)

func get_state() -> int:
	return _state

func set_state(state: int) -> void:
	_state = state & 0xFFFFFFFF
```

### Deterministic System Template

```gdscript
extends RefCounted
class_name {SystemName}System
## Deterministic system called per-tick by SimulationManager.
## Returns event arrays. Fully deterministic -- no signals in hot path.

const TIMESTEP: float = 1.0 / 60.0

var _events: Array = []


func process_tick(entities: Array, rng: DeterministicRng,
		tick: int, dt: float) -> Array:
	## Main per-tick entry point. Returns array of event dictionaries.
	## entities must be sorted by sim_id before calling.
	_events.clear()

	# Phase 1: Update state
	for entity in entities:
		if not _is_active(entity):
			continue
		_update_state(entity, tick)

	# Phase 2: Resolve interactions (uses rng)
	for entity in entities:
		if not _is_active(entity):
			continue
		_resolve(entity, entities, rng, tick)

	return _events


func _is_active(entity) -> bool:
	if entity is Dictionary:
		return entity.get("is_alive", true)
	return entity.is_alive


func _update_state(entity, tick: int) -> void:
	# Tick-based timers, cooldowns, dissipation
	pass


func _resolve(entity, all_entities: Array, rng: DeterministicRng, tick: int) -> void:
	# Use rng for probabilistic outcomes
	var roll: float = rng.next_float01()
	# ... resolution logic ...
	_events.append({"type": "resolved", "entity_id": entity.get("sim_id", -1), "tick": tick})


func reset() -> void:
	_events.clear()
```

### Checkpoint / Replay Hashing Template

```gdscript
## Call every N ticks to record a verifiable state hash.
func _compute_checkpoint(entities: Array, rng: DeterministicRng, tick: int) -> int:
	var checksum: int = tick
	# Iterate in sim_id order (entities must be pre-sorted)
	for entity in entities:
		checksum = _hash_combine(checksum, entity.get("sim_id", 0))
		checksum = _hash_combine(checksum, _hash_float(float(entity.get("hp", 0))))
		var pos: Vector2 = entity.get("position", Vector2.ZERO)
		checksum = _hash_combine(checksum, _hash_float(pos.x))
		checksum = _hash_combine(checksum, _hash_float(pos.y))
	# Include RNG state
	checksum = _hash_combine(checksum, rng.get_state())
	return checksum

func _hash_combine(a: int, b: int) -> int:
	return (a * 16777619) ^ b

func _hash_float(val: float) -> int:
	return int(val * 10000.0)
```

### Tick Loop Integration Template

```gdscript
## In SimulationManager or equivalent:
const TICKS_PER_SECOND: float = 60.0
const DT: float = 1.0 / TICKS_PER_SECOND
const CHECKSUM_INTERVAL_TICKS: int = 60

var rng: DeterministicRng = null
var _checkpoints: Array = []

func start_battle(seed_val: int) -> void:
	rng = DeterministicRng.new(seed_val)
	_checkpoints.clear()

func _run_tick(tick: int) -> void:
	# Build sorted entity array for deterministic iteration
	var sorted_ids: Array = entities.keys()
	sorted_ids.sort()
	var sorted_entities: Array = []
	for id in sorted_ids:
		sorted_entities.append(entities[id])

	# Run systems in fixed order
	var events: Array = _system.process_tick(sorted_entities, rng, tick, DT)

	# Checkpoint
	if tick > 0 and tick % CHECKSUM_INTERVAL_TICKS == 0:
		var checksum: int = _compute_checkpoint(sorted_entities, rng, tick)
		_checkpoints.append({"tick": tick, "checksum": checksum})
```

## Integration Steps

1. Add `DeterministicRng` class to `project/src/systems/deterministic_rng.gd`.
2. Create the system class in `project/src/systems/{system_name}_system.gd` extending `RefCounted`.
3. In `SimulationManager`, instantiate one `DeterministicRng` at battle start with the match seed.
4. Pass the shared `rng` instance to every system's `process_tick()` call.
5. Sort all entity arrays by `sim_id` before passing to any system.
6. Add checkpoint computation at configurable intervals (default: every 60 ticks).
7. Store checkpoints in an array; expose `get_all_checkpoints()` for replay verification.
8. Write replay-determinism tests that run the same seed twice and compare all events.

## Validation Checklist

- [ ] Two runs with same seed produce identical event arrays
- [ ] Two runs with same seed produce identical per-tick RNG states
- [ ] Two runs with same seed produce identical checkpoint hashes at every interval
- [ ] Different seeds produce different results (sanity check)
- [ ] No NaN, Inf, or overflow values in any event field after 1000+ ticks
- [ ] No use of `randf()`, `randi()`, `RandomNumberGenerator`, or `Time.get_*()` in system code
- [ ] All dictionary/collection iterations are sorted by deterministic key
- [ ] Float operations use `clampf()` to prevent unbounded growth
- [ ] `is_nan()` and `is_inf()` guards on all damage/position calculations
- [ ] RNG state can be saved (`get_state()`) and restored (`set_state()`) for mid-sim resume

## Known Risks

- **Float precision drift across platforms**: Godot uses double-precision floats but results
  may differ between x86 and ARM. Mitigate with integer-scaled math for critical values
  and checkpoint verification every 1 second of game time.
- **Dictionary iteration order**: Godot 4 dictionaries maintain insertion order, but this is
  fragile. Always sort keys explicitly before iterating.
- **RNG call count mismatch**: If a code path conditionally calls `rng.next_float01()`,
  the call count diverges. Every branch that uses RNG must consume the same number of
  RNG calls regardless of outcome, OR the conditional must be itself deterministic.

## Examples (from this codebase)

- DeterministicRng: `project/src/systems/deterministic_rng.gd`
- WeaponSystem (deterministic tick system): `project/src/systems/weapon_system.gd`
- CombatResolver (pure function, no side effects): `project/src/systems/combat_resolver.gd`
- SimulationManager checkpoint: `project/autoload/SimulationManager.gd` lines 267-269, 388-414
- Replay determinism tests: `project/tests/test_replay_determinism.gd`
- RNG unit tests: `project/tests/test_deterministic_rng.gd`

---

# Pattern 3: Balance Simulation Harness

## Metadata
- version: 1.0
- applies_to: [weapon balance, ability balance, unit balance, card game balance, matchmaking tuning]
- auto_apply_safe: false
- requires_human_review:
  - When changing imbalance detection thresholds
  - When the report is used to auto-tune live game values
  - When adding new matchup dimensions (team size, map, items)

## Problem

Game designers need automated tooling to:
1. Run thousands of simulated matchups between all item/weapon/ability combinations.
2. Detect dominant strategies (win rate > threshold) and degenerate matchups (too fast/slow).
3. Produce structured reports that feed into tuning pipelines.
4. Do this reproducibly (deterministic seeds) so results are verifiable.

Without this pattern, balance is done by feel, playtest hours are wasted, and regressions
go undetected.

## Prerequisites

- Pattern 2 (Deterministic Simulation Unit) fully implemented
- A headless simulation that can run without rendering (RefCounted, not Node-based)
- Stat data loaded via Pattern 1 (Modular Stat Loading)
- At least 2 items/weapons/abilities to compare

## Template

### Duel Simulator (Generic)

```gdscript
extends RefCounted
class_name DuelSimulator
## Headless 1v1 simulation for balance testing.
## No Node dependencies. Uses inline xorshift32 RNG matching DeterministicRng.

const TIMESTEP: float = 1.0 / 60.0
const MAX_TICKS: int = 3600  # 60 seconds max
const DEFAULT_HP: float = 100.0


func run_duel(config_a: Dictionary, config_b: Dictionary, seed_val: int) -> Dictionary:
	## Simulate a 1v1 matchup. Returns: {winner, ttk_a, ttk_b, ticks}
	var rng := _Rng.new(seed_val)

	var entity_a: Dictionary = _make_entity(1, config_a)
	var entity_b: Dictionary = _make_entity(2, config_b)

	# Place entities at engagement range
	var engagement_range: float = _compute_engagement_range(config_a, config_b)
	entity_a["position_x"] = 0.0
	entity_b["position_x"] = engagement_range

	var ttk_a: float = -1.0
	var ttk_b: float = -1.0
	var tick: int = 0

	while tick < MAX_TICKS:
		# Entity A acts first (deterministic: lower sim_id first)
		if entity_a["hp"] > 0 and entity_b["hp"] > 0:
			_resolve_action(entity_a, entity_b, config_a, engagement_range, rng, tick)
		if entity_a["hp"] > 0 and entity_b["hp"] > 0:
			_resolve_action(entity_b, entity_a, config_b, engagement_range, rng, tick)

		# Check outcomes
		if entity_b["hp"] <= 0 and ttk_a < 0:
			ttk_a = float(tick + 1) * TIMESTEP
		if entity_a["hp"] <= 0 and ttk_b < 0:
			ttk_b = float(tick + 1) * TIMESTEP
		if entity_a["hp"] <= 0 or entity_b["hp"] <= 0:
			break
		tick += 1

	var winner: String = "draw"
	if entity_b["hp"] <= 0 and entity_a["hp"] > 0:
		winner = str(config_a.get("id", "a"))
	elif entity_a["hp"] <= 0 and entity_b["hp"] > 0:
		winner = str(config_b.get("id", "b"))
	elif entity_a["hp"] <= 0 and entity_b["hp"] <= 0:
		winner = str(config_a.get("id", "a"))  # First-processed wins ties

	return {"winner": winner, "ttk_a": ttk_a, "ttk_b": ttk_b, "ticks": tick + 1}


func run_batch(config_a: Dictionary, config_b: Dictionary,
		num_runs: int, base_seed: int) -> Dictionary:
	## Run num_runs duels and aggregate results.
	var a_wins: int = 0
	var b_wins: int = 0
	var draws: int = 0
	var winner_ttks: Array = []
	var id_a: String = str(config_a.get("id", "a"))
	var id_b: String = str(config_b.get("id", "b"))

	for i in range(num_runs):
		var result: Dictionary = run_duel(config_a, config_b, base_seed + i)
		if result["winner"] == id_a:
			a_wins += 1
			if result["ttk_a"] >= 0:
				winner_ttks.append(result["ttk_a"])
		elif result["winner"] == id_b:
			b_wins += 1
			if result["ttk_b"] >= 0:
				winner_ttks.append(result["ttk_b"])
		else:
			draws += 1

	return {
		"config_a_wins": a_wins,
		"config_b_wins": b_wins,
		"draws": draws,
		"avg_ttk_winner": _avg(winner_ttks),
		"ttk_variance": _variance(winner_ttks),
	}


func _make_entity(sim_id: int, config: Dictionary) -> Dictionary:
	return {
		"sim_id": sim_id,
		"hp": config.get("hp", DEFAULT_HP),
		"is_alive": true,
		"position_x": 0.0,
		# Add system-specific state here
	}


func _compute_engagement_range(config_a: Dictionary, config_b: Dictionary) -> float:
	var range_a: float = config_a.get("range_optimal", 100.0)
	var range_b: float = config_b.get("range_optimal", 100.0)
	return maxf(30.0, (range_a + range_b) / 2.0)


func _resolve_action(attacker: Dictionary, defender: Dictionary,
		config: Dictionary, distance: float, rng: _Rng, tick: int) -> void:
	# System-specific action resolution
	pass


func _avg(arr: Array) -> float:
	if arr.is_empty():
		return 0.0
	var total: float = 0.0
	for v in arr:
		total += float(v)
	return total / float(arr.size())


func _variance(arr: Array) -> float:
	if arr.size() < 2:
		return 0.0
	var mean: float = _avg(arr)
	var sum_sq: float = 0.0
	for v in arr:
		var diff: float = float(v) - mean
		sum_sq += diff * diff
	return sum_sq / float(arr.size())


## Inner RNG matching xorshift32 from DeterministicRng
class _Rng:
	var _state: int = 1

	func _init(seed_val: int) -> void:
		_state = seed_val if seed_val != 0 else 1

	func next_u32() -> int:
		var x: int = _state
		x = x ^ ((x << 13) & 0xFFFFFFFF)
		x = x ^ ((x >> 17) & 0xFFFFFFFF)
		x = x ^ ((x << 5) & 0xFFFFFFFF)
		_state = x & 0xFFFFFFFF
		return _state

	func next_float01() -> float:
		return float(next_u32()) / 4294967296.0
```

### Batch Runner / Balance Report Generator

```gdscript
extends RefCounted
class_name BalanceRunner
## Runs all pair combinations and produces a structured balance report.

const WIN_RATE_THRESHOLD: float = 0.70
const TTK_VARIANCE_THRESHOLD: float = 50.0
const TTK_TOO_FAST: float = 3.0
const TTK_TOO_SLOW: float = 30.0


func run_full_balance(configs: Array, runs_per_pair: int, base_seed: int) -> Dictionary:
	## Run all unique pair combinations: n*(n-1)/2 matchups.
	var sim := DuelSimulator.new()
	var pairs: Array = []
	var wins: Dictionary = {}
	var losses: Dictionary = {}

	for c in configs:
		var cid: String = str(c.get("id", ""))
		wins[cid] = 0
		losses[cid] = 0

	for i in range(configs.size()):
		for j in range(i + 1, configs.size()):
			var ca: Dictionary = configs[i]
			var cb: Dictionary = configs[j]
			var id_a: String = str(ca.get("id", ""))
			var id_b: String = str(cb.get("id", ""))

			var batch: Dictionary = sim.run_batch(ca, cb, runs_per_pair, base_seed)
			var total: int = batch["config_a_wins"] + batch["config_b_wins"] + batch["draws"]
			var wr_a: float = float(batch["config_a_wins"]) / float(total) if total > 0 else 0.5

			pairs.append({
				"config_a": id_a, "config_b": id_b,
				"config_a_wins": batch["config_a_wins"],
				"config_b_wins": batch["config_b_wins"],
				"draws": batch["draws"],
				"win_rate_a": wr_a,
				"win_rate_b": 1.0 - wr_a,
				"avg_ttk_winner": batch["avg_ttk_winner"],
				"ttk_variance": batch["ttk_variance"],
			})

			wins[id_a] += batch["config_a_wins"]
			wins[id_b] += batch["config_b_wins"]
			losses[id_a] += batch["config_b_wins"]
			losses[id_b] += batch["config_a_wins"]

	var flags: Array = detect_imbalance(pairs)

	return {
		"meta": {
			"runs_per_pair": runs_per_pair,
			"base_seed": base_seed,
			"total_duels": pairs.size() * runs_per_pair,
		},
		"pairs": pairs,
		"imbalance_flags": flags,
		"summary": {"flagged_pairs": flags.size()},
	}


func detect_imbalance(pairs: Array) -> Array:
	## Return array of imbalance flags based on thresholds.
	var flags: Array = []
	for pair in pairs:
		var wr_a: float = pair.get("win_rate_a", 0.5)
		var wr_b: float = pair.get("win_rate_b", 0.5)
		var avg_ttk: float = pair.get("avg_ttk_winner", 10.0)
		var ttk_var: float = pair.get("ttk_variance", 0.0)
		var pair_name: String = str(pair.get("config_a", "")) + " vs " + str(pair.get("config_b", ""))

		if wr_a > WIN_RATE_THRESHOLD:
			flags.append({"pair": pair_name, "flag": "IMBALANCED",
				"value": wr_a, "threshold": WIN_RATE_THRESHOLD,
				"detail": str(pair.get("config_a", "")) + " dominates"})
		if wr_b > WIN_RATE_THRESHOLD:
			flags.append({"pair": pair_name, "flag": "IMBALANCED",
				"value": wr_b, "threshold": WIN_RATE_THRESHOLD,
				"detail": str(pair.get("config_b", "")) + " dominates"})
		if ttk_var > TTK_VARIANCE_THRESHOLD:
			flags.append({"pair": pair_name, "flag": "HIGH_VARIANCE",
				"value": ttk_var, "threshold": TTK_VARIANCE_THRESHOLD})
		if avg_ttk > 0.0 and avg_ttk < TTK_TOO_FAST:
			flags.append({"pair": pair_name, "flag": "TOO_FAST",
				"value": avg_ttk, "threshold": TTK_TOO_FAST})
		if avg_ttk > TTK_TOO_SLOW:
			flags.append({"pair": pair_name, "flag": "TOO_SLOW",
				"value": avg_ttk, "threshold": TTK_TOO_SLOW})
	return flags
```

### Imbalance Detection Thresholds (with rationale)

| Threshold | Default | Rationale |
|-----------|---------|-----------|
| `WIN_RATE_THRESHOLD` | 0.70 (70%) | A 70/30 win rate means one option is clearly dominant. Below 60% is noise in small samples. Above 70% is statistically significant at n=100+. IronCore uses 55% for a tighter bound since it runs 10,000 duels. |
| `TTK_VARIANCE_THRESHOLD` | 50.0 | High variance means outcomes are coin-flip dependent rather than skill/build-dependent. Measured in squared seconds. |
| `TTK_TOO_FAST` | 3.0s | Sub-3-second kills feel unfair to the losing player; no time to react or reposition. |
| `TTK_TOO_SLOW` | 30.0s | Fights lasting over 30 seconds are boring and suggest both builds are too defensive. |

### Output Schema (balance_report.json)

```json
{
  "meta": {
    "runs_per_pair": 100,
    "base_seed": 12345,
    "total_duels": 6600
  },
  "pairs": [
    {
      "config_a": "wpn_mg_t1",
      "config_b": "wpn_laser_t1",
      "config_a_wins": 52,
      "config_b_wins": 45,
      "draws": 3,
      "win_rate_a": 0.52,
      "win_rate_b": 0.45,
      "avg_ttk_winner": 12.5,
      "ttk_variance": 8.3
    }
  ],
  "imbalance_flags": [
    {
      "pair": "wpn_railgun_t3 vs wpn_blade_t1",
      "flag": "IMBALANCED",
      "value": 0.85,
      "threshold": 0.70,
      "detail": "wpn_railgun_t3 dominates"
    }
  ],
  "summary": {
    "flagged_pairs": 3
  }
}
```

## Integration Steps

1. Create `project/scripts/ai/duel_simulator.gd` with the DuelSimulator class.
2. Create `project/scripts/ai/balance_runner.gd` with the BalanceRunner class.
3. Implement `_resolve_action()` in DuelSimulator with your system's combat logic (copied/simplified from the main system).
4. The DuelSimulator must use its own inline `_Rng` class (identical algorithm to `DeterministicRng`) to avoid depending on the main simulation stack.
5. Create a runner script or editor tool that:
   a. Loads all configs via DataLoader.
   b. Calls `BalanceRunner.run_full_balance(configs, 100, 12345)`.
   c. Writes the result to `project/scripts/ai/balance_report.json`.
6. Add imbalance detection thresholds as constants at the top of BalanceRunner.
7. Optionally create an `@tool EditorScript` (`project/tools/balance_report_tool.gd`) for one-click balance runs from the Godot editor.

## Validation Checklist

- [ ] `run_duel()` with same seed produces identical results across runs
- [ ] `run_batch()` with 100 runs produces statistically stable win rates (re-run variance < 5%)
- [ ] No matchup exceeds the win rate threshold (or is flagged if it does)
- [ ] Repair/healing-only configs are correctly excluded from combat matchups
- [ ] All TTK values are non-negative (no negative time-to-kill)
- [ ] Report JSON is valid and parseable
- [ ] Imbalance flags include both pair name and which config dominates
- [ ] Total duel count matches `n*(n-1)/2 * runs_per_pair` (excluding skipped pairs)

## Known Risks

- The DuelSimulator uses simplified combat logic (no projectile travel, no movement).
  This means the balance report reflects raw stat matchups, not tactical play. This is
  intentional for automated balance scanning but should not replace human playtesting.
- The inline `_Rng` class must exactly match the `DeterministicRng` algorithm. If the
  main RNG is updated, the simulator's inner RNG must be updated in tandem.
- High `runs_per_pair` counts (10,000+) may take minutes. Consider progress reporting.

## Examples (from this codebase)

- DuelSimulator: `project/scripts/ai/duel_simulator.gd`
- BalanceRunner: `project/scripts/ai/balance_runner.gd`
- Balance report output: `project/scripts/ai/balance_report.json`
- Editor tool: `project/scripts/balance/balance_report_tool.gd`

---

# Pattern 4: ECS-Lite Tick System

## Metadata
- version: 1.0
- applies_to: [combat systems, movement systems, status effect systems, AI decision systems, any per-tick game logic]
- auto_apply_safe: true
- requires_human_review:
  - When adding a new system to the tick pipeline (phase ordering matters)
  - When the system modifies shared state that other systems read in the same tick

## Problem

Game logic needs to be:
1. Split into independent, testable systems (not monolithic update functions).
2. Executed in a fixed deterministic order each tick.
3. Operable on plain data (Dictionaries or RefCounted objects), not Node trees.
4. Free of GC pressure in the hot loop (no allocations per tick).

The full ECS pattern (entity IDs, component stores, system queries) is overkill for a
Godot game with < 100 entities. This "ECS-Lite" variant keeps the benefits (data
separation, deterministic ordering, testability) without the boilerplate.

## Prerequisites

- A SimulationManager or equivalent tick loop owner
- Entity data as Dictionaries or lightweight RefCounted objects with a `sim_id` field
- Pattern 2 (Deterministic Simulation Unit) for RNG and ordering

## Template

### System Base Pattern

```gdscript
extends RefCounted
class_name {SystemName}System
## ECS-lite system. Called once per tick by SimulationManager.
## Operates on entity arrays. Returns events. No Node dependencies.

# Pre-allocated arrays reused each tick (avoids GC pressure)
var _events: Array = []
var _temp_set: Dictionary = {}  # Reusable scratch dictionary


func process_tick(entities: Array, rng: DeterministicRng,
		tick: int, dt: float, context: Dictionary = {}) -> Array:
	## Main entry point. entities MUST be sorted by sim_id.
	## context: additional data (arena_bounds, obstacle list, etc.)
	## Returns: Array of event Dictionaries.
	_events.clear()
	_temp_set.clear()

	# Phase 1: State update (no interactions)
	for entity in entities:
		if not _is_active(entity):
			continue
		_phase_update(entity, tick, dt)

	# Phase 2: Interaction resolution (may use rng)
	for entity in entities:
		if not _is_active(entity):
			continue
		_phase_resolve(entity, entities, rng, tick, context)

	# Phase 3: Cleanup (remove dead entities from mutable lists, etc.)
	_phase_cleanup(entities, tick)

	return _events


func _is_active(entity) -> bool:
	if entity is Dictionary:
		return entity.get("is_alive", true)
	return entity.is_alive


func _phase_update(entity, tick: int, dt: float) -> void:
	## Override: per-entity state updates (cooldowns, dissipation, timers).
	pass


func _phase_resolve(entity, all_entities: Array, rng: DeterministicRng,
		tick: int, context: Dictionary) -> void:
	## Override: entity-vs-entity interactions.
	pass


func _phase_cleanup(entities: Array, tick: int) -> void:
	## Override: remove dead projectiles, expire effects, etc.
	pass


func reset() -> void:
	## Call between battles to clear cached state.
	_events.clear()
	_temp_set.clear()
```

### SimulationManager Pipeline Template

```gdscript
## In SimulationManager:
var _systems: Array = []  # Ordered list of systems

func _ready() -> void:
	# Systems execute in this exact order every tick.
	# Order matters: AI decides -> Commands override -> Movement resolves
	# -> Weapons fire -> Status ticks -> Win/loss check
	_systems = [
		preload("res://src/systems/ai_system.gd").new(),
		preload("res://src/systems/command_system.gd").new(),
		preload("res://src/systems/movement_system.gd").new(),
		preload("res://src/systems/weapon_system.gd").new(),
		preload("res://src/systems/status_system.gd").new(),
	]

func _run_tick(tick: int) -> void:
	# Sort entities once per tick
	var sorted_ids: Array = entities.keys()
	sorted_ids.sort()
	var sorted_entities: Array = []
	for id in sorted_ids:
		sorted_entities.append(entities[id])

	# Run each system in order
	var context: Dictionary = {"arena_bounds": arena_bounds}
	for system in _systems:
		var events: Array = system.process_tick(sorted_entities, rng, tick, DT, context)
		_process_events(events)

	# Checkpoint
	if tick > 0 and tick % CHECKSUM_INTERVAL_TICKS == 0:
		_record_checkpoint(sorted_entities, rng, tick)
```

### Event Schema Convention

All systems emit events as flat Dictionaries with a required `type` key:

```gdscript
# Standard event fields:
{
	"type": "hit",           # Required. String identifier for the event type.
	"tick": 120,             # Required. Tick when the event occurred.
	"source_id": 1,          # Optional. sim_id of the acting entity.
	"target_id": 2,          # Optional. sim_id of the affected entity.
	# ... system-specific fields ...
}
```

Common event types across systems:
- `shot_fired`, `hit`, `kill`, `projectile_spawned`, `projectile_expired` (WeaponSystem)
- `moved`, `collision` (MovementSystem)
- `effect_applied`, `effect_expired`, `effect_tick` (StatusSystem)
- `command_issued` (CommandSystem)

## Integration Steps

1. Create each system as a `RefCounted` class in `project/src/systems/`.
2. Each system implements `process_tick()` returning an event array.
3. Pre-allocate `_events` and scratch arrays as instance variables (not local vars).
4. In SimulationManager, store systems in an ordered array.
5. Each tick: sort entities by `sim_id`, iterate systems in order, collect events.
6. Forward events to rendering/audio/stats layers via signals (outside the tick loop).
7. For testing: instantiate the system directly, pass mock entity arrays and a `DeterministicRng`. No Node tree needed.

## Validation Checklist

- [ ] Each system can be instantiated and tested without a Node tree
- [ ] `process_tick()` with empty entity array returns empty event array (no crash)
- [ ] Events contain required `type` and `tick` fields
- [ ] No heap allocations inside the per-entity loop (reuse `_events.clear()`, not `_events = []`)
- [ ] System order in SimulationManager matches design document
- [ ] Adding/removing a system does not break other systems (no cross-system coupling)
- [ ] `reset()` clears all cached state between battles

## Known Risks

- System execution order is implicit (array position). Document the order in the
  architecture summary. A swap can cause subtle bugs (e.g., status effects tick before
  damage is applied).
- Pre-allocated arrays (`_events`) mean the system is NOT thread-safe. Each system
  instance must be used by a single thread. This is fine for Godot's single-threaded
  _physics_process but matters if you add threading later.
- Dictionary-based entities are flexible but lack type safety. Typos in key names
  (e.g., `"postion"` vs `"position"`) cause silent bugs. Consider a `_get_float()`
  helper pattern (see WeaponSystem lines 530-564 in this codebase).

## Examples (from this codebase)

- WeaponSystem (full ECS-lite system): `project/src/systems/weapon_system.gd`
  - Phased processing: cooldowns (Phase 1), firing (Phase 2), projectile movement (Phase 3), hit detection (Phase 4), cleanup (Phase 5)
  - Pre-allocated `_events` and `_dead_set` arrays
  - Entity abstraction helpers (`_is_bot_alive`, `_get_position`, `_get_int_prop`)
  - WeaponData cache to avoid repeated `from_dict()` calls
- CombatResolver (pure static functions): `project/src/systems/combat_resolver.gd`
  - Stateless damage calculation with no side effects
  - Pre-computed resist key lookup (`_RESIST_KEYS` const Dictionary)
- SimulationManager pipeline: `project/autoload/SimulationManager.gd` lines 239-271
  - Sorted bot iteration, weapon system call, event forwarding, checkpoint

---

# Pattern 5: Defensive Data Parsing

## Metadata
- version: 1.0
- applies_to: [any system that loads external JSON, user-generated content, mod support, save files]
- auto_apply_safe: true
- requires_human_review:
  - When adding new allowed values to allowlists
  - When the data source is user-controlled (mods, custom maps, save files)

## Problem

JSON data files may contain:
1. Invalid types (string where int expected, nested object where flat value expected).
2. Out-of-range values (negative HP, accuracy > 1.0, damage overflow).
3. Injection via unexpected field values (malicious strings, deeply nested objects).
4. Unknown fields from newer schema versions or typos.

The parser must never crash, never propagate invalid state, and silently discard
bad data while loading valid data.

## Prerequisites

- GDScript 4.x
- A `from_dict()` factory method pattern (Pattern 1)

## Template

```gdscript
static func from_dict(d: Dictionary) -> {SystemName}Data:
	var obj := {SystemName}Data.new()

	# --- Rule 1: Type-safe extraction with defaults ---
	obj.id = str(d.get("id", ""))
	obj.name = str(d.get("name", ""))
	obj.damage = float(d.get("damage", 0.0))
	obj.count = int(d.get("count", 1))

	# --- Rule 2: Clamp numerics to safe ranges ---
	obj.damage = clampf(obj.damage, -500.0, 500.0)
	obj.count = clampi(obj.count, 1, 10)

	# --- Rule 3: Enum validation via allowlist ---
	var raw_type: Variant = d.get("type", "")
	var allowed_types: Array = ["melee", "ranged", "magic"]
	if raw_type is String and raw_type in allowed_types:
		obj.type = raw_type
	else:
		obj.type = "melee"  # Safe default

	# --- Rule 4: Sub-object array validation ---
	var raw_effects: Array = d.get("effects", [])
	var allowed_effect_types: Array = ["burn", "stun", "slow"]
	obj.effects = []
	for e in raw_effects:
		if not (e is Dictionary):
			continue  # Skip non-dict entries
		var etype: Variant = e.get("type", "")
		if not (etype is String) or not (etype in allowed_effect_types):
			continue  # Skip unknown effect types
		var safe_effect: Dictionary = {
			"type": etype,
			"magnitude": clampf(float(e.get("magnitude", 0.0)), 0.0, 1.0),
			"duration": clampi(int(e.get("duration", 60)), 1, 600),
		}
		obj.effects.append(safe_effect)

	# --- Rule 5: Tag array allowlist ---
	var raw_tags: Array = d.get("tags", [])
	var allowed_tags: Array = ["fast", "heavy", "support"]
	obj.tags = []
	for tag in raw_tags:
		if tag is String and tag in allowed_tags:
			obj.tags.append(tag)

	# --- Rule 6: Nested dictionary validation ---
	var raw_hints: Variant = d.get("hints", {})
	obj.hints = {}
	if raw_hints is Dictionary:
		var allowed_keys: Array = ["preferred_range", "role"]
		for key in allowed_keys:
			if raw_hints.has(key) and raw_hints[key] is String:
				obj.hints[key] = raw_hints[key]

	# --- Rule 7: Cap array sizes ---
	if obj.effects.size() > 3:
		obj.effects.resize(3)  # Truncate to max

	return obj
```

## Integration Steps

1. Apply these rules inside every `from_dict()` or data parsing method.
2. Use `d.get(key, default)` for every field access -- never `d[key]`.
3. Wrap every value with its expected type cast: `str()`, `float()`, `int()`.
4. Clamp all numerics immediately after extraction.
5. Validate enums against hardcoded allowlists.
6. For sub-object arrays, validate each element independently; skip invalid ones.
7. Write an `is_valid()` method that checks post-construction invariants.

## Validation Checklist

- [ ] `from_dict({})` produces a valid object with safe defaults (no crash)
- [ ] `from_dict({"unknown_key": "junk"})` does not crash or propagate unknown data
- [ ] `from_dict({"damage": "not_a_number"})` does not crash (type cast handles it)
- [ ] `from_dict({"effects": ["not_a_dict"]})` skips invalid entries
- [ ] `from_dict({"effects": [{"type": "unknown_type"}]})` skips invalid effect types
- [ ] `from_dict({"tags": [123, null, "valid_tag"]})` only keeps valid string tags
- [ ] Numeric values are clamped (e.g., damage=99999 becomes 500.0)
- [ ] `is_valid()` rejects objects with empty id, wrong category, out-of-range tier

## Known Risks

- `float("not_a_number")` in GDScript returns 0.0 (safe). `int("not_a_number")` returns
  0 (safe). But `str(null)` returns `"null"` which may be unexpected. Always check
  `Variant` type before string operations if the value might be null.
- Allowlists must be updated in code when new enum values are added. This is by design
  to prevent injection, but creates a maintenance burden.

## Examples (from this codebase)

- WeaponData.from_dict(): `project/src/systems/weapon_data.gd` lines 67-166
  - Effect validation with type check, allowlist, and clamping (lines 110-129)
  - Tag validation with allowlist (lines 131-141)
  - ai_hints nested dictionary validation (lines 143-158)
- WeaponData.is_valid(): `project/src/systems/weapon_data.gd` lines 169-227
  - 25+ range checks covering every numeric field

---

# Cross-Pattern Dependencies

```
Pattern 1 (Modular Stat Loading)
    |
    v
Pattern 5 (Defensive Data Parsing) -- applied inside Pattern 1's from_dict()
    |
    v
Pattern 2 (Deterministic Simulation Unit) -- consumes loaded data
    |
    +---> Pattern 4 (ECS-Lite Tick System) -- structures the simulation loop
    |
    +---> Pattern 3 (Balance Simulation Harness) -- runs headless sims using the same data + RNG
```

Recommended application order for a new game system:
1. Pattern 1 + Pattern 5 (data loading with defensive parsing)
2. Pattern 2 (deterministic RNG and tick loop)
3. Pattern 4 (system architecture)
4. Pattern 3 (balance testing harness)

---

# Auto-Apply Safety Summary

| Pattern | auto_apply_safe | Reason |
|---------|----------------|--------|
| 1. Modular Stat Loading | **true** | Low risk: creates new files, does not modify existing systems. Failures are caught by is_valid(). |
| 2. Deterministic Simulation Unit | **false** | Must integrate into existing tick loop. RNG call ordering affects all systems. Requires human review of integration points. |
| 3. Balance Simulation Harness | **false** | Threshold values affect balance decisions. Simplified combat model may not reflect actual gameplay. Results require human interpretation. |
| 4. ECS-Lite Tick System | **true** | Low risk: creates new RefCounted classes. Does not modify Node tree or existing code. Failures are isolated per-system. |
| 5. Defensive Data Parsing | **true** | Low risk: applied inside from_dict() methods. Failures result in safe defaults, never crashes. |
