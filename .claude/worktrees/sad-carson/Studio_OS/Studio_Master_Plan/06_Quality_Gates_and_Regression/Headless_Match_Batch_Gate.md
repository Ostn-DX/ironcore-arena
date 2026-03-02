---
title: Headless Match Batch Gate
type: gate
layer: enforcement
status: active
tags:
  - headless
  - batch
  - simulation
  - gate
  - automated-testing
  - ai-vs-ai
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Determinism_Replay_Gate]"
used_by:
  - "[Regression_Harness_Spec]]"
  - "[[Release_Certification_Checklist]]"
  - "[[Perf_Budget_Enforcement]"
---

# Headless Match Batch Gate

## Purpose

The Headless Match Batch Gate runs thousands of AI-vs-AI matches in headless mode to validate game balance, catch edge cases, and ensure system stability under extended play. This gate is essential for simulation-heavy games.

## Tool/Script

**Primary**: `scripts/gates/batch_match_gate.py`
**Headless Runner**: `Assets/Scripts/Core/Headless/HeadlessMatchRunner.cs`
**Batch Controller**: `scripts/tools/batch_controller.py`

## Local Run

```bash
# Quick batch (100 matches)
python scripts/gates/batch_match_gate.py --count 100 --duration 300

# Standard batch (1000 matches)
python scripts/gates/batch_match_gate.py --count 1000 --duration 600

# Full regression batch (10000 matches)
python scripts/gates/batch_match_gate.py --count 10000 --duration 1200

# Specific scenario batch
python scripts/gates/batch_match_gate.py --scenario combat_focused --count 500

# Parallel execution
python scripts/gates/batch_match_gate.py --count 1000 --workers 8
```

## CI Run

```yaml
# .github/workflows/batch-match-gate.yml
name: Headless Match Batch Gate
on:
  schedule:
    - cron: '0 2 * * *'  # Nightly at 2 AM
  workflow_dispatch:
jobs:
  batch-matches:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Batch Match Gate
        run: python scripts/gates/batch_match_gate.py --count 5000 --workers 4
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: batch-results
          path: reports/batch/
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| Crash Rate | 0% | Matches ending in crash |
| Soft Lock Rate | < 0.1% | Matches exceeding max duration |
| Exception Rate | < 0.01% | Unhandled exceptions per match |
| Determinism | 100% | Replay hash matches |
| Win Rate Balance | 45-55% | AI win rate distribution |
| Average Duration | Within 10% of expected | Match completion time |
| Memory Leak | < 1MB per match | Memory growth rate |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| Crash | >= 1 | HARD FAIL - stability issue |
| Soft Lock | >= 1% | HARD FAIL - game logic issue |
| Exception | >= 0.1% | SOFT FAIL - error handling issue |
| Win Rate Imbalance | < 40% or > 60% | SOFT FAIL - balance issue |
| Memory Leak | >= 5MB per match | SOFT FAIL - memory issue |

## Batch Configuration

```yaml
# config/batch_scenarios.yml
scenarios:
  quick_validation:
    count: 100
    duration: 300
    ai_config: balanced
    map_pool: small_maps
    
  standard_regression:
    count: 1000
    duration: 600
    ai_config: varied
    map_pool: all_maps
    
  stress_test:
    count: 10000
    duration: 1200
    ai_config: aggressive
    map_pool: large_maps
    
  balance_check:
    count: 2000
    duration: 600
    ai_config: mirror_match
    map_pool: competitive_maps
```

## Match Outcome Categories

| Outcome | Description | Target Rate |
|---------|-------------|-------------|
| Normal Victory | Standard win condition | 95% |
| Timeout | Max duration reached | < 4% |
| Draw | Mutual destruction | < 1% |
| Crash | Exception or error | 0% |
| Soft Lock | No progress detected | < 0.1% |

## Failure Modes

### Match Crash

**Symptoms**: Match terminates unexpectedly with exception
**Immediate Action**: HARD FAIL - investigate stack trace

### Soft Lock

**Symptoms**: Match runs indefinitely without progress
**Detection**: No state changes for 60+ seconds
**Immediate Action**: HARD FAIL - investigate game logic

### Balance Issue

**Symptoms**: One AI wins disproportionately
**Detection**: Win rate outside 45-55% range
**Immediate Action**: SOFT FAIL - design review required

## Remediation Steps

### Fix Match Crash

1. Check batch report for crash logs
2. Identify failing scenario and seed
3. Reproduce locally: `scripts/tools/replay_match.py --seed <seed>`
4. Debug and fix the issue
5. Add regression test for the crash
6. Re-run batch gate

### Fix Soft Lock

1. Identify soft-locked match from report
2. Analyze replay for stuck state
3. Add progress detection to game logic
4. Implement timeout or forced resolution
5. Re-run batch to verify fix

### Address Balance Issue

1. Review win rate distribution by:
   - AI type
   - Map
   - Starting conditions
2. Identify over/under-performing elements
3. Propose balance changes
4. Re-run batch to validate
5. Document changes in balance changelog

## Batch Report Format

```json
{
  "batch_id": "batch_20240115_020000",
  "config": {
    "count": 1000,
    "duration": 600,
    "scenario": "standard"
  },
  "summary": {
    "completed": 998,
    "crashed": 0,
    "soft_locked": 2,
    "timeouts": 45,
    "draws": 12
  },
  "win_rates": {
    "ai_aggressive": 0.52,
    "ai_defensive": 0.48
  },
  "performance": {
    "avg_duration_seconds": 485,
    "avg_memory_mb": 128,
    "memory_leak_mb_per_match": 0.3
  },
  "crashes": [],
  "soft_locks": [
    {"match_id": 456, "seed": 789012, "duration": 1200}
  ]
}
```

## Integration with Other Gates

- **Requires**: [[Determinism_Replay_Gate]] must pass
- **Provides data to**: [[Regression_Harness_Spec]]
- **Performance data**: [[Perf_Budget_Enforcement]]
- **Balance data**: Design team dashboards

## Resource Requirements

| Batch Size | Workers | Duration | CPU | Memory |
|------------|---------|----------|-----|--------|
| 100 | 1 | 5 min | 1 core | 2GB |
| 1000 | 4 | 15 min | 4 cores | 8GB |
| 10000 | 8 | 2 hours | 8 cores | 16GB |

## Parallel Execution

```python
# scripts/gates/batch_match_gate.py
class BatchMatchGate:
    def run_parallel(self, count: int, workers: int):
        """Execute matches in parallel worker processes."""
        with Pool(workers) as pool:
            results = pool.map(self.run_match, range(count))
        return self.aggregate_results(results)
```

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| Unity headless mode memory leak | Restart workers every 100 matches | BATCH-123 |
| Long batch times in CI | Run nightly, not per-PR | CI-456 |
| AI non-determinism | Verify AI uses seeded RNG | BATCH-789 |
