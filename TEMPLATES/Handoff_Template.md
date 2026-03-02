# Handoff Template
## AI-Native Game Studio OS - Inter-Agent Communication

---

## Handoff Information

| Field | Value |
|-------|-------|
| Handoff ID | HANDOFF-[YYYY]-[NNNN] |
| Timestamp | [ISO8601] |
| From Agent | [AGENT_ID] |
| To Agent | [AGENT_ID] |
| Task ID | [TASK_ID] |
| Priority | P0/P1/P2/P3 |

---

## Task Summary

### Original Request
[Brief description of original task]

### Objectives
- [Objective 1]
- [Objective 2]
- [Objective 3]

---

## Work Completed

### Completed Items
- [x] [Item 1]
- [x] [Item 2]
- [x] [Item 3]

### Partially Completed
- [~] [Item 4] - [Reason for partial completion]

### Not Started
- [ ] [Item 5]

---

## Current State

### Progress
```
[████████████████████░░░░] XX%
```

### Current Blockers
| Blocker | Severity | ETA Resolution |
|---------|----------|----------------|
| [Description] | HIGH/MEDIUM/LOW | [ETA] |

### Decisions Made
| Decision | Rationale | Timestamp |
|----------|-----------|-----------|
| [Decision] | [Rationale] | [Time] |

---

## Context Pack

### Request Context
```json
{
  "original_request": "...",
  "parameters": {...},
  "constraints": {...}
}
```

### System State
```json
{
  "domain_states": {...},
  "active_executions": [...],
  "resource_utilization": {...}
}
```

### Relevant Artifacts
| Artifact | Location | Hash |
|----------|----------|------|
| [Name] | [Path] | [SHA256] |

### Log References
- [Log entry 1]
- [Log entry 2]

---

## Next Steps

### Immediate Actions
1. [Action 1]
2. [Action 2]

### Pending Decisions
| Decision | Options | Recommendation |
|----------|---------|----------------|
| [Decision] | [Options] | [Recommendation] |

### Risks & Mitigations
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk] | HIGH/MEDIUM/LOW | HIGH/MEDIUM/LOW | [Mitigation] |

---

## Metrics

| Metric | Value |
|--------|-------|
| Time Spent | [X] hours |
| Tokens Used | [X] |
| Cost Incurred | $[X.XX] |
| Iterations | [X] |

---

## Notes

[Additional notes for receiving agent]

---

## Acknowledgment

Receiving Agent: _________________

Acknowledged At: _________________

---

*Template Version: 1.0.0*
