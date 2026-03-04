---
title: AI-Native Game Studio OS - Workflow Implementation
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

# Agent Workflow Implementation Summary

## Directory Structure

```
ironcore-work/
├── agents/
│   ├── TICKET_TEMPLATE.md
│   ├── context/
│   │   ├── invariants.md
│   │   ├── project_summary.md
│   │   └── conventions.md
│   ├── tickets/                    # Ticket definitions (YAML frontmatter)
│   │   ├── TICKET-0001.md
│   │   └── ...
│   ├── runs/                       # Per-ticket run outputs
│   │   └── <TICKET-ID>/
│   │       ├── ROUTE.json
│   │       ├── REPORT.md
│   │       ├── logs/
│   │       └── handoff/            # External executor path only
│   └── audits/                     # Audit reports by date
│       └── <YYYY-MM-DD>/
│           ├── AUDIT_REPORT.md
│           └── METRICS.json
├── tools/
│   ├── studio_run.ps1              # One-command pipeline (Windows)
│   ├── studio_run.sh               # One-command pipeline (Mac/Linux)
│   ├── validate_vault.py           # Vault frontmatter validation
│   ├── validate_configs.py         # Risk/budget config validation
│   ├── route_ticket.py             # Routing decision -> ROUTE.json
│   ├── build_context_pack.py       # Context pack builder
│   ├── require_context_pack.py     # Pack existence gate
│   ├── verify_manifest.py          # Schema + SHA-256 integrity check
│   ├── run_ticket.py               # Ticket execution orchestrator
│   ├── build_handoff_packet.py     # External executor handoff
│   ├── studio_audit.py             # Drift detection + auto-tickets
│   ├── dev_gate.ps1                # Dev gate (Windows)
│   ├── dev_gate.sh                 # Dev gate (Mac/Linux)
│   ├── schemas/
│   │   └── manifest.schema.json    # JSON Schema for manifest.json
│   ├── config/
│   │   ├── risk_config.default.json
│   │   └── budget_config.default.json
│   ├── context_packs/              # Built context packs (runtime)
│   │   └── <TICKET-ID>/
│   │       ├── manifest.json
│   │       ├── allowed_files/
│   │       └── vault_notes/
│   └── studio_audit_config.json    # Audit thresholds
└── Studio_OS/                      # Obsidian vault (READ-ONLY for pipeline)
```

## One-Command Pipeline

### Usage

```bash
# Windows (PowerShell)
.\tools\studio_run.ps1 -Ticket agents\tickets\TICKET-0001.md

# Mac/Linux/Git Bash
./tools/studio_run.sh agents/tickets/TICKET-0001.md
```

### Pipeline Steps

| Step | Tool | Purpose | Exit codes |
|------|------|---------|------------|
| 1 | `validate_vault.py` | YAML frontmatter on all Studio_OS/ files | 0=ok, 1=no vault, 2=errors |
| 2 | `validate_configs.py` | Risk thresholds monotonic, budget sums to 1.0 | 0=ok, 1=file error, 2=invalid |
| 3 | `route_ticket.py` | Decide executor, write ROUTE.json | 0=ok, 1=parse error |
| 4 | `build_context_pack.py` | Build allowlist + vault notes pack | 0-4 |
| 5 | `require_context_pack.py` | Assert pack exists with valid manifest | 0-3 |
| 6 | `verify_manifest.py` | Schema validation + SHA-256 hash check | 0-3 |
| 7 | `run_ticket.py` | Execute ticket (full orchestrator) | 0=ok/waiting, 1=parse, 2+=step fail |
| 8 | `dev_gate` | Vault validation (Godot stages skipped) | 0=ok, 1=stage fail, 2=vault fail |
| 9 | `studio_audit.py` | Drift detection, auto-ticket generation | 0=clean, 1=config, 2=drift, 3=infra |

Any failure stops the pipeline with the failing step's exit code.

### Execution Paths

**Local path** (executor=local): All steps run sequentially. `run_ticket.py` invokes route -> pack -> verify -> dev_gate internally.

**External path** (executor=claude|codex|manual): Steps 1-6 run, then `run_ticket.py` builds a handoff packet at `agents/runs/<ID>/handoff/` and exits with status `WAITING_FOR_EXTERNAL_EXECUTOR`.

## Manifest Format

Context pack manifests (`tools/context_packs/<ID>/manifest.json`) are validated against `tools/schemas/manifest.schema.json`.

```json
{
  "ticket_id": "TICKET-0001",
  "allowed_file_count": 2,
  "vault_note_count": 1,
  "max_allowed": 10,
  "hash_algorithm": "sha256",
  "files": {
    "ticket.md": "sha256:abc123...",
    "allowed_files/project/foo.gd": "sha256:def456..."
  }
}
```

All hashes use the format `sha256:<64 hex chars>`. The `hash_algorithm` field is always `"sha256"`.

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

## Config Validation

**Risk config** (`tools/config/risk_config.default.json`):
- Thresholds must be monotonic: `low <= medium <= high <= critical <= 100`
- All four levels required

**Budget config** (`tools/config/budget_config.default.json`):
- Allocations must sum to `1.0 +/- 0.001`
- Values must be in `[0.0, 1.0]`

## Key Constraints

1. **Studio_OS/ is READ-ONLY** - Never write to the vault via pipeline
2. **File allowlist** - Max 10 files per ticket (enforced in build_context_pack.py)
3. **Notes are vault-relative** - Paths under `Studio_OS/`, not repo root
4. **Hash consistency** - All digests use `sha256:` prefix format
5. **Timestamps are metadata** - `generated_at` fields record operational timing but do not affect deterministic replay
6. **Gate required** - Every ticket must pass dev_gate before completion
7. **Determinism preserved** - 60Hz sim, seeded RNG, no nondeterministic timestamps in game state

## Audit System

`python tools/studio_audit.py` runs independently (no ticket argument needed).

**Drift indicators checked:**
- `gate_failure_rate` - % of last N runs with FAILED status
- `repeated_file_modifications` - same file in 5+ distinct runs
- `vault_validation_failures` - any vault validation failure
- `missing_manifest_count` - runs without context pack manifest
- `tampered_pack_count` - packs failing SHA-256 verify_manifest check

Config: `tools/studio_audit_config.json` - all thresholds configurable.
Auto-tickets use `AUDIT-XXXX` prefix and can be run through the pipeline.
