---
title: OpenClaw Daily Work Loop
type: system
layer: execution
status: active
tags:
  - openclaw
  - daily
  - loop
  - autonomous
  - operation
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Ticket_Intake_Management]]"
  - "[[Implementation_Workflow]"
used_by:
  - "[Automated_Prioritization_Rules]]"
  - "[[Escalation_Triggers]"
---

# OpenClaw Daily Work Loop

## Purpose

The Daily Work Loop defines how OpenClaw operates autonomously, continuously processing the backlog, executing tickets, and managing the development pipeline with minimal human intervention.

## Loop Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      DAILY WORK LOOP                         │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │  Check   │───▶│ Prioritize│───▶│  Select  │              │
│  │ Backlog  │    │  Tickets  │    │  Ticket  │              │
│  └──────────┘    └──────────┘    └────┬─────┘              │
│                                        │                     │
│  ┌──────────┐    ┌──────────┐    ┌─────┴─────┐              │
│  │  Update  │◀───│  Report  │◀───│  Execute  │              │
│  │  Status  │    │  Result  │    │  Workflow │              │
│  └──────────┘    └──────────┘    └───────────┘              │
│                                        │                     │
│                              ┌─────────┴─────────┐           │
│                              ▼                   ▼           │
│                        ┌──────────┐      ┌──────────┐       │
│                        │ Success  │      │  Failure │       │
│                        │ (Next)   │      │ (Retry/  │       │
│                        │          │      │ Escalate)│       │
│                        └──────────┘      └──────────┘       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Loop Phases

### Phase 1: Backlog Check

```python
async def check_backlog() -> BacklogStatus:
    """Check current state of ticket backlog."""
    
    # Load backlog
    backlog = await load_backlog()
    
    # Categorize tickets
    status = BacklogStatus(
        pending=[t for t in backlog if t.status == "pending"],
        blocked=[t for t in backlog if t.status == "blocked"],
        in_progress=[t for t in backlog if t.status == "active"],
        failed=[t for t in backlog if t.status == "failed"],
        completed_today=await get_completed_today()
    )
    
    # Log status
    logger.info(f"Backlog: {len(status.pending)} pending, "
                f"{len(status.blocked)} blocked, "
                f"{len(status.in_progress)} in progress")
    
    return status
```

### Phase 2: Prioritization

```python
async def prioritize_tickets(
    tickets: [Ticket],
    status: BacklogStatus
) -> [Ticket]:
    """Prioritize tickets for execution."""
    
    # Apply prioritization rules
    scored = []
    for ticket in tickets:
        score = await calculate_priority_score(ticket, status)
        scored.append((ticket, score))
    
    # Sort by score (descending)
    scored.sort(key=lambda x: x[1], reverse=True)
    
    # Return prioritized list
    return [t for t, _ in scored]
```

### Phase 3: Ticket Selection

```python
async def select_next_ticket(
    prioritized: [Ticket],
    status: BacklogStatus
) -> Optional[Ticket]:
    """Select next ticket to execute."""
    
    # Check for in-progress tickets first
    if status.in_progress:
        # Continue with existing work
        return status.in_progress[0]
    
    # Check resource availability
    if not await has_available_resources():
        logger.info("No resources available, waiting...")
        return None
    
    # Check concurrent execution limits
    active_count = len(status.in_progress)
    if active_count >= MAX_CONCURRENT_TICKETS:
        logger.info(f"Max concurrent tickets ({MAX_CONCURRENT_TICKETS}) reached")
        return None
    
    # Select highest priority available ticket
    for ticket in prioritized:
        if await can_execute(ticket):
            return ticket
    
    return None
```

### Phase 4: Workflow Execution

```python
async def execute_ticket_workflow(ticket: Ticket) -> ExecutionResult:
    """Execute full workflow for a ticket."""
    
    logger.info(f"Executing ticket: {ticket.id}")
    
    # Mark as in-progress
    await update_ticket_status(ticket.id, "active")
    
    try:
        # Execute implementation workflow
        result = await implementation_workflow.execute(ticket)
        
        if result.status == "success":
            await update_ticket_status(ticket.id, "completed")
            await notify_success(ticket, result)
            
        elif result.status == "partial":
            await update_ticket_status(ticket.id, "completed_with_warnings")
            await notify_partial(ticket, result)
            
        elif result.status == "retry":
            await update_ticket_status(ticket.id, "pending")
            await schedule_retry(ticket, result)
            
        else:  # failed
            await update_ticket_status(ticket.id, "failed")
            await handle_failure(ticket, result)
        
        return result
        
    except Exception as e:
        logger.error(f"Unexpected error executing {ticket.id}: {e}")
        await update_ticket_status(ticket.id, "failed")
        await handle_unexpected_error(ticket, e)
        return ExecutionResult(status="error", error=str(e))
```

### Phase 5: Status Update

```python
async def update_status(
    ticket: Ticket,
    result: ExecutionResult
):
    """Update system status after execution."""
    
    # Update ticket in backlog
    await update_backlog(ticket, result)
    
    # Update metrics
    await update_metrics(ticket, result)
    
    # Update dashboard
    await update_dashboard()
    
    # Check for blocked tickets that may now be unblocked
    await check_unblocked_dependencies(ticket)
```

### Phase 6: Result Reporting

```python
async def report_result(
    ticket: Ticket,
    result: ExecutionResult
):
    """Report execution result."""
    
    report = ExecutionReport(
        ticket_id=ticket.id,
        status=result.status,
        duration_ms=result.duration_ms,
        files_changed=result.files_changed,
        tests_added=result.tests_added,
        timestamp=now()
    )
    
    # Log to audit trail
    await log_to_audit_trail(report)
    
    # Send notifications
    if result.status in ["failed", "error"]:
        await notify_failure(ticket, result)
    
    # Update daily summary
    await update_daily_summary(report)
```

## Main Loop

```python
async def daily_work_loop():
    """Main autonomous work loop."""
    
    logger.info("OpenClaw daily work loop started")
    
    while True:
        try:
            # 1. Check backlog
            status = await check_backlog()
            
            # 2. Prioritize tickets
            prioritized = await prioritize_tickets(
                status.pending + status.failed,
                status
            )
            
            # 3. Select next ticket
            ticket = await select_next_ticket(prioritized, status)
            
            if ticket:
                # 4. Execute workflow
                result = await execute_ticket_workflow(ticket)
                
                # 5. Update status
                await update_status(ticket, result)
                
                # 6. Report result
                await report_result(ticket, result)
            
            else:
                # No work available
                logger.info("No tickets ready for execution")
                
                # Check for human input
                await check_for_human_input()
                
                # Brief pause before next iteration
                await asyncio.sleep(LOOP_PAUSE_SECONDS)
            
            # Check for shutdown signal
            if await should_shutdown():
                logger.info("Shutdown signal received, exiting loop")
                break
                
        except Exception as e:
            logger.error(f"Error in work loop: {e}")
            await asyncio.sleep(ERROR_PAUSE_SECONDS)
    
    logger.info("OpenClaw daily work loop stopped")
```

## Loop Configuration

```yaml
WorkLoopConfig:
  timing:
    loop_pause_seconds: 30
    error_pause_seconds: 60
    max_execution_time_minutes: 30
    
  limits:
    max_concurrent_tickets: 3
    max_retries_per_ticket: 3
    daily_ticket_limit: 20
    
  monitoring:
    health_check_interval_seconds: 300
    status_report_interval_minutes: 60
```

## Health Checks

```python
async def run_health_check() -> HealthStatus:
    """Run system health check."""
    
    checks = {
        "backlog": await check_backlog_health(),
        "resources": await check_resource_availability(),
        "agents": await check_agent_health(),
        "gates": await check_gate_health(),
    }
    
    healthy = all(c.healthy for c in checks.values())
    
    if not healthy:
        logger.warning(f"Health check failed: {checks}")
        
        # Check if safe mode needed
        if should_activate_safe_mode(checks):
            await activate_safe_mode()
    
    return HealthStatus(
        healthy=healthy,
        checks=checks,
        timestamp=now()
    )
```

## Daily Summary

```python
async def generate_daily_summary() -> DailySummary:
    """Generate end-of-day summary."""
    
    return DailySummary(
        date=date.today(),
        tickets_completed=await count_completed_today(),
        tickets_failed=await count_failed_today(),
        tickets_pending=await count_pending(),
        files_changed=await count_files_changed_today(),
        tests_added=await count_tests_added_today(),
        avg_execution_time=await calculate_avg_execution_time(),
        success_rate=await calculate_success_rate(),
        issues=await get_issues_requiring_attention()
    )
```

## Integration with Other Systems

### Ticket Intake
Loop pulls from [[Ticket_Intake_Management|ticket intake]]:

```python
backlog = await ticket_intake.get_backlog()
```

### Prioritization
Uses [[Automated_Prioritization_Rules|prioritization rules]]:

```python
score = await prioritization_rules.calculate_score(ticket)
```

### Escalation
Triggers [[Escalation_Triggers|escalation]] when needed:

```python
if result.status == "failed":
    await escalation_triggers.check_and_escalate(ticket, result)
```

### Safe Mode
Activates [[Safe_Mode_Behavior|safe mode]] on critical failures:

```python
if critical_failure_detected():
    await safe_mode.activate()
```
