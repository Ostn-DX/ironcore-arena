---
title: How to Run OpenClaw With This Vault
type: template
layer: execution
status: active
tags:
  - how-to
  - run
  - openclaw
  - operations
  - daily-use
depends_on:
  - "[Quickstart_OpenClaw]]"
  - "[[Studio_OS_in_10_Rules]]"
  - "[[OpenClaw_Daily_Work_Loop]"
used_by:
  - "[30_Day_Enablement_Plan]"
---

# How to Run OpenClaw With This Vault

## Daily Operation Checklist

### Morning Routine (5 minutes)

```bash
# 1. Check system health
$ openclaw health
✓ Vault accessible
✓ Local LLM responding
✓ Git repository synced
✓ All gates operational

# 2. Review backlog
$ openclaw backlog
Pending: 5 tickets
In Progress: 2 tickets
Blocked: 0 tickets
Completed (today): 0 tickets

# 3. Check costs
$ openclaw costs --today
$8.42 / $50.00 daily budget (16.8%)
```

### Creating Work (10 minutes)

#### Step 1: Write Intent in Obsidian

1. Open Obsidian
2. Navigate to `05_Execution_Flow_and_Tickets/`
3. Create new file: `TICKET-[YYYY]-[NNN]-[description].md`
4. Use template:

```markdown
---
title: Add save/load system
type: feature
layer: execution
status: pending
autonomy: L2
tags: [feature, systems, save-game]
depends_on: [[Player_Data_Spec]]
used_by: []
---

# Add Save/Load System

## Description
Implement a save/load system that persists player progress.

## Acceptance Criteria
- [ ] Game state can be saved to disk
- [ ] Game state can be loaded from disk
- [ ] Save files are versioned
- [ ] Corrupted saves are handled gracefully
- [ ] Unit tests for save/load logic

## Constraints
- Max cost: $10.00
- Max time: 8 hours
- Target autonomy: L2

## Notes
Use JSON format for save files. Consider encryption for production.
```

#### Step 2: Save and Let OpenClaw Detect

Save the file. OpenClaw automatically:
1. Detects new ticket (within 30 seconds)
2. Parses YAML frontmatter
3. Validates format
4. Adds to backlog

#### Step 3: Verify Detection

```bash
$ openclaw status TICKET-2024-042
Ticket: TICKET-2024-042
Status: pending
Detected: 2024-01-15T09:15:00Z
Autonomy: L2
Estimated cost: $0.85
```

### Monitoring Execution (As Needed)

#### Check Active Work

```bash
# See what's running
$ openclaw active
TICKET-2024-041: Implementing (45 min elapsed)
TICKET-2024-040: Testing (12 min elapsed)
```

#### Watch Progress

```bash
# Real-time logs
$ openclaw logs --ticket TICKET-2024-042 --follow
[09:15:30] Ticket parsed successfully
[09:15:35] Context pack built (15 files, 45KB)
[09:15:40] Routed to local-medium model
[09:16:15] Code generation complete
[09:16:20] Running build gate...
[09:17:05] Build gate passed
[09:17:10] Running unit tests gate...
```

#### Intervene if Needed

```bash
# Check if intervention needed
$ openclaw status TICKET-2024-042
Status: awaiting_decision
Reason: gate_failed_3x
Options: [retry, escalate, cancel]

# Escalate to human
$ openclaw escalate TICKET-2024-042 --reason "complex_issue"

# Or cancel
$ openclaw cancel TICKET-2024-042 --reason "requirements_changed"
```

### Reviewing Results (10 minutes)

#### When Ticket Completes

```bash
$ openclaw status TICKET-2024-042
Status: completed
Duration: 2h 15m
Cost: $0.042
Gates: build ✓ lint ✓ tests ✓ perf ✓
Files changed: 5
Tests added: 8
```

#### Review the PR

1. Open your Git client
2. Find PR for TICKET-2024-042
3. Review changes:
   - Code quality
   - Test coverage
   - Acceptance criteria met

#### Approve or Request Changes

```bash
# Approve (if L2-L3, auto-merges)
$ openclaw approve TICKET-2024-042

# Request changes
$ openclaw revise TICKET-2024-042 --feedback "Add error handling for corrupted saves"
```

### Evening Wrap-Up (5 minutes)

```bash
# Daily summary
$ openclaw summary --today
Tickets completed: 3
Tickets failed: 1 (TICKET-2024-038 - escalated)
Total cost: $12.45
Avg cycle time: 1h 45m

# Check tomorrow's queue
$ openclaw backlog --pending
5 tickets ready for tomorrow

# Sync everything
$ openclaw sync
Vault synced to git
```

## Weekly Operations

### Monday: Planning (30 minutes)

```bash
# Last week's metrics
$ openclaw metrics --week
Tickets: 15 completed, 2 failed
Cost: $67.23 / $350 budget
Gate pass rate: 88%
Avg cycle time: 2h 12m

# Review failed tickets
$ openclaw list --status failed
TICKET-2024-038: Complex threading issue
TICKET-2024-029: Performance regression

# Plan this week
# (In Obsidian, update ticket priorities)
```

### Friday: Retrospective (30 minutes)

```bash
# Full week report
$ openclaw report --week

# Export for team review
$ openclaw export --format markdown --output weekly_report.md
```

## Emergency Procedures

### Stop Everything

```bash
# Emergency pause
$ openclaw pause --emergency
All operations paused.
Active tickets: 2 (will complete current step)
```

### Resume

```bash
# Resume operation
$ openclaw resume
Operations resumed.
```

### Rollback

```bash
# Rollback a ticket
$ openclaw rollback TICKET-2024-042
Rolling back to pre-ticket state...
✓ Changes reverted
✓ Branch cleaned
```

### Cost Emergency

```bash
# Check current spend
$ openclaw costs --today
$48.50 / $50.00 (97%)

# Pause to prevent overrun
$ openclaw pause --reason "budget-protection"

# Review spending
$ openclaw costs --analysis
Top costs:
  - TICKET-2024-040: $15.23 (frontier model)
  - TICKET-2024-039: $8.45 (multiple retries)
```

## Advanced Operations

### Batch Operations

```bash
# Create multiple tickets from spec
$ openclaw decompose SPEC-2024-001
Decomposed into 5 tickets:
  - TICKET-2024-050
  - TICKET-2024-051
  - TICKET-2024-052
  - TICKET-2024-053
  - TICKET-2024-054

# Run gates on all pending tickets
$ openclaw gates --all-pending
```

### Configuration Changes

```bash
# View current config
$ openclaw config
autonomy: L2
max_cost_per_ticket: 5.00
max_cost_per_day: 50.00
default_model: local-medium

# Update config
$ openclaw config --autonomy L3
Autonomy level updated to L3

# Reset to defaults
$ openclaw config --reset
```

### Debugging

```bash
# Verbose logging
$ openclaw logs --ticket TICKET-2024-042 --verbose

# Check agent decisions
$ openclaw debug --ticket TICKET-2024-042 --show-routing

# Replay execution
$ openclaw replay TICKET-2024-042
```

## Integration with Obsidian

### Daily Notes

Create a daily note in Obsidian:

```markdown
# 2024-01-15

## Tickets Created
- [[TICKET-2024-042]] - Save/load system

## Tickets Completed
- [[TICKET-2024-039]] - UI polish (cost: $0.034)

## Blockers
- None

## Notes
OpenClaw running smoothly at L2 autonomy.
```

### Linking Tickets

Use wiki-links to connect related work:

```markdown
---
title: Add save button to pause menu
depends_on: [[TICKET-2024-042]]  # Save/load system
---
```

## Troubleshooting

### OpenClaw Won't Start

```bash
# Check vault path
$ openclaw --vault ~/Studio_Master_Plan/ status
Error: Vault not found at path

# Verify path
$ ls ~/Studio_Master_Plan/
00_Master_Index/  01_Studio_Strategy/ ...

# Fix path
$ openclaw config --vault-path /correct/path/
```

### Ticket Not Detected

```bash
# Validate ticket format
$ openclaw validate TICKET-2024-042
Error: Invalid YAML frontmatter
Line 5: Missing 'status' field

# Fix and retry
```

### Gates Failing Repeatedly

```bash
# Run gates manually to debug
$ openclaw gates --run --ticket TICKET-2024-042
Build gate: FAILED
  Error: Undefined variable 'player_data'

# Fix issue, then retry
$ openclaw retry TICKET-2024-042
```

## Best Practices

1. **Start each day with health check** - Catch issues early
2. **Write clear acceptance criteria** - Reduces rework
3. **Set appropriate autonomy** - L2 is good default
4. **Monitor costs daily** - Prevent surprises
5. **Review completed work** - Learn and improve
6. **Use tags consistently** - Better organization
7. **Link dependencies** - Proper sequencing
8. **Keep tickets atomic** - Easier to review
9. **Document blockers** - Helps team coordination
10. **Weekly retrospectives** - Continuous improvement

---

*This guide covers daily operation. For setup, see [[Quickstart_OpenClaw]].*
