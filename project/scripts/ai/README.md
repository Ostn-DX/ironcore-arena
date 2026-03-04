# Advanced AI Combat Intelligence for Godot 4

A high-performance, deterministic AI system for tactical combat scenarios supporting up to 20 bots at 60Hz.

## Features

- **Tactical Position Scoring**: Multi-factor evaluation of positions (cover, flanking, distance, LOS, cohesion, kiting)
- **Role-Based Behaviors**: Tank, Sniper, Scout, and Support roles with unique tactical preferences
- **Squad Coordination**: Focus fire, retreat decisions, and regroup commands
- **Amortized Decision Making**: Spread AI processing across frames for consistent performance
- **Deterministic**: Same inputs always produce same outputs (sort by sim_id)
- **Debug Visualization**: Toggleable debug draw for paths, positions, states, and cover points

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  BotAIAdvanced  │────▶│ TacticalScorer   │◄────│  AIRole Config  │
│  (per-bot AI)   │     │ (position eval)  │     │ (Tank/Sniper/   │
└────────┬────────┘     └──────────────────┘     │  Scout/Support) │
         │                                        └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────────┐
│ SquadCoordinator│────▶│ AITacticalContext│
│ (team tactics)  │     │ (shared context) │
└─────────────────┘     └──────────────────┘
         │
         ▼
┌─────────────────┐
│  AIDebugDraw    │
│ (visualization) │
└─────────────────┘
```

## File Overview

### tactical_scorer.gd
Evaluates tactical positions based on multiple weighted factors:
- **Cover Score**: Proximity to cover points, LOS blocking
- **Flank Score**: Side/back angles to enemies
- **Distance Score**: Proximity to preferred engagement range
- **LOS Score**: Ability to shoot enemies
- **Cohesion Score**: Near allies but not too near
- **Kite Score**: Maintain distance advantage

### bot_ai_advanced.gd
Main AI controller for each bot:
- State machine: IDLE, ENGAGING, RETREATING, REPOSITIONING, PURSUING
- Role-based behaviors with configurable weights
- Target selection with focus fire coordination
- Amortized decision making (every N ticks)
- Path following with recalculation

### squad_coordinator.gd
Team-wide tactical coordination:
- Focus fire target selection
- Retreat decision based on strength ratio
- Regroup commands when team is spread
- Deterministic iteration (sort by sim_id)

### ai_tactical_context.gd
Shared context for all AI agents:
- Enemy/ally queries
- Cover point management with occupancy tracking
- Spatial partitioning for efficient queries
- Team registration and lookups

### ai_debug_draw.gd
Debug visualization system:
- Path drawing
- Position and role indicators
- Target lines
- State display
- Cover point visualization
- Squad info overlay

## Usage

### Basic Setup

```gdscript
# Create tactical context
var ctx = AITacticalContext.new()
ctx.initialize(simulation_manager, squad_coordinator)
ctx.set_cover_points(cover_points)
ctx.set_arena_bounds(arena_rect)

# Create squad coordinator
var coordinator = SquadCoordinator.new()
add_child(coordinator)

# Create debug drawer
var debug_draw = AIDebugDraw.new()
debug_draw.set_squad_coordinator(coordinator)
debug_draw.set_tactical_context(ctx)
debug_draw.enabled = true
add_child(debug_draw)

# Create pathfinder
var pathfinder = Pathfinder.new()
pathfinder.initialize(navigation_mesh)
```

### Per-Bot Setup

```gdscript
# For each bot
var ai = BotAIAdvanced.new()
ai.initialize(bot, ctx, pathfinder)
ai.set_role(BotAIAdvanced.AIRole.SNIPER)
bot.add_child(ai)

# Register for debug
debug_draw.register_ai(ai)

# Register with context
ctx.register_bot(bot, team_id)
```

### Main Loop

```gdscript
func _physics_process(delta: float) -> void:
    var sim_tick = Engine.get_physics_frames()
    
    # Update squad coordination (amortized internally)
    squad_coordinator.update_team(team_id, bots, enemies, sim_tick)
    
    # Update each bot AI (amortized internally)
    for bot in bots:
        bot.ai.make_decision(sim_tick)
```

## Role Configurations

### Tank
- Preferred Distance: 150px
- Weapon Range: 250px
- High cohesion weight (1.2)
- Lower distance preference (0.4)
- Pushes objectives, protects allies

### Sniper
- Preferred Distance: 400px
- Weapon Range: 600px
- High cover weight (1.5)
- High LOS weight (1.5)
- High distance weight (1.2)
- Low cohesion weight (0.3)

### Scout
- Preferred Distance: 250px
- Weapon Range: 300px
- High flank weight (1.5)
- Low cohesion weight (0.3)
- Seeks side angles, isolates targets

### Support
- Preferred Distance: 200px
- Weapon Range: 350px
- High cohesion weight (1.2)
- Targets threats to allies
- Stays near team

## Performance

- Decision interval: 6 ticks (10Hz per bot)
- Path recalculation: 30 ticks (2Hz per bot)
- Spatial grid: 200px cells
- Cache validity: 5 ticks
- Supports 20+ bots at 60Hz without frame spikes

## Determinism

All iteration is sorted by `sim_id`:
```gdscript
sorted_bots.sort_custom(func(a, b): return a.get_sim_id() < b.get_sim_id())
```

This ensures:
- Same initial state → Same decisions
- Same random seed → Same behavior
- Reproducible for testing/debugging

## Debug Visualization

Toggle debug draw at runtime:
```gdscript
debug_draw.enabled = true
debug_draw.draw_paths = true
debug_draw.draw_positions = true
debug_draw.draw_cover = true
debug_draw.draw_targets = true
debug_draw.draw_states = true
```

Visual indicators:
- **T/S/C/P**: Tank/Sniper/Scout/Support role
- **Colored circles**: State (Gray/Red/Orange/Blue/Yellow)
- **Green lines**: AI paths
- **Red lines**: Target lines
- **Blue circles**: Cover points
- **Yellow circle**: Move target

## Integration Requirements

Bot nodes must implement:
```gdscript
func get_sim_id() -> int          # Unique simulation ID
func get_team_id() -> int         # Team ID
func get_global_position() -> Vector2
func get_health_ratio() -> float  # 0.0 to 1.0
func is_alive() -> bool
func get_weapon_range() -> float  # Optional
```

## Constants Reference

```gdscript
# Decision timing
DECISION_INTERVAL = 6           # Ticks between decisions
PATH_RECALCULATION_INTERVAL = 30

# Distances
EVALUATION_RADIUS = 300.0
EVALUATION_STEPS = 16
IDEAL_COHESION_DISTANCE = 150.0

# Thresholds
RETREAT_RATIO_THRESHOLD = 0.4
RETREAT_HEALTH_THRESHOLD = 0.35
FOCUS_FIRE_TIMEOUT = 180
```
