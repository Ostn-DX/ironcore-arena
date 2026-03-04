# IRONCORE ARENA v0.1.0

**Engine:** Godot 4.6 (2D, single-player)  
**Status:** Feature Complete ✅ | Art Production Phase 🎨  
**Target:** Steam release

Top-down deterministic bot-combat game. Build bots from discrete parts under weight constraints, then watch them fight autonomously in arena combat. Issue limited tactical commands to guide your squad.

---

## 🎮 Features (19/19 Complete)

### Core Systems
- ✅ Component database (JSON)
- ✅ DataLoader autoload
- ✅ Bot entity class
- ✅ BotAI system
- ✅ Builder UI foundation

### Battle System
- ✅ BattleManager (spawn, combat loop)
- ✅ Arena scene (4 themes, boundaries)
- ✅ Win/Loss detection
- ✅ Results screen (rewards, stats)

### Economy & Progression
- ✅ GameState autoload (credits, tier)
- ✅ Shop system (buy components)
- ✅ Save/Load (JSON persistence)
- ✅ Tier progression (unlock arenas)

### Scene Flow
- ✅ Main menu
- ✅ Scene transitions
- ✅ Battle HUD

### Polish
- ✅ Sound effects framework
- ✅ Visual effects framework
- ✅ Balance manager

---

## 📁 Project Structure

```
ironcore-work/
├── project/              # Godot 4.6 project
│   ├── src/
│   │   ├── entities/     # Bot, Arena, Projectile, etc.
│   │   ├── managers/     # BattleManager, ShopManager, etc.
│   │   ├── systems/      # AI, Movement, Combat systems
│   │   ├── ui/           # UI screens and components
│   │   └── tools/        # SpriteGenerator, etc.
│   ├── autoload/         # Singletons (GameState, AudioManager)
│   ├── scenes/           # Scene files (.tscn)
│   ├── data/             # JSON content files
│   └── assets/           # Sprites, audio, fonts
├── docs/                 # Documentation
│   ├── spec_v0_1_0/      # Game specification
│   ├── COMPLETION_CHECKLIST.md  # Full task list
│   └── ART_STATUS.md     # Art production tracking
├── data/                 # Component database
├── schemas/              # JSON schemas
└── tools/                # Validation scripts
```

---

## 🚀 Getting Started

### Prerequisites
- Godot 4.6 or later
- (Optional) Git for version control

### Running the Game
1. Clone/download the repository
2. Open `project/project.godot` in Godot
3. Press F5 or click "Run Project"

### Controls
- **Mouse**: Select bots, drag to issue commands
- **ESC**: Pause / Go back
- **Click + Drag**: Move bot or attack target

---

## 🎨 Current Phase: Art Production

### MVP Art Tasks (In Progress)
- [x] SpriteGenerator tool created
- [x] 3 chassis types (scout, fighter, tank)
- [x] 6 weapon types
- [ ] Arena tileset
- [ ] UI styling

See [`docs/ART_STATUS.md`](docs/ART_STATUS.md) for detailed progress.

---

## 🏗️ Architecture Highlights

### Deterministic Combat
- Fixed 60 ticks/second simulation
- Replay support via seed
- AI decision recording

### Component System
- 5 chassis types × 4 tiers
- 6 weapon types × 4 tiers
- 5 armor types × 4 tiers
- Weight-based loadout constraints

### Progression
- 4 tiers unlocking content
- Arena completion tracking
- Credit economy
- Component shop

---

## 📊 Game Balance

Centralized in `BalanceManager.gd`:
- Combat stats (HP, damage, speed)
- Economy (rewards, costs)
- Progression (weight limits, par times)
- AI difficulty scaling

---

## 🛠️ Development Tools

### SpriteGenerator
Procedurally generates placeholder sprites:
```gdscript
var gen = SpriteGenerator.new()
var texture = gen.generate_chassis_sprite("scout", 0)
```

### Balance Report
```gdscript
BalanceManager.print_balance_report()
```

---

## 📈 Next Steps

1. **Art Production** (Current)
   - Replace placeholder sprites
   - Create arena tilesets
   - UI polish

2. **Audio Implementation**
   - Add SFX files
   - Music tracks
   - Volume balancing

3. **Content**
   - 4+ playable arenas
   - Tutorial
   - Campaign map

4. **Distribution**
   - Steam build
   - Trailer
   - Store page

See [`docs/COMPLETION_CHECKLIST.md`](docs/COMPLETION_CHECKLIST.md) for full roadmap.

---

## 📜 License

[License TBD]

---

## 🙏 Credits

Developed by [Your Name/Team]

---

**Version:** 0.1.0  
**Last Updated:** 2026-02-20
