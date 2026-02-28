---
title: Postmortem Process
type: system
layer: execution
status: active
tags:
  - postmortem
  - retrospective
  - learning
  - improvement
  - incident
  - analysis
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Architecture_Decay_Controls]]"
  - "[[Risk_Taxonomy]"
used_by: []
---

# Postmortem Process

## Purpose

Postmortems are blameless investigations into significant incidents, releases, or milestones. They identify root causes, extract lessons learned, and drive process improvements.

## When to Conduct Postmortems

### Mandatory Postmortems

| Trigger | Timeline | Participants |
|---------|----------|--------------|
| Production incident (P0/P1) | Within 48 hours | Full team |
| Release rollback | Within 24 hours | Release team |
| Security breach | Within 4 hours | Security team |
| Data loss | Within 4 hours | Full team |
| Major milestone | Within 1 week | Full team |

### Optional Postmortems

| Trigger | Timeline | Participants |
|---------|----------|--------------|
| Release with > 5 critical bugs | Within 1 week | QA + Dev |
| Sprint with < 50% completion | Within 1 week | Team |
| Feature cancellation | Within 1 week | Feature team |

## Postmortem Template

```markdown
# Postmortem: [TITLE]

## Metadata
| Field | Value |
|-------|-------|
| Date | YYYY-MM-DD |
| Incident ID | INC-XXX |
| Severity | P0/P1/P2/P3 |
| Duration | HH:MM |
| Reporter | @name |

## Summary
[One-paragraph summary of what happened]

## Timeline

| Time | Event | Source |
|------|-------|--------|
| 09:00 | Issue detected | Monitoring alert |
| 09:05 | Team notified | Slack #alerts |
| 09:15 | Investigation started | @alice |
| 09:30 | Root cause identified | Log analysis |
| 09:45 | Fix deployed | @bob |
| 10:00 | Service restored | Monitoring |

## Impact

| Metric | Value |
|--------|-------|
| Users Affected | X% (N players) |
| Downtime | HH:MM |
| Data Lost | Yes/No (amount) |
| Revenue Impact | $X |
| Reputation Impact | Description |

## Root Cause Analysis

### 5 Whys

1. **Why did the issue occur?**
   - Answer

2. **Why did [answer to 1] happen?**
   - Answer

3. **Why did [answer to 2] happen?**
   - Answer

4. **Why did [answer to 3] happen?**
   - Answer

5. **Why did [answer to 4] happen?**
   - Root cause

### Contributing Factors

- Factor 1: Description
- Factor 2: Description
- Factor 3: Description

## Detection

### How Was the Issue Detected?
- [ ] Monitoring alert
- [ ] Player report
- [ ] Internal testing
- [ ] Automated test
- [ ] Other: _____

### Detection Delay
Time from issue start to detection: _____

### Could Detection Have Been Faster?
[Analysis of detection gaps]

## Response

### Response Actions
1. Action 1 (time taken)
2. Action 2 (time taken)
3. Action 3 (time taken)

### What Went Well
- Positive aspect 1
- Positive aspect 2

### What Could Have Gone Better
- Improvement area 1
- Improvement area 2

## Resolution

### Fix Applied
[Description of the fix]

### Verification
- [ ] Fix tested in staging
- [ ] Fix deployed to production
- [ ] Monitoring confirms resolution

## Lessons Learned

### Technical
1. Lesson 1
2. Lesson 2

### Process
1. Lesson 1
2. Lesson 2

### Communication
1. Lesson 1
2. Lesson 2

## Action Items

| ID | Action | Owner | Due Date | Priority |
|----|--------|-------|----------|----------|
| A1 | [Description] | @name | YYYY-MM-DD | High |
| A2 | [Description] | @name | YYYY-MM-DD | Medium |
| A3 | [Description] | @name | YYYY-MM-DD | Low |

## Prevention

### How Can This Be Prevented?
1. Prevention measure 1
2. Prevention measure 2

### Which Gates Could Have Caught This?
- [ ] [[Build_Gate]]
- [ ] [[Unit_Tests_Gate]]
- [ ] [[Determinism_Replay_Gate]]
- [ ] [[Performance_Gate]]
- [ ] [[Content_Validation_Gate]]
- [ ] [[Security_Secret_Scanning_Gate]]
- [ ] Other: _____

### Gate Improvements Needed
[Description of gate enhancements]

## Related Documentation

- Incident ticket: [TICKET-XXX]
- Fix PR: [PR-XXX]
- Monitoring dashboard: [Link]
- Slack thread: [Link]

## Sign-Off

| Role | Name | Date |
|------|------|------|
| Incident Lead | | |
| Tech Lead | | |
| Producer | | |

---

*This postmortem follows the principle of blameless postmortems. We focus on systemic issues, not individual fault.*
```

## Postmortem Meeting Format

### Before the Meeting
- [ ] Timeline documented
- [ ] Data gathered (logs, metrics)
- [ ] Template filled out
- [ ] Participants invited

### Meeting Agenda (60 minutes)

| Time | Topic | Owner |
|------|-------|-------|
| 0:00 | Opening & ground rules | Facilitator |
| 0:05 | Timeline review | Incident Lead |
| 0:15 | Impact assessment | Reporter |
| 0:20 | Root cause analysis | Team |
| 0:35 | Lessons learned | Team |
| 0:45 | Action items | Team |
| 0:55 | Closing | Facilitator |

### Ground Rules

1. **Blameless** - Focus on systems, not people
2. **Fact-based** - Use data, not opinions
3. **Constructive** - Aim for improvement
4. **Inclusive** - All voices heard
5. **Action-oriented** - Leave with clear next steps

## Postmortem Outcomes

### Immediate Actions (Within 24 hours)
- [ ] Postmortem document published
- [ ] Critical action items assigned
- [ ] Team briefed on lessons learned

### Short-term Actions (Within 1 week)
- [ ] Action items in sprint backlog
- [ ] Gate improvements identified
- [ ] Process changes documented

### Long-term Actions (Within 1 month)
- [ ] Follow-up on action items
- [ ] Measure improvement effectiveness
- [ ] Update playbooks

## Postmortem Repository

```
Postmortems/
├── 2024/
│   ├── Q1/
│   │   ├── 2024-01-15_database_outage.md
│   │   └── 2024-02-20_release_rollback.md
│   ├── Q2/
│   └── Q3/
└── Templates/
    └── postmortem_template.md
```

## Integration with Other Processes

- **Informs**: [[Architecture_Decay_Controls]] (systemic issues)
- **Updates**: [[Risk_Taxonomy]] (new risk patterns)
- **Improves**: Quality gates (gap analysis)
- **Feeds**: Sprint planning (action items)

## Postmortem Metrics

Track these to measure learning:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Postmortems completed | 100% of triggers | Count |
| Action items completed | > 80% | Completion rate |
| Repeat incidents | < 10% | Incident similarity |
| Time to postmortem | < 48 hours | Average |
| Time to action items | < 1 week | Average |
