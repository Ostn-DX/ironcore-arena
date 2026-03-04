---
title: Dependency_Graph
type: index
layer: architecture
status: active
tags:
  - index
  - dependencies
  - graph
  - relationships
depends_on: []
used_by: []
---

# Dependency Graph

## Core Dependencies

### Determinism Layer (Foundation)
```
[[Deterministic_60Hz_Simulation]]
├─ used by → [[Tactical_AI_System]]
├─ used by → [[Replay_System]]
├─ used by → [[AI_Decision_Making]]
└─ depends on → [[Deterministic_RNG_Implementation]]
```

### AI System Dependencies
```
[[Tactical_AI_System]]
├─ depends on → [[Pathfinding_System]]
├─ depends on → [[Squad_Coordination]]
├─ depends on → [[Deterministic_60Hz_Simulation]]
└─ used by → [[AI_Tank_Profile]]
    └─ used by → [[AI_Assault_Profile]]
    └─ used by → [[AI_Sniper_Profile]]
    └─ used by → [[AI_Scout_Profile]]
```

### Quality Gate Dependencies
```
[[Dev_Gate_Validation_System]]
├─ depends on → [[Headless_Match_Runner]]
├─ depends on → [[UI_Smoke_Test]]
└─ depends on → [[Determinism_Test]]

[[Simulation_Test_Suite]]
├─ depends on → [[Deterministic_60Hz_Simulation]]
├─ depends on → [[GUT_Testing_Framework]]
└─ used by → [[CI_Pipeline]]
```

### Economy Dependencies
```
[[Economy_Progression_System]]
├─ depends on → [[Arena_Difficulty_Curve]]
├─ depends on → [[Component_Unlock_System]]
└─ used by → [[Player_Retention_Loop]]
    └─ used by → [[Monetization_Design]]
```

### Agent Swarm Dependencies
```
[[Agent_Swarm_Architecture]]
├─ depends on → [[Ticket_Based_Workflow]]
├─ depends on → [[Context_Pack_System]]
└─ depends on → [[Output_Normalization]]

[[Architect_Agent]]
└─ outputs to → [[Implementation_Agent]]
    └─ outputs to → [[Validation_Agent]]
        └─ outputs to → [[Balancer_Agent]]
```

## Cross-Cutting Concerns

### Pitfall Prevention
All systems depend on:
- [[Determinism_Validation_Agent]] (for simulation systems)
- [[Performance_Monitor_Agent]] (for real-time systems)
- [[Pitfall_Detection_Agent]] (for all code)

### Code Quality
All systems must follow:
- [[Architectural_Invariants]]
- [[Code_Conventions_Standard]]

## Critical Paths

### Battle Simulation
```
[[Deterministic_60Hz_Simulation]]
→ [[Component_Architecture_Pattern]]
→ [[Tactical_AI_System]]
→ [[Pathfinding_System]]
```

### Quality Assurance
```
[[Dev_Gate_Validation_System]]
→ [[Headless_Match_Runner]]
→ [[Simulation_Test_Suite]]
→ [[Release_Certification_Criteria]]
```

### Content Production
```
[[Content_Scaling_Strategy]]
→ [[Asset_Pipeline_System]]
→ [[Procedural_Generation_Guidelines]]
→ [[Arena_Template_System]]
```

## Orphan Prevention

Every note must have at least one inbound link. Verified:
- ✅ All design notes link to [[System_Map]]
- ✅ All pitfall notes link to detection agents
- ✅ All agent notes link to [[Agent_Swarm_Architecture]]
- ✅ All enforcement notes link to validation systems

## Dependency Rules

### Allowed
- Lower layer → Upper layer (foundation → feature)
- Design → Implementation (intent → execution)
- System → Test (code → validation)

### Forbidden
- Circular dependencies
- Implementation → Design (no feedback loops in vault)
- Test → Test (no test interdependencies)

## Visualization

For visual dependency graph, see:
- Mermaid diagram in [[System_Architecture_Diagram]]
- Graphviz DOT export in `tools/generate_dependency_graph.py`
