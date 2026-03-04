---
title: Cost Monitoring Dashboard Spec
type: system
layer: execution
status: active
tags:
  - dashboard
  - monitoring
  - metrics
  - alerts
  - visualization
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Token_Burn_Controls]]"
  - "[[Compute_Burn_Controls]]"
  - "[[Calibration_Protocol]"
used_by:
  - "[Monthly_Budget_Prototype_Tier]]"
  - "[[Monthly_Budget_Indie_Tier]]"
  - "[[Monthly_Budget_MultiProject_Tier]"
---

# Cost Monitoring Dashboard Spec

## Overview

Real-time visibility into AI costs with actionable insights. The dashboard enables proactive cost management and rapid response to anomalies.

## Dashboard Layout

### Executive Summary (Top Row)

```
┌─────────────────────────────────────────────────────────────┐
│  CURRENT MONTH          TODAY           HOURLY RATE         │
│  $847 / $1000          $42.50          $12.50/hr            │
│  ████████████░░ 84%    On track        Projected: $950      │
└─────────────────────────────────────────────────────────────┘
```

**Metrics**:
- Current spend vs budget
- Today's spend
- Hourly burn rate
- Projected month-end

### Real-Time Gauges (Second Row)

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  API Calls   │  │   Tokens     │  │   Compute    │  │   Cache      │
│   2,847      │  │   1.2M       │  │   $145       │  │   62%        │
│  / 5,000     │  │   / 2M       │  │   / $400     │  │   hit rate   │
│  ██████░░░   │  │  ██████░░░   │  │  ███░░░░░░   │  │  ██████░░░   │
│    57%       │  │    60%       │  │    36%       │  │   Good       │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

### Cost Breakdown (Third Row)

**By Model**:
```
Model              Calls    Tokens    Cost    % of Total
────────────────────────────────────────────────────────
Local 8B           1,847    450K      $12     14%
Local 14B            234    120K       $8      9%
GPT-4o Mini          456    280K      $45     35%
Claude 3.5 Sonnet    310    350K      $67     52%
────────────────────────────────────────────────────────
TOTAL              2,847   1.2M      $132    100%
```

**By Feature Class**:
```
Class    Count    Avg Cost    Total    % of Budget
──────────────────────────────────────────────────
Class A    45      $2.50      $112      13%
Class B    28      $8.00      $224      26%
Class C    12     $25.00      $300      35%
Class D     5     $75.00      $375      44%
Class E     1    $200.00      $200      24%
```

### Trend Charts (Bottom Half)

**Daily Spend Trend**:
```
Spend ($)
  │
50├        ╭─╮
  │    ╭───╯ ╰──╮
40├────╯        ╰────╮
  │                   ╰───
30├
  │
20├────────────────────────
  │
10├
  └────┬────┬────┬────┬────
      Mon  Tue  Wed  Thu  Fri
```

**Model Usage Distribution**:
```
  Local 8B    ████████████████████ 45%
  Local 14B   ██████ 12%
  GPT-4o Mini ██████████████ 28%
  Claude      ████████ 15%
```

## Detailed Views

### Per-Project View (Multi-Project Tier)

```
Project          Budget    Spent    Remaining    Status
────────────────────────────────────────────────────────
Flagship         $2500    $1847      $653       🟢
Mobile App       $1200     $945      $255       🟡
Backend API       $600     $420      $180       🟢
Maintenance       $400     $380       $20       🔴
────────────────────────────────────────────────────────
```

### Per-Developer View (Indie/Multi-Project)

```
Developer    API Calls    Tokens    Cost    Daily Avg
──────────────────────────────────────────────────────
Alice            892      420K      $156      $7.80
Bob              734      380K      $142      $7.10
Carol            621      280K       $98      $4.90
David            600      120K       $45      $2.25
──────────────────────────────────────────────────────
```

### Per-Task View

```
Task Type          Count    Avg Time    Avg Cost    Success
───────────────────────────────────────────────────────────
Code Complete        456      2.3s       $0.12       94%
Code Gen             234     12.5s       $1.45       87%
Code Review          189     18.2s       $2.30       91%
Debug                123     45.0s       $5.60       78%
Architecture          67    120.0s      $18.50       85%
───────────────────────────────────────────────────────────
```

## Alert Configuration

### Alert Levels

| Level | Condition | Channel | Action |
|-------|-----------|---------|--------|
| Info | 50% of daily limit | Slack | None |
| Warning | 75% of daily limit | Slack + Email | Throttle |
| Critical | 90% of daily limit | All channels | Heavy throttle |
| Emergency | 100% of daily limit | All + SMS | Hard stop |

### Custom Alerts

```yaml
alerts:
  spend_spike:
    condition: "hourly_spend > 2x average"
    action: "notify_admin"
    
  unusual_pattern:
    condition: "api_calls > 3x normal for user"
    action: "require_verification"
    
  budget_projection:
    condition: "projected_spend > 110% of budget"
    action: "warn_team_lead"
    
  quality_degradation:
    condition: "error_rate > 10% for model"
    action: "switch_fallback_model"
```

## Data Sources

### Primary Metrics

```yaml
sources:
  api_costs:
    provider: openai
    endpoint: /usage
    frequency: real_time
    
  local_metrics:
    source: ollama_metrics
    endpoint: /api/metrics
    frequency: 10_seconds
    
  application_metrics:
    source: opentelemetry
    endpoint: /metrics
    frequency: 1_minute
```

### Derived Metrics

| Metric | Formula | Update Frequency |
|--------|---------|------------------|
| Cost per ticket | Total cost / tickets | Real-time |
| Token efficiency | Output / Input | Hourly |
| Cache hit rate | Hits / Total | Real-time |
| ROI | Value / Cost | Daily |

## Implementation Notes

### Tech Stack Options

**Option 1: Grafana + Prometheus**
- Pros: Open source, flexible, proven
- Cons: Setup complexity
- Best for: Indie+ tiers

**Option 2: Custom React + TimescaleDB**
- Pros: Custom UI, full control
- Cons: Development effort
- Best for: Multi-project tier

**Option 3: Vercel Analytics + Custom**
- Pros: Easy setup, serverless
- Cons: Limited customization
- Best for: Prototype tier

### Data Retention

| Data Type | Retention | Aggregation |
|-----------|-----------|-------------|
| Raw events | 7 days | None |
| Hourly aggregates | 90 days | Hourly |
| Daily aggregates | 2 years | Daily |
| Monthly reports | Forever | Monthly |

## Mobile View

```
┌─────────────────────┐
│  $847 / $1000       │
│  ████████████░░ 84% │
├─────────────────────┤
│  Today: $42.50      │
│  Hourly: $12.50     │
├─────────────────────┤
│  [Alerts: 2]        │
│  ⚠️ 75% daily limit │
├─────────────────────┤
│  [View Details]     │
└─────────────────────┘
```

## API Endpoints

```yaml
endpoints:
  GET /api/costs/current:
    returns: Current month spend
    
  GET /api/costs/daily:
    params: start_date, end_date
    returns: Daily spend breakdown
    
  GET /api/costs/by-model:
    returns: Spend per model
    
  GET /api/costs/by-project:
    returns: Spend per project
    
  GET /api/alerts:
    returns: Active alerts
    
  POST /api/alerts/acknowledge:
    body: alert_id
    action: Acknowledge alert
```

---

*You can't manage what you don't measure. This dashboard makes costs visible and actionable.*
