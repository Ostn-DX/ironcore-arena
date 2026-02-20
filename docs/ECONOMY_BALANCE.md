# IRONCORE ARENA - Economy & Weight Balance
## Arena Progression and Build Strategy

---

## CURRENT STATE ANALYSIS

### Component Weights (from components.json)

| Type | Light | Medium | Heavy |
|------|-------|--------|-------|
| **Chassis (self)** | 18-25 kg | 35 kg | 50-65 kg |
| **Plating** | 6-10 kg | 12-18 kg | 25 kg |
| **Weapons** | 8-15 kg | 20-28 kg | 30-35 kg |
| **Mobility** | 5-8 kg | 10-15 kg | 20 kg |

### Example Bot Builds

| Build | Chassis | Plating | Weapon | Mobility | **Total** |
|-------|---------|---------|--------|----------|-----------|
| **Speedster** | 18 kg | 6 kg | 8 kg | 5 kg | **37 kg** |
| **Scout** | 25 kg | 10 kg | 15 kg | 8 kg | **58 kg** |
| **Fighter** | 35 kg | 18 kg | 20 kg | 12 kg | **85 kg** |
| **Tank** | 50 kg | 25 kg | 35 kg | 20 kg | **130 kg** |
| **Super Heavy** | 65 kg | 25 kg | 35 kg | 20 kg | **145 kg** |

---

## PROBLEM: CURRENT ARENA WEIGHT LIMITS ARE TOO LOW

| Arena | Current Limit | Problem |
|-------|---------------|---------|
| Boot Camp | 50 kg | Can't even fit a Scout build (58kg) |
| Iron Graveyard | 70 kg | Fighter build (85kg) is over |
| Kill Grid | 90 kg | Tank build (130kg) is way over |
| Gauntlet | 100 kg | Still can't run a tank |
| Champion's Pit | 120 kg | Tank still doesn't fit |

### The Issue
Arena weight limits are supposed to challenge players to make strategic choices, but currently they're so low that most builds don't work. The limits should be:
- Low enough to force choices
- High enough to allow variety
- Progressive to reward unlocking better parts

---

## PROPOSED REVISED BALANCE

### Arena Weight Limits (Progressive)

| Arena | Tier | Weight Cap | Entry Fee | Reward | Strategy |
|-------|------|------------|-----------|--------|----------|
| **Boot Camp** | 1 | **80 kg** | 0 CR | 100 CR | Light builds only, speed matters |
| **Iron Graveyard** | 1 | **100 kg** | 50 CR | 200 CR | Medium builds viable |
| **Kill Grid** | 2 | **130 kg** | 150 CR | 400 CR | Heavy builds possible |
| **The Gauntlet** | 2 | **150 kg** | 300 CR | 600 CR | Multiple bot strategy |
| **Champion's Pit** | 3 | **200 kg** | 500 CR | 1200 CR | Bring your best |

### Why These Numbers Work

| Arena | Limit | Can Use | Can't Use | Strategic Choice |
|-------|-------|---------|-----------|------------------|
| Boot Camp | 80kg | Speedster (37), Scout (58) | Fighter (85), Tank (130) | Speed vs armor tradeoff |
| Iron Graveyard | 100kg | +Fighter (85) | Tank (130) | Medium is the sweet spot |
| Kill Grid | 130kg | +Tank (130) | Super Heavy (145) | Heavy viable but limited |
| Gauntlet | 150kg | +Super Heavy (145), 2x bots | None really | Team composition matters |
| Champion's Pit | 200kg | Everything + extras | - | Pure power test |

---

## ENEMY WEIGHT MATCHING

### Current Enemy Builds (Enemy Weight Budgets)

| Enemy | Chassis | Plating | Weapon | Est. Weight |
|-------|---------|---------|--------|-------------|
| **Trainee Scout** | Light (25) | Light (10) | MG (15) | **~50 kg** |
| **Scrapper Fighter** | Medium (35) | Medium (18) | Cannon (28) | **~81 kg** |
| **Salvager Scout** | Light (25) | Light (10) | MG (15) | **~50 kg** |
| **Hunter Tank** | Heavy (50) | Heavy (25) | Launcher (30) | **~105 kg** |
| **Raider Fighter** | Medium (35) | Light (12) | Shotgun (18) | **~65 kg** |
| **Executioner Sniper** | Medium (35) | Medium (18) | Sniper (28) | **~81 kg** |
| **THE CHAMPION** | Heavy (65) | Heavy (25) | Cannon (35) | **~145 kg** |

### Arena Enemy Weight Totals

| Arena | Enemies | Enemy Weight Total | Player Limit | Advantage |
|-------|---------|-------------------|--------------|-----------|
| Boot Camp | 1 Scout | 50 kg | 80 kg | +30kg (player advantage) |
| Iron Graveyard | Fighter + Scout | 131 kg | 100 kg | -31kg (underdog) |
| Kill Grid | Tank + Raider + Sniper | 251 kg | 130 kg | -121kg (major underdog) |
| Gauntlet | 5 bots | ~350 kg | 150 kg | -200kg (wave survival) |
| Champion's Pit | Boss + 4 | ~500 kg | 200 kg | -300kg (boss fight) |

---

## ECONOMY BALANCE

### Entry Fee vs Reward Structure

| Arena | Entry | Reward | Net Profit | ROI | Risk/Reward |
|-------|-------|--------|------------|-----|-------------|
| Boot Camp | 0 | 100 | +100 | ∞% | Free practice |
| Iron Graveyard | 50 | 200 | +150 | 300% | Good beginner farm |
| Kill Grid | 150 | 400 | +250 | 267% | Risk increases |
| Gauntlet | 300 | 600 | +300 | 200% | High stakes |
| Champion's Pit | 500 | 1200 | +700 | 240% | Worth the risk |

### Progression Pacing

Starting credits: **500 CR**

| Step | Action | Credits After |
|------|--------|---------------|
| 1 | Win Boot Camp | 600 CR |
| 2 | Buy medium chassis (-550) | 50 CR |
| 3 | Win Iron Graveyard (+150 net) | 200 CR |
| 4 | Buy better plating (-380) | -180 CR (need to grind) |
| 5 | Win Boot Camp again | -80 CR → 20 CR |
| 6 | Win Graveyard again | 170 CR |
| 7 | Now ready for Kill Grid | ... |

---

## RECOMMENDED CHANGES

### 1. Update Arena Weight Limits

```json
{
  "arena_boot_camp": { "weight_cap": 80 },
  "arena_iron_graveyard": { "weight_cap": 100 },
  "arena_kill_grid": { "weight_cap": 130 },
  "arena_the_gauntlet": { "weight_cap": 150 },
  "arena_champions_pit": { "weight_cap": 200 }
}
```

### 2. Update Entry Fees & Rewards

```json
{
  "arena_boot_camp": { "entry_fee": 0, "reward_credits": 100 },
  "arena_iron_graveyard": { "entry_fee": 50, "reward_credits": 200 },
  "arena_kill_grid": { "entry_fee": 150, "reward_credits": 400 },
  "arena_the_gauntlet": { "entry_fee": 300, "reward_credits": 600 },
  "arena_champions_pit": { "entry_fee": 500, "reward_credits": 1200 }
}
```

### 3. Adjust Enemy Difficulty

Kill Grid and Gauntlet might be too hard with current enemy counts:

| Arena | Current Enemies | Suggested | Reason |
|-------|-----------------|-----------|--------|
| Kill Grid | 3 enemies | 2 enemies | 251kg vs 130kg is too punishing |
| Gauntlet | 5 enemies | 4 enemies | Better pacing for waves |

Alternative: Give player 2 bot slots for harder arenas.

---

## STRATEGIC BUILD RECOMMENDATIONS

### Boot Camp (80kg limit)
**Best Build:** Speedster
- Chassis: Speedster V2 (18kg)
- Plating: Nano-Fiber (6kg)
- Weapon: Piranha SMG (15kg)
- Mobility: Light wheels (5kg)
- **Total: 44kg** ✓ Under 80kg

### Iron Graveyard (100kg limit)
**Best Build:** Scout or Light Fighter
- Chassis: AKAUMIN (25kg)
- Plating: Santrin (10kg)
- Weapon: Raptor Rifle (20kg)
- Mobility: Medium wheels (8kg)
- **Total: 63kg** ✓ Under 100kg

### Kill Grid (130kg limit)
**Best Build:** Medium Fighter
- Chassis: TORQ MK-1 (35kg)
- Plating: Steel Guard (18kg)
- Weapon: Thunder Cannon (35kg)
- Mobility: Tracks (15kg)
- **Total: 103kg** ✓ Under 130kg

### Gauntlet (150kg limit)
**Best Build:** Heavy or dual light bots
- Chassis: Titan-X (50kg)
- Plating: Titanium Weave (12kg)
- Weapon: Thunder Cannon (35kg)
- Mobility: Heavy tracks (20kg)
- **Total: 117kg** ✓ Under 150kg

### Champion's Pit (200kg limit)
**Best Build:** Super Heavy
- Chassis: Juggernaut 9000 (65kg)
- Plating: Imperium Plate (25kg)
- Weapon: Javelin Missile (30kg)
- Mobility: Heavy tracks (20kg)
- **Total: 140kg** ✓ Under 200kg, room for utility

---

## DECISION POINT

**Current system has arena limits LOWER than component capacities.**

Option A: Raise arena limits (recommended above)
Option B: Lower component capacities to match
Option C: Remove arena limits entirely, use only chassis limits

**My recommendation: Option A** - It creates interesting strategic choices while still allowing variety.

---

## IMPLEMENTATION CHECKLIST

- [ ] Update arena weight_cap values
- [ ] Update entry_fee and reward_credits
- [ ] Consider reducing enemy counts for balance
- [ ] Add weight display to builder UI
- [ ] Add "overweight" warning in builder
- [ ] Test each arena with max-weight build

---

## QUICK REFERENCE TABLE

| Arena | Weight Cap | Entry | Reward | Best Build Type |
|-------|------------|-------|--------|-----------------|
| Boot Camp | 80kg | 0 | 100 | Speedster |
| Iron Graveyard | 100kg | 50 | 200 | Scout/Light |
| Kill Grid | 130kg | 150 | 400 | Medium |
| Gauntlet | 150kg | 300 | 600 | Heavy |
| Champion's Pit | 200kg | 500 | 1200 | Super Heavy |
