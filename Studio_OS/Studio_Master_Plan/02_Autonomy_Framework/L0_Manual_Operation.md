---
title: L0 Manual Operation
type: system
layer: execution
status: active
tags:
  - autonomy
  - L0
  - manual
  - control
  - level-0
depends_on:
  - "[Autonomy_Ladder_L0_L5]]"
  - "[[Autonomy_Score_Rubric]]"
  - "[[Studio_Priorities_Manifesto]"
used_by:
  - "[L1_Assisted_Operation]]"
  - "[[Autonomy_Upgrade_Path]"
---

# L0: Manual Operation

## Level Definition

L0 (Manual Operation) represents complete human control with no AI automation. The human executes all work directly using standard tools. The system provides documentation and reference materials but performs no automated actions.

## Human Role

**Full Control**: Human makes all decisions and executes all actions.

**Responsibilities**:
- Understand requirements from tickets
- Design implementation approach
- Write all code/assets manually
- Run all tests manually
- Perform all builds manually
- Validate output against acceptance criteria
- Make all decisions about approach and trade-offs

## System Role

**Passive Support**: System provides information but takes no action.

**Capabilities**:
- Display ticket information
- Show linked specifications
- Provide documentation references
- List available tools
- Show historical context
- No automation, no suggestions, no execution

## When to Use L0

### Appropriate Contexts
- **Learning**: Human wants to understand how something works
- **Emergency**: Critical situation requiring direct control
- **Novel Problems**: Tasks too unique for any pattern
- **Debugging**: Investigating system behavior
- **Exploration**: Prototyping or experimenting
- **Distrust**: Human doesn't trust automation for this task

### Indicators for L0
- Autonomy Score: 0-20
- No similar work in history
- High stakes with no fallback
- Human explicitly requests L0
- System recommends L0 due to risk

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    L0 WORKFLOW                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. HUMAN reads ticket in Obsidian                          │
│     └─ System displays ticket content only                  │
│                                                              │
│  2. HUMAN reviews linked specifications                     │
│     └─ System shows spec links, human navigates             │
│                                                              │
│  3. HUMAN designs implementation                            │
│     └─ No system involvement                                │
│                                                              │
│  4. HUMAN implements using own tools                        │
│     └─ IDE, asset tools, etc.                               │
│                                                              │
│  5. HUMAN runs tests manually                               │
│     └─ Test commands executed by human                      │
│                                                              │
│  6. HUMAN validates against acceptance criteria             │
│     └─ Human judgment                                       │
│                                                              │
│  7. HUMAN commits and builds                                │
│     └─ Manual git, manual build                             │
│                                                              │
│  8. HUMAN updates ticket status in Obsidian                 │
│     └─ Manual status update                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Tools Available

At L0, the human uses their preferred tools directly:
- IDE (VS Code, Rider, etc.)
- Godot/Unity editor
- Git CLI or GUI
- Asset creation tools
- Terminal/shell
- Testing frameworks

The system does not invoke these tools; the human does.

## Documentation Access

The system provides read-only access to:
- Ticket details
- Linked specifications
- Historical tickets
- Pattern documentation
- API references
- Architecture decisions

## No Automation Means

At L0, the following are NOT automated:
- ❌ Code generation
- ❌ Code suggestions
- ❌ Test generation
- ❌ Build execution
- ❌ Validation checks
- ❌ Status updates
- ❌ Progress tracking
- ❌ Error analysis

## Escalation

L0 is the minimum autonomy level. There is no lower level to escalate to.

**From L0, human may**:
- Continue at L0
- Request L1 assistance
- Request higher autonomy for future similar work

## Exit Criteria

To move from L0 to L1:
- Human completes task at L0
- Task is documented
- Pattern begins to emerge
- Human comfortable with assistance

## Metrics

| Metric | Measurement |
|--------|-------------|
| Cycle time | Human-reported or inferred |
| Human effort | 100% (baseline) |
| System effort | 0% |
| Escalation rate | N/A (already at minimum) |

## Cost Profile

| Cost Type | Amount |
|-----------|--------|
| API calls | Zero |
| Compute | Human's local machine only |
| Human time | Maximum (100%) |

## Safety

L0 is the safest autonomy level from a control perspective:
- Human has complete visibility
- Human makes all decisions
- No unexpected automation
- Full accountability clear

However, L0 may be less safe for:
- Repetitive tasks (human error)
- Complex validation (human may miss issues)
- Consistency (human may be inconsistent)

## Best Practices

1. **Document Learnings**: When working at L0, document insights for future automation
2. **Identify Patterns**: Look for repeatable elements that could become templates
3. **Note Friction**: Identify painful manual steps that could be automated
4. **Stay Focused**: Without automation, concentration is critical
5. **Take Breaks**: Manual work is tiring; schedule breaks to maintain quality

## Example Ticket

```yaml
---
title: Implement basic player controller
autonomy: L0
status: in_progress
---

## Description
Implement a basic player controller for 2D platformer.

## Acceptance Criteria
- [ ] Player can move left/right
- [ ] Player can jump
- [ ] Player respects gravity
- [ ] Input handling implemented

## Notes
Working at L0 to learn Godot's input system before automating.
```

## Enforcement

- L0 is default for new/unfamiliar domains
- Human can force L0 via ticket metadata
- System respects L0 specification
- No automation triggered at L0
