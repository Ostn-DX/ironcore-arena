---
title: Architecture Decay Controls
type: system
layer: architecture
status: active
tags:
  - architecture
  - decay
  - technical-debt
  - refactoring
  - maintenance
  - quality
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Lint_Static_Analysis_Gate]]"
  - "[[Risk_Taxonomy]"
used_by:
  - "[Postmortem_Process]"
---

# Architecture Decay Controls

## Purpose

Architecture decay is the gradual degradation of code quality and system design over time. These controls detect, measure, and prevent decay to maintain long-term codebase health.

## Decay Indicators

### Code-Level Indicators

| Indicator | Measurement | Warning Threshold | Critical Threshold |
|-----------|-------------|-------------------|-------------------|
| Cyclomatic Complexity | Average per method | > 10 | > 20 |
| Code Duplication | Percentage | > 5% | > 10% |
| Class Size | Lines of code | > 500 | > 1000 |
| Method Size | Lines of code | > 50 | > 100 |
| Comment Ratio | Comments / LOC | < 10% | < 5% |
| TODO Count | Number of TODOs | > 50 | > 100 |
| FIXME Count | Number of FIXMEs | > 10 | > 25 |

### System-Level Indicators

| Indicator | Measurement | Warning Threshold | Critical Threshold |
|-----------|-------------|-------------------|-------------------|
| Coupling | Dependencies per class | > 10 | > 20 |
| Test Coverage | Line coverage % | < 70% | < 50% |
| Build Time | Minutes | > 10 | > 20 |
| Test Time | Minutes | > 15 | > 30 |
| Package Size | MB | > 1.5GB | > 2GB |

## Decay Detection

### Automated Detection

```python
# scripts/architecture/decay_detector.py
class ArchitectureDecayDetector:
    """Detects architecture decay through code metrics."""
    
    THRESHOLDS = {
        'complexity': {'warning': 10, 'critical': 20},
        'duplication': {'warning': 5, 'critical': 10},
        'class_size': {'warning': 500, 'critical': 1000},
        'method_size': {'warning': 50, 'critical': 100},
        'coverage': {'warning': 70, 'critical': 50},
    }
    
    def analyze(self, codebase_path: Path) -> DecayReport:
        report = DecayReport()
        
        # Run analyzers
        report.complexity = self.analyze_complexity(codebase_path)
        report.duplication = self.analyze_duplication(codebase_path)
        report.coverage = self.analyze_coverage(codebase_path)
        report.dependencies = self.analyze_dependencies(codebase_path)
        
        # Calculate decay score
        report.decay_score = self.calculate_decay_score(report)
        
        return report
```

### Trend Analysis

Track metrics over time to detect decay trends:

```python
def analyze_trends(self, metric_history: List[MetricPoint]):
    """Detect negative trends in code metrics."""
    
    # Linear regression on last 30 days
    slope = self.linear_regression(metric_history).slope
    
    if slope > 0.1:  # Increasing complexity
        return TrendAlert(
            metric="complexity",
            trend="increasing",
            rate=slope,
            recommendation="Schedule refactoring sprint"
        )
```

## Decay Prevention Strategies

### 1. Refactoring Budget

Allocate 20% of development time to refactoring:

| Sprint Type | Refactoring Allocation |
|-------------|----------------------|
| Feature Sprint | 20% of capacity |
| Bug Fix Sprint | 30% of capacity |
| Polish Sprint | 50% of capacity |
| Refactoring Sprint | 100% of capacity |

### 2. Boy Scout Rule

"Leave the codebase cleaner than you found it."

- Fix one TODO when touching a file
- Reduce complexity when adding features
- Add tests when fixing bugs
- Update documentation when changing code

### 3. Technical Debt Tracking

```markdown
# Technical Debt Register

| ID | Description | Created | Priority | Effort | Owner |
|----|-------------|---------|----------|--------|-------|
| TD001 | Refactor PlayerController (complexity 25) | 2024-01 | High | 3 days | @alice |
| TD002 | Consolidate duplicate AI code | 2024-01 | Medium | 2 days | @bob |
| TD003 | Increase test coverage in Economy | 2024-01 | Medium | 5 days | @carol |
```

### 4. Architecture Review Board

Monthly review of:
- Decay metrics trends
- New technical debt
- Refactoring priorities
- Architecture decisions

## Decay Gates

### Complexity Gate

```yaml
# config/complexity_gate.yml
rules:
  - name: method_complexity
    max_cyclomatic: 10
    max_lines: 50
    
  - name: class_complexity
    max_methods: 20
    max_lines: 500
    max_dependencies: 10
```

### Coverage Gate

```yaml
# config/coverage_gate.yml
requirements:
  overall: 70
  by_layer:
    Core: 90
    Gameplay: 80
    UI: 60
  by_criticality:
    Critical: 95
    Standard: 70
    Low: 50
```

## Refactoring Triggers

### Automatic Triggers

| Condition | Action |
|-----------|--------|
| Complexity > 20 | Create refactoring ticket |
| Duplication > 10% | Schedule duplication sprint |
| Coverage < 50% | Block new features |
| Build time > 20 min | Optimize build pipeline |

### Manual Triggers

| Condition | Action |
|-----------|--------|
| Feature takes 2x estimate | Investigate technical debt |
| Bug in "stable" code | Review related code |
| New developer struggles | Improve documentation |
| Performance regression | Profile and optimize |

## Decay Recovery

### Refactoring Sprint Template

```markdown
# Refactoring Sprint: [NAME]

## Goals
- [ ] Reduce average complexity from X to Y
- [ ] Increase coverage from X% to Y%
- [ ] Eliminate Z TODOs

## Scope
- Systems: [List]
- Files: [Count]
- Estimated effort: [Days]

## Success Criteria
- [ ] All complexity < 10
- [ ] No new warnings
- [ ] All tests pass
- [ ] Performance maintained

## Risks
- [ ] May introduce bugs
- [ ] May affect save compatibility
```

## Architecture Health Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│                 ARCHITECTURE HEALTH DASHBOARD                │
├─────────────────────────────────────────────────────────────┤
│  OVERALL HEALTH: ████████████████████░░░░ 78%               │
├─────────────────────────────────────────────────────────────┤
│  COMPLEXITY                                                                    │
│  Average: 8.2  ████████████████████░░░░░ Good               │
│  Max: 18       ████████████████████████░░ Watch             │
│  Trend: ↓ 5%   (improving)                                  │
├─────────────────────────────────────────────────────────────┤
│  COVERAGE                                                                    │
│  Overall: 72%  ██████████████████████░░░░ Good              │
│  Core: 88%     ████████████████████████░░ Good              │
│  Trend: → 0%   (stable)                                     │
├─────────────────────────────────────────────────────────────┤
│  DUPLICATION                                                                 │
│  3.2%          ████████████████░░░░░░░░░░ Good              │
│  Trend: ↓ 1%   (improving)                                  │
├─────────────────────────────────────────────────────────────┤
│  TECHNICAL DEBT                                                              │
│  TODOs: 42     ████████████████████░░░░░░ Watch             │
│  FIXMEs: 8     ██████████████░░░░░░░░░░░░ Good              │
│  Tickets: 12   ██████████████████░░░░░░░░ Watch             │
└─────────────────────────────────────────────────────────────┘
```

## Integration with Other Processes

- **Metrics from**: [[Lint_Static_Analysis_Gate]], [[Unit_Tests_Gate]]
- **Informs**: Sprint planning (refactoring allocation)
- **Feeds**: [[Postmortem_Process]] (decay analysis)
- **Used by**: [[Risk_Taxonomy]] (automation priorities)

## Decay Prevention Checklist

### Daily
- [ ] Fix one TODO when touching code
- [ ] Add tests for bug fixes
- [ ] Update documentation

### Weekly
- [ ] Review decay metrics
- [ ] Address new warnings
- [ ] Update technical debt register

### Monthly
- [ ] Architecture review board meeting
- [ ] Refactoring sprint planning
- [ ] Decay trend analysis

### Quarterly
- [ ] Major refactoring initiatives
- [ ] Architecture evolution planning
- [ ] Technical debt paydown sprints
