---
title: Monthly Budget - Multi-Project Tier
type: template
layer: execution
status: active
tags:
  - budget
  - enterprise
  - tier-3
  - multi-project
  - scale
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Model_Cost_Matrix]]"
  - "[[Monthly_Budget_Indie_Tier]"
used_by:
  - "[Calibration_Protocol]]"
  - "[[Cost_Monitoring_Dashboard_Spec]]"
  - "[[ROI_Optimization_Rules]"
---

# Monthly Budget: Multi-Project Tier

## Target: $2000-10000/month

This tier supports studios running multiple projects simultaneously with dedicated resources per project. Scale through efficiency, not just spending.

## Budget Allocation

### Hardware (Dedicated Infrastructure)

| Component | Specification | One-Time | Monthly (36mo) |
|-----------|---------------|----------|----------------|
| Primary Server | Dual RTX 4090, 128GB RAM | $8000 | $222 |
| Secondary Server | RTX 3090 x2, 64GB RAM | $3000 | $83 |
| Edge Nodes | 3x Mini-PC (local inference) | $1500 | $42 |
| Network/NAS | 10GbE, 20TB storage | $2000 | $56 |
| **Total Hardware** | - | **$14500** | **$403** |

### API Budget: $1000-4000/month

| Service | Allocation | Expected Usage |
|---------|------------|----------------|
| OpenAI (Enterprise) | $800 | GPT-4o, o1-preview |
| Anthropic (Pro) | $1000 | Claude 3.5 Sonnet/Opus |
| Google (Scale) | $600 | Gemini Pro, Flash |
| Azure OpenAI | $500 | Enterprise features |
| OpenRouter | $400 | Model diversity |
| Buffer/Experiments | $300-700 | A/B testing, new models |

### Infrastructure: $800-3000/month

| Service | Tier | Cost | Purpose |
|---------|------|------|---------|
| GitHub Enterprise | 20+ seats | $400 | Advanced security |
| AWS/GCP/Azure | Standard | $400-1500 | Compute, storage |
| Vector DB (managed) | Production | $200-500 | Pinecone/Weaviate |
| Monitoring/DataDog | Pro | $200-400 | Full observability |
| CI/CD (GitHub Actions) | Large runners | $150-300 | Parallel builds |
| CDN/Edge | - | $100-200 | Global delivery |
| Backup/DR | - | $100-200 | Business continuity |

### Per-Project Allocation

| Project Tier | Monthly Budget | Team Size | API Allocation |
|--------------|----------------|-----------|----------------|
| Flagship | $2000-3000 | 5-8 devs | $800 |
| Major | $1000-1500 | 3-5 devs | $400 |
| Minor | $500-800 | 1-3 devs | $200 |
| Maintenance | $200-400 | Shared | $100 |

## Model Configuration

### Local Infrastructure (50% of workload)

```yaml
local_infrastructure:
  primary_cluster:
    models:
      - llama3.1:70b-q4    # Complex tasks
      - qwen2.5:72b-q4     # Alternative
      - mixtral:8x7b       # MoE efficiency
    capacity: 1000 calls/hour
    
  secondary_cluster:
    models:
      - llama3.1:8b        # Fast tasks
      - qwen2.5:14b        # Balanced
      - deepseek-coder:33b # Code focus
    capacity: 5000 calls/hour
    
  edge_nodes:
    models:
      - phi3:medium        # Personal inference
      - gemma2:9b          # Lightweight
    capacity: 500 calls/hour per node
```

**Expected daily usage**:
- 10K-25K local calls/day across all projects
- 200K-500K tokens generated/day locally
- Cost: ~$150-300/month (electricity, maintenance)

### API Models (50% of workload)

```yaml
api_models:
  reasoning:
    primary: claude-3.5-opus
    fallback: gpt-4o
    
  production:
    primary: claude-3.5-sonnet
    fallback: gpt-4o
    
  scale:
    primary: gemini-1.5-pro
    fallback: gpt-4o-mini
    
  experiments:
    openrouter: true
    new_models: true
```

**Expected daily usage**:
- 3000-8000 API calls/day across all projects
- 10M-30M input tokens/month
- 5M-15M output tokens/month
- Cost: ~$2000-5000/month

## Cost Control at Scale

### Project-Level Isolation

```yaml
project_budgets:
  flagship_project:
    monthly_limit: $2500
    api_allocation: 30%
    local_priority: true
    
  major_projects:
    monthly_limit: $1200
    api_allocation: 25%
    shared_resources: true
    
  minor_projects:
    monthly_limit: $600
    api_allocation: 15%
    overflow_allowed: false
```

### Intelligent Load Balancing

- Route to least-cost capable model
- Queue non-urgent requests for off-peak
- Pre-warm models based on schedule
- Auto-scale local clusters

### Cross-Project Caching

| Cache Scope | TTL | Expected Savings |
|-------------|-----|------------------|
| Shared embeddings | Infinite | 30% token reduction |
| Common code patterns | 14 days | 15% generation reduction |
| Agent decisions | 7 days | 10% call reduction |
| **Overall** | - | **40-50%** |

## Expected Monthly Breakdown

| Category | Low | Likely | High |
|----------|-----|--------|------|
| API calls | $1000 | $2500 | $4500 |
| Hardware (amortized) | $300 | $403 | $600 |
| Electricity/maintenance | $100 | $200 | $350 |
| Infrastructure | $800 | $1500 | $2800 |
| Monitoring/tools | $100 | $200 | $400 |
| **Total** | **$2300** | **$4803** | **$8650** |

## Team Structure Impact

| Team Size | Expected Monthly | Per-Developer |
|-----------|------------------|---------------|
| 10 developers | $3000-4500 | $300-450 |
| 20 developers | $5000-7500 | $250-375 |
| 30 developers | $7000-10000 | $230-333 |

*Economies of scale emerge at 15+ developers due to shared infrastructure*

## Risk Management

| Risk | Impact | Mitigation |
|------|--------|------------|
| Runaway API costs | 3-5x overage | Per-project hard limits |
| Hardware failure | $500-2000 emergency | Redundancy, spares |
| Vendor lock-in | Price increases | Multi-provider strategy |
| Team churn | Knowledge loss | Documentation, runbooks |

## Success Metrics

- Stay within budget 95% of months
- Process 1000+ tickets/month across projects
- <50% of calls go to paid APIs
- Per-ticket cost <$4 (at scale)
- 99.9% infrastructure uptime
- <5% unplanned overruns

## Governance

### Weekly Reviews
- Per-project spend vs budget
- API usage patterns
- Optimization opportunities

### Monthly Deep Dives
- Cost per feature by project
- Model performance comparison
- Infrastructure utilization

### Quarterly Planning
- Budget adjustments
- Model/provider evaluation
- Capacity planning

## Calibration Plan

**Month 1**: Baseline all projects
**Month 2-3**: Optimize routing and caching
**Quarter 2**: Full cost attribution
**Quarter 3+**: Continuous optimization

---

*Scale efficiently. The goal is 10x output at 3x cost, not 10x output at 10x cost.*
