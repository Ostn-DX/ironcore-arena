---
title: Quality Gates Overview
type: gate
layer: enforcement
status: active
tags:
  - quality
  - gates
  - ci-cd
  - enforcement
  - automation
  - philosophy
depends_on: []
used_by:
  - "[Build_Gate]]"
  - "[[Unit_Tests_Gate]]"
  - "[[Determinism_Replay_Gate]]"
  - "[[Headless_Match_Batch_Gate]]"
  - "[[UI_Smoke_Gate]]"
  - "[[Performance_Gate]]"
  - "[[Content_Validation_Gate]]"
  - "[[Lint_Static_Analysis_Gate]]"
  - "[[Security_Secret_Scanning_Gate]]"
  - "[[Packaging_Gate]]"
  - "[[Regression_Harness_Spec]"
---

# Quality Gates Overview

## Philosophy: Gates Make Autonomy Safe

Quality gates are the enforcement layer that transforms autonomous AI development from dangerous to trustworthy. Without gates, autonomy produces chaos; with gates, autonomy produces velocity.

### Core Principles

**1. Fail Fast, Fail Clear**
Every gate must provide an unambiguous pass/fail result within 60 seconds of local execution. Ambiguity is the enemy of autonomy.

**2. Deterministic Enforcement**
A gate that passes on one machine must pass on all machines. Environment drift is a gate failure mode.

**3. Remediation is Mandatory**
Every failure mode must have a documented remediation path. "Figure it out" is not acceptable.

**4. Gate Composition**
Gates compose into pipelines. A pipeline is only as strong as its weakest gate.

### Gate Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    QUALITY GATE PIPELINE                     │
├─────────────────────────────────────────────────────────────┤
│  LAYER 1: BUILD                                              │
│  ├── Build_Gate: Compilation must succeed                    │
│  └── Duration: < 5 minutes                                   │
├─────────────────────────────────────────────────────────────┤
│  LAYER 2: STATIC ANALYSIS                                    │
│  ├── Lint_Static_Analysis_Gate: Code quality checks          │
│  ├── Security_Secret_Scanning_Gate: Secret detection         │
│  └── Duration: < 2 minutes                                   │
├─────────────────────────────────────────────────────────────┤
│  LAYER 3: UNIT TESTS                                         │
│  ├── Unit_Tests_Gate: Core logic validation                  │
│  └── Duration: < 10 minutes                                  │
├─────────────────────────────────────────────────────────────┤
│  LAYER 4: INTEGRATION                                        │
│  ├── Determinism_Replay_Gate: Replay consistency             │
│  ├── Headless_Match_Batch_Gate: Batch simulation testing     │
│  └── Duration: < 30 minutes                                  │
├─────────────────────────────────────────────────────────────┤
│  LAYER 5: VALIDATION                                         │
│  ├── Content_Validation_Gate: Asset/data integrity           │
│  ├── UI_Smoke_Gate: Critical path automation                 │
│  └── Duration: < 15 minutes                                  │
├─────────────────────────────────────────────────────────────┤
│  LAYER 6: PERFORMANCE                                        │
│  ├── Performance_Gate: FPS, memory, load time budgets        │
│  └── Duration: < 20 minutes                                  │
├─────────────────────────────────────────────────────────────┤
│  LAYER 7: PACKAGING                                          │
│  ├── Packaging_Gate: Steam build correctness                 │
│  └── Duration: < 30 minutes                                  │
└─────────────────────────────────────────────────────────────┘
```

### Gate Execution Contexts

| Context | Trigger | Parallelism | Failure Action |
|---------|---------|-------------|----------------|
| Local Dev | Manual/pre-commit | Single-threaded | Block commit |
| CI/PR | Pull request | Parallel jobs | Block merge |
| Nightly | Scheduled | Full parallel | Alert + ticket |
| Release | Tag push | Full parallel | Block release |

### Gate Specification Template

Every gate must define:

1. **Tool/Script**: The executable that performs the check
2. **Local Run**: Command for developer execution
3. **CI Run**: Command for CI environment
4. **Pass Threshold**: Numeric or boolean success criteria
5. **Fail Threshold**: Numeric or boolean failure criteria
6. **Failure Mode**: What happens when the gate fails
7. **Remediation**: Step-by-step recovery instructions

### Gate Inheritance

New gates should be created using [[Gate_Template]] as the base. The template ensures consistency across all quality enforcement.

### Gate Metrics

Track these metrics for every gate:
- **Flakiness Rate**: % of runs with inconsistent results (target: < 1%)
- **Mean Execution Time**: Average duration (target: see layer specs)
- **False Positive Rate**: % of failures that were not real issues (target: < 5%)
- **Remediation Success Rate**: % of failures resolved by documented steps (target: > 90%)

### Emergency Gate Override

In exceptional circumstances, a gate may be temporarily bypassed:

1. Requires approval from Tech Lead + Producer
2. Must be documented in [[Known_Risk_Acceptance_Checklist]]
3. Must have rollback plan in [[Rollback_Plan_Checklist]]
4. Must have remediation ticket with deadline
5. Override expires automatically in 48 hours

### Gate Evolution

Gates are not static. They evolve based on:
- Postmortem findings (see [[Postmortem_Process]])
- Architecture changes (see [[Architecture_Decay_Controls]])
- Production incident patterns
- Tooling improvements

All gate changes must update [[Gate_Template]] and trigger re-certification of dependent gates.

### Related Documentation

- [[Regression_Harness_Spec]]: How gates integrate with regression testing
- [[Risk_Taxonomy]]: What gates can and cannot catch
- [[Release_Certification_Checklist]]: Final release validation
