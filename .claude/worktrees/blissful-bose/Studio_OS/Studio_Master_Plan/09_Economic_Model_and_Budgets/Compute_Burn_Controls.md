---
title: Compute Burn Controls
type: rule
layer: enforcement
status: active
tags:
  - compute
  - gpu
  - limits
  - throttling
  - infrastructure
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Model_Cost_Matrix]"
used_by:
  - "[Monthly_Budget_Prototype_Tier]]"
  - "[[Monthly_Budget_Indie_Tier]]"
  - "[[Monthly_Budget_MultiProject_Tier]]"
  - "[[Cost_Monitoring_Dashboard_Spec]"
---

# Compute Burn Controls

## Overview

Compute burn controls manage local GPU resources, VPS usage, and cloud compute costs. These complement token controls for complete cost management.

## Local GPU Controls

### GPU Resource Management

```yaml
gpu_management:
  memory_limits:
    warning_at: 80%
    throttle_at: 90%
    oom_protection: 95%
    
  concurrent_models:
    max_loaded: 3
    unload_inactive_after: 10_minutes
    priority_models:
      - embedding_model
      - primary_code_model
      
  batch_processing:
    max_batch_size: 8
    max_wait_time: 2_seconds
```

### Model Loading Strategy

**Hot Models** (Always Loaded):
- Embedding model (lightweight)
- Primary 8B model (fast tasks)

**Warm Models** (Load on Demand):
- 14B model (medium complexity)
- Code-specific model

**Cold Models** (Preload for Known Work):
- 70B model (complex tasks)
- Specialty models (rare use)

### Power Management

```yaml
power_management:
  idle_timeout: 30_minutes
  sleep_mode: reduce_clocks
  wake_on_request: true
  
  schedule:
    work_hours: full_power
    off_hours: sleep_mode
    weekend: deep_sleep
```

## VPS/Cloud Controls

### Instance Management

```yaml
instance_controls:
  auto_scaling:
    min_instances: 1
    max_instances: 5
    scale_up_at: 70% cpu
    scale_down_at: 30% cpu
    
  instance_types:
    default: cpu_4gb
    gpu_tasks: gpu_t4
    heavy_tasks: gpu_a10
    
  spot_instances:
    enabled: true
    max_bid: 0.50/hour
    fallback: on_demand
```

### Time-Based Controls

```yaml
scheduling:
  work_hours:
    instances: 2
    instance_type: standard
    
  off_hours:
    instances: 1
    instance_type: small
    
  weekend:
    instances: 0
    action: shutdown
```

## Cost Limits by Tier

### Prototype Tier

```yaml
compute_limits:
  local_gpu:
    max_vram: 12GB
    max_power_watts: 200
    
  cloud:
    max_monthly: $25
    max_hourly: $2
    allowed_services:
      - vercel_hobby
      - railway_starter
```

### Indie Tier

```yaml
compute_limits:
  local_gpu:
    max_vram: 24GB
    max_power_watts: 300
    
  cloud:
    max_monthly: $400
    max_hourly: $10
    allowed_services:
      - aws_ec2
      - gcp_compute
      - railway_standard
```

### Multi-Project Tier

```yaml
compute_limits:
  local_gpu:
    max_vram: 80GB
    max_power_watts: 800
    
  cloud:
    max_monthly: $3000
    max_hourly: $50
    allowed_services:
      - aws_ec2
      - gcp_compute
      - azure_ml
```

## Throttling Strategies

### GPU Throttling

```yaml
gpu_throttling:
  queue_management:
    max_queue_depth: 20
    timeout: 30_seconds
    
  quality_reduction:
    at_80%_load:
      reduce_context: true
      use_quantized: true
      
    at_90%_load:
      batch_only: true
      defer_non_urgent: true
      
    at_95%_load:
      reject_new_requests: true
      finish_in_flight: true
```

### Cloud Throttling

```yaml
cloud_throttling:
  cost_based:
    at_50%_budget:
      prefer_spot: true
      reduce_instance_size: false
      
    at_75%_budget:
      prefer_spot: true
      reduce_instance_size: true
      
    at_90%_budget:
      spot_only: true
      min_instances: 1
      
    at_100%_budget:
      shutdown_non_production: true
```

## Storage Controls

### Vector Database Limits

```yaml
vector_db_limits:
  max_dimensions: 1536
  max_vectors: 1000000
  
  tier_limits:
    prototype:
      max_size_gb: 1
      max_queries_per_day: 10000
      
    indie:
      max_size_gb: 10
      max_queries_per_day: 100000
      
    multi_project:
      max_size_gb: 100
      max_queries_per_day: 1000000
```

### Artifact Storage

```yaml
artifact_storage:
  retention:
    builds: 30_days
    logs: 7_days
    cache: 90_days
    
  compression:
    enabled: true
    level: 6
    
  cleanup:
    schedule: daily
    remove_orphaned: true
```

## Network Controls

### Egress Limits

```yaml
egress_limits:
  prototype:
    monthly_gb: 100
    
  indie:
    monthly_gb: 500
    
  multi_project:
    monthly_gb: 2000
    
  alerts:
    warning_at: 80%
    throttle_at: 100%
```

### CDN Usage

```yaml
cdn_controls:
  caching:
    static_assets: 1_year
    api_responses: 1_hour
    
  compression:
    brotli: true
    gzip: true
```

## Monitoring

### GPU Metrics

```yaml
gpu_monitoring:
  metrics:
    - utilization_percent
    - vram_usage_gb
    - temperature_c
    - power_draw_w
    - inference_latency_ms
    
  alerts:
    high_temp: 80C
    high_vram: 90%
    high_latency: 5000ms
```

### Cloud Metrics

```yaml
cloud_monitoring:
  metrics:
    - instance_hours
    - cost_per_hour
    - storage_gb
    - egress_gb
    - api_calls
    
  alerts:
    daily_spend: $50
    hourly_spend: $10
```

## Emergency Procedures

### GPU Overload

1. **Detect**: Monitor queue depth and latency
2. **Throttle**: Reduce batch size, increase timeouts
3. **Scale**: Spin up cloud GPU if configured
4. **Recover**: Gradually restore normal operation

### Cloud Runaway

1. **Detect**: Hourly spend > 2x normal
2. **Stop**: Halt auto-scaling, cap instances
3. **Investigate**: Identify cause (loop? attack?)
4. **Resume**: Manual restart with limits

## Optimization Strategies

### Local Optimization

- Use quantized models (Q4, Q5)
- Batch requests when possible
- Unload unused models
- Monitor temperature and power

### Cloud Optimization

- Use spot instances for non-critical work
- Right-size instances (don't over-provision)
- Schedule shutdowns for off-hours
- Use reserved instances for predictable workloads

---

*Compute costs can surprise you. Monitor continuously, throttle aggressively, and optimize relentlessly.*
