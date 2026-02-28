---
title: Physics_Modularity_System
type: system
layer: architecture
status: active
tags:
  - physics
  - modularity
  - determinism
  - extensibility
depends_on:
  - "[Deterministic_60Hz_Simulation]"
used_by:
  - "[Projectile_System]]"
  - "[[Collision_Detection]]"
  - "[[Movement_System]"
---

# Physics Modularity System

## Purpose
Enable physics behaviors to be composed from discrete, testable modules. Supports deterministic simulation and future extensions.

## Core Rules

### Physics Modules

| Module | Responsibility | Configurable |
|--------|---------------|--------------|
| **Movement** | Position, velocity, acceleration | Speed, mass |
| **Collision** | Hit detection, response | Hitbox size |
| **Drag** | Friction, air resistance | Drag coefficient |
| **Forces** | Applied impulses | Force vector |

### Module Pattern
```gdscript
class_name PhysicsModule
extends RefCounted

## Base class for physics behaviors

func integrate(entity: PhysicsEntity, dt: float) -> void:
    ## Override in subclasses
    pass

func on_collision(entity: PhysicsEntity, other: PhysicsEntity) -> void:
    ## Override in subclasses
    pass
```

### Composing Behaviors
```gdscript
# Bot with multiple physics modules
var physics := PhysicsEntity.new()
physics.add_module(MovementModule.new(speed: 5.0))
physics.add_module(CollisionModule.new(radius: 20.0))
physics.add_module(DragModule.new(coefficient: 0.1))
```

## Failure Modes

### Order Dependency
**Symptom:** Different module order = different results
**Fix:** Define clear execution order (movement → collision → forces)

### Float Drift
**Symptom:** Position accumulates error over time
**Fix:** Use `step()` for position snapping, verify determinism

## Related
[[Deterministic_Physics_Integration]]
[[Spatial_Partitioning_System]]
[[Physics_Test_Suite]]
