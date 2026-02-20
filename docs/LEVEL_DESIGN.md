# IRONCORE ARENA - Level Design Document
## Arena Identity, Enemies & Combat Flow

---

## ARENA 1: BOOT CAMP

### Identity
**Theme:** Training facility, clean, structured
**Purpose:** Tutorial - teach player basic mechanics
**Mood:** Safe, controlled, educational

### Visual Aesthetic
- **Floor:** Clean grey concrete with grid lines
- **Walls:** Simple barriers, white/yellow safety stripes
- **Lighting:** Bright, even, no shadows
- **Props:** Target dummies, training equipment (non-interactive)
- **Color:** Neutral greys, safety yellow accents

### Layout
- Open central area (400×300)
- Minimal obstacles (1-2 simple barriers)
- Clear sight lines everywhere
- Symmetrical - fair for learning

### Enemy Composition
| Slot | Type | Behavior | Purpose |
|------|------|----------|---------|
| 1 | Scout T1 | Balanced AI | Teach basic combat |

### Fighting Style
- **Player advantage:** 1v1, plenty of space
- **Enemy behavior:** Standard - moves, shoots, takes cover occasionally
- **Pacing:** Slow, predictable
- **Learning goals:**
  - How to select bots
  - How to issue move commands
  - How to issue attack commands
  - How damage/HP works

### Difficulty
- **Rating:** ⭐ (Very Easy)
- **Win rate expected:** 95%+
- **No fail state:** Can retry infinitely

### Narrative Hook
"Welcome to the Arena. Your first match is a training bout against a standard scout unit. Learn the controls, commander."

---

## ARENA 2: IRON GRAVEYARD

### Identity
**Theme:** Rusted scrapyard, industrial decay
**Purpose:** Introduce cover mechanics and flanking
**Mood:** Dangerous but manageable, territorial

### Visual Aesthetic
- **Floor:** Rust-orange metal plates, oil stains
- **Walls:** Scrap metal barriers, irregular heights
- **Lighting:** Dim, warm (amber/orange glow)
- **Props:** Crushed vehicles, scrap piles, chains
- **Color:** Rust orange, brown, dark metal

### Layout
- Central corridor with side alcoves
- Multiple cover points (4-6 barriers)
- Choke points and flanking routes
- Asmetrical - requires positioning strategy

### Enemy Composition
| Slot | Type | Behavior | Purpose |
|------|------|----------|---------|
| 1 | Fighter T1 | Aggressive AI | Frontline pressure |
| 2 | Scout T1 | Flanker AI | Teaches cover/flanking |

### Fighting Style
- **Player challenge:** 1v2, must use cover
- **Enemy coordination:** 
  - Fighter pushes aggressively
  - Scout tries to flank around cover
- **Pacing:** Medium, requires awareness
- **Learning goals:**
  - Using cover effectively
  - Managing multiple enemies
  - Positioning matters

### Difficulty
- **Rating:** ⭐⭐ (Easy)
- **Win rate expected:** 75%
- **Failure teaches:** Cover usage, kiting

### Strategic Considerations
- Cover breaks line of sight
- Enemies will try to surround
- Staying in open = bad
- Mobile tactics beat standing still

### Narrative Hook
"The Graveyard is where failed bots go to die. These scrap-salvagers don't welcome visitors. Watch your corners."

---

## ARENA 3: KILL GRID

### Identity
**Theme:** Death trap, precision danger
**Purpose:** Master hazards and advanced tactics
**Mood:** Intense, unforgiving, tactical

### Visual Aesthetic
- **Floor:** Dark metal with glowing hazard grid
- **Walls:** Energy barriers, laser fences
- **Lighting:** Dark with neon accents (red/cyan warning lights)
- **Props:** Mines, turrets, pressure plates
- **Color:** Dark blue/black, warning red, tech cyan

### Layout
- Large open area with hazard zones
- Central "safe" corridor
- Minefield perimeter
- Elevated sniper positions

### Enemy Composition
| Slot | Type | Behavior | Purpose |
|------|------|----------|---------|
| 1 | Tank T1 | Defensive AI | Anchor point, absorbs damage |
| 2 | Fighter T1 | Aggressive AI | Pressure and disruption |
| 3 | Sniper T2 | Support AI | Area denial, punish mistakes |

### Fighting Style
- **Player challenge:** 1v3, positional puzzle
- **Enemy coordination:**
  - Tank holds center, draws fire
  - Fighter flanks aggressively
  - Sniper spawns later, covers angles
- **Pacing:** Fast, tactical, unforgiving
- **Learning goals:**
  - Hazard awareness (mines)
  - Priority targeting (sniper first?)
  - Advanced positioning
  - Managing 3v1

### Hazards
- **Proximity Mines:** 40 damage, 3s arm time
- **Location:** Central field (avoid) vs edges (safer)
- **Tactical use:** Can kite enemies into mines

### Difficulty
- **Rating:** ⭐⭐⭐⭐ (Hard)
- **Win rate expected:** 40%
- **Failure teaches:** Positioning, priorities, hazard awareness

### Strategic Considerations
- Mines are indiscriminate (enemy bots also take damage)
- Sniper must be dealt with quickly
- Tank is tanky but slow - ignore or focus?
- Open ground is deadly (sniper + mines)

### Narrative Hook
"The Grid is a death sentence. Mines, snipers, and heavy armor. Only commanders who understand positioning survive the Kill Grid."

---

## ENEMY AI PROFILES BY ARENA

### Boot Camp - Standard
```
AI: ai_balanced
Aggression: 0.5
Cover Usage: 0.3
Flanking: 0.2
Retreat Threshold: 20% HP
```

### Iron Graveyard - Aggressive + Flanker
```
Fighter AI: ai_aggressive
- Pushes constantly
- Low retreat threshold (10%)
- Ignores cover for aggression

Scout AI: ai_flanker  
- High flanking weight
- Uses cover to approach
- Targets weak/flanked bots
```

### Kill Grid - Coordinated Team
```
Tank AI: ai_defensive
- Holds position
- High cover usage
- Protects sniper sight lines

Fighter AI: ai_brawler
- Aggressive but smart
- Retreats to tank if damaged
- Coordinates with tank

Sniper AI: ai_sniper
- Maximum range
- Prioritizes damaged targets
- Relocates if flanked
```

---

## PROGRESSION FLOW

```
Boot Camp (Tutorial)
    ↓ [Win]
Iron Graveyard (Cover/Flanking)
    ↓ [Win + 150 CR]
Kill Grid (Hazards/3v1)
    ↓ [Win + 300 CR]
The Gauntlet (Chokepoints/Waves)
    ↓ [Win + 450 CR]
Champion's Pit (Boss Battle)
    ↓ [Win + 1000 CR]
[Campaign Complete - Tier 3 Unlocked]
```

---

## ARENA SUMMARY (5 Total)

| # | Arena | Tier | Size | Enemies | Difficulty | Teaching |
|---|-------|------|------|---------|------------|----------|
| 1 | Boot Camp | 1 | 600×400 | 1 Scout | ⭐ | Basic controls |
| 2 | Iron Graveyard | 1 | 800×600 | 2 bots | ⭐⭐ | Cover/flanking |
| 3 | Kill Grid | 2 | 1000×700 | 3 bots + mines | ⭐⭐⭐⭐ | Hazards |
| 4 | The Gauntlet | 2 | 1200×500 | 5 bots (waves) | ⭐⭐⭐⭐ | Positioning |
| 5 | Champion's Pit | 3 | 900×900 | Boss + 4 bots | ⭐⭐⭐⭐⭐ | Everything |

---

## ENEMY VARIANTS BY TIER

### Tier 1 (Starting)
- Scout T1: Fast, light, machine gun
- Fighter T1: Balanced, cannon
- Tank T1: Slow, heavy armor, launcher

### Tier 2 (Unlock after Kill Grid)
- Scout T2: +Sensors, better accuracy
- Fighter T2: +Mobility, faster
- Tank T2: +Armor, repair ability
- Sniper T1: Long range, beam weapon
- Support T1: Utility, repair others

---

## AESTHETIC PROGRESSION

| Arena | Color | Mood | Complexity |
|-------|-------|------|------------|
| Boot Camp | Grey/Yellow | Safe/Clean | Simple |
| Iron Graveyard | Orange/Brown | Gritty/Danger | Medium |
| Kill Grid | Red/Blue/Cyan | Deadly/Tech | Complex |

---

## DESIGN PRINCIPLES

1. **Each level teaches one thing**
   - Boot Camp: Basic controls
   - Graveyard: Cover
   - Grid: Hazards + multi-enemy

2. **Difficulty ramps smoothly**
   - 1v1 → 1v2 → 1v3
   - Open → Cover → Hazards
   - Static → Mobile → Coordinated

3. **Visual language matches danger**
   - Bright/safe → Dark/dangerous
   - Clean → Rusty → Tech
   - Grey → Orange → Red

4. **Enemy naming matches theme**
   - Boot Camp: "Trainee"
   - Graveyard: "Scrapper", "Salvager"
   - Grid: "Hunter", "Sentinel", "Executioner"

---

## IMPLEMENTATION CHECKLIST

- [x] Boot Camp arena data
- [x] Iron Graveyard arena data  
- [x] Kill Grid arena data
- [ ] Boot Camp enemy variant (Trainee Scout)
- [ ] Graveyard enemy variants (Scrapper Fighter, Salvager Scout)
- [ ] Grid enemy variants (Hunter Tank, Executioner Sniper)
- [ ] AI profile: ai_flanker
- [ ] AI profile: ai_sniper
- [ ] AI profile: ai_brawler
- [ ] Hazard: proximity mine
- [ ] Visual polish per arena theme

---

## NOTES

- Enemy names should appear in battle ("Scrapper Alpha destroyed!")
- Each arena should feel visually distinct at a glance
- Players should be able to predict arena style from name
- Difficulty should feel fair, not cheap
