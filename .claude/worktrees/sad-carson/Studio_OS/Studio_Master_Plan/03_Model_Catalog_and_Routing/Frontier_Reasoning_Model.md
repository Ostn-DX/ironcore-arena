---
title: Frontier Reasoning Model
type: agent
layer: architecture
status: active
tags:
  - frontier
  - reasoning
  - gpt4
  - o1
  - claude
  - planning
  - review
  - architecture
depends_on:
  - "[Model_Catalog_Overview]]"
  - "[[Local_LLM_Coder_Medium]"
used_by:
  - "[Task_Routing_Overview]]"
  - "[[Code_Implementation_Routing]]"
  - "[[Refactor_Routing]]"
  - "[[Bug_Triage_Routing]]"
  - "[[Determinism_Issue_Routing]"
---

# Frontier Reasoning Model

## Model Class: GPT-4/o1/Claude-3.5-Sonnet Class Models

Frontier reasoning models represent the state-of-the-art in LLM capabilities. These API-based models are reserved for high-value tasks requiring deep reasoning, complex planning, and critical review functions.

### Supported Models

| Model | Provider | Context | Best For | Cost/1K Tokens |
|-------|----------|---------|----------|----------------|
| GPT-4o | OpenAI | 128K | General reasoning, analysis | $0.005/$0.015 |
| o1/o3-mini | OpenAI | 200K | Complex reasoning, math | $0.003/$0.012 |
| Claude 3.5 Sonnet | Anthropic | 200K | Code analysis, long context | $0.003/$0.015 |
| Claude 3 Opus | Anthropic | 200K | Maximum capability | $0.015/$0.075 |
| Gemini 1.5 Pro | Google | 1M | Ultra-long context | $0.0035/$0.0105 |

### Capability Profile

**Strengths:**
- Exceptional reasoning and problem-solving
- Strong at novel architectural patterns
- Excellent code review capabilities
- Can handle very long contexts (200K+ tokens)
- Superior at understanding complex requirements
- Strong at debugging subtle issues
- Excellent at explaining trade-offs
- Good at security analysis

**Weaknesses:**
- High cost per token
- API dependency (latency, availability)
- Privacy concerns for sensitive code
- Rate limits on most providers
- Can be overconfident in responses
- May not respect project-specific conventions without explicit instruction

### Optimal Task Types

1. **Architecture and design decisions**
2. **Complex debugging** requiring deep reasoning
3. **Security audits** and vulnerability analysis
4. **Performance optimization** strategy
5. **Code review** of critical changes
6. **Test strategy** design
7. **Refactoring planning** for large components
8. **Novel algorithm design**
9. **Cross-system integration design**
10. **Technical documentation** of complex systems

### Reserved for High-Value Tasks

Frontier models should ONLY be used for:
- Tasks where failure cost > $50
- Security-sensitive code paths
- Performance-critical optimizations
- Novel problems without established patterns
- Final review before production
- Architectural decisions affecting >5 components

### Context Budget

- **Max files**: 50+ files (with smart chunking)
- **Max tokens**: 100,000-200,000 (provider dependent)
- **Max time**: 300 seconds per request
- **Recommended approach**: Summarize large contexts

### Configuration

```yaml
# API configuration
temperature: 0.0  # Deterministic for code tasks
max_tokens: 4096
context_window: 128000  # or 200000
# Enable extended thinking for o1 models
reasoning_effort: high  # for o1/o3 models
```

### Confidence Scoring

| Factor | Weight | Measurement |
|--------|--------|-------------|
| Self-assessment | 0.15 | Model's confidence expression |
| Reasoning quality | 0.25 | Coherence of explanation |
| Pattern novelty | 0.20 | Distance from known patterns |
| Context adequacy | 0.20 | Coverage of relevant information |
| Historical accuracy | 0.20 | Track record on similar tasks |

### Cost Governance

**Daily Budget Caps:**
- Architecture tasks: $20/day
- Code review: $10/day
- Debugging: $15/day
- Documentation: $5/day

**Cost Optimization:**
- Cache similar requests
- Use cheaper models for initial filtering
- Batch related requests
- Summarize long contexts before sending

### Failure Patterns

1. **Over-Engineering**: Proposes overly complex solutions
   - *Detection*: Complexity metrics, review feedback
   - *Remediation*: Add constraints, request simpler alternatives

2. **Convention Violations**: Ignores project-specific patterns
   - *Detection*: Style guide violations
   - *Remediation*: Include style guide in context

3. **Hallucinated APIs**: Confidently suggests non-existent APIs
   - *Detection*: API validation, documentation check
   - *Remediation*: Provide API reference in context

4. **Context Misuse**: Focuses on wrong parts of large context
   - *Detection*: Irrelevant recommendations
   - *Remediation*: Highlight key sections, use summaries

### Escalation Triggers

- Confidence score < 0.7 (escalate to human)
- Cost estimate exceeds $5 per task
- Security-critical findings
- Architectural disagreement between models

### Cost Profile

| Task Type | Tokens | Cost | Justification |
|-----------|--------|------|---------------|
| Architecture review | 50K | $0.75 | Prevents costly mistakes |
| Security audit | 30K | $0.45 | Risk mitigation |
| Complex debugging | 20K | $0.30 | Time savings |
| Code review | 15K | $0.23 | Quality assurance |

### When to Use vs Local Models

| Scenario | Local Medium | Frontier |
|----------|--------------|----------|
| Standard CRUD | Yes | No |
| Novel algorithm | Maybe | Yes |
| Security audit | No | Yes |
| Performance critical | Review | Yes |
| Architecture decision | Input | Yes |
| Simple bug fix | Yes | No |
| Complex race condition | No | Yes |

### Integration

Used primarily by:
- [[Task_Routing_Overview]]: Final escalation tier
- [[Code_Implementation_Routing]]: Complex implementation review
- [[Refactor_Routing]]: Large-scale refactoring approval
- [[Bug_Triage_Routing]]: Complex bug analysis
- [[Determinism_Issue_Routing]]: Non-deterministic bug root cause
