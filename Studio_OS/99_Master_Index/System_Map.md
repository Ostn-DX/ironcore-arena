---
title: System_Map
type: index
layer: architecture
status: active
tags:
  - index
  - overview
  - systems
  - map
depends_on: []
used_by: []
---

# System Map

## Overview

Ironcore Arena is a deterministic robot combat simulation built on Godot 4. This map shows all major systems and their relationships.

## Core Architecture

### Engine Systems
```
[[Deterministic_60Hz_Simulation]]
├── [[Component_Architecture_Pattern]]
├── [[EventBus_Decoupled_Communication]]
└── [[Physics_Tick_Architecture]]
```

### AI Systems
```
[[Tactical_AI_System]]
├── [[Pathfinding_System]]
├── [[Squad_Coordination]]
└── [[AI_Role_Profiles]]
    ├── [[AI_Tank_Profile]]
    ├── [[AI_Assault_Profile]]
    ├── [[AI_Sniper_Profile]]
    └── [[AI_Scout_Profile]]
```

### Quality Assurance
```
[[Dev_Gate_Validation_System]]
├── [[Headless_Match_Runner]]
├── [[UI_Smoke_Test]]
└── [[Determinism_Test]]

[[Simulation_Test_Suite]]
├── [[Determinism_Tests]]
├── [[Bot_Behavior_Tests]]
├── [[Projectile_Tests]]
└── [[Edge_Case_Tests]]
```

## Design Systems

### Progression
```
[[Economy_Progression_System]]
├── [[Arena_Difficulty_Design]]
├── [[Component_Unlock_System]]
└── [[Weight_Cap_Design]]
```

### Visual
```
[[Visual_Design_System]]
├── [[Color_Palette]]
├── [[Typography_System]]
└── [[Animation_Standards]]
```

## Agent Swarm

```
[[Agent_Swarm_Architecture]]
├── [[Architect_Agent]]
├── [[Implementation_Agent]]
├── [[Validation_Agent]]
└── [[Balancer_Agent]]

[[Ticket_Based_Workflow]]
├── [[Context_Pack_System]]
├── [[Output_Normalization]]
└── [[Integration_Guide]]
```

## Pitfall Prevention

### Common Traps
- [[Determinism_Loss_Pitfall]]
- [[Performance_Degradation_Pitfall]]
- [[Memory_Leak_Pitfall]]
- [[Save_Data_Corruption_Pitfall]]

### Detection Agents
- [[Determinism_Validation_Agent]]
- [[Performance_Monitor_Agent]]
- [[Pitfall_Detection_Agent]]

## Release Process

```
[[Release_Certification_Criteria]]
├── [[Alpha_Certification]]
├── [[Beta_Certification]]
└── [[Release_Certification]]

[[CI_CD_Pipeline]]
├── [[Automated_Testing]]
├── [[Build_Generation]]
└── [[Deployment]]
```

## Quick Navigation

### By Role
- **Designer**: [[00_Design_Intent]]
- **Programmer**: [[01_Engine_Systems]], [[04_Determinism]]
- **AI Developer**: [[06_Combat_AI]]
- **QA**: [[09_Quality_Gates]], [[10_Regression_Harness]]
- **Producer**: [[11_Release_Certification]]

### By Layer
- **Design**: [[00_Design_Intent]], [[08_Economy_Design]]
- **Architecture**: [[01_Engine_Systems]], [[12_Architectural_Decisions]]
- **Enforcement**: [[09_Quality_Gates]], [[10_Regression_Harness]]
- **Execution**: [[02_AI_Swarm_Architecture]], [[06_Combat_AI]]

## Statistics

- **Total Notes**: 40+
- **Systems**: 15
- **Pitfalls**: 5
- **Agents**: 5
- **Quality Gates**: 3
- **Design Mechanics**: 4

## Recent Additions

See [[Dependency_Graph]] for system relationships.
See [[Agent_Command_Flow]] for workflow documentation.
