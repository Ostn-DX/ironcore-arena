---
title: Agent Command Flow
type: system
layer: execution
status: active
tags:
  - agent-flow
  - execution
  - pipeline
  - workflow
  - command-chain
depends_on:
  - "[System_Map]]"
  - "[[Dependency_Graph]]"
  - "[[Orchestration_Architecture_Overview]"
used_by:
  - "[Quickstart_OpenClaw]]"
  - "[[How_to_Run_OpenClaw_With_This_Vault]"
---

# Agent Command Flow

## Intent → Tickets → Code → Gate → Release

This document describes the complete flow of work through the OpenClaw system, from human intent to shipped build.

## High-Level Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   HUMAN     │────▶│   TICKET    │────▶│    CODE     │────▶│    GATE     │────▶│  RELEASE    │
│   INTENT    │     │  CREATION   │     │  GENERATION │     │  VALIDATION │     │   MERGE     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │                   │                   │
      ▼                   ▼                   ▼                   ▼                   ▼
   Obsidian          OpenClaw           Agents + Tools        Quality Gates      Git + Steam
```

## Phase 1: Intent Capture

### Input: Human Intent

```yaml
intent:
  source: human
  description: "Add double-jump ability to player controller"
  context:
    - related_feature: "Player movement system"
    - affected_files: ["player_controller.gd"]
    - priority: high
  constraints:
    - max_cost_usd: 5.00
    - max_time_hours: 4
    - autonomy_level: L2
```

### Process: Intent Specification

1. **Human writes intent** in Obsidian using [[Intent_Specification_Format]]
2. **OpenClaw parses** intent into structured format
3. **Context builder** assembles relevant specifications
4. **Autonomy assessor** determines execution level

### Output: Structured Intent

```yaml
parsed_intent:
  id: INTENT-2024-001
  type: feature
  complexity: medium
  estimated_tokens: 15000
  recommended_model: local-medium
  autonomy_level: L2
  required_gates: [build, unit-tests, performance]
```

## Phase 2: Ticket Creation

### Input: Structured Intent

### Process: Spec Decomposition

```
┌─────────────────────────────────────────────────────────────┐
│              SPEC DECOMPOSITION AGENT                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Input: Parsed Intent                                        │
│       │                                                      │
│       ▼                                                      │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Analyze   │───▶│   Break     │───▶│   Sequence  │     │
│  │  Complexity │    │  Into Tasks │    │   Tickets   │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│       │                   │                   │              │
│       ▼                   ▼                   ▼              │
│  Output: Ticket List                                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Output: Tickets

```yaml
tickets:
  - id: TICKET-001
    title: "Implement double-jump state machine"
    type: code
    acceptance_criteria:
      - "Player can jump twice before landing"
      - "Double-jump has 0.2s cooldown"
      - "Animation state transitions correctly"
    
  - id: TICKET-002
    title: "Add double-jump input handling"
    type: code
    depends_on: [TICKET-001]
    acceptance_criteria:
      - "Second jump triggered on second press"
      - "Input buffered for 0.1s"
    
  - id: TICKET-003
    title: "Create double-jump tests"
    type: test
    depends_on: [TICKET-001, TICKET-002]
    acceptance_criteria:
      - "Unit tests for state machine"
      - "Integration tests for input handling"
```

## Phase 3: Code Generation

### Input: Ticket + Context Pack

```yaml
context_pack:
  ticket: TICKET-001
  target_files:
    - path: "player_controller.gd"
      content: "...current implementation..."
  related_files:
    - path: "input_handler.gd"
      content: "...input system..."
  test_files:
    - path: "test_player_controller.gd"
      content: "...existing tests..."
  specs:
    - "Movement_System_Spec.md"
  max_tokens: 32000
```

### Process: Model Routing & Execution

```
┌─────────────────────────────────────────────────────────────┐
│                 CODE GENERATION PIPELINE                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐                                            │
│  │   Route to  │───▶ Local Small Model (7B)                │
│  │   Model     │      Confidence: 0.65                      │
│  └─────────────┘      ├─▶ Below threshold                    │
│       │               │                                      │
│       │               ▼                                      │
│       │          ┌─────────────┐                             │
│       │          │   Escalate  │───▶ Local Medium (13B)      │
│       │          │             │      Confidence: 0.82       │
│       │          └─────────────┘      ├─▶ Within range       │
│       │                               │                      │
│       │                               ▼                      │
│       │                          ┌─────────────┐             │
│       │                          │   Generate  │───▶ Code     │
│       │                          │    Code     │              │
│       │                          └─────────────┘              │
│       │                                                      │
│       └─────────────────────────────────────────────────────▶│
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Output: Generated Code

```yaml
generated_code:
  files:
    - path: "player_controller.gd"
      changes:
        - type: modify
          line_range: [45, 67]
          new_content: |
            # Double-jump implementation
            var jump_count = 0
            var max_jumps = 2
            var jump_cooldown = 0.2
            
            func handle_jump():
                if jump_count < max_jumps and jump_cooldown <= 0:
                    velocity.y = jump_force
                    jump_count += 1
                    jump_cooldown = 0.2
  confidence: 0.82
  estimated_cost: 0.003
```

## Phase 4: Gate Validation

### Input: Generated Code

### Process: Gate Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    GATE PIPELINE                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Layer 1: BUILD                                              │
│  ├─▶ [[Build_Gate]]                                         │
│  ├─▶ Compile check                                          │
│  └─▶ PASS / FAIL                                            │
│                                                              │
│  Layer 2: STATIC ANALYSIS                                    │
│  ├─▶ [[Lint_Static_Analysis_Gate]]                          │
│  ├─▶ Code quality check                                     │
│  └─▶ PASS / FAIL                                            │
│                                                              │
│  Layer 3: UNIT TESTS                                         │
│  ├─▶ [[Unit_Tests_Gate]]                                    │
│  ├─▶ Run test_player_controller.gd                          │
│  └─▶ PASS (12/12) / FAIL                                    │
│                                                              │
│  Layer 4: PERFORMANCE                                        │
│  ├─▶ [[Performance_Gate]]                                   │
│  ├─▶ Check jump processing time < 0.1ms                     │
│  └─▶ PASS (0.03ms) / FAIL                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Output: Gate Results

```yaml
gate_results:
  build_gate:
    status: pass
    duration_ms: 45000
    
  lint_gate:
    status: pass
    warnings: 0
    duration_ms: 8000
    
  unit_tests_gate:
    status: pass
    tests_run: 12
    tests_passed: 12
    duration_ms: 120000
    
  performance_gate:
    status: pass
    jump_time_ms: 0.03
    budget_ms: 0.1
    duration_ms: 180000
    
overall_status: pass
```

## Phase 5: Release Merge

### Input: Passed Gates

### Process: Merge & Deploy

```
┌─────────────────────────────────────────────────────────────┐
│                 MERGE & RELEASE PIPELINE                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Create    │───▶│   Human     │───▶│   Merge     │     │
│  │     PR      │    │   Review    │    │   to Main   │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│       │                   │                   │              │
│       │              (if L2-L3)               │              │
│       │                   │                   ▼              │
│       │              ┌─────────────┐    ┌─────────────┐     │
│       └─────────────▶│   Auto      │───▶│   Deploy    │     │
│                      │   Merge     │    │   to Steam  │     │
│                      │   (if L4+)  │    │             │     │
│                      └─────────────┘    └─────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Output: Released Build

```yaml
release:
  version: "0.4.2"
  commit: "abc123def456"
  tickets_included: [TICKET-001, TICKET-002, TICKET-003]
  gates_passed: [build, lint, unit-tests, performance]
  deployed_to: steam
  deployment_time: "2024-01-15T14:32:00Z"
```

## Complete Flow Diagram

```
Human Intent
    │
    ▼
┌─────────────────┐
│   OBSIDIAN      │
│  Intent Spec    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│   OPENCLAW      │────▶│  Context Pack   │
│     Parser      │     │    Builder      │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│   Spec Decomp   │
│     Agent       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Tickets      │
│   (Created)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Model Router   │────▶│  Local/Medium/  │
│                 │     │   Frontier      │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│  Code Generator │
│     Agent       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Generated Code │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Quality Gates  │
│   (Pipeline)    │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│ PASS  │ │ FAIL  │
└───┬───┘ └───┬───┘
    │         │
    ▼         ▼
┌───────┐ ┌───────────┐
│ Merge │ │ Remediate │
│       │ │   Retry   │
└───┬───┘ └─────┬─────┘
    │           │
    ▼           ▼
┌───────────┐ ┌───────────┐
│  Release  │ │ Escalate  │
│   Steam   │ │  to Human │
└───────────┘ └───────────┘
```

## Flow Metrics

| Phase | Avg Duration | Cost | Failure Rate |
|-------|--------------|------|--------------|
| Intent → Ticket | 2 min | $0.00 | 5% |
| Ticket → Code | 15 min | $0.05 | 15% |
| Code → Gate | 30 min | $0.00 | 10% |
| Gate → Release | 10 min | $0.00 | 2% |
| **Total** | **57 min** | **$0.05** | **28%** |

## Failure Handling

| Failure Point | Response | Escalation |
|---------------|----------|------------|
| Intent parse fail | Request clarification | L1 |
| Model confidence low | Escalate model tier | L2 |
| Gate fail (build) | Auto-fix, retry | L2 |
| Gate fail (tests) | Debug agent, retry | L3 |
| Gate fail (perf) | Optimize, retry | L3 |
| Multiple retries | Human takeover | L0 |

## Enforcement

- Every intent MUST produce at least one ticket
- Every ticket MUST reference at least one gate
- Every code change MUST pass all gates
- Every gate failure MUST have remediation path
- Every release MUST have rollback plan
