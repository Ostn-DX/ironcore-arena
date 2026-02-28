---
title: Model_Routing_Decision_Tree
type: decision
layer: execution
status: active
tags:
  - models
  - routing
  - cost-control
depends_on: []
used_by:
  - "[Autonomous_Execution_Loop]"
---

# Model Routing Decision Tree (Option C Hybrid)

## Purpose

Ensure controlled use of subscriptions while preserving autonomy and cost containment.

## Default Model

Small feature (< 2 files):
→ Kimi 2.5 Code

Medium feature (cross-module, < 5 files):
→ Kimi 2.5 Code
→ If 2 failed repair attempts → Claude Code

Large architectural change:
→ Claude Code (single pass review)
→ Return to Kimi for implementation

Deep research:
→ Research model only
→ Output must be structured, not narrative

UI interpretation:
→ Vision-capable model (manual trigger only)

Art / Audio:
→ Local-first
→ Paid model only if local quality fails twice

## Cost Controls

- Max retries per model: 3
- Max model escalations per ticket: 1
- Paid model invocation must log usage

## Escalation

If:
- Architectural invariant conflict
- Determinism failure persists
- Cross-system drift detected

→ Escalate to human