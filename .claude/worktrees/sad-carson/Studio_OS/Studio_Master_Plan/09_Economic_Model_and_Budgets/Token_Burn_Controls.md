---
title: Token Burn Controls
type: rule
layer: enforcement
status: active
tags:
  - tokens
  - limits
  - throttling
  - controls
  - safety
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Model_Cost_Matrix]"
used_by:
  - "[Monthly_Budget_Prototype_Tier]]"
  - "[[Monthly_Budget_Indie_Tier]]"
  - "[[Monthly_Budget_MultiProject_Tier]]"
  - "[[Cost_Monitoring_Dashboard_Spec]"
---

# Token Burn Controls

## Overview

Token burn controls prevent runaway API costs through layered limits, intelligent throttling, and emergency stops. These are safety mechanisms, not productivity barriers.

## Control Layers

### Layer 1: Request-Level Controls

**Max Tokens Per Request**:
```yaml
limits:
  input_tokens:
    default: 8000
    max: 32000
    
  output_tokens:
    default: 2000
    max: 8000
    
  context_window:
    warning_at: 0.7
    hard_limit: 0.9
```

**Context Management**:
- Automatic summarization at 70% context
- Sliding window for long conversations
- Relevant context retrieval only

### Layer 2: User/Session Controls

**Daily Limits**:
```yaml
daily_limits:
  prototype_tier:
    api_calls: 100
    input_tokens: 10000
    output_tokens: 5000
    cost_usd: 3.00
    
  indie_tier:
    api_calls: 500
    input_tokens: 50000
    output_tokens: 25000
    cost_usd: 25.00
    
  multi_project:
    api_calls: 2000
    input_tokens: 200000
    output_tokens: 100000
    cost_usd: 100.00
```

**Session Controls**:
- Max 50 consecutive API calls without local attempt
- Cooldown period after 20 rapid calls
- Force review after $5 spend in one session

### Layer 3: System-Wide Controls

**Hourly Limits**:
```yaml
hourly_limits:
  max_api_calls: 500
  max_cost_usd: 50
  burst_allowance: 1.5x
```

**Rate Limiting**:
- 10 calls/second sustained
- 50 calls/second burst (5 seconds)
- Queue excess requests

## Throttling Strategies

### Progressive Throttling

```yaml
throttling:
  green_zone:  # 0-50% of limit
    action: none
    
  yellow_zone:  # 50-75% of limit
    action: warn_user
    message: "Approaching daily limit"
    
  orange_zone:  # 75-90% of limit
    action: throttle
    measures:
      - prefer_local_models: true
      - reduce_context: true
      - cache_only: false
    
  red_zone:  # 90-100% of limit
    action: heavy_throttle
    measures:
      - local_models_only: true
      - require_approval: true
      - queue_requests: true
    
  black_zone:  # >100% of limit
    action: hard_stop
    measures:
      - block_api_calls: true
      - notify_admin: true
      - log_incident: true
```

### Smart Throttling

**Quality-Based**:
- If local model confidence > 0.8, skip API
- If cached result similarity > 0.9, use cache
- If task complexity < threshold, force local

**Cost-Based**:
- Route to cheapest capable model
- Batch small requests
- Defer non-urgent requests to off-peak

## Emergency Stops

### Automatic Triggers

```yaml
emergency_stops:
  spend_spike:
    trigger: "2x normal hourly spend"
    action: pause_api_calls
    duration: 15_minutes
    
  error_rate:
    trigger: "50% errors in 5 minutes"
    action: switch_provider
    notify: true
    
  unusual_pattern:
    trigger: "10x normal call frequency"
    action: require_captcha
    audit: true
    
  budget_exceeded:
    trigger: "monthly budget > 100%"
    action: api_shutdown
    require: manual_override
```

### Manual Overrides

| Override | Authorization | Duration | Audit |
|----------|---------------|----------|-------|
| Temporary increase | Team lead | 24 hours | Required |
| Emergency bypass | Admin | 1 hour | Required |
| Disable limits | Admin + approval | Session | Required |

## Caching as Burn Control

### Cache Hierarchy

```yaml
caching:
  l1_cache:  # In-memory
    ttl: 1_hour
    max_size: 1000_entries
    
  l2_cache:  # Redis/local
    ttl: 24_hours
    max_size: 10000_entries
    
  l3_cache:  # Persistent
    ttl: 7_days
    max_size: 100000_entries
```

### Cache Key Strategy

- Exact match for identical requests
- Fuzzy match for similar requests (80% similarity)
- Semantic match for equivalent meaning

## Monitoring and Alerts

### Real-Time Metrics

```yaml
monitoring:
  metrics:
    - tokens_per_minute
    - cost_per_hour
    - api_call_rate
    - cache_hit_rate
    - error_rate
    
  alert_thresholds:
    warning: 70% of any limit
    critical: 90% of any limit
    emergency: 100% of any limit
```

### Alert Channels

| Severity | Channel | Response Time |
|----------|---------|---------------|
| Warning | Slack/email | 1 hour |
| Critical | Slack + SMS | 15 minutes |
| Emergency | Phone + Pager | 5 minutes |

## Recovery Procedures

### After Hard Stop

1. **Immediate**: Assess cause (runaway script? attack?)
2. **Short-term**: Implement temporary fix
3. **Medium-term**: Adjust limits if needed
4. **Long-term**: Update prevention rules

### Post-Incident Review

- What triggered the stop?
- Were limits appropriate?
- Could caching have helped?
- Update playbooks

## Configuration Examples

### Conservative (Prototype)

```yaml
burn_control:
  daily_api_calls: 100
  daily_cost: $3
  throttle_at: 50%
  hard_stop_at: 100%
  local_first: true
```

### Balanced (Indie)

```yaml
burn_control:
  daily_api_calls: 500
  daily_cost: $25
  throttle_at: 70%
  hard_stop_at: 100%
  smart_routing: true
```

### Relaxed (Multi-Project)

```yaml
burn_control:
  daily_api_calls: 2000
  daily_cost: $100
  throttle_at: 80%
  hard_stop_at: 110%
  project_isolation: true
```

## Testing Burn Controls

### Load Testing

- Simulate 10x normal load
- Verify throttling activates
- Confirm hard stops work
- Measure recovery time

### Chaos Testing

- Randomly fail API calls
- Inject latency spikes
- Test fallback chains
- Validate emergency stops

---

*Burn controls exist to prevent disasters, not to prevent work. Calibrate them to your risk tolerance.*
