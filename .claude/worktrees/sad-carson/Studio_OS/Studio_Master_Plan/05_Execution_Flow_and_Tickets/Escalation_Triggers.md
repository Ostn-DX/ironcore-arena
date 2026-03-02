---
title: Escalation Triggers
type: system
layer: enforcement
status: active
tags:
  - escalation
  - triggers
  - alerts
  - human
  - intervention
depends_on:
  - "[OpenClaw_Daily_Work_Loop]]"
  - "[[Retry_Policy_Specification]"
used_by:
  - "[Safe_Mode_Behavior]"
---

# Escalation Triggers

## Purpose

Escalation Triggers define the conditions under which OpenClaw interrupts human operators, ensuring critical issues receive immediate attention while minimizing unnecessary interruptions.

## Escalation Levels

### Level 1: Notification (Non-Blocking)

Informs humans of noteworthy events without requiring immediate action.

**Triggers:**
- Ticket completed successfully
- Minor gate failure (auto-fixed)
- Performance degradation detected
- Unusual pattern detected

### Level 2: Alert (Attention Required)

Requires human awareness but not immediate action.

**Triggers:**
- Multiple consecutive failures on same task
- Security vulnerability detected
- Test coverage drop below threshold
- Dependency conflict detected

### Level 3: Urgent (Action Required Soon)

Requires human action within a defined timeframe.

**Triggers:**
- Max retries exceeded
- Rollback failed
- Critical gate failure
- Data integrity issue

### Level 4: Emergency (Immediate Action Required)

Requires immediate human intervention.

**Triggers:**
- Production incident
- Security breach
- Data loss detected
- System in safe mode

## Trigger Definitions

### Critical Error Triggers

```python
CRITICAL_TRIGGERS = {
    "security_vulnerability": {
        "level": 4,
        "message": "Security vulnerability detected in generated code",
        "immediate": True,
        "channels": ["pager", "email", "slack"]
    },
    "data_loss_detected": {
        "level": 4,
        "message": "Potential data loss detected",
        "immediate": True,
        "channels": ["pager", "email"]
    },
    "production_incident": {
        "level": 4,
        "message": "Production incident detected",
        "immediate": True,
        "channels": ["pager", "phone"]
    }
}
```

### Failure Triggers

```python
FAILURE_TRIGGERS = {
    "max_retries_exceeded": {
        "level": 3,
        "message": "Max retries exceeded for ticket",
        "threshold": 1,
        "cooldown_minutes": 30,
        "channels": ["email", "slack"]
    },
    "rollback_failed": {
        "level": 3,
        "message": "Rollback operation failed",
        "immediate": True,
        "channels": ["email", "slack"]
    },
    "consecutive_failures": {
        "level": 2,
        "message": "Multiple consecutive failures detected",
        "threshold": 3,
        "window_minutes": 60,
        "channels": ["slack"]
    }
}
```

### Pattern Triggers

```python
PATTERN_TRIGGERS = {
    "failure_rate_spike": {
        "level": 2,
        "message": "Failure rate above normal threshold",
        "threshold": 0.3,  # 30% failure rate
        "window_minutes": 60,
        "channels": ["slack"]
    },
    "unusual_error_pattern": {
        "level": 2,
        "message": "Unusual error pattern detected",
        "threshold": 5,  # 5 similar errors
        "window_minutes": 30,
        "channels": ["slack"]
    },
    "performance_regression": {
        "level": 1,
        "message": "Performance regression detected",
        "threshold": 0.1,  # 10% regression
        "channels": ["slack"]
    }
}
```

## Escalation Engine

### Check and Escalate

```python
async def check_and_escalate(
    event: Event,
    context: Context
):
    """Check if event should trigger escalation."""
    
    # Check all trigger categories
    triggers = [
        check_critical_triggers(event, context),
        check_failure_triggers(event, context),
        check_pattern_triggers(event, context)
    ]
    
    # Find highest level trigger
    highest = max(triggers, key=lambda t: t.level if t else 0)
    
    if highest:
        await execute_escalation(highest, event, context)
```

### Execute Escalation

```python
async def execute_escalation(
    trigger: Trigger,
    event: Event,
    context: Context
):
    """Execute escalation for trigger."""
    
    # Build escalation message
    message = build_escalation_message(trigger, event, context)
    
    # Send to appropriate channels
    for channel in trigger.channels:
        await send_to_channel(channel, message)
    
    # Log escalation
    await log_escalation(trigger, event, message)
    
    # Track escalation metrics
    await track_escalation_metrics(trigger)
```

### Escalation Message Builder

```python
def build_escalation_message(
    trigger: Trigger,
    event: Event,
    context: Context
) -> EscalationMessage:
    """Build human-readable escalation message."""
    
    return EscalationMessage(
        level=trigger.level,
        title=trigger.message,
        timestamp=now(),
        
        details={
            "event_type": event.type,
            "ticket_id": getattr(event, 'ticket_id', None),
            "error": getattr(event, 'error', None),
            "context": context.summary()
        },
        
        actions=[
            {
                "label": "View Details",
                "url": generate_details_url(event)
            },
            {
                "label": "Acknowledge",
                "callback": "acknowledge_escalation"
            }
        ],
        
        urgency=calculate_urgency(trigger, event)
    )
```

## Cooldown and Deduplication

### Cooldown Management

```python
class EscalationCooldown:
    def __init__(self):
        self.last_escalation = {}
    
    def can_escalate(self, trigger_id: str, cooldown_minutes: int) -> bool:
        """Check if enough time has passed since last escalation."""
        
        last = self.last_escalation.get(trigger_id)
        if not last:
            return True
        
        elapsed = (now() - last).minutes
        return elapsed >= cooldown_minutes
    
    def record_escalation(self, trigger_id: str):
        """Record escalation timestamp."""
        self.last_escalation[trigger_id] = now()
```

### Deduplication

```python
class EscalationDeduplicator:
    def __init__(self):
        self.recent_escalations = set()
    
    def is_duplicate(self, event: Event) -> bool:
        """Check if this event is a duplicate escalation."""
        
        key = self.generate_key(event)
        
        if key in self.recent_escalations:
            return True
        
        # Add to recent set
        self.recent_escalations.add(key)
        
        # Schedule removal after window
        asyncio.create_task(
            self.remove_after(key, minutes=30)
        )
        
        return False
    
    def generate_key(self, event: Event) -> str:
        """Generate deduplication key for event."""
        return f"{event.type}:{getattr(event, 'ticket_id', '')}"
```

## Notification Channels

### Channel Implementations

```python
class PagerChannel:
    async def send(self, message: EscalationMessage):
        """Send pager notification."""
        await pager_service.page(
            message=message.title,
            priority=message.level,
            details=message.details
        )

class EmailChannel:
    async def send(self, message: EscalationMessage):
        """Send email notification."""
        await email_service.send(
            to=ESCALATION_EMAIL_LIST,
            subject=f"[OpenClaw] {message.title}",
            body=render_email_template(message)
        )

class SlackChannel:
    async def send(self, message: EscalationMessage):
        """Send Slack notification."""
        await slack_service.post(
            channel=ESCALATION_SLACK_CHANNEL,
            blocks=render_slack_blocks(message)
        )
```

## Escalation Dashboard

### Real-Time View

```yaml
EscalationDashboard:
  active_escalations:
    - id: "ESC-001"
      level: 3
      title: "Max retries exceeded"
      ticket_id: "TICKET-123"
      triggered_at: "2024-01-15T10:30:00Z"
      acknowledged: false
      
  escalation_history:
    - date: "2024-01-15"
      total: 5
      by_level:
        1: 2
        2: 2
        3: 1
        4: 0
```

### Metrics

```python
async def get_escalation_metrics(days: int = 7) -> EscalationMetrics:
    """Get escalation metrics."""
    
    history = await load_escalation_history(days)
    
    return EscalationMetrics(
        total_escalations=len(history),
        by_level=count_by_level(history),
        avg_response_time=calculate_avg_response_time(history),
        most_common_triggers=find_most_common(history, n=5),
        false_positive_rate=calculate_false_positive_rate(history)
    )
```

## Integration with Safe Mode

### Safe Mode Trigger

```python
async def check_safe_mode_trigger():
    """Check if safe mode should be activated."""
    
    recent_escalations = await get_recent_escalations(minutes=30)
    
    # Count level 3+ escalations
    critical_count = len([e for e in recent_escalations if e.level >= 3])
    
    if critical_count >= SAFE_MODE_THRESHOLD:
        await activate_safe_mode()
        await execute_escalation(
            trigger=SAFE_MODE_TRIGGER,
            event=SafeModeEvent(),
            context=get_system_context()
        )
```

## Acknowledgment and Resolution

### Human Acknowledgment

```python
async def acknowledge_escalation(escalation_id: str, user: str):
    """Acknowledge an escalation."""
    
    escalation = await load_escalation(escalation_id)
    
    escalation.acknowledged = True
    escalation.acknowledged_by = user
    escalation.acknowledged_at = now()
    
    await save_escalation(escalation)
    
    # Notify channels
    await notify_acknowledgment(escalation)
```

### Resolution

```python
async def resolve_escalation(
    escalation_id: str,
    resolution: str,
    user: str
):
    """Resolve an escalation."""
    
    escalation = await load_escalation(escalation_id)
    
    escalation.resolved = True
    escalation.resolution = resolution
    escalation.resolved_by = user
    escalation.resolved_at = now()
    
    await save_escalation(escalation)
    
    # Update metrics
    await track_resolution_metrics(escalation)
```
