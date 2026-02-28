---
title: OpenClaw_Ingestion_Rules
type: rule
layer: enforcement
status: active
tags:
  - rules
  - ingestion
  - cost
  - limits
depends_on: []
used_by:
  - "[Daily_Operator_Protocol]"
---

# OpenClaw Ingestion Rules

## Purpose
Strict content boundaries for OpenClaw execution. Prevents context overflow and cost overrun.

## Permitted Ingestion

When executing a ticket, OpenClaw may ingest ONLY:

### 1. Core System Notes (Always)
```
Studio_OS/99_Master_Index/System_Map.md
Studio_OS/12_Architectural_Decisions/Architectural_Invariants.md
Studio_OS/12_Architectural_Decisions/Code_Conventions_Standard.md
```

### 2. Relevant System Notes (By Tag)
```
# Determine by ticket tags
ticket_tags = ["ai", "combat"]
ingest = find_notes_by_tags(ticket_tags, limit=3)
```

### 3. Allowlisted Code Files
```
# From ticket allowlist only
autoload/SimulationManager.gd
src/ai/tactical.gd
```

### 4. Context Pack (If Available)
```
tools/context_packs/TICKET-XXX/
  - ticket.md
  - invariants.md
  - conventions.md
  - summary.md
  - allowed_files/
```

## Forbidden Ingestion

OpenClaw must NEVER ingest:

- ❌ Other tickets (completed or pending)
- ❌ Git history or diffs
- ❌ Binary assets (images, audio)
- ❌ External documentation
- ❌ Full codebase scan
- ❌ Notes outside explicit allowlist
- ❌ Historical context from previous sessions

## Ingestion Budget

| Content Type | Max Tokens | Priority |
|--------------|------------|----------|
| System notes | 5000 | Required |
| Relevant notes | 5000 | Required |
| Code files | 10000 | Required |
| Context pack | 16000 | If available |
| **Total Budget** | **20000** | Hard limit |

## Validation

```python
def validate_ingestion(requested_files):
    allowed = [
        "System_Map.md",
        "Architectural_Invariants.md",
        "Code_Conventions_Standard.md",
    ]
    allowed += get_notes_by_tags(ticket.tags)
    allowed += ticket.allowlist
    
    for file in requested_files:
        if file not in allowed:
            raise IngestionViolation(f"{file} not in allowlist")
```

## Cost Containment

### Token Limits Per Request
- Soft limit: 15K tokens
- Hard limit: 20K tokens
- Over limit: Request truncated

### Model Selection by Context Size
```python
if total_tokens < 5000:
    model = "gpt-4o-mini"
elif total_tokens < 15000:
    model = "kimi-k2.5"
else:
    model = "claude-3.5-sonnet"
    truncate_context_to(15000)
```

## Enforcement

### Automated
```bash
# Validate ingestion before execution
python tools/validate_ingestion.py TICKET-XXX

# Check token count
token_count=$(python tools/count_tokens.py context_pack/)
if [ $token_count -gt 20000 ]; then
    echo "ERROR: Context exceeds 20K token limit"
    exit 1
fi
```

### Audit Trail
Every execution logs:
```json
{
  "ticket": "TICKET-001",
  "ingested_files": [...],
  "total_tokens": 15400,
  "model_used": "kimi-k2.5",
  "cost": "$0.80"
}
```

## Violation Response

| Severity | Response |
|----------|----------|
| Attempted ingestion of forbidden file | Log warning, skip file |
| Token limit exceeded | Truncate context, notify human |
| Repeated violations | Disable autonomous execution |

## Related
[[Context_Pack_Spec]]
[[Model_Catalog]]
[[Monthly_Budget_Tiers]]
