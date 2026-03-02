## ID
AGENT-001

## Title
Design and Implement Advanced AI Combat System

## Goal
Replace the current simplistic AI with tactical, squad-aware combat intelligence that uses cover, flanking, and role-based behaviors.

## Problem Statement
Current AI is "basic state-based" with no pathfinding. Enemies walk directly at the player and shoot. This makes combat feel mechanical and unengaging. The AI system needs to support:
- Pathfinding around obstacles
- Tactical positioning (cover, high ground, flanking angles)
- Role-based behaviors (Tank pushes forward, Sniper stays at range, Scout flanks)
- Squad coordination (focus fire, retreat decisions, group tactics)

## Allowed Files
- project/autoload/SimulationManager.gd
- project/src/entities/bot.gd
- project/src/ai/bot_ai.gd (if exists, else create)
- project/data/campaign.json (read-only reference)
- project/data/arena_*.json (if exists)

## New Files
- project/src/ai/tactical_ai.gd
- project/src/ai/squad_manager.gd
- project/src/systems/pathfinder.gd
- project/src/ai/ai_profile_*.gd (role-specific behaviors)

## Forbidden Files
- UI scenes (scenes/*.tscn)
- GameState.gd (no economy changes)
- Any JSON data files (read-only)

## Architecture Requirements

### 1. Pathfinding System (pathfinder.gd)
```gdscript
class_name Pathfinder
## A* pathfinding for arena navigation

func find_path(start: Vector2, end: Vector2, obstacles: Array) -> Array[Vector2]:
func get_nearest_cover(position: Vector2, team: int) -> Vector2:
func get_flanking_position(target: Vector2, current: Vector2) -> Vector2:
```

### 2. Tactical AI (tactical_ai.gd)
```gdscript
class_name TacticalAI
## Per-bot tactical decision making

enum TacticalState { ENGAGE, TAKE_COVER, FLANK, RETREAT, HOLD }

func evaluate_tactical_position(pos: Vector2) -> float:
    ## Score based on:
    ## - Distance to optimal weapon range
    ## - Proximity to cover
    ## - Line of sight to enemies
    ## - Exposure to enemy fire (risk)
    ## - Distance to allies (cohesion)

func select_target(enemies: Array[Bot]) -> Bot:
    ## Consider: threat level, HP, distance, focused by allies
```

### 3. Squad Manager (squad_manager.gd)
```gdscript
class_name SquadManager
## Coordinates multiple AI bots on same team

func assign_roles(bots: Array[Bot]) -> void:
    ## Assign: Tank (highest armor), Assault (damage), Support (healing if exists)

func coordinate_attack(target: Bot) -> void:
    ## Signal multiple bots to focus fire

func evaluate_retreat(team_hp_pct: float, enemy_hp_pct: float) -> bool:
```

### 4. AI Profiles
Create specific behaviors for:
- `ai_tank.gd`: Pushes forward, absorbs damage, draws fire
- `ai_assault.gd`: Medium range, seeks cover between shots
- `ai_sniper.gd`: Maintains max range, repositions after firing
- `ai_scout.gd`: Flanks, hits backline, retreats if targeted

## Integration Points

SimulationManager.gd modifications needed:
```gdscript
# In _spawn_team(), add:
var squad_mgr = SquadManager.new()
add_child(squad_mgr)
squad_mgr.initialize(bots)

# In _run_tick(), before bot processing:
squad_mgr.update_squad_tactics()

# In bot processing:
bot.ai_component.make_decision(squad_mgr.get_context())
```

## Acceptance Criteria
- [ ] AC1: AI uses obstacles for cover (verified by debug visualization)
- [ ] AC2: Snipers maintain 70%+ of max weapon range
- [ ] AC3: Tanks position closer to enemies than allies
- [ ] AC4: Squad focus-fire: 3+ bots attack same target within 2 seconds
- [ ] AC5: AI retreats when HP < 25% and no allies nearby
- [ ] AC6: Pathfinding completes < 1ms for 20x20 grid
- [ ] AC7: Deterministic (same seed = same AI decisions)

## Tests Required
- [ ] test1: 1v1 with obstacle - AI should path around, not through
- [ ] test2: Sniper vs Tank - Sniper maintains range advantage
- [ ] test3: 3v3 squad fight - verify focus fire coordination
- [ ] test4: Performance: 60 FPS with 20 AI bots

## Performance Constraints
- Pathfinding: < 1ms per query
- AI decision: < 0.5ms per bot per tick
- Maintain 60Hz simulation
- No allocation in hot paths

## Deliverable Structure
```
agent_runs/AGENT-001/
  NEW_FILES/
    - src/ai/tactical_ai.gd
    - src/ai/squad_manager.gd
    - src/systems/pathfinder.gd
    - src/ai/ai_tank.gd
    - src/ai/ai_assault.gd
    - src/ai/ai_sniper.gd
    - src/ai/ai_scout.gd
  MODIFICATIONS/
    - SimulationManager.gd.patch
  TESTS/
    - test_ai_pathfinding.gd
    - test_squad_coordination.gd
  INTEGRATION_GUIDE.md
  CHANGELOG.md
```

## Notes
- Maintain determinism: seeded RNG only
- Debug visualization optional but helpful
- Start simple: A* with rectangular obstacles
- Arena obstacles defined in campaign.json
- No learning/adaptation - static behaviors only for v0.1

## Research Areas
1. A* implementation in GDScript (optimized for gridless continuous space)
2. Influence maps for tactical positioning
3. Squad AI coordination patterns (from RTS games)
