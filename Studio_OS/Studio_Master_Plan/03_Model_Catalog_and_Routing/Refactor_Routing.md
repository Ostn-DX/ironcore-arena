---
title: Refactor Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - refactor
  - multi-file
  - changes
  - architecture
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Code_Implementation_Routing]]"
  - "[[Local_LLM_Coder_Medium]]"
  - "[[Frontier_Reasoning_Model]"
used_by:
  - "[Performance_Regression_Routing]"
---

# Refactor Routing

## Multi-File Change Routing

Refactoring tasks require special routing due to their cross-file nature and higher risk profile. Refactors are classified by scope, impact, and safety level.

### Refactor Classification

| Class | Scope | Files | Risk | Example |
|-------|-------|-------|------|---------|
| A | Single file | 1 | Low | Rename variable |
| B | Local scope | 2-5 | Medium | Extract method |
| C | Component | 5-15 | High | Change interface |
| D | System-wide | 15+ | Critical | Migrate framework |

### Routing Decision Tree

```
Refactor Request
│
├── Class A: Single file
│   └── Route: Local Medium
│       └── Confidence >= 0.80 → ACCEPT
│       └── Confidence < 0.80 → Human Review
│
├── Class B: Local scope (2-5 files)
│   └── Route: Local Medium (primary)
│       └── Generate refactor plan
│       └── Execute file-by-file
│       └── Confidence >= 0.75 → ACCEPT
│       └── Confidence 0.60-0.75 → Frontier Review
│       └── Confidence < 0.60 → Human Required
│
├── Class C: Component (5-15 files)
│   └── Route: Frontier (plan) → Local Medium (execute)
│       └── Frontier creates refactor plan
│       └── Local Medium executes per plan
│       └── Frontier reviews results
│       └── All gates pass → ACCEPT
│       └── Any gate fails → Human Required
│
└── Class D: System-wide (15+ files)
    └── Route: Human Required
        └── Frontier assists with analysis
        └── Human creates plan
        └── Human executes with AI assistance
```

### Owner Agent: Refactor Agent

The Refactor Agent owns multi-file change coordination.

**Responsibilities:**
- Classify refactor scope
- Identify affected files
- Create refactor plan
- Coordinate execution
- Validate cross-file consistency
- Handle rollback if needed

### Permitted Models by Class

| Class | Planning | Execution | Review |
|-------|----------|-----------|--------|
| A | Local Medium | Local Medium | Local Medium |
| B | Local Medium | Local Medium | Frontier |
| C | Frontier | Local Medium | Frontier |
| D | Human | Human + AI | Human |

### Context Pack Contents

**Class B Context Pack (5-10 files):**
```yaml
context_pack:
  target_files: 5  # Files to modify
  dependencies: 3  # Imported modules
  test_files: 2  # Related tests
  interface_defs: 1  # Interface/API definitions
  total_tokens_budget: 16000
```

**Class C Context Pack (15+ files):**
```yaml
context_pack:
  target_files: 10  # Primary files
  dependencies: 10  # Related modules
  test_files: 5  # Test suite
  interface_defs: 3  # API definitions
  docs: 2  # Architecture docs
  total_tokens_budget: 32000
  
  # For large refactors, use summaries
  use_summaries: true
  summary_depth: "function_signatures"
```

### Gates Required

**Pre-Refactor Gates:**
1. **Impact Analysis**: Identify all affected files
2. **Test Coverage**: Verify tests exist for affected code
3. **Backup Check**: Ensure version control checkpoint
4. **Approval Gate**: For Class C+, require approval

**Per-File Gates:**
1. **Syntax Check**: Each file must compile
2. **Import Resolution**: All imports must resolve
3. **Interface Compatibility**: APIs must remain compatible

**Post-Refactor Gates:**
1. **Full Test Suite**: All tests must pass
2. **Integration Tests**: Cross-file interactions verified
3. **Static Analysis**: No new warnings
4. **Performance Check**: No regressions
5. **Confidence Threshold**: Overall confidence >= 0.75

### Refactor Plan Template

```yaml
refactor_plan:
  id: "refactor-001"
  class: "B"
  description: "Extract inventory management to service"
  
  phases:
    - phase: 1
      action: "Create new service class"
      files: ["inventory_service.py"]
      estimated_lines: 150
      
    - phase: 2
      action: "Migrate inventory methods"
      files: ["player.py", "chest.py", "shop.py"]
      estimated_lines: 200
      
    - phase: 3
      action: "Update tests"
      files: ["test_inventory.py"]
      estimated_lines: 100
  
  rollback_strategy: "git revert"
  estimated_time: "2 hours"
  risk_level: "medium"
```

### Escalation Triggers

| Trigger | Action |
|---------|--------|
| Plan confidence < 0.70 | Escalate planning to Frontier |
| Execution confidence < 0.60 | Halt, human review required |
| Test failure in >2 files | Halt, investigate dependencies |
| Interface breakage | Halt, human review required |
| Performance regression >10% | Halt, optimization required |

### Rollback Strategy

Every refactor must have rollback capability:

```yaml
rollback:
  method: "git revert"  # or "backup restore"
  checkpoint: "pre-refactor-branch"
  auto_rollback: true  # for Class A, B
  manual_rollback: true  # for Class C, D
  rollback_triggers:
    - test_failure_rate > 0.20
    - critical_bug_reported
    - performance_regression > 0.20
```

### Cost Estimates

| Class | Local Medium | Frontier | Human | Total Range |
|-------|--------------|----------|-------|-------------|
| A | $0.003 | - | - | $0.003 |
| B | $0.010 | $0.20* | - | $0.01-0.20 |
| C | $0.030 | $0.50* | - | $0.03-0.50 |
| D | $0.050 | $1.00* | $200/hr | $200+ |

*If review required

### Best Practices

1. Always create refactor plan before execution
2. Execute in small, reversible phases
3. Run tests after each phase
4. Maintain rollback capability
5. Document changes for reviewers
6. Use feature flags for risky changes

### Integration

Used by:
- [[Performance_Regression_Routing]]: Performance fixes often require refactoring
