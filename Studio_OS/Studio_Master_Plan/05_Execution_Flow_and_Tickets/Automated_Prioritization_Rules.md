---
title: Automated Prioritization Rules
type: system
layer: execution
status: active
tags:
  - prioritization
  - rules
  - ranking
  - scoring
  - automation
depends_on:
  - "[Ticket_Intake_Management]]"
  - "[[Ticket_Template_Spec]"
used_by:
  - "[OpenClaw_Daily_Work_Loop]"
---

# Automated Prioritization Rules

## Purpose

Automated Prioritization Rules define how OpenClaw ranks and orders tickets in the backlog, ensuring the most valuable and urgent work is executed first.

## Priority Factors

### 1. Explicit Priority

Base score from ticket priority:

```python
PRIORITY_SCORES = {
    "critical": 100,
    "high": 75,
    "medium": 50,
    "low": 25
}

def get_priority_score(ticket: Ticket) -> int:
    return PRIORITY_SCORES.get(ticket.priority, 0)
```

### 2. Ticket Type

Adjust score based on ticket type:

```python
TYPE_MULTIPLIERS = {
    "bugfix": 1.5,      # Bugs get higher priority
    "feature": 1.0,     # Standard priority
    "refactor": 0.8,    # Lower priority
    "docs": 0.5,        # Lowest priority
    "chore": 0.5,
    "test": 0.7
}

def apply_type_multiplier(score: float, ticket: Ticket) -> float:
    return score * TYPE_MULTIPLIERS.get(ticket.type, 1.0)
```

### 3. Age Factor

Older tickets get slight priority boost:

```python
def calculate_age_factor(ticket: Ticket) -> float:
    """Calculate age-based priority boost."""
    age_days = (now() - ticket.created_at).days
    
    # Boost increases with age, capped at 30 days
    boost = min(age_days / 10, 3.0)
    
    return 1.0 + (boost * 0.1)  # Max 1.3x boost
```

### 4. Dependency Factor

Tickets that unblock others get priority:

```python
async def calculate_dependency_factor(ticket: Ticket) -> float:
    """Calculate priority boost for unblocking tickets."""
    
    # Count tickets blocked by this one
    blocked_count = await count_blocked_by(ticket.id)
    
    if blocked_count == 0:
        return 1.0
    
    # Boost based on how many tickets are unblocked
    boost = min(blocked_count * 0.2, 2.0)
    
    return 1.0 + boost
```

### 5. Complexity Factor

Simpler tickets get slight priority (quick wins):

```python
COMPLEXITY_SCORES = {
    "simple": 1.2,
    "medium": 1.0,
    "complex": 0.8,
    "very_complex": 0.6
}

def apply_complexity_factor(score: float, ticket: Ticket) -> float:
    return score * COMPLEXITY_SCORES.get(ticket.complexity, 1.0)
```

### 6. Business Value

Extract business value from intent:

```python
async def calculate_business_value(ticket: Ticket) -> float:
    """Calculate business value score."""
    
    # Load parent intent
    intent = await load_intent(ticket.source.intent_id)
    
    value = 1.0
    
    # Check for explicit business constraints
    if intent.constraints.business:
        # Time-sensitive business needs
        if "milestone" in intent.constraints.business.lower():
            value *= 1.5
        
        # Revenue impact
        if "revenue" in intent.constraints.business.lower():
            value *= 2.0
    
    # Check motivation
    if "retention" in intent.context.motivation.lower():
        value *= 1.3
    
    if "engagement" in intent.context.motivation.lower():
        value *= 1.2
    
    return value
```

## Priority Calculation

### Complete Scoring Function

```python
async def calculate_priority_score(ticket: Ticket) -> float:
    """Calculate complete priority score for ticket."""
    
    # Base score from explicit priority
    score = get_priority_score(ticket)
    
    # Apply multipliers
    score = apply_type_multiplier(score, ticket)
    score *= calculate_age_factor(ticket)
    score *= await calculate_dependency_factor(ticket)
    score = apply_complexity_factor(score, ticket)
    score *= await calculate_business_value(ticket)
    
    # Apply urgency factor
    score *= calculate_urgency_factor(ticket)
    
    return score
```

### Urgency Factor

```python
def calculate_urgency_factor(ticket: Ticket) -> float:
    """Calculate urgency based on time constraints."""
    
    # Check for deadline
    if hasattr(ticket, 'deadline') and ticket.deadline:
        days_until = (ticket.deadline - now()).days
        
        if days_until < 1:
            return 3.0  # Due today
        elif days_until < 3:
            return 2.0  # Due within 3 days
        elif days_until < 7:
            return 1.5  # Due within week
        elif days_until < 14:
            return 1.2  # Due within 2 weeks
    
    return 1.0
```

## Priority Categories

### Auto-Categorization

```python
def categorize_priority(score: float) -> str:
    """Categorize priority based on score."""
    
    if score >= 150:
        return "p0-critical"
    elif score >= 100:
        return "p1-high"
    elif score >= 60:
        return "p2-medium"
    elif score >= 30:
        return "p3-low"
    else:
        return "p4-backlog"
```

## Dynamic Reprioritization

### Triggers for Recalculation

```python
REPRIORITIZATION_TRIGGERS = [
    "new_critical_ticket",
    "dependency_resolved",
    "deadline_approaching",
    "business_priority_change",
    "sprint_boundary"
]

async def should_recalculate_priority(ticket: Ticket) -> bool:
    """Check if ticket priority should be recalculated."""
    
    # Recalculate if last calculation was > 24 hours ago
    if ticket.last_priority_calculation:
        hours_since = (now() - ticket.last_priority_calculation).hours
        if hours_since > 24:
            return True
    
    # Recalculate if any trigger event occurred
    for trigger in REPRIORITIZATION_TRIGGERS:
        if await check_trigger(trigger, ticket):
            return True
    
    return False
```

### Batch Recalculation

```python
async def recalculate_all_priorities():
    """Recalculate priorities for all pending tickets."""
    
    backlog = await load_backlog()
    
    for ticket in backlog.tickets:
        if ticket.status == "pending":
            if await should_recalculate_priority(ticket):
                # Calculate new score
                new_score = await calculate_priority_score(ticket)
                
                # Update if changed significantly
                if abs(new_score - ticket.priority_score) > 10:
                    ticket.priority_score = new_score
                    ticket.last_priority_calculation = now()
                    
                    logger.info(
                        f"Updated priority for {ticket.id}: "
                        f"{ticket.priority_score:.1f}"
                    )
    
    await save_backlog(backlog)
```

## Priority Override Rules

### Human Override

```python
async def apply_priority_override(
    ticket: Ticket,
    override: PriorityOverride
):
    """Apply human priority override."""
    
    ticket.priority_override = override
    ticket.priority_score = override.score
    ticket.override_reason = override.reason
    ticket.override_by = override.user
    
    logger.info(
        f"Priority override applied to {ticket.id}: "
        f"{override.score} ({override.reason})"
    )
```

### Emergency Escalation

```python
async def emergency_escalate(ticket: Ticket, reason: str):
    """Emergency escalation to highest priority."""
    
    ticket.priority_score = 999  # Above all others
    ticket.escalated = True
    ticket.escalation_reason = reason
    ticket.escalated_at = now()
    
    # Notify team
    await notify_emergency_escalation(ticket, reason)
```

## Priority Reporting

### Priority Distribution

```python
async def get_priority_distribution() -> PriorityDistribution:
    """Get distribution of tickets by priority."""
    
    backlog = await load_backlog()
    
    distribution = defaultdict(int)
    for ticket in backlog.tickets:
        category = categorize_priority(ticket.priority_score)
        distribution[category] += 1
    
    return PriorityDistribution(
        p0_critical=distribution["p0-critical"],
        p1_high=distribution["p1-high"],
        p2_medium=distribution["p2-medium"],
        p3_low=distribution["p3-low"],
        p4_backlog=distribution["p4-backlog"]
    )
```

### Priority Trends

```python
async def get_priority_trends(days: int = 7) -> PriorityTrends:
    """Get priority trends over time."""
    
    history = await load_priority_history(days)
    
    return PriorityTrends(
        avg_priority_change=calculate_avg_change(history),
        high_priority_growth=calculate_growth(history, "p0-critical", "p1-high"),
        backlog_growth=calculate_growth(history, "p4-backlog")
    )
```

## Integration with Other Systems

### Daily Work Loop
Prioritization feeds [[OpenClaw_Daily_Work_Loop|daily work loop]]:

```python
prioritized = sorted(tickets, key=lambda t: t.priority_score, reverse=True)
```

### Ticket Intake
New tickets get initial priority via [[Ticket_Intake_Management|ticket intake]]:

```python
ticket.priority_score = await calculate_priority_score(ticket)
```
