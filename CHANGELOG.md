# Changelog

All notable changes to Ironcore Arena will be documented in this file.

## [0.1.0] - 2026-02-20

### Added - Initial MVP Release

#### Core Systems
- Component database with chassis, weapons, plating (JSON)
- DataLoader autoload for all game data
- Bot entity class with stats and composition
- BotAI system with tactical decision making
- Builder UI for creating bot loadouts

#### Battle System
- BattleManager orchestrates combat loop
- Arena scenes with 4 visual themes
- Win/Loss detection with multiple end conditions
- Results screen with S/A/B/C/D/F grading
- Battle HUD with team status and timer

#### Economy & Progression
- GameState autoload (credits, tier, progress)
- Shop system for buying components
- Save/Load system with JSON persistence
- Tier progression unlocking new content
- Campaign map with 4 unique arenas

#### Scene Flow
- Main menu with save detection
- Scene transitions with fade/wipe effects
- Campaign map for arena selection
- Tutorial system with 13-step guide

#### Polish
- AudioManager with sound categories
- VFXManager for particles and screen shake
- BalanceManager for centralized tuning
- Screen transition effects

#### Content
- **4 Campaign Arenas:**
  - Roxtan Park (Tier 1, Easy, 1 enemy)
  - Tory's Junkyard (Tier 2, Medium, 2 enemies)
  - Chrometek Rally (Tier 3, Hard, 3 enemies)
  - MetalMash 2057 (Tier 4, Expert, 4 enemies + Boss)

- **3 Chassis Types:** Scout, Fighter, Tank
- **6 Weapon Types:** Machine Gun, Cannon, Launcher, Beam, Sniper, Shotgun
- **5 Armor Types:** Light to Heavy plating

#### Development Tools
- SpriteGenerator - Procedural bot/weapon sprites
- TilesetGenerator - Procedural arena tiles
- UIThemeGenerator - UI themes and backgrounds
- SoundGenerator - Synthesized sound effects

### Known Limitations
- Procedural sprites are placeholders for final art
- Sound effects are synthesized (not recorded)
- No background music tracks yet

---

## [Unreleased]

### Planned for v0.2.0
- Replace procedural sprites with final pixel art
- Add authentic sound effect files
- Include background music tracks
- Steam integration
- Achievement system
