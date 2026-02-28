---
title: System Map
type: system
layer: architecture
status: active
tags:
  - system-map
  - overview
  - navigation
  - hierarchy
  - index
depends_on:
  - "[Studio_OS_Overview]]"
  - "[[OpenClaw_Core_System]"
used_by:
  - "[Dependency_Graph]]"
  - "[[Quickstart_OpenClaw]]"
  - "[[How_to_Run_OpenClaw_With_This_Vault]"
---

# System Map

## Hierarchical Vault Structure

The AI-Native Game Studio OS vault is organized into 11 functional domains, each containing atomic notes with explicit dependencies.

```
Studio_Master_Plan/
│
├── 00_Master_Index/                    # Navigation & entry points
│   ├── System_Map.md                   # ← You are here
│   ├── Dependency_Graph.md
│   ├── Agent_Command_Flow.md
│   ├── Quickstart_OpenClaw.md
│   └── Glossary.md
│
├── 01_Studio_Strategy/                 # Vision, priorities, enablement
│   ├── Studio_OS_Overview.md
│   ├── OpenClaw_Core_System.md
│   ├── Studio_Priorities_Manifesto.md
│   ├── Autonomy_Ladder_L0_L5.md
│   ├── Decision_Making_Protocols.md
│   ├── Governance_and_Authority_Boundaries.md
│   ├── Intent_to_Release_Pipeline.md
│   └── 30_Day_Enablement_Plan.md
│
├── 02_Autonomy_Framework/              # L0-L5 autonomy levels
│   ├── L0_Manual_Operation.md
│   ├── L1_Assisted_Operation.md
│   ├── L2_Supervised_Autonomy.md
│   ├── L3_Conditional_Autonomy.md
│   ├── L4_High_Autonomy.md
│   ├── L5_Full_Autonomy.md
│   ├── Autonomy_Score_Rubric.md
│   └── Autonomy_Upgrade_Path.md
│
├── 03_Model_Catalog_and_Routing/       # AI model selection & routing
│   ├── Model_Catalog_Overview.md
│   ├── Task_Routing_Overview.md
│   ├── Local_LLM_Coder_Small.md
│   ├── Local_LLM_Coder_Medium.md
│   ├── Frontier_Reasoning_Model.md
│   ├── Repo_Aware_Code_Editor.md
│   ├── Vision_UI_Interpreter.md
│   ├── Vision_Art_Direction.md
│   ├── Image_Diffusion_Local.md
│   ├── Image_Diffusion_API.md
│   ├── Model_3D_Generation.md
│   ├── Audio_Generation_SFX.md
│   ├── Audio_Generation_Music.md
│   ├── Audio_Generation_Voice.md
│   └── [9 Task Routing Rules]
│
├── 04_Agent_Architecture/              # Agent orchestration
│   ├── Orchestration_Architecture_Overview.md
│   ├── Agent_Role_Definitions.md
│   ├── Command_Graph_Specification.md
│   ├── Message_Contracts.md
│   ├── Context_Pack_Builder_Spec.md
│   ├── Output_Normalizer_Spec.md
│   ├── Retry_Policy_Specification.md
│   ├── Rollback_Protocol.md
│   └── Quarantine_Branch_Protocol.md
│
├── 05_Execution_Flow_and_Tickets/      # Ticket lifecycle
│   ├── OpenClaw_Daily_Work_Loop.md
│   ├── Ticket_Intake_Management.md
│   ├── Intent_Specification_Format.md
│   ├── Ticket_Template_Spec.md
│   ├── Spec_Decomposition_Rules.md
│   ├── Implementation_Workflow.md
│   ├── Review_Gate_Workflow.md
│   ├── Merge_Release_Workflow.md
│   ├── Gate_Protocol.md
│   ├── Patch_Protocol.md
│   ├── Automated_Prioritization_Rules.md
│   ├── Escalation_Triggers.md
│   ├── Safe_Mode_Behavior.md
│   ├── Weekly_Consolidation_Review.md
│   └── [4 Prompt Templates]
│
├── 06_Quality_Gates_and_Regression/    # Quality enforcement
│   ├── Quality_Gates_Overview.md
│   ├── Build_Gate.md
│   ├── Lint_Static_Analysis_Gate.md
│   ├── Unit_Tests_Gate.md
│   ├── Determinism_Replay_Gate.md
│   ├── Headless_Match_Batch_Gate.md
│   ├── UI_Smoke_Gate.md
│   ├── Performance_Gate.md
│   ├── Content_Validation_Gate.md
│   ├── Security_Secret_Scanning_Gate.md
│   ├── Packaging_Gate.md
│   ├── Regression_Harness_Spec.md
│   ├── Risk_Taxonomy.md
│   ├── Postmortem_Process.md
│   ├── Architecture_Decay_Controls.md
│   ├── Versioning_Changelog_Rules.md
│   ├── Release_Certification_Checklist.md
│   ├── Rollback_Plan_Checklist.md
│   └── Known_Risk_Acceptance_Checklist.md
│
├── 07_Engine_Pipelines/                # Engine-specific pipelines
│   ├── Godot/
│   │   ├── Godot_Pipeline_Overview.md
│   │   ├── Godot_Project_Layout_Conventions.md
│   │   ├── Godot_GDScript_Style_Guide.md
│   │   ├── Godot_Export_Pipeline.md
│   │   ├── Godot_CI_Template.md
│   │   ├── Godot_GUT_Test_Framework.md
│   │   ├── Godot_Deterministic_Fixed_Timestep.md
│   │   ├── Godot_Profiling_Practices.md
│   │   ├── Godot_Performance_Budgets.md
│   │   ├── Godot_Lint_Static_Checks.md
│   │   ├── Godot_Asset_Import_Pipeline.md
│   │   ├── Godot_Autoload_Conventions.md
│   │   ├── Godot_Headless_Sim_Runner_Spec.md
│   │   ├── Godot_UI_Smoke_Runner_Spec.md
│   │   └── Godot_Steam_Build_Packaging.md
│   └── Unity/
│       ├── Unity_Pipeline_Overview.md
│       ├── Unity_Project_Layout_Conventions.md
│       ├── Unity_CSharp_Style_Guide.md
│       ├── Unity_Assembly_Definition_Strategy.md
│       ├── Unity_Addressables_Strategy.md
│       ├── Unity_Export_Pipeline.md
│       ├── Unity_Build_Automation.md
│       ├── Unity_CI_Template.md
│       ├── Unity_EditMode_Test_Framework.md
│       ├── Unity_PlayMode_Test_Framework.md
│       ├── Unity_Determinism_Strategy.md
│       ├── Unity_Profiling_Perf_Gates.md
│       ├── Unity_Analyzers_Setup.md
│       ├── Unity_Asset_Import_Pipeline.md
│       ├── Unity_Rollback_Strategy.md
│       └── Unity_Steam_Build_Packaging.md
│
├── 08_Art_and_Audio_Pipelines/         # Creative asset pipelines
│   ├── Art_Pipeline_Overview.md
│   ├── Audio_Pipeline_Overview.md
│   ├── Asset_Pack_First_Rule.md
│   ├── Asset_Resolution_Standards.md
│   ├── Asset_Format_Specifications.md
│   ├── Asset_Naming_Conventions.md
│   ├── Atlas_Packing_Strategy.md
│   ├── Import_Settings_Validation.md
│   ├── Prompt_Architecture_Templates.md
│   ├── Art_Direction_Intake_Format.md
│   ├── Style_Lock_Approval_Process.md
│   ├── Batch_Generation_Workflow.md
│   ├── Human_Checkpoint_Minimization.md
│   ├── Local_Diffusion_Setup.md
│   ├── Paid_Diffusion_Routing.md
│   ├── Art_Validation_Gates.md
│   ├── Audio_Format_Standards.md
│   ├── SFX_List_Generation.md
│   ├── SFX_Generation_Routing.md
│   ├── Music_Direction_Spec.md
│   ├── UI_Audio_Taxonomy.md
│   ├── Voice_TTS_Routing.md
│   ├── Audio_Validation_Gates.md
│   └── Art_Audio_Integration_Workflow.md
│
├── 09_Economic_Model_and_Budgets/      # Cost control
│   ├── Economic_Model_Overview.md
│   ├── Model_Cost_Matrix.md
│   ├── Model_Pricing_Template.md
│   ├── Cost_Per_Feature_Estimates.md
│   ├── ROI_Optimization_Rules.md
│   ├── Token_Burn_Controls.md
│   ├── Compute_Burn_Controls.md
│   ├── Calibration_Protocol.md
│   ├── Cost_Monitoring_Dashboard_Spec.md
│   ├── Monthly_Budget_Prototype_Tier.md
│   ├── Monthly_Budget_Indie_Tier.md
│   └── Monthly_Budget_MultiProject_Tier.md
│
├── 10_Templates_and_Checklists/        # Reusable templates
│   ├── Gate_Template.md
│   └── Release_Checklist_Template.md
│
└── 11_Risk_Postmortems_and_Drift_Control/  # Maintenance
    ├── Top_Risks_and_Mitigations.md
    └── Vault_Maintenance_Guide.md
```

## Cross-Cutting Concerns

### Cost Control (Everywhere)
- [[Economic_Model_Overview]] - Philosophy
- [[Token_Burn_Controls]] - API cost limits
- [[Compute_Burn_Controls]] - Local resource limits
- [[Model_Cost_Matrix]] - Per-model pricing

### Quality Enforcement (Everywhere)
- [[Quality_Gates_Overview]] - Gate philosophy
- [[Gate_Protocol]] - Gate execution
- [[Regression_Harness_Spec]] - Continuous validation

### Autonomy Levels (Everywhere)
- [[Autonomy_Ladder_L0_L5]] - Level definitions
- [[Decision_Making_Protocols]] - When to escalate
- [[Escalation_Triggers]] - Automatic escalation

## Entry Points by Role

| Role | Start Here |
|------|------------|
| **New User** | [[Quickstart_OpenClaw]] |
| **Tech Lead** | [[Studio_OS_Overview]] → [[Quality_Gates_Overview]] |
| **Producer** | [[Studio_Priorities_Manifesto]] → [[Economic_Model_Overview]] |
| **Developer** | [[OpenClaw_Daily_Work_Loop]] → [[Ticket_Template_Spec]] |
| **AI Engineer** | [[Orchestration_Architecture_Overview]] → [[Task_Routing_Overview]] |
| **QA** | [[Quality_Gates_Overview]] → [[Regression_Harness_Spec]] |

## Navigation Patterns

### Downward Navigation
Follow `depends_on` links to understand prerequisites.

### Upward Navigation
Follow `used_by` links to see impact and consumers.

### Horizontal Navigation
Follow wiki-links in content to related concepts.

### Tag Navigation
Use tags to find notes by type:
- `#system` - Core system documentation
- `#gate` - Quality gates
- `#agent` - Agent definitions
- `#template` - Reusable templates
- `#pitfall` - Known issues to avoid

## Vault Statistics

- **Total Notes**: 157
- **System Notes**: 35
- **Gate Notes**: 20
- **Agent Notes**: 15
- **Template Notes**: 5
- **Routing Rules**: 24
- **Engine Pipelines**: 33
- **Economic Models**: 12

## Maintenance

This map is auto-generated. Last updated: See git history.
For updates, modify the source of truth in individual notes.
