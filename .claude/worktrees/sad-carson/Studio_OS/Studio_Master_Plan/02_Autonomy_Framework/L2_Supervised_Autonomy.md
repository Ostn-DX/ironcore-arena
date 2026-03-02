---
title: L2 Supervised Autonomy
type: system
layer: execution
status: active
tags:
  - autonomy
  - L2
  - supervised
  - ai-driven
  - level-2
depends_on:
  - "[Autonomy_Ladder_L0_L5]]"
  - "[[Autonomy_Score_Rubric]]"
  - "[[L1_Assisted_Operation]"
used_by:
  - "[L3_Conditional_Autonomy]]"
  - "[[Autonomy_Upgrade_Path]"
---

# L2: Supervised Autonomy

## Level Definition

L2 (Supervised Autonomy) is AI-driven execution with human checkpoints. The system executes work autonomously but pauses at defined gates for human review and approval. Human involvement is required to proceed past checkpoints but not during execution between checkpoints.

## Human Role

**Supervisor**: Human reviews checkpoints and approves progression.

**Responsibilities**:
- Review output at each checkpoint
- Approve or reject continuation
- Provide feedback on issues
- Decide on remediation approach
- Approve final shipment

**Authority**:
- Block progression at any checkpoint
- Request changes or remediation
- Escalate or de-escalate autonomy
- Override system decisions

**Time Commitment**:
- Checkpoint reviews: 5-15 minutes each
- Typical ticket: 2-4 checkpoints
- Total human time: ~30-60 minutes per ticket

## System Role

**Executor**: System drives execution and pauses at checkpoints.

**Capabilities**:
- Execute multi-step work autonomously
- Pause at defined checkpoints
- Present comprehensive context at checkpoints
- Execute remediation on approval
- Track progress and state
- Self-monitor for issues

**Limitations**:
- Cannot proceed past checkpoint without approval
- Must present all relevant context
- Must flag any concerns
- Cannot hide failures or issues

## When to Use L2

### Appropriate Contexts
- **Standard Development**: Routine implementation work
- **Established Patterns**: Well-understood problem domains
- **Building Trust**: First runs of new automation
- **Medium Stakes**: Important but not critical work
- **Learning System**: Understanding system capabilities

### Indicators for L2
- Autonomy Score: 36-55
- Established patterns available
- Similar work completed successfully
- Human wants oversight but not involvement
- Default autonomy for most work

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    L2 WORKFLOW                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. SYSTEM parses ticket and creates plan                   │
│     └─ Human notified of plan                               │
│                                                              │
│  2. SYSTEM executes first phase                             │
│     └─ Human not involved                                   │
│                                                              │
│  3. SYSTEM reaches checkpoint, pauses                       │
│     └─ Checkpoint notification sent to human                │
│                                                              │
│  4. HUMAN reviews checkpoint output                         │
│     └─ System provides: results, context, concerns          │
│                                                              │
│  5. HUMAN approves, requests changes, or rejects            │
│     └─ System acts on human direction                       │
│                                                              │
│  6. Repeat steps 2-5 for each checkpoint                    │
│     └─ Typically 2-4 checkpoints per ticket                 │
│                                                              │
│  7. Final checkpoint: shipment approval                     │
│     └─ Human approves final integration                     │
│                                                              │
│  8. SYSTEM completes integration                            │
│     └─ Ticket marked complete                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Checkpoint Structure

Each checkpoint includes:

```yaml
checkpoint:
  id: [UUID]
  ticket: [Ticket reference]
  phase: [Phase name]
  status: awaiting_review
  
  output:
    summary: [What was accomplished]
    artifacts: [List of created/modified files]
    metrics: [Lines of code, test coverage, etc.]
  
  context:
    decisions_made: [Key decisions during execution]
    issues_encountered: [Any problems and resolutions]
    concerns: [Anything human should know]
  
  validation:
    automated_tests: [Test results]
    static_analysis: [Linting, type checking, etc.]
    gate_status: [Pass/Fail for automated gates]
  
  next_phase:
    description: [What will happen next]
    estimated_duration: [How long it will take]
    risks: [Potential issues]
  
  human_action:
    approve: [Continue to next phase]
    request_changes: [Specify changes needed]
    reject: [Abort and explain why]
    escalate: [Escalate to higher authority]
```

## Checkpoint Placement

Typical checkpoints for different work types:

### Code Implementation
1. After initial implementation
2. After test addition
3. Final review before commit

### Asset Creation
1. After draft/prototype
2. After refinement
3. Final approval before integration

### Feature Development
1. After architecture/design
2. After core implementation
3. After testing
4. Final integration approval

## Checkpoint Review Format

Human receives:

```
═══════════════════════════════════════════════════════════════
CHECKPOINT REVIEW REQUIRED
Ticket: [Title] | Phase: [Phase Name]
═══════════════════════════════════════════════════════════════

SUMMARY
[What was accomplished in this phase]

OUTPUT
- Files created: [N]
- Files modified: [N]
- Lines added: [N]
- Lines removed: [N]
- Test coverage: [N]%

AUTOMATED VALIDATION
✓ Unit tests: [N] passed, [N] failed
✓ Integration tests: [N] passed, [N] failed
✓ Static analysis: [Pass/Fail]
✓ Style checks: [Pass/Fail]

CONCERNS
[None / List of concerns]

NEXT PHASE
[Description of what happens next]
Estimated: [Duration]

ACTION REQUIRED
[APPROVE] - Continue to next phase
[REQUEST CHANGES] - Specify: ____________
[REJECT] - Abort this ticket
[ESCALATE] - Escalate to: ____________
═══════════════════════════════════════════════════════════════
```

## Escalation Triggers

From L2, escalate to L1 when:
- System consistently makes poor decisions
- Human wants more control
- Novel situation arises
- Trust in system decreases

From L2, escalate to L3 when:
- High checkpoint pass rate (>95%)
- Human approves most checkpoints without changes
- Pattern proven stable
- Human time better spent elsewhere

## Exit Criteria

To promote from L2 to L3:
- Minimum 10 successful L2 completions
- Checkpoint approval rate >95%
- Zero critical issues in last 10 tickets
- Automated gates defined and passing
- Human approves promotion

## Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Checkpoint approval rate | >90% | Approved / Total checkpoints |
| Time to review | <15 min | Human review duration |
| Changes per checkpoint | <1 | Average change requests |
| Cycle time vs L1 | -30% | Compared to assisted |

## Cost Profile

| Cost Type | Amount |
|-----------|--------|
| API calls | Moderate (execution + checkpoints) |
| Compute | Local + some cloud |
| Human time | Moderate (~40% of L0) |

## Safety

L2 provides safety through checkpoint reviews:
- Human sees all significant output
- Issues caught before integration
- Course correction possible
- Final approval before shipment

## Best Practices

1. **Review Promptly**: Don't let checkpoints queue up
2. **Be Thorough**: Check both what was done and what wasn't
3. **Provide Feedback**: Help system learn from reviews
4. **Ask Questions**: If something is unclear, ask
5. **Trust but Verify**: Assume good work, but verify

## Example Checkpoint Review

```
═══════════════════════════════════════════════════════════════
CHECKPOINT REVIEW REQUIRED
Ticket: Implement enemy AI patrol behavior | Phase: Implementation
═══════════════════════════════════════════════════════════════

SUMMARY
Implemented patrol behavior for enemy AI with waypoint following,
direction changes, and idle states.

OUTPUT
- Files created: 1 (enemy_patrol.gd)
- Files modified: 2 (enemy.gd, level_1.tscn)
- Lines added: 156
- Lines removed: 12
- Test coverage: 87%

AUTOMATED VALIDATION
✓ Unit tests: 12 passed, 0 failed
✓ Integration tests: 5 passed, 0 failed
✓ Static analysis: Pass
✓ Style checks: Pass

CONCERNS
- None

NEXT PHASE
Add edge case tests for patrol boundary conditions
Estimated: 10 minutes

ACTION REQUIRED
[APPROVE] - Continue to test phase
[REQUEST CHANGES] - Specify: ____________
[REJECT] - Abort this ticket
[ESCALATE] - Escalate to: ____________
═══════════════════════════════════════════════════════════════

Human: APPROVE
```

## Enforcement

- System MUST pause at checkpoints
- System MUST present comprehensive context
- Human MUST approve to proceed
- All checkpoint decisions logged
- Timeout on checkpoint = escalation
