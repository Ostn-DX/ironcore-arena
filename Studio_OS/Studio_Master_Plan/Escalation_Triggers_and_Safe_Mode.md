---
title: Escalation_Triggers_and_Safe_Mode
type: rule
layer: enforcement
status: active
tags:
  - escalation
  - safety
  - autonomy
depends_on:
  - "[Autonomous_Execution_Loop]"
used_by: []
---

# Escalation Triggers and Safe Mode

## Purpose

Prevent uncontrolled execution and protect system integrity.

## Escalation Triggers

1. 3 failed repair attempts
2. Determinism gate failure persists
3. File modification outside allowlist
4. Token/cost ceiling exceeded
5. Architectural invariant violation

## Safe Mode Behavior

When triggered:

- No architectural refactors allowed
- No cross-system changes
- Only bug-level patches permitted
- Human review required before exiting Safe Mode

## Escalation Report Must Include

- Ticket summary
- Files modified
- Gate output logs
- Retry history
- Model usage summary
- Suspected root cause

## Enforcement

- Safe Mode flag persisted in repo
- Must be manually cleared