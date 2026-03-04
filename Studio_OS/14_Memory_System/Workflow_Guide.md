---
title: "Memory System Workflow"
type: guide
layer: memory
status: active
domain: studio_os
tags:
  - guide
  - workflow
  - memory
---

# Memory System Workflow

How to use the 14_Memory_System for efficient, cost-effective collaboration.

---

## Overview

**You** ↔ **Me (Kimi 2.5)** ↔ **External Executors (Codex/Claude)**

I bridge the gap by:
1. Creating detailed blueprints (cheap)
2. Doing local work (cheap)
3. Handing off complex work to you for external execution (controlled cost)

**Result:** 60-90% cost savings + full traceability

---

## The Workflow

### Step 1: You Give Me a Large Task

**You say:**
> "I need a save/load system with encryption, cloud sync, and conflict resolution."

---

### Step 2: I Create a Blueprint

**I do:**
1. Analyze the request
2. Check Solutions_Learned/ for prior art
3. Assess complexity
4. Create ticket in `14_Memory_System/Active_Tickets/`

**Ticket contains:**
- My interpretation of the task
- Proposed approach
- Complexity assessment
- Cost estimate
- Execution checklist
- External executor recommendation (if needed)

**I tell you:**
> "I've created TASK-2026-03-02-001 with my blueprint. Review it and let me know if you want adjustments."

---

### Step 3: You Review & Adjust

**You read the ticket** in Obsidian or I show you.

**You might say:**
- "Looks good, commit" → Go to Step 4
- "Adjust: use AES-256 instead of AES-128" → I update, you review again
- "Remove cloud sync for now" → I update scope
- "Add compression requirement" → I add to checklist

**Cost so far:** ~$0.01-0.05 (my time only)

---

### Step 4: You Say "Commit"

**You say:**
> "Commit to ticket TASK-2026-03-02-001"

**I execute:**

#### If LOCAL execution:
1. Start working through checklist
2. Mark items complete in real-time
3. Log any issues to Solutions_Learned/
4. Reference prior solutions when relevant
5. Update ticket with progress
6. Complete all checklist items

#### If EXTERNAL execution:
1. Prepare handoff packet
2. Give you:
   - Context files list
   - Key constraints
   - Expected output format
   - Integration instructions
3. You run it manually with Codex/Claude Code
4. You give me the output
5. I integrate and validate
6. I complete the ticket

---

### Step 5: Completion

**When done:**
- Ticket moves to `Completed_Tickets/`
- Full execution log preserved
- Actual costs recorded
- Lessons learned documented
- Solutions linked

**I tell you:**
> "TASK-2026-03-02-001 complete. Duration: 2 hours. Cost: $0.23 (local) + $1.50 (your Codex run). Total: $1.73. Solutions SOLV-003 and SOLV-007 referenced."

---

## Cost Comparison

### Traditional Full-Auto (before)
| Phase | Executor | Cost |
|-------|----------|------|
| Planning | Claude | $0.50 |
| Execution | Claude | $2.00 |
| Validation | Claude | $0.50 |
| **Total** | | **$3.00** |

### New Hybrid Model (now)
| Phase | Executor | Cost |
|-------|----------|------|
| Blueprint | Kimi 2.5 (me) | $0.03 |
| Review | You | $0 |
| Local work | Kimi 2.5 (me) | $0.20 |
| Complex part | Your Codex | $1.00 |
| **Total** | | **$1.23** |

**Savings: 59%**

For tasks with no complex parts (all local):
| Phase | Cost |
|-------|------|
| Blueprint | $0.03 |
| Execution | $0.20 |
| **Total** | **$0.23** |

**Savings vs full-auto: 92%**

---

## Commands You Can Use

### Starting Work
```
"I need [task description]"
→ I create blueprint ticket

"Check solutions for [problem]"
→ I search Solutions_Learned/

"Show me active tickets"
→ I list Active_Tickets/
```

### During Review
```
"Commit to ticket [ID]"
→ I start execution

"Adjust: [specific change]"
→ I update ticket

"Pause ticket [ID]"
→ I stop, document state

"Cancel ticket [ID]"
→ I archive with notes
```

### During Execution
```
"Status update"
→ I show checklist progress

"Hit a blocker: [description]"
→ I search solutions or create new one

"This needs Codex"
→ I prepare handoff packet
```

### At Completion
```
"Mark [ID] complete"
→ I finalize ticket

"What did we learn?"
→ I summarize solutions used

"Similar to [past task]?"
→ I reference prior completed tickets
```

---

## When to Use External Executors

### Use LOCAL (me) when:
- File changes < 5 files
- No simulation core touched
- Pattern is familiar
- Risk score < 50
- Budget is tight

### Use EXTERNAL (Codex/Claude) when:
- Complex algorithms needed
- Novel problem space
- >10 files affected
- Simulation core at risk
- Determinism concerns
- You want to double-check my work

### Use MANUAL (you) when:
- Security-critical code
- Architectural decisions
- Cost doesn't matter
- You want hands-on

---

## Memory System Benefits

### For You
1. **Visibility** - See exactly what I plan to do before I do it
2. **Control** - Adjust scope, approach, constraints
3. **Cost Control** - Choose when to spend on external executors
4. **History** - Look back at how problems were solved
5. **Continuity** - Task context survives chat sessions

### For Me
1. **Clarity** - Forced to think before acting
2. **Learning** - Solutions database improves over time
3. **Efficiency** - Reference prior work instead of re-solving
4. **Accountability** - Complete log of decisions

### For the Project
1. **Knowledge Base** - Institutional memory in Obsidian
2. **Onboarding** - New team members see how things work
3. **Audit Trail** - Full history of changes
4. **Pattern Recognition** - See what approaches work

---

## Quick Start Example

### You:
> "Build a headless match runner that can run 1000 battles and output balance statistics."

### Me (creates TASK-2026-03-02-001):
```yaml
title: "Headless Match Runner with Balance Stats"
# ... frontmatter ...
```

### Content:
**Task Interpretation:**
- Create tool to run 1000 battles without UI
- Collect metrics: win rates, TTK, damage dealt
- Output JSON/CSV for analysis

**Complexity Assessment:**
- Files touched: 3 (new files)
- Risk: Low (isolated tool)
- Determinism: Must maintain
- **Recommendation: Local execution (me)**

**Checklist:**
- [ ] Design BattleBatchConfig class
- [ ] Implement HeadlessBattleRunner
- [ ] Create BattleMetrics collector
- [ ] Add JSON/CSV export
- [ ] Test with 10 battles
- [ ] Scale test with 100 battles
- [ ] Full 1000 battle run
- [ ] Validate determinism

**Estimated Cost:** $0.15 (all local)

### You:
> "Looks good, but add HTML report output too. And commit."

### Me:
- Update checklist: add HTML export
- Start execution
- Mark items complete in real-time
- Complete in ~1 hour
- Move to Completed_Tickets/

### Final:
- **Actual Cost:** $0.12
- **Solutions Used:** None (new work)
- **Solutions Created:** SOLV-002_headless_runner_setup

---

## File Locations

| Type | Path |
|------|------|
| This Guide | `14_Memory_System/` |
| Active Work | `14_Memory_System/Active_Tickets/` |
| Completed | `14_Memory_System/Completed_Tickets/` |
| Solutions | `14_Memory_System/Solutions_Learned/` |
| Daily Logs | `14_Memory_System/Daily_Logs/` |
| Templates | `14_Memory_System/*_Template.md` |

---

Ready to start? Give me a large task and I'll create the first blueprint!
