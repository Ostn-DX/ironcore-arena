---
title: Retry Policy Specification
type: system
layer: enforcement
status: active
tags:
  - retry
  - policy
  - backoff
  - failure
  - resilience
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Command_Graph_Specification]"
used_by:
  - "[OpenClaw_Daily_Work_Loop]]"
  - "[[Safe_Mode_Behavior]"
---

# Retry Policy Specification

## Purpose

The Retry Policy defines how OpenClaw handles transient failures during agent execution. It provides configurable, context-aware retry strategies that balance resilience with resource efficiency.

## Core Principles

1. **Fail Fast for Permanent Errors**: Don't retry deterministic failures
2. **Exponential Backoff**: Increase delay between retries
3. **Context-Aware**: Different strategies per failure type
4. **Bounded**: Maximum retries prevent infinite loops
5. **Observable**: All retries logged and monitored

## Retry Configuration

```yaml
RetryPolicy:
  version: "1.0"
  
  global:
    max_retries: 3
    base_delay_ms: 1000
    max_delay_ms: 30000
    exponential_base: 2
    
  strategies:
    - name: "transient_network"
      match_errors: ["NET001", "NET002", "TIMEOUT"]
      max_retries: 3
      base_delay_ms: 1000
      
    - name: "rate_limited"
      match_errors: ["RATE_LIMIT"]
      max_retries: 5
      base_delay_ms: 5000
      
    - name: "context_overflow"
      match_errors: ["CTX003"]
      max_retries: 2
      base_delay_ms: 500
      strategy: reduce_context
      
    - name: "permanent"
      match_errors: ["SYNTAX_ERROR", "VALIDATION_FAILED"]
      max_retries: 0  # Don't retry
```

## Exponential Backoff Algorithm

```python
import random
import time

def calculate_delay(
    attempt: int,
    base_delay_ms: int,
    max_delay_ms: int,
    exponential_base: float = 2.0,
    jitter: bool = True
) -> float:
    """Calculate delay with exponential backoff and jitter."""
    # Exponential component
    exponential_delay = base_delay_ms * (exponential_base ** attempt)
    
    # Cap at maximum
    capped_delay = min(exponential_delay, max_delay_ms)
    
    # Add jitter to prevent thundering herd
    if jitter:
        jitter_factor = random.uniform(0.5, 1.5)
        capped_delay *= jitter_factor
    
    return capped_delay / 1000.0  # Convert to seconds

# Example delays:
# Attempt 0: 1s (± jitter)
# Attempt 1: 2s (± jitter)
# Attempt 2: 4s (± jitter)
# Attempt 3: 8s (± jitter) - capped at max
```

## Retry Strategies

### 1. Simple Retry

Retry with same inputs:

```python
async def simple_retry(task, policy):
    for attempt in range(policy.max_retries + 1):
        try:
            return await execute(task)
        except RetryableError as e:
            if attempt == policy.max_retries:
                raise MaxRetriesExceeded(e)
            
            delay = calculate_delay(attempt, policy)
            await asyncio.sleep(delay)
```

### 2. Context Reduction Retry

Retry with reduced context on overflow:

```python
async def context_reduction_retry(task, policy):
    context = task.context
    
    for attempt in range(policy.max_retries + 1):
        try:
            return await execute(task.with_context(context))
        except ContextOverflowError:
            if attempt == policy.max_retries:
                raise MaxRetriesExceeded()
            
            # Reduce context by 25%
            context = reduce_context(context, factor=0.75)
            
            delay = calculate_delay(attempt, policy)
            await asyncio.sleep(delay)
```

### 3. Alternative Strategy Retry

Try different approaches:

```python
async def alternative_strategy_retry(task, policy):
    strategies = task.alternative_strategies
    
    for attempt, strategy in enumerate(strategies):
        try:
            return await execute(task.with_strategy(strategy))
        except RetryableError as e:
            if attempt == len(strategies) - 1:
                raise MaxRetriesExceeded(e)
            
            delay = calculate_delay(attempt, policy)
            await asyncio.sleep(delay)
```

### 4. Circuit Breaker Pattern

Prevent cascade failures:

```python
class CircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_timeout=60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
    
    def can_execute(self) -> bool:
        if self.state == "CLOSED":
            return True
        
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = "HALF_OPEN"
                return True
            return False
        
        return True  # HALF_OPEN
    
    def record_success(self):
        self.failure_count = 0
        self.state = "CLOSED"
    
    def record_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.failure_threshold:
            self.state = "OPEN"
```

## Failure Classification

### Retryable Errors

| Error Code | Description | Strategy |
|------------|-------------|----------|
| NET001 | Network timeout | Simple retry |
| NET002 | Connection reset | Simple retry |
| RATE_LIMIT | API rate limited | Exponential backoff |
| CTX003 | Context too large | Reduce context |
| TIMEOUT | Execution timeout | Simple retry |
| TEMP_UNAVAIL | Service temporarily unavailable | Circuit breaker |

### Non-Retryable Errors

| Error Code | Description | Action |
|------------|-------------|--------|
| SYNTAX_ERROR | Invalid syntax | Fail immediately |
| VALIDATION_FAILED | Schema validation failed | Fail immediately |
| PERMISSION_DENIED | Access denied | Escalate to human |
| NOT_FOUND | Resource not found | Fail immediately |
| CONFLICT | Concurrent modification | Manual resolution |

## Per-Agent Retry Policies

```yaml
agent_policies:
  CodeGenerator:
    max_retries: 3
    base_delay_ms: 2000
    strategies:
      - simple
      - context_reduction
      - alternative_approach
      
  TestWriter:
    max_retries: 2
    base_delay_ms: 1000
    strategies:
      - simple
      - context_reduction
      
  Reviewer:
    max_retries: 2
    base_delay_ms: 1000
    strategies:
      - simple
      
  GateExecutor:
    max_retries: 1
    base_delay_ms: 5000
    strategies:
      - simple
```

## Retry State Machine

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│  Idle   │────▶│ Attempt │────▶│ Success │
└─────────┘     └────┬────┘     └─────────┘
                     │
                     ▼
              ┌─────────────┐
              │Retryable?   │
              └──────┬──────┘
                     │
        ┌────────────┼────────────┐
        │Yes         │No          │Max Retries
        ▼            ▼            │Reached
   ┌─────────┐  ┌─────────┐       │
   │  Delay  │  │  Fail   │◀──────┘
   └────┬────┘  └─────────┘
        │
        ▼
   ┌─────────┐
   │ Retry   │────▶ (back to Attempt)
   └─────────┘
```

## Monitoring and Observability

### Retry Metrics

```python
@dataclass
class RetryMetrics:
    task_id: str
    agent_type: str
    total_attempts: int
    final_status: str  # success, failed, max_retries
    total_duration_ms: int
    retry_delays_ms: [int]
    error_types: [str]
```

### Alerting Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Retry rate | > 20% | > 40% |
| Max retries exceeded | > 5/hour | > 20/hour |
| Average retry count | > 2 | > 3 |
| Circuit breaker open | > 2 | > 5 |

### Logging Format

```json
{
  "event": "retry_attempt",
  "trace_id": "uuid",
  "task_id": "task_123",
  "agent": "CodeGenerator",
  "attempt": 2,
  "max_attempts": 3,
  "delay_ms": 2000,
  "error_code": "NET001",
  "error_message": "Connection timeout"
}
```

## Integration with Other Systems

### Rollback Protocol
When max retries exceeded, trigger [[Rollback_Protocol|rollback]]:

```python
async def handle_max_retries_exceeded(task, error):
    logger.error(f"Max retries exceeded for {task.id}")
    
    # Trigger rollback
    await rollback_protocol.execute(
        task=task,
        reason=f"Max retries exceeded: {error}"
    )
```

### Safe Mode
Repeated failures trigger [[Safe_Mode_Behavior|safe mode]]:

```python
def check_safe_mode_trigger(failure_history):
    recent_failures = count_failures_in_window(failure_history, minutes=30)
    if recent_failures > SAFE_MODE_THRESHOLD:
        activate_safe_mode()
```

## Best Practices

1. **Idempotency**: All retryable operations must be idempotent
2. **Statelessness**: Don't rely on state between retries
3. **Clear Error Messages**: Include retry guidance in errors
4. **Graceful Degradation**: Have fallback for persistent failures
5. **Monitor Patterns**: Track failure patterns for systemic issues
