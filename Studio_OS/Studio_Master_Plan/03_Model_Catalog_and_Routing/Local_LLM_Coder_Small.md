---
title: Local LLM Coder (Small)
type: agent
layer: execution
status: active
tags:
  - local
  - llm
  - code
  - small
  - fast
  - 3b
  - 7b
  - implementation
depends_on:
  - "[Model_Catalog_Overview]"
used_by:
  - "[Code_Implementation_Routing]]"
  - "[[Bug_Triage_Routing]]"
  - "[[UI_Flow_Change_Routing]"
---

# Local LLM Coder (Small)

## Model Class: 3B-7B Parameter Local Models

Small local LLMs serve as the workhorse for high-volume, low-complexity coding tasks. These models run on consumer-grade hardware (8-16GB VRAM) and provide sub-second to few-second response times for typical tasks.

### Supported Models

| Model | Parameters | VRAM | Quantization | Best For |
|-------|------------|------|--------------|----------|
| Qwen2.5-Coder | 3B/7B | 4-8GB | Q4/Q5_K_M | General coding, quick fixes |
| CodeLlama | 7B | 6GB | Q4_K_M | Python, C++ patterns |
| DeepSeek-Coder | 6.7B | 6GB | Q4_K_M | Long context understanding |
| StarCoder2 | 7B | 6GB | Q4_K_M | Multi-language support |
| Phi-4 | 4B | 4GB | Q4_K_M | Instruction following |

### Capability Profile

**Strengths:**
- Fast inference (10-50 tokens/second on RTX 3060)
- Low latency for interactive workflows
- Excellent for boilerplate generation
- Strong at pattern completion
- Good at simple refactoring
- Deterministic with temperature=0

**Weaknesses:**
- Limited context window (4K-8K tokens)
- Struggles with complex multi-file changes
- May hallucinate APIs not in context
- Poor at architectural decisions
- Limited reasoning for edge cases
- Can produce syntactically correct but semantically wrong code

### Optimal Task Types

1. **Single-function implementation** (<50 lines)
2. **Simple bug fixes** with clear error messages
3. **Test case generation** for existing functions
4. **Documentation generation** from code
5. **Code formatting and style fixes**
6. **Variable/parameter renaming**
7. **Simple regex patterns**
8. **Configuration file edits**

### Context Budget

- **Max files**: 3 files (target + 2 context)
- **Max tokens**: 4,096 (input + output)
- **Max time**: 30 seconds per request
- **Recommended chunk size**: 2,048 tokens

### Configuration

```yaml
# Recommended inference settings
temperature: 0.0  # Deterministic for code
max_tokens: 2048
context_window: 4096
repeat_penalty: 1.1
top_p: 0.95
top_k: 40
```

### Confidence Scoring

| Factor | Weight | Measurement |
|--------|--------|-------------|
| Token probability | 0.25 | Mean logprob of generated tokens |
| Pattern match | 0.25 | Similarity to training examples |
| Complexity score | 0.20 | Cyclomatic complexity of task |
| Context coverage | 0.15 | % of required symbols in context |
| Historical accuracy | 0.15 | Success rate on similar tasks |

### Failure Patterns

1. **Context Overflow**: Task requires more context than available
   - *Detection*: Context window exceeded warning
   - *Remediation*: Escalate to Medium model or chunk task

2. **API Hallucination**: Generates calls to non-existent APIs
   - *Detection*: Static analysis fails, symbols not found
   - *Remediation*: Add API definitions to context, retry

3. **Partial Implementation**: Stops mid-implementation
   - *Detection*: Incomplete function, missing closing braces
   - *Remediation*: Increase max_tokens, retry with continuation

4. **Wrong Language**: Outputs in wrong programming language
   - *Detection*: Language mismatch in output
   - *Remediation*: Explicit language instruction, retry

### Escalation Triggers

- Confidence score < 0.7
- Static analysis fails
- Compilation errors after 2 retries
- Task requires >3 files
- Estimated token count > 3,500
- Complex reasoning required

### Cost Profile

- **Per-request cost**: $0.00 (local inference)
- **Hardware cost**: ~$0.05/hour (amortized GPU)
- **Effective cost**: ~$0.001/1K tokens (electricity + hardware)

### Performance Benchmarks

| Hardware | Tokens/sec | Latency (512 tokens) |
|----------|------------|---------------------|
| RTX 3060 12GB | 35-45 | 12s |
| RTX 4090 24GB | 80-120 | 5s |
| M2 Pro 16GB | 25-35 | 15s |
| CPU (16 threads) | 5-10 | 50s |

### Integration

Used primarily by:
- [[Code_Implementation_Routing]]: Default for simple implementation tasks
- [[Bug_Triage_Routing]]: Quick fixes for known patterns
- [[UI_Flow_Change_Routing]]: Simple UI component updates
