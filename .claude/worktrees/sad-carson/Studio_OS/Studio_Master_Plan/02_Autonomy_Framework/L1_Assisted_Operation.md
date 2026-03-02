---
title: L1 Assisted Operation
type: system
layer: execution
status: active
tags:
  - autonomy
  - L1
  - assisted
  - human-driven
  - level-1
depends_on:
  - "[Autonomy_Ladder_L0_L5]]"
  - "[[Autonomy_Score_Rubric]]"
  - "[[L0_Manual_Operation]"
used_by:
  - "[L2_Supervised_Autonomy]]"
  - "[[Autonomy_Upgrade_Path]"
---

# L1: Assisted Operation

## Level Definition

L1 (Assisted Operation) is human-driven execution with AI assistance. The human makes all decisions and drives the work forward, while the system provides suggestions, automates sub-tasks, and offers support. Human approval is required for all significant actions.

## Human Role

**Driver**: Human directs all work and makes all decisions.

**Responsibilities**:
- Define approach and strategy
- Make all architectural decisions
- Approve or reject all AI suggestions
- Execute or delegate execution of work
- Validate all output
- Decide when to proceed

**Authority**:
- Veto any AI suggestion
- Request alternative approaches
- Change direction at any time
- Escalate or de-escalate autonomy

## System Role

**Assistant**: System provides support but never acts without approval.

**Capabilities**:
- Suggest implementation approaches
- Generate boilerplate code
- Automate repetitive tasks
- Provide context and references
- Answer questions
- Format and refactor on request
- Run tests on command
- Generate options for human selection

**Limitations**:
- Never commits changes without approval
- Never deploys without approval
- Never modifies production without approval
- All suggestions clearly labeled as such

## When to Use L1

### Appropriate Contexts
- **New Domains**: Working in unfamiliar technology or pattern
- **Complex Decisions**: High-stakes choices requiring human judgment
- **Learning**: Human wants to understand while doing
- **First-Time Patterns**: Implementing something for the first time
- **Preference**: Human simply prefers to drive

### Indicators for L1
- Autonomy Score: 21-35
- Some similar work exists but not exact match
- Human explicitly requests L1
- Novel combination of known patterns
- High learning value

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    L1 WORKFLOW                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. HUMAN creates ticket with L1 autonomy                   │
│     └─ System loads context                                 │
│                                                              │
│  2. HUMAN requests suggestions from system                  │
│     └─ System analyzes and provides options                 │
│                                                              │
│  3. HUMAN selects approach or refines request               │
│     └─ Iteration until human satisfied                      │
│                                                              │
│  4. SYSTEM generates initial implementation                 │
│     └─ Human reviews and provides feedback                  │
│                                                              │
│  5. HUMAN approves or requests changes                      │
│     └─ System makes requested changes                       │
│                                                              │
│  6. SYSTEM automates sub-tasks on request                   │
│     └─ Formatting, renaming, etc.                           │
│                                                              │
│  7. HUMAN runs tests (manual or on request)                 │
│     └─ System can execute test commands                     │
│                                                              │
│  8. HUMAN validates and approves final output               │
│     └─ System updates status on human command               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Suggestion Format

All AI suggestions follow this format:

```
[SUGGESTION]
Approach: [Brief description]
Rationale: [Why this approach]
Confidence: [High/Medium/Low]

Implementation:
[Code/Content]

Alternatives:
- [Alternative 1]
- [Alternative 2]

APPROVE / MODIFY / REJECT ?
```

## Automation at L1

The following CAN be automated at L1 (with explicit request):
- ✅ Code formatting
- ✅ Variable renaming
- ✅ Import organization
- ✅ Boilerplate generation
- ✅ Test execution
- ✅ Build execution
- ✅ Documentation generation
- ✅ Simple refactoring

The following require explicit approval:
- ⚠️ Code commits
- ⚠️ File creation/deletion
- ⚠️ Configuration changes
- ⚠️ Dependency changes
- ⚠️ Any production impact

## Interaction Patterns

### Pattern: Suggest-Select-Refine
1. System suggests multiple approaches
2. Human selects one or requests alternatives
3. System implements selected approach
4. Human reviews and requests refinements
5. Iterate until human approves

### Pattern: Human-Drives-System-Assists
1. Human defines approach
2. System provides supporting automation
3. Human reviews and directs
4. System executes sub-tasks
5. Human validates final result

### Pattern: Exploratory
1. Human asks questions
2. System provides information
3. Human explores options
4. System generates examples
5. Human decides on direction

## Escalation Triggers

From L1, escalate to L0 when:
- Human wants complete manual control
- System suggestions consistently unhelpful
- Task too simple for assistance overhead

From L1, escalate to L2 when:
- Pattern becomes clear
- Human tired of approving every step
- Success rate high for similar tasks
- Human trusts system judgment

## Exit Criteria

To promote from L1 to L2:
- Minimum 5 successful L1 completions
- Human comfortable with system capabilities
- Pattern documented
- Success rate >80% for suggestions

## Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Suggestion acceptance rate | >70% | Approved / Total suggestions |
| Iteration count | <3 | Average iterations per task |
| Human decision time | <5 min | Time to approve/reject |
| Cycle time vs L0 | -20% | Compared to manual |

## Cost Profile

| Cost Type | Amount |
|-----------|--------|
| API calls | Low (suggestions only) |
| Compute | Local + minimal cloud |
| Human time | High (~80% of L0) |

## Safety

L1 maintains strong safety through human oversight:
- All significant actions approved
- Human can intervene at any time
- Clear audit trail of decisions
- Easy to course-correct

## Best Practices

1. **Be Explicit**: Clearly state what you want from the system
2. **Provide Feedback**: Accept/reject suggestions promptly
3. **Ask Questions**: Use system as learning resource
4. **Iterate**: Don't expect perfect first attempt
5. **Document Decisions**: Note why approaches were chosen

## Example Interaction

```
Human: "I need to implement player movement. Suggest approaches."

System: "[SUGGESTION] Three approaches:
1. CharacterBody2D with built-in physics
2. RigidBody2D for realistic physics
3. Custom implementation for precise control

Recommendation: CharacterBody2D for platformer
Confidence: High

APPROVE / MODIFY / REJECT ?"

Human: "APPROVE. Generate implementation."

System: "[GENERATED CODE]
class_name PlayerController
extends CharacterBody2D
...

APPROVE / MODIFY / REJECT ?"

Human: "MODIFY: Add double jump."

System: "[UPDATED CODE]
...

APPROVE / MODIFY / REJECT ?"

Human: "APPROVE. Commit this."

System: "Committing with message: 'Add player controller with double jump'
CONFIRM ?"

Human: "CONFIRM"
```

## Enforcement

- All AI outputs labeled as suggestions
- No action without explicit approval
- Approval logged with timestamp
- Human can override at any point
