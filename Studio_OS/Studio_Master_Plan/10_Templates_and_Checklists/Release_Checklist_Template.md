---
title: Release Checklist Template
type: template
layer: execution
status: active
tags:
  - template
  - release
  - checklist
  - steam
  - certification
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Release_Certification_Checklist]"
used_by: []
---

# Release Checklist Template

## Purpose

Use this template when preparing for a new release. Copy this file, customize for your release, and complete all items before submission.

## Release Information

| Field | Value |
|-------|-------|
| Version | [e.g., 1.2.3] |
| Release Date | [YYYY-MM-DD] |
| Release Type | [Major/Minor/Patch/Hotfix] |
| Target Platforms | [Windows/Linux/macOS/etc] |
| Release Owner | [@name] |
| QA Lead | [@name] |

## Pre-Release Checklist

### Version & Documentation

- [ ] Version number follows [[Versioning_Changelog_Rules]]
- [ ] `CHANGELOG.md` updated with all changes
- [ ] Version constant updated in code
- [ ] Git tag created: `git tag v[X.Y.Z]`
- [ ] Tag pushed: `git push origin v[X.Y.Z]`
- [ ] Release notes drafted
- [ ] Known issues documented
- [ ] Support contact info current

### Legal & Compliance

- [ ] EULA included in build
- [ ] Privacy policy updated (if changed)
- [ ] Third-party licenses documented
- [ ] Age rating accurate
- [ ] Content descriptors accurate

## Quality Gates

### Layer 1: Build

- [ ] [[Build_Gate]] PASSED
  - [ ] Windows build successful
  - [ ] Linux build successful (if supported)
  - [ ] macOS build successful (if supported)
  - [ ] Zero compilation errors
  - [ ] Warnings below threshold

### Layer 2: Static Analysis

- [ ] [[Lint_Static_Analysis_Gate]] PASSED
  - [ ] Zero critical issues
  - [ ] Zero security vulnerabilities
  - [ ] Style violations acceptable

- [ ] [[Security_Secret_Scanning_Gate]] PASSED
  - [ ] Zero secrets detected
  - [ ] Pre-commit hooks active

### Layer 3: Unit Tests

- [ ] [[Unit_Tests_Gate]] PASSED
  - [ ] 100% test pass rate
  - [ ] Critical tests passed
  - [ ] Coverage meets threshold

### Layer 4: Integration

- [ ] [[Determinism_Replay_Gate]] PASSED (if applicable)
  - [ ] State hashes match
  - [ ] Replays validate

- [ ] [[Headless_Match_Batch_Gate]] PASSED (if applicable)
  - [ ] Zero crashes
  - [ ] Balance acceptable
  - [ ] Performance within budget

### Layer 5: Validation

- [ ] [[Content_Validation_Gate]] PASSED
  - [ ] All JSON valid
  - [ ] No missing references
  - [ ] Prefabs load correctly

- [ ] [[UI_Smoke_Gate]] PASSED
  - [ ] Critical paths complete
  - [ ] UI elements detected
  - [ ] No UI exceptions

### Layer 6: Performance

- [ ] [[Performance_Gate]] PASSED
  - [ ] FPS meets targets
  - [ ] Memory within budget
  - [ ] Load times acceptable
  - [ ] No regressions > 10%

### Layer 7: Packaging

- [ ] [[Packaging_Gate]] PASSED
  - [ ] Executable present
  - [ ] All DLLs included
  - [ ] Steam API valid
  - [ ] Size within limits

## Platform-Specific

### Steam

- [ ] Steam App ID configured
- [ ] `steam_appid.txt` present
- [ ] Achievements configured in partner site
- [ ] Cloud saves configured (if applicable)
- [ ] Store page complete
- [ ] Screenshots uploaded (min 5)
- [ ] System requirements accurate
- [ ] Pricing configured

### Console (if applicable)

- [ ] Platform certification passed
- [ ] Compliance requirements met
- [ ] Age rating obtained
- [ ] Master build submitted

## Manual Testing

### Critical Paths

- [ ] Game launches from platform
- [ ] Main menu accessible
- [ ] New game starts
- [ ] Save/load works
- [ ] Settings apply
- [ ] Quit works cleanly

### Feature Testing

- [ ] Core gameplay loop works
- [ ] Tutorial completes (if applicable)
- [ ] Multiplayer connects (if applicable)
- [ ] Achievements unlock (if applicable)
- [ ] DLC works (if applicable)

### Platform Testing

- [ ] Tested on minimum spec
- [ ] Tested on recommended spec
- [ ] Controller support verified (if applicable)
- [ ] Windowed mode works
- [ ] Fullscreen mode works

## Risk Management

- [ ] [[Known_Risk_Acceptance_Checklist]] reviewed
- [ ] All known risks documented
- [ ] Risk approvals obtained
- [ ] [[Rollback_Plan_Checklist]] prepared
- [ ] Rollback tested

## Pre-Launch

### Communication

- [ ] Team notified of release date
- [ ] Support team briefed
- [ ] Community announcement scheduled
- [ ] Social media posts ready
- [ ] Press/influencers notified (if major)

### Monitoring

- [ ] Analytics dashboard ready
- [ ] Error tracking active
- [ ] Performance monitoring configured
- [ ] Alerts configured

### Infrastructure

- [ ] Servers scaled (if applicable)
- [ ] CDN warmed (if applicable)
- [ ] Database backups current
- [ ] Failover tested

## Launch Day

### Pre-Launch (T-1 hour)

- [ ] Final build verification
- [ ] All systems green
- [ ] Team on standby
- [ ] Communication channels open

### Launch (T-0)

- [ ] Build published to platform
- [ ] Store page updated
- [ ] Announcement posted
- [ ] Monitoring active

### Post-Launch (T+1 hour)

- [ ] Error rates normal
- [ ] Player reports monitored
- [ ] Social media monitored
- [ ] Support queue manageable

### Post-Launch (T+24 hours)

- [ ] No critical issues
- [ ] Player sentiment positive
- [ ] Performance stable
- [ ] Hotfix not needed

## Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Tech Lead | | | |
| Producer | | | |
| QA Lead | | | |
| Design Lead | | | |

## Post-Release

- [ ] Retrospective scheduled
- [ ] Metrics review scheduled
- [ ] Player feedback collected
- [ ] Lessons learned documented

## Notes

[Any additional notes or special considerations for this release]

---

**Release Status**: [ ] READY [ ] NOT READY

**Blockers**:
- [List any blockers]

**Next Steps**:
- [List next steps]
