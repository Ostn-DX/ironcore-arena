---
title: Release Certification Checklist
type: template
layer: execution
status: active
tags:
  - release
  - certification
  - checklist
  - steam
  - launch
  - validation
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Build_Gate]]"
  - "[[Unit_Tests_Gate]]"
  - "[[Determinism_Replay_Gate]]"
  - "[[Performance_Gate]]"
  - "[[Content_Validation_Gate]]"
  - "[[Packaging_Gate]"
used_by: []
---

# Release Certification Checklist

## Purpose

This checklist ensures all quality gates have passed and all release requirements are met before submitting to Steam or other distribution platforms. No release proceeds without complete certification.

## Pre-Certification Requirements

### Version and Documentation

- [ ] Version number follows [[Versioning_Changelog_Rules]]
- [ ] CHANGELOG.md updated with all changes
- [ ] Release notes drafted for Steam
- [ ] Known issues documented
- [ ] Support contact information current

### Legal and Compliance

- [ ] EULA included in build
- [ ] Privacy policy updated
- [ ] Third-party licenses documented
- [ ] Age rating information current
- [ ] Content descriptors accurate

## Quality Gates Certification

### Layer 1: Build

- [ ] [[Build_Gate]] PASSED
  - [ ] All platforms compile successfully
  - [ ] Zero compilation errors
  - [ ] Warnings below threshold (< 50)
  - [ ] Build artifacts generated
  - [ ] Build size within budget

### Layer 2: Static Analysis

- [ ] [[Lint_Static_Analysis_Gate]] PASSED
  - [ ] Zero critical issues
  - [ ] Zero security vulnerabilities
  - [ ] Style violations below threshold
  - [ ] Complexity within limits

- [ ] [[Security_Secret_Scanning_Gate]] PASSED
  - [ ] Zero secrets detected
  - [ ] No high-entropy suspicious strings
  - [ ] Pre-commit hooks active

### Layer 3: Unit Tests

- [ ] [[Unit_Tests_Gate]] PASSED
  - [ ] 100% test pass rate
  - [ ] All critical tests passed
  - [ ] Code coverage >= 70%
  - [ ] No new flaky tests

### Layer 4: Integration

- [ ] [[Determinism_Replay_Gate]] PASSED (if applicable)
  - [ ] 100% state hash match
  - [ ] All replays validate
  - [ ] RNG sequences deterministic

- [ ] [[Headless_Match_Batch_Gate]] PASSED (if applicable)
  - [ ] Zero crashes
  - [ ] Soft lock rate < 0.1%
  - [ ] Balance within 45-55%
  - [ ] Performance within budget

### Layer 5: Validation

- [ ] [[Content_Validation_Gate]] PASSED
  - [ ] 100% JSON validity
  - [ ] 100% schema compliance
  - [ ] Zero missing references
  - [ ] All prefabs load correctly

- [ ] [[UI_Smoke_Gate]] PASSED
  - [ ] 100% critical paths complete
  - [ ] All UI elements detected
  - [ ] Screen transitions < 3s
  - [ ] No UI exceptions

### Layer 6: Performance

- [ ] [[Performance_Gate]] PASSED
  - [ ] Average FPS >= 60 (or platform target)
  - [ ] Minimum FPS >= 30
  - [ ] Frame time 99th < 33ms
  - [ ] Memory within budget
  - [ ] No memory leaks detected
  - [ ] Load times within budget
  - [ ] No regressions > 10%

### Layer 7: Packaging

- [ ] [[Packaging_Gate]] PASSED
  - [ ] Executable present and valid
  - [ ] All required DLLs included
  - [ ] Steam API properly integrated
  - [ ] Manifest complete
  - [ ] Size within platform limits
  - [ ] Icons all sizes present
  - [ ] Version info correct

## Platform-Specific Certification

### Steam Requirements

- [ ] Steam App ID configured
- [ ] steam_appid.txt present
- [ ] steam_api64.dll valid
- [ ] Steamworks SDK version current
- [ ] Achievements configured in partner site
- [ ] Cloud saves configured (if applicable)
- [ ] Steam Input configured (if applicable)
- [ ] Store page complete
- [ ] Screenshots uploaded (min 5)
- [ ] Trailer uploaded
- [ ] System requirements accurate
- [ ] Pricing configured
- [ ] Release date set

### Build Depot Configuration

- [ ] Windows depot configured
- [ ] Linux depot configured (if supported)
- [ ] macOS depot configured (if supported)
- [ ] Depot filters correct
- [ ] Launch options configured
- [ ] Install scripts tested

## Manual Testing

### Critical Path Verification

- [ ] Game launches from Steam
- [ ] Main menu accessible
- [ ] New game starts successfully
- [ ] Save/load works
- [ ] Settings apply correctly
- [ ] Quit game works cleanly

### Platform Testing

- [ ] Tested on minimum spec hardware
- [ ] Tested on recommended hardware
- [ ] Tested on target platforms
- [ ] Controller support verified (if applicable)
- [ ] Windowed/fullscreen modes work

### Online Features (if applicable)

- [ ] Multiplayer connections work
- [ ] Leaderboards functional
- [ ] Achievements unlock
- [ ] Cloud saves sync

## Risk Assessment

- [ ] [[Known_Risk_Acceptance_Checklist]] reviewed
- [ ] All known risks documented
- [ ] Risk acceptance signed off
- [ ] Mitigation plans in place

## Rollback Preparedness

- [ ] [[Rollback_Plan_Checklist]] prepared
- [ ] Previous version can be restored
- [ ] Rollback tested
- [ ] Communication plan ready

## Final Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Tech Lead | | | |
| Producer | | | |
| QA Lead | | | |
| Design Lead | | | |

## Post-Release Monitoring

- [ ] Analytics dashboard ready
- [ ] Error tracking active
- [ ] Support channels staffed
- [ ] Community monitoring plan

## Certification Approval

```
RELEASE CERTIFICATION APPROVAL
==============================

Version: [VERSION]
Date: [DATE]

All quality gates: PASSED
Manual testing: COMPLETE
Platform requirements: MET
Risk assessment: REVIEWED
Rollback plan: READY

APPROVED FOR RELEASE

Signed: ___________________
       [NAME, TITLE]
       [DATE]
```

## Emergency Override

In exceptional circumstances, a release may proceed with gate failures:

1. Document each override in [[Known_Risk_Acceptance_Checklist]]
2. Obtain approval from:
   - Tech Lead
   - Producer
   - Studio Director
3. Set remediation deadline (max 48 hours)
4. Activate enhanced monitoring
5. Prepare hotfix branch

**Note**: Security gate failures CANNOT be overridden.
