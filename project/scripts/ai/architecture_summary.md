# IronCore Arena -- Modular Combat Expansion: Architecture Summary

## 1. Architecture Summary

### Design Philosophy

The weapon system is a **data-driven, modular combat framework** built on three pillars:

1. **WeaponData Resources** -- All 12+ weapon variants are defined as JSON data (with optional GDScript Resource wrappers). No weapon behavior is hard-coded; stats, effects, projectile types, and damage formulas are driven entirely by data files and balance envelopes.

2. **Deterministic Tick-Based Resolution** -- Every combat calculation (firing, hit detection, damage, status effects) runs inside the fixed 60Hz simulation tick using the existing `DeterministicRng` (xorshift32). No calls to `randf()`, `Time.get_*()`, or Godot physics. All dictionary iterations sorted by key. All tie-breaks use `sim_id`.

3. **System-of-Systems ECS-Lite** -- The weapon system is one of several `RefCounted` systems (`WeaponSystem`, `MovementSystem`, `StatusSystem`, etc.) orchestrated by `SimulationManager`. Each system operates on `Bot` data objects; no system holds global singleton state beyond what `SimulationManager` provides.

### High-Level Flow

```
SimulationManager.process_tick(dt)
  |-- AISystem.process(bots, rng, tick)          // decide targets, set fire flags
  |-- CommandSystem.process(bots, tick)           // player commands override AI
  |-- MovementSystem.process(bots, arena, dt)     // velocity, collision, clamping
  |-- WeaponSystem.process(bots, projectiles, rng, tick, dt)
  |     |-- cooldown management (tick-based)
  |     |-- heat management (per-tick dissipation)
  |     |-- fire resolution (spawn projectiles)
  |     |-- projectile update (ballistic move, beam instant, melee instant)
  |     |-- hit detection (circle-circle, deterministic iteration by sim_id)
  |     |-- damage calculation (base * falloff * (1 - resist) * crit)
  |     |-- status effect application (delegated to StatusSystem)
  |     +-- projectile cleanup
  |-- StatusSystem.process(bots, tick)            // tick effects, expiry, stacking
  |-- WinLossManager.check(bots, tick)            // end conditions
  +-- checkpoint (every CHECKSUM_INTERVAL_TICKS)
```

### Weapon Categories

The 12 weapon variants span 4 archetypes across 3 tiers:

| Archetype   | T1 Variant         | T2 Variant           | T3 Variant             |
|-------------|---------------------|----------------------|------------------------|
| Ballistic   | Light Machine Gun   | Gatling Cannon       | Railgun                |
| Energy      | Beam Cutter         | Plasma Repeater      | Arc Disruptor          |
| Explosive   | Micro Rocket Pod    | Grenade Launcher     | Siege Mortar           |
| Melee/Util  | Shock Blade         | Repair Beam          | EMP Pulse Cannon       |

Each weapon has a unique combination of: projectile_type (ballistic/beam/melee/aoe), damage_type (ballistic/energy/explosive), fire_rate, accuracy, range envelope, heat profile, and status effects.

---

## 2. File Change Table

### New Files

| # | Path | Purpose |
|---|------|---------|
| 1 | `project/src/systems/weapon_system.gd` | **REPLACE STUB** -- Full WeaponSystem: fire control, projectile lifecycle, hit detection, damage calc |
| 2 | `project/src/systems/movement_system.gd` | **REPLACE STUB** -- Full MovementSystem: velocity, acceleration, collision, arena clamping |
| 3 | `project/src/systems/status_system.gd` | **REPLACE STUB** -- Full StatusSystem: effect application, ticking, stacking, expiry |
| 4 | `project/src/systems/ai_system.gd` | **REPLACE STUB** -- Full AISystem: FSM, target selection, fire decisions |
| 5 | `project/src/systems/command_system.gd` | **REPLACE STUB** -- Full CommandSystem: MOVE/FOLLOW/FOCUS with cooldowns |
| 6 | `project/src/managers/simulation_manager.gd` | **REPLACE STUB** -- Full SimulationManager: tick loop, system orchestration, checkpoint |
| 7 | `project/src/managers/game_state.gd` | **REPLACE STUB** -- Full GameState: player profile, loadouts, credits, progression |
| 8 | `project/data/weapons/weapons_t1_t3.json` | 12 weapon definitions (T1-T3), all fields per schema |
| 9 | `project/schemas/weapon.schema.json` | JSON Schema for WeaponData validation |
| 10 | `project/tests/test_weapon_system.gd` | Unit tests: fire cooldown, heat, damage calc, hit detection, determinism |
| 11 | `project/tests/test_status_effects.gd` | **REPLACE STUB** -- Full tests: apply, tick, stack, expire, interact |
| 12 | `project/tests/test_determinism.gd` | **REPLACE STUB** -- Full tests: 100-tick replay, checksum match, RNG isolation |
| 13 | `project/tests/test_damage_calc.gd` | **REPLACE STUB** -- Full tests: range falloff, resistances, min damage, crits |
| 14 | `project/scripts/ai/architecture_summary.md` | This document |
| 15 | `project/scripts/ai/weapon_schema.json` | Complete JSON schema for WeaponData with 12 variant fields |

### Modified Files

| # | Path | Change Description |
|---|------|--------------------|
| 1 | `project/src/entities/bot.gd` | Add `shield_hp`, `shield_max_hp`, `heat_capacity` fields. Update `setup_from_loadout()` to parse weapon data via new schema. Add `get_weapon_range()` helper. |
| 2 | `project/src/entities/projectile.gd` | Add AOE fields (`splash_radius`, `splash_falloff`). Update `_init()` to read from WeaponData schema. Add `resolve_hit_deterministic()` using `DeterministicRng` instead of `RandomNumberGenerator`. |
| 3 | `project/src/managers/BattleManager.gd` | Wire `WeaponSystem` events to stats tracking (`shots_fired`, `shots_hit`, `damage_dealt`). Connect `StatusSystem` signals. |
| 4 | `project/src/managers/ShopManager.gd` | Add weapon category to `CATEGORIES`. Update `_normalize_component()` to expose weapon-specific stats (DPS, range, heat). |
| 5 | `project/src/ui/build_screen.gd` | Add weapon slot display in bot preview. Show DPS calculation. Add weapon comparison tooltip. |
| 6 | `project/src/ui/shop_screen.gd` | Add weapon stats rendering (DPS, range bar, heat bar). Color-code by damage_type. |
| 7 | `project/autoload/DataLoader.gd` | Add `get_weapon(id)`, `get_all_weapons()`, `get_weapons_by_tier()` (already present in autoload wrapper, ensure core `data_loader.gd` indexes `weapons_t1_t3.json`). |
| 8 | `project/data/slice/parts_slice.json` | Add 9 new weapon entries (T2-T3) to complement existing 3 T1 weapons. |
| 9 | `project/data/balance/envelopes_t1_t5.json` | Verify weapon envelopes cover all 12 variants. No change if already compliant. |

---

## 3. Data Schema Definition

### WeaponData Resource Schema (GDScript)

```gdscript
class_name WeaponData extends Resource

## Unique identifier matching parts_slice.json
@export var id: String = ""

## Display name
@export var name: String = ""

## Always "weapon"
@export var category: String = "weapon"

## Tier 1-5
@export var tier: int = 1

## Weight in kg
@export var weight: float = 5.0

## Credit cost
@export var cost: int = 100

## Flavor text
@export var description: String = ""

## --- Core Combat Stats ---

## Damage per shot (before modifiers)
@export var damage_per_shot: float = 10.0

## Shots per second
@export var fire_rate: float = 1.0

## Minimum effective range (below this: 0 damage)
@export var range_min: float = 0.0

## Optimal range (full damage)
@export var range_optimal: float = 100.0

## Maximum range (projectile despawns)
@export var range_max: float = 200.0

## Base accuracy [0.0 - 1.0]
@export var accuracy: float = 0.7

## --- Projectile ---

## "ballistic" | "beam" | "melee" | "aoe"
@export var projectile_type: String = "ballistic"

## "ballistic" | "energy" | "explosive"
@export var damage_type: String = "ballistic"

## Speed in units/sec (0 for beam/melee)
@export var projectile_speed: float = 400.0

## Projectile collision radius
@export var projectile_radius: float = 4.0

## --- AOE (for explosive/aoe types) ---

## Splash damage radius (0 = single target)
@export var splash_radius: float = 0.0

## Splash damage falloff curve (1.0 = linear, 2.0 = quadratic)
@export var splash_falloff: float = 1.0

## --- Heat Management ---

## Heat generated per shot
@export var heat_per_shot: float = 2.0

## Heat dissipated per tick (1/60 sec)
@export var heat_dissipation_per_tick: float = 0.3

## Heat threshold that triggers overheat lockout
@export var overheat_threshold: float = 40.0

## Ticks of forced cooldown when overheated
@export var overheat_lockout_ticks: int = 120

## --- Critical Hits ---

## Crit chance [0.0 - 1.0]
@export var crit_chance: float = 0.0

## Crit damage multiplier
@export var crit_multiplier: float = 1.5

## --- Status Effects ---

## Array of {type, magnitude, duration_ticks, tick_interval, stacking}
@export var effects: Array[Dictionary] = []
```

### JSON Fallback Schema

See `project/scripts/ai/weapon_schema.json` for the full JSON Schema (draft-07). Key points:

- `id`: string, pattern `^wpn_[a-z0-9_]+$`
- `category`: must be `"weapon"`
- `projectile_type`: enum `["ballistic", "beam", "melee", "aoe"]`
- `damage_type`: enum `["ballistic", "energy", "explosive"]`
- `effects`: array of StatusEffect objects with `type` enum `["slow", "stun", "burn", "emp", "armor_break"]`
- All numeric fields have min/max bounds matching balance envelopes

---

## 4. Determinism Design

### RNG Isolation

The simulation uses a **single** `DeterministicRng` instance (xorshift32) owned by `SimulationManager`. All systems receive it as a parameter:

```
SimulationManager._rng: DeterministicRng
  seed(match_seed) at battle start
  |
  passed to WeaponSystem.process(bots, projectiles, rng, tick, dt)
  passed to AISystem.process(bots, rng, tick)
  passed to StatusSystem.process(bots, rng, tick) -- for proc effects
```

**Rule**: No system creates its own RNG. No system calls Godot's `randf()` or `randi()`. The `_rng` call count is tracked for replay verification.

### Tick-Based Resolution

All time-dependent operations use integer tick counts, never `delta`:

- Fire cooldown: `next_fire_tick = current_tick + cooldown_ticks`
- Heat dissipation: `heat -= heat_dissipation_per_tick` (per tick, not per second)
- Status duration: `remaining_ticks -= 1` (per tick)
- Projectile travel: `distance += speed * SimConstants.TIMESTEP` (fixed dt)

### Deterministic Iteration Order

Every loop over bots/projectiles is ordered by `sim_id` (ascending). Dictionary iterations use `DeterminismHelpers.get_sorted_keys()`. This matches the existing `determinism_contract.md`.

### Checkpoints

Every `CHECKSUM_INTERVAL_TICKS` (60 ticks = 1 second), `SimulationManager` computes a state checksum:

```gdscript
func _compute_checkpoint(tick: int) -> int:
    var checksum: int = tick
    # Iterate bots in sim_id order
    var sorted_ids: Array = _bots.keys()
    sorted_ids.sort()
    for id in sorted_ids:
        var bot = _bots[id]
        checksum = DeterminismHelpers.hash_combine(checksum, bot.sim_id)
        checksum = DeterminismHelpers.hash_combine(checksum, DeterminismHelpers.hash_vector2(bot.position))
        checksum = DeterminismHelpers.hash_combine(checksum, DeterminismHelpers.hash_float(float(bot.hp)))
        checksum = DeterminismHelpers.hash_combine(checksum, bot.weapons.size())
    # Hash RNG state
    checksum = DeterminismHelpers.hash_combine(checksum, _rng.get_state())
    return checksum
```

Checksums are stored in an array for replay comparison. Two runs with the same seed must produce identical checksum sequences.

### Replay Safety

A replay file stores: `{seed, player_commands: [{tick, type, target}]}`. To replay:
1. Initialize with same seed
2. Feed commands at correct ticks
3. Compare checksum arrays

No external state (OS time, frame delta, physics) leaks into simulation.

---

## 5. Risk Map

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| **Float precision drift across platforms** | HIGH | MEDIUM | Use `DeterminismHelpers.fix_precision()` at every state storage point. Integer math for damage where possible. Checkpoint comparison catches drift within 1 second. |
| **Heat/cooldown desync if tick rate varies** | HIGH | LOW | All timing uses integer ticks, never delta. `SimConstants.TIMESTEP` is `const`. SimulationManager accumulator ensures exactly 60 ticks/sec regardless of frame rate. |
| **Dictionary iteration order non-determinism** | HIGH | HIGH (if violated) | All existing code already follows `determinism_contract.md`. New WeaponSystem code must sort bot arrays by `sim_id` before processing. Code review checklist enforced. |
| **Splash damage ordering affects kill attribution** | MEDIUM | MEDIUM | Process splash targets in `sim_id` order. First-hit attribution is deterministic. |
| **Balance: one weapon dominates meta** | MEDIUM | HIGH | DPS-per-weight and DPS-per-cost balance metrics enforced by envelope system. 10,000-duel simulation (Task #3) validates no weapon exceeds 55% win rate. |
| **Performance: 20 bots * many projectiles at 60Hz** | MEDIUM | MEDIUM | Projectile cap (`MAX_PROJECTILES = 500`). Spatial hash for collision (cell size 128). Beam/melee are instant (no projectile entity). Object pooling for projectiles. |
| **Status effect stacking exploits** | LOW | MEDIUM | Stacking rules per effect: `replace` (latest wins), `refresh` (reset duration), `stack` (additive, capped at 3 stacks max). Cap defined in schema. |
| **Existing BattleManager uses Node2D bots, not RefCounted** | MEDIUM | HIGH | BattleManager currently calls `bot.queue_free()`, `add_child(bot)`. The simulation layer uses RefCounted Bot. Rendering layer creates Node2D sprites that mirror Bot data. Keep separation: simulation = RefCounted, rendering = Node2D. BattleManager bridges both. |

---

## 6. Integration Points

### WeaponSystem <-> build_screen.gd

**Current state**: `build_screen.gd` (line 304) iterates `["chassis", "armor", "weapon"]` slots and calls `DataLoader.get_part(part_id)` to display stats.

**Integration**:
- `build_screen.gd._update_bot_display()` reads weapon data from `DataLoader.get_weapon(weapon_id)` to compute and display:
  - DPS: `damage_per_shot * fire_rate`
  - Effective range: `range_optimal` - `range_max` bar
  - Heat profile: `heat_per_shot * fire_rate` vs `heat_dissipation_per_tick * 60`
  - Status effects list
- The `current_bot` dictionary gains a `"weapons"` array (plural) instead of single `"weapon"` string, supporting multi-slot chassis. Build screen renders all equipped weapons.
- Weight validation: sum of all weapon weights checked against chassis `weight_capacity`.

### WeaponSystem <-> shop_screen.gd

**Current state**: `ShopManager` (line 265-271) renders weapon stats as `{Damage, Fire Rate, Range, Accuracy, Weight}`.

**Integration**:
- `ShopManager.get_component_stats()` for `"weapons"` category returns expanded stats:
  ```
  {
    "DPS": damage_per_shot * fire_rate,
    "Damage": damage_per_shot,
    "Fire Rate": fire_rate,
    "Range": "%d-%d" % [range_optimal, range_max],
    "Accuracy": "%.0f%%" % (accuracy * 100),
    "Damage Type": damage_type.capitalize(),
    "Projectile": projectile_type.capitalize(),
    "Heat/Shot": heat_per_shot,
    "Effects": effects_summary_string,
    "Weight": weight
  }
  ```
- `shop_screen.gd` color-codes weapons by `damage_type`: ballistic=gray, energy=blue, explosive=orange.
- Comparison tooltip: when selecting a weapon, show delta vs currently equipped weapon's DPS/range.

### WeaponSystem <-> GameState.gd

**Current state**: `GameState.gd` is a stub (TASK-06). When implemented:

**Integration**:
- `GameState.loadouts` stores bot loadouts as:
  ```json
  {
    "id": "bot_1",
    "name": "My Bot",
    "chassis": "chassis_light_t1",
    "armor": ["arm_plate_t1"],
    "weapons": ["wpn_mg_t1", "wpn_laser_t1"],
    "mobility": ["mob_wheels_t1"],
    "sensors": ["sen_basic_t1"],
    "utility": []
  }
  ```
- `GameState.owned_parts: Dictionary` tracks `{part_id: int}` quantities. Weapons are purchasable/equippable like other parts.
- `GameState.current_tier` gates weapon availability (tier <= player_tier + 1).
- When a battle starts, `BattleManager.setup_battle()` reads loadouts from `GameState` and passes weapon IDs to `Bot.setup_from_loadout()`, which indexes into `DataLoader` for full weapon data.

### WeaponSystem <-> SimulationManager

`SimulationManager` owns the tick loop and calls `WeaponSystem.process()` each tick. It passes:
- `bots: Array[Bot]` (sorted by sim_id)
- `projectiles: Array[Projectile]` (mutable, WeaponSystem adds/removes)
- `rng: DeterministicRng` (shared instance)
- `tick: int` (current simulation tick)
- `dt: float` (always `SimConstants.TIMESTEP`)
- `arena_bounds: Rect2` (for projectile OOB checks)

WeaponSystem returns events via a results array (no signals in hot path):
```gdscript
var events: Array[Dictionary] = weapon_system.process(bots, projectiles, rng, tick, dt, arena_bounds)
# events = [{type: "shot_fired", bot_id, weapon_id, tick}, {type: "hit", ...}, {type: "kill", ...}]
```

SimulationManager forwards events to BattleManager for stats tracking and to VFXManager for visual effects.

### WeaponSystem <-> BalanceManager

`BalanceManager.CombatBalance` provides baseline constants:
- `BASE_WEAPON_DAMAGE`, `DAMAGE_PER_TIER` -- used for tier scaling validation
- `BASE_FIRE_COOLDOWN`, `FIRE_COOLDOWN_PER_TIER` -- not directly used (data-driven per weapon), but validated against envelopes

The 10,000-duel simulation framework (Task #3) uses `BalanceManager.generate_balance_report()` alongside per-weapon DPS/DPW (damage per weight) metrics to flag outliers.

### WeaponSystem <-> StatusSystem

WeaponSystem delegates effect application to StatusSystem:
```gdscript
for effect_def in weapon_data.effects:
    status_system.apply_effect(target_bot, effect_def, rng, tick)
```

StatusSystem handles stacking rules (`replace`/`refresh`/`stack`), duration tracking, and per-tick damage (burn). WeaponSystem does not manage effect lifecycle.
