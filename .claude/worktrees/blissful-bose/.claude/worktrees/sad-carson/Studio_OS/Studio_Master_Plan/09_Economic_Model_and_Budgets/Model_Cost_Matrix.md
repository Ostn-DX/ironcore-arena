---
title: Model Cost Matrix
type: decision
layer: architecture
status: active
tags:
  - models
  - pricing
  - comparison
  - local
  - api
  - tokens
depends_on:
  - "[Economic_Model_Overview]"
used_by:
  - "[Monthly_Budget_Prototype_Tier]]"
  - "[[Monthly_Budget_Indie_Tier]]"
  - "[[Monthly_Budget_MultiProject_Tier]]"
  - "[[ROI_Optimization_Rules]]"
  - "[[Cost_Per_Feature_Estimates]]"
---

# Model Cost Matrix

## Overview

This matrix compares all model options across cost dimensions: tokens, compute, time, and quality. Use this for routing decisions and budget planning.

## Local Models (Ollama/LM Studio)

### Small Models (3B-7B Parameters)

| Model | VRAM Required | Load Time | Tokens/Sec | Quality Score |
|-------|---------------|-----------|------------|---------------|
| Phi-3 Mini (3.8B) | 4GB | 2-3s | 45-60 | 6/10 |
| Llama 3.1 (8B) | 6GB | 3-4s | 35-50 | 7/10 |
| Qwen 2.5 (7B) | 6GB | 3-4s | 40-55 | 7/10 |
| Gemma 2 (9B) | 8GB | 4-5s | 30-45 | 7/10 |

**Cost Model**:
- **Low**: $0 (existing hardware)
- **Likely**: $10-30/month (electricity, amortized GPU)
- **High**: $50/month (dedicated mini-PC)

**Best For**: Code completion, simple generation, high-volume low-complexity tasks

### Medium Models (13B-14B Parameters)

| Model | VRAM Required | Load Time | Tokens/Sec | Quality Score |
|-------|---------------|-----------|------------|---------------|
| Qwen 2.5 (14B) | 10GB | 5-7s | 25-35 | 8/10 |
| Llama 3.1 (70B-q4) | 40GB | 15-20s | 8-15 | 9/10 |
| DeepSeek Coder (33B) | 20GB | 8-12s | 15-25 | 8.5/10 |

**Cost Model**:
- **Low**: $30-50/month (RTX 3060 12GB)
- **Likely**: $75-150/month (RTX 4070/4070 Ti)
- **High**: $300-500/month (RTX 4090 or dual GPU)

**Best For**: Complex reasoning, architecture decisions, code review

### Large Models (70B+ Parameters)

| Model | VRAM Required | Load Time | Tokens/Sec | Quality Score |
|-------|---------------|-----------|------------|---------------|
| Llama 3.1 (70B-q4) | 40GB | 15-20s | 8-15 | 9/10 |
| Qwen 2.5 (72B-q4) | 45GB | 18-25s | 6-12 | 9/10 |

**Cost Model**:
- **Low**: $200-300/month (used RTX 3090/4090)
- **Likely**: $400-600/month (dual GPU setup)
- **High**: $800-1200/month (cloud GPU rental)

**Best For**: Exceptional cases, complex multi-file refactoring

## Paid API Models

### Tier 1: Fast & Cheap (Simple Tasks)

| Model | Input/1K | Output/1K | Typical Latency | Quality |
|-------|----------|-----------|-----------------|---------|
| GPT-3.5 Turbo | $0.0005 | $0.0015 | 500-800ms | 7/10 |
| Claude 3 Haiku | $0.00025 | $0.00125 | 400-700ms | 7/10 |
| Gemini 1.5 Flash | $0.000075 | $0.0003 | 300-600ms | 6.5/10 |

**Cost per 1000 calls** (avg 2K input, 1K output):
- **Low**: $1.50 (Flash)
- **Likely**: $3.50 (Haiku/Turbo)
- **High**: $5.00 (with retries)

### Tier 2: Balanced (Most Tasks)

| Model | Input/1K | Output/1K | Typical Latency | Quality |
|-------|----------|-----------|-----------------|---------|
| GPT-4o Mini | $0.00015 | $0.0006 | 600-1000ms | 8/10 |
| Claude 3.5 Sonnet | $0.003 | $0.015 | 800-1500ms | 9/10 |
| Gemini 1.5 Pro | $0.00125 | $0.005 | 700-1200ms | 8.5/10 |

**Cost per 1000 calls** (avg 3K input, 1.5K output):
- **Low**: $1.50 (GPT-4o Mini)
- **Likely**: $15-25 (Sonnet/Pro)
- **High**: $40 (with context window usage)

### Tier 3: Premium (Complex Tasks)

| Model | Input/1K | Output/1K | Typical Latency | Quality |
|-------|----------|-----------|-----------------|---------|
| GPT-4o | $0.0025 | $0.01 | 1000-2000ms | 9/10 |
| Claude 3.5 Opus | $0.015 | $0.075 | 1500-3000ms | 9.5/10 |
| o1-preview | $0.015 | $0.06 | 5000-15000ms | 9.5/10 |

**Cost per 1000 calls** (avg 4K input, 2K output):
- **Low**: $15 (GPT-4o)
- **Likely**: $80-150 (Opus/o1)
- **High**: $300+ (with reasoning tokens)

## Cost Comparison Summary

### Per-1K-Tokens-Generated (All-In)

| Approach | Low | Likely | High | Notes |
|----------|-----|--------|------|-------|
| Local 7B | $0.0001 | $0.0005 | $0.001 | Amortized hardware |
| Local 14B | $0.0005 | $0.0015 | $0.003 | Better quality |
| API Tier 1 | $0.001 | $0.002 | $0.004 | Fast, no setup |
| API Tier 2 | $0.005 | $0.015 | $0.03 | Best balance |
| API Tier 3 | $0.02 | $0.05 | $0.15 | Premium only |

### Break-Even Analysis

**When does local hardware pay off?**

Assuming $500 GPU investment, 3-year lifespan:
- Break-even vs GPT-3.5: ~150K tokens/day
- Break-even vs GPT-4o Mini: ~50K tokens/day
- Break-even vs GPT-4o: ~10K tokens/day

**For a typical indie studio** (10K-50K tokens/day):
- Local 7B/14B is almost always cheaper
- Reserve APIs for 10-20% of tasks

## Routing Recommendations

| Task Type | Primary | Fallback | Never Use |
|-----------|---------|----------|-----------|
| Code completion | Local 7B | Local 14B | API Tier 3 |
| Simple generation | Local 7B | API Tier 1 | API Tier 2+ |
| Complex refactoring | Local 14B | API Tier 2 | - |
| Architecture design | Local 14B | API Tier 2 | API Tier 3 |
| Debug complex bugs | API Tier 2 | API Tier 3 | - |
| Security review | API Tier 2 | API Tier 3 | Tier 1 |
| Documentation | Local 7B | API Tier 1 | Tier 2+ |

## Measurement Plan

1. **Benchmark Suite**: 50 representative tasks across categories
2. **Quality Scoring**: Human rating 1-10 on usefulness
3. **Cost Tracking**: Actual spend per task type
4. **Recalibration**: Monthly as prices and models change

---

*Prices as of late 2024. Always verify current pricing before committing to budgets.*
