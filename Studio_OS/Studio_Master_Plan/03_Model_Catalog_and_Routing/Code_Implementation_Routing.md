---
title: Code Implementation Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - code
  - implementation
  - tickets
  - models
  - gates
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Local_LLM_Coder_Small]]"
  - "[[Local_LLM_Coder_Medium]]"
  - "[[Frontier_Reasoning_Model]"
used_by:
  - "[Refactor_Routing]]"
  - "[[Bug_Triage_Routing]"
---

# Code Implementation Routing

## Ticket-to-Model Mapping

Code implementation tasks are routed based on complexity, scope, and risk factors extracted from the ticket description and codebase analysis.

### Routing Decision Tree

```
Ticket Received
│
├── Is it a simple change? (<50 lines, single function)
│   ├── YES → Local LLM Small
│   │   └── Confidence >= 0.85? → ACCEPT
│   │   └── Confidence < 0.85? → Local LLM Medium Review
│   │
│   └── NO → Continue
│
├── Is it a medium change? (50-200 lines, 2-5 files)
│   ├── YES → Local LLM Medium
│   │   └── Confidence >= 0.75? → ACCEPT
│   │   └── Confidence 0.60-0.75? → Frontier Review
│   │   └── Confidence < 0.60? → Frontier Escalation
│   │
│   └── NO → Continue
│
├── Is it a complex change? (200+ lines, 5+ files)
│   ├── YES → Local LLM Medium (attempt)
│   │   └── Confidence >= 0.70? → Frontier Review
│   │   └── Confidence < 0.70? → Frontier Primary
│   │
│   └── NO → Continue
│
└── Is it novel/uncertain? (new pattern, unclear requirements)
    └── YES → Frontier Primary (with human review)
```

### Owner Agent: Code Agent

The Code Agent owns implementation routing and execution.

**Responsibilities:**
- Parse ticket requirements
- Determine complexity classification
- Select initial model
- Execute with context packing
- Validate output
- Handle escalation

### Permitted Models by Complexity

| Complexity | Primary | Review | Escalation |
|------------|---------|--------|------------|
| Simple | Local Small | Local Medium | Local Medium |
| Medium | Local Medium | Local Medium | Frontier |
| Complex | Local Medium | Frontier | Frontier |
| Novel | Frontier | Frontier | Human |

### Context Pack Contents

**Simple Task Context Pack (max 5 files):**
```yaml
context_pack:
  target_file: 1  # The file to modify
  related_files: 2  # Direct imports/dependencies
  test_files: 1  # Related tests
  docs: 1  # API documentation
  total_tokens_budget: 4000
```

**Medium Task Context Pack (max 10 files):**
```yaml
context_pack:
  target_files: 3  # Files to modify
  related_files: 4  # Dependencies
  test_files: 2  # Test files
  docs: 1  # Documentation
  total_tokens_budget: 8000
```

**Complex Task Context Pack (max 20 files):**
```yaml
context_pack:
  target_files: 5  # Files to modify
  related_files: 10  # Dependencies
  test_files: 3  # Test files
  docs: 2  # Documentation
  config: 1  # Project config
  total_tokens_budget: 32000
```

### Gates Required

**Pre-Execution Gates:**
1. **Context Validation**: Verify all files exist and are readable
2. **Budget Check**: Ensure cost estimate within limits
3. **Permission Check**: Verify agent has write permission

**Post-Execution Gates:**
1. **Syntax Check**: Code must parse/compile
2. **Static Analysis**: Pass linter (no errors, warnings logged)
3. **Test Execution**: Related tests must pass
4. **Confidence Threshold**: Meet minimum confidence

### Escalation Triggers

| Trigger | From | To | Condition |
|---------|------|-----|-----------|
| Low confidence | Local Small | Local Medium | Score < 0.7 |
| Syntax error | Local Small | Local Medium | After 2 retries |
| Test failure | Local Small | Local Medium | After 2 retries |
| Low confidence | Local Medium | Frontier | Score < 0.6 |
| Complex logic | Local Medium | Frontier | Cyclomatic > 10 |
| Security risk | Any | Frontier + Human | Security scan flag |
| Novel pattern | Any | Frontier | No similar code found |

### Confidence Scoring Formula

```python
def calculate_confidence(task_result):
    score = 0.0
    
    # Token probability (25%)
    score += 0.25 * task_result.mean_token_probability
    
    # Static analysis (25%)
    score += 0.25 * (1.0 if task_result.linter_clean else 0.5)
    
    # Test results (25%)
    score += 0.25 * task_result.test_pass_rate
    
    # Pattern match (15%)
    score += 0.15 * task_result.similarity_to_existing
    
    # Complexity alignment (10%)
    score += 0.10 * (1.0 if task_result.complexity_expected else 0.5)
    
    return min(1.0, score)
```

### Example Routing Scenarios

**Scenario 1: Simple Bug Fix**
```
Ticket: "Fix off-by-one error in inventory count"
Complexity: Simple (10-line change)
Route: Local Small
Result: Confidence 0.92
Action: ACCEPT
```

**Scenario 2: Medium Feature**
```
Ticket: "Add sorting to inventory grid"
Complexity: Medium (100 lines, 3 files)
Route: Local Medium
Result: Confidence 0.68
Action: ESCALATE to Frontier for review
```

**Scenario 3: Complex Refactor**
```
Ticket: "Migrate inventory system to new data model"
Complexity: Complex (500+ lines, 10 files)
Route: Local Medium (attempt) → Frontier
Result: Local confidence 0.45
Action: ESCALATE to Frontier primary
```

### Cost Estimates

| Complexity | Local Small | Local Medium | Frontier | Total Range |
|------------|-------------|--------------|----------|-------------|
| Simple | $0.001 | - | - | $0.001 |
| Medium | - | $0.003 | $0.10* | $0.003-0.10 |
| Complex | - | $0.005 | $0.50* | $0.005-0.50 |
| Novel | - | - | $1.00* | $1.00 |

*Only if escalation occurs

### Integration

Used by:
- [[Refactor_Routing]]: Refactoring builds on implementation
- [[Bug_Triage_Routing]]: Bug fixes are implementation tasks
