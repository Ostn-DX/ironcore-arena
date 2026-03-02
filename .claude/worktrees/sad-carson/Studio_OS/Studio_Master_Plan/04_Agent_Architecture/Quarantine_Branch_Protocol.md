---
title: Quarantine Branch Protocol
type: system
layer: enforcement
status: active
tags:
  - quarantine
  - branch
  - isolation
  - failure
  - review
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Rollback_Protocol]"
used_by:
  - "[Safe_Mode_Behavior]]"
  - "[[Escalation_Triggers]"
---

# Quarantine Branch Protocol

## Purpose

The Quarantine Branch Protocol isolates unstable or failed changes into separate branches for analysis, preventing contamination of the main codebase while preserving work for debugging and potential recovery.

## Core Principles

1. **Isolation**: Failed changes never touch main branches
2. **Preservation**: All work saved for analysis
3. **Transparency**: Clear visibility into quarantined changes
4. **Review Required**: Human review mandatory before reintegration
5. **Expiration**: Quarantined branches expire after set period

## When to Quarantine

### Automatic Quarantine

| Condition | Action |
|-----------|--------|
| 3+ consecutive failures on same task | Auto-quarantine |
| Security vulnerability in generated code | Immediate quarantine |
| Test failure affecting critical path | Auto-quarantine |
| Rollback failure | Immediate quarantine + alert |
| Safe mode triggered | Auto-quarantine recent changes |

### Manual Quarantine

| Condition | Action |
|-----------|--------|
| Suspicious code pattern detected | Manual quarantine |
| Performance regression suspected | Manual quarantine |
| Human review flags concerns | Manual quarantine |

## Quarantine Process

### 1. Create Quarantine Branch

```python
async def create_quarantine_branch(
    source_branch: str,
    task: Task,
    error: Error,
    reason: str
) -> QuarantineBranch:
    """Create a quarantine branch for failed changes."""
    
    # Generate unique quarantine ID
    quarantine_id = generate_quarantine_id(task.id, error.code)
    
    # Create branch name
    branch_name = f"quarantine/{quarantine_id}"
    
    # Create branch from source
    await git_branch(source_branch, branch_name)
    
    # Apply failed changes to quarantine branch
    await apply_changes_to_branch(task.output, branch_name)
    
    # Create quarantine metadata
    quarantine = QuarantineBranch(
        id=quarantine_id,
        branch_name=branch_name,
        source_branch=source_branch,
        task_id=task.id,
        error=error,
        reason=reason,
        created_at=now(),
        expires_at=now() + QUARANTINE_TTL,
        status="active"
    )
    
    # Save metadata
    await save_quarantine_metadata(quarantine)
    
    # Notify
    await notify_quarantine_created(quarantine)
    
    return quarantine
```

### 2. Quarantine Branch Structure

```
quarantine/{quarantine_id}/
├── quarantine.yaml          # Metadata
├── error_report.yaml        # Detailed error info
├── task_output/             # Original agent output
│   ├── NEW_FILES/
│   ├── MODIFICATIONS/
│   └── TESTS/
├── analysis/                # Analysis artifacts
│   ├── static_analysis.log
│   ├── test_results.log
│   └── dependency_graph.dot
└── review/                  # Review notes
    ├── initial_assessment.md
    └── resolution_notes.md
```

### 3. Quarantine Metadata

```yaml
QuarantineBranch:
  id: "Q20240115_001"
  branch_name: "quarantine/Q20240115_001"
  source_branch: "main"
  
  task:
    id: "task_12345"
    agent: "CodeGenerator"
    intent: "Add player inventory system"
    
  error:
    code: "TEST_FAILURE"
    message: "3 tests failed in inventory module"
    stack_trace: "..."
    
  reason: "Automatic quarantine after 3 consecutive failures"
  
  timeline:
    created_at: "2024-01-15T10:30:00Z"
    expires_at: "2024-01-29T10:30:00Z"
    reviewed_at: null
    resolved_at: null
    
  status: active|under_review|resolved|expired
  
  resolution:
    type: fixed|discarded|merged
    notes: ""
    resolved_by: ""
```

## Quarantine Lifecycle

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Created  │────▶│  Active  │────▶│ Under    │
│          │     │          │     │ Review   │
└──────────┘     └──────────┘     └────┬─────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
              ┌──────────┐      ┌──────────┐      ┌──────────┐
              │  Fixed   │      │ Discarded│      │  Merged  │
              │  (retry) │      │          │      │          │
              └────┬─────┘      └──────────┘      └──────────┘
                   │
                   ▼
              ┌──────────┐
              │ Resolved │
              └──────────┘
```

## Quarantine Review Process

### 1. Initial Assessment

```python
async def perform_initial_assessment(quarantine: QuarantineBranch):
    """Perform automated initial assessment."""
    assessment = {
        "quarantine_id": quarantine.id,
        "timestamp": now(),
        "findings": []
    }
    
    # Run static analysis
    static_results = await run_static_analysis(quarantine.branch_name)
    assessment["findings"].extend(static_results.issues)
    
    # Run tests
    test_results = await run_tests(quarantine.branch_name)
    assessment["test_failures"] = test_results.failures
    
    # Analyze dependencies
    dep_analysis = await analyze_dependencies(quarantine)
    assessment["dependency_issues"] = dep_analysis.issues
    
    # Determine root cause category
    assessment["root_cause_category"] = categorize_root_cause(assessment)
    
    # Save assessment
    await save_assessment(quarantine.id, assessment)
    
    return assessment
```

### 2. Root Cause Categories

| Category | Description | Resolution |
|----------|-------------|------------|
| Context_Issue | Insufficient/wrong context | Rebuild context, retry |
| Agent_Error | Agent generated incorrect code | Fix agent, retry |
| Test_Issue | Tests incorrect or outdated | Fix tests, retry |
| Dependency_Issue | Dependency conflict | Resolve dependencies |
| Environment_Issue | Environment problem | Fix environment |
| Intent_Ambiguity | Human intent unclear | Clarify intent |

### 3. Human Review

```yaml
HumanReview:
  quarantine_id: string
  reviewer: string
  reviewed_at: ISO8601
  
  assessment:
    root_cause: string
    severity: low|medium|high|critical
    effort_to_fix: small|medium|large
    
  recommendation:
    action: fix_and_retry|discard|merge_as_is|escalate
    notes: string
    
  follow_up:
    required: boolean
    assigned_to: string
    due_date: ISO8601
```

## Quarantine Resolution

### Resolution Types

#### 1. Fixed and Retry

```python
async def resolve_fixed_and_retry(quarantine: QuarantineBranch):
    """Fix issues and retry the task."""
    # 1. Create fix branch from quarantine
    fix_branch = f"fix/{quarantine.id}"
    await git_branch(quarantine.branch_name, fix_branch)
    
    # 2. Apply fixes (manual or automated)
    await apply_fixes(fix_branch, quarantine.assessment)
    
    # 3. Run verification
    if await verify_fix(fix_branch):
        # 4. Merge to main
        await merge_to_main(fix_branch)
        
        # 5. Mark quarantine resolved
        await mark_resolved(quarantine, "fixed")
    else:
        raise FixVerificationFailed()
```

#### 2. Discarded

```python
async def resolve_discarded(quarantine: QuarantineBranch, reason: str):
    """Discard quarantined changes."""
    # 1. Archive quarantine for learning
    await archive_quarantine(quarantine)
    
    # 2. Delete branch
    await git_delete_branch(quarantine.branch_name)
    
    # 3. Mark resolved
    await mark_resolved(quarantine, "discarded", reason)
    
    # 4. Log for pattern analysis
    log_discard_pattern(quarantine, reason)
```

#### 3. Merged As-Is

```python
async def resolve_merged_as_is(quarantine: QuarantineBranch):
    """Merge quarantined changes despite issues."""
    # 1. Human approval required
    if not await verify_human_approval(quarantine):
        raise HumanApprovalRequired()
    
    # 2. Merge to main
    await merge_branch(quarantine.branch_name, "main")
    
    # 3. Mark resolved
    await mark_resolved(quarantine, "merged")
    
    # 4. Create follow-up ticket
    await create_follow_up_ticket(quarantine)
```

## Quarantine Monitoring

### Dashboard Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| Active Quarantines | Number of active quarantines | > 5 |
| Quarantine Rate | % of tasks quarantined | > 10% |
| Avg Time to Resolve | Mean resolution time | > 3 days |
| Expired Quarantines | Quarantines past TTL | > 0 |

### Quarantine Health Score

```python
def calculate_quarantine_health() -> float:
    """Calculate overall quarantine health (0-100)."""
    active = count_active_quarantines()
    rate = calculate_quarantine_rate()
    avg_time = calculate_avg_resolution_time()
    expired = count_expired_quarantines()
    
    score = 100
    score -= active * 5  # -5 per active quarantine
    score -= rate * 50   # -50 at 100% rate
    score -= avg_time * 2  # -2 per day
    score -= expired * 20  # -20 per expired
    
    return max(0, score)
```

## Quarantine Cleanup

### Expired Quarantine Handling

```python
async def cleanup_expired_quarantines():
    """Clean up quarantines past their expiration date."""
    expired = find_expired_quarantines()
    
    for quarantine in expired:
        # Archive before deletion
        await archive_quarantine(quarantine)
        
        # Delete branch
        await git_delete_branch(quarantine.branch_name)
        
        # Mark expired
        await mark_expired(quarantine)
        
        logger.info(f"Cleaned up expired quarantine: {quarantine.id}")
```

### Archival

```python
async def archive_quarantine(quarantine: QuarantineBranch):
    """Archive quarantine for future analysis."""
    archive_path = f"archives/quarantines/{quarantine.id}"
    
    # Copy all artifacts
    await copy_directory(quarantine.path, archive_path)
    
    # Add to quarantine database
    await add_to_quarantine_db(quarantine)
    
    # Update analytics
    await update_quarantine_analytics(quarantine)
```

## Integration with Other Systems

### Safe Mode
Quarantine triggers safe mode:

```python
async def handle_quarantine_creation(quarantine):
    if count_recent_quarantines(hours=1) > SAFE_MODE_THRESHOLD:
        await activate_safe_mode()
```

### Escalation
Critical quarantines escalate to humans:

```python
async def handle_critical_quarantine(quarantine):
    if quarantine.error.severity == "critical":
        await escalate_to_human(quarantine)
```

### Pattern Analysis
Quarantine data feeds into failure pattern analysis:

```python
async def analyze_quarantine_patterns():
    """Analyze quarantine patterns for systemic issues."""
    patterns = await find_common_patterns(
        time_window=days(30)
    )
    
    for pattern in patterns:
        if pattern.frequency > PATTERN_THRESHOLD:
            await create_systemic_issue_ticket(pattern)
```
