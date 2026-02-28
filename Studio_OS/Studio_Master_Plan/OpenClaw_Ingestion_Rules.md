---
title: OpenClaw_Ingestion_Rules
type: rule
layer: enforcement
status: active
tags:
  - openclaw
  - context
  - cost-control
depends_on: []
used_by:
  - "[Autonomous_Execution_Loop]"
---

# OpenClaw Ingestion Rules

## Purpose

Prevent context bloat, token waste, and architectural drift by strictly limiting what OpenClaw may ingest per ticket.

## Core Rules

1. OpenClaw MUST NOT ingest the entire vault.
2. OpenClaw MUST ingest only:
   - [[System_Map]]
   - [[Invariants]]
   - [[Conventions]]
3. OpenClaw MAY ingest:
   - 1–3 relevant system notes (selected by tag or explicit mention)
   - Only allowlisted code files specified in the ticket
4. Historical tickets are NEVER included.
5. Diff-only review is preferred over full file ingestion when possible.

## Interfaces

Inputs:
- Ticket
- File allowlist
- System tags

Outputs:
- Context pack folder
- Context summary

## Failure Modes

- Token explosion
- Over-generalized changes
- Cross-system corruption
- Cost spike

## Enforcement

- Context pack builder script enforces file allowlist.
- Max file count: 10.
- Max total context size: configurable ceiling.
- Escalate if required context exceeds limits.