# Ironcore Arena - Project Summary

## Overview
Single-player robot combat simulation built in Godot 4. Players build bots from modular parts, command them in real-time arena battles.

## Current Version
v0.1.0 MVP - Core loop playable, 4 arenas, tiered progression system

## Tech Stack
- Engine: Godot 4.x
- Language: GDScript (strict typing)
- Data: JSON files for content
- Saves: JSON (`user://ironcore_save.json`)

## Key Singletons (Autoload)
| Name | File | Purpose |
|------|------|---------|
| DataLoader | autoload/DataLoader.gd | Loads/caches JSON game data |
| GameState | autoload/GameState.gd | Player profile, credits, progression |
| SimulationManager | autoload/SimulationManager.gd | 60Hz battle simulation |
| SaveManager | autoload/SaveManager.gd | Save/load with version migration |
| AudioManager | autoload/AudioManager.gd | Sound categories, music |
| VFXManager | autoload/VFXManager.gd | Particles, screen shake |
| EventBus | autoload/event_bus.gd | Decoupled pub/sub signals |

## Core Game Loop
1. Build bot in Builder (select chassis, weapons, armor)
2. Select arena from Campaign map
3. Battle: Command bot (drag to move, drag to attack)
4. Results screen with stats and credits
5. Shop to buy new parts
6. Progress to next tier

## Content Structure
- `data/components.json` - Chassis, weapons, plating, mobility, sensors
- `data/campaign.json` - Arenas, enemy loadouts, progression tiers
- `assets/` - Sprites (currently procedural/generated)
- `audio/` - Sound effects (currently synthesized)

## Simulation Details
- 60Hz fixed timestep
- Deterministic (seeded RNG)
- Max 3 minutes per battle
- Commands: move, attack, hold position
- AI profiles: aggressive, defensive, balanced

## Current State
- 4 campaign arenas (1→2→3→4 enemies)
- 3 chassis types, 6 weapon types, 5 armor types
- Shop, save/load, tier progression implemented
- Placeholder art and audio

## Critical Paths
1. Battle simulation correctness (determinism, no crashes)
2. UI flow (Main Menu → Builder → Battle → Results)
3. Save/load stability (progression must persist)
