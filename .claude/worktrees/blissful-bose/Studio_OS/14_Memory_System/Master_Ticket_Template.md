---
title: "Master Ticket Template"
type: template
layer: memory
status: template
domain: studio_os
tags:
  - template
  - ticket
---

# Master Ticket Template

Use this format for all new task tickets in `Active_Tickets/`.

---

## Copy Below This Line for New Tickets

---

title: "[Brief Task Title]"
type: task
layer: memory
status: active
domain: studio_os
tags:
  - active
  - [relevant_tags]
---

# TASK-[YYYY-MM-DD-NNN]: [Task Title]

**Created:** [Date]  
**Status:** 🔵 Active / 🟡 In Progress / 🟢 Completed / 🔴 Blocked  
**Executor:** Kimi 2.5 / Codex / Claude / Manual  
**Estimated Cost:** $0.XX  
**Actual Cost:** $X.XX (filled at completion)

---

## 1. Task Interpretation

### Original Request
[What you asked for]

### My Understanding
[My interpretation of what needs to be done]

### Scope Boundaries
- **In scope:** [What I'll do]
- **Out of scope:** [What I won't do]
- **Questions:** [Anything unclear]

---

## 2. Complexity Assessment & Executor Selection

| Factor | Score | Notes |
|--------|-------|-------|
| Files touched | X/10 | [Which files] |
| Risk level | Low/Med/High | [Why] |
| Determinism impact | None/Low/High | [Why] |
| Novelty | New/Pattern/Copy | [Similar to...] |

**Overall Complexity:** Simple / Medium / Complex / Architectural

### Executor Selection

**Recommended:** Kimi 2.5 / Agent Swarm / Deep Research / Codex / Claude Code / Manual

**Rationale:** [Why this executor]

| Option | Time | Efficiency | Best For |
|--------|------|------------|----------|
| Kimi 2.5 | X min | High | Blueprints, local work |
| Agent Swarm | X min | Very High | 20+ files |
| Deep Research | X min | High | Novel domains |
| Codex | X min | High | Refactoring |
| Claude Code | X min | High | Architecture |

**External Executor:** Yes / No  
*If Yes: Handoff packet prepared in `tools/context_packs/`*  
*See: [[Economics_Strategy|Full Strategy Guide]]*

---

## 3. Proposed Approach

### Strategy
[High-level approach]

### Rationale
[Why this approach vs alternatives]

### Alternatives Considered
1. [Option A] - Rejected because...
2. [Option B] - Rejected because...

---

## 4. Execution Checklist

### Phase 1: Setup
- [ ] Requirements clarified
- [ ] Files identified
- [ ] Tests identified (if applicable)
- [ ] Dependencies checked

### Phase 2: Implementation
- [ ] [Step 1]
- [ ] [Step 2]
- [ ] [Step 3]
- [ ] ...

### Phase 3: Validation
- [ ] Local tests pass
- [ ] Vault validation passes
- [ ] Determinism check (if applicable)
- [ ] Manual review complete

### Phase 4: Documentation & Dashboard
- [ ] Code comments added
- [ ] Memory updated (if needed)
- [ ] **Dashboard.html updated** (progress, tasks, next up)
- [ ] Ticket completion notes

---

## 5. Issues & Solutions

| Time | Issue | Solution | Solution ID |
|------|-------|----------|-------------|
| [HH:MM] | [Description] | [How fixed] | [SOLV-XXX or NEW] |

*If new solution: Create `Solutions_Learned/SOLV-XXX_description.md`*

---

## 6. External Executor Notes

*Fill if recommending Codex/Claude*

### Handoff Packet Location
`tools/context_packs/[TASK-ID]/`

### Context Files
- [File 1]
- [File 2]

### Key Constraints
- [Constraint 1]
- [Constraint 2]

### Expected Output
[What the external executor should produce]

### Integration Steps
[How to integrate their output back]

---

## 7. Completion Log

**Completed:** [Date]  
**Duration:** [Time elapsed]  
**Final Cost:** $X.XX

### What Was Done
[Summary of actual work completed]

### Changes from Original Plan
[If scope changed, why]

### Lessons Learned
[For future reference]

### Related Solutions
- [[Solutions_Learned/SOLV-XXX|Solution Name]]

---

## 8. Review Checkpoints

*You review here and give adjustments*

### Checkpoint 1: Initial Blueprint
**Your feedback:**
- [ ] Looks good, commit
- [ ] Adjust: [specific changes]

### Checkpoint 2: Mid-execution (if long)
**Your feedback:**
- [ ] Continue as planned
- [ ] Pivot: [specific changes]

### Checkpoint 3: Pre-completion
**Your feedback:**
- [ ] Complete and close
- [ ] Needs: [specific additions]

---

## Quick Commands

```
You say: "Commit to ticket TASK-XXXX"
→ I execute checklist

You say: "Adjust [specific]"
→ I update blueprint

You say: "Check solutions for [problem]"
→ I search Solutions_Learned/

You say: "Move to completed"
→ I finalize and archive
```
