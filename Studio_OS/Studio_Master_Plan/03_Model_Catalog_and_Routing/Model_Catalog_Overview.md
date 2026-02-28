---
title: Model Catalog Overview
type: system
layer: architecture
status: active
tags:
  - models
  - routing
  - catalog
  - capabilities
  - selection
depends_on: []
used_by:
  - "[Task_Routing_Overview]]"
  - "[[Local_LLM_Coder_Small]]"
  - "[[Local_LLM_Coder_Medium]]"
  - "[[Frontier_Reasoning_Model]]"
  - "[[Repo_Aware_Code_Editor]]"
  - "[[Vision_UI_Interpreter]]"
  - "[[Vision_Art_Direction]]"
  - "[[Audio_Generation_SFX]]"
  - "[[Audio_Generation_Music]]"
  - "[[Audio_Generation_Voice]]"
  - "[[Image_Diffusion_Local]]"
  - "[[Image_Diffusion_API]]"
  - "[[Model_3D_Generation]"
---

# Model Catalog Overview

## Organization Philosophy

The AI-Native Game Studio OS maintains a tiered model catalog organized by capability class, cost profile, and operational constraints. This catalog serves as the single source of truth for model selection decisions across all automated and semi-automated workflows.

### Catalog Structure

The catalog is organized into five primary capability classes:

| Class | Purpose | Cost Profile | Latency Target |
|-------|---------|--------------|----------------|
| **Code Generation** | Implementation, refactoring, debugging | $0.001-0.10/1K tokens | 2-30s |
| **Reasoning & Planning** | Architecture, design, complex analysis | $0.03-0.50/1K tokens | 10-120s |
| **Vision** | UI analysis, art direction, layout | $0.005-0.05/image | 5-30s |
| **Audio** | SFX, music, voice generation | $0.001-0.50/audio | 1-60s |
| **Image/3D** | Asset generation, concept art | $0.02-2.00/image | 5-120s |

### Selection Principles

**1. Default to Local First**
- Local models are the default for all code generation tasks
- Only escalate to paid APIs when local models fail confidence thresholds
- Local models provide determinism, privacy, and cost control

**2. Confidence-Based Escalation**
- Every task receives a confidence score (0.0-1.0) from the initial model
- Scores below 0.7 trigger automatic escalation
- Scores 0.7-0.85 trigger review by secondary model
- Scores above 0.85 proceed with human spot-checking

**3. Context Budget Enforcement**
- Each model class has a maximum context budget (files, tokens, time)
- Context packs are pre-filtered to stay within budget
- Excess context triggers chunking or summarization

**4. Capability Matching**
- Match task requirements to model strengths
- Never use a vision model for pure code tasks
- Never use a small coder for architecture decisions

### Model Registration

All models in the catalog must provide:

```yaml
model_id: unique-identifier
capability_class: code|reasoning|vision|audio|image|3d
provider: local|api|hybrid
context_window: 4096|8192|32768|128000
strengths: [list of specific capabilities]
weaknesses: [list of known limitations]
cost_per_1k_tokens: float or null
latency_p50: seconds
failure_patterns: [known failure modes]
```

### Confidence Scoring Methodology

Confidence scores are derived from:

1. **Self-Assessment**: Model's own confidence expression (0.0-0.3 weight)
2. **Pattern Matching**: Task similarity to training distribution (0.0-0.3 weight)
3. **Complexity Score**: Measured cyclomatic + cognitive complexity (0.0-0.2 weight)
4. **Historical Accuracy**: Track record on similar tasks (0.0-0.2 weight)

### Escalation Matrix

| Initial Model | Confidence | Escalation Target | Review Model |
|--------------|------------|-------------------|--------------|
| Local Small | <0.5 | Local Medium | Frontier |
| Local Small | 0.5-0.7 | Local Medium | Local Medium |
| Local Medium | <0.6 | Frontier | Frontier |
| Frontier | <0.7 | Human Review | Human |
| Any Vision | <0.6 | Human Review | Human |

### Cost Governance

- Monthly budget caps per capability class
- Real-time cost tracking with alerts at 80% budget
- Automatic downgrading when budgets exceeded
- Cost-per-task reporting for optimization

### Version Management

Models are pinned to specific versions:
- Local models: quantized checkpoint hash
- API models: version date or snapshot ID
- Updates require re-validation on test suite

### Integration Points

The catalog integrates with:
- [[Task_Routing_Overview]]: For routing decisions
- [[Code_Implementation_Routing]]: For code task model selection
- [[Build_Release_Routing]]: For CI/CD model usage
