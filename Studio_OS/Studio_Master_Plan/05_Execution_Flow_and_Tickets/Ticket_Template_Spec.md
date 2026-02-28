---
title: Ticket Template Specification
type: template
layer: execution
status: active
tags:
  - ticket
  - template
  - specification
  - task
  - workflow
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Intent_Specification_Format]"
used_by:
  - "[Spec_Decomposition_Rules]]"
  - "[[OpenClaw_Daily_Work_Loop]"
---

# Ticket Template Specification

## Purpose

The Ticket Template defines the standardized format for all work items in the OpenClaw system. It ensures consistent specification, tracking, and execution of development tasks.

## Ticket Structure

```yaml
Ticket:
  # Identification
  id: string           # Unique ticket ID (e.g., "TICKET-2024-001")
  version: "1.0"       # Ticket format version
  
  # Classification
  type: feature|bugfix|refactor|docs|test|chore
  priority: critical|high|medium|low
  complexity: simple|medium|complex|very_complex
  
  # Source
  source:
    intent_id: string           # Parent intent
    created_by: human|agent     # Creator type
    created_at: ISO8601
    
  # Description
  title: string        # Brief summary
  description: string  # Detailed description
  
  # Scope
  scope:
    target_files: [string]      # Primary files to modify
    affected_modules: [string]  # Modules impacted
    dependencies: [string]      # Tickets this depends on
    
  # Requirements
  requirements:
    functional: [string]        # Functional requirements
    non_functional: [string]    # Performance, security, etc.
    acceptance_criteria: [string]
    
  # Constraints
  constraints:
    must_preserve: [string]     # Behaviors to preserve
    must_not_break: [string]    # Things that must keep working
    coding_standards: [string]  # Standards to follow
    
  # Test Requirements
  testing:
    unit_tests_required: boolean
    integration_tests_required: boolean
    coverage_target: float      # 0.0 - 1.0
    test_scenarios: [string]
    
  # Implementation Notes
  implementation:
    approach: string            # Suggested approach
    estimated_effort: string    # Time estimate
    risks: [string]             # Known risks
    
  # Metadata
  metadata:
    tags: [string]
    estimated_tokens: integer
    file_count_estimate: integer
```

## Ticket Types

### Feature Ticket

```yaml
id: "TICKET-2024-001"
type: feature
priority: high
complexity: medium

title: "Add player inventory system"
description: |
  Implement a comprehensive inventory system that allows
  players to collect, store, and use items during gameplay.

scope:
  target_files:
    - "src/player/inventory.rs"
    - "src/player/mod.rs"
    - "src/items/mod.rs"
  affected_modules:
    - "player"
    - "items"
  dependencies: []

requirements:
  functional:
    - "Players can add items to inventory"
    - "Players can remove items from inventory"
    - "Inventory has maximum capacity"
    - "Items stack when possible"
  acceptance_criteria:
    - "All inventory operations have unit tests"
    - "Integration tests pass"
    - "No performance regression"

testing:
  unit_tests_required: true
  integration_tests_required: true
  coverage_target: 0.85
  test_scenarios:
    - "Add single item"
    - "Add stackable items"
    - "Remove item"
    - "Inventory full scenario"
```

### Bugfix Ticket

```yaml
id: "TICKET-2024-002"
type: bugfix
priority: critical
complexity: simple

title: "Fix player movement stuttering"
description: |
  Player character exhibits stuttering movement when
  moving diagonally at high speeds. Issue appears to
  be in the velocity calculation.

scope:
  target_files:
    - "src/player/movement.rs"
  affected_modules:
    - "player"
  dependencies: []

requirements:
  functional:
    - "Diagonal movement is smooth"
    - "No regression in other movement"
  acceptance_criteria:
    - "Movement test passes"
    - "No stuttering at 60fps"

constraints:
  must_preserve:
    - "All existing movement controls"
    - "Physics behavior"

testing:
  unit_tests_required: true
  integration_tests_required: false
  coverage_target: 0.80
  test_scenarios:
    - "Diagonal movement at max speed"
    - "Diagonal movement with acceleration"
```

### Refactor Ticket

```yaml
id: "TICKET-2024-003"
type: refactor
priority: medium
complexity: complex

title: "Extract rendering system from GameState"
description: |
  Current GameState monolith handles too many concerns.
  Extract rendering logic into a dedicated RenderSystem
  to improve separation of concerns and testability.

scope:
  target_files:
    - "src/state.rs"
    - "src/render/system.rs"  # New file
  affected_modules:
    - "state"
    - "render"
  dependencies: []

requirements:
  functional:
    - "Rendering behavior unchanged"
    - "GameState delegates to RenderSystem"
  acceptance_criteria:
    - "All existing tests pass"
    - "New RenderSystem has tests"
    - "No performance regression"

constraints:
  must_preserve:
    - "All rendering behavior"
    - "Public API compatibility"
  must_not_break:
    - "Any existing functionality"

testing:
  unit_tests_required: true
  integration_tests_required: true
  coverage_target: 0.90
```

## Ticket Lifecycle

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Created │───▶│ Pending │───▶│ Active  │───▶│Complete │
└─────────┘    └─────────┘    └────┬────┘    └─────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼
              ┌─────────┐    ┌─────────┐    ┌─────────┐
              │ Blocked │    │ Failed  │    │ Cancel  │
              └────┬────┘    └────┬────┘    └─────────┘
                   │              │
                   └──────────────┘
                                  │
                                  ▼
                            ┌─────────┐
                            │ Retry   │
                            └─────────┘
```

### Status Definitions

| Status | Description | Transitions |
|--------|-------------|-------------|
| created | Initial state | → pending |
| pending | Waiting for execution | → active, → cancelled |
| active | Currently being worked | → completed, → failed, → blocked |
| blocked | Waiting for dependency | → active |
| failed | Execution failed | → retry, → cancelled |
| completed | Successfully finished | - |
| cancelled | Manually cancelled | - |

## Ticket Dependencies

### Dependency Types

```yaml
dependencies:
  # Must complete before this ticket
  blocks:
    - ticket_id: "TICKET-2024-001"
      reason: "Inventory API needed"
      
  # Can parallelize with this ticket
  parallel:
    - ticket_id: "TICKET-2024-004"
      shared_resources: ["src/items/"]
      
  # Must not conflict with this ticket
  conflicts:
    - ticket_id: "TICKET-2024-005"
      reason: "Modifies same files"
```

### Dependency Resolution

```python
def resolve_dependencies(tickets: [Ticket]) -> ExecutionOrder:
    """Resolve ticket dependencies into execution order."""
    graph = DependencyGraph()
    
    for ticket in tickets:
        graph.add_node(ticket.id, ticket)
        
        for dep in ticket.scope.dependencies:
            graph.add_edge(dep, ticket.id, type="blocks")
    
    # Detect cycles
    if graph.has_cycles():
        raise DependencyCycleError(graph.find_cycles())
    
    # Topological sort for execution order
    execution_order = graph.topological_sort()
    
    # Identify parallelizable groups
    parallel_groups = graph.find_parallel_groups()
    
    return ExecutionOrder(
        sequential=execution_order,
        parallel=parallel_groups
    )
```

## Ticket Estimation

### Complexity Matrix

| Complexity | Effort | Files | Risk | Review |
|------------|--------|-------|------|--------|
| simple | < 2 hours | 1-3 | Low | Auto |
| medium | 2-8 hours | 3-10 | Medium | Auto + Spot |
| complex | 1-3 days | 10-20 | High | Full |
| very_complex | 3+ days | 20+ | Very High | Full + Architecture |

### Token Estimation

```python
def estimate_tokens(ticket: Ticket) -> int:
    """Estimate token usage for ticket execution."""
    base = 1000
    
    # Add for each target file
    for file in ticket.scope.target_files:
        base += estimate_file_tokens(file)
    
    # Add for complexity
    complexity_multiplier = {
        "simple": 1.0,
        "medium": 1.5,
        "complex": 2.5,
        "very_complex": 4.0
    }
    
    return int(base * complexity_multiplier[ticket.complexity])
```

## Ticket Validation

### Pre-Execution Validation

```python
def validate_ticket(ticket: Ticket) -> ValidationResult:
    """Validate ticket before execution."""
    errors = []
    
    # Required fields
    required = ["id", "type", "title", "description"]
    for field in required:
        if not getattr(ticket, field):
            errors.append(f"Missing required field: {field}")
    
    # Scope validation
    if not ticket.scope.target_files:
        errors.append("No target files specified")
    
    # Dependency validation
    for dep in ticket.scope.dependencies:
        if not ticket_exists(dep):
            errors.append(f"Dependency not found: {dep}")
    
    # Test requirements
    if ticket.testing.unit_tests_required and not ticket.testing.coverage_target:
        errors.append("Coverage target required when unit tests required")
    
    return ValidationResult(valid=len(errors) == 0, errors=errors)
```

## Ticket Storage

### File Organization

```
tickets/
  {ticket_id}.yaml          # Ticket specification
  backlog.yaml              # Pending tickets
  active.yaml               # Currently executing
  completed/                # Archive
    {year}/
      {month}/
        {ticket_id}.yaml
```

### Backlog Format

```yaml
TicketBacklog:
  version: "1.0"
  last_updated: ISO8601
  
  tickets:
    - id: "TICKET-2024-001"
      status: pending
      priority: high
      created_at: "2024-01-15T10:00:00Z"
      
    - id: "TICKET-2024-002"
      status: pending
      priority: critical
      created_at: "2024-01-15T10:05:00Z"
```

## Integration with Other Systems

### Intent Decomposition
Tickets created from [[Intent_Specification_Format|intents]]:

```python
def decompose_intent(intent: Intent) -> [Ticket]:
    """Decompose intent into executable tickets."""
    # Use SpecDecomposer agent
    tickets = spec_decomposer.decompose(intent)
    
    # Validate each ticket
    for ticket in tickets:
        validate_ticket(ticket)
    
    return tickets
```

### Command Graph
Tickets feed into [[Command_Graph_Specification|command graphs]]:

```python
def ticket_to_command_graph(ticket: Ticket) -> CommandGraph:
    """Convert ticket to executable command graph."""
    return CommandGraphBuilder()
        .add_node(ContextBuilder(ticket))
        .add_node(CodeGenerator(ticket))
        .add_node(TestWriter(ticket))
        .add_node(Reviewer(ticket))
        .add_node(GateExecutor(ticket))
        .build()
```
