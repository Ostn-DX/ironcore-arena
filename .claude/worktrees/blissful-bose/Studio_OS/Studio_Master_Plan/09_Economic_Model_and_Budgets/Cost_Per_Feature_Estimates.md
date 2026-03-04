---
title: Cost Per Feature Estimates
type: decision
layer: execution
status: active
tags:
  - costing
  - features
  - estimates
  - pricing
  - planning
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Model_Cost_Matrix]"
used_by:
  - "[Monthly_Budget_Prototype_Tier]]"
  - "[[Monthly_Budget_Indie_Tier]]"
  - "[[Monthly_Budget_MultiProject_Tier]]"
  - "[[ROI_Optimization_Rules]"
---

# Cost Per Feature Estimates

## Overview

Use these estimates for sprint planning, budget allocation, and ROI analysis. All figures include model calls, compute, and reasonable rework.

## Feature Classification

### Class A: Simple Features (1-3 days)

**Definition**: Single component, well-understood domain, clear requirements

**Examples**:
- UI component with standard patterns
- CRUD endpoint for existing entity
- Simple validation logic
- Configuration change

**Cost Estimates**:

| Tier | Low | Likely | High | Notes |
|------|-----|--------|------|-------|
| Prototype | $0.50 | $1.50 | $4 | Mostly local |
| Indie | $1 | $3 | $8 | Mixed local/API |
| Multi-Project | $2 | $5 | $12 | Full tooling |

**Token Breakdown (Likely)**:
- Planning: 2K input, 500 output
- Implementation: 5K input, 2K output
- Review: 3K input, 1K output
- **Total**: ~10K input, 3.5K output

**Model Mix**:
- 80% local (7B/8B models)
- 20% API (Tier 1-2)

### Class B: Medium Features (3-7 days)

**Definition**: Multiple components, some complexity, integration required

**Examples**:
- New service/module
- Authentication flow
- Data migration
- API integration

**Cost Estimates**:

| Tier | Low | Likely | High | Notes |
|------|-----|--------|------|-------|
| Prototype | $3 | $8 | $20 | Careful API use |
| Indie | $8 | $20 | $50 | Balanced approach |
| Multi-Project | $15 | $35 | $80 | Full review |

**Token Breakdown (Likely)**:
- Architecture: 5K input, 2K output
- Implementation: 15K input, 6K output
- Testing: 5K input, 2K output
- Review: 8K input, 3K output
- **Total**: ~33K input, 13K output

**Model Mix**:
- 60% local (8B/14B models)
- 40% API (Tier 2)

### Class C: Complex Features (1-2 weeks)

**Definition**: System-level changes, significant architecture, multiple integrations

**Examples**:
- New microservice
- Real-time system
- Complex algorithm implementation
- Major refactoring

**Cost Estimates**:

| Tier | Low | Likely | High | Notes |
|------|-----|--------|------|-------|
| Prototype | $15 | $35 | $80 | Limited scope |
| Indie | $40 | $100 | $250 | Full process |
| Multi-Project | $80 | $180 | $400 | Team review |

**Token Breakdown (Likely)**:
- Design: 10K input, 5K output
- Architecture: 8K input, 4K output
- Implementation: 30K input, 15K output
- Testing: 10K input, 5K output
- Review: 15K input, 8K output
- **Total**: ~73K input, 37K output

**Model Mix**:
- 40% local (14B models)
- 60% API (Tier 2-3)

### Class D: Major Features (2-4 weeks)

**Definition**: New subsystem, significant user-facing change, cross-cutting concerns

**Examples**:
- New game system
- Multiplayer networking
- AI behavior system
- Content pipeline

**Cost Estimates**:

| Tier | Low | Likely | High | Notes |
|------|-----|--------|------|-------|
| Prototype | $50 | $120 | $300 | MVP only |
| Indie | $150 | $400 | $1000 | Production |
| Multi-Project | $300 | $700 | $1500 | Enterprise |

**Token Breakdown (Likely)**:
- Discovery: 15K input, 8K output
- Design: 20K input, 12K output
- Implementation: 80K input, 40K output
- Testing: 25K input, 15K output
- Review: 30K input, 20K output
- Documentation: 10K input, 8K output
- **Total**: ~180K input, 103K output

**Model Mix**:
- 30% local (14B/70B models)
- 70% API (Tier 2-3)

### Class E: Epic Features (1-2 months)

**Definition**: Major product areas, foundational changes, significant unknowns

**Examples**:
- New game mode
- Platform migration
- Major engine upgrade
- New monetization system

**Cost Estimates**:

| Tier | Low | Likely | High | Notes |
|------|-----|--------|------|-------|
| Prototype | $200 | $500 | $1200 | Proof of concept |
| Indie | $600 | $1500 | $4000 | Full delivery |
| Multi-Project | $1200 | $3000 | $8000 | Multi-team |

**Token Breakdown (Likely)**:
- Discovery/Research: 50K input, 30K output
- Architecture: 40K input, 25K output
- Implementation: 200K input, 120K output
- Testing: 60K input, 40K output
- Review/Iteration: 80K input, 50K output
- Documentation: 30K input, 25K output
- **Total**: ~460K input, 290K output

**Model Mix**:
- 20% local (largest models)
- 80% API (Tier 2-3, heavy Tier 3)

## Feature Type Adjustments

### Multiplier Factors

| Factor | Multiplier | Examples |
|--------|------------|----------|
| New domain | 1.3-1.5 | Unfamiliar tech stack |
| Legacy code | 1.2-1.4 | Working with old systems |
| High stakes | 1.2-1.3 | Security, payments |
| Tight deadline | 1.1-1.3 | Rushed work, more rework |
| Well-documented | 0.8-0.9 | Clear specs, examples |
| Reuse possible | 0.7-0.8 | Similar to existing |

## Cost Optimization by Feature Class

### Class A (Simple)
- Use local models exclusively
- Aggressive caching
- Minimal review

### Class B (Medium)
- Start local, escalate if needed
- Standard review process
- Cache common patterns

### Class C (Complex)
- Architecture review required
- Mixed local/API approach
- Document decisions for reuse

### Class D (Major)
- Full design document
- API models for critical decisions
- Multiple review cycles

### Class E (Epic)
- Discovery phase first
- Spike/prototype validation
- Phased implementation

## Planning Template

```yaml
feature_estimate:
  name: "Feature Name"
  class: B
  base_cost:
    low: $8
    likely: $20
    high: $50
  
  adjustments:
    new_domain: 1.3
    tight_deadline: 1.2
  
  adjusted_cost:
    low: $12
    likely: $31
    high: $78
  
  model_mix:
    local: 60%
    api_tier1: 10%
    api_tier2: 30%
  
  confidence: medium
```

## Measurement Plan

1. **Track actual vs estimated** for 20 features per class
2. **Calculate variance** and adjust multipliers
3. **Review monthly** and update estimates
4. **Build team-specific** factors (some teams are more efficient)

---

*These are starting points. Your actual costs will vary. Measure and calibrate.*
