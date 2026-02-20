# IRONCORE ARENA - FULL SCALE DESIGN
## 30 Mission Campaign with RTS Progression

---

## CORE VISION

**Ironcore Arena** evolves from a 5-arena demo into a **30-mission campaign** with exponential scaling:

- **Early game (Missions 1-10):** 1-3 player bots, intimate arenas
- **Mid game (Missions 11-20):** 4-7 player bots, larger battlefields  
- **Late game (Missions 21-30):** 10+ player bots, massive war zones vs 20+ enemies

**Visual Identity:** RTS camera with zoom (mouse wheel), pan (edge scroll or middle-click drag), and group selection (click-drag box).

---

## WEIGHT SYSTEM REDESIGN ("pts")

### All Components Have Weight

| Component Type | Weight Range (pts) |
|----------------|-------------------|
| **Chassis** | 10-80 pts |
| **Plating (Armor)** | 5-30 pts |
| **Weapons** | 8-40 pts |
| **Mobility** | 5-25 pts |
| **Sensors** | 3-15 pts |
| **Utilities** | 5-20 pts |

### Example Build Weights

| Build | Components | Total Weight |
|-------|-----------|--------------|
| **Light Scout** | Chassis 15 + Plating 5 + Weapon 8 + Wheels 5 | **33 pts** |
| **Medium Fighter** | Chassis 30 + Plating 12 + Weapon 20 + Tracks 10 | **72 pts** |
| **Heavy Tank** | Chassis 60 + Plating 25 + Weapon 35 + Tracks 20 | **140 pts** |
| **Command Unit** | Chassis 40 + Plating 15 + Weapon 15 + Sensors 10 + Repair 10 | **90 pts** |

---

## 30 MISSION CAMPAIGN STRUCTURE

### ACT I: RECRUIT (Missions 1-10)
**Theme:** Learning the ropes, small skirmishes
**Player Scale:** 1-3 bots
**Enemy Scale:** 1-5 bots
**Arena Size:** 600×400 to 1000×700

| Mission | Name | Player Bots | Enemies | Weight Cap | Special |
|---------|------|-------------|---------|------------|---------|
| 1 | Boot Camp | 1 | 1 | 50 pts | Tutorial |
| 2 | First Blood | 1 | 2 | 60 pts | Basic combat |
| 3 | Double Team | 2 | 2 | 80 pts | 2-bot control |
| 4 | Iron Graveyard | 2 | 3 | 100 pts | Cover mechanics |
| 5 | Ambush Alley | 2 | 4 | 110 pts | Flanking |
| 6 | Kill Grid | 3 | 3 | 130 pts | Hazards |
| 7 | The Gauntlet | 3 | 5 | 150 pts | Waves |
| 8 | Crossfire | 3 | 6 | 160 pts | Positioning |
| 9 | Breach Point | 3 | 7 | 180 pts | Chokepoints |
| 10 | Trial by Fire | 3 | 8 | 200 pts | Act I Boss |

### ACT II: VETERAN (Missions 11-20)
**Theme:** Larger battles, team tactics
**Player Scale:** 4-7 bots
**Enemy Scale:** 5-15 bots
**Arena Size:** 1000×800 to 2000×1500

| Mission | Name | Player Bots | Enemies | Weight Cap | Special |
|---------|------|-------------|---------|------------|---------|
| 11 | Squad Alpha | 4 | 6 | 250 pts | Squad tactics |
| 12 | Pincer Movement | 4 | 8 | 280 pts | Flanking |
| 13 | Hold the Line | 5 | 10 | 320 pts | Defensive |
| 14 | Breakthrough | 5 | 12 | 350 pts | Assault |
| 15 | The Meat Grinder | 6 | 15 | 400 pts | Survival |
| 16 | Urban Warfare | 6 | 12 | 450 pts | City ruins |
| 17 | Blitzkrieg | 7 | 14 | 500 pts | Speed run |
| 18 | Siege Engine | 7 | 16 | 550 pts | Destruction |
| 19 | No Man's Land | 7 | 18 | 600 pts | Mines + snipers |
| 20 | Champion's Pit | 7 | 20 | 700 pts | Act II Boss |

### ACT III: COMMANDER (Missions 21-30)
**Theme:** Full scale war, army vs army
**Player Scale:** 8-15 bots
**Enemy Scale:** 15-40 bots
**Arena Size:** 2000×1500 to 4000×3000

| Mission | Name | Player Bots | Enemies | Weight Cap | Special |
|---------|------|-------------|---------|------------|---------|
| 21 | Battalion | 8 | 15 | 800 pts | Company size |
| 22 | Iron Tide | 8 | 20 | 900 pts | Wave defense |
| 23 | Scorched Earth | 9 | 22 | 1000 pts | Destruction |
| 24 | The Killing Field | 9 | 25 | 1100 pts | Open warfare |
| 25 | Fortress Assault | 10 | 28 | 1200 pts | Siege |
| 26 | Armored Division | 10 | 30 | 1400 pts | Tank warfare |
| 27 | Total War | 12 | 35 | 1600 pts | Everything |
| 28 | The Apocalypse | 12 | 38 | 1800 pts | Survival |
| 29 | Final Stand | 15 | 40 | 2000 pts | Last defense |
| 30 | IRONCORE ARENA | 15 | 50+ | 2500 pts | Ultimate boss |

---

## ARENA SIZE PROGRESSION

### Visual Scaling

| Act | Typical Size | Camera Start | Zoom Range |
|-----|--------------|--------------|------------|
| **Act I** | 600×400 to 1000×700 | Close (1.0x) | 0.8x - 1.5x |
| **Act II** | 1200×900 to 2000×1500 | Medium (0.8x) | 0.5x - 1.5x |
| **Act III** | 2500×2000 to 4000×3000 | Far (0.5x) | 0.3x - 1.2x |

### RTS Camera Features

**Controls:**
- **Mouse Wheel:** Zoom in/out
- **Middle Click + Drag:** Pan camera
- **Edge Scrolling:** Move camera near screen edges
- **Spacebar:** Center on selected units
- **Mini-map:** Click to jump location

**Group Selection:**
- **Click:** Select single bot
- **Click-Drag Box:** Select multiple bots in area
- **Ctrl+Click:** Add to selection
- **Shift+Click:** Remove from selection
- **Double Click:** Select all bots of same type
- **Number Keys (1-9):** Assign control groups

---

## WEIGHT CAP PROGRESSION (EXPONENTIAL)

| Mission | Weight Cap | Player Bots | Cap per Bot (avg) |
|---------|------------|-------------|-------------------|
| 1 | 50 pts | 1 | 50 |
| 5 | 110 pts | 2 | 55 |
| 10 | 200 pts | 3 | 67 |
| 15 | 400 pts | 6 | 67 |
| 20 | 700 pts | 7 | 100 |
| 25 | 1200 pts | 10 | 120 |
| 30 | 2500 pts | 15 | 167 |

**Formula:** Weight Cap = 50 × (1.15 ^ Mission Number)

This allows:
- More bots over time
- Heavier bots over time
- Mix of light scouts + heavy tanks in late game

---

## ECONOMY SCALING

### Entry Fees & Rewards (Exponential)

| Mission | Entry Fee | Victory Reward | Net Profit |
|---------|-----------|----------------|------------|
| 1 | 0 | 100 | +100 |
| 5 | 100 | 300 | +200 |
| 10 | 500 | 1500 | +1000 |
| 15 | 2000 | 6000 | +4000 |
| 20 | 8000 | 25000 | +17000 |
| 25 | 30000 | 100000 | +70000 |
| 30 | 100000 | 500000 | +400000 |

**Grinding:** Early missions stay profitable for farming if player gets stuck.

---

## COMPONENT UNLOCK PROGRESSION

### Tier 0 (Start)
- Light chassis (15 pts)
- Basic plating (5 pts)
- Machine gun (8 pts)
- Wheels (5 pts)

### Tier 1 (Unlock Mission 3)
- Medium chassis (30 pts)
- Better plating (12 pts)
- Cannon (20 pts)
- Tracks (10 pts)

### Tier 2 (Unlock Mission 8)
- Heavy chassis (60 pts)
- Heavy plating (25 pts)
- Launcher (35 pts)
- Advanced sensors (10 pts)

### Tier 3 (Unlock Mission 15)
- Super heavy chassis (80 pts)
- Titan plating (30 pts)
- Beam weapons (40 pts)
- Shield generators (20 pts)

### Tier 4 (Unlock Mission 25)
- Ultimate chassis (100+ pts)
- Legendary weapons (50 pts)
- Experimental tech (varies)

---

## MISSION TYPES (VARIETY)

### Classic Elimination
Destroy all enemies. Standard.

### Survival (Hold X minutes)
Survive against endless waves.

### Assault (Capture points)
Control 3 strategic locations.

### Defense (Protect target)
Keep VIP unit or structure alive.

### Escort (Move target to exit)
Guide civilian bots across map.

### Annihilation (Destroy target)
Kill specific enemy unit.

### King of the Hill
Control center zone for X seconds.

### Resource War
Collect scrap piles faster than enemy.

---

## IMPLEMENTATION PRIORITY

### Phase 1: Core RTS (Next)
- [ ] RTS camera (zoom, pan)
- [ ] Group selection (box select)
- [ ] Control groups (1-9 keys)
- [ ] Mini-map
- [ ] Change "kg" to "pts" everywhere

### Phase 2: Scale (After)
- [ ] Add missions 6-10
- [ ] Implement all component weights
- [ ] Test 3-bot control

### Phase 3: Army Scale (Later)
- [ ] Add missions 11-20
- [ ] Optimize for 10+ bots
- [ ] Squad AI formations

### Phase 4: War Scale (Final)
- [ ] Add missions 21-30
- [ ] Optimize for 50+ bots
- [ ] Epic boss battles

---

## TECHNICAL NOTES

### Performance Targets
- **Act I (1-3 bots):** 60 FPS on any hardware
- **Act II (4-7 bots):** 60 FPS on mid-tier
- **Act III (10+ bots):** 30+ FPS on recommended

### Optimization Strategies
- Object pooling for projectiles
- Spatial hashing for collision
- LOD for distant bots (simplified visuals)
- Culling off-screen entities

### Camera Bounds
```gdscript
# Camera clamps to arena size
camera.position.x = clamp(camera.position.x, 0, arena_width)
camera.position.y = clamp(camera.position.y, 0, arena_height)

# Zoom limits based on arena
min_zoom = min(screen_width / arena_width, screen_height / arena_height) * 0.8
max_zoom = 1.5  # Don't zoom in too close
```

---

## SUMMARY

**Ironcore Arena v1.0 Vision:**
- 30 missions across 3 acts
- 1 bot → 15 bot progression
- Intimate arenas → massive war zones
- Simple controls → complex RTS
- Linear scaling → exponential growth

**This transforms the game from a 5-level demo into a full 20+ hour campaign.**

---

**Ready to implement Phase 1 (RTS camera + group selection)?**
