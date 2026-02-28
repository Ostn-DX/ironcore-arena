---
title: Autonomy_Ladder_L0_to_L5
type: system
layer: architecture
status: active
tags:
  - autonomy
  - levels
  - ladder
  - progression
depends_on: []
used_by:
  - "[Autonomy_Scoring_Rubric]"
---

# Autonomy Ladder L0 to L5

## Purpose
Measurable progression of OpenClaw autonomy in game development. Current: L2. Target: L4.

## Level Definitions

### L0: Manual Only
**Description:** Every action requires explicit human command.

**Characteristics:**
- Human writes all tickets
- Human runs all tools
- Human applies all patches
- Human makes all decisions

**Use Case:** Initial setup, learning phase

---

### L1: Tool Assisted
**Description:** OpenClaw runs tools on command, human interprets.

**Characteristics:**
- OpenClaw executes: validate_vault.py, dev_gate.sh
- Human reads output
- Human decides next action
- OpenClaw never modifies code

**Use Case:** Validation, testing

**Entry Criteria:**
- [ ] All tools documented
- [ ] OpenClaw can execute shell commands
- [ ] Output parsing reliable

---

### L2: Supervised Execution (CURRENT)
**Description:** OpenClaw executes tickets with human approval gates.

**Characteristics:**
- Human creates tickets
- OpenClaw builds context packs
- OpenClaw produces output
- Human approves before integration
- Human runs gate
- Human commits

**Use Case:** Active development with safety

**Entry Criteria:**
- [x] Ticket system operational
- [x] Context packs working
- [x] Normalization validating
- [x] Gates passing reliably

**Exit Criteria (to L3):**
- [ ] 10 consecutive tickets integrated without human intervention
- [ ] Gate pass rate >95%
- [ ] Zero critical regressions
- [ ] Escalation rate <5%

---

### L3: Conditional Autonomy
**Description:** OpenClaw integrates low-risk tickets automatically, escalates others.

**Characteristics:**
- Auto-integrate: Bug fixes, documentation
- Human approval: New features, architecture
- Auto-run gate
- Auto-commit on pass
- Human reviews daily

**Use Case:** High-velocity development

**Entry Criteria:**
- [ ] Gate reliability proven
- [ ] Rollback system tested
- [ ] Cost tracking accurate
- [ ] Escalation system working

**Exit Criteria (to L4):**
- [ ] 50 tickets auto-integrated
- [ ] Zero undetected regressions
- [ ] Human review time <15 min/day
- [ ] Cost variance <20%

---

### L4: High Autonomy (TARGET)
**Description:** OpenClaw handles full development cycle, human provides direction.

**Characteristics:**
- Auto-creates tickets from goals
- Auto-routes to appropriate agents
- Auto-integrates most work
- Human: Goals, architecture, final approval
- Human: Complex debugging, creative decisions

**Use Case:** Production game studio

**Entry Criteria:**
- [ ] L3 stable for 1 month
- [ ] Self-healing loops working
- [ ] Quality metrics stable
- [ ] Budget tracking accurate

**Exit Criteria (to L5):**
- [ ] 1 month without human intervention
- [ ] Game shipped autonomously
- [ ] Player satisfaction >4 stars

---

### L5: Full Autonomy
**Description:** OpenClaw operates independently, human provides high-level intent.

**Characteristics:**
- Human: "Make a robot combat game"
- OpenClaw: Design, implement, ship
- Human: Playtest, feedback
- Human: Business decisions

**Use Case:** Future state, not current target

**Entry Criteria:**
- [ ] L4 proven for 6+ months
- [ ] Multiple successful releases
- [ ] Creative judgment validated

---

## Current Status

**Level:** L2 (Supervised Execution)
**Progress to L3:** 40%
**Blockers:**
- Need 10 consecutive successful tickets
- Need gate reliability >95%

## Level Advancement

Advancement requires:
1. All entry criteria met
2. Human approval
3. 2-week trial at new level
4. Rollback option if issues

## Regression Policy

If issues at any level:
1. Immediate fallback to previous level
2. Root cause analysis
3. Fix and retry advancement

## Related
[[Autonomy_Scoring_Rubric]]
[[Escalation_Policy]]
[[Daily_Operator_Protocol]]
