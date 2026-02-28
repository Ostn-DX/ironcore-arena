---
title: Architectural_Invariants
type: rule
layer: enforcement
status: active
tags:
  - invariants
  - constraints
  - non-negotiable
  - architecture
depends_on: []
used_by:
  - "[Code_Review_Checklist]]"
  - "[[Agent_Validation_Rules]"
---

# Architectural Invariants

## Purpose
Non-negotiable constraints that keep the codebase maintainable, deterministic, and performant. Violations invalidate tickets.

## Core Rules

### Determinism Invariants
- ✅ Seeded RNG only (`deterministic_rng.gd`)
- ✅ 60Hz fixed timestep
- ❌ No `randf()`/`randi()` without seed
- ❌ No `Time.get_unix_time_from_system()` in sim
- ❌ No platform-dependent float operations

### State Management Invariants
- ✅ `GameState` owns player profile
- ✅ `SimulationManager` owns battle state
- ✅ UI emits events, doesn't mutate state directly
- ❌ No direct GameState mutation from scenes
- ❌ No cross-singleton circular dependencies

### Component Invariants
- ✅ Components attach as child nodes
- ✅ Typed parent references only
- ✅ Signals for cross-component comms
- ❌ No hardcoded node paths
- ❌ No direct sibling references

### File Organization Invariants
- ✅ `autoload/` = singletons only
- ✅ `scripts/components/` = reusable components
- ✅ `src/` = core systems
- ✅ `scenes/` = scene files
- ✅ `data/` = JSON content

### Performance Invariants
- ✅ 60 FPS target on RTX 4080
- ✅ Max 20 bots per battle
- ✅ Max 100 projectiles
- ✅ No allocation in hot paths
- ✅ Pre-allocated arrays

### Code Quality Invariants
- ✅ Full type hints (`-> void`, `-> int`)
- ✅ `class_name` for all scripts
- ✅ Doc comments for public functions
- ❌ No `yield` (use `await`)
- ❌ No untyped signatures
- ❌ No global variables

## Failure Modes

### Invariant Violation
**Severity:** Critical
**Action:** Ticket rejected, return to architect
**Detection:** [[Architect_Agent]], [[Pitfall_Detection_Agent]]

### Silent Drift
**Symptom:** Code slowly accumulates technical debt
**Prevention:** Quarterly invariant audits

## Enforcement

### Automated
- [[Lint_Agent]] checks type hints
- [[Determinism_Validation_Agent]] audits RNG usage
- [[Performance_Agent]] profiles allocations

### Manual
- Code review checklist includes all invariants
- Architecture review for major changes

## Related
[[Code_Conventions]]
[[Quality_Gates]]
[[Refactor_Policy]]
