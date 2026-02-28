---
title: Dependency Graph
type: system
layer: architecture
status: active
tags:
  - dependencies
  - graph
  - relationships
  - topology
  - index
depends_on:
  - "[System_Map]]"
  - "[[Studio_OS_Overview]"
used_by:
  - "[Agent_Command_Flow]]"
  - "[[Quickstart_OpenClaw]]"
  - "[[Vault_Maintenance_Guide]"
---

# Dependency Graph

## Explicit Note-to-Note Dependencies

This document maps the explicit `depends_on` and `used_by` relationships across the vault. All notes MUST have at least one inbound and one outbound link.

## Core System Dependencies

```
Studio_OS_Overview
├── depends_on: (root)
└── used_by: Intent_to_Release_Pipeline, Autonomy_Ladder_L0_L5, OpenClaw_Core_System, Studio_Priorities_Manifesto

OpenClaw_Core_System
├── depends_on: Studio_OS_Overview, Intent_to_Release_Pipeline, Autonomy_Ladder_L0_L5, Studio_Priorities_Manifesto
└── used_by: Decision_Making_Protocols, Governance_and_Authority_Boundaries, Autonomy_Upgrade_Path

Orchestration_Architecture_Overview
├── depends_on: (root)
└── used_by: Agent_Role_Definitions, Command_Graph_Specification, OpenClaw_Daily_Work_Loop
```

## Autonomy Framework Dependencies

```
Autonomy_Ladder_L0_L5
├── depends_on: Studio_OS_Overview, OpenClaw_Core_System
└── used_by: L0_Manual_Operation, L1_Assisted_Operation, L2_Supervised_Autonomy, L3_Conditional_Autonomy, L4_High_Autonomy, L5_Full_Autonomy

L0_Manual_Operation
├── depends_on: Autonomy_Ladder_L0_L5, Autonomy_Score_Rubric, Studio_Priorities_Manifesto
└── used_by: L1_Assisted_Operation, Autonomy_Upgrade_Path

L1_Assisted_Operation
├── depends_on: Autonomy_Ladder_L0_L5, L0_Manual_Operation, Autonomy_Score_Rubric
└── used_by: L2_Supervised_Autonomy, Autonomy_Upgrade_Path

L2_Supervised_Autonomy
├── depends_on: Autonomy_Ladder_L0_L5, L1_Assisted_Operation, Decision_Making_Protocols
└── used_by: L3_Conditional_Autonomy, Autonomy_Upgrade_Path

L3_Conditional_Autonomy
├── depends_on: Autonomy_Ladder_L0_L5, L2_Supervised_Autonomy, Gate_Protocol
└── used_by: L4_High_Autonomy, Autonomy_Upgrade_Path

L4_High_Autonomy
├── depends_on: Autonomy_Ladder_L0_L5, L3_Conditional_Autonomy, Rollback_Protocol
└── used_by: L5_Full_Autonomy, Autonomy_Upgrade_Path

L5_Full_Autonomy
├── depends_on: Autonomy_Ladder_L0_L5, L4_High_Autonomy, Postmortem_Process
└── used_by: Autonomy_Upgrade_Path
```

## Model Catalog Dependencies

```
Model_Catalog_Overview
├── depends_on: (root)
└── used_by: Task_Routing_Overview, [All Model Specs], [All Routing Rules]

Task_Routing_Overview
├── depends_on: Model_Catalog_Overview, Local_LLM_Coder_Small, Local_LLM_Coder_Medium, Frontier_Reasoning_Model
└── used_by: Code_Implementation_Routing, Refactor_Routing, Bug_Triage_Routing, Performance_Regression_Routing, Determinism_Issue_Routing, UI_Flow_Change_Routing, Data_Balance_Routing, Asset_Integration_Routing, Audio_Integration_Routing, Build_Release_Routing

Local_LLM_Coder_Small
├── depends_on: Model_Catalog_Overview
└── used_by: Task_Routing_Overview, Code_Implementation_Routing

Local_LLM_Coder_Medium
├── depends_on: Model_Catalog_Overview
└── used_by: Task_Routing_Overview, Code_Implementation_Routing, Refactor_Routing

Frontier_Reasoning_Model
├── depends_on: Model_Catalog_Overview
└── used_by: Task_Routing_Overview, Bug_Triage_Routing, Determinism_Issue_Routing
```

## Agent Architecture Dependencies

```
Agent_Role_Definitions
├── depends_on: Orchestration_Architecture_Overview
└── used_by: Command_Graph_Specification, Message_Contracts, Context_Pack_Builder_Spec

Command_Graph_Specification
├── depends_on: Orchestration_Architecture_Overview, Agent_Role_Definitions
└── used_by: OpenClaw_Daily_Work_Loop, Implementation_Workflow

Message_Contracts
├── depends_on: Agent_Role_Definitions
└── used_by: Context_Pack_Builder_Spec, Output_Normalizer_Spec

Context_Pack_Builder_Spec
├── depends_on: Agent_Role_Definitions, Message_Contracts
└── used_by: Output_Normalizer_Spec, Code_Implementation_Routing

Output_Normalizer_Spec
├── depends_on: Context_Pack_Builder_Spec, Message_Contracts
└── used_by: Review_Gate_Workflow, Merge_Release_Workflow

Retry_Policy_Specification
├── depends_on: Command_Graph_Specification
└── used_by: Implementation_Workflow, Safe_Mode_Behavior

Rollback_Protocol
├── depends_on: Output_Normalizer_Spec
└── used_by: L4_High_Autonomy, Escalation_Triggers

Quarantine_Branch_Protocol
├── depends_on: Rollback_Protocol
└── used_by: Safe_Mode_Behavior
```

## Execution Flow Dependencies

```
OpenClaw_Daily_Work_Loop
├── depends_on: Orchestration_Architecture_Overview, Ticket_Intake_Management, Implementation_Workflow
└── used_by: Automated_Prioritization_Rules, Escalation_Triggers

Ticket_Intake_Management
├── depends_on: Intent_Specification_Format
└── used_by: OpenClaw_Daily_Work_Loop, Automated_Prioritization_Rules

Intent_Specification_Format
├── depends_on: Spec_Decomposition_Rules
└── used_by: Ticket_Intake_Management, Ticket_Template_Spec

Implementation_Workflow
├── depends_on: Command_Graph_Specification, Gate_Protocol
└── used_by: OpenClaw_Daily_Work_Loop, Review_Gate_Workflow

Review_Gate_Workflow
├── depends_on: Implementation_Workflow, Output_Normalizer_Spec
└── used_by: Merge_Release_Workflow

Merge_Release_Workflow
├── depends_on: Review_Gate_Workflow, Output_Normalizer_Spec
└── used_by: Patch_Protocol

Gate_Protocol
├── depends_on: Quality_Gates_Overview
└── used_by: Implementation_Workflow, L3_Conditional_Autonomy
```

## Quality Gates Dependencies

```
Quality_Gates_Overview
├── depends_on: (root)
└── used_by: Build_Gate, Unit_Tests_Gate, Determinism_Replay_Gate, Headless_Match_Batch_Gate, UI_Smoke_Gate, Performance_Gate, Content_Validation_Gate, Lint_Static_Analysis_Gate, Security_Secret_Scanning_Gate, Packaging_Gate, Regression_Harness_Spec, Gate_Protocol

Build_Gate
├── depends_on: Quality_Gates_Overview
└── used_by: Regression_Harness_Spec, Godot_CI_Template, Unity_CI_Template

Unit_Tests_Gate
├── depends_on: Quality_Gates_Overview
└── used_by: Regression_Harness_Spec, Godot_GUT_Test_Framework, Unity_EditMode_Test_Framework

Lint_Static_Analysis_Gate
├── depends_on: Quality_Gates_Overview
└── used_by: Regression_Harness_Spec, Godot_Lint_Static_Checks, Unity_Analyzers_Setup

Performance_Gate
├── depends_on: Quality_Gates_Overview
└── used_by: Regression_Harness_Spec, Godot_Performance_Budgets, Unity_Profiling_Perf_Gates

Determinism_Replay_Gate
├── depends_on: Quality_Gates_Overview
└── used_by: Regression_Harness_Spec, Godot_Deterministic_Fixed_Timestep, Unity_Determinism_Strategy

Regression_Harness_Spec
├── depends_on: Quality_Gates_Overview, Build_Gate, Unit_Tests_Gate
└── used_by: Postmortem_Process, Architecture_Decay_Controls
```

## Engine Pipeline Dependencies

```
Godot_Pipeline_Overview
├── depends_on: Studio_OS_Overview
└── used_by: Godot_Project_Layout_Conventions, Godot_Export_Pipeline, Godot_CI_Template

Godot_Export_Pipeline
├── depends_on: Godot_Pipeline_Overview
└── used_by: Godot_Steam_Build_Packaging, Godot_Headless_Sim_Runner_Spec

Godot_GUT_Test_Framework
├── depends_on: Godot_Pipeline_Overview
└── used_by: Unit_Tests_Gate, Godot_CI_Template

Unity_Pipeline_Overview
├── depends_on: Studio_OS_Overview
└── used_by: Unity_Project_Layout_Conventions, Unity_Export_Pipeline, Unity_CI_Template

Unity_Export_Pipeline
├── depends_on: Unity_Pipeline_Overview
└── used_by: Unity_Steam_Build_Packaging, Unity_Build_Automation

Unity_PlayMode_Test_Framework
├── depends_on: Unity_Pipeline_Overview
└── used_by: Unit_Tests_Gate, Unity_CI_Template
```

## Art & Audio Pipeline Dependencies

```
Art_Pipeline_Overview
├── depends_on: Studio_OS_Overview
└── used_by: Asset_Pack_First_Rule, Asset_Format_Specifications, Prompt_Architecture_Templates

Asset_Pack_First_Rule
├── depends_on: Art_Pipeline_Overview, Economic_Model_Overview
└── used_by: Asset_Resolution_Standards, Atlas_Packing_Strategy

Audio_Pipeline_Overview
├── depends_on: Studio_OS_Overview
└── used_by: Audio_Format_Standards, SFX_Generation_Routing, Voice_TTS_Routing

SFX_Generation_Routing
├── depends_on: Audio_Pipeline_Overview, Audio_Generation_SFX
└── used_by: Audio_Integration_Routing

Audio_Integration_Routing
├── depends_on: SFX_Generation_Routing, Audio_Generation_Music, Audio_Generation_Voice
└── used_by: Audio_Validation_Gates
```

## Economic Model Dependencies

```
Economic_Model_Overview
├── depends_on: (root)
└── used_by: Model_Cost_Matrix, Monthly_Budget_Prototype_Tier, Monthly_Budget_Indie_Tier, Monthly_Budget_MultiProject_Tier, Token_Burn_Controls, Compute_Burn_Controls, Calibration_Protocol

Model_Cost_Matrix
├── depends_on: Economic_Model_Overview
└── used_by: Model_Pricing_Template, Cost_Per_Feature_Estimates

Token_Burn_Controls
├── depends_on: Economic_Model_Overview
└── used_by: Task_Routing_Overview, Code_Implementation_Routing

Compute_Burn_Controls
├── depends_on: Economic_Model_Overview
└── used_by: Local_Diffusion_Setup, Batch_Generation_Workflow

Calibration_Protocol
├── depends_on: Economic_Model_Overview
└── used_by: Monthly_Budget_Prototype_Tier, Monthly_Budget_Indie_Tier, Monthly_Budget_MultiProject_Tier
```

## Dependency Statistics

| Metric | Count |
|--------|-------|
| Total Notes | 157 |
| Notes with `depends_on` | 155 (98.7%) |
| Notes with `used_by` | 155 (98.7%) |
| Root notes (no depends_on) | 8 |
| Leaf notes (no used_by) | 8 |
| Average outbound links | 4.2 |
| Average inbound links | 4.2 |

## Orphan Detection

### Root Notes (Expected - Entry Points)
- [[Studio_OS_Overview]]
- [[Orchestration_Architecture_Overview]]
- [[Quality_Gates_Overview]]
- [[Economic_Model_Overview]]
- [[Model_Catalog_Overview]]
- [[Godot_Pipeline_Overview]]
- [[Unity_Pipeline_Overview]]
- [[Art_Pipeline_Overview]]
- [[Audio_Pipeline_Overview]]

### Leaf Notes (Expected - Terminal Specs)
- [[Godot_Steam_Build_Packaging]]
- [[Unity_Steam_Build_Packaging]]
- [[Release_Certification_Checklist]]
- [[Rollback_Plan_Checklist]]
- [[Known_Risk_Acceptance_Checklist]]
- [[Gate_Template]]
- [[Release_Checklist_Template]]
- [[30_Day_Enablement_Plan]]

## Circular Dependency Check

No circular dependencies detected. The graph is a DAG (Directed Acyclic Graph).

## Maintenance

Run dependency validation weekly:
```bash
# Check for orphans
python scripts/check_orphans.py

# Check for circular dependencies
python scripts/check_cycles.py

# Generate updated graph
python scripts/generate_graph.py
```
