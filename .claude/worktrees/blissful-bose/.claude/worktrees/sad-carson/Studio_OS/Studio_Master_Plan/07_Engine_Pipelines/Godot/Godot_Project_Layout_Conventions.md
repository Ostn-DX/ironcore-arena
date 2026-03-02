---
title: Godot Project Layout Conventions
type: rule
layer: architecture
status: active
tags:
  - godot
  - project-structure
  - conventions
  - folders
  - organization
depends_on:
  - "[Godot_Pipeline_Overview]"
used_by:
  - "[Godot_Autoload_Conventions]]"
  - "[[Godot_GDScript_Style_Guide]]"
  - "[[Godot_Asset_Import_Pipeline]"
---

# Godot Project Layout Conventions

Standardized project structure ensures AI agents, human developers, and CI systems can navigate and modify Godot projects predictably. This convention applies to all Godot 4.x projects in the studio.

## Root Structure

```
project_root/
├── project.godot          # Main project file (NEVER rename)
├── icon.svg               # Project icon (auto-generated)
├── .gitattributes         # Git LFS configuration
├── .gitignore             # Godot-specific ignores
├── README.md              # Project documentation
├── CHANGELOG.md           # Version history
├── LICENSE                # Project license
│
├── addons/                # Third-party plugins and addons
│   ├── gut/               # GUT testing framework
│   ├── logger/            # Logging utilities
│   └── ...
│
├── assets/                # Raw source assets (Git LFS)
│   ├── audio/             # WAV, OGG source files
│   ├── images/            # PNG, JPG source files
│   ├── models/            # Blend, FBX source files
│   ├── fonts/             # TTF, OTF font files
│   └── shaders/           # GLSL shader source
│
├── src/                   # All game code and scenes
│   ├── autoload/          # Global singletons
│   ├── core/              # Core systems (input, save, audio)
│   ├── entities/          # Game entities (player, enemies, NPCs)
│   ├── ui/                # UI scenes and scripts
│   ├── levels/            # Level scenes and tilemaps
│   ├── resources/         # Custom resource definitions
│   ├── utils/             # Utility scripts and helpers
│   └── tests/             # Test scenes and test scripts
│
├── docs/                  # Project documentation
│   ├── architecture/      # Architecture decisions
│   ├── api/               # API documentation
│   └── guides/            # Developer guides
│
├── scripts/               # Build and automation scripts
│   ├── setup.sh           # Initial project setup
│   ├── test.sh            # Run all tests locally
│   ├── export.sh          # Build exports
│   └── ci/                # CI-specific scripts
│
└── builds/                # Build outputs (gitignored)
    ├── debug/
    ├── release/
    └── steam/
```

## The `src/` Directory Convention

All game code MUST reside in `src/`. Do not scatter scripts at the project root.

### `src/autoload/`
Global singletons loaded via Project Settings → Autoload.

```
src/autoload/
├── game_state.gd          # Global game state manager
├── audio_manager.gd       # Audio playback control
├── scene_manager.gd       # Scene transition handling
├── input_manager.gd       # Input abstraction layer
├── save_manager.gd        # Save/load system
└── event_bus.gd           # Global event system
```

**Rule**: Maximum 8 autoloads. If you need more, refactor into hierarchical systems.

### `src/core/`
Fundamental systems that don't fit entity model.

```
src/core/
├── constants.gd           # Game constants (enums, config)
├── types.gd               # Type definitions and custom classes
├── pool_manager.gd        # Object pooling
└── ...
```

### `src/entities/`
All game entities with consistent naming:

```
src/entities/
├── player/
│   ├── player.tscn        # Main player scene
│   ├── player.gd          # Player controller script
│   ├── player_state.gd    # Player state machine
│   └── sprites/           # Player-specific sprites
├── enemy/
│   ├── base_enemy.tscn
│   ├── base_enemy.gd
│   ├── enemy_types/
│   │   ├── slime/
│   │   └── goblin/
└── projectile/
    └── ...
```

**Naming Rule**: Folder name matches scene root node name matches script class_name.

### `src/ui/`
UI scenes organized by screen/purpose:

```
src/ui/
├── components/            # Reusable UI components
│   ├── health_bar/
│   ├── button_custom/
│   └── dialog_box/
├── screens/               # Full-screen UI
│   ├── main_menu/
│   ├── pause_menu/
│   └── hud/
├── themes/                # UI themes and styles
│   └── default_theme.tres
└── transitions/           # Screen transition effects
```

### `src/levels/`
Level scenes and related data:

```
src/levels/
├── _templates/            # Level template scenes
├── world_01/
│   ├── level_01_01.tscn
│   ├── level_01_02.tscn
│   └── tilesets/
└── world_02/
    └── ...
```

### `src/tests/`
Test organization mirrors `src/` structure:

```
src/tests/
├── unit/                  # Unit tests (GUT)
│   ├── entities/
│   ├── core/
│   └── utils/
├── integration/           # Integration tests
│   └── ...
└── scenes/                # Test scenes for manual testing
    └── ...
```

## File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Scenes | `snake_case.tscn` | `player.tscn`, `main_menu.tscn` |
| Scripts | `snake_case.gd` | `player.gd`, `game_state.gd` |
| Resources | `PascalCase.tres` | `PlayerStats.tres`, `WeaponData.tres` |
| Shaders | `snake_case.gdshader` | `water_effect.gdshader` |
| Materials | `snake_case.tres` | `metal_material.tres` |
| TileSets | `snake_case.tres` | `dungeon_tileset.tres` |

## Scene Organization

Every scene file MUST follow this node structure:

```
Player (CharacterBody2D) - Root node, matches filename
├── Sprite2D              # Visual representation
├── CollisionShape2D      # Physics
├── AnimationPlayer       # Animations
└── StateMachine          # Logic (if applicable)
```

**Rule**: The root node's name MUST match the scene filename (without extension).

## Git Configuration

### .gitignore
```gitignore
# Godot 4 specific ignores
.import/
export.cfg
export_presets.cfg
*.tmp
*.translation

# Build outputs
builds/

# OS files
.DS_Store
Thumbs.db
```

### .gitattributes
```gitattributes
# Git LFS for binary assets
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.fbx filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text
```

## Enforcement

### Pre-commit Hook
```bash
#!/bin/bash
# scripts/hooks/pre-commit
# Validate project structure

# Check for files outside src/
if git diff --cached --name-only | grep -E "^[^/]+\.gd$"; then
    echo "ERROR: Scripts must be in src/ directory"
    exit 1
fi

# Check naming conventions
# ... additional checks
```

### CI Validation
The [[Godot_CI_Template]] validates:
- All .gd files are in src/
- Scene root names match filenames
- No orphaned .tscn files (missing scripts)

## Migration from Non-Standard Layout

1. Create new folder structure alongside existing
2. Move files incrementally, updating references
3. Use Godot's "Move To" dialog to auto-update dependencies
4. Run tests after each move
5. Delete old structure once complete

## See Also

- [[Godot_Autoload_Conventions]] - Singleton organization
- [[Godot_Asset_Import_Pipeline]] - Asset import settings
- [[Godot_GDScript_Style_Guide]] - Code style conventions
