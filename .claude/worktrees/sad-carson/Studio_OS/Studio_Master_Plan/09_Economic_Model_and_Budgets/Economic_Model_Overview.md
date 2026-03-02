---
title: Economic Model Overview
type: system
layer: architecture
status: active
tags:
  - economics
  - cost-model
  - budget
  - philosophy
  - measurement
depends_on: []
used_by:
  - "[Model_Cost_Matrix]]"
  - "[[Monthly_Budget_Prototype_Tier]]"
  - "[[Monthly_Budget_Indie_Tier]]"
  - "[[Monthly_Budget_MultiProject_Tier]]"
  - "[[Token_Burn_Controls]]"
  - "[[Compute_Burn_Controls]]"
  - "[[Calibration_Protocol]]"
---

# Economic Model Overview

## Cost Philosophy: Local-First, Intelligence-Second

The OpenClaw economic model is built on a fundamental principle: **minimize recurring costs while maximizing autonomous capability**. This is not austerity for its own sake—it is a strategic choice that forces smarter architecture, better caching, and more efficient agent design.

### Core Tenets

**1. Local-First Execution**
- Default to local models (Ollama, LM Studio, local LLaMA variants)
- Paid API calls are explicit opt-in decisions, not defaults
- Every paid call must justify its cost through measurable value

**2. Intelligence Tiering**
- Simple tasks → Local small models (3B-7B parameters)
- Complex reasoning → Local medium models (13B parameters)
- Exceptional cases only → Paid APIs (GPT-4, Claude, etc.)

**3. Aggressive Caching**
- Embedding results cached indefinitely
- Code generation outputs cached by hash
- Agent decisions cached with confidence thresholds

**4. Measurement Over Estimation**
- All cost assumptions must be validated
- Every budget tier includes calibration protocol
- Real usage data overrides theoretical models

## Cost Categories

### Token Costs (Primary Variable)
- **Input tokens**: Prompts, context, retrieved documents
- **Output tokens**: Generated code, decisions, summaries
- **Pricing models**: Per-1K tokens, subscription, or hybrid

### Compute Costs (Fixed + Variable)
- **Local GPU**: Amortized hardware cost, electricity
- **VPS/Cloud**: Hourly rates, egress fees
- **Serverless**: Per-invocation pricing

### Storage Costs (Typically Minor)
- Vector database hosting
- Artifact storage (builds, logs)
- Cache storage with TTL policies

### Human Costs (Often Ignored)
- Review time for AI outputs
- Correction and rework cycles
- Context switching overhead

## Measurement Framework

### Primary Metrics

| Metric | Definition | Target Frequency |
|--------|------------|------------------|
| Cost Per Ticket | Total spend / tickets processed | Daily |
| Cost Per Feature | Spend / features delivered | Weekly |
| Token Efficiency | Output tokens / input tokens | Per-call |
| Cache Hit Rate | Cached responses / total calls | Hourly |
| Paid Call Ratio | Paid calls / total calls | Daily |

### Secondary Metrics

- **Time-to-first-token**: Latency impact on developer flow
- **Error rate by model tier**: Quality vs cost correlation
- **Rework rate**: Percentage of outputs requiring revision
- **Agent autonomy ratio**: Human interventions per 100 tickets

## Calibration Approach

All cost estimates in this economic model are **calibrated estimates**—not guesses, not guarantees. The calibration protocol requires:

1. **Baseline Measurement**: Run 20 representative tickets through each model tier
2. **Statistical Analysis**: Calculate mean, median, P95 costs
3. **Confidence Intervals**: Express ranges as low/likely/high
4. **Regular Recalibration**: Re-measure monthly or when models change

## Budget Tier Philosophy

Three tiers exist not as rigid boxes but as **operational modes**:

- **Prototype Tier**: Validate the concept, minimize burn
- **Indie Tier**: Production-ready with cost discipline
- **Multi-Project Tier**: Scale through efficiency, not spending

Each tier represents a different point on the cost-capability curve. The goal is to operate at the optimal point for your current stage.

## Cost Control Hierarchy

1. **Prevention**: Don't make expensive calls (caching, local models)
2. **Detection**: Monitor spend in real-time (dashboards, alerts)
3. **Intervention**: Stop runaway costs (emergency brakes)
4. **Recovery**: Learn and adjust (post-mortems, calibration)

## Key Assumptions (To Be Validated)

- Local 7B models handle 70% of tasks adequately
- Caching reduces API calls by 40-60%
- Human review costs exceed AI costs for simple tasks
- Token prices decline 20-30% annually

## Measurement Plan

**Week 1-2**: Deploy instrumentation, establish baselines
**Week 3-4**: Run calibration suite, validate assumptions
**Month 2+**: Continuous monitoring with monthly deep-dives
**Quarterly**: Full model review, tier adjustment recommendations

---

*This model is a living document. Costs change, models improve, and assumptions fail. The only constant is measurement.*
