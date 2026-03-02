---
title: Intent Specification Format
type: system
layer: execution
status: active
tags:
  - intent
  - specification
  - human
  - input
  - requirements
depends_on:
  - "[Orchestration_Architecture_Overview]"
used_by:
  - "[Spec_Decomposition_Rules]]"
  - "[[Ticket_Template_Spec]"
---

# Intent Specification Format

## Purpose

The Intent Specification Format defines how humans communicate development goals to OpenClaw. It provides a structured yet flexible way to express what needs to be built, fixed, or improved.

## Intent Structure

```yaml
Intent:
  version: "1.0"
  intent_id: string  # Auto-generated
  
  # Source
  submitted_by: string      # Human identifier
  submitted_at: ISO8601     # Auto-populated
  
  # Classification
  type: feature|bugfix|refactor|docs|optimization|spike
  
  # Priority
  priority: critical|high|medium|low
  
  # Description
  title: string             # Brief summary
  description: string       # Detailed explanation
  
  # Context
  context:
    background: string      # Why this is needed
    motivation: string      # Business/technical driver
    
  # Scope
  scope:
    in_scope: [string]      # What IS included
    out_of_scope: [string]  # What is NOT included
    
  # Requirements
  requirements:
    must_have: [string]     # Critical requirements
    should_have: [string]   # Important but not critical
    nice_to_have: [string]  # Desired if time permits
    
  # Constraints
  constraints:
    technical: [string]     # Technical limitations
    business: [string]      # Business constraints
    time: string            # Time constraints
    
  # Success Criteria
  success_criteria:
    functional: [string]    # Functional success metrics
    non_functional: [string] # Performance, security, etc.
    
  # References
  references:
    related_issues: [string]
    design_docs: [string]
    external_links: [string]
```

## Intent Types

### Feature Intent

```yaml
intent_id: "INTENT-2024-001"
type: feature
priority: high

title: "Add multiplayer lobby system"
description: |
  Implement a lobby system that allows players to create,
  join, and manage multiplayer game sessions.
  
  The lobby should support:
  - Creating public and private lobbies
  - Joining via lobby code or browse list
  - Player ready states
  - Host migration on disconnect

context:
  background: |
    Current game only supports single-player. Multiplayer
    is the top requested feature from player surveys.
  motivation: |
    Increase player engagement and retention through
    social gameplay features.

scope:
  in_scope:
    - "Lobby creation and management"
    - "Player join/leave flow"
    - "Ready state handling"
    - "Basic chat functionality"
  out_of_scope:
    - "Matchmaking algorithm"
    - "Ranked/competitive modes"
    - "Spectator mode"

requirements:
  must_have:
    - "Up to 8 players per lobby"
    - "Lobby persistence across disconnects (30s grace)"
    - "Host migration when host leaves"
  should_have:
    - "Lobby password protection"
    - "Player kick functionality"
  nice_to_have:
    - "Custom lobby settings"
    - "Lobby chat with emoji support"

constraints:
  technical:
    - "Must work with existing networking layer"
    - "Max 100 concurrent lobbies per server"
  business:
    - "Release in next milestone (4 weeks)"
  time: "3 weeks implementation"

success_criteria:
  functional:
    - "Players can create and join lobbies"
    - "Host migration works without data loss"
    - "Graceful handling of disconnects"
  non_functional:
    - "Lobby operations < 100ms latency"
    - "99.9% uptime for lobby service"
```

### Bugfix Intent

```yaml
intent_id: "INTENT-2024-002"
type: bugfix
priority: critical

title: "Fix memory leak in particle system"
description: |
  The particle system leaks memory during extended gameplay
  sessions, eventually causing the game to crash.
  
  Issue appears to be in particle texture cleanup.

context:
  background: |
    Reported by multiple players after 2+ hours of gameplay.
    Memory usage grows linearly with particle effects.
  motivation: |
    Critical stability issue affecting player experience.

scope:
  in_scope:
    - "Particle system memory management"
    - "Texture lifecycle"
  out_of_scope:
    - "Particle effect redesign"
    - "Performance optimization"

requirements:
  must_have:
    - "No memory growth during gameplay"
    - "All particle resources properly released"

constraints:
  time: "Fix within 48 hours"

success_criteria:
  functional:
    - "Memory usage stable over 4+ hour session"
    - "No crashes related to particles"
```

### Refactor Intent

```yaml
intent_id: "INTENT-2024-003"
type: refactor
priority: medium

title: "Extract game state serialization"
description: |
  Current save/load logic is scattered across multiple modules.
  Extract into a dedicated serialization system for better
  maintainability and testability.

context:
  background: |
    Save/load bugs are hard to debug due to scattered logic.
    Adding new saveable fields requires changes in multiple places.
  motivation: |
    Improve code organization and reduce save/load bug rate.

scope:
  in_scope:
    - "Create serialization module"
    - "Migrate existing save/load logic"
    - "Maintain backward compatibility"
  out_of_scope:
    - "Save file format changes"
    - "New save features"

requirements:
  must_have:
    - "All existing save files still load"
    - "New serialization system fully tested"
  should_have:
    - "Performance maintained or improved"

constraints:
  technical:
    - "Must maintain save file compatibility"
  time: "1 week"

success_criteria:
  functional:
    - "All existing tests pass"
    - "Save/load behavior unchanged"
  non_functional:
    - "Serialization module has 90%+ coverage"
```

## Intent Submission Methods

### 1. Structured YAML

Direct YAML submission:

```yaml
# intent.yaml
intent:
  type: feature
  priority: high
  title: "Add feature X"
  description: "..."
```

### 2. Natural Language

OpenClaw parses natural language:

```
"Add a player inventory system that can hold up to 50 items.
Items should stack when possible. Include UI for viewing and
using items. This is high priority for next release."
```

Parsed to:
```yaml
type: feature
priority: high
title: "Add player inventory system"
description: "..."
```

### 3. Template-Based

Pre-defined templates:

```yaml
# feature_template.yaml
intent:
  type: feature
  title: "{{feature_name}}"
  description: "{{description}}"
  requirements:
    must_have: "{{must_have}}"
  priority: "{{priority}}"
```

## Intent Validation

### Validation Rules

```python
def validate_intent(intent: Intent) -> ValidationResult:
    """Validate intent specification."""
    errors = []
    
    # Required fields
    required = ["type", "title", "description"]
    for field in required:
        if not getattr(intent, field):
            errors.append(f"Missing required field: {field}")
    
    # Type validation
    valid_types = ["feature", "bugfix", "refactor", "docs", "optimization", "spike"]
    if intent.type not in valid_types:
        errors.append(f"Invalid type: {intent.type}")
    
    # Priority validation
    valid_priorities = ["critical", "high", "medium", "low"]
    if intent.priority not in valid_priorities:
        errors.append(f"Invalid priority: {intent.priority}")
    
    # Scope validation
    if not intent.scope.in_scope:
        errors.append("No in-scope items defined")
    
    # Requirements validation
    if not intent.requirements.must_have:
        errors.append("No must-have requirements defined")
    
    return ValidationResult(valid=len(errors) == 0, errors=errors)
```

## Intent Processing

### Intent to Tickets

```python
async def process_intent(intent: Intent) -> [Ticket]:
    """Process intent into executable tickets."""
    
    # 1. Validate intent
    validation = validate_intent(intent)
    if not validation.valid:
        raise InvalidIntentError(validation.errors)
    
    # 2. Decompose into tickets
    tickets = await spec_decomposer.decompose(intent)
    
    # 3. Prioritize tickets
    prioritized = prioritize_tickets(tickets, intent.priority)
    
    # 4. Add to backlog
    await add_to_backlog(prioritized)
    
    return prioritized
```

## Intent Storage

### Intent Archive

```
intents/
  {intent_id}.yaml
  backlog.yaml
  archive/
    {year}/
      {month}/
        {intent_id}.yaml
```

### Intent Index

```yaml
IntentIndex:
  version: "1.0"
  intents:
    - intent_id: "INTENT-2024-001"
      type: feature
      status: in_progress
      tickets: ["TICKET-001", "TICKET-002"]
      submitted_at: "2024-01-15T10:00:00Z"
```

## Integration with Other Systems

### Spec Decomposition
Intents feed into [[Spec_Decomposition_Rules|spec decomposition]]:

```python
tickets = spec_decomposer.decompose(intent)
```

### Ticket Creation
Intents generate [[Ticket_Template_Spec|tickets]]:

```python
for ticket in tickets:
    ticket.source.intent_id = intent.intent_id
```

### Prioritization
Intent priority influences [[Automated_Prioritization_Rules|ticket prioritization]]:

```python
def calculate_priority(intent: Intent) -> Priority:
    base = priority_map[intent.priority]
    
    # Adjust based on constraints
    if is_time_critical(intent):
        base += 10
    
    return base
```
