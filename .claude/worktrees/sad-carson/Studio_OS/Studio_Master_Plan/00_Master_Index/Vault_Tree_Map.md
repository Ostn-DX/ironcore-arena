---
title: Vault Tree Map
type: system
layer: architecture
status: active
tags:
  - tree
  - map
  - index
  - files
  - complete-listing
depends_on:
  - "[System_Map]"
used_by:
  - "[Vault_Maintenance_Guide]"
---

# Vault Tree Map

## Complete File Listing

This document contains a complete listing of all files in the Studio OS Obsidian Vault.

**Total Files**: 166 notes
**Last Updated**: Auto-generated

---

## 00_Master_Index/ (7 files)

Navigation and entry point notes:

| File | Type | Purpose |
|------|------|---------|
| [[System_Map]] | system | Hierarchical vault structure |
| [[Dependency_Graph]] | system | Note-to-note dependencies |
| [[Agent_Command_Flow]] | system | Intent → Release flow |
| [[Quickstart_OpenClaw]] | template | 5-minute getting started |
| [[Glossary]] | system | Unified terminology |
| [[Studio_OS_in_10_Rules]] | rule | Enforceable rules |
| [[How_to_Run_OpenClaw_With_This_Vault]] | template | Daily operations guide |
| [[Vault_Tree_Map]] | system | This file - complete listing |

---

## 01_Studio_Strategy/ (8 files)

Vision, priorities, and strategic direction:

| File | Type | Purpose |
|------|------|---------|
| [[Studio_OS_Overview]] | system | Core system philosophy |
| [[OpenClaw_Core_System]] | system | Execution engine spec |
| [[Studio_Priorities_Manifesto]] | system | Cost-first priorities |
| [[Autonomy_Ladder_L0_L5]] | system | Autonomy level definitions |
| [[Decision_Making_Protocols]] | system | Escalation rules |
| [[Governance_and_Authority_Boundaries]] | system | Decision ownership |
| [[Intent_to_Release_Pipeline]] | system | Full workflow overview |
| [[30_Day_Enablement_Plan]] | template | Week-by-week onboarding |

---

## 02_Autonomy_Framework/ (8 files)

L0-L5 autonomy levels and scoring:

| File | Type | Purpose |
|------|------|---------|
| [[L0_Manual_Operation]] | system | Full human control |
| [[L1_Assisted_Operation]] | system | AI suggestions |
| [[L2_Supervised_Autonomy]] | system | AI executes, human reviews |
| [[L3_Conditional_Autonomy]] | system | Auto-merge on gates |
| [[L4_High_Autonomy]] | system | Human review for novel only |
| [[L5_Full_Autonomy]] | system | Full self-direction |
| [[Autonomy_Score_Rubric]] | system | Scoring methodology |
| [[Autonomy_Upgrade_Path]] | system | Level progression rules |

---

## 03_Model_Catalog_and_Routing/ (24 files)

AI model selection and task routing:

### Model Catalog (12 files)

| File | Type | Purpose |
|------|------|---------|
| [[Model_Catalog_Overview]] | system | Catalog philosophy |
| [[Local_LLM_Coder_Small]] | system | 7B local model spec |
| [[Local_LLM_Coder_Medium]] | system | 13B local model spec |
| [[Frontier_Reasoning_Model]] | system | GPT-4/Claude spec |
| [[Repo_Aware_Code_Editor]] | system | Code-aware model |
| [[Vision_UI_Interpreter]] | system | UI analysis model |
| [[Vision_Art_Direction]] | system | Art direction model |
| [[Image_Diffusion_Local]] | system | Local image gen |
| [[Image_Diffusion_API]] | system | Paid image gen |
| [[Model_3D_Generation]] | system | 3D asset generation |
| [[Audio_Generation_SFX]] | system | SFX generation |
| [[Audio_Generation_Music]] | system | Music generation |
| [[Audio_Generation_Voice]] | system | Voice/TTS generation |

### Task Routing (11 files)

| File | Type | Purpose |
|------|------|---------|
| [[Task_Routing_Overview]] | system | Routing philosophy |
| [[Code_Implementation_Routing]] | rule | Code task routing |
| [[Refactor_Routing]] | rule | Refactoring routing |
| [[Bug_Triage_Routing]] | rule | Bug fix routing |
| [[Performance_Regression_Routing]] | rule | Performance issue routing |
| [[Determinism_Issue_Routing]] | rule | Non-determinism routing |
| [[UI_Flow_Change_Routing]] | rule | UI change routing |
| [[Data_Balance_Routing]] | rule | Data change routing |
| [[Asset_Integration_Routing]] | rule | Asset routing |
| [[Audio_Integration_Routing]] | rule | Audio routing |
| [[Build_Release_Routing]] | rule | Build/release routing |

---

## 04_Agent_Architecture/ (9 files)

Agent orchestration and coordination:

| File | Type | Purpose |
|------|------|---------|
| [[Orchestration_Architecture_Overview]] | system | Coordination philosophy |
| [[Agent_Role_Definitions]] | system | Agent responsibilities |
| [[Command_Graph_Specification]] | system | Execution sequencing |
| [[Message_Contracts]] | system | Communication format |
| [[Context_Pack_Builder_Spec]] | system | Context assembly |
| [[Output_Normalizer_Spec]] | system | Output standardization |
| [[Retry_Policy_Specification]] | system | Failure retry rules |
| [[Rollback_Protocol]] | system | State recovery |
| [[Quarantine_Branch_Protocol]] | system | Isolation for unstable changes |

---

## 05_Execution_Flow_and_Tickets/ (18 files)

Ticket lifecycle and execution:

### Core Flow (10 files)

| File | Type | Purpose |
|------|------|---------|
| [[OpenClaw_Daily_Work_Loop]] | system | Autonomous operation loop |
| [[Ticket_Intake_Management]] | system | Backlog management |
| [[Intent_Specification_Format]] | system | Intent documentation |
| [[Ticket_Template_Spec]] | template | Ticket structure |
| [[Spec_Decomposition_Rules]] | system | Breaking down specs |
| [[Implementation_Workflow]] | system | Code generation flow |
| [[Review_Gate_Workflow]] | system | Review process |
| [[Merge_Release_Workflow]] | system | Release process |
| [[Gate_Protocol]] | system | Gate execution |
| [[Patch_Protocol]] | system | Hotfix process |

### Management (4 files)

| File | Type | Purpose |
|------|------|---------|
| [[Automated_Prioritization_Rules]] | rule | Ticket prioritization |
| [[Escalation_Triggers]] | rule | Auto-escalation conditions |
| [[Safe_Mode_Behavior]] | system | Emergency operation |
| [[Weekly_Consolidation_Review]] | template | Weekly process |

### Prompt Templates (4 files)

| File | Type | Purpose |
|------|------|---------|
| [[Prompt_Ticket_Executor]] | template | Ticket execution prompt |
| [[Prompt_Refactor_Planner]] | template | Refactoring prompt |
| [[Prompt_PR_Summary_Writer]] | template | PR summary prompt |
| [[Prompt_Gate_Failure_Fixer]] | template | Gate failure prompt |

---

## 06_Quality_Gates_and_Regression/ (20 files)

Quality enforcement layer:

### Gates Overview (1 file)

| File | Type | Purpose |
|------|------|---------|
| [[Quality_Gates_Overview]] | gate | Gate philosophy |

### Individual Gates (10 files)

| File | Type | Purpose |
|------|------|---------|
| [[Build_Gate]] | gate | Compilation check |
| [[Lint_Static_Analysis_Gate]] | gate | Code quality |
| [[Unit_Tests_Gate]] | gate | Test execution |
| [[Determinism_Replay_Gate]] | gate | Replay consistency |
| [[Headless_Match_Batch_Gate]] | gate | Batch simulation |
| [[UI_Smoke_Gate]] | gate | Critical path UI |
| [[Performance_Gate]] | gate | Performance budgets |
| [[Content_Validation_Gate]] | gate | Asset integrity |
| [[Security_Secret_Scanning_Gate]] | gate | Secret detection |
| [[Packaging_Gate]] | gate | Build packaging |

### Regression & Process (9 files)

| File | Type | Purpose |
|------|------|---------|
| [[Regression_Harness_Spec]] | system | Continuous testing |
| [[Risk_Taxonomy]] | system | Risk categorization |
| [[Postmortem_Process]] | system | Failure analysis |
| [[Architecture_Decay_Controls]] | system | Code health |
| [[Versioning_Changelog_Rules]] | rule | Version management |
| [[Release_Certification_Checklist]] | template | Release validation |
| [[Rollback_Plan_Checklist]] | template | Rollback preparation |
| [[Known_Risk_Acceptance_Checklist]] | template | Risk acceptance |
| [[Perf_Budget_Enforcement]] | system | Performance limits |

---

## 07_Engine_Pipelines/Godot/ (16 files)

Godot 4.x specific pipelines:

| File | Type | Purpose |
|------|------|---------|
| [[Godot_Pipeline_Overview]] | system | Godot philosophy |
| [[Godot_Project_Layout_Conventions]] | system | Folder structure |
| [[Godot_GDScript_Style_Guide]] | system | Coding standards |
| [[Godot_Export_Pipeline]] | system | Build automation |
| [[Godot_CI_Template]] | template | CI configuration |
| [[Godot_GUT_Test_Framework]] | system | Testing framework |
| [[Godot_Deterministic_Fixed_Timestep]] | system | Determinism |
| [[Godot_Profiling_Practices]] | system | Performance profiling |
| [[Godot_Performance_Budgets]] | system | Performance limits |
| [[Godot_Lint_Static_Checks]] | system | Static analysis |
| [[Godot_Asset_Import_Pipeline]] | system | Asset processing |
| [[Godot_Autoload_Conventions]] | system | Singleton patterns |
| [[Godot_Headless_Sim_Runner_Spec]] | system | Headless testing |
| [[Godot_UI_Smoke_Runner_Spec]] | system | UI automation |
| [[Godot_Steam_Build_Packaging]] | system | Steam deployment |
| [[Godot_vs_Unity_Decision_Guide]] | decision | Engine selection |

---

## 07_Engine_Pipelines/Unity/ (17 files)

Unity specific pipelines:

| File | Type | Purpose |
|------|------|---------|
| [[Unity_Pipeline_Overview]] | system | Unity philosophy |
| [[Unity_Project_Layout_Conventions]] | system | Folder structure |
| [[Unity_CSharp_Style_Guide]] | system | Coding standards |
| [[Unity_Assembly_Definition_Strategy]] | system | Assembly organization |
| [[Unity_Addressables_Strategy]] | system | Asset management |
| [[Unity_Export_Pipeline]] | system | Build automation |
| [[Unity_Build_Automation]] | system | Build scripts |
| [[Unity_CI_Template]] | template | CI configuration |
| [[Unity_EditMode_Test_Framework]] | system | Editor testing |
| [[Unity_PlayMode_Test_Framework]] | system | Runtime testing |
| [[Unity_Determinism_Strategy]] | system | Determinism |
| [[Unity_Profiling_Perf_Gates]] | system | Performance profiling |
| [[Unity_Analyzers_Setup]] | system | Static analysis |
| [[Unity_Asset_Import_Pipeline]] | system | Asset processing |
| [[Unity_Rollback_Strategy]] | system | State recovery |
| [[Unity_Steam_Build_Packaging]] | system | Steam deployment |
| [[Unity_vs_Godot_Decision_Guide]] | decision | Engine selection |

---

## 08_Art_and_Audio_Pipelines/ (24 files)

Creative asset pipelines:

### Art Pipeline (14 files)

| File | Type | Purpose |
|------|------|---------|
| [[Art_Pipeline_Overview]] | system | Art philosophy |
| [[Asset_Pack_First_Rule]] | rule | Asset pack priority |
| [[Asset_Resolution_Standards]] | system | Resolution specs |
| [[Asset_Format_Specifications]] | system | File formats |
| [[Asset_Naming_Conventions]] | system | Naming standards |
| [[Atlas_Packing_Strategy]] | system | Texture atlases |
| [[Import_Settings_Validation]] | system | Import checks |
| [[Prompt_Architecture_Templates]] | template | Prompt patterns |
| [[Art_Direction_Intake_Format]] | template | Art request format |
| [[Style_Lock_Approval_Process]] | system | Style approval |
| [[Batch_Generation_Workflow]] | system | Batch processing |
| [[Human_Checkpoint_Minimization]] | system | Reduce human review |
| [[Local_Diffusion_Setup]] | system | Local image gen setup |
| [[Paid_Diffusion_Routing]] | rule | Paid API routing |
| [[Art_Validation_Gates]] | gate | Art quality checks |

### Audio Pipeline (10 files)

| File | Type | Purpose |
|------|------|---------|
| [[Audio_Pipeline_Overview]] | system | Audio philosophy |
| [[Audio_Format_Standards]] | system | Audio formats |
| [[SFX_List_Generation]] | system | SFX inventory |
| [[SFX_Generation_Routing]] | rule | SFX routing |
| [[Music_Direction_Spec]] | system | Music requirements |
| [[UI_Audio_Taxonomy]] | system | UI sound categories |
| [[Voice_TTS_Routing]] | rule | Voice generation routing |
| [[Audio_Validation_Gates]] | gate | Audio quality checks |
| [[Art_Audio_Integration_Workflow]] | system | Integration process |

---

## 09_Economic_Model_and_Budgets/ (12 files)

Cost control and budgeting:

| File | Type | Purpose |
|------|------|---------|
| [[Economic_Model_Overview]] | system | Cost philosophy |
| [[Model_Cost_Matrix]] | system | Per-model pricing |
| [[Model_Pricing_Template]] | template | Pricing calculator |
| [[Cost_Per_Feature_Estimates]] | system | Feature costs |
| [[ROI_Optimization_Rules]] | rule | ROI guidelines |
| [[Token_Burn_Controls]] | system | API cost limits |
| [[Compute_Burn_Controls]] | system | Compute limits |
| [[Calibration_Protocol]] | system | Cost validation |
| [[Cost_Monitoring_Dashboard_Spec]] | system | Dashboard design |
| [[Monthly_Budget_Prototype_Tier]] | system | Prototype budget |
| [[Monthly_Budget_Indie_Tier]] | system | Indie budget |
| [[Monthly_Budget_MultiProject_Tier]] | system | Scale budget |

---

## 10_Templates_and_Checklists/ (2 files)

Reusable templates:

| File | Type | Purpose |
|------|------|---------|
| [[Gate_Template]] | template | New gate template |
| [[Release_Checklist_Template]] | template | Release checklist |

---

## 11_Risk_Postmortems_and_Drift_Control/ (2 files)

Maintenance and risk management:

| File | Type | Purpose |
|------|------|---------|
| [[Top_Risks_and_Mitigations]] | pitfall | Risk register |
| [[Vault_Maintenance_Guide]] | system | Vault upkeep |

---

## Statistics Summary

| Category | Count |
|----------|-------|
| **Total Notes** | 166 |
| **System Notes** | 85 |
| **Gate Notes** | 12 |
| **Agent Notes** | 9 |
| **Template Notes** | 12 |
| **Rule Notes** | 15 |
| **Decision Notes** | 2 |
| **Pitfall Notes** | 1 |
| **Routing Rules** | 24 |
| **Engine Pipelines** | 33 |
| **Economic Models** | 12 |

---

## File Naming Convention

All files follow the pattern:
```
[Folder]/[Descriptive_Name].md
```

- Use PascalCase for file names
- Use underscores for spaces
- Include version numbers for specs: `Spec_Name_v2.md`
- Use descriptive names that indicate content

---

*This tree map is auto-generated. For updates, see [[Vault_Maintenance_Guide]].*
