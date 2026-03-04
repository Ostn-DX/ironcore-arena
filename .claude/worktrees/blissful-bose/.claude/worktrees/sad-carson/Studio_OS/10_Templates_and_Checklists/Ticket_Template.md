---
title: Ticket_Template
type: template
layer: execution
status: active
tags:
  - template
  - ticket
  - workflow
  - execution
depends_on: []
used_by:
  - "[Daily_Operator_Protocol]"
---

# Ticket Template

## Copy/Paste Block

```markdown
---
title: TICKET-XXX_Descriptive_Name
type: task
layer: execution
status: draft
tags: [implementation, category]
depends_on: []
used_by: []
estimated_cost: $X.XX
actual_cost: $0.00
---

## ID
TICKET-XXX

## Title
Brief, actionable description

## Goal
One sentence objective. What does "done" look like?

## Allowed Files (edit allowlist)
- path/to/file1.gd
- path/to/file2.gd
- data/specific.json

## New Files (if any)
- new_file.gd
- new_file.tscn

## Forbidden Files
- autoload/GameState.gd (unless explicitly allowed)
- scenes/*.tscn (unless explicitly allowed)
- Any files not in allowlist

## Acceptance Criteria
- [ ] AC1: Specific, testable condition
- [ ] AC2: Another specific condition
- [ ] AC3: Edge case handled

## Tests Required
- [ ] test1: What to verify
- [ ] test2: Another verification

## Run Command
```bash
./tools/dev_gate.sh
```

## Notes
- Invariants: See Studio_OS/12_Architectural_Decisions/Architectural_Invariants.md
- Conventions: See Studio_OS/12_Architectural_Decisions/Code_Conventions_Standard.md
- Context: [link to relevant system note]

## Cost Tracking
```yaml
estimated_tokens:
  input: 10000
  output: 20000
estimated_cost: $5.00
model_recommended: kimi-k2.5
max_iterations: 2
```
```

## Allowlist Enforcement Rules

1. **Explicit listing required** - Every editable file must be listed
2. **Wildcard prohibition** - No `src/**/*.gd` patterns
3. **Forbidden explicit** - List what must NOT be touched
4. **New file declaration** - All created files listed upfront

## Retry Limits

| Failure Type | Max Retries | Action After |
|--------------|-------------|--------------|
| Syntax error | 2 | Escalate to human |
| Logic error | 3 | Escalate to architect agent |
| Gate failure | 2 | Fix specific failure, re-run |
| Cost overflow | 0 | Halt, human decision |

## Rollback Rules

1. **Pre-integration backup** - Git stash before applying
2. **Per-file rollback** - Can revert single files
3. **Gate failure auto-rollback** - If gate fails, auto-revert
4. **Manual rollback command:**
   ```bash
   git checkout -- path/to/file.gd
   ```

## Checklist (Before Submission)

- [ ] Allowlist contains all necessary files
- [ ] No files listed that shouldn't be touched
- [ ] Acceptance criteria are testable
- [ ] Run command is specified
- [ ] Estimated cost is calculated
- [ ] Related systems are linked

## Related
[[Context_Pack_Spec]]
[[Patch_Protocol]]
[[Output_Normalizer_Spec]]
