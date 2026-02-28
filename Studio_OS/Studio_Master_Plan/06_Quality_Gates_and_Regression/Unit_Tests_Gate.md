---
title: Unit Tests Gate
type: gate
layer: enforcement
status: active
tags:
  - unit-tests
  - testing
  - gate
  - ci-cd
  - nunit
  - test-runner
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Build_Gate]"
used_by:
  - "[Regression_Harness_Spec]]"
  - "[[Release_Certification_Checklist]"
---

# Unit Tests Gate

## Purpose

The Unit Tests Gate validates core game logic, systems, and utilities through automated tests. It ensures that fundamental behaviors remain correct as the codebase evolves.

## Tool/Script

**Primary**: `scripts/gates/unit_test_gate.py`
**Unity Test Runner**: `Unity Test Framework` (NUnit)
**Alternative**: `dotnet test` for pure C# assemblies

## Local Run

```bash
# Run all unit tests
python scripts/gates/unit_test_gate.py --category all

# Run specific category
python scripts/gates/unit_test_gate.py --category gameplay

# Run with coverage
python scripts/gates/unit_test_gate.py --coverage --threshold 70

# Quick mode (fast tests only)
python scripts/gates/unit_test_gate.py --quick

# Via Unity directly
/Unity -runTests -testPlatform EditMode -testResults results.xml
```

## CI Run

```yaml
# .github/workflows/unit-test-gate.yml
name: Unit Tests Gate
on: [push, pull_request]
jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Unit Tests
        run: python scripts/gates/unit_test_gate.py --category all --coverage
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| Test Pass Rate | 100% | (passed / total) * 100 |
| Critical Tests | 100% | All tests marked [Critical] pass |
| Code Coverage | >= 70% | Line coverage percentage |
| Critical Coverage | >= 90% | Coverage of critical systems |
| Test Execution Time | < 10 min | Total test suite duration |
| Flaky Test Rate | < 1% | Tests with inconsistent results |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| Failed Tests | >= 1 | HARD FAIL - logic regression |
| Critical Test Fail | >= 1 | HARD FAIL - immediate block |
| Coverage Drop | > 5% from baseline | SOFT FAIL - requires review |
| Test Timeout | > 10 min | SOFT FAIL - performance issue |
| New Flaky Test | >= 1 | SOFT FAIL - must stabilize |

## Test Categories

| Category | Description | Max Duration | Required |
|----------|-------------|--------------|----------|
| Core | Math, utilities, data structures | 30s | Yes |
| Gameplay | Game rules, state machines | 2min | Yes |
| AI | Behavior trees, pathfinding | 3min | Yes |
| Economy | Resource systems, progression | 1min | Yes |
| Network | Multiplayer sync, serialization | 2min | Yes |
| Integration | Cross-system tests | 5min | Yes |
| Slow | Stress tests, benchmarks | 10min | Optional |

## Critical Test Annotation

```csharp
// Mark tests that must never fail
[Test]
[Category("Critical")]
[Description("Core game loop must initialize correctly")]
public void GameLoop_Initialize_Succeeds()
{
    // This test failure blocks all releases
}
```

## Failure Modes

### Test Failure

**Symptoms**: One or more tests report FAILED
**Immediate Action**: Gate fails, PR blocked

### Coverage Regression

**Symptoms**: Coverage drops below threshold
**Immediate Action**: SOFT FAIL - requires Tech Lead approval

### Flaky Test

**Symptoms**: Test passes/fails inconsistently
**Immediate Action**: Test quarantined, ticket created

## Remediation Steps

### Fix Failing Tests

1. Identify failing test from CI logs
2. Run locally: `python scripts/gates/unit_test_gate.py --filter TestName`
3. Debug and fix the underlying issue
4. Verify fix: Run test 10 times locally
5. Push fix and re-run gate

### Add Missing Coverage

1. Check coverage report: `reports/coverage/index.html`
2. Identify uncovered code paths
3. Write tests for uncovered logic
4. Verify coverage meets threshold
5. Push new tests

### Stabilize Flaky Test

1. Identify flaky test from CI history
2. Add diagnostic logging to test
3. Run test 100 times locally: `scripts/tools/stress_test.sh TestName`
4. Fix race condition or timing issue
5. Re-enable test after 50 consecutive passes

### Quarantine Flaky Test (Emergency)

```csharp
// Temporarily disable flaky test
[Test]
[Category("Quarantined")]
[Ignore("Flaky - see ticket TEST-1234")]
public void FlakyTest()
{
    // Will not run in CI
}
```

## Test Organization

```
Assets/Tests/
├── EditMode/
│   ├── Core/
│   │   ├── MathTests.cs
│   │   ├── DataStructureTests.cs
│   │   └── SerializationTests.cs
│   ├── Gameplay/
│   │   ├── GameStateTests.cs
│   │   ├── CombatTests.cs
│   │   └── EconomyTests.cs
│   └── AI/
│       ├── PathfindingTests.cs
│       └── BehaviorTreeTests.cs
├── PlayMode/
│   └── IntegrationTests.cs
└── TestUtils/
    └── TestHelpers.cs
```

## Coverage Requirements by System

| System | Required Coverage | Notes |
|--------|-------------------|-------|
| Core/Math | 95% | Foundation utilities |
| Game State | 90% | Critical for determinism |
| Economy | 85% | Progression systems |
| AI/Pathfinding | 80% | Complex algorithms |
| UI/View | 60% | Visual elements less critical |

## Integration with Other Gates

- **Requires**: [[Build_Gate]] must pass first
- **Blocks**: [[Determinism_Replay_Gate]], [[Headless_Match_Batch_Gate]]
- **Feeds metrics to**: [[Regression_Harness_Spec]]
- **Coverage reports**: [[Perf_Budget_Enforcement]] (code complexity correlation)

## Performance Budgets

| Test Type | Max Duration | Action on Exceed |
|-----------|--------------|------------------|
| Unit Test | 100ms | Investigate, optimize |
| Integration Test | 5s | Profile, consider splitting |
| Stress Test | 60s | Acceptable for stress tests |

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| Unity Test Runner memory leak | Restart Unity between batches | UNITY-890 |
| PlayMode tests hang in CI | Add 30s timeout per test | CI-234 |
| Coverage inaccurate for generics | Use alternative coverage tool | TEST-567 |
