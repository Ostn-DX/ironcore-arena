---
title: Risk Taxonomy
type: system
layer: design
status: active
tags:
  - risk
  - taxonomy
  - automation
  - classification
  - quality
  - gates
depends_on:
  - "[Quality_Gates_Overview]"
used_by:
  - "[Known_Risk_Acceptance_Checklist]]"
  - "[[Architecture_Decay_Controls]"
---

# Risk Taxonomy

## Purpose

This document categorizes risks by their detectability (automated vs. human) and provides guidance on which quality gates can catch each type of risk.

## Risk Classification Matrix

| Risk Category | Automated Detection | Human Review | Primary Gate |
|---------------|---------------------|--------------|--------------|
| Compilation Errors | ✅ 100% | ❌ | [[Build_Gate]] |
| Unit Test Failures | ✅ 100% | ❌ | [[Unit_Tests_Gate]] |
| Determinism Issues | ✅ 100% | ❌ | [[Determinism_Replay_Gate]] |
| Performance Regressions | ✅ 95% | ⚠️ | [[Performance_Gate]] |
| Memory Leaks | ✅ 90% | ⚠️ | [[Performance_Gate]] |
| Security Vulnerabilities | ✅ 80% | ✅ | [[Security_Secret_Scanning_Gate]] |
| Code Quality Issues | ✅ 85% | ✅ | [[Lint_Static_Analysis_Gate]] |
| Content Errors | ✅ 95% | ⚠️ | [[Content_Validation_Gate]] |
| UI Breakage | ✅ 70% | ✅ | [[UI_Smoke_Gate]] |
| Game Balance | ⚠️ 30% | ✅ | [[Headless_Match_Batch_Gate]] |
| Fun Factor | ❌ 0% | ✅ | Playtesting |
| Visual Quality | ❌ 10% | ✅ | Art Review |
| Audio Quality | ❌ 10% | ✅ | Audio Review |
| Narrative Coherence | ❌ 0% | ✅ | Design Review |
| UX Flow | ⚠️ 20% | ✅ | UX Review |

## Automated Detection (Gates)

### Fully Automated (No Human Required)

These risks are caught 100% by automated gates:

| Risk | Gate | Detection Method |
|------|------|------------------|
| Syntax errors | [[Build_Gate]] | Compiler |
| Missing references | [[Build_Gate]] | Unity build |
| Test assertions | [[Unit_Tests_Gate]] | NUnit runner |
| State hash mismatch | [[Determinism_Replay_Gate]] | Hash comparison |
| JSON parse errors | [[Content_Validation_Gate]] | Schema validator |
| Missing assets | [[Content_Validation_Gate]] | Reference checker |
| Secret leakage | [[Security_Secret_Scanning_Gate]] | Pattern matching |
| FPS below threshold | [[Performance_Gate]] | Profiler data |
| Memory budget exceeded | [[Performance_Gate]] | Memory tracker |

### Mostly Automated (Human Review Optional)

These risks are mostly caught by gates, but may need human judgment:

| Risk | Gate | Automated | Human |
|------|------|-----------|-------|
| Performance regression | [[Performance_Gate]] | Detects change | Judges significance |
| Code complexity | [[Lint_Static_Analysis_Gate]] | Calculates metrics | Judges refactor need |
| UI element missing | [[UI_Smoke_Gate]] | Detects absence | Judges impact |
| Balance issues | [[Headless_Match_Batch_Gate]] | Detects win rate skew | Judges acceptability |
| Crash rate | [[Headless_Match_Batch_Gate]] | Counts crashes | Judges severity |

## Human-Required Detection

### Design & Creative Risks

These risks require human judgment and cannot be automated:

| Risk | Detection Method | Review Process |
|------|------------------|----------------|
| Fun factor | Playtesting | Internal playtests, focus groups |
| Game balance (feel) | Playtesting | Designer evaluation |
| Visual appeal | Art review | Art director sign-off |
| Audio quality | Listening | Audio director review |
| Narrative coherence | Reading | Narrative designer review |
| Pacing | Playtesting | Designer evaluation |
| Difficulty curve | Playtesting | Analytics + designer review |

### UX Risks

| Risk | Detection Method | Review Process |
|------|------------------|----------------|
| Control responsiveness | Playtesting | UX evaluation |
| Menu clarity | User testing | UX researcher observation |
| Tutorial effectiveness | New player testing | Onboarding metrics |
| Feedback clarity | Playtesting | Designer + UX review |

## Risk Priority by Automation Potential

### High Automation Priority

Focus automation efforts here for maximum ROI:

1. **Compilation & Build** - 100% automatable
2. **Unit Tests** - 100% automatable
3. **Determinism** - 100% automatable (for sim games)
4. **Content Validation** - 95% automatable
5. **Performance Budgets** - 90% automatable

### Medium Automation Priority

Some automation possible, human judgment needed:

1. **Security Scanning** - 80% automatable
2. **Code Quality** - 85% automatable
3. **UI Automation** - 70% automatable
4. **Crash Detection** - 90% automatable

### Low Automation Priority

Minimal automation possible:

1. **Balance (feel)** - 30% automatable
2. **Visual Quality** - 10% automatable
3. **Audio Quality** - 10% automatable
4. **Fun Factor** - 0% automatable

## Gate Coverage Analysis

```
RISK COVERAGE BY GATE
=====================

Build Gate:           ████████████████████ 100% (compilation, references)
Unit Tests Gate:      ████████████████████ 100% (tested logic)
Determinism Gate:     ████████████████████ 100% (replay consistency)
Content Gate:         ███████████████████░  95% (data integrity)
Performance Gate:     ██████████████████░░  90% (metrics, budgets)
Security Gate:        ███████████████░░░░░  80% (secrets, patterns)
Lint Gate:            ██████████████░░░░░░  85% (code quality)
UI Smoke Gate:        ██████████████░░░░░░  70% (critical paths)
Batch Match Gate:     ███████░░░░░░░░░░░░░  30% (balance only)

OVERALL AUTOMATION:   ████████████████░░░░  78%
```

## Risk Escalation Matrix

| Risk Level | Automated Detection | Human Escalation | Timeline |
|------------|---------------------|------------------|----------|
| Critical | Immediate block | Immediate alert | < 5 min |
| High | Block + alert | Same-day review | < 4 hours |
| Medium | Warning | Weekly review | < 1 week |
| Low | Log only | Monthly review | < 1 month |

## Gate Investment Recommendations

### Tier 1: Essential (100% coverage required)

- [[Build_Gate]] - Zero tolerance for build failures
- [[Unit_Tests_Gate]] - Core logic must be tested
- [[Security_Secret_Scanning_Gate]] - Security is non-negotiable

### Tier 2: High Value (90%+ coverage target)

- [[Content_Validation_Gate]] - Prevents runtime errors
- [[Performance_Gate]] - Maintains player experience
- [[Determinism_Replay_Gate]] - For multiplayer/sim games

### Tier 3: Important (70%+ coverage target)

- [[Lint_Static_Analysis_Gate]] - Code quality maintenance
- [[UI_Smoke_Gate]] - Critical path validation
- [[Packaging_Gate]] - Distribution readiness

### Tier 4: Supplementary (Nice to have)

- [[Headless_Match_Batch_Gate]] - Balance data, not blocking

## Automation Limitations

### What Gates Cannot Catch

1. **Subjective Experience**
   - Is the game fun?
   - Does it feel fair?
   - Is it visually appealing?

2. **Emergent Behavior**
   - Unexpected strategy discoveries
   - Unintended combo interactions
   - Player creativity

3. **Contextual Appropriateness**
   - Is this the right time for this feature?
   - Does this fit the game's tone?
   - Is the difficulty appropriate?

4. **Market Fit**
   - Will players want this?
   - Is the price right?
   - Is the positioning correct?

## Human-in-the-Loop Requirements

Even with full automation, humans must:

1. **Design Review** - Approve feature designs
2. **Playtest** - Validate fun factor
3. **Art Review** - Approve visual quality
4. **Audio Review** - Approve sound design
5. **Final Certification** - Sign off on release

## Integration with Other Processes

- **Informs**: [[Known_Risk_Acceptance_Checklist]] (automation level)
- **Guides**: [[Architecture_Decay_Controls]] (automation priorities)
- **Used by**: Release planning (human resource allocation)
