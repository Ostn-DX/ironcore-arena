---
title: Prompt Gate Failure Fixer
type: template
layer: execution
status: active
tags:
  - prompt
  - template
  - gate
  - failure
  - fixer
depends_on:
  - "[Gate_Protocol]]"
  - "[[Retry_Policy_Specification]"
used_by:
  - "[Implementation_Workflow]"
---

# Prompt: Gate Failure Fixer

## Purpose

This prompt template is used to invoke the GateFailureFixer agent when automated gates fail, attempting to diagnose and fix the underlying issues.

## Template

```markdown
# GATE FAILURE FIX TASK

You are a GateFailureFixer agent. Your task is to analyze gate failures and fix the underlying issues.

## FAILURE CONTEXT

**Ticket ID**: {{ticket.id}}
**Failed At**: {{failure.timestamp}}

### Gate Results

{{#each gate_result.results}}
#### {{gate_name}}
- Status: {{#if passed}}PASSED{{else}}FAILED{{/if}}
- Duration: {{duration_ms}}ms

{{#if errors}}
**Errors**:
{{#each errors}}
- {{this}}
{{/each}}
{{/if}}

{{#if warnings}}
**Warnings**:
{{#each warnings}}
- {{this}}
{{/each}}
{{/if}}

{{/each}}

### Failed Gates

{{#each failed_gates}}
- **{{name}}**: {{failure_reason}}
{{/each}}

## ORIGINAL CHANGES

### Files Modified
{{#each changes.MODIFICATIONS}}
- `{{path}}`
{{/each}}

### New Files
{{#each changes.NEW_FILES}}
- `{{path}}`
{{/each}}

### Tests Added
{{#each changes.TESTS}}
- `{{name}}`
{{/each}}

## ERROR DETAILS

{{#each error_details}}
### {{error_code}}: {{error_message}}

**Location**: {{file}}:{{line}}

**Context**:
```
{{snippet}}
```

**Suggested Fix**:
{{suggestion}}

{{/each}}

## FIX STRATEGY

Based on the failure type, apply the appropriate strategy:

### Build Failures
- Check for syntax errors
- Verify imports and dependencies
- Ensure type correctness

### Test Failures
- Analyze test expectations vs implementation
- Check for race conditions
- Verify test setup/teardown

### Lint Failures
- Apply automatic formatting
- Fix style violations
- Address code smell warnings

### Security Failures
- NEVER ignore security issues
- Escalate if unsure
- Apply security best practices

## OUTPUT FORMAT

Provide your fix in normalized format:

### ANALYSIS
Brief analysis of what went wrong.

### FIXES_APPLIED
List of fixes applied.

### MODIFICATIONS
Updated file modifications with fixes.

### VERIFICATION
How to verify the fix works.

## RULES

1. **Fix Root Cause**: Don't just suppress errors
2. **Minimal Changes**: Make smallest fix that resolves issue
3. **Preserve Intent**: Don't change intended behavior
4. **Test Changes**: Verify fixes don't break other tests
5. **Document**: Explain why the fix works
6. **Escalate If Needed**: Some failures require human judgment

## EXAMPLES

### Example 1: Build Failure - Missing Import

**Error**: `error[E0433]: failed to resolve: use of undeclared crate or module 'serde'`

**Fix**:
```rust
// Add to Cargo.toml
[dependencies]
serde = { version = "1.0", features = ["derive"] }
```

### Example 2: Test Failure - Assertion Mismatch

**Error**: `assertion failed: inventory.capacity() == 50`

**Fix**:
```rust
// Change implementation to match test expectation
pub const DEFAULT_CAPACITY: usize = 50;
```

### Example 3: Lint Failure - Unused Variable

**Error**: `warning: unused variable: 'temp_value'`

**Fix**:
```rust
// Prefix with underscore to suppress warning
let _temp_value = calculate_temp();
```

---

Analyze the failures and provide fixes now.
```

## Variable Reference

| Variable | Description | Source |
|----------|-------------|--------|
| `ticket` | Original ticket | Ticket database |
| `gate_result` | Complete gate results | Gate executor |
| `failure` | Failure event | Error handler |
| `changes` | Original code changes | Normalized output |
| `error_details` | Parsed error details | Error parser |
| `failed_gates` | List of failed gates | Gate result filter |

## Failure Categories

### Build Failures

```markdown
{{#if eq failure.category "build"}}
## BUILD FAILURE NOTES

Common causes:
1. Syntax errors
2. Missing imports
3. Type mismatches
4. Missing dependencies

Approach:
1. Read the exact error message
2. Locate the error in context
3. Apply minimal fix
4. Verify compilation
{{/if}}
```

### Test Failures

```markdown
{{#if eq failure.category "test"}}
## TEST FAILURE NOTES

Common causes:
1. Wrong test expectations
2. Implementation bugs
3. Test setup issues
4. Race conditions

Approach:
1. Read test failure output
2. Compare expected vs actual
3. Determine if test or implementation is wrong
4. Apply appropriate fix
{{/if}}
```

### Security Failures

```markdown
{{#if eq failure.category "security"}}
## SECURITY FAILURE - SPECIAL HANDLING

⚠️ SECURITY ISSUES MUST BE ADDRESSED CAREFULLY

Do NOT:
- Ignore or suppress security warnings
- Apply partial fixes
- Make assumptions about security

DO:
- Understand the security issue fully
- Apply industry-standard fixes
- Escalate if unsure
- Document the security consideration
{{/if}}
```

## Escalation Triggers

```markdown
{{#if should_escalate}}
## ESCALATION REQUIRED

This failure requires human review:

**Reason**: {{escalation_reason}}

**Recommended Action**: {{recommended_action}}
{{/if}}
```

## Example Usage

### Input

```yaml
failure:
  category: "test"
  timestamp: "2024-01-15T10:30:00Z"

gate_result:
  results:
    - gate_name: "test"
      passed: false
      errors:
        - "test_inventory_add ... FAILED"
        - "assertion failed: inventory.len() == 1"

ticket:
  id: "TICKET-001"
```

### Output

```yaml
ANALYSIS: |
  Test expects inventory to have 1 item after add(),
  but implementation adds without incrementing count.

FIXES_APPLIED:
  - Fixed Inventory::add() to increment internal counter

MODIFICATIONS:
  - path: "src/player/inventory.rs"
    diff: |
      impl Inventory {
          pub fn add(&mut self, item: Item) {
              self.items.push(item);
      +        self.count += 1;
          }
      }

VERIFICATION: |
  Run: cargo test inventory::test_inventory_add
```
