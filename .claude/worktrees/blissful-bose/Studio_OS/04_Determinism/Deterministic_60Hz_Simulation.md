---
title: Deterministic_60Hz_Simulation
type: system
layer: architecture
status: active
tags:
  - simulation
  - determinism
  - physics
  - core
depends_on: []
used_by:
  - "[Combat_Resolution_System]]"
  - "[[Replay_System]]"
  - "[[AI_Decision_Making]"
---

# Deterministic 60Hz Simulation

## Purpose
Battle simulation must produce identical results given identical inputs across all platforms. This enables replays, AI training, and fair competitive play.

## Core Rules

### Timing
- Fixed timestep: 60 ticks per second
- `DT = 1.0 / 60.0` (~16.67ms)
- Never use delta time from `_process()`
- Always use constant `_physics_process()` delta

### Random Number Generation
- Seeded RNG only: `deterministic_rng.gd`
- Never use `randf()`/`randi()` directly
- Seed derived from: arena_id + timestamp_hash
- Same seed = identical battle sequence

### Forbidden Operations
- No `Time.get_unix_time_from_system()` in sim logic
- No hardware-specific floating point (use `step()` for determinism)
- No async operations during simulation tick
- No dictionary iteration order dependence

### State Isolation
- `SimulationManager` owns all battle state
- `GameState` owns persistent player data
- No cross-contamination between ticks
- All mutations happen in `_run_tick()`

## Failure Modes

### Determinism Break
**Symptom:** Same seed produces different results on replay
**Causes:**
- Unseeded random calls
- Platform-specific float behavior
- Dictionary key order assumptions
- Race conditions in async code

**Detection:** [[Replay_Validation_Test]]

### Performance Degradation
**Symptom:** Frame drops below 60Hz during battle
**Causes:**
- Allocation in hot paths
- O(n²) collision detection
- Excessive AI calculations per tick

**Detection:** [[Performance_Monitor]]

## Enforcement

### Quality Gates
- [[Headless_Match_Runner]] validates 10 matches per seed
- [[Determinism_Test_Suite]] runs before each commit
- [[Performance_Regression_Test]] checks FPS

### Agents
- [[Determinism_Validation_Agent]] audits code for forbidden patterns
- [[Performance_Monitor_Agent]] profiles hot paths

## Related
[[Deterministic_RNG_Implementation]]
[[Physics_Tick_Architecture]]
[[Float_Consistency_Across_Platforms]]
