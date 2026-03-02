---
title: Patch_Protocol
type: template
layer: execution
status: active
tags:
  - template
  - patch
  - integration
  - commands
depends_on: []
used_by:
  - "[Daily_Operator_Protocol]"
---

# Patch Protocol

## Purpose
Exact steps for applying agent output to repository. Eliminates integration guesswork.

## Pre-Integration Checklist

```bash
# 1. Verify gate passes on current state
./tools/dev_gate.sh
# Must return 0

# 2. Create backup branch
git checkout -b backup/pre-TICKET-XXX
git checkout -

# 3. Stash any uncommitted changes
git stash push -m "pre-TICKET-XXX"

# 4. Validate agent output
python tools/normalize_agent_output.py TICKET-XXX
# Must return 0
```

## Integration Steps

### Step 1: Copy New Files
```bash
cp -r agent_runs/TICKET-XXX/NEW_FILES/* project/
```

Verify:
```bash
ls -la project/src/ai/new_file.gd  # Should exist
```

### Step 2: Apply Modifications
```bash
# Option A: If .patch files exist
for patch in agent_runs/TICKET-XXX/MODIFICATIONS/*.patch; do
    git apply "$patch"
done

# Option B: If before/after files exist
# Follow INTEGRATION_GUIDE.md instructions
```

### Step 3: Copy Tests
```bash
cp -r agent_runs/TICKET-XXX/TESTS/* project/tests/
```

### Step 4: Verify Changes
```bash
# Check modified files
git status

# Review diff
git diff --stat

# Check specific files
cat project/src/ai/tactical.gd | head -50
```

### Step 5: Run Gate
```bash
./tools/dev_gate.sh
```

**If PASS:** Continue to commit
**If FAIL:** Go to Failure Response

## Success Path

```bash
# 1. Stage changes
git add -A

# 2. Commit with ticket reference
git commit -m "TICKET-XXX: Brief description

- Change 1
- Change 2

Closes TICKET-XXX"

# 3. Push
git push origin main

# 4. Update ticket status
# Mark as complete in tracking
```

## Failure Response

### Gate Failure

```bash
# 1. Identify failure stage
# Look at gate output

# 2. Option A: Fix forward
# Edit files directly to fix failure
# Re-run gate

# 3. Option B: Rollback
git checkout -- .  # Revert all changes
git clean -fd       # Remove new files

# 4. Return to agent with specific error
# Include gate output in feedback
```

### Rollback Commands

```bash
# Soft rollback (keep files)
git checkout -- path/to/file.gd

# Hard rollback (full revert)
git checkout -- .
git clean -fd

# Restore from backup branch
git checkout backup/pre-TICKET-XXX
```

## Safety Rules

1. **Never force push**
2. **Always run gate before commit**
3. **Keep backup until confirmed working**
4. **Document any manual fixes**

## Post-Integration

```bash
# Verify on clean checkout
git stash pop  # If you stashed earlier
./tools/dev_gate.sh  # Verify still passes

# Clean up
rm -rf agent_runs/TICKET-XXX/
rm -rf tools/context_packs/TICKET-XXX/

# Update cost tracking
# Add actual_cost to ticket frontmatter
```

## Related
[[Ticket_Template]]
[[Gate_Failure_Response_Playbook]]
