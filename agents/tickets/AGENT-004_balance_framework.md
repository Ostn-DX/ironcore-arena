## ID
AGENT-004

## Title
Build Automated Balance Validation Framework

## Goal
Create data-driven balance analysis tool that runs thousands of simulated battles, identifies imbalances, and generates tuning recommendations. Remove guesswork from balance.

## Problem Statement
Current balance is "unverified" — formulas created but not tested. Questions unanswered:
- Is Tier 3 too hard for new players?
- Do weapons have meaningful tradeoffs?
- Is credit progression too fast/slow?
- Which chassis is overpowered?
- What's the optimal loadout?

Manual testing is slow and biased. Need automated analysis.

## Allowed Files
- project/autoload/SimulationManager.gd (read)
- project/autoload/GameState.gd (read)
- project/data/components.json (read)
- project/data/campaign.json (read)
- project/data/balance/ (new balance data goes here)

## New Files
- project/tools/balance_validator.gd (headless analysis tool)
- project/src/analysis/match_analyzer.gd
- project/src/analysis/balance_report.gd
- project/data/balance/baseline_metrics.json
- docs/BALANCE_ANALYSIS.md
- reports/balance_report_*.json (generated)

## Forbidden Files
- Any source code modifications (analysis only)
- Any JSON data modifications (recommendations only)

## Architecture

### 1. Match Analyzer (match_analyzer.gd)
```gdscript
class_name MatchAnalyzer
## Analyzes a single battle and extracts metrics

func analyze(battle_log: BattleLog) -> MatchMetrics:
    ## Returns:
    ## - Duration
    ## - Damage dealt per bot
    ## - Damage taken per bot
    ## - Shots fired/hit ratio
    ## - Distance traveled
    ## - Time in cover
    ## - Weapon effectiveness
    ## - Chassis survivability

func compare_loadouts(loadout_a: Dictionary, loadout_b: Dictionary) -> Comparison:
    ## Run 100 battles between two specific loadouts
    ## Returns win rate, avg duration, confidence interval
```

### 2. Balance Report Generator (balance_report.gd)
```gdscript
class_name BalanceReport
## Aggregates metrics across many battles

func generate_component_report() -> Dictionary:
    ## For each chassis: win rate, avg survival time
    ## For each weapon: DPS, accuracy, effective range
    ## For each armor: damage mitigation, speed impact
    
func generate_arena_report() -> Dictionary:
    ## For each arena: completion rate, avg attempts, win rate
    ## Identify "wall" arenas where players get stuck
    
func generate_progression_report() -> Dictionary:
    ## Simulate full campaign progression
    ## Track credit accumulation vs costs
    ## Identify grind points or credit overflow
```

### 3. Headless Balance Validator (tools/balance_validator.gd)
```gdscript
## Usage: godot --headless --script res://tools/balance_validator.gd -- --mode=full

## Modes:
## --mode=components: Test all chassis/weapon/armor combinations (1v1)
## --mode=arenas: Test each campaign arena with various player loadouts
## --mode=progression: Simulate full playthrough, track economy
## --mode=full: Run all analyses

## Output: reports/balance_report_YYYYMMDD_HHMMSS.json
```

### 4. Report JSON Schema
```json
{
  "metadata": {
    "timestamp": "2024-02-27T10:30:00Z",
    "version": "0.1.0",
    "simulations_run": 10000
  },
  "component_balance": {
    "chassis": {
      "scout": {"win_rate": 0.45, "survival_time_avg": 45.2, "tier": "balanced"},
      "tank": {"win_rate": 0.58, "survival_time_avg": 78.5, "tier": "strong"}
    },
    "weapons": {
      "machine_gun": {"dps": 45, "accuracy": 0.65, "effective_range": 200},
      "sniper": {"dps": 120, "accuracy": 0.85, "effective_range": 600}
    }
  },
  "arena_difficulty": {
    "roxtan_park": {"first_attempt_clear": 0.85, "avg_attempts": 1.2},
    "chrometek_rally": {"first_attempt_clear": 0.32, "avg_attempts": 3.8}
  },
  "economy": {
    "credits_per_hour": 850,
    "tier_2_unlock_time_hours": 2.5,
    "tier_3_unlock_time_hours": 6.0
  },
  "recommendations": [
    {
      "severity": "high",
      "category": "component",
      "subject": "tank_chassis",
      "issue": "58% win rate in 1v1, 13% above average",
      "recommendation": "Reduce HP from 180 to 160 or speed from 3.0 to 2.7"
    },
    {
      "severity": "medium", 
      "category": "arena",
      "subject": "chrometek_rally",
      "issue": "First attempt clear rate 32%, below 50% target",
      "recommendation": "Reduce sniper damage or add more cover"
    }
  ]
}
```

## Analysis Dimensions

### Component Balance
**Methodology:**
1. Generate all 1v1 matchups (chassis A + weapon X vs chassis B + weapon Y)
2. Run 100 battles per matchup with fixed seeds
3. Calculate win rates, confidence intervals
4. Flag outliers (> 60% win rate = potentially OP, < 40% = UP)

**Metrics to Track:**
- Win rate per component (isolated)
- Win rate per component combination
- DPS efficiency (damage / cost)
- Survival time per chassis
- Effective range accuracy dropoff

### Arena Difficulty
**Methodology:**
1. Simulate player with "tier-appropriate" loadout attempting arena
2. If fail, simulate upgrade, retry (mimics player progression)
3. Track attempts until success
4. Run 1000 "players" per arena

**Metrics to Track:**
- First attempt clear rate (target: > 50%)
- Average attempts to clear
- Most common failure point (which enemy, what HP)
- Upgrade purchases triggered by failure

### Economy Progression
**Methodology:**
1. Simulate full campaign playthrough
2. Track credits earned, spent, saved
3. Track component purchases over time
4. Calculate "time to unlock" per tier

**Metrics to Track:**
- Credits per hour of gameplay
- Components purchased per tier
- Savings rate (credits unspent)
- Grinding required (repeat battles for credits)

### Weapon Effectiveness Curves
**Methodology:**
1. For each weapon, test at various ranges (50, 100, 200, 400, 600 units)
2. Test against each chassis type
3. Calculate damage per second, hits per second

**Output:**
- Effectiveness heatmap (weapon vs range)
- Optimal range per weapon
- Counter-pick relationships

## Baseline Metrics (balance/baseline_metrics.json)
```json
{
  "targets": {
    "component_win_rate_range": [0.45, 0.55],
    "first_attempt_clear_rate_min": 0.50,
    "avg_attempts_max": 3.0,
    "credits_per_hour_target": 600,
    "tier_unlock_time_hours": [0.5, 2.0, 5.0, 10.0]
  },
  "component_baselines": {
    "scout_survival_time": 40.0,
    "fighter_survival_time": 60.0,
    "tank_survival_time": 80.0
  }
}
```

## Deliverable Structure
```
agent_runs/AGENT-004/
  NEW_FILES/
    - src/analysis/match_analyzer.gd
    - src/analysis/balance_report.gd
    - tools/balance_validator.gd
    - data/balance/baseline_metrics.json
    - docs/BALANCE_ANALYSIS.md
  MODIFICATIONS/
    - (none - analysis tool only)
  TESTS/
    - test_match_analyzer.gd
    - test_balance_report.gd
  INTEGRATION_GUIDE.md
  CHANGELOG.md
```

## Sample Output Report
Include a sample balance report with the deliverable, showing:
- What the tool found (hypothetical imbalances)
- How recommendations are formatted
- Visualizations (if any)

## Acceptance Criteria
- [ ] AC1: Tool runs 1000+ battles without crashes
- [ ] AC2: Component analysis covers all chassis/weapon combos
- [ ] AC3: Arena analysis simulates "player progression"
- [ ] AC4: Report identifies at least 3 potential imbalances (even if false positives)
- [ ] AC5: Recommendations include specific tuning values
- [ ] AC6: Tool completes full analysis in < 5 minutes
- [ ] AC7: JSON output is valid and documented schema
- [ ] AC8: Baseline metrics file defines clear targets

## Performance Requirements
- 1000 battles in < 60 seconds (headless)
- Report generation < 1 second
- Memory usage < 500MB during analysis

## Notes
- This is analysis only - no changes to game balance
- Tool helps identify problems, human decides fixes
- Run before each release to catch regressions
- Compare reports over time to track balance trends
