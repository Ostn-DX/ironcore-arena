---
title: Monthly Budget - Indie Tier
type: template
layer: execution
status: active
tags:
  - budget
  - indie
  - tier-2
  - studio
  - production
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Model_Cost_Matrix]]"
  - "[[Monthly_Budget_Prototype_Tier]"
used_by:
  - "[Calibration_Protocol]]"
  - "[[Cost_Monitoring_Dashboard_Spec]]"
  - "[[ROI_Optimization_Rules]"
---

# Monthly Budget: Indie Tier

## Target: $500-2000/month

This tier supports small studios (2-5 developers) in production. Balance between capability and cost discipline remains critical.

## Budget Allocation

### Hardware (One-Time or Amortized)

| Component | Specification | Cost | Monthly (36mo) |
|-----------|---------------|------|----------------|
| Primary GPU | RTX 4070 Ti Super 16GB | $800 | $22 |
| Secondary GPU | RTX 3060 12GB (used) | $250 | $7 |
| Workstation | 64GB RAM, fast CPU | $1500 | $42 |
| Total Hardware | - | $2550 | $71 |

### API Budget: $300-800/month

| Service | Allocation | Expected Usage |
|---------|------------|----------------|
| OpenAI GPT-4o | $200 | Complex tasks, review |
| Anthropic Claude 3.5 Sonnet | $250 | Architecture, debugging |
| Google Gemini Pro | $100 | Balanced workloads |
| OpenRouter (flex) | $100 | Model diversity |
| Buffer | $50-100 | Overflow, experiments |

### Infrastructure: $150-400/month

| Service | Tier | Cost | Purpose |
|---------|------|------|---------|
| GitHub Team | 5 seats | $20 | Repos, Actions |
| Vercel Pro | - | $20 | Deployments |
| Railway/Render | Standard | $50-100 | Services |
| Pinecone/Weaviate | Standard | $70-150 | Vector DB |
| AWS/GCP (minimal) | - | $50-100 | Storage, egress |
| Monitoring | - | $20-50 | Logs, metrics |

## Model Configuration

### Primary: Local Models (60% of workload)

```yaml
local_models:
  fast: llama3.1:8b          # 70% of local calls
  capable: qwen2.5:14b       # 25% of local calls
  powerful: llama3.1:70b-q4  # 5% of local calls
  embedding: nomic-embed-text
  code: deepseek-coder:33b
```

**Expected daily usage**:
- 2000-4000 local calls/day across team
- 20K-50K tokens generated/day locally
- Cost: ~$30-50/month (electricity, amortization)

### Secondary: API Models (40% of workload)

```yaml
api_models:
  balanced: gpt-4o
  reasoning: claude-3.5-sonnet
  fast_cheap: gemini-1.5-flash
  coding: claude-3.5-sonnet
  emergency: gpt-4o-mini
```

**Expected daily usage**:
- 500-1000 API calls/day across team
- 1M-3M input tokens/month
- 500K-1.5M output tokens/month
- Cost: ~$400-700/month

## Team Distribution

| Role | Daily API Calls | Daily Local Calls | Monthly API Budget |
|------|-----------------|-------------------|-------------------|
| Tech Lead | 50 | 100 | $150 |
| Senior Dev | 40 | 150 | $120 |
| Mid Dev | 30 | 200 | $90 |
| Junior Dev | 20 | 150 | $60 |
| Shared/CI | 100 | 500 | $200 |

## Daily Limits (Per-Role)

| Metric | Daily Limit | Action at Limit |
|--------|-------------|-----------------|
| API calls (individual) | 100 | Throttle to local |
| API calls (team) | 500 | Queue for tomorrow |
| Daily API spend | $30 | Hard stop |
| Consecutive API calls | 20 | Force local retry |

## Cost Control Measures

### Intelligent Routing

```yaml
routing_rules:
  code_completion:
    primary: local_8b
    confidence_threshold: 0.7
    
  code_review:
    primary: local_14b
    fallback: claude-sonnet
    
  architecture:
    primary: claude-sonnet
    fallback: gpt-4o
    
  bug_investigation:
    primary: local_14b
    fallback: claude-sonnet
    max_depth: 3
```

### Caching Strategy (Aggressive)

| Cache Type | TTL | Expected Hit Rate |
|------------|-----|-------------------|
| Embeddings | Infinite | 80%+ |
| Code gen (exact match) | 7 days | 30% |
| Code gen (fuzzy match) | 3 days | 15% |
| Agent decisions | 24 hours | 40% |
| **Overall** | - | **50-60%** |

### Team Policies

- Morning standup: Review yesterday's spend
- Weekly: Cost review meeting (15 min)
- Monthly: Deep dive on optimization opportunities
- Quarterly: Model and pricing review

## Expected Monthly Breakdown

| Category | Low | Likely | High |
|----------|-----|--------|------|
| API calls | $300 | $550 | $850 |
| Hardware (amortized) | $50 | $71 | $100 |
| Electricity/local | $25 | $40 | $60 |
| Infrastructure | $150 | $250 | $400 |
| **Total** | **$525** | **$911** | **$1410** |

## Assumptions

- 3-5 active developers
- 150-300 tickets processed per month
- 60% of tasks handled locally
- Average ticket requires 3-5 model calls
- Cache hit rate of 50-60%
- 20-22 working days per month

## Risk Factors

| Risk | Impact | Mitigation |
|------|--------|------------|
| Team growth | +$200/dev/month | Per-dev budgets |
| Model price hikes | 20-30% overage | Price lock-ins |
| Unexpected complexity | 2x API usage | Daily limits |
| CI/CD costs | Variable | Caching, local runners |

## Success Metrics

- Stay within $500-1500/month 90% of months
- Process 200+ tickets/month
- <40% of calls go to paid APIs
- Per-ticket cost <$5
- Zero unplanned overruns >20%

## Upgrade Triggers

Consider moving to Multi-Project Tier when:
- Multiple active projects requiring isolation
- Team exceeds 5 developers
- Monthly spend consistently >$1500
- Need dedicated infrastructure per project
- Enterprise requirements (SSO, compliance)

## Calibration Plan

**Week 1-2**: Baseline measurement per developer
**Week 3-4**: Team pattern analysis
**Month 2**: Optimize routing rules
**Month 3**: Full calibration report
**Quarterly**: Re-calibrate with new models/prices

---

*This tier is the sweet spot for most indie studios. Enough budget to be productive, tight enough to stay disciplined.*
