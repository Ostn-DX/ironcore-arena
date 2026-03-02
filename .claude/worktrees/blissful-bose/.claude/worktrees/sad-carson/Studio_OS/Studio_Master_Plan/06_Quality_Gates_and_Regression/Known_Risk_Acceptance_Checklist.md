---
title: Known Risk Acceptance Checklist
type: template
layer: execution
status: active
tags:
  - risk
  - acceptance
  - checklist
  - mitigation
  - exceptions
  - documentation
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Risk_Taxonomy]]"
  - "[[Release_Certification_Checklist]"
used_by: []
---

# Known Risk Acceptance Checklist

## Purpose

This checklist documents known risks that are being accepted for a release. It ensures conscious decision-making, proper documentation, and clear accountability for each accepted risk.

## Risk Information

| Field | Value |
|-------|-------|
| Release Version | |
| Date | |
| Risk ID | RISK-XXX |
| Category | |
| Severity | |
| Gate Affected | |

## Risk Description

### Summary
[One-line description of the risk]

### Detailed Description
[Full explanation of what could go wrong]

### Impact Assessment
- **Users Affected**: [Percentage or count]
- **Platforms Affected**: [Which platforms]
- **Feature Affected**: [Which feature/system]
- **Worst Case Scenario**: [What happens if risk materializes]

### Probability
- [ ] Rare (< 1% of users)
- [ ] Unlikely (1-10% of users)
- [ ] Possible (10-50% of users)
- [ ] Likely (> 50% of users)

### Severity
- [ ] Critical (Game unplayable, data loss, security breach)
- [ ] High (Major feature broken, frequent crashes)
- [ ] Medium (Minor feature issues, workarounds exist)
- [ ] Low (Cosmetic issues, minor inconvenience)

## Risk Matrix

```
            PROBABILITY
          Rare  Unlikely  Possible  Likely
         ┌─────┬─────────┬─────────┬──────┐
Critical │ MED │  HIGH   │  CRIT   │ CRIT │
         ├─────┼─────────┼─────────┼──────┤
High     │ LOW │  MED    │  HIGH   │ CRIT │
         ├─────┼─────────┼─────────┼──────┤
Medium   │ LOW │  LOW    │  MED    │ HIGH │
         ├─────┼─────────┼─────────┼──────┤
Low      │ MIN │  LOW    │  LOW    │ MED  │
         └─────┴─────────┴─────────┴──────┘
         
MIN = Minimal risk - document only
LOW = Low risk - team lead approval
MED = Medium risk - producer approval
HIGH = High risk - director approval
CRIT = Critical risk - requires mitigation
```

## Mitigation Plan

### Immediate Mitigation
[What we're doing now to reduce risk]

### Monitoring
[How we'll detect if risk materializes]

### Response Plan
[What we'll do if the risk occurs]

### Timeline for Fix
- [ ] Hotfix (within 24 hours)
- [ ] Patch (within 1 week)
- [ ] Next release (within 1 month)
- [ ] Backlog (no immediate plan)

## Gate Override Justification

### Gate That Failed
[Which quality gate failed]

### Why Override is Necessary
[Business/technical justification]

### Alternative Considered
[What alternatives were evaluated]

### Why Alternatives Rejected
[Why we can't use alternatives]

## Approvals

| Role | Name | Approval | Date | Conditions |
|------|------|----------|------|------------|
| Risk Owner | | | | |
| Tech Lead | | | | |
| Producer | | | | |
| QA Lead | | | | |
| Studio Director | | | | (if required) |

## Documentation

### Related Tickets
- Issue: [TICKET-XXX]
- Fix: [TICKET-XXX]
- Monitoring: [TICKET-XXX]

### Communication
- [ ] Team notified
- [ ] Support briefed
- [ ] Community post drafted (if public)

### Release Notes
[How this risk will be described in release notes]

## Risk Acceptance Template

```
RISK ACCEPTANCE DECLARATION
===========================

Risk ID: [RISK-XXX]
Date: [DATE]
Release: [VERSION]

We acknowledge and accept the following risk:

[RISK DESCRIPTION]

This risk may affect [X%] of users on [PLATFORMS].

The worst-case scenario is: [SCENARIO]

We are accepting this risk because: [JUSTIFICATION]

Mitigation in place: [MITIGATION]

Fix planned for: [TIMELINE]

Approved by:
- [NAME], Tech Lead
- [NAME], Producer
- [NAME], Studio Director (if required)

This acceptance expires on: [DATE] (max 30 days)
```

## Risk Categories

### Technical Risks

| Category | Examples | Typical Mitigation |
|----------|----------|-------------------|
| Performance | FPS drops on low-end | Adaptive quality, monitoring |
| Stability | Rare crash condition | Crash reporting, hotfix ready |
| Compatibility | OS/driver specific | Min spec enforcement, workarounds |
| Data Integrity | Save corruption risk | Backup saves, cloud sync |

### Business Risks

| Category | Examples | Typical Mitigation |
|----------|----------|-------------------|
| Schedule | Release deadline pressure | Scope reduction, overtime |
| Competitive | Market timing | Feature prioritization |
| Resource | Team capacity | Contractor support, overtime |

### External Risks

| Category | Examples | Typical Mitigation |
|----------|----------|-------------------|
| Platform | Steam/Console cert issues | Early submission, buffer time |
| Third-party | SDK/service issues | Fallback plans, monitoring |
| Legal | Content concerns | Legal review, content changes |

## Risk Register

| ID | Description | Probability | Severity | Status | Owner | Fix Target |
|----|-------------|-------------|----------|--------|-------|------------|
| R001 | | | | | | |
| R002 | | | | | | |
| R003 | | | | | | |

## Post-Release Review

After release, review all accepted risks:

- [ ] Did any accepted risk materialize?
- [ ] Was mitigation effective?
- [ ] Was response plan adequate?
- [ ] Should risk acceptance process change?

## Integration with Other Processes

- **Required by**: [[Release_Certification_Checklist]]
- **Informs**: [[Postmortem_Process]]
- **Feeds**: [[Risk_Taxonomy]] (pattern analysis)
