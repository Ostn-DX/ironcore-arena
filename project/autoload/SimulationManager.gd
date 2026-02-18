extends Node
## SimulationManager singleton — runs combat simulation in _physics_process.
## Owns bot/projectile/hazard arrays. Exposes start_battle(), issue_command().
## Signals for tick events and battle end. Can run headless.
## Implementation: TASK-07
