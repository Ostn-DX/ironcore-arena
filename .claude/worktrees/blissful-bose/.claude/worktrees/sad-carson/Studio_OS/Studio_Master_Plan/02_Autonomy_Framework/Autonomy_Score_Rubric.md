---
title: Autonomy Score Rubric
type: system
layer: enforcement
status: active
tags:
  - autonomy
  - scoring
  - rubric
  - metrics
  - evaluation
depends_on:
  - "[Autonomy_Ladder_L0_L5]]"
  - "[[Studio_Priorities_Manifesto]"
used_by:
  - "[L0_Manual_Operation]]"
  - "[[L1_Assisted_Operation]]"
  - "[[L2_Supervised_Autonomy]]"
  - "[[L3_Conditional_Autonomy]]"
  - "[[L4_High_Autonomy]]"
  - "[[L5_Full_Autonomy]]"
  - "[[Autonomy_Upgrade_Path]"
---

# Autonomy Score Rubric

## Purpose

The Autonomy Score Rubric provides a quantitative 0-100 scoring system for evaluating autonomy readiness. Scores determine which autonomy level is appropriate for a given context and track progress toward higher autonomy.

## Score Categories

The total score is calculated across five categories, each contributing 0-20 points:

| Category | Weight | Measures |
|----------|--------|----------|
| Pattern Maturity | 20% | Availability of established patterns |
| Historical Success | 20% | Track record of similar work |
| Context Clarity | 20% | Completeness of specifications |
| Risk Profile | 20% | Blast radius of potential failures |
| Resource Availability | 20% | Access to required tools and data |

## Category Scoring

### Category 1: Pattern Maturity (0-20 points)

Measures how well-established the patterns are for this type of work.

| Score | Description | Criteria |
|-------|-------------|----------|
| 0-4 | Novel | No similar work done before |
| 5-8 | Emerging | Some related work, but not this specific type |
| 9-12 | Established | Similar work done 2-5 times |
| 13-16 | Mature | Similar work done 6-10 times |
| 17-20 | Proven | Similar work done 10+ times with high success |

**Scoring Factors**:
- Number of similar completed tickets
- Similarity score to historical work
- Pattern documentation completeness
- Template availability

### Category 2: Historical Success (0-20 points)

Measures the success rate of similar work in the past.

| Score | Description | Criteria |
|-------|-------------|----------|
| 0-4 | Poor | <50% success rate |
| 5-8 | Below Average | 50-70% success rate |
| 9-12 | Average | 70-85% success rate |
| 13-16 | Good | 85-95% success rate |
| 17-20 | Excellent | >95% success rate |

**Scoring Factors**:
- First-attempt gate pass rate
- Escalation rate for similar work
- Rework rate for similar work
- Time since last failure

### Category 3: Context Clarity (0-20 points)

Measures the completeness and clarity of specifications and context.

| Score | Description | Criteria |
|-------|-------------|----------|
| 0-4 | Vague | Minimal context, many open questions |
| 5-8 | Incomplete | Some context, several gaps |
| 9-12 | Adequate | Most context available, minor gaps |
| 13-16 | Complete | Full context, clear specifications |
| 17-20 | Comprehensive | Full context with examples and edge cases |

**Scoring Factors**:
- Acceptance criteria completeness
- Linked specifications available
- Example implementations referenced
- Edge cases documented
- Dependencies identified

### Category 4: Risk Profile (0-20 points)

Measures the safety and reversibility of the work. Higher is safer.

| Score | Description | Criteria |
|-------|-------------|----------|
| 0-4 | High Risk | Irreversible, production impact, data loss possible |
| 5-8 | Elevated | Reversible-with-cost, system impact |
| 9-12 | Moderate | Reversible, module impact |
| 13-16 | Low | Easily reversible, local impact |
| 17-20 | Minimal | No production impact, fully reversible |

**Scoring Factors**:
- Reversibility of changes
- Scope of impact (local/module/system/organization)
- Production vs. development environment
- Data modification risk
- External dependency risk

### Category 5: Resource Availability (0-20 points)

Measures access to required tools, data, and resources.

| Score | Description | Criteria |
|-------|-------------|----------|
| 0-4 | Unavailable | Critical resources missing |
| 5-8 | Limited | Some resources available, gaps remain |
| 9-12 | Partial | Most resources available |
| 13-16 | Available | All required resources accessible |
| 17-20 | Optimal | All resources available with excess capacity |

**Scoring Factors**:
- Tool availability
- Data access
- Compute resources
- API budget available
- Human expertise available if needed

## Total Score Interpretation

| Total Score | Recommended Autonomy Level | Description |
|-------------|---------------------------|-------------|
| 0-20 | L0 (Manual) | Too risky for any automation |
| 21-35 | L1 (Assisted) | Human-driven with AI support |
| 36-55 | L2 (Supervised) | AI-driven with human checkpoints |
| 56-75 | L3 (Conditional) | AI-driven with auto-gates |
| 76-90 | L4 (High) | AI-driven, milestone reviews only |
| 91-100 | L5 (Full) | Full self-operation |

## Score Calculation Example

```
Ticket: Implement player movement controller

Category 1 - Pattern Maturity: 16/20
  - Similar controllers implemented 8 times
  - Pattern well-documented
  - Template available

Category 2 - Historical Success: 18/20
  - 95% first-attempt pass rate
  - Last failure 3 months ago
  - Low escalation rate

Category 3 - Context Clarity: 15/20
  - Clear acceptance criteria
  - Input handling spec linked
  - Physics parameters documented

Category 4 - Risk Profile: 17/20
  - Fully reversible changes
  - Local impact only
  - Development environment

Category 5 - Resource Availability: 19/20
  - All tools available
  - Engine templates ready
  - Test framework accessible

TOTAL: 85/100
RECOMMENDED AUTONOMY: L4 (High Autonomy)
```

## Score Tracking

### Per-Ticket Scores
- Every ticket scored at creation
- Score recalculated if context changes
- Final score recorded on completion
- Scores feed into historical metrics

### Aggregate Metrics
- Average score by work type
- Score distribution across tickets
- Score trends over time
- Correlation with outcomes

## Score Override Rules

1. **Human Override**: Human can specify any autonomy level, regardless of score
2. **Safety Override**: Risk score <5 forces maximum L2 autonomy
3. **Cost Override**: Budget constraints may force lower autonomy
4. **Learning Override**: Deliberate practice may use lower autonomy than score suggests

## Score Improvement

To improve scores and enable higher autonomy:

| Category | Improvement Actions |
|----------|---------------------|
| Pattern Maturity | Document patterns, create templates, build library |
| Historical Success | Fix failure modes, enhance gates, improve training |
| Context Clarity | Write better specs, include examples, document edge cases |
| Risk Profile | Add safety checks, improve reversibility, scope reduction |
| Resource Availability | Provision tools, cache data, budget allocation |

## Score Validation

- Scores validated against actual outcomes
- Prediction accuracy tracked
- Scoring model adjusted based on results
- Quarterly review of scoring criteria

## Enforcement

- Score calculated automatically for every ticket
- Score visible in ticket metadata
- Recommended autonomy level suggested
- Override requires explicit justification
