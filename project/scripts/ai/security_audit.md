# IronCore Arena -- Combat System Security Audit

**Audit Date**: 2026-03-03
**Auditor**: Security Auditor Agent (PHASE 5)
**Scope**: All new/modified combat system code in project/src/, project/autoload/, project/scripts/ai/, project/data/
**Overall Risk Rating**: YELLOW

---

## Executive Summary Table

| Finding | File | Risk | Patched? |
|---------|------|------|----------|
| FINDING-1 | weapon_data.gd:116 | HIGH | YES |
| FINDING-2 | weapon_data.gd:109 | HIGH | YES |
| FINDING-3 | weapon_data.gd:152-160 | HIGH | YES |
| FINDING-4 | data_loader.gd:212 | HIGH | YES |
| FINDING-5 | data_loader.gd:175 | HIGH | YES |
| FINDING-6 | combat_resolver.gd:59 | MEDIUM | NO |
| FINDING-7 | deterministic_rng.gd:79 | LOW | NO |
| FINDING-8 | weapon_system.gd:324 | LOW | NO |
| FINDING-9 | SimulationManager.gd:388-413 | LOW | NO |
| FINDING-10 | data_loader.gd:7 | MEDIUM | NO |
| FINDING-11 | weapon_data.gd:140 | MEDIUM | NO |
| FINDING-12 | weapon_system.gd:579 | LOW | NO |

**Summary**: 5 HIGH, 3 MEDIUM, 4 LOW. All 5 HIGH findings patched directly in source.

---

## Detailed Findings

### FINDING-1: Unvalidated tags and ai_hints allow arbitrary data injection
```
File: project/src/systems/weapon_data.gd:116-117
Risk: HIGH
```

**Description**: `from_dict()` copies `tags` and `ai_hints` from parsed JSON without any validation. A crafted weapons.json could inject arbitrary data types (nested dictionaries, arrays with thousands of elements, deeply nested objects) into these fields. While GDScript does not execute arbitrary strings, oversized or deeply nested structures could cause memory exhaustion or unexpected behavior in downstream AI systems that iterate over `ai_hints`.

**Exploit Scenario**: An attacker modifies weapons.json to include:
```json
"ai_hints": {"preferred_range": "<script>", "evil_key": {"nested": {"deep": "...1000 levels..."}}}
"tags": [1, 2, 3, null, {"obj": true}, "...10000 entries..."]
```
This could crash the engine via stack overflow on deep nesting, or cause UI rendering issues if tags are displayed as strings.

**Patch**: Applied. Tags now validated against an allowlist of 12 known values. `ai_hints` restricted to known keys (`preferred_range`, `role_affinity`) with enum-validated values. All other keys silently dropped.

---

### FINDING-2: Effects array entries not validated in from_dict() -- unbounded magnitudes
```
File: project/src/systems/weapon_data.gd:109-114
Risk: HIGH
```

**Description**: `from_dict()` copies effect dictionaries verbatim from JSON with only an `is Dictionary` check. There is no validation of effect `type` (could be any string), `magnitude` (could be 999999.0), `duration_ticks` (could be MAX_INT), or `stacking` rule. The `is_valid()` function does not check the effects array at all.

**Exploit Scenario**: A crafted weapons.json with:
```json
"effects": [{"type": "burn", "magnitude": 999999.0, "duration_ticks": 999999, "apply_chance": 1.0}]
```
Would pass `is_valid()` and create a weapon that kills any target instantly via burn damage, or a weapon with `{"type": "stun", "duration_ticks": 999999}` that permanently stuns targets.

**Patch**: Applied. Each effect entry is now rebuilt from scratch with:
- `type` validated against allowlist: `["slow", "stun", "burn", "emp", "armor_break"]`
- `magnitude` clamped to `[0.0, 1.0]`
- `duration_ticks` clamped to `[1, 600]`
- `tick_interval` clamped to `[0, 60]`
- `stacking` validated against `["replace", "refresh", "stack"]`
- `max_stacks` clamped to `[1, 5]`
- `apply_chance` clamped to `[0.01, 1.0]`
- Invalid entries silently dropped

---

### FINDING-3: Incomplete is_valid() bounds checking -- multiple fields unchecked
```
File: project/src/systems/weapon_data.gd:152-160
Risk: HIGH
```

**Description**: `is_valid()` only checks 13 of ~25+ numeric fields. Missing checks for: `range_min`, `range_optimal`, `range_max` (upper bounds), `splash_radius`, `splash_falloff`, `spread_angle`, `projectile_speed`, `projectile_radius`, `heat_per_shot`, `heat_dissipation_per_tick`, `overheat_threshold` (upper bound), `overheat_lockout_ticks`, `burst_delay_ticks`, and `effects.size()`. A weapon could pass validation with `splash_radius: 99999` or `projectile_speed: 999999`.

**Exploit Scenario**: A weapon with `splash_radius: 5000.0` would hit every bot on the arena in a single shot. A weapon with `projectile_speed: 999999.0` combined with `range_max: 99999` would effectively be hitscan. `heat_dissipation_per_tick: 999.0` would make overheating impossible.

**Patch**: Applied. Added bounds checks for all remaining fields matching the JSON schema constraints:
- `range_min`: [0, 100], `range_optimal`: [10, 800], `range_max`: [20, 1200]
- `splash_radius`: [0, 200], `splash_falloff`: [0.5, 3.0]
- `spread_angle`: [0, 45], `projectile_speed`: [0, 2000], `projectile_radius`: [1, 30]
- `heat_per_shot`: [0, 50], `heat_dissipation_per_tick`: [0, 5.0]
- `overheat_threshold`: [10, 200], `overheat_lockout_ticks`: [30, 600]
- `burst_delay_ticks`: [0, 30], `effects.size()`: max 3

---

### FINDING-4: No file size limit on JSON loading -- DoS via oversized data file
```
File: project/src/managers/data_loader.gd:212-222
Risk: HIGH
```

**Description**: `_read_file()` reads the entire file into memory without checking file size. A replaced weapons.json or components.json file of several hundred MB would cause the engine to freeze or crash with out-of-memory.

**Exploit Scenario**: Attacker replaces `weapons.json` with a 500MB file containing deeply nested JSON. The JSON parser attempts to parse the entire structure, exhausting memory and crashing the game on startup.

**Patch**: Applied. Added `MAX_FILE_SIZE = 2 * 1024 * 1024` (2MB) check via `file.get_length()` before reading. Files exceeding this limit are rejected with an error.

---

### FINDING-5: No cap on weapon array size in _load_weapons_json()
```
File: project/src/managers/data_loader.gd:175-178
Risk: HIGH
```

**Description**: After parsing, `_load_weapons_json()` iterates over every entry in the weapons array and creates WeaponData resources for each. A JSON array with 100,000 entries would create 100,000 Resource objects, exhausting memory even if the file is under the size cap.

**Exploit Scenario**: Craft a weapons.json with 50,000 minimal weapon entries. Each creates a WeaponData resource. Combined with the weapon_data_cache dictionary, this consumes significant memory and slows all DataLoader queries.

**Patch**: Applied. Added `MAX_WEAPON_ENTRIES = 200` cap. Arrays exceeding this size are rejected with an error.

---

### FINDING-6: Resist key constructed from user-controlled damage_type string
```
File: project/src/systems/combat_resolver.gd:59
Risk: MEDIUM
```

**Description**: `var resist_key: String = "resist_" + weapon.damage_type` constructs a dictionary lookup key from the weapon's `damage_type`. If `damage_type` is not one of `["ballistic", "energy", "explosive"]`, the lookup would attempt to read a non-existent key. While `target_bot.get(resist_key, 0.0)` safely returns 0.0 for missing keys (meaning zero resistance = full damage), this means a weapon with an invalid damage_type like `"magic"` would bypass all armor.

**Exploit Scenario**: If `is_valid()` were bypassed (e.g., legacy weapon not through weapons.json path), a weapon with `damage_type: "piercing"` would ignore all resistances since no bot has `resist_piercing`. However, `is_valid()` now strictly checks `damage_type` against the enum, making this a secondary concern.

**Mitigation**: The `is_valid()` check (FINDING-3 patch) prevents invalid damage_types from entering the system. No code patch needed beyond the existing validation.

---

### FINDING-7: Modulo bias in DeterministicRng.next_int_range()
```
File: project/src/systems/deterministic_rng.gd:79
Risk: LOW
```

**Description**: `next_u32() % range_size` introduces modulo bias when `range_size` is not a power of 2. For a 32-bit RNG with range_size 3, values 0 and 1 are very slightly more likely than value 2 (by ~2^-32). For a game RNG this bias is negligible.

**Exploit Scenario**: Statistically negligible. Would require billions of samples to detect a ~0.00000002% bias.

**Mitigation**: Acceptable for game use. No patch needed.

---

### FINDING-8: Weapon data stored in projectile dictionary by reference
```
File: project/src/systems/weapon_system.gd:324
Risk: LOW
```

**Description**: `"weapon_data": weapon_data` stores a reference to the weapon data in each projectile dictionary. If weapon data is mutated after projectile creation (e.g., by another system or hot-reload), in-flight projectiles would use modified stats. This is a data integrity concern, not a direct security vulnerability.

**Exploit Scenario**: In normal gameplay, weapon data is read-only after loading. Risk only exists if a future system allows runtime weapon modification.

**Mitigation**: Acceptable current risk. If runtime weapon modification is added, projectiles should store a snapshot.

---

### FINDING-9: Checksum is not cryptographically strong
```
File: project/autoload/SimulationManager.gd:388-413
Risk: LOW
```

**Description**: The checkpoint checksum uses simple hash combining (`(a << 5 + a) ^ b`) which is not collision-resistant. An attacker who knows the algorithm could craft two different game states with the same checksum.

**Exploit Scenario**: In a competitive replay-verification scenario, a player could craft a modified replay that produces matching checksums. However, this requires knowledge of the exact hash algorithm and all intermediate states.

**Mitigation**: For local single-player simulation, this is acceptable. If competitive ranked play with server-side replay verification is added, upgrade to SHA-256 checksums.

---

### FINDING-10: COMPONENTS_PATH uses relative parent directory traversal
```
File: project/src/managers/data_loader.gd:7
Risk: MEDIUM
```

**Description**: `const COMPONENTS_PATH: String = "res://../data/components.json"` uses `..` to traverse above the `res://` root. While Godot's resource system restricts `res://` paths to the project directory, the `..` traversal is non-standard and its behavior may vary across platforms or export targets. In some configurations, this could read files outside the intended project directory.

**Exploit Scenario**: If the Godot project is deployed in a directory where `..` resolves to a user-writable location, an attacker could place a malicious `components.json` there. In practice, Godot's VFS typically prevents this, but the pattern is risky.

**Mitigation**: Recommend changing to `res://data/components.json` or an explicit absolute path. Current risk is medium because Godot's resource system provides some protection.

---

### FINDING-11: Validation allows damage_per_shot range [-500, 500] but schema says [1, 500]
```
File: project/src/systems/weapon_data.gd:140
Risk: MEDIUM
```

**Description**: `is_valid()` allows `damage_per_shot` in range `[-500.0, 500.0]` to support healing weapons (Repair Beam has -15). However, the JSON schema specifies `minimum: 1` for `damage_per_shot`. This inconsistency means the GDScript validation is more permissive than the schema. A weapon with `damage_per_shot: -500` would pass GDScript validation but violate the schema.

**Exploit Scenario**: A crafted weapon with `damage_per_shot: -500` and `projectile_type: "beam"` targeting allies would heal 500 HP per shot (if the heal path works), making a team nearly unkillable. However, `CombatResolver.resolve_hit()` clamps final damage to `[0, 9999]`, so negative damage becomes 0. The actual heal mechanic would need a separate code path.

**Mitigation**: The mismatch should be resolved. Either update the schema to allow negative values for heal weapons, or tighten validation to require `damage_per_shot >= 1` for non-support weapons. Current risk is medium because the combat resolver already clamps negative damage to 0.

---

### FINDING-12: _apply_damage converts float to int, discarding fractional damage
```
File: project/src/systems/weapon_system.gd:579
Risk: LOW
```

**Description**: `var dmg: int = int(clampf(amount, 0.0, MAX_DAMAGE))` truncates fractional damage. A weapon dealing 0.9 damage per shot would deal 0 damage per hit. This is a design choice but could cause unexpected behavior with very low damage weapons.

**Exploit Scenario**: Not exploitable. Weapons must deal >= 1.0 raw damage to have any effect. Low-damage weapons with high fire rate would appear to deal damage based on stats but have reduced effective DPS.

**Mitigation**: Acceptable design choice. Document that effective damage is integer.

---

## Audit Areas -- No Findings

### JSON Injection Safety
Godot's `JSON.parse()` returns only data types (Dictionary, Array, String, float, int, bool, null). There is no `eval()`, no code execution from JSON, and no prototype pollution. **SAFE**.

### Resource Injection (load/preload paths)
All `preload()` calls in the audited files use string literals (`"res://..."` constants). No `load()` calls use data-driven paths from JSON. `DataLoader` reads JSON text, not `.gd`/`.tscn` resources. **SAFE**.

### AI Interface Hooks
`ai_hints` fields are read-only data used for AI decision-making (preferred_range enum, role_affinity array). No field is passed to `eval()`, `Expression`, `call()`, `callv()`, or any code execution mechanism. After FINDING-1 patch, only allowlisted keys/values are preserved. **SAFE**.

### Replay Safety
The `DeterministicRng` (xorshift32) produces identical sequences for identical seeds. Seed=0 is mapped to seed=1 (preventing the xorshift degenerate zero-state). Seed space is 32-bit (4 billion values). No seed value causes degenerate output or reduced period. **SAFE**.

### Hash Integrity
Checksums are computed at runtime for replay verification (not loaded from files). No SHA-256 hashes are stored or verified. The checkpoint system uses a simple hash combine, which is adequate for local replay comparison but not for adversarial scenarios (see FINDING-9). **ACCEPTABLE**.

---

## Patches Applied

All 5 HIGH findings have been patched directly in the source files:

### Patch 1: weapon_data.gd -- Tags and ai_hints validation
**Lines 116-145 (after patch)**
Tags validated against 12-entry allowlist. `ai_hints` restricted to `preferred_range` (enum) and `role_affinity` (enum array). All unknown keys/values dropped.

### Patch 2: weapon_data.gd -- Effects array strict validation
**Lines 109-127 (after patch)**
Each effect rebuilt from scratch with type enum check, magnitude clamped [0,1], duration clamped [1,600], tick_interval clamped [0,60], stacking enum check, max_stacks clamped [1,5], apply_chance clamped [0.01,1.0].

### Patch 3: weapon_data.gd -- Complete is_valid() bounds checking
**Lines 152-193 (after patch)**
Added bounds checks for 15 previously unchecked fields, matching JSON schema constraints. Added effects.size() <= 3 check.

### Patch 4: data_loader.gd -- File size limit
**Line 212 (after patch)**
Added MAX_FILE_SIZE = 2MB check before reading any JSON file.

### Patch 5: data_loader.gd -- Weapon entry count cap
**Line 175 (after patch)**
Added MAX_WEAPON_ENTRIES = 200 cap on weapons.json array size.

---

## Overall Risk Rating: YELLOW

**Rationale**: The codebase had 5 HIGH-severity validation gaps that could allow crafted JSON data to inject oversized values, unbounded status effects, or arbitrary data structures into the combat system. All 5 have been patched. The remaining MEDIUM and LOW findings are acceptable risks for a single-player/local game. The code is free of critical vulnerabilities (no code injection, no resource injection, no eval of data). If competitive multiplayer with server-side verification is planned, FINDING-9 (weak checksums) and FINDING-10 (path traversal) should be addressed.
