# Ironcore Arena - Architectural Invariants

These constraints are non-negotiable. Any ticket that violates these is invalid.

## Core Systems

### Deterministic Simulation
- 60Hz fixed timestep (`_physics_process`)
- Seeded RNG for replayability
- No `randf()`/`randi()` without seeding first
- No `Time.get_unix_time_from_system()` in simulation logic
- Floating-point operations must be deterministic across platforms

### State Management
- `GameState` owns player profile (credits, parts, progression)
- `SimulationManager` owns battle state (bots, projectiles, ticks)
- UI screens do NOT mutate GameState directly
- UI emits EventBus signals OR calls ScreenRouter/UIFlow methods
- All state changes flow through established channels

### Component Pattern
- Reusable behaviors as Component nodes (HealthComponent, StateMachine)
- Components attached to parent, query parent for context
- No hardcoded node paths; use `@onready var` with `get_node()`

### File Organization
- `autoload/` - Singletons only (AutoLoad in project.godot)
- `scripts/components/` - Reusable component scripts
- `scripts/ai/` - AI behaviors
- `src/` - Core systems (Bot, Projectile, RNG, etc.)
- `scenes/` - Scene files (.tscn)
- `data/` - JSON content (components, arenas, campaigns)

## Forbidden Patterns

- Global variables (use autoload singletons)
- Circular dependencies between singletons
- Direct file system access outside `user://` and `res://`
- `yield` (use `await`)
- Untyped function signatures (GDScript 2.0 requires types)

## Performance Constraints

- Target: 60 FPS on RTX 4080
- Max 20 bots per battle
- Max 100 projectiles active
- No allocation in hot paths (use object pools)
- Pre-allocate arrays where possible

## Refactor Policy

- No refactors unless explicitly in ticket
- No "while I'm here" changes
- No edits outside ticket allowlist
