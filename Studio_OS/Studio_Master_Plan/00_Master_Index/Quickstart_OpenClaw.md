---
title: Quickstart OpenClaw
type: template
layer: execution
status: active
tags:
  - quickstart
  - onboarding
  - tutorial
  - getting-started
  - daily-use
depends_on:
  - "[System_Map]]"
  - "[[Agent_Command_Flow]]"
  - "[[OpenClaw_Core_System]"
used_by:
  - "[How_to_Run_OpenClaw_With_This_Vault]"
---

# Quickstart: OpenClaw Daily Use

## 5-Minute Setup

### Prerequisites

- Obsidian installed with vault at `~/Studio_Master_Plan/`
- OpenClaw daemon running locally
- Git repository configured
- Godot 4.x or Unity installed

### Start OpenClaw

```bash
# Start the OpenClaw daemon
openclaw --vault ~/Studio_Master_Plan/ --daemon

# Verify status
openclaw status
```

## Daily Workflow

### Morning: Check Status (2 minutes)

```bash
# See what's in the backlog
openclaw backlog

# Output:
# Pending: 5 tickets
# In Progress: 2 tickets
# Blocked: 1 ticket
# Completed (today): 0 tickets
```

### Create a New Ticket (3 minutes)

1. **Open Obsidian** and navigate to `05_Execution_Flow_and_Tickets/`

2. **Create new file** using template:

```markdown
---
title: Implement player inventory system
type: feature
layer: execution
status: pending
autonomy: L2
tags: [feature, gameplay, inventory]
depends_on: [[Player_Controller_Spec]]
used_by: []
---

# Implement Player Inventory System

## Description
Add a basic inventory system that allows players to collect and manage items.

## Acceptance Criteria
- [ ] Inventory UI displays 20 slots
- [ ] Items can be picked up from world
- [ ] Items can be dropped
- [ ] Inventory persists between scenes
- [ ] Unit tests for inventory logic

## Constraints
- Max cost: $5.00
- Max time: 4 hours
- Target autonomy: L2

## Notes
Use existing UI framework from HUD system.
```

3. **Save file** as `TICKET-2024-001-Inventory-System.md`

### Let OpenClaw Work (Automatic)

OpenClaw automatically:
1. Detects new tickets
2. Parses requirements
3. Routes to appropriate agent
4. Generates code
5. Runs gates
6. Reports results

### Check Results (2 minutes)

```bash
# Check ticket status
openclaw status TICKET-2024-001

# Output:
# Ticket: TICKET-2024-001
# Status: completed
# Duration: 2h 15m
# Cost: $0.042
# Gates: build ✓ lint ✓ tests ✓ perf ✓
```

### Review and Merge (5 minutes)

1. **Review the PR** in your Git client
2. **Check test results** in CI
3. **Approve and merge** if satisfied

## Common Commands

```bash
# Check system health
openclaw health

# View metrics dashboard
openclaw metrics

# Pause autonomous operation
openclaw pause

# Resume operation
openclaw resume

# Force safe mode
openclaw safe-mode

# View logs
openclaw logs --tail 100

# Check cost today
openclaw costs --today

# List active agents
openclaw agents

# Cancel a ticket
openclaw cancel TICKET-2024-001
```

## Ticket Lifecycle States

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ PENDING │───▶│ PARSING │───▶│ ACTIVE  │───▶│  GATES  │───▶│COMPLETED│
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │                                              │
     │                                         ┌────┴────┐
     │                                         ▼         ▼
     │                                    ┌─────────┐ ┌─────────┐
     │                                    │  RETRY  │ │  FAILED │
     │                                    └────┬────┘ └────┬────┘
     │                                         │           │
     └─────────────────────────────────────────┴───────────┘
```

## Escalation Triggers

OpenClaw automatically escalates to human when:

| Trigger | Action Required |
|---------|-----------------|
| Cost exceeds $5/ticket | Approve or cancel |
| Gate fails 3x | Review and decide |
| Confidence < 0.5 | Provide guidance |
| Ambiguous requirements | Clarify intent |
| Security scan alert | Manual review |

## Cost Monitoring

```bash
# Daily cost report
openclaw costs --today
# Output: $12.45 / $50.00 budget

# Weekly report
openclaw costs --week
# Output: $67.23 / $350.00 budget

# Per-ticket costs
openclaw costs --ticket TICKET-2024-001
# Output: $0.042 (tokens: 15,000)
```

## Troubleshooting

### OpenClaw won't start
```bash
# Check vault path
openclaw --vault ~/Studio_Master_Plan/ status

# Check permissions
ls -la ~/Studio_Master_Plan/

# Reset state
openclaw reset --soft
```

### Ticket stuck in parsing
```bash
# Check ticket format
openclaw validate TICKET-2024-001

# View parse errors
openclaw logs --ticket TICKET-2024-001
```

### Gate keeps failing
```bash
# View gate details
openclaw gates --ticket TICKET-2024-001

# Run gates manually
openclaw gates --run --ticket TICKET-2024-001
```

## Best Practices

1. **Start with L2 autonomy** - Good balance of speed and safety
2. **Write clear acceptance criteria** - Reduces rework
3. **Reference existing specs** - Improves context
4. **Set cost limits** - Prevents runaway spending
5. **Review daily** - Catch issues early
6. **Use tags** - Improves organization
7. **Link dependencies** - Enables proper sequencing

## Next Steps

- Read [[Studio_OS_Overview]] for full system understanding
- Review [[Quality_Gates_Overview]] for quality standards
- Check [[Economic_Model_Overview]] for cost optimization
- See [[Agent_Command_Flow]] for detailed execution flow
