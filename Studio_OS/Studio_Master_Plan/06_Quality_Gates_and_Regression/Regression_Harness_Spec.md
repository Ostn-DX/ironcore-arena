---
title: Regression Harness Spec
type: system
layer: enforcement
status: active
tags:
  - regression
  - harness
  - testing
  - automation
  - replay
  - batch
  - headless
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Unit_Tests_Gate]]"
  - "[[Determinism_Replay_Gate]]"
  - "[[Headless_Match_Batch_Gate]"
used_by:
  - "[Release_Certification_Checklist]]"
  - "[[Perf_Budget_Enforcement]"
---

# Regression Harness Spec

## Purpose

The Regression Harness is the unified testing framework that orchestrates all quality gates and provides comprehensive regression detection. It runs the complete test suite, aggregates results, and generates actionable reports.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     REGRESSION HARNESS                           │
├─────────────────────────────────────────────────────────────────┤
│  ORCHESTRATION LAYER                                             │
│  ├── Test Scheduler: Prioritizes and queues tests               │
│  ├── Resource Manager: Allocates workers/machines               │
│  ├── Result Aggregator: Collects and merges results             │
│  └── Report Generator: Creates human-readable reports           │
├─────────────────────────────────────────────────────────────────┤
│  EXECUTION LAYER                                                 │
│  ├── Headless Match Runner: AI-vs-AI simulations                │
│  ├── Replay Validator: Determinism verification                 │
│  ├── Unit Test Runner: Core logic validation                    │
│  ├── Performance Profiler: FPS/memory/load time                 │
│  └── UI Automation: Critical path testing                       │
├─────────────────────────────────────────────────────────────────┤
│  DATA LAYER                                                      │
│  ├── Test Database: Historical results and trends               │
│  ├── Baseline Store: Known-good states and metrics              │
│  ├── Artifact Storage: Logs, screenshots, profiles              │
│  └── Metrics Pipeline: Performance and coverage data            │
└─────────────────────────────────────────────────────────────────┘
```

## Tool/Script

**Primary**: `scripts/regression_harness.py`
**Configuration**: `config/regression_harness.yml`
**Dashboard**: `tools/regression_dashboard/` (web UI)

## Local Run

```bash
# Run full regression suite
python scripts/regression_harness.py --full

# Quick regression (critical tests only)
python scripts/regression_harness.py --quick

# Specific component
python scripts/regression_harness.py --component gameplay

# Compare against baseline
python scripts/regression_harness.py --compare-baseline v1.2.0

# Generate report only
python scripts/regression_harness.py --report-only
```

## CI Run

```yaml
# .github/workflows/regression.yml
name: Full Regression
on:
  schedule:
    - cron: '0 2 * * *'  # Nightly
  workflow_dispatch:
jobs:
  regression:
    runs-on: ubuntu-latest
    timeout-minutes: 180
    steps:
      - uses: actions/checkout@v4
      - name: Full Regression
        run: python scripts/regression_harness.py --full
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: regression-results
          path: reports/regression/
```

## Regression Test Categories

| Category | Test Count | Duration | Frequency |
|----------|------------|----------|-----------|
| Critical | 50 | 5 min | Every PR |
| Standard | 500 | 30 min | Every merge |
| Extended | 5000 | 2 hours | Nightly |
| Full | 50000 | 8 hours | Weekly |

## Headless Match Suite

### Match Configuration

```yaml
# config/headless_matches.yml
match_types:
  - name: quick_battle
    duration: 300
    ai_config: balanced
    map_pool: [small_1, small_2, small_3]
    count: 1000
    
  - name: extended_war
    duration: 1200
    ai_config: varied
    map_pool: [large_1, large_2]
    count: 500
    
  - name: stress_test
    duration: 3600
    ai_config: aggressive
    map_pool: [massive_1]
    count: 100
```

### Match Validation

| Check | Threshold | Action on Fail |
|-------|-----------|----------------|
| Crash Rate | 0% | Block release |
| Soft Lock Rate | < 0.1% | Investigate |
| Determinism | 100% | Block release |
| Balance | 45-55% win rate | Design review |
| Performance | Within budget | Optimize |

## Replay Check System

### Replay Storage

```
Replays/
├── Baselines/          # Known-good replays
│   ├── v1.0.0/
│   ├── v1.1.0/
│   └── v1.2.0/
├── Regression/         # New replays for validation
│   └── pending/
└── Failed/             # Replays that failed validation
    └── YYYY-MM-DD/
```

### Replay Validation Process

1. **Record**: Save replay during match execution
2. **Hash**: Compute state hash at key frames
3. **Store**: Save to regression database
4. **Validate**: Re-run and compare hashes
5. **Report**: Flag any hash mismatches

```python
# scripts/regression/replay_validator.py
class ReplayValidator:
    def validate_replay(self, replay_path: Path) -> ValidationResult:
        replay = Replay.load(replay_path)
        
        # Run simulation
        runner = HeadlessMatchRunner()
        result = runner.run_from_replay(replay)
        
        # Compare hashes
        if result.state_hashes != replay.expected_hashes:
            return ValidationResult.failed(
                "Hash mismatch detected",
                details={
                    "expected": replay.expected_hashes,
                    "actual": result.state_hashes
                }
            )
        
        return ValidationResult.passed()
```

## Regression Detection

### Metric Comparison

| Metric | Comparison | Threshold | Action |
|--------|------------|-----------|--------|
| FPS Average | vs baseline | > -10% | Alert |
| FPS Min | vs baseline | > -20% | Block |
| Memory Peak | vs baseline | > +10% | Alert |
| Load Time | vs baseline | > +20% | Block |
| Test Pass Rate | vs baseline | = 100% | Block |
| Code Coverage | vs baseline | > -5% | Alert |

### Trend Analysis

```python
# scripts/regression/trend_analyzer.py
class TrendAnalyzer:
    def analyze_trends(self, metric: str, days: int = 30):
        """Detect performance degradation trends."""
        data = self.db.query(f"""
            SELECT date, value FROM metrics
            WHERE metric = '{metric}'
            AND date > NOW() - INTERVAL '{days} days'
            ORDER BY date
        """)
        
        # Linear regression
        slope, intercept, r_value = self.linear_regression(data)
        
        if slope < -0.05:  # 5% degradation
            return TrendAlert(
                metric=metric,
                trend="degrading",
                rate=slope,
                recommendation="Investigate performance regression"
            )
```

## Report Format

```json
{
  "run_id": "reg_20240115_020000",
  "duration_seconds": 7200,
  "summary": {
    "total_tests": 5000,
    "passed": 4995,
    "failed": 3,
    "skipped": 2,
    "pass_rate": 0.999
  },
  "gates": {
    "build": {"status": "passed", "duration": 300},
    "unit_tests": {"status": "passed", "duration": 600},
    "determinism": {"status": "passed", "duration": 900},
    "batch_matches": {"status": "passed", "duration": 3600},
    "performance": {"status": "passed", "duration": 1200},
    "ui_smoke": {"status": "passed", "duration": 600}
  },
  "regressions": [
    {
      "type": "performance",
      "metric": "fps_average",
      "baseline": 62.5,
      "current": 58.2,
      "change": -6.9,
      "severity": "warning"
    }
  ],
  "artifacts": {
    "logs": "s3://artifacts/logs/reg_20240115_020000/",
    "screenshots": "s3://artifacts/screenshots/reg_20240115_020000/",
    "profiles": "s3://artifacts/profiles/reg_20240115_020000/"
  }
}
```

## Integration with Other Gates

- **Orchestrates**: All quality gates
- **Consumes**: Results from [[Unit_Tests_Gate]], [[Determinism_Replay_Gate]], [[Headless_Match_Batch_Gate]], [[Performance_Gate]], [[UI_Smoke_Gate]]
- **Produces**: Regression reports for [[Release_Certification_Checklist]]
- **Feeds**: [[Perf_Budget_Enforcement]] (trend data)

## Dashboard

The regression dashboard provides:
- Real-time test status
- Historical trend charts
- Failure investigation tools
- Baseline management
- Test coverage visualization

```bash
# Start dashboard locally
python tools/regression_dashboard/server.py
# Open http://localhost:8080
```

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| Long-running tests timeout | Split into smaller batches | REG-123 |
| Resource contention in CI | Use dedicated runners | REG-456 |
| Flaky tests cause noise | Quarantine and stabilize | REG-789 |
