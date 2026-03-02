---
title: Context_Pack_Spec
type: template
layer: execution
status: active
tags:
  - template
  - context
  - pack
  - automation
depends_on: []
used_by:
  - "[Daily_Operator_Protocol]"
---

# Context Pack Spec

## Purpose
Minimal, deterministic context delivery to agents. Reduces token burn and improves output quality.

## Generation Command

```bash
python tools/build_context_pack.py agents/tickets/TICKET-XXX.md
```

## Output Structure

```
tools/context_packs/TICKET-XXX/
├── ticket.md                    # Full ticket
├── invariants.md               # Architectural constraints
├── conventions.md              # Code conventions
├── project_summary.md          # Project overview
├── pack_metadata.json          # Generated metadata
├── allowed_files/              # Copied from ticket allowlist
│   ├── autoload/
│   │   └── System.gd
│   └── src/
│       └── entity.gd
└── new_files/                  # Empty templates for agent to fill
    └── new_component.gd
```

## Metadata Format

```json
{
  "ticket_id": "TICKET-001",
  "title": "Implement tactical AI",
  "estimated_cost": "$5.00",
  "model_recommended": "kimi-k2.5",
  "token_budget": {
    "context": 15000,
    "max_output": 30000
  },
  "files": {
    "allowed": ["autoload/SimulationManager.gd", "src/ai/tactical.gd"],
    "new": ["src/ai/tactical.gd"],
    "forbidden": ["scenes/*.tscn"]
  },
  "dependencies": {
    "systems": ["Deterministic_60Hz_Simulation"],
    "notes": ["Tactical_AI_System"]
  }
}
```

## Content Rules

### Include
- [x] Ticket with full context
- [x] Invariants (critical constraints)
- [x] Conventions (code style)
- [x] Project summary (high-level)
- [x] Allowlisted files (actual code)

### Exclude
- [ ] Files not in allowlist
- [ ] Historical notes
- [ ] Completed tickets
- [ ] External documentation
- [ ] Binary assets

### Token Budget

| Pack Component | Max Tokens | Priority |
|----------------|------------|----------|
| Ticket | 2000 | Required |
| Invariants | 1500 | Required |
| Conventions | 1500 | Required |
| Summary | 1000 | Required |
| Code files | 10000 | Required |
| **Total** | **16000** | Budget |

If code files exceed 10K tokens, use excerpts with `[...]` markers.

## Validation

```bash
# Verify pack integrity
python tools/validate_context_pack.py TICKET-XXX

# Check token count
token_count=$(python tools/count_tokens.py tools/context_packs/TICKET-XXX/)
if [ $token_count -gt 16000 ]; then
    echo "WARNING: Context pack exceeds budget"
fi
```

## Agent Ingestion

Agent receives:
```python
context_pack = {
    "metadata": {...},
    "ticket": "...",
    "invariants": "...",
    "conventions": "...",
    "summary": "...",
    "code_files": {...}
}
```

Agent does NOT receive:
- Full codebase
- Git history
- Other tickets
- Documentation outside pack

## Related
[[Ticket_Template]]
[[OpenClaw_Ingestion_Rules]]
