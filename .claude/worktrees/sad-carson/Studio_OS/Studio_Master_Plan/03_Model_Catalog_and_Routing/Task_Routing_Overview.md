---
title: Task Routing Overview
type: system
layer: architecture
status: active
tags:
  - routing
  - tasks
  - policy
  - framework
  - decision
  - escalation
depends_on:
  - "[Model_Catalog_Overview]]"
  - "[[Local_LLM_Coder_Small]]"
  - "[[Local_LLM_Coder_Medium]]"
  - "[[Frontier_Reasoning_Model]"
used_by:
  - "[Code_Implementation_Routing]]"
  - "[[Refactor_Routing]]"
  - "[[Bug_Triage_Routing]]"
  - "[[Performance_Regression_Routing]]"
  - "[[Determinism_Issue_Routing]]"
  - "[[UI_Flow_Change_Routing]]"
  - "[[Data_Balance_Routing]]"
  - "[[Asset_Integration_Routing]]"
  - "[[Audio_Integration_Routing]]"
  - "[[Build_Release_Routing]"
---

# Task Routing Overview

## Routing Philosophy

The AI-Native Game Studio OS employs a tiered routing system that matches task complexity to model capability while minimizing cost and maximizing quality. The core principle is **progressive escalation**: start with the cheapest adequate model and escalate only when necessary.

### Routing Principles

**1. Local-First Default**
- All code tasks start with local models
- Only escalate to paid APIs on confidence failure
- Privacy and cost control are primary concerns

**2. Confidence-Driven Escalation**
- Every task receives confidence score (0.0-1.0)
- Automatic escalation below thresholds
- Human review for highest-stakes decisions

**3. Context Minimization**
- Send only necessary context to models
- Pre-filter files before routing
- Use summaries for large contexts

**4. Capability Matching**
- Match task type to model strengths
- Never use vision models for pure code
- Reserve frontier models for complex reasoning

### Routing Decision Framework

```
┌─────────────────────────────────────────────────────────────┐
│                    TASK RECEIVED                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: CLASSIFY TASK                                       │
│  ├── Type: code|vision|audio|asset|build                     │
│  ├── Complexity: simple|medium|complex|novel                 │
│  ├── Scope: single-file|multi-file|system-wide               │
│  └── Risk: low|medium|high|critical                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: SELECT INITIAL MODEL                                │
│  ├── Code + Simple → Local Small                             │
│  ├── Code + Medium → Local Medium                            │
│  ├── Code + Complex → Local Medium (with review)             │
│  ├── Code + Novel → Frontier (after local attempt)           │
│  ├── Vision → Vision Model                                   │
│  ├── Audio → Audio Pipeline                                  │
│  └── Asset → Asset Pipeline                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: EXECUTE WITH CONFIDENCE SCORING                     │
│  ├── Generate solution                                       │
│  ├── Calculate confidence score                              │
│  └── Run validation gates                                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: EVALUATE RESULT                                     │
│  ├── Confidence >= 0.85 → ACCEPT                             │
│  ├── Confidence 0.70-0.85 → REVIEW                           │
│  ├── Confidence 0.50-0.70 → ESCALATE                         │
│  └── Confidence < 0.50 → FAIL + ESCALATE                     │
└─────────────────────────────────────────────────────────────┘
```

### Escalation Matrix

| Current Model | Confidence | Escalation Target | Human Review |
|--------------|------------|-------------------|--------------|
| Local Small | <0.5 | Local Medium | No |
| Local Small | 0.5-0.7 | Local Medium | Spot-check |
| Local Medium | <0.6 | Frontier | Yes |
| Local Medium | 0.6-0.75 | Frontier | Spot-check |
| Frontier | <0.7 | Human | Required |
| Any Vision | <0.6 | Human | Required |
| Any Audio | <0.7 | Human | Spot-check |

### Context Pack Specification

Every routed task includes a context pack:

```yaml
context_pack:
  # Core files (always included)
  target_files: ["path/to/file.py"]
  max_target_files: 10
  
  # Related files (auto-discovered)
  related_files: ["path/to/imported.py"]
  max_related_files: 5
  
  # Test files
  test_files: ["path/to/test_file.py"]
  max_test_files: 3
  
  # Documentation
  docs: ["README.md", "API.md"]
  max_docs: 2
  
  # Configuration
  config: ["pyproject.toml", ".cursorrules"]
  
  # Total budget
  max_total_files: 20
  max_tokens: 32000
```

### Owner Agent Assignment

| Task Type | Owner Agent | Escalation Agent |
|-----------|-------------|------------------|
| Code implementation | Code Agent | Senior Code Agent |
| Refactoring | Refactor Agent | Architecture Agent |
| Bug fix | Debug Agent | Senior Debug Agent |
| Performance | Perf Agent | Architecture Agent |
| UI changes | UI Agent | UX Agent |
| Data changes | Data Agent | Design Agent |
| Assets | Asset Agent | Art Director |
| Audio | Audio Agent | Audio Director |
| Build/Release | Build Agent | DevOps Agent |

### Gate Requirements

Every routing decision must pass through gates:

**Pre-Execution Gates:**
- Context validation
- Budget check
- Permission check

**Post-Execution Gates:**
- Static analysis
- Test execution
- Confidence threshold
- Security scan (for critical)

### Cost Tracking

Real-time cost tracking per routing decision:

```yaml
cost_tracking:
  task_id: "unique-id"
  routing_path: ["local-small", "local-medium"]
  tokens_used: 15000
  estimated_cost: 0.003
  actual_cost: 0.0025
  time_elapsed: 45s
  budget_remaining: 0.997
```

### Failure Handling

**Routing Failure Types:**

1. **Context Overflow**: Too much context for model
   - *Action*: Chunk context, retry
   - *Escalation*: Summarize, retry with smaller model

2. **Model Unavailable**: Local model not loaded
   - *Action*: Queue task, load model
   - *Escalation*: Use fallback model

3. **Budget Exceeded**: Cost limit reached
   - *Action*: Pause routing, alert
   - *Escalation*: Require approval

4. **Confidence Cascade**: Multiple models fail
   - *Action*: Log for analysis
   - *Escalation*: Human required

### Integration Points

The routing system integrates with:
- [[Code_Implementation_Routing]]: Code task routing
- [[Refactor_Routing]]: Refactoring routing
- [[Bug_Triage_Routing]]: Bug fix routing
- [[Performance_Regression_Routing]]: Performance routing
- [[Determinism_Issue_Routing]]: Non-deterministic routing
- [[UI_Flow_Change_Routing]]: UI change routing
- [[Data_Balance_Routing]]: Data change routing
- [[Asset_Integration_Routing]]: Asset routing
- [[Audio_Integration_Routing]]: Audio routing
- [[Build_Release_Routing]]: Build routing
