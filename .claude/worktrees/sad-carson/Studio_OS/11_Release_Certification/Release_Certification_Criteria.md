---
title: Release_Certification_Criteria
type: rule
layer: enforcement
status: active
tags:
  - release
  - certification
  - quality
  - shipping
depends_on:
  - "[Dev_Gate_Validation_System]]"
  - "[[Simulation_Test_Suite]"
used_by:
  - "[Release_Manager]]"
  - "[[QA_Team]"
---

# Release Certification Criteria

## Purpose
Define objective criteria that must be met before any release (alpha, beta, or full). Prevents shipping broken builds.

## Core Rules

### Pre-Release Checklist

#### 1. Automated Validation
- [ ] All tests pass (100%)
- [ ] Gate passes without warnings
- [ ] Determinism verified (replay matches)
- [ ] Performance: 60 FPS minimum on target hardware
- [ ] No crash reports in last 7 days

#### 2. Content Completeness
- [ ] All arenas playable
- [ ] All enemy variants implemented
- [ ] All UI screens functional
- [ ] Save/load works across sessions
- [ ] No placeholder text visible

#### 3. Quality Metrics
| Metric | Alpha | Beta | Release |
|--------|-------|------|---------|
| Crash-free sessions | >95% | >99% | >99.9% |
| Avg session length | >5 min | >15 min | >30 min |
| Completion rate (Boot Camp) | >90% | >95% | >98% |
| Player retention (Day 1) | - | >40% | >50% |

### Version Numbering

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]

Examples:
0.1.0-alpha      # Internal alpha
0.1.0-beta.1     # First beta
0.1.0-beta.2     # Second beta  
0.1.0            # Release
0.1.1            # Hotfix
0.2.0            # Feature update
```

### Certification Process

#### Alpha Certification
1. Feature complete (all systems implemented)
2. All tests pass
3. No game-breaking bugs
4. Playable from start to finish

#### Beta Certification
1. Alpha criteria + polish
2. Balance validated
3. Performance optimized
4. No major bugs

#### Release Certification
1. Beta criteria + stability
2. All known bugs triaged (fix or defer)
3. Documentation complete
4. Marketing materials ready

## Failure Modes

### Rushed Release
**Symptom:** Shipping with known critical bugs
**Prevention:** Strict criteria, no exceptions

### Feature Creep
**Symptom:** Adding features after code freeze
**Prevention:** Feature freeze 2 weeks before release

### Platform Issues
**Symptom:** Works on dev machine, fails on player hardware
**Prevention:** CI tests on multiple platforms

## Enforcement

### Release Manager Authority
- Can block release for any criteria violation
- Must sign off on all releases
- Maintains release checklist

### Automated Gates
- CI prevents merge without tests passing
- Build script validates version format
- Automated crash report monitoring

## Related
[[Dev_Gate_Validation_System]]
[[Version_Numbering_Scheme]]
[[CI_CD_Pipeline]]
[[Crash_Reporting_System]]
