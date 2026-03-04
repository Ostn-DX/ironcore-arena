---
title: Rollback Plan Checklist
type: template
layer: execution
status: active
tags:
  - rollback
  - emergency
  - checklist
  - recovery
  - deployment
  - hotfix
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Release_Certification_Checklist]"
used_by: []
---

# Rollback Plan Checklist

## Purpose

This checklist ensures we can quickly and safely rollback to a previous version if a critical issue is discovered after release. Every release must have a tested rollback plan.

## Rollback Triggers

Rollback should be initiated when:

- [ ] Critical bug affecting > 50% of users
- [ ] Security vulnerability discovered
- [ ] Data loss or corruption occurring
- [ ] Game unplayable on supported platforms
- [ ] Legal/compliance issue identified
- [ ] Player outcry requiring immediate action

## Pre-Release Rollback Preparation

### Version Tagging

- [ ] Previous release tagged: `git tag v[PREVIOUS]`
- [ ] Tag pushed to remote: `git push origin v[PREVIOUS]`
- [ ] Build artifacts for previous version archived
- [ ] Previous version package stored in artifact repository

### Steam Configuration

- [ ] Steamworks SDK configured for depots
- [ ] Previous build ID noted: ___________
- [ ] Steam command-line rollback tested
- [ ] Steam partner site access verified

### Database/Backend (if applicable)

- [ ] Database schema migrations are backward compatible OR
- [ ] Rollback migration scripts prepared
- [ ] Data backup from before release available
- [ ] Backend version can be rolled back independently

### Communication Templates

- [ ] Rollback announcement drafted
- [ ] Support team briefed on rollback procedure
- [ ] Community manager has messaging ready

## Rollback Procedures

### Steam Rollback

```bash
# Method 1: Set previous build as default
steamcmd +login $STEAM_USERNAME $STEAM_PASSWORD \
  +app_build_switch $APP_ID $PREVIOUS_BUILD_ID \
  +quit

# Method 2: Use Steam partner site
# 1. Log into partner.steampowered.com
# 2. Navigate to App Admin
# 3. Go to SteamPipe → Builds
# 4. Select previous build
# 5. Set as default
# 6. Save changes
```

### Build Rollback (Internal)

```bash
# Rollback to previous version
git checkout v[PREVIOUS]

# Rebuild
python scripts/gates/build_gate.py --platform all

# Repackage
python scripts/gates/packaging_gate.py --full

# Deploy to Steam
python scripts/deploy/steam_deploy.py --build-id [PREVIOUS]
```

## Rollback Checklist

### Immediate Actions (First 15 minutes)

- [ ] Issue confirmed and severity assessed
- [ ] Rollback decision made by Tech Lead + Producer
- [ ] Rollback procedure initiated
- [ ] Team notified (Slack #releases)
- [ ] Support team alerted

### Rollback Execution (15-60 minutes)

- [ ] Steam rollback command executed
- [ ] Rollback verified on test account
- [ ] Rollback confirmed in Steam partner site
- [ ] Build propagation monitored
- [ ] Error rates monitored

### Communication (Within 1 hour)

- [ ] Internal team status update
- [ ] Support team briefed on issue
- [ ] Community announcement posted (if public)
- [ ] Social media updated (if needed)
- [ ] Press/influencers notified (if major)

### Post-Rollback (1-24 hours)

- [ ] Rollback success confirmed via metrics
- [ ] Player reports monitored
- [ ] Issue root cause identified
- [ ] Fix branch created
- [ ] Hotfix prioritized

## Rollback Verification

### Verify Rollback Success

- [ ] Steam shows previous version
- [ ] Game launches successfully
- [ ] Core features functional
- [ ] No new issues introduced
- [ ] Player reports of improvement

### Monitor Metrics

| Metric | Expected | Actual | Status |
|--------|----------|--------|--------|
| Crash Rate | Baseline | | |
| Error Rate | Baseline | | |
| Player Complaints | Decreasing | | |
| Session Length | Baseline | | |

## Rollback Communication Templates

### Internal Announcement

```
🚨 ROLLBACK INITIATED 🚨

Version: [VERSION]
Reason: [BRIEF REASON]
Rollback To: [PREVIOUS VERSION]
ETA: [TIME]

Incident Lead: [NAME]
Communication Lead: [NAME]

Updates in #incident-response
```

### Player Announcement

```
We've temporarily rolled back to version [PREVIOUS] 
due to [BRIEF REASON]. 

We're working on a fix and will update soon.

Thank you for your patience.
```

### Support Briefing

```
ROLLBACK SUMMARY
================

What Happened: [DESCRIPTION]
Player Impact: [IMPACT]
Current Status: Rolled back to [VERSION]
Workaround: [IF ANY]
Fix ETA: [TIMELINE]

Support Responses:
- Acknowledge issue
- Confirm rollback in progress/complete
- No player action needed
- Will update when fix available
```

## Rollback Testing

### Pre-Release Test

Before each release, test the rollback:

```bash
# 1. Deploy test build to Steam (private branch)
python scripts/deploy/steam_deploy.py --branch test

# 2. Verify test build works
# (Manual test on test branch)

# 3. Rollback to previous
python scripts/deploy/steam_rollback.py --to v[PREVIOUS]

# 4. Verify rollback works
# (Manual test - should see previous version)

# 5. Document rollback time
Rollback Time: ___ minutes
```

### Rollback Time Budget

| Platform | Target | Maximum |
|----------|--------|---------|
| Steam | 15 min | 30 min |
| Console | 2 hours | 4 hours |
| Mobile | 1 hour | 2 hours |

## Post-Rollback Actions

### Hotfix Process

1. Create hotfix branch from rolled-back version
2. Apply minimal fix
3. Fast-track through quality gates
4. Deploy as emergency release

### Incident Review

- [ ] Timeline documented
- [ ] Root cause identified
- [ ] Contributing factors analyzed
- [ ] Prevention measures identified
- [ ] Process improvements documented
- [ ] [[Postmortem_Process]] completed

## Rollback Decision Tree

```
                    CRITICAL ISSUE DETECTED
                             │
                             ▼
                    ┌─────────────────┐
                    │ Affect > 50%    │
                    │ of users?       │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                   YES               NO
                    │                 │
                    ▼                 ▼
            ┌──────────────┐   ┌──────────────┐
            │ ROLLBACK     │   │ Can hotfix   │
            │ IMMEDIATELY  │   │ in 4 hours?  │
            └──────────────┘   └──────┬───────┘
                                      │
                             ┌────────┴────────┐
                             │                 │
                            YES               NO
                             │                 │
                             ▼                 ▼
                     ┌──────────────┐   ┌──────────────┐
                     │ PREPARE      │   │ ROLLBACK     │
                     │ HOTFIX       │   │ NOW          │
                     └──────────────┘   └──────────────┘
```

## Integration with Other Processes

- **Required by**: [[Release_Certification_Checklist]]
- **Informs**: [[Postmortem_Process]]
- **Uses**: Steam deployment scripts
