# Agent Workflow - Quick Reference

## One-Command Pipeline

```bash
# Windows (PowerShell)
.\tools\studio_run.ps1 -Ticket agents\tickets\TICKET-0001.md

# Mac/Linux/Git Bash
./tools/studio_run.sh agents/tickets/TICKET-0001.md
```

This runs the full enforcement pipeline in order:
1. `validate_vault.py` - YAML frontmatter check on Studio_OS/
2. `validate_configs.py` - Risk/budget config validation
3. `route_ticket.py` - Decide executor, write ROUTE.json
4. `build_context_pack.py` - Build allowlist + vault notes pack
5. `require_context_pack.py` - Assert pack exists with valid manifest
6. `verify_manifest.py` - Schema validation + SHA-256 integrity check
7. `run_ticket.py` - Execute ticket (local or build handoff)
8. `dev_gate` - Vault validation (Godot skipped)
9. `studio_audit.py` - Drift detection + auto-ticket generation

Any failure stops the pipeline immediately with a non-zero exit code.

## Individual Commands

```bash
# Create context pack
python tools/build_context_pack.py agents/tickets/TICKET-XXX.md

# Verify manifest integrity
python tools/verify_manifest.py TICKET-XXX

# Route a ticket (writes ROUTE.json)
python tools/route_ticket.py --ticket agents/tickets/TICKET-XXX.md

# Run a ticket through enforcement pipeline
python tools/run_ticket.py --ticket agents/tickets/TICKET-XXX.md

# Validate configs
python tools/validate_configs.py

# Run gate (Windows)
.\tools\dev_gate.ps1 -SkipGodot

# Run gate (Mac/Linux)
./tools/dev_gate.sh --skip-godot

# Run audit
python tools/studio_audit.py
python tools/studio_audit.py --simulate-drift
```

## Ticket Lifecycle

```
1. Write ticket     -> agents/tickets/TICKET-XXX.md  (YAML frontmatter)
2. Run pipeline     -> ./tools/studio_run.sh agents/tickets/TICKET-XXX.md
3. Pipeline routes  -> agents/runs/TICKET-XXX/ROUTE.json
4. Pipeline builds  -> tools/context_packs/TICKET-XXX/manifest.json
5. Pipeline runs    -> agents/runs/TICKET-XXX/REPORT.md
6. Pipeline gates   -> vault validation + audit
7. Commit           -> git commit -m "TICKET-XXX: Description"
```

## Ticket Template (YAML Frontmatter)

```yaml
---
ticket: TICKET-XXX
title: "Clear description of work"
scope: small          # small | large | architectural
risk: low             # low | high
allowlist:
  - project/path/to/file.gd
notes:
  - 09_Quality_Gates/Dev_Gate_Validation_System.md
---

## Goal
One sentence describing what "done" looks like.

## Acceptance Criteria
- [ ] AC1: Testable condition
```

## File Locations

| Type | Path |
|------|------|
| Tickets | `agents/tickets/` |
| Context | `agents/context/` |
| Context Packs | `tools/context_packs/<ticket>/` |
| Run Reports | `agents/runs/<ticket>/` |
| Audit Reports | `agents/audits/<date>/` |
| Schemas | `tools/schemas/` |
| Configs | `tools/config/` |
| Gate Scripts | `tools/dev_gate.*` |
| Pipeline Scripts | `tools/studio_run.*` |

## Routing Rules (Priority Order)

1. `executor:` field in frontmatter (explicit override)
2. `manual: true` -> manual
3. `needs_codex: true` -> codex
4. `needs_external_llm: true` -> claude
5. `scope: large|architectural` -> claude
6. `risk: high` -> claude
7. Tags in EXTERNAL_TAGS set -> claude
8. `len(allowlist) > 5` -> claude
9. Default -> local

## Hash Format

All integrity hashes use the format `sha256:<64 hex chars>`.
The manifest schema enforces this pattern.

## Common Issues

**Pipeline fails at validate_vault**
-> Fix YAML frontmatter errors in Studio_OS/ files

**Pipeline fails at verify_manifest**
-> Context pack was modified outside the pipeline. Rebuild: `python tools/build_context_pack.py <ticket.md>`

**Pipeline fails at dev_gate (Godot not found)**
-> Use `-SkipGodot` flag or add Godot to PATH

**Config validation fails**
-> Check `tools/config/risk_config.default.json` and `budget_config.default.json`
