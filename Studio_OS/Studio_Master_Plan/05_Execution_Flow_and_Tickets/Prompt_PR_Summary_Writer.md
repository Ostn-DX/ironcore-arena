---
title: Prompt PR Summary Writer
type: template
layer: execution
status: active
tags:
  - prompt
  - template
  - pr
  - summary
  - documentation
depends_on:
  - "[Output_Normalizer_Spec]]"
  - "[[Merge_Release_Workflow]"
used_by: []
---

# Prompt: PR Summary Writer

## Purpose

This prompt template is used to generate clear, comprehensive pull request descriptions from ticket and change information.

## Template

```markdown
# PR SUMMARY WRITING TASK

You are a PR Summary Writer agent. Your task is to create a clear, informative pull request description.

## CHANGE INFORMATION

**Ticket ID**: {{ticket.id}}
**Type**: {{ticket.type}}
**Priority**: {{ticket.priority}}

**Title**: {{ticket.title}}

**Description**:
{{ticket.description}}

## CHANGES SUMMARY

### Files Changed
{{#each changes.MODIFICATIONS}}
- Modified: `{{path}}` ({{lines_changed}} lines)
{{/each}}

{{#each changes.NEW_FILES}}
- Added: `{{path}}` ({{line_count}} lines)
{{/each}}

### Tests Added
{{#each changes.TESTS}}
- `{{name}}` ({{type}})
{{/each}}

### Statistics
- Files changed: {{stats.files_changed}}
- Lines added: {{stats.lines_added}}
- Lines removed: {{stats.lines_removed}}
- Test coverage: {{stats.coverage}}%

## REQUIREMENTS ADDRESSED

{{#each ticket.requirements.functional}}
- ✅ {{this}}
{{/each}}

## OUTPUT FORMAT

Generate a PR description in the following format:

```markdown
## Summary

Brief one-paragraph summary of the changes.

## Changes

### Added
- List of new features/files

### Modified
- List of modifications

### Removed
- List of removals (if any)

## Testing

- How the changes were tested
- Test coverage information

## Checklist

- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Code follows style guidelines

## Related

- Links to related tickets/issues
```

## STYLE GUIDE

### PR Title Format

```
[<TYPE>] <Brief description>

Types:
- [FEATURE] New feature
- [BUGFIX] Bug fix
- [REFACTOR] Code refactoring
- [DOCS] Documentation
- [TEST] Test changes
- [CHORE] Maintenance
```

### Description Guidelines

1. **Be concise**: Focus on what changed and why
2. **Be specific**: Include concrete details
3. **Be actionable**: Help reviewers understand the change
4. **Be complete**: Don't omit important context

### Example PR Titles

- ✅ "[FEATURE] Add player inventory system"
- ✅ "[BUGFIX] Fix memory leak in particle system"
- ❌ "Fix stuff"
- ❌ "Update code"

### Example Descriptions

**Good**:
```markdown
## Summary

Adds a complete inventory system that allows players to collect,
store, and use items during gameplay.

## Changes

### Added
- `Inventory` struct with add/remove/capacity management
- Item stacking for stackable items
- UI components for inventory display
- Persistence layer for saving/loading inventory

### Modified
- `Player` struct now includes `inventory` field
- Save/load system handles inventory data

## Testing

- 15 unit tests covering all inventory operations
- Integration tests for save/load
- Manual testing in-game
- Coverage: 87%

## Checklist

- [x] Tests added
- [x] Documentation updated
- [x] No breaking changes
```

**Bad**:
```markdown
Added inventory stuff.
Tests pass.
```

---

Generate the PR description now.
```

## Variable Reference

| Variable | Description | Source |
|----------|-------------|--------|
| `ticket` | Original ticket | Ticket database |
| `changes` | Normalized changes | Output normalizer |
| `stats` | Change statistics | Stats calculator |

## Output Sections

### Summary Section

```markdown
## Summary

{{generated_summary}}
```

Requirements:
- 1-3 sentences
- Captures the "what" and "why"
- No implementation details

### Changes Section

```markdown
## Changes

### Added
{{#each new_features}}
- {{description}}
{{/each}}

### Modified
{{#each modifications}}
- {{description}}
{{/each}}

### Removed
{{#each removals}}
- {{description}}
{{/each}}
```

### Testing Section

```markdown
## Testing

{{test_summary}}

- Unit tests: {{unit_test_count}}
- Integration tests: {{integration_test_count}}
- Coverage: {{coverage}}%
```

### Checklist Section

```markdown
## Checklist

- [{{#if tests_added}}x{{else}} {{/if}}] Tests added/updated
- [{{#if docs_updated}}x{{else}} {{/if}}] Documentation updated
- [{{#if no_breaking}}x{{else}} {{/if}}] No breaking changes
- [x] Code follows style guidelines
```

## Type-Specific Templates

### Feature PR

```markdown
## Summary

This PR implements {{ticket.title}}, adding {{feature_description}}.

## Motivation

{{intent.context.motivation}}

## Implementation Notes

{{implementation_details}}

## Usage Example

```rust
// Example code showing how to use the new feature
```
```

### Bugfix PR

```markdown
## Summary

Fixes {{ticket.title}} by {{fix_description}}.

## Root Cause

{{root_cause_analysis}}

## Fix

{{fix_description}}

## Verification

- [x] Bug reproduction test added
- [x] Fix verified with reproduction case
- [x] Regression tests pass
```

### Refactor PR

```markdown
## Summary

Refactors {{ticket.title}} to improve {{improvement_area}}.

## Changes

{{refactor_changes}}

## Behavior Preservation

- [x] All existing tests pass
- [x] No public API changes
- [x] Performance maintained

## Migration Notes

{{#if migration_needed}}
{{migration_instructions}}
{{else}}
No migration needed.
{{/if}}
```

## Example Output

### Input

```yaml
ticket:
  id: "TICKET-001"
  type: feature
  title: "Add player inventory system"
  description: "Implement inventory for items"

changes:
  NEW_FILES:
    - path: "src/player/inventory.rs"
      line_count: 85
  MODIFICATIONS:
    - path: "src/player/mod.rs"
      lines_changed: 5
  TESTS:
    - name: "test_inventory_add"
    - name: "test_inventory_remove"

stats:
  files_changed: 2
  lines_added: 90
  lines_removed: 0
  coverage: 87
```

### Output

```markdown
[FEATURE] Add player inventory system

## Summary

This PR implements a complete player inventory system that allows
collecting, storing, and using items during gameplay.

## Changes

### Added
- `Inventory` struct with capacity management
- Methods for adding/removing items
- Item stacking for stackable items
- Unit tests for all operations

### Modified
- `Player` struct now includes `inventory` field

## Testing

- 8 unit tests covering add/remove/capacity operations
- Integration test for inventory persistence
- Coverage: 87%

## Checklist

- [x] Tests added/updated
- [x] Documentation updated
- [x] No breaking changes
- [x] Code follows style guidelines

## Related

- Closes TICKET-001
```
