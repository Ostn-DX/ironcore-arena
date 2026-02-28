---
title: File_Organization_Structure
type: system
layer: architecture
status: active
tags:
  - organization
  - structure
  - files
  - directories
depends_on: []
used_by:
  - "[Component_Architecture_Pattern]]"
  - "[[Code_Conventions_Standard]"
---

# File Organization Structure

## Purpose
Maintain consistent, navigable project structure. Reduces cognitive load and enables automated tooling.

## Core Rules

### Directory Hierarchy
```
project/
├── autoload/          # Singletons (AutoLoad)
│   ├── GameState.gd
│   ├── SimulationManager.gd
│   ├── DataLoader.gd
│   └── EventBus.gd
├── scripts/
│   ├── components/    # Reusable components
│   │   ├── HealthComponent.gd
│   │   ├── StateMachine.gd
│   │   └── SpriteComponent.gd
│   └── ai/           # AI behaviors
│       ├── tactical_ai.gd
│       └── squad_manager.gd
├── src/              # Core systems
│   ├── entities/     # Bot, Projectile
│   ├── systems/      # RNG, Pathfinding
│   └── analysis/     # Balance tools
├── scenes/           # Scene files
│   ├── main_menu.tscn
│   ├── builder/
│   └── ui/
├── resources/        # Resource classes
│   ├── sprite_atlas.gd
│   └── animation_state.gd
├── data/             # JSON content
│   ├── components.json
│   ├── campaign.json
│   └── balance/
├── assets/           # Sprites, audio
│   ├── sprites/
│   ├── audio/
│   └── fonts/
├── tools/            # Editor/validation tools
│   ├── run_headless_matches.gd
│   └── balance_validator.gd
└── tests/            # GUT test suites
    ├── test_simulation.gd
    └── test_ai.gd
```

### File Naming

| Type | Pattern | Example |
|------|---------|---------|
| GDScript | snake_case.gd | `bot_controller.gd` |
| Scene | snake_case.tscn | `main_menu.tscn` |
| Resource | PascalCase.tres | `SpriteAtlas.tres` |
| JSON | snake_case.json | `components.json` |
| Test | test_*.gd | `test_bot_behavior.gd` |

### Singleton Pattern
- Only in `autoload/`
- Must be registered in project.godot AutoLoad
- Use `@onready` for references, never hardcode paths

### Component Pattern
- Only in `scripts/components/`
- Must use `class_name`
- Must be attachable to any Node

## Failure Modes

### Wrong Directory
**Symptom:** Can't find files, broken imports
**Fix:** Move to correct directory, update references

### Circular Imports
**Symptom:** Script fails to load
**Fix:** Refactor shared code to `src/shared/`

## Related
[[Godot_Project_Settings]]
[[AutoLoad_Configuration]]
[[Import_Path_Resolution]]
