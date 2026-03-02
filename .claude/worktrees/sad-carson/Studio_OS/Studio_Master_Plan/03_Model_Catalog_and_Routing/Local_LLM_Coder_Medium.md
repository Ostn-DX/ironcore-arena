---
title: Local LLM Coder (Medium)
type: agent
layer: execution
status: active
tags:
  - local
  - llm
  - code
  - medium
  - 13b
  - 34b
  - complex
  - reasoning
depends_on:
  - "[Model_Catalog_Overview]]"
  - "[[Local_LLM_Coder_Small]"
used_by:
  - "[Code_Implementation_Routing]]"
  - "[[Refactor_Routing]]"
  - "[[Performance_Regression_Routing]"
---

# Local LLM Coder (Medium)

## Model Class: 13B-34B Parameter Local Models

Medium local LLMs provide the reasoning depth and context capacity needed for complex implementation tasks while maintaining the cost and privacy benefits of local inference. These models require enthusiast-grade hardware (16-48GB VRAM).

### Supported Models

| Model | Parameters | VRAM | Quantization | Best For |
|-------|------------|------|--------------|----------|
| Qwen2.5-Coder | 14B/32B | 12-24GB | Q4/Q5_K_M | Complex algorithms, architecture |
| CodeLlama | 13B/34B | 12-24GB | Q4_K_M | Large codebase understanding |
| DeepSeek-Coder-V2 | 16B | 14GB | Q4_K_M | Multi-file reasoning |
| Mixtral 8x7B | 47B (12B active) | 16GB | Q4_K_M | MoE efficiency, broad knowledge |
| WizardCoder | 13B/34B | 12-24GB | Q4_K_M | Instruction following |

### Capability Profile

**Strengths:**
- Strong multi-file reasoning (up to 10 files)
- Excellent at complex algorithm implementation
- Good at understanding existing code patterns
- Capable of meaningful refactoring
- Better edge case handling than small models
- Can handle architectural decisions with guidance
- Maintains coherence across longer generations

**Weaknesses:**
- Higher latency (20-60s for complex tasks)
- Significant VRAM requirements
- Still limited vs frontier models for novel problems
- May miss subtle cross-file dependencies
- Can over-engineer simple solutions
- Struggles with very large codebases (>100K lines)

### Optimal Task Types

1. **Multi-file feature implementation** (3-10 files)
2. **Complex algorithm implementation** (50-200 lines)
3. **Significant refactoring** affecting multiple functions
4. **API design and implementation**
5. **Performance optimization** with analysis
6. **Test suite generation** for modules
7. **Code review** of medium complexity changes
8. **Integration tasks** requiring multiple components

### Context Budget

- **Max files**: 10 files
- **Max tokens**: 8,192-32,768 (model dependent)
- **Max time**: 120 seconds per request
- **Recommended chunk size**: 4,096 tokens

### Configuration

```yaml
# Recommended inference settings
temperature: 0.0  # Deterministic for code
max_tokens: 4096
context_window: 8192  # or 32768 for supported models
repeat_penalty: 1.1
top_p: 0.95
top_k: 40
```

### Confidence Scoring

| Factor | Weight | Measurement |
|--------|--------|-------------|
| Token probability | 0.20 | Mean logprob of generated tokens |
| Pattern match | 0.20 | Similarity to training examples |
| Complexity score | 0.20 | Cyclomatic + cognitive complexity |
| Context coverage | 0.20 | % of required symbols in context |
| Historical accuracy | 0.20 | Success rate on similar tasks |

### Failure Patterns

1. **Reasoning Depth**: Task requires reasoning beyond model capacity
   - *Detection*: Circular logic, inconsistent solutions
   - *Remediation*: Escalate to Frontier model

2. **Context Fragmentation**: Important context split across files
   - *Detection*: Missing imports, undefined references
   - *Remediation*: Improve context packing, add summaries

3. **Over-Engineering**: Adds unnecessary abstraction
   - *Detection*: Complexity increase without benefit
   - *Remediation*: Add constraints to prompt, review output

4. **Hallucinated Dependencies**: References non-existent libraries
   - *Detection*: Import errors, package not found
   - *Remediation*: Add dependency manifest to context

### Escalation Triggers

- Confidence score < 0.6
- Static analysis fails after 2 attempts
- Requires >10 files
- Novel architectural pattern needed
- Security-sensitive code
- Performance-critical path

### Cost Profile

- **Per-request cost**: $0.00 (local inference)
- **Hardware cost**: ~$0.15/hour (amortized GPU)
- **Effective cost**: ~$0.003/1K tokens (electricity + hardware)
- **Break-even vs API**: ~500 requests/day

### Performance Benchmarks

| Hardware | Tokens/sec | Latency (1024 tokens) |
|----------|------------|----------------------|
| RTX 4090 24GB | 45-60 | 20s |
| RTX 3090 24GB | 35-50 | 25s |
| 2x RTX 4090 | 80-100 | 12s |
| A100 40GB | 60-80 | 15s |

### Comparison with Small Models

| Metric | Small (7B) | Medium (34B) | Improvement |
|--------|-----------|--------------|-------------|
| HumanEval | 45% | 72% | +60% |
| Multi-file tasks | 35% | 68% | +94% |
| Context window | 4K | 32K | +700% |
| Latency | 5s | 25s | 5x |
| VRAM | 6GB | 24GB | 4x |

### Integration

Used primarily by:
- [[Code_Implementation_Routing]]: Escalation target for complex tasks
- [[Refactor_Routing]]: Default for multi-file refactoring
- [[Performance_Regression_Routing]]: Analysis and optimization tasks
