---
title: Prompt Ticket Executor
type: template
layer: execution
status: active
tags:
  - prompt
  - template
  - ticket
  - executor
  - agent
depends_on:
  - "[Ticket_Template_Spec]]"
  - "[[Context_Pack_Builder_Spec]"
used_by:
  - "[Implementation_Workflow]"
---

# Prompt: Ticket Executor

## Purpose

This prompt template is used by OpenClaw to invoke the CodeGenerator agent for executing implementation tickets.

## Template

```markdown
# TICKET EXECUTION TASK

You are a CodeGenerator agent for an AI-Native Game Studio. Your task is to implement the following ticket.

## TICKET INFORMATION

**Ticket ID**: {{ticket.id}}
**Type**: {{ticket.type}}
**Priority**: {{ticket.priority}}
**Complexity**: {{ticket.complexity}}

**Title**: {{ticket.title}}

**Description**:
{{ticket.description}}

## REQUIREMENTS

### Functional Requirements
{{#each ticket.requirements.functional}}
- {{this}}
{{/each}}

### Non-Functional Requirements
{{#each ticket.requirements.non_functional}}
- {{this}}
{{/each}}

### Acceptance Criteria
{{#each ticket.requirements.acceptance_criteria}}
- [ ] {{this}}
{{/each}}

## CONSTRAINTS

### Must Preserve
{{#each ticket.constraints.must_preserve}}
- {{this}}
{{/each}}

### Must Not Break
{{#each ticket.constraints.must_not_break}}
- {{this}}
{{/each}}

## CONTEXT

You have been provided with a context pack containing relevant files for this task.

**Files in Context**:
{{#each context.files}}
- `{{path}}` ({{language}}, {{size_bytes}} bytes)
{{/each}}

### Key Files to Modify
{{#each ticket.scope.target_files}}
- `{{this}}`
{{/each}}

## CODING STANDARDS

{{coding_standards}}

## TEST REQUIREMENTS

{{#if ticket.testing.unit_tests_required}}
- Unit tests required: Yes
- Coverage target: {{ticket.testing.coverage_target}}%
{{/if}}

{{#if ticket.testing.integration_tests_required}}
- Integration tests required: Yes
{{/if}}

## OUTPUT FORMAT

You MUST produce output in the following normalized format:

### NEW_FILES
List any new files created, with complete content.

### MODIFICATIONS
List modifications to existing files with unified diffs.

### TESTS
List test cases created.

### INTEGRATION_GUIDE
Provide step-by-step integration instructions.

## RULES

1. **Complete Implementation**: Provide fully working code, not stubs
2. **Follow Standards**: Adhere to project coding standards
3. **Include Tests**: Write comprehensive tests for new code
4. **Document**: Add inline comments for complex logic
5. **Preserve Behavior**: Don't break existing functionality
6. **Type Safety**: Ensure type correctness
7. **Error Handling**: Include appropriate error handling
8. **Performance**: Consider performance implications

## EXAMPLES

{{#each examples}}
### Example {{@index}}: {{title}}

**Task**: {{task}}

**Solution**:
```{{language}}
{{code}}
```

{{/each}}

---

Execute this ticket now. Provide your complete implementation in the specified format.
```

## Variable Reference

| Variable | Description | Source |
|----------|-------------|--------|
| `ticket` | Complete ticket object | Ticket database |
| `context` | Context pack for this task | Context builder |
| `coding_standards` | Project coding standards | Standards file |
| `examples` | Relevant code examples | Example database |

## Example Usage

### Input

```yaml
ticket:
  id: "TICKET-001"
  type: feature
  priority: high
  title: "Add player inventory system"
  description: "Implement inventory that can hold items"
  requirements:
    functional:
      - "Add items to inventory"
      - "Remove items from inventory"
  scope:
    target_files:
      - "src/player/inventory.rs"
```

### Output

```yaml
NEW_FILES:
  - path: "src/player/inventory.rs"
    content: |
      pub struct Inventory {
          items: Vec<Item>,
      }
      // ... full implementation

MODIFICATIONS:
  - path: "src/player/mod.rs"
    diff: |
      +pub mod inventory;

TESTS:
  - name: "test_inventory_add"
    code: |
      #[test]
      fn test_inventory_add() {
          // ... test code
      }

INTEGRATION_GUIDE: |
  1. Add new file: src/player/inventory.rs
  2. Update src/player/mod.rs to include module
  3. Run tests: cargo test inventory
```

## Customization Points

### Language-Specific Variants

```markdown
{{#if eq language "rust"}}
## RUST-SPECIFIC NOTES
- Use `Result<T, E>` for fallible operations
- Prefer `&str` over `String` for parameters
- Use `#[derive(Debug)]` for debuggability
{{/if}}

{{#if eq language "typescript"}}
## TYPESCRIPT-SPECIFIC NOTES
- Use strict type annotations
- Prefer interfaces over types
- Include JSDoc comments
{{/if}}
```

### Complexity-Based Adjustments

```markdown
{{#if eq complexity "simple"}}
This is a simple task. Focus on clean, straightforward implementation.
{{/if}}

{{#if eq complexity "complex"}}
This is a complex task. Break down your approach:
1. First, describe your design
2. Then implement step by step
3. Include comprehensive tests
{{/if}}
```
