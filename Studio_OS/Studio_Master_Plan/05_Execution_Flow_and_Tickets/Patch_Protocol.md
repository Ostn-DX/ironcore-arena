---
title: Patch Protocol
type: system
layer: execution
status: active
tags:
  - patch
  - diff
  - apply
  - changes
  - integration
depends_on:
  - "[Output_Normalizer_Spec]]"
  - "[[Ticket_Template_Spec]"
used_by:
  - "[Implementation_Workflow]]"
  - "[[Merge_Release_Workflow]"
---

# Patch Protocol

## Purpose

The Patch Protocol defines how changes are packaged, validated, and applied to the codebase. It ensures reliable, traceable integration of agent-generated changes.

## Patch Types

### 1. Forward Patch

Normal change application:

```yaml
ForwardPatch:
  version: "1.0"
  patch_id: uuid
  created_at: ISO8601
  
  source:
    task_id: string
    agent: string
    base_commit: sha
    
  changes:
    new_files: [NewFile]
    modifications: [FileModification]
    deletions: [FileDeletion]
    
  metadata:
    total_files: integer
    lines_added: integer
    lines_removed: integer
```

### 2. Rollback Patch

Undo changes:

```yaml
RollbackPatch:
  version: "1.0"
  patch_id: uuid
  source_patch: uuid  # Original patch being rolled back
  
  changes:
    # Reverse of forward patch
    files_to_restore: [FileRestore]
    files_to_delete: [FileDelete]  # New files from forward
```

### 3. Hotfix Patch

Emergency fix:

```yaml
HotfixPatch:
  version: "1.0"
  patch_id: uuid
  severity: critical|high
  
  changes:
    modifications: [FileModification]
    
  validation:
    minimal_tests: [string]
    skip_full_suite: boolean
```

## Patch Creation

### From Normalized Output

```python
def create_patch_from_output(
    output: NormalizedOutput,
    base_commit: str
) -> ForwardPatch:
    """Create patch from agent normalized output."""
    
    patch = ForwardPatch(
        patch_id=generate_uuid(),
        source=PatchSource(
            task_id=output.task_id,
            agent=output.agent_type,
            base_commit=base_commit
        ),
        changes=PatchChanges(),
        metadata=PatchMetadata()
    )
    
    # Add new files
    for new_file in output.NEW_FILES:
        patch.changes.new_files.append(NewFile(
            path=new_file.path,
            content=new_file.content,
            mode="100644"
        ))
        patch.metadata.lines_added += new_file.line_count
    
    # Add modifications
    for mod in output.MODIFICATIONS:
        patch.changes.modifications.append(FileModification(
            path=mod.path,
            original_hash=mod.original.hash,
            new_hash=mod.modified.hash,
            diff=mod.diff
        ))
        patch.metadata.lines_added += mod.lines_added
        patch.metadata.lines_removed += mod.lines_removed
    
    patch.metadata.total_files = (
        len(patch.changes.new_files) +
        len(patch.changes.modifications)
    )
    
    return patch
```

### Patch File Format

```diff
# Patch file format (unified diff)
From: agent@openclaw
Date: 2024-01-15T10:30:00Z
Subject: [PATCH] Add player inventory system

---
 src/player/inventory.rs | 85 +++++++++++++++++++
 src/player/mod.rs       |  5 ++-
 2 files changed, 88 insertions(+), 2 deletions(-)

diff --git a/src/player/inventory.rs b/src/player/inventory.rs
new file mode 100644
index 0000000..abc1234
--- /dev/null
+++ b/src/player/inventory.rs
@@ -0,0 +1,85 @@
+use std::collections::HashMap;
+
+pub struct Inventory {
+    items: HashMap<String, u32>,
+    capacity: u32,
+}
+
+impl Inventory {
+    pub fn new(capacity: u32) -> Self {
+        Self {
+            items: HashMap::new(),
+            capacity,
+        }
+    }
+    // ... more code
+}

diff --git a/src/player/mod.rs b/src/player/mod.rs
index def4567..ghi8901 100644
--- a/src/player/mod.rs
+++ b/src/player/mod.rs
@@ -1,5 +1,8 @@
 pub mod movement;
+pub mod inventory;
+
+pub use inventory::Inventory;
 
 pub struct Player {
     name: String,
+    inventory: Inventory,
 }
```

## Patch Validation

### Pre-Application Checks

```python
def validate_patch(patch: Patch, target_branch: str) -> ValidationResult:
    """Validate patch before application."""
    errors = []
    
    # 1. Check base commit matches
    current_commit = get_current_commit(target_branch)
    if patch.source.base_commit != current_commit:
        errors.append(
            f"Base commit mismatch: "
            f"expected {patch.source.base_commit}, "
            f"got {current_commit}"
        )
    
    # 2. Verify file states for modifications
    for mod in patch.changes.modifications:
        current_hash = hash_file(mod.path)
        if current_hash != mod.original_hash:
            errors.append(
                f"File {mod.path} has changed since patch creation"
            )
    
    # 3. Check for conflicts
    for new_file in patch.changes.new_files:
        if file_exists(new_file.path):
            errors.append(f"File already exists: {new_file.path}")
    
    # 4. Validate file paths
    for change in all_changes(patch):
        if not is_valid_path(change.path):
            errors.append(f"Invalid path: {change.path}")
    
    # 5. Size limits
    total_size = sum(len(f.content) for f in patch.changes.new_files)
    if total_size > MAX_PATCH_SIZE:
        errors.append(f"Patch exceeds size limit: {total_size}")
    
    return ValidationResult(valid=len(errors) == 0, errors=errors)
```

## Patch Application

### Safe Application Process

```python
async def apply_patch(
    patch: Patch,
    target_branch: str,
    options: ApplyOptions
) -> ApplyResult:
    """Safely apply patch to target branch."""
    
    # 1. Pre-validation
    validation = validate_patch(patch, target_branch)
    if not validation.valid:
        return ApplyResult(
            status="failed",
            errors=validation.errors
        )
    
    # 2. Create backup branch
    backup_branch = f"backup/{target_branch}/{patch.patch_id}"
    await create_branch(target_branch, backup_branch)
    
    # 3. Apply changes
    applied = []
    try:
        # Apply new files
        for new_file in patch.changes.new_files:
            await write_file(new_file.path, new_file.content)
            applied.append(("create", new_file.path))
        
        # Apply modifications
        for mod in patch.changes.modifications:
            await apply_diff(mod.path, mod.diff)
            applied.append(("modify", mod.path))
        
        # Apply deletions
        for deletion in patch.changes.deletions:
            await delete_file(deletion.path)
            applied.append(("delete", deletion.path))
    
    except Exception as e:
        # Rollback partial application
        await rollback_partial(applied)
        return ApplyResult(status="failed", error=str(e))
    
    # 4. Post-application validation
    if not await validate_application(patch):
        await rollback_partial(applied)
        return ApplyResult(status="failed", error="Post-validation failed")
    
    # 5. Commit
    commit_hash = await commit_changes(
        message=generate_commit_message(patch),
        author=patch.source.agent
    )
    
    return ApplyResult(
        status="success",
        commit_hash=commit_hash,
        files_changed=len(applied)
    )
```

### Conflict Resolution

```python
async def resolve_conflicts(
    patch: Patch,
    conflicts: [Conflict]
) -> ResolvedPatch:
    """Resolve merge conflicts in patch."""
    
    resolved = PatchChanges()
    
    for conflict in conflicts:
        if conflict.type == "both_modified":
            # Attempt automatic merge
            merged = await auto_merge(conflict)
            if merged:
                resolved.modifications.append(merged)
            else:
                # Flag for manual resolution
                conflict.requires_manual_resolution = True
                
        elif conflict.type == "deleted_by_us":
            # Keep their changes
            resolved.modifications.append(conflict.their_changes)
            
        elif conflict.type == "deleted_by_them":
            # Keep our changes
            resolved.modifications.append(conflict.our_changes)
    
    return ResolvedPatch(
        original=patch,
        resolved=resolved,
        manual_conflicts=[c for c in conflicts if c.requires_manual_resolution]
    )
```

## Patch Storage

### Patch Archive

```
patches/
  {patch_id}/
    patch.yaml           # Patch metadata
    patch.diff           # Unified diff
    validation_report.yaml
    application_log.yaml
```

### Patch Index

```yaml
PatchIndex:
  version: "1.0"
  patches:
    - patch_id: uuid
      task_id: string
      status: pending|applied|failed|rolled_back
      created_at: ISO8601
      applied_at: ISO8601
      commit_hash: sha
```

## Patch Rollback

### Rollback Procedure

```python
async def rollback_patch(patch_id: str, reason: str):
    """Rollback an applied patch."""
    
    # 1. Load original patch
    patch = load_patch(patch_id)
    
    # 2. Create rollback patch
    rollback = create_rollback_patch(patch)
    
    # 3. Apply rollback
    result = await apply_patch(rollback, get_current_branch())
    
    # 4. Update patch status
    await update_patch_status(patch_id, "rolled_back", reason)
    
    # 5. Log rollback
    log_rollback(patch_id, reason, result.commit_hash)
```

## Integration with Other Systems

### Gate Protocol
Patches validated by [[Gate_Protocol|gates]]:

```python
async def gate_validate_patch(patch: Patch) -> GateResult:
    """Run gate checks on patch."""
    return await gate_executor.validate(
        patch=patch,
        checks=["build", "test", "lint"]
    )
```

### Review Workflow
Patches reviewed in [[Review_Gate_Workflow|review]]:

```python
async def submit_for_review(patch: Patch):
    """Submit patch for review."""
    await review_queue.submit(
        patch=patch,
        priority=patch.priority
    )
```

### Merge Workflow
Patches merged via [[Merge_Release_Workflow|merge workflow]]:

```python
async def merge_patch(patch: Patch, target: str):
    """Merge patch to target branch."""
    await merge_workflow.execute(
        patch=patch,
        target_branch=target,
        strategy="squash"
    )
```
