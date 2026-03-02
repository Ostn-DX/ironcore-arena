---
title: Safe Mode Behavior
type: system
layer: enforcement
status: active
tags:
  - safe-mode
  - failure
  - recovery
  - protection
  - emergency
depends_on:
  - "[Escalation_Triggers]]"
  - "[[Rollback_Protocol]]"
  - "[[Quarantine_Branch_Protocol]"
used_by:
  - "[OpenClaw_Daily_Work_Loop]"
---

# Safe Mode Behavior

## Purpose

Safe Mode is a protective state that OpenClaw enters when repeated failures indicate systemic issues. It halts autonomous operation to prevent further damage and allows for human investigation.

## Safe Mode Triggers

### Automatic Triggers

```python
SAFE_MODE_TRIGGERS = {
    "repeated_failures": {
        "threshold": 5,
        "window_minutes": 30,
        "description": "5+ failures in 30 minutes"
    },
    "consecutive_rollback_failures": {
        "threshold": 2,
        "description": "2+ consecutive rollback failures"
    },
    "critical_gate_failure": {
        "threshold": 1,
        "description": "Critical gate failure"
    },
    "resource_exhaustion": {
        "threshold": 0.9,
        "description": "90%+ resource utilization"
    },
    "quarantine_overflow": {
        "threshold": 10,
        "description": "10+ active quarantines"
    }
}
```

### Trigger Detection

```python
async def check_safe_mode_triggers() -> Optional[Trigger]:
    """Check if any safe mode trigger is activated."""
    
    # Check repeated failures
    recent_failures = await count_failures(minutes=30)
    if recent_failures >= SAFE_MODE_TRIGGERS["repeated_failures"]["threshold"]:
        return Trigger(
            type="repeated_failures",
            count=recent_failures
        )
    
    # Check rollback failures
    rollback_failures = await count_rollback_failures()
    if rollback_failures >= SAFE_MODE_TRIGGERS["consecutive_rollback_failures"]["threshold"]:
        return Trigger(
            type="rollback_failures",
            count=rollback_failures
        )
    
    # Check resource utilization
    resources = await check_resource_utilization()
    if resources > SAFE_MODE_TRIGGERS["resource_exhaustion"]["threshold"]:
        return Trigger(
            type="resource_exhaustion",
            utilization=resources
        )
    
    # Check quarantine count
    quarantines = await count_active_quarantines()
    if quarantines >= SAFE_MODE_TRIGGERS["quarantine_overflow"]["threshold"]:
        return Trigger(
            type="quarantine_overflow",
            count=quarantines
        )
    
    return None
```

## Safe Mode Activation

### Activation Process

```python
async def activate_safe_mode(trigger: Trigger):
    """Activate safe mode."""
    
    logger.critical(f"Activating safe mode due to: {trigger.type}")
    
    # 1. Set safe mode flag
    await set_safe_mode_flag(True)
    
    # 2. Pause all active work
    await pause_active_work()
    
    # 3. Preserve current state
    await preserve_system_state()
    
    # 4. Quarantine recent changes
    await quarantine_recent_changes()
    
    # 5. Notify humans
    await notify_safe_mode_activation(trigger)
    
    # 6. Start monitoring
    await start_safe_mode_monitoring()
    
    logger.info("Safe mode activated")
```

### State Preservation

```python
async def preserve_system_state():
    """Preserve current system state for analysis."""
    
    state = SystemState(
        timestamp=now(),
        active_tickets=await get_active_tickets(),
        recent_failures=await get_recent_failures(),
        resource_usage=await get_resource_usage(),
        queue_state=await get_queue_state(),
        recent_changes=await get_recent_changes()
    )
    
    # Save state
    await save_system_state(state)
    
    # Create incident report
    await create_incident_report(state)
```

## Safe Mode Behavior

### Restricted Operations

```python
SAFE_MODE_RESTRICTIONS = {
    "new_ticket_execution": False,  # Don't start new work
    "automatic_retries": False,     # Don't auto-retry failures
    "automatic_merges": False,      # Don't auto-merge
    "context_building": True,       # Allow context building (read-only)
    "status_queries": True,         # Allow status queries
    "human_initiated_work": True,   # Allow human-initiated work
    "rollback_operations": True,    # Allow rollbacks
}
```

### Allowed Operations

```python
async def check_operation_allowed(operation: str) -> bool:
    """Check if operation is allowed in safe mode."""
    
    if not await is_safe_mode_active():
        return True
    
    allowed = SAFE_MODE_RESTRICTIONS.get(operation, False)
    
    if not allowed:
        logger.warning(f"Operation '{operation}' blocked in safe mode")
    
    return allowed
```

## Safe Mode Monitoring

### Health Checks

```python
async def run_safe_mode_health_checks():
    """Run health checks while in safe mode."""
    
    while await is_safe_mode_active():
        # Check system stability
        stability = await check_system_stability()
        
        # Check resource recovery
        resources = await check_resource_recovery()
        
        # Check failure rate
        failure_rate = await check_failure_rate()
        
        # Log status
        logger.info(
            f"Safe mode health: "
            f"stability={stability}, "
            f"resources={resources}, "
            f"failure_rate={failure_rate}"
        )
        
        # Check if recovery possible
        if await can_exit_safe_mode():
            logger.info("System stable, safe mode exit possible")
        
        await asyncio.sleep(60)  # Check every minute
```

### Recovery Indicators

```python
async def can_exit_safe_mode() -> bool:
    """Check if safe mode can be exited."""
    
    # No failures in last 15 minutes
    recent_failures = await count_failures(minutes=15)
    if recent_failures > 0:
        return False
    
    # Resource utilization below 70%
    resources = await check_resource_utilization()
    if resources > 0.7:
        return False
    
    # All quarantines resolved
    quarantines = await count_active_quarantines()
    if quarantines > 0:
        return False
    
    # Human approval (if required)
    if SAFE_MODE_REQUIRES_HUMAN_APPROVAL:
        if not await has_human_approval():
            return False
    
    return True
```

## Safe Mode Exit

### Exit Process

```python
async def exit_safe_mode(user: Optional[str] = None):
    """Exit safe mode and resume normal operation."""
    
    logger.info(f"Exiting safe mode (initiated by: {user or 'auto'})")
    
    # 1. Verify system stability
    if not await can_exit_safe_mode():
        raise SafeModeExitNotAllowed("System not stable enough")
    
    # 2. Clear safe mode flag
    await set_safe_mode_flag(False)
    
    # 3. Resume paused work
    await resume_paused_work()
    
    # 4. Clear quarantines if resolved
    await clear_resolved_quarantines()
    
    # 5. Reset failure counters
    await reset_failure_counters()
    
    # 6. Notify humans
    await notify_safe_mode_exit(user)
    
    # 7. Resume normal operation
    await resume_daily_work_loop()
    
    logger.info("Safe mode exited, normal operation resumed")
```

### Gradual Recovery

```python
async def gradual_recovery():
    """Gradually resume operations after safe mode."""
    
    # Phase 1: Read-only operations
    await enable_read_only_operations()
    await asyncio.sleep(300)  # Wait 5 minutes
    
    # Phase 2: Low-risk operations
    await enable_low_risk_operations()
    await asyncio.sleep(300)
    
    # Phase 3: Normal operations
    await enable_normal_operations()
```

## Safe Mode Dashboard

### Real-Time Status

```yaml
SafeModeDashboard:
  status: active
  activated_at: "2024-01-15T10:30:00Z"
  activated_by: "repeated_failures"
  
  trigger_details:
    type: "repeated_failures"
    count: 7
    threshold: 5
    
  current_state:
    paused_tickets: 3
    active_quarantines: 4
    resource_utilization: 0.65
    failure_rate_15m: 0.0
    
  recovery_indicators:
    no_recent_failures: true
    resources_normal: true
    quarantines_resolved: false
    human_approved: false
    
  exit_readiness: "pending_quarantines"
```

## Post-Safe Mode Analysis

### Incident Report

```python
async def generate_incident_report() -> IncidentReport:
    """Generate report on safe mode incident."""
    
    state = await load_preserved_state()
    
    return IncidentReport(
        incident_id=generate_id(),
        triggered_at=state.timestamp,
        trigger_type=state.trigger_type,
        
        root_cause_analysis=await analyze_root_cause(state),
        
        affected_tickets=[t.id for t in state.active_tickets],
        
        recovery_actions_taken=await get_recovery_actions(),
        
        recommendations=await generate_recommendations(state),
        
        lessons_learned=await extract_lessons(state)
    )
```

## Prevention Measures

### Proactive Detection

```python
async def proactive_safe_mode_prevention():
    """Take action before safe mode is needed."""
    
    # Monitor failure rate
    failure_rate = await calculate_failure_rate(minutes=10)
    
    if failure_rate > 0.2:  # 20% failure rate
        logger.warning("High failure rate detected, taking preventive action")
        
        # Reduce concurrent execution
        await reduce_concurrent_limit()
        
        # Increase retry delays
        await increase_retry_delays()
        
        # Alert team
        await alert_preventive_action(failure_rate)
```

## Integration with Other Systems

### Escalation
Safe mode triggers [[Escalation_Triggers|escalation]]:

```python
await execute_escalation(
    trigger=SAFE_MODE_ESCALATION,
    event=SafeModeEvent(),
    context=get_system_context()
)
```

### Quarantine
Safe mode uses [[Quarantine_Branch_Protocol|quarantine]]:

```python
await quarantine_branch_protocol.quarantine_recent_changes()
```

### Rollback
Safe mode may trigger [[Rollback_Protocol|rollback]]:

```python
if await should_rollback_recent_changes():
    await rollback_protocol.rollback_recent()
```
