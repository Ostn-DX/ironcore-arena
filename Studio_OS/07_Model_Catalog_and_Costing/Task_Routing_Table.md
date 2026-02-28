---
title: Task_Routing_Table
type: cost
layer: costing
status: active
tags:
  - routing
  - tasks
  - cost
  - optimization
depends_on:
  - "[Model_Catalog]"
used_by:
  - "[Daily_Operator_Protocol]"
---

# Task Routing Table

## Purpose
Deterministic routing of tasks to appropriate models based on cost-efficiency and capability requirements.

## Routing Matrix

### Code Implementation Tasks

| Complexity | Context Size | Primary Route | Fallback | Max Cost |
|------------|--------------|---------------|----------|----------|
| Simple (<50 lines) | <10K tokens | GPT-4o-mini | Gemini Flash | $0.05 |
| Medium (50-200 lines) | 10K-50K tokens | Kimi k2.5 | GPT-4o | $0.50 |
| Complex (200+ lines) | 50K-100K tokens | Kimi k2.5 | Claude 3.5 Sonnet | $2.00 |
| Architectural | 100K+ tokens | Claude 3.5 Sonnet | GPT-4o | $5.00 |

### Analysis & Review Tasks

| Task Type | Primary Route | Fallback | Max Cost |
|-----------|---------------|----------|----------|
| Code review | Claude 3.5 Sonnet | Kimi k2.5 | $1.00 |
| Test generation | Kimi k2.5 | GPT-4o-mini | $0.30 |
| Documentation | Gemini Flash | GPT-4o-mini | $0.10 |
| Balance analysis | GPT-4o | Kimi k2.5 | $0.50 |
| Debug analysis | Kimi k2.5 | Claude 3.5 Sonnet | $1.00 |

### Content Generation Tasks

| Task Type | Primary Route | Fallback | Max Cost |
|-----------|---------------|----------|----------|
| Sprite descriptions | Gemini Flash | GPT-4o-mini | $0.05 |
| Audio prompts | GPT-4o-mini | Gemini Flash | $0.03 |
| Arena descriptions | GPT-4o | Gemini Flash | $0.20 |
| Enemy backstories | Gemini Flash | GPT-4o-mini | $0.10 |

## Routing Decision Tree

```
START
  │
  ├─→ Is this architectural design?
  │   └─→ YES → Route to Claude 3.5 Sonnet
  │
  ├─→ Is this code implementation?
  │   ├─→ Context < 50K tokens?
  │   │   └─→ YES → Route to Kimi k2.5
  │   │   └─→ NO → Route to GPT-4o
  │   └─→ Context > 100K tokens?
  │       └─→ YES → Route to Claude 3.5 Sonnet
  │
  ├─→ Is this documentation?
  │   └─→ YES → Route to Gemini Flash
  │
  ├─→ Is this simple/quick?
  │   └─→ YES → Route to GPT-4o-mini
  │
  └─→ DEFAULT → Route to GPT-4o
```

## Escalation Triggers

| Trigger | From | To | Condition |
|---------|------|-----|-----------|
| Quality fail | GPT-4o-mini | GPT-4o | Output has errors |
| Context overflow | Kimi k2.5 | Claude 3.5 Sonnet | >100K tokens |
| Complex logic | Kimi k2.5 | Claude 3.5 Sonnet | Multiple failures |
| Speed priority | Any | Claude Haiku | Need fast response |

## Cost Caps Per Ticket

| Ticket Type | Soft Cap | Hard Cap |
|-------------|----------|----------|
| Bug fix | $0.50 | $2.00 |
| Feature implementation | $2.00 | $5.00 |
| Architecture design | $5.00 | $10.00 |
| Test suite | $1.00 | $3.00 |
| Documentation | $0.50 | $1.00 |

## Retry Policy

| Failure Type | Retry Count | Escalate To |
|--------------|-------------|-------------|
| Parse error | 1x same model | Next tier |
| Logic error | 2x same model | Claude 3.5 Sonnet |
| Timeout | 1x same model | Faster model |
| Cost overflow | 0x | N/A (halt) |

## Related
[[Model_Catalog]]
[[Calibration_Protocol]]
[[Cost_Model_Assumptions]]
