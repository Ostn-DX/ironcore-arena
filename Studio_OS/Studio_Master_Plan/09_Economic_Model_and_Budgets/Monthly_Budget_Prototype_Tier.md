---
title: Monthly Budget - Prototype Tier
type: template
layer: execution
status: active
tags:
  - budget
  - prototype
  - tier-1
  - startup
  - low-cost
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Model_Cost_Matrix]"
used_by:
  - "[Calibration_Protocol]]"
  - "[[Cost_Monitoring_Dashboard_Spec]"
---

# Monthly Budget: Prototype Tier

## Target: <$100/month

This tier is designed for solo developers, early prototypes, and validation phases. The goal is maximum learning with minimum burn.

## Budget Allocation

### Hardware (One-Time or Amortized)

| Component | Option A | Option B | Recommendation |
|-----------|----------|----------|----------------|
| GPU | Use existing | RTX 3060 12GB (used) | Start with existing |
| RAM | 16GB minimum | 32GB preferred | 16GB acceptable |
| Storage | 500GB SSD | 1TB NVMe | 500GB minimum |

**One-time cost**: $0-300 (if buying used GPU)
**Amortized monthly**: $0-25 (over 12 months)

### API Budget: $50-75/month

| Service | Allocation | Expected Usage |
|---------|------------|----------------|
| OpenAI GPT-4o Mini | $20 | ~13K calls/month |
| Anthropic Claude Haiku | $15 | ~5K calls/month |
| Google Gemini Flash | $10 | ~6K calls/month |
| Buffer/Overflow | $10-20 | Unexpected needs |

### Infrastructure: $0-25/month

| Service | Cost | Purpose |
|---------|------|---------|
| GitHub (free tier) | $0 | Repos, Actions (limited) |
| Vercel/Railway (hobby) | $0-20 | Preview deployments |
| Supabase (free tier) | $0 | Database, auth |
| Vector DB (local) | $0 | Chroma, Qdrant local |

## Model Configuration

### Primary: Local Models (70% of workload)

```yaml
local_models:
  primary: llama3.1:8b
  fallback: phi3:medium
  embedding: nomic-embed-text
```

**Expected daily usage**:
- 500-1000 local calls/day
- 2K-5K tokens generated/day locally
- Cost: ~$5-10/month (electricity)

### Secondary: API Models (30% of workload)

```yaml
api_models:
  simple_tasks: gemini-1.5-flash
  complex_tasks: gpt-4o-mini
  emergency: claude-3-haiku
```

**Expected daily usage**:
- 50-100 API calls/day
- 150K-300K input tokens/month
- 50K-100K output tokens/month
- Cost: ~$40-60/month

## Daily Limits (Hard Stops)

| Metric | Daily Limit | Monthly Projection |
|--------|-------------|-------------------|
| API calls | 100 | 3,000 |
| Input tokens | 10K | 300K |
| Output tokens | 5K | 150K |
| Total API spend | $3 | $90 |

## Cost Control Measures

### Automatic Throttling

```yaml
throttling:
  daily_api_calls: 100
  daily_token_spend: $2.50
  consecutive_failures: 5
  
actions:
  at_50%: "warn"
  at_80%: "throttle_to_local_only"
  at_100%: "hard_stop"
```

### Caching Strategy

- Embed results: Cache indefinitely
- Code generation: Cache by content hash (7 days)
- Agent decisions: Cache with confidence >0.8 (24 hours)
- **Expected cache hit rate**: 40-50%

### Fallback Chain

1. Try local model first
2. If quality < threshold, retry with different local model
3. Only then escalate to API
4. For APIs: Flash → Haiku → Mini (in that order)

## Expected Monthly Breakdown

| Category | Low | Likely | High |
|----------|-----|--------|------|
| API calls | $30 | $55 | $80 |
| Electricity (local) | $3 | $8 | $15 |
| Infrastructure | $0 | $10 | $25 |
| **Total** | **$33** | **$73** | **$120** |

## Assumptions

- 20-30 development days per month
- 50-100 tickets processed per month
- 60-70% of tasks handled locally
- Average ticket requires 2-3 model calls
- Cache hit rate of 40-50%

## Risk Factors

| Risk | Impact | Mitigation |
|------|--------|------------|
| Unexpected API usage | 2x budget | Daily limits, alerts |
| Local model failures | Forced API use | Multiple local models |
| Price increases | 20-30% overage | Buffer in budget |
| Scope creep | More tickets | Ticket size limits |

## Success Metrics

- Stay under $100/month 90% of months
- Process 50+ tickets/month
- <20% of calls go to paid APIs
- Zero emergency budget overruns

## Upgrade Triggers

Consider moving to Indie Tier when:
- Consistently hitting daily limits
- Need for 14B+ local models
- Team expands beyond 1 developer
- Monthly API spend exceeds $75 regularly

## Calibration Plan

**Week 1**: Deploy with limits, observe actual usage
**Week 2**: Adjust limits based on patterns
**Week 3**: Run 20-ticket benchmark
**Week 4**: Finalize monthly projection

---

*This tier proves the model works before scaling. If you can't make it work at $100/month, more budget won't fix the underlying issues.*
