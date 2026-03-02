---
title: AI-Native Game Studio OS - Quick Start
type: guide
layer: operations
status: active
domain: studio_os
tags:
  - guide
  - operations
  - studio_os
depends_on: []
used_by: []
---

# AI-Native Game Studio OS - Quick Reference

## What Is This?

A self-governing system for orchestrating AI agents in game development. It routes tasks to the right AI (Claude, Codex, Local LLM), manages costs, enforces quality gates, and maintains determinism.

## Quick Start

```bash
# Run a ticket through the pipeline
cd ironcore-work
python3 tools/run_ticket.py --ticket agents/tickets/TICKET-0001.md

# Or use the one-command wrapper
./tools/studio_run.sh agents/tickets/TICKET-0001.md
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `python3 tools/validate_vault.py` | Check Studio_OS/ integrity |
| `python3 tools/validate_configs.py` | Validate risk/budget configs |
| `python3 tools/route_ticket.py --ticket <file>` | Decide which AI to use |
| `python3 tools/build_context_pack.py <ticket>` | Build context for AI |
| `python3 tools/run_ticket.py --ticket <file>` | Full pipeline execution |
| `python3 tools/studio_audit.py` | Detect drift & auto-generate tickets |

## Project Structure

```
ironcore-work/
├── agents/tickets/        # Work tickets
├── agents/runs/           # Execution outputs
├── tools/                 # Pipeline scripts
├── Studio_OS/            # Obsidian vault (docs)
├── ANALYTICS/            # Cost/performance models
├── VAULT/                # System reference
└── project/              # Godot game project
```

## Documentation

| File | Purpose |
|------|---------|
| `IMPLEMENTATION_COMPLETE.md` | Full system documentation |
| `MASTER_BLUEPRINT.md` | Architecture specification |
| `WORKFLOW_IMPLEMENTATION.md` | Developer guide |
| `TROUBLESHOOTING_MANUAL.md` | Problem solving |
| `AGENT_SWARM_INTEGRATION_COMPLETE.md` | Game feature integration |

## Status

✅ **OPERATIONAL** - All 20 domains integrated, pipeline tested, audit system active.
