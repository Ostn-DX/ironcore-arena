---
title: Model_Catalog
type: cost
layer: costing
status: active
tags:
  - models
  - cost
  - pricing
  - api
depends_on: []
used_by:
  - "[Task_Routing_Table]"
---

# Model Catalog

## Purpose
Central registry of all LLM models available for agent work, with actual pricing and capability mapping.

## Model Inventory

### Tier 1: Code-Optimized (Primary)

| Model | Provider | Input | Output | Context | Best For |
|-------|----------|-------|--------|---------|----------|
| **Kimi k2.5** | Moonshot | $0.80/M | $0.80/M | 128K | Code generation, refactoring |
| **Claude 3.5 Sonnet** | Anthropic | $3.00/M | $15.00/M | 200K | Architecture, complex reasoning |
| **GPT-4o** | OpenAI | $2.50/M | $10.00/M | 128K | General purpose, analysis |

### Tier 2: Cost-Optimized (High Volume)

| Model | Provider | Input | Output | Context | Best For |
|-------|----------|-------|--------|---------|----------|
| **Gemini 1.5 Flash** | Google | $0.075/M | $0.30/M | 1M | Documentation, summaries |
| **GPT-4o-mini** | OpenAI | $0.15/M | $0.60/M | 128K | Simple tasks, validation |
| **Llama 3.1 405B** | Fireworks | $0.90/M | $0.90/M | 128K | Local inference backup |

### Tier 3: Specialized

| Model | Provider | Input | Output | Use Case |
|-------|----------|-------|--------|----------|
| **Claude 3 Haiku** | Anthropic | $0.25/M | $1.25/M | Fast classification |
| **GPT-4o-audio** | OpenAI | $2.50/M | $10.00/M | Whisper transcription |
| **DALL-E 3** | OpenAI | $0.04/image | - | Asset generation |

## Capability Matrix

| Task | Preferred | Fallback | Avoid |
|------|-----------|----------|-------|
| Architecture design | Claude 3.5 Sonnet | GPT-4o | Gemini Flash |
| GDScript implementation | Kimi k2.5 | GPT-4o | Claude Haiku |
| Test generation | Kimi k2.5 | GPT-4o-mini | GPT-4 |
| Documentation | Gemini Flash | GPT-4o-mini | Claude Sonnet |
| Code review | Claude 3.5 Sonnet | Kimi k2.5 | GPT-4o-mini |
| Debugging | Kimi k2.5 | Claude 3.5 Sonnet | Gemini Flash |
| JSON/data work | GPT-4o | Gemini Flash | Claude Haiku |
| Complex reasoning | Claude 3.5 Sonnet | GPT-4o | Gemini Flash |

## Cost Efficiency Ranking (Code Tasks)

1. **Kimi k2.5** - Best code/$ ratio
2. **Gemini Flash** - Best for docs/simple tasks
3. **GPT-4o-mini** - Reliable, moderate cost
4. **GPT-4o** - High quality, higher cost
5. **Claude 3.5 Sonnet** - Best quality, expensive

## Context Window Utilization

| Model | Max Context | Practical Limit | % for Code |
|-------|-------------|-----------------|------------|
| Kimi k2.5 | 128K | 100K | 70% |
| Claude 3.5 Sonnet | 200K | 150K | 60% |
| Gemini Flash | 1M | 500K | 80% |
| GPT-4o | 128K | 100K | 70% |

## Routing Rules

```python
def route_task(task_type, complexity, context_size):
    if complexity == "architectural":
        return "claude-3-5-sonnet"
    elif task_type == "code" and context_size < 50K:
        return "kimi-k2.5"
    elif task_type == "documentation":
        return "gemini-flash"
    elif complexity == "simple":
        return "gpt-4o-mini"
    else:
        return "gpt-4o"
```

## Related
[[Task_Routing_Table]]
[[Cost_Model_Assumptions]]
[[Monthly_Budget_Tiers]]
