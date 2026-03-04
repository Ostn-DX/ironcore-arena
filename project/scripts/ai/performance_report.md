# Performance Report: Weapon System at 60Hz with 20 Bots

## Parameters
- **Tick rate**: 60Hz (16.67ms frame budget)
- **Bot count**: 20 bots, each with 1 weapon
- **Worst case**: All 20 bots fire simultaneously (20 projectiles spawned per tick)
- **Target**: < 0.2ms (200us) additional frame cost from weapon system per tick

---

## 1. Hotspot Table

| # | Method | Est. Cost BEFORE (us) | Optimization Applied | Est. Cost AFTER (us) |
|---|--------|-----------------------|----------------------|----------------------|
| 1 | `process_tick` event array alloc | 3-5 | Reuse pre-allocated `_events` array via `.clear()` instead of `= []` | ~1 |
| 2 | `dead_indices.has(i)` O(n) scan | 5-15 (per projectile) | Replaced `Array` with `Dictionary` (`_dead_set`) for O(1) `.has()` | ~1 |
| 3 | `_try_fire_weapons` return array | 2-4 (per bot) | Changed to `void`; appends directly to `_events` | 0 |
| 4 | `_fire_shot` return array | 2-4 (per shot) | Changed to `void`; appends directly to `_events` | 0 |
| 5 | `_resolve_projectile_hit` return array | 2-4 (per hit) | Changed to `void`; appends directly to `_events` | 0 |
| 6 | `_resolve_aoe_impact` return array | 2-4 (per splash) | Changed to `void`; appends directly to `_events` | 0 |
| 7 | `_ensure_weapon_data` (from_dict) | 8-15 (per hit) | Added `_wd_cache` Dictionary; `_ensure_weapon_data_cached()` returns cached WeaponData | ~1 (cache hit) |
| 8 | `"resist_" + weapon.damage_type` string concat | 1-2 (per hit) | Pre-computed `_RESIST_KEYS` const Dictionary lookup | ~0.5 |
| 9 | `resolve_splash` `targets.duplicate()` | 3-8 (per splash, N bots) | Sort targets in-place; no `.duplicate()` | ~0.5 |
| 10 | `resolve_hit` repeated property access | 1-3 (per hit) | Cache weapon properties into local vars at method entry | ~0.5 |
| 11 | `resolve_splash` repeated property access | 1-3 (per splash target) | Cache weapon properties and resist key at loop entry | ~0.5 |
| 12 | Phase 3 double `projectile_type` lookup | 1-2 (per projectile) | Read `ptype` once, reuse for both `ballistic`/`aoe` checks | ~0.5 |
| 13 | Phase 4 repeated `proj.get("team"/"source_bot_id")` | 1-2 (per proj*bot) | Hoist `proj_team` and `proj_source` outside inner bot loop | ~0.3 |

---

## 2. Frame Cost Estimate (20 bots, 1 weapon each)

### Assumptions
- GDScript Dictionary `.get()`: ~0.1-0.3us per call
- GDScript Array `.append()`: ~0.1us
- `WeaponData.from_dict()` (25+ field copies): ~10-15us
- `Vector2.distance_to()`: ~0.05us
- `DeterministicRng.next_float01()`: ~0.1us
- Typical active projectiles: 5-15 at any given time

### BEFORE Optimization

| Phase | Operations | Cost (us) |
|-------|-----------|-----------|
| Phase 1: Cooldown/heat | 20 bots x 1 weapon x ~5 dict lookups | ~15 |
| Phase 2: Fire resolution | ~3-5 bots fire/tick x target lookup + fire_shot + array allocs | ~40-60 |
| Phase 3: Projectile update | ~10 projectiles x move + bounds + range + string compare | ~15-20 |
| Phase 4: Hit detection | ~10 projectiles x 20 bots x collision + string compare | ~30-50 |
| Phase 5: Cleanup | sort + remove_at x ~3-5 | ~5-10 |
| Event array overhead | ~10-20 intermediate arrays created/merged | ~15-25 |
| WeaponData.from_dict per hit | ~3-5 hits x 10-15us | ~30-75 |
| **TOTAL BEFORE** | | **~150-240us** |

### AFTER Optimization

| Phase | Operations | Cost (us) |
|-------|-----------|-----------|
| Phase 1: Cooldown/heat | 20 bots x 1 weapon x ~5 dict lookups | ~15 |
| Phase 2: Fire resolution | ~3-5 bots fire/tick, direct _events append | ~25-35 |
| Phase 3: Projectile update | ~10 projectiles, ptype cached per proj | ~10-15 |
| Phase 4: Hit detection | ~10 projectiles x 20 bots, hoisted lookups, O(1) dead check | ~20-35 |
| Phase 5: Cleanup | Dictionary keys sort + remove_at | ~5-8 |
| Event array overhead | 0 intermediate arrays (direct append) | ~0 |
| WeaponData cache | ~3-5 hits x 0.5us (cache hit) | ~1.5-2.5 |
| **TOTAL AFTER** | | **~76-110us** |

---

## 3. Target Confirmation

| Metric | Value |
|--------|-------|
| Estimated cost BEFORE | ~150-240us (0.15-0.24ms) |
| Estimated cost AFTER | ~76-110us (0.076-0.110ms) |
| Target budget | < 200us (0.2ms) |
| **Meets target?** | **YES** |
| Frame budget consumed | 0.5-0.7% of 16.67ms |

---

## 4. Remaining Risks at Higher Scale

### 40 Bots Scenario
- Phase 4 hit detection is O(projectiles * bots) = O(P*B). With 40 bots and ~20 projectiles, this becomes ~800 collision checks vs ~200 at 20 bots. Estimated cost: ~160-200us total.
- **Mitigation**: If 40 bots is needed, implement spatial hashing (cell size 128) for Phase 4. The architecture doc already notes this as a planned optimization. This would reduce hit detection from O(P*B) to O(P*k) where k = bots per cell (~3-5).

### 60+ Bots Scenario
- `_collect_splash_targets` iterates all bots and creates a dict per alive bot. At 60 bots, each AOE splash creates ~60 dictionaries.
- **Mitigation**: Add distance pre-filter in `_collect_splash_targets` to skip bots beyond splash_radius before converting to dict.

### Projectile Saturation
- `MAX_PROJECTILES = 500` is safe. Even at worst case (20 burst-3 weapons firing simultaneously), peak is ~60 projectiles. The cap is defensive, not expected to be hit.

### GC Pressure
- Dictionary event creation remains in the hot path (~5-10 per tick). GDScript 4's incremental GC handles this well for small dicts. If profiling shows GC spikes, consider a ring buffer of pre-allocated event dicts.

---

## 5. Micro-Optimization Diff Summary

### weapon_system.gd
1. Added pre-allocated `_events: Array` and `_dead_set: Dictionary` as instance vars, `.clear()` each tick instead of allocating new arrays
2. Added `_wd_cache: Dictionary` for WeaponData resource caching across hits
3. Changed `_try_fire_weapons`, `_fire_shot`, `_resolve_projectile_hit`, `_resolve_aoe_impact` from returning `Array` to `void` (direct `_events.append`)
4. Replaced `dead_indices: Array` with `_dead_set: Dictionary` for O(1) membership test
5. Hoisted `proj.get("team")` and `proj.get("source_bot_id")` outside inner bot loop in Phase 4
6. Cached `ptype` once per projectile in Phase 3 (avoids double `.get()`)
7. Added `_ensure_weapon_data_cached()` method with per-weapon-id cache
8. Updated `reset()` to clear all caches

### combat_resolver.gd
1. Added `_RESIST_KEYS` const Dictionary to replace `"resist_" + damage_type` string concatenation
2. `resolve_hit`: Cache 7 weapon properties into local vars at method entry
3. `resolve_splash`: Sort targets in-place (no `.duplicate()`), cache weapon properties and resist key before loop

### Files Modified
- `project/src/systems/weapon_system.gd`
- `project/src/systems/combat_resolver.gd`

### Files NOT Modified (no changes needed)
- `project/src/systems/weapon_data.gd` -- Data class, not in hot path
- `project/src/systems/deterministic_rng.gd` -- Already optimal (pure math)
- `project/autoload/SimulationManager.gd` -- Orchestration layer, no hot path issues
