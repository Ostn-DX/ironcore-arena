---
title: Rollback Protocol
type: system
layer: enforcement
status: active
tags:
  - rollback
  - undo
  - recovery
  - safety
  - state
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Output_Normalizer_Spec]"
used_by:
  - "[Retry_Policy_Specification]]"
  - "[[Safe_Mode_Behavior]"
---

# Rollback Protocol

## Purpose

The Rollback Protocol provides a reliable mechanism to undo changes when agent execution fails, ensuring the system can recover to a known good state without data loss or corruption.

## Core Principles

1. **Atomicity**: Rollback either completes fully or not at all
2. **Reversibility**: Every change must have a corresponding undo
3. **Safety First**: When in doubt, rollback
4. **Audit Trail**: All rollbacks logged with reason
5. **Fast Recovery**: Minimize downtime during rollback

## Rollback Triggers

### Automatic Triggers

| Condition | Severity | Action |
|-----------|----------|--------|
| Max retries exceeded | High | Auto-rollback |
| Gate failure (critical) | High | Auto-rollback |
| Security vulnerability detected | Critical | Immediate rollback |
| Data corruption detected | Critical | Immediate rollback |
| Test suite failure (critical path) | High | Auto-rollback |

### Manual Triggers

| Condition | Action |
|-----------|--------|
| Human review rejection | Manual rollback |
| Post-merge issue discovered | Manual rollback |
| Performance regression | Manual rollback |

## Rollback Levels

### 1. Task-Level Rollback

Undo changes from a single failed task:

```python
async def rollback_task(task_id: str, reason: str):
    """Rollback a single task's changes."""
    # 1. Load task output
    output = load_normalized_output(task_id)
    
    # 2. Create rollback patch
    rollback_patch = create_rollback_patch(output)
    
    # 3. Apply rollback
    await apply_patch(rollback_patch)
    
    # 4. Verify rollback
    verify_rollback(task_id)
    
    # 5. Log rollback
    log_rollback(task_id, reason, rollback_patch)
```

### 2. Graph-Level Rollback

Undo all changes from a command graph execution:

```python
async def rollback_graph(graph_id: str, reason: str):
    """Rollback all tasks in a command graph."""
    # 1. Get execution order (reverse for rollback)
    tasks = get_graph_tasks(graph_id, reverse=True)
    
    # 2. Rollback each task
    for task in tasks:
        await rollback_task(task.id, f"Graph rollback: {reason}")
    
    # 3. Clean up any intermediate state
    cleanup_graph_state(graph_id)
```

### 3. Branch-Level Rollback

Reset branch to last known good state:

```python
async def rollback_branch(branch: str, target_commit: str, reason: str):
    """Rollback entire branch to specific commit."""
    # 1. Create backup branch
    backup_branch = f"backup/{branch}/{timestamp()}"
    await git_branch(branch, backup_branch)
    
    # 2. Reset to target
    await git_reset_hard(branch, target_commit)
    
    # 3. Verify branch state
    verify_branch_state(branch, target_commit)
    
    # 4. Log rollback
    log_branch_rollback(branch, target_commit, reason)
```

## Rollback Patch Creation

### From NEW_FILES

```python
def create_rollback_for_new_files(new_files: [NewFile]) -> Patch:
    """Create patch to delete newly created files."""
    deletions = []
    
    for file in new_files:
        deletions.append({
            "operation": "delete",
            "path": file.path,
            "content": None
        })
    
    return Patch(
        type="rollback",
        operations=deletions,
        description=f"Delete {len(new_files)} new files"
    )
```

### From MODIFICATIONS

```python
def create_rollback_for_modifications(mods: [FileModification]) -> Patch:
    """Create patch to revert file modifications."""
    reversions = []
    
    for mod in mods:
        reversions.append({
            "operation": "modify",
            "path": mod.path,
            "content": mod.original.content,
            "hash": mod.original.hash
        })
    
    return Patch(
        type="rollback",
        operations=reversions,
        description=f"Revert {len(mods)} file modifications"
    )
```

### Combined Rollback Patch

```python
def create_rollback_patch(output: NormalizedOutput) -> RollbackPatch:
    """Create complete rollback patch from normalized output."""
    operations = []
    
    # Reverse order: delete new files first, then revert modifications
    # (This prevents conflicts with files that were both created and modified)
    
    # 1. Delete new files (in reverse creation order)
    for file in reversed(output.NEW_FILES):
        operations.append(DeleteOperation(path=file.path))
    
    # 2. Revert modifications (in reverse modification order)
    for mod in reversed(output.MODIFICATIONS):
        operations.append(RevertOperation(
            path=mod.path,
            original_content=mod.original.content,
            original_hash=mod.original.hash
        ))
    
    # 3. Remove tests
    for test in reversed(output.TESTS):
        operations.append(DeleteOperation(path=test.file_path))
    
    return RollbackPatch(
        version="1.0",
        source_task=output.task_id,
        operations=operations,
        created_at=now(),
        reason=None  # Filled in at apply time
    )
```

## Rollback Application

### Safe Application Process

```python
async def apply_rollback_patch(patch: RollbackPatch, reason: str) -> Result:
    """Safely apply rollback patch."""
    patch.reason = reason
    
    # 1. Pre-check: Verify all files exist as expected
    for op in patch.operations:
        if not verify_precondition(op):
            raise RollbackPreconditionFailed(op)
    
    # 2. Create backup
    backup = create_backup(patch)
    
    # 3. Apply operations
    applied = []
    try:
        for op in patch.operations:
            await apply_operation(op)
            applied.append(op)
    except Exception as e:
        # Partial failure - attempt recovery
        logger.error(f"Partial rollback failure: {e}")
        await recover_from_partial_rollback(applied, backup)
        raise RollbackFailed(e)
    
    # 4. Verify rollback
    if not verify_rollback_complete(patch):
        await recover_from_partial_rollback(applied, backup)
        raise RollbackVerificationFailed()
    
    # 5. Log success
    log_rollback_success(patch)
    
    return Success()
```

### Operation Types

```python
class DeleteOperation:
    """Delete a file created during the task."""
    path: str
    
    async def apply(self):
        if os.path.exists(self.path):
            os.remove(self.path)
            logger.info(f"Deleted: {self.path}")

class RevertOperation:
    """Revert a file to its original state."""
    path: str
    original_content: str
    original_hash: str
    
    async def apply(self):
        # Verify current state
        current_hash = hash_file(self.path)
        
        # Write original content
        with open(self.path, 'w') as f:
            f.write(self.original_content)
        
        logger.info(f"Reverted: {self.path}")
```

## Rollback Verification

### Verification Steps

```python
def verify_rollback_complete(patch: RollbackPatch) -> bool:
    """Verify rollback was applied correctly."""
    for op in patch.operations:
        if isinstance(op, DeleteOperation):
            if os.path.exists(op.path):
                logger.error(f"File still exists after rollback: {op.path}")
                return False
        
        elif isinstance(op, RevertOperation):
            current_hash = hash_file(op.path)
            if current_hash != op.original_hash:
                logger.error(f"File not reverted correctly: {op.path}")
                return False
    
    return True
```

### Post-Rollback Checks

```python
async def post_rollback_checks():
    """Run checks after rollback to ensure system health."""
    # 1. Build check
    if not await run_build():
        raise PostRollbackBuildFailed()
    
    # 2. Test check (critical tests only)
    if not await run_critical_tests():
        raise PostRollbackTestFailed()
    
    # 3. Lint check
    if not await run_linter():
        logger.warning("Lint issues after rollback")
    
    logger.info("Post-rollback checks passed")
```

## Rollback Storage

### Rollback Log

```yaml
RollbackLog:
  rollback_id: uuid
  timestamp: ISO8601
  
  trigger:
    type: automatic|manual
    reason: string
    source_task: string
    source_graph: string
  
  patch:
    operations_count: integer
    files_affected: [string]
    
  result:
    status: success|partial|failed
    duration_ms: integer
    error: string  # If failed
```

### Rollback Archive

```
rollbacks/
  {rollback_id}/
    rollback_log.yaml
    rollback_patch.yaml
    backup/
      {files}  # Pre-rollback backup
    verification/
      pre_rollback_state.yaml
      post_rollback_state.yaml
```

## Integration with Other Systems

### Retry Policy
When max retries exceeded, trigger rollback:

```python
async def handle_task_failure(task, error):
    if is_max_retries_exceeded(error):
        await rollback_protocol.rollback_task(
            task_id=task.id,
            reason=f"Max retries exceeded: {error}"
        )
```

### Safe Mode
Critical failures trigger safe mode after rollback:

```python
async def handle_critical_failure(task, error):
    await rollback_task(task.id, f"Critical failure: {error}")
    
    if is_critical_error(error):
        activate_safe_mode()
```

### Quarantine
Failed changes may be quarantined:

```python
async def rollback_with_quarantine(task, error):
    await rollback_task(task.id, error)
    
    # Move to quarantine for analysis
    await quarantine_branch_protocol.create(
        task=task,
        error=error
    )
```

## Rollback Best Practices

1. **Test Rollbacks**: Regularly test rollback procedures
2. **Backup First**: Always backup before rollback
3. **Verify After**: Always verify system state post-rollback
4. **Log Everything**: Comprehensive logging for debugging
5. **Monitor**: Alert on rollback frequency
6. **Review**: Periodic review of rollback causes
