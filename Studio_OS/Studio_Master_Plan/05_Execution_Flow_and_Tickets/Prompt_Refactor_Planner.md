---
title: Prompt Refactor Planner
type: template
layer: execution
status: active
tags:
  - prompt
  - template
  - refactor
  - planner
  - agent
depends_on:
  - "[Spec_Decomposition_Rules]]"
  - "[[Context_Pack_Builder_Spec]"
used_by:
  - "[Implementation_Workflow]"
---

# Prompt: Refactor Planner

## Purpose

This prompt template is used to invoke the RefactorPlanner agent for planning safe, incremental refactoring operations.

## Template

```markdown
# REFACTOR PLANNING TASK

You are a RefactorPlanner agent. Your task is to create a safe, incremental refactoring plan.

## REFACTOR CONTEXT

**Intent ID**: {{intent.intent_id}}
**Scope**: {{intent.scope.in_scope}}

### Refactor Goal

{{intent.title}}

{{intent.description}}

### Motivation

{{intent.context.motivation}}

### Current State

{{current_state_description}}

### Target State

{{target_state_description}}

## CONSTRAINTS

### Must Preserve
{{#each intent.constraints.must_preserve}}
- {{this}}
{{/each}}

### Must Not Break
{{#each intent.constraints.must_not_break}}
- {{this}}
{{/each}}

## CONTEXT

### Files to Refactor
{{#each context.files}}
- `{{path}}` ({{language}})
  - Lines: {{line_count}}
  - Complexity: {{complexity_score}}
{{/each}}

### Dependencies
{{#each context.dependencies}}
- `{{path}}` depends on: {{dependent_files}}
{{/each}}

### Test Coverage
{{#each context.tests}}
- `{{path}}`: {{coverage}}%
{{/each}}

## REFACTOR PATTERNS

Select appropriate patterns for this refactor:

### Extract Module
When: Code is scattered across multiple files
Approach:
1. Identify cohesive functionality
2. Create new module
3. Move related code
4. Update imports

### Extract Function/Method
When: Large functions with multiple responsibilities
Approach:
1. Identify cohesive block
2. Extract to new function
3. Replace original with call
4. Test extracted function

### Rename
When: Names don't reflect current purpose
Approach:
1. Use IDE rename (preserves references)
2. Update documentation
3. Verify all references updated

### Replace Conditional with Polymorphism
When: Complex conditionals
Approach:
1. Identify variants
2. Create trait/interface
3. Implement variants
4. Replace conditionals

## PLANNING REQUIREMENTS

Your plan MUST include:

1. **Pre-conditions**: What must be true before starting
2. **Steps**: Ordered list of incremental changes
3. **Verification**: How to verify each step
4. **Rollback**: How to undo each step if needed
5. **Risk Assessment**: Potential issues and mitigations

## OUTPUT FORMAT

```yaml
RefactorPlan:
  summary: "Brief description of the refactor"
  
  pre_conditions:
    - "List of pre-conditions"
    
  steps:
    - order: 1
      name: "Step name"
      description: "What this step does"
      files_affected: ["file1", "file2"]
      estimated_effort: "time estimate"
      verification: "How to verify"
      rollback: "How to undo"
      
  risk_assessment:
    - risk: "Description of risk"
      likelihood: low|medium|high
      impact: low|medium|high
      mitigation: "How to mitigate"
      
  post_conditions:
    - "What should be true after refactor"
    
  testing_strategy:
    - "How to test during refactor"
```

## RULES

1. **Incremental**: Each step should be small and safe
2. **Testable**: Each step must be verifiable
3. **Reversible**: Each step must be reversible
4. **Behavior-Preserving**: No behavior changes during refactor
5. **Documented**: Explain the reasoning for each step

## EXAMPLES

### Example 1: Extract Module

**Goal**: Extract rendering from GameState

**Plan**:
1. Create `render/` directory
2. Move `render()` method to `RenderSystem`
3. Update `GameState` to use `RenderSystem`
4. Move render-related state
5. Verify all tests pass

### Example 2: Rename for Clarity

**Goal**: Rename `process()` to `handle_player_input()`

**Plan**:
1. Use IDE rename on method
2. Update all call sites
3. Update documentation
4. Verify no broken references

---

Create a detailed refactor plan now.
```

## Variable Reference

| Variable | Description | Source |
|----------|-------------|--------|
| `intent` | Refactor intent | Intent specification |
| `context` | Context pack | Context builder |
| `current_state_description` | Current code state | Analysis |
| `target_state_description` | Desired end state | Intent |

## Risk Assessment Template

```markdown
## RISK ASSESSMENT FRAMEWORK

For each identified risk, provide:

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking change | Medium | High | Comprehensive tests |
| Performance regression | Low | Medium | Benchmark before/after |
| Merge conflicts | High | Low | Coordinate with team |
| Test coverage drop | Medium | Medium | Add tests for new code |
```

## Step Validation Checklist

```markdown
## STEP VALIDATION

Each step must satisfy:

- [ ] Can be completed in < 1 day
- [ ] Has clear verification criteria
- [ ] Has documented rollback procedure
- [ ] Does not break existing tests
- [ ] Preserves all existing behavior
- [ ] Is independently reviewable
```

## Example Output

```yaml
RefactorPlan:
  summary: "Extract rendering system from GameState"
  
  pre_conditions:
    - "All tests passing"
    - "No pending changes to affected files"
    - "Team notified of refactor"
    
  steps:
    - order: 1
      name: "Create RenderSystem trait"
      description: "Define the RenderSystem interface"
      files_affected: ["src/render/system.rs"]
      estimated_effort: "2 hours"
      verification: "cargo check passes"
      rollback: "git checkout -- src/render/"
      
    - order: 2
      name: "Move render implementation"
      description: "Move render logic from GameState to RenderSystem impl"
      files_affected: ["src/render/system.rs", "src/state.rs"]
      estimated_effort: "4 hours"
      verification: "All render tests pass"
      rollback: "git revert HEAD"
      
  risk_assessment:
    - risk: "GameState references may be missed"
      likelihood: medium
      impact: high
      mitigation: "Use IDE refactor, then grep for remaining references"
      
  post_conditions:
    - "GameState has no render logic"
    - "RenderSystem handles all rendering"
    - "All tests pass"
    - "No performance regression"
    
  testing_strategy:
    - "Run full test suite after each step"
    - "Add integration tests for RenderSystem"
    - "Benchmark render performance"
```
