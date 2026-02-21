# IRONCORE ARENA - 30 Mission Design Discussion
## Planning the Full Campaign

---

## CURRENT STATE (5 Arenas)

| # | Arena | Theme | Size | Player Bots | Enemies | Weight Cap |
|---|-------|-------|------|-------------|---------|------------|
| 1 | Boot Camp | Clean/Grey | 600×400 | 1 | 1 Scout | 80 pts |
| 2 | Iron Graveyard | Rust/Orange | 800×600 | 2 | 2 bots | 100 pts |
| 3 | Kill Grid | Tech/Dark | 1000×700 | 3 | 2 bots + hazards | 130 pts |
| 4 | The Gauntlet | Industrial | 1200×500 | 1 | 3 bots (waves) | 150 pts |
| 5 | Champion's Pit | Boss Arena | 900×900 | 2 | Boss + 4 bots | 200 pts |

---

## DESIGN QUESTIONS

### 1. Mission Variety

**Option A: Pure Elimination**
- Every mission: Destroy all enemies
- Simple, straightforward
- Risk: Repetitive

**Option B: Mixed Objectives**
- Elimination (destroy all)
- Survival (hold X minutes)
- Defense (protect target)
- Assault (capture points)
- Escort (move VIP to exit)

**Recommendation:** Mix objectives from Mission 6 onwards. Keep first 5 simple for learning.

---

### 2. Environment Variety

**Current Themes:**
- Clean/Grey (training)
- Rust/Orange (industrial decay)
- Tech/Dark (hazards)
- Industrial (chokepoints)
- Boss Arena (epic)

**Potential New Themes:**
- **Frozen Wastes** (Ice, slow movement, white/blue)
- **Lava Fields** (Environmental damage, red/orange)
- **Urban Ruins** (Buildings, streets, cover)
- **Desert Dunes** (Open, sand, tan/yellow)
- **Underground Cave** (Tight spaces, bioluminescent)
- **Sky Platform** (Open edges, fall hazards)
- **Factory Assembly** (Moving parts, conveyor belts)
- **Cyber Void** (Digital, neon, glitch effects)

**Question:** How many unique themes for 30 missions? 
- Option: 10 themes × 3 missions each
- Option: 15 themes × 2 missions each
- Option: 6 themes with variations (lighting, obstacles)

---

### 3. Difficulty Progression

**Current Progression:**
Linear increase in enemies and weight caps

**Alternative: Sawtooth Pattern**
```
Difficulty
    │    ╱╲      ╱╲      ╱╲
    │   ╱  ╲    ╱  ╲    ╱  ╲
    │  ╱    ╲  ╱    ╲  ╱    ╲
    │ ╱      ╲╱      ╲╱      ╲
    └───────────────────────────
      1  5  10  15  20  25  30
      
      Hard missions at: 5, 10, 15, 20, 25, 30
      (Boss/challenge levels)
```

**Benefit:** Easy missions after hard ones let players recover/farm.

---

### 4. Player Army Growth

**Current Plan:**
- Missions 1-10: 1-3 bots
- Missions 11-20: 4-7 bots
- Missions 21-30: 8-15 bots

**Question:** How does the player control 15 bots effectively?

**Options:**
A. **Individual control** (RTS-style, lots of micro)
B. **Squad system** (Select squads of 3-5, control as groups)
C. **AI behaviors** (Set tactics, AI handles details)
D. **Formation system** (Bots stay in formations, move as one)

**Recommendation:** Start with individual control, add formations later.

---

### 5. Enemy Scaling

**Current Enemy Counts:**
- Act I: 1-8 enemies
- Act II: 6-20 enemies
- Act III: 15-50+ enemies

**Question:** What does "50 enemies" look like?

**Visual Impact:**
- Screen full of bots
- May need LOD (level of detail) for distant bots
- Particle effects become expensive
- Camera needs to zoom out very far

**Technical Limits:**
- Godot can handle 100+ simple nodes
- Physics collisions become expensive
- Pathfinding for 50+ units = lag

**Solutions:**
1. **Hybrid approach:** 15 player bots vs 30 enemies = 45 total (doable)
2. **Wave system:** Not all enemies on screen at once
3. **Simplified AI:** Distant bots use cheaper AI
4. **Size limits:** Mission 30 = 15v30, not 15v50

**Recommendation:** Cap at 40 total bots on screen. Use waves for "50 enemies."

---

## PROPOSED ARENA IDEAS

### Act I: Recruit (Missions 1-10) - 3 More Needed

| # | Name | Theme | Objective | Special |
|---|------|-------|-----------|---------|
| 6 | Frozen Outpost | Ice | Elimination | Slow movement |
| 7 | Sandstorm Valley | Desert | Survival (2 min) | Visibility reduced |
| 8 | Ruin Run | Urban | Elimination | Building cover |
| 9 | Cavern Clash | Cave | Assault (2 points) | Tight spaces |
| 10 | The Trial | Arena | Boss | Single strong enemy |

### Act II: Veteran (Missions 11-20) - 10 Needed

| # | Name | Theme | Objective | Special |
|------|------|-------|-----------|---------|
| 11 | Molten Forge | Lava | Elimination | Floor damage |
| 12 | Sky Dock | Platform | Defense | Fall hazards |
| 13 | Factory Floor | Industrial | Escort | Moving cover |
| 14 | Digital Domain | Cyber | Elimination | Teleporters |
| 15 | The Colosseum | Arena | Survival (5 min) | Wave survival |
| 16 | Wasteland Run | Desert | Assault | Open terrain |
| 17 | Ice Breaker | Frozen | Elimination | Ice cracks |
| 18 | Metro Mayhem | Urban | Defense | Subway tunnels |
| 19 | Lava Lake | Volcanic | Elimination | Rising lava |
| 20 | The Gauntlet II | Industrial | Boss | Upgraded Gauntlet |

### Act III: Commander (Missions 21-30) - 10 Needed

| # | Name | Theme | Objective | Special |
|------|------|-------|-----------|---------|
| 21 | Siege Engine | Castle | Assault | Destruction |
| 22 | Void Sector | Space | Elimination | Low gravity |
| 23 | City Center | Urban | Defense | Multi-point |
| 24 | Scorched Earth | Wasteland | Survival | Everything |
| 25 | Factory Zero | Industrial | Escort | Moving parts |
| 26 | Crystal Caverns | Cave | Elimination | Reflective surfaces |
| 27 | Sky Fortress | Platform | Assault | Verticality |
| 28 | The Badlands | Desert | Defense | Long sightlines |
| 29 | Core Meltdown | Volcanic | Survival | Collapsing arena |
| 30 | IRONCORE PRIME | Arena | Final Boss | All mechanics |

---

## UNIQUE MECHANICS TO ADD

### Hazards (Environmental)
- [x] Mines (Kill Grid)
- [ ] Lava/Fire damage
- [ ] Ice (slippery/slow)
- [ ] Turrets (neutral, shoot everything)
- [ ] Teleporters
- [ ] Moving platforms
- [ ] Collapsing floors
- [ ] Fog of war (limited vision)

### Dynamic Elements
- [ ] Time of day (lighting changes)
- [ ] Weather (rain, snow, sandstorm)
- [ ] Destructible cover
- [ ] Reinforcements (mid-battle arrivals)
- [ ] Vehicle/structure destruction

---

## DECISIONS NEEDED

### 1. How many unique themes?
**Options:**
- A. 6 core themes, variations for 30 levels
- B. 10 distinct themes
- C. 15+ themes (every 2 missions new look)

**My recommendation:** 10 themes, 3 missions each. Players get variety without asset overload.

### 2. How many total bots on screen?
**Options:**
- A. 20 max (10v10) - Safe, runs everywhere
- B. 40 max (15v25) - Balanced
- C. 60+ max (20v40) - Epic but risky

**My recommendation:** 40 max. Mission 30 = 15 player bots vs 25 enemies (with waves).

### 3. Tutorial integration?
**Options:**
- A. Boot Camp is the only tutorial
- B. First 3 missions teach mechanics
- C. Full guided tutorial (popup text)

**My recommendation:** Boot Camp teaches basics, first 5 gradually introduce concepts.

### 4. Boss frequency?
**Options:**
- A. Boss every 10 missions (3 total)
- B. Boss every 5 missions (6 total)
- C. Boss every mission mini-boss + big bosses

**My recommendation:** Major boss at 10, 20, 30. Mini-bosses at 5, 15, 25.

---

## NEXT STEPS

**To build the remaining 25 arenas, I need:**

1. ✅ Theme list (decided above)
2. ✅ Objective variety (decided above)  
3. ✅ Difficulty curve (sawtooth pattern)
4. ✅ Enemy counts per mission
5. ⚠️ Arena size progression
6. ⚠️ Weight cap progression
7. ⚠️ Entry fee/reward progression

**Once decided, I can:**
- Generate all 30 arena JSON files
- Balance enemy compositions
- Set up unlock progression

---

## YOUR CALL

**Which decisions need your input?**

1. **Theme variety** - How many unique looks?
2. **Max bots** - 20, 40, or 60+ on screen?
3. **Tutorial style** - Minimal or guided?
4. **Boss frequency** - Every 5 or every 10 missions?
5. **Mission objectives** - All elimination or mixed?

**Or should I just make the call and build them?**
