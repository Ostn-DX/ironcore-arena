# Ironcore Arena - Balance Analysis & Data
## Component Statistics, Efficiency Metrics, and Balance Recommendations

---

## CHASSIS ANALYSIS

### Raw Stats Comparison
| ID | Name | Tier | HP | Speed | Weight Cap | Cost | HP/₡ | Speed/₡ |
|----|------|------|-----|-------|-----------|------|------|---------|
| akaumin_dl2_100 | AKAUMIN DL2-100 | 0 | 80 | 5.0 | 120 | 300 | 0.27 | 0.017 |
| torq_mk1 | TORQ MK-1 | 1 | 120 | 4.2 | 150 | 550 | 0.22 | 0.008 |
| speedster_v2 | SPEEDSTER V2 | 1 | 60 | 7.0 | 100 | 480 | 0.13 | 0.015 |
| heavy_titan_x | TITAN-X | 2 | 180 | 3.0 | 200 | 900 | 0.20 | 0.003 |
| juggernaut_9000 | JUGGERNAUT 9000 | 3 | 250 | 2.5 | 250 | 1500 | 0.17 | 0.002 |

### Efficiency Analysis
**HP Efficiency (HP per Credit):**
- Best: AKAUMIN DL2-100 (0.27) - Starter chassis is most HP-efficient
- Worst: SPEEDSTER V2 (0.13) - Trading HP for speed
- Average Tier 1: 0.175

**Speed Efficiency (Speed per Credit):**
- Best: AKAUMIN DL2-100 (0.017) - Well-rounded
- Worst: JUGGERNAUT 9000 (0.002) - Heavy tank penalty
- SPEEDSTER V2 pays 2x cost for +40% speed vs AKAUMIN

### Balance Assessment
✅ **Well Balanced:** Cost curves are appropriate
⚠️ **Watch:** JUGGERNAUT may be underpowered for 1500₡ cost
💡 **Recommendation:** Consider +50 HP or damage reduction bonus for JUGGERNAUT

---

## PLATING (ARMOR) ANALYSIS

### Raw Stats Comparison
| ID | Name | Tier | HP Bonus | Dmg Red | Weight | Cost | HP/₡ | EHP* |
|----|------|------|----------|---------|--------|------|------|------|
| santrin_auro | SANTRIN AURO | 0 | 40 | 15% | 10 | 200 | 0.20 | 47 |
| nano_fiber_mesh | NANO-FIBER MESH | 1 | 25 | 10% | 6 | 450 | 0.06 | 28 |
| steel_guard | STEEL GUARD | 1 | 65 | 22% | 18 | 380 | 0.17 | 83 |
| titanium_weave | TITANIUM WEAVE | 2 | 50 | 18% | 12 | 620 | 0.08 | 61 |
| imperium_plate | IMPERIUM PLATE | 3 | 90 | 30% | 25 | 1100 | 0.08 | 129 |

*EHP = Effective HP = HP Bonus / (1 - Damage Reduction)

### Efficiency Analysis
**HP Efficiency (HP per Credit):**
- Best: SANTRIN AURO (0.20) - Starter armor best value
- Worst: NANO-FIBER (0.06) - Paying for low weight, not HP
- Tier 1 range: 0.06-0.17 (large variance)

**Effective HP per Credit:**
- Best: STEEL GUARD (0.22 EHP/₡)
- Worst: NANO-FIBER (0.06 EHP/₡)

### Balance Assessment
⚠️ **Issue Detected:** NANO-FIBER MESH is extremely expensive for its protection
  - Costs 2.25x SANTRIN but provides less EHP
  - Only advantage is 4 weight savings
  - 💡 **Recommendation:** Reduce cost to 300₡ or increase HP bonus to 35

✅ **Well Balanced:** STEEL GUARD is good middle-tier choice
✅ **Well Balanced:** IMPERIUM PLATE appropriate for endgame

---

## WEAPONS ANALYSIS

### Raw Stats Comparison
| ID | Name | Tier | Dmg Min | Dmg Max | Avg Dmg | Fire Rate | DPS | Cost | DPS/₡ |
|----|------|------|---------|---------|---------|-----------|-----|------|-------|
| raptor_dt_01 | RAPTOR DT-01 | 0 | 15 | 25 | 20 | 2.0 | 40 | 250 | 0.16 |
| piranha_smg | PIRANHA SMG | 1 | 8 | 14 | 11 | 6.0 | 66 | 420 | 0.16 |
| striker_rifle | STRIKER RIFLE | 1 | 30 | 45 | 38 | 1.5 | 57 | 580 | 0.10 |
| thunder_cannon | THUNDER CANNON | 2 | 80 | 120 | 100 | 0.5 | 50 | 950 | 0.05 |
| phoenix_laser | PHOENIX LASER | 2 | 45 | 55 | 50 | 3.0 | 150 | 1200 | 0.13 |
| titan_gauss | TITAN GAUSS | 3 | 200 | 300 | 250 | 0.3 | 75 | 2000 | 0.04 |

*DPS = Average Damage × Fire Rate (shots per second)

### DPS Efficiency Analysis
**Best DPS Value:**
- RAPTOR DT-01: 0.16 DPS/₡ (starter)
- PIRANHA SMG: 0.16 DPS/₡ (same efficiency!)

**Worst DPS Value:**
- TITAN GAUSS: 0.04 DPS/₡ - Paying for burst, not sustained
- THUNDER CANNON: 0.05 DPS/₡ - Similar burst tax

**Tier Scaling:**
- Tier 0-1 maintain ~0.16 efficiency
- Tier 2 drops to 0.05-0.13
- Tier 3 drops further to 0.04

### Balance Assessment
⚠️ **Major Issue:** TITAN GAUSS has terrible DPS value
  - 2000₡ for 75 DPS
  - PHOENIX LASER: 1200₡ for 150 DPS (2x better!)
  - 💡 **Recommendation:** Boost TITAN GAUSS to 400-500 damage or increase fire rate to 0.5

⚠️ **Issue:** THUNDER CANNON underperforms
  - 950₡ for 50 DPS
  - PHOENIX LASER out-DPSes it by 3x for only 250₡ more
  - 💡 **Recommendation:** Reduce cost to 700₡ or increase damage to 100-150

✅ **Well Balanced:** RAPTOR and PIRANHA have identical efficiency - good risk/reward (damage vs speed)

---

## BUILD COMBINATIONS

### Starter Build (Striker Alpha)
- Chassis: AKAUMIN DL2-100 (80 HP)
- Armor: SANTRIN AURO (40 HP, 15% DR)
- Weapon: RAPTOR DT-01 (40 DPS)
- **Total HP:** 120 (141 EHP)
- **Total DPS:** 40
- **Cost:** 750₡

### Tank Build (Defender Beta)
- Chassis: TORQ MK-1 (120 HP)
- Armor: STEEL GUARD (65 HP, 22% DR)
- Weapon: THUNDER CANNON (50 DPS)
- **Total HP:** 185 (237 EHP)
- **Total DPS:** 50
- **Cost:** 1910₡

### Glass Cannon Build
- Chassis: SPEEDSTER V2 (60 HP)
- Armor: NANO-FIBER (25 HP, 10% DR)
- Weapon: PHOENIX LASER (150 DPS)
- **Total HP:** 85 (94 EHP)
- **Total DPS:** 150
- **Cost:** 2130₡

**Analysis:** Glass cannon costs 2.8x starter build but has 3.75x DPS - reasonable progression

---

## ECONOMY BALANCE

### Credit Flow Analysis
**Starter Kit:** 500₡
**First Arena Reward:** ~200₡ (estimated)
**Time to first upgrade:** 2-3 battles

### Part Cost Distribution
| Tier | Avg Chassis | Avg Armor | Avg Weapon | Total Build |
|------|-------------|-----------|------------|-------------|
| 0 | 300₡ | 200₡ | 250₡ | 750₡ |
| 1 | 515₡ | 415₡ | 500₡ | 1430₡ |
| 2 | 900₡ | 620₡ | 1075₡ | 2595₡ |
| 3 | 1500₡ | 1100₡ | 2000₡ | 4600₡ |

**Progression Curve:**
- Tier 0→1: 1.9x cost increase
- Tier 1→2: 1.8x cost increase
- Tier 2→3: 1.8x cost increase

✅ **Well Balanced:** Smooth exponential curve

---

## RECOMMENDATIONS

### High Priority (Fix Before Release)
1. **NANO-FIBER MESH:** Reduce cost from 450₡ to 300₡ or buff HP to 35
2. **TITAN GAUSS:** Increase fire rate to 0.5 (100 DPS) or reduce cost to 1400₡
3. **THUNDER CANNON:** Increase damage to 100-150 or reduce cost to 700₡

### Medium Priority (Polish)
4. **JUGGERNAUT 9000:** Add +50 HP or 5% damage reduction
5. **Arena Rewards:** Verify 200₡ reward is appropriate for 750₡ starter builds

### Low Priority (Nice to Have)
6. Consider adding weapon mod system to improve late-game efficiency
7. Add armor penetration mechanic to make high-tier weapons more valuable

---

## OVERALL BALANCE SCORE: 7.5/10

**Strengths:**
- ✅ Good cost curve across tiers
- ✅ Clear role differentiation
- ✅ Starter kit well-designed

**Issues:**
- ⚠️ 3 components significantly underpowered
- ⚠️ Late-game DPS efficiency drops too sharply

---

*Analysis Version: 1.0*
*Generated: 2024-02-23*
*Based on components.json v1.0.0*
