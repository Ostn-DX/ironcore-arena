---
title: Ticket Intake Management
type: system
layer: execution
status: active
tags:
  - ticket
  - intake
  - backlog
  - management
  - queue
depends_on:
  - "[Intent_Specification_Format]]"
  - "[[Spec_Decomposition_Rules]"
used_by:
  - "[OpenClaw_Daily_Work_Loop]]"
  - "[[Automated_Prioritization_Rules]"
---

# Ticket Intake Management

## Purpose

Ticket Intake Management defines how new work enters the OpenClaw system—from initial intent submission through ticket creation, validation, and placement in the backlog.

## Intake Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Intent  │───▶│Decompose │───▶│ Validate │───▶│  Queue   │
│  Submit  │    │  Intent  │    │  Tickets │    │  for     │
│          │    │          │    │          │    │Execution │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

## Intake Methods

### 1. Human-Submitted Intents

```python
async def submit_intent(intent: Intent) -> SubmissionResult:
    """Submit new intent from human."""
    
    # 1. Validate intent
    validation = validate_intent(intent)
    if not validation.valid:
        return SubmissionResult(
            status="rejected",
            errors=validation.errors
        )
    
    # 2. Store intent
    intent.intent_id = generate_intent_id()
    intent.submitted_at = now()
    await store_intent(intent)
    
    # 3. Queue for decomposition
    await decomposition_queue.submit(intent)
    
    return SubmissionResult(
        status="accepted",
        intent_id=intent.intent_id,
        estimated_completion=estimate_completion(intent)
    )
```

### 2. Automated Issue Detection

```python
async def detect_and_create_issues():
    """Automatically detect issues and create tickets."""
    
    # Check for failing tests
    failing_tests = await detect_failing_tests()
    for test in failing_tests:
        if is_new_failure(test):
            await create_bugfix_intent(
                title=f"Fix failing test: {test.name}",
                description=f"Test {test.name} started failing",
                priority="high"
            )
    
    # Check for security alerts
    security_issues = await detect_security_issues()
    for issue in security_issues:
        await create_bugfix_intent(
            title=f"Security: {issue.title}",
            description=issue.description,
            priority="critical"
        )
    
    # Check for performance regressions
    regressions = await detect_performance_regressions()
    for reg in regressions:
        await create_optimization_intent(
            title=f"Performance: {reg.metric} regression",
            description=f"{reg.metric} degraded by {reg.percentage}%",
            priority="medium"
        )
```

### 3. Scheduled Maintenance

```python
async def create_scheduled_maintenance():
    """Create scheduled maintenance tickets."""
    
    # Dependency updates
    outdated_deps = await check_outdated_dependencies()
    if outdated_deps:
        await submit_intent(Intent(
            type="chore",
            title="Update dependencies",
            description=f"Update {len(outdated_deps)} outdated dependencies",
            priority="low"
        ))
    
    # Documentation refresh
    if await should_refresh_docs():
        await submit_intent(Intent(
            type="docs",
            title="Refresh documentation",
            description="Update outdated documentation",
            priority="low"
        ))
```

## Intent Decomposition

### Queue for Decomposition

```python
async def process_decomposition_queue():
    """Process intents waiting for decomposition."""
    
    queue = await decomposition_queue.get_pending()
    
    for intent in queue:
        try:
            # Decompose intent into tickets
            tickets = await spec_decomposer.decompose(intent)
            
            # Validate tickets
            for ticket in tickets:
                validation = validate_ticket(ticket)
                if not validation.valid:
                    logger.error(f"Invalid ticket: {validation.errors}")
                    continue
                
                # Add to backlog
                await add_to_backlog(ticket)
            
            # Mark intent as processed
            await mark_intent_decomposed(intent.intent_id, tickets)
            
        except Exception as e:
            logger.error(f"Decomposition failed for {intent.intent_id}: {e}")
            await mark_decomposition_failed(intent.intent_id, str(e))
```

## Backlog Management

### Backlog Structure

```yaml
Backlog:
  version: "1.0"
  last_updated: ISO8601
  
  tickets:
    - id: "TICKET-001"
      status: pending
      priority: high
      created_at: "2024-01-15T10:00:00Z"
      dependencies: []
      
    - id: "TICKET-002"
      status: blocked
      priority: medium
      created_at: "2024-01-15T10:05:00Z"
      dependencies: ["TICKET-001"]
      blocked_reason: "Waiting for TICKET-001"
```

### Adding to Backlog

```python
async def add_to_backlog(ticket: Ticket):
    """Add ticket to backlog."""
    
    # Set initial status
    ticket.status = "pending"
    
    # Check dependencies
    if ticket.scope.dependencies:
        deps_satisfied = await check_dependencies_satisfied(ticket)
        if not deps_satisfied:
            ticket.status = "blocked"
            ticket.blocked_reason = "Dependencies not satisfied"
    
    # Add to backlog
    backlog = await load_backlog()
    backlog.tickets.append(ticket)
    
    # Save backlog
    await save_backlog(backlog)
    
    # Notify
    logger.info(f"Added {ticket.id} to backlog")
```

### Dependency Management

```python
async def check_dependencies_satisfied(ticket: Ticket) -> bool:
    """Check if ticket dependencies are satisfied."""
    
    for dep_id in ticket.scope.dependencies:
        dep = await get_ticket(dep_id)
        
        if not dep:
            logger.warning(f"Dependency {dep_id} not found for {ticket.id}")
            return False
        
        if dep.status != "completed":
            return False
    
    return True

async def check_unblocked_dependencies(completed_ticket: Ticket):
    """Check if completing a ticket unblocks others."""
    
    backlog = await load_backlog()
    
    for ticket in backlog.tickets:
        if ticket.status == "blocked":
            if completed_ticket.id in ticket.scope.dependencies:
                # Check if all dependencies now satisfied
                if await check_dependencies_satisfied(ticket):
                    ticket.status = "pending"
                    ticket.blocked_reason = None
                    logger.info(f"Unblocked {ticket.id}")
```

## Backlog Queries

### Common Queries

```python
class BacklogQueries:
    async def get_pending(self) -> [Ticket]:
        """Get all pending tickets."""
        backlog = await load_backlog()
        return [t for t in backlog.tickets if t.status == "pending"]
    
    async def get_blocked(self) -> [Ticket]:
        """Get all blocked tickets."""
        backlog = await load_backlog()
        return [t for t in backlog.tickets if t.status == "blocked"]
    
    async def get_by_priority(self, priority: str) -> [Ticket]:
        """Get tickets by priority."""
        backlog = await load_backlog()
        return [t for t in backlog.tickets if t.priority == priority]
    
    async def get_by_type(self, type: str) -> [Ticket]:
        """Get tickets by type."""
        backlog = await load_backlog()
        return [t for t in backlog.tickets if t.type == type]
    
    async def get_ready_for_execution(self) -> [Ticket]:
        """Get tickets ready for execution."""
        pending = await self.get_pending()
        return [t for t in pending if await can_execute(t)]
```

## Backlog Maintenance

### Cleanup Tasks

```python
async def run_backlog_maintenance():
    """Run periodic backlog maintenance."""
    
    backlog = await load_backlog()
    
    # Remove stale tickets
    stale_threshold = now() - timedelta(days=30)
    backlog.tickets = [
        t for t in backlog.tickets
        if t.created_at > stale_threshold or t.status != "pending"
    ]
    
    # Archive completed tickets
    completed = [t for t in backlog.tickets if t.status == "completed"]
    for ticket in completed:
        await archive_ticket(ticket)
        backlog.tickets.remove(ticket)
    
    # Update priorities
    for ticket in backlog.tickets:
        if ticket.status == "pending":
            ticket.priority = await recalculate_priority(ticket)
    
    await save_backlog(backlog)
```

### Metrics

```python
async def get_backlog_metrics() -> BacklogMetrics:
    """Get backlog metrics."""
    
    backlog = await load_backlog()
    
    return BacklogMetrics(
        total_tickets=len(backlog.tickets),
        pending=len([t for t in backlog.tickets if t.status == "pending"]),
        blocked=len([t for t in backlog.tickets if t.status == "blocked"]),
        in_progress=len([t for t in backlog.tickets if t.status == "active"]),
        avg_age_days=calculate_avg_age(backlog.tickets),
        by_priority=count_by_priority(backlog.tickets),
        by_type=count_by_type(backlog.tickets)
    )
```

## Integration with Other Systems

### Daily Work Loop
Backlog feeds [[OpenClaw_Daily_Work_Loop|daily work loop]]:

```python
status = await backlog_queries.get_status()
ticket = await select_next_ticket(status.pending)
```

### Prioritization
Backlog uses [[Automated_Prioritization_Rules|prioritization rules]]:

```python
priority = await prioritization_rules.calculate(ticket)
```

### Spec Decomposition
Intents decomposed via [[Spec_Decomposition_Rules|spec decomposition]]:

```python
tickets = await spec_decomposer.decompose(intent)
```
