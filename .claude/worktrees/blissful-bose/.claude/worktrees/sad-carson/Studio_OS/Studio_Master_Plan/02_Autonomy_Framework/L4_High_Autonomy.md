---
title: L4 High Autonomy
type: system
layer: execution
status: active
tags:
  - autonomy
  - L4
  - high
  - milestone
  - batch
  - level-4
depends_on:
  - "[Autonomy_Ladder_L0_L5]]"
  - "[[Autonomy_Score_Rubric]]"
  - "[[L3_Conditional_Autonomy]"
used_by:
  - "[L5_Full_Autonomy]]"
  - "[[Autonomy_Upgrade_Path]"
---

# L4: High Autonomy

## Level Definition

L4 (High Autonomy) is AI-driven execution with milestone reviews only. The system manages multiple related tickets, executes complete workflows, and batches work for periodic human review. Human is involved only at predefined milestones, not per-ticket.

## Human Role

**Milestone Reviewer**: Human reviews aggregated results at milestones.

**Responsibilities**:
- Review batched work at milestones
- Approve or reject milestone deliverables
- Provide strategic direction
- Handle exceptions and escalations
- Set milestone criteria

**Authority**:
- Approve/reject milestone completion
- Redefine milestone criteria
- Escalate or de-escalate autonomy
- Interrupt batch processing
- Request per-ticket review

**Time Commitment**:
- Milestone reviews: 30-60 minutes each
- Milestone frequency: Daily or per-sprint
- Typical milestone: 5-20 tickets
- Human time per ticket: ~2-5 minutes

## System Role

**Batch Manager**: System manages work across multiple tickets with minimal human involvement.

**Capabilities**:
- Manage multiple related tickets
- Self-prioritize within constraints
- Batch work for efficient processing
- Execute complete workflows
- Aggregate results for milestone review
- Self-monitor and self-report
- Escalate exceptions

**Batching Strategy**:
- Group related tickets
- Sequence for dependency efficiency
- Parallelize independent work
- Aggregate for milestone review

## When to Use L4

### Appropriate Contexts
- **Production Workflows**: Mature development processes
- **High Volume**: Many similar tickets
- **Well-Understood Domain**: Established patterns
- **Efficiency Focus**: Minimize per-ticket overhead
- **Strategic Oversight**: Human focuses on direction, not execution

### Indicators for L4
- Autonomy Score: 76-90
- Sustained success at L3
- Milestone gates defined
- Human rarely intervenes at L3
- Pattern extremely stable

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    L4 WORKFLOW                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. SYSTEM receives batch of related tickets                │
│     └─ Human defines milestone criteria                     │
│                                                              │
│  2. SYSTEM prioritizes and sequences tickets                │
│     └─ Dependency analysis, parallelization                 │
│                                                              │
│  3. SYSTEM executes tickets autonomously                    │
│     └─ L3-level autonomy per ticket                         │
│                                                              │
│  4. SYSTEM aggregates completed work                        │
│     └─ Results batched for milestone                        │
│                                                              │
│  5. SYSTEM prepares milestone report                        │
│     └─ Summary, metrics, concerns                           │
│                                                              │
│  6. HUMAN reviews milestone deliverables                    │
│     └─ Batch review, not per-ticket                         │
│                                                              │
│  7. HUMAN approves or requests changes                      │
│     └─ Approval = all tickets integrated                    │
│                                                              │
│  8. SYSTEM integrates approved work                         │
│     └─ Milestone complete                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Milestone Structure

### Milestone Definition

```yaml
milestone:
  id: [UUID]
  name: [Milestone name]
  description: [What this milestone represents]
  
  criteria:
    - All tickets in scope completed
    - All gates passed
    - No critical issues
    - Metrics meet targets
  
  scope:
    tickets: [List of ticket IDs]
    themes: [Feature areas covered]
    estimated_effort: [Story points or hours]
  
  review_requirements:
    reviewer: [Role required]
    format: [Report / Demo / Code review]
    duration: [Estimated review time]
  
  on_approval:
    action: integrate
    notify: [Stakeholders]
  
  on_rejection:
    action: remediate
    feedback_required: true
```

### Milestone Report Format

```
═══════════════════════════════════════════════════════════════
MILESTONE REVIEW: [Milestone Name]
Date: [Date] | Reviewer: [Role]
═══════════════════════════════════════════════════════════════

SUMMARY
[Ticket count] tickets completed
[Feature summary]

TICKETS COMPLETED
✓ [TICKET-001] [Title] [Status]
✓ [TICKET-002] [Title] [Status]
...

AGGREGATE METRICS
- Total lines added: [N]
- Total lines removed: [N]
- Test coverage: [N]%
- Tests added: [N]
- Tests passing: [N]/[N]

QUALITY INDICATORS
✓ Gate pass rate: [N]%
✓ No critical issues
⚠ Warning: [Description]

CONCERNS
[None / List of concerns]

RECOMMENDATIONS
[System recommendations for approval]

ACTION REQUIRED
[APPROVE] - Integrate all tickets
[REQUEST CHANGES] - Specify: ____________
[REJECT] - Return all tickets for rework
[REVIEW INDIVIDUAL] - Review specific tickets
═══════════════════════════════════════════════════════════════
```

## Batching Strategy

### Batch by Theme
Group tickets by feature area or theme:
- Player mechanics
- Enemy AI
- UI systems
- Audio

### Batch by Dependency
Sequence tickets by dependencies:
- Foundation first
- Dependent tickets after prerequisites
- Parallelize independent chains

### Batch by Risk
Mix risk levels within batch:
- Include some low-risk (high confidence)
- Include some medium-risk (validation needed)
- Avoid all high-risk in one batch

### Batch Size Guidelines
| Factor | Recommendation |
|--------|----------------|
| Review time | 30-60 minutes per batch |
| Ticket count | 5-20 tickets per batch |
| Complexity | Mix simple and complex |
| Risk | Don't batch all high-risk |

## Escalation Triggers

From L4, escalate to L3 when:
- Milestone rejection rate high
- Quality issues in batches
- Human wants more visibility
- Pattern stability decreases

From L4, escalate to L5 when:
- Milestone approvals routine
- Human rarely requests changes
- System extremely reliable
- 24/7 operation needed

## Exit Criteria

To promote from L4 to L5:
- Minimum 10 successful milestones
- Milestone approval rate >95%
- Human changes per milestone <10%
- Comprehensive monitoring in place
- Exception handling tested
- Human approves promotion

## Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Milestone approval rate | >95% | Approved / Total |
| Changes per milestone | <10% | Changed tickets / Total |
| Escalation rate | <2% | Escalated / Total tickets |
| Cycle time vs L3 | -15% | Compared to conditional |
| Human time per ticket | <5 min | Total human involvement |

## Cost Profile

| Cost Type | Amount |
|-----------|--------|
| API calls | High (batch processing) |
| Compute | Local + cloud |
| Human time | Very Low (~5% of L0) |

## Safety

L4 safety through milestone reviews:
- Batch validation before integration
- Aggregated metrics reveal patterns
- Human sees big picture
- Exceptions escalate immediately
- Can drop to per-ticket review if needed

## Best Practices

1. **Define Clear Milestones**: Criteria should be objective
2. **Right-Size Batches**: Not too big, not too small
3. **Mix Risk Levels**: Don't put all risky work in one batch
4. **Monitor Trends**: Aggregate metrics reveal issues
5. **Stay Interruptible**: Human can always request per-ticket review

## Example Milestone Review

```
═══════════════════════════════════════════════════════════════
MILESTONE REVIEW: Sprint 3 Player Mechanics
Date: 2024-01-15 | Reviewer: Tech Lead
═══════════════════════════════════════════════════════════════

SUMMARY
12 tickets completed covering player movement, jumping, and
interaction systems.

TICKETS COMPLETED
✓ [TICKET-101] Implement walk animation
✓ [TICKET-102] Implement run animation
✓ [TICKET-103] Add jump physics
✓ [TICKET-104] Add double jump
✓ [TICKET-105] Implement coyote time
✓ [TICKET-106] Add jump buffering
✓ [TICKET-107] Implement wall jump
✓ [TICKET-108] Add interaction system
✓ [TICKET-109] Implement item pickup
✓ [TICKET-110] Add inventory UI
✓ [TICKET-111] Implement drop item
✓ [TICKET-112] Add interaction feedback

AGGREGATE METRICS
- Total lines added: 1,247
- Total lines removed: 89
- Test coverage: 91%
- Tests added: 48
- Tests passing: 48/48

QUALITY INDICATORS
✓ Gate pass rate: 98%
✓ No critical issues
✓ All acceptance criteria met

CONCERNS
- None

RECOMMENDATIONS
All tickets meet quality standards. Recommend approval.

ACTION REQUIRED
[APPROVE] - Integrate all tickets
[REQUEST CHANGES] - Specify: ____________
[REJECT] - Return all tickets for rework
[REVIEW INDIVIDUAL] - Review specific tickets
═══════════════════════════════════════════════════════════════

Human: APPROVE
```

## Enforcement

- Milestone criteria MUST be defined before batch
- All tickets in batch MUST meet criteria
- Human MUST approve milestone
- Rejected tickets MUST be remediated
- All milestone decisions logged
