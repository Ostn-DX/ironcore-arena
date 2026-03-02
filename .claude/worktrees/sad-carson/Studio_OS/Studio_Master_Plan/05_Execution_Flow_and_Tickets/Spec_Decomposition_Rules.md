---
title: Spec Decomposition Rules
type: system
layer: execution
status: active
tags:
  - decomposition
  - specification
  - rules
  - tickets
  - breakdown
depends_on:
  - "[Intent_Specification_Format]]"
  - "[[Ticket_Template_Spec]"
used_by:
  - "[OpenClaw_Daily_Work_Loop]]"
  - "[[Implementation_Workflow]"
---

# Spec Decomposition Rules

## Purpose

Spec Decomposition Rules define how OpenClaw breaks down high-level intents into executable tickets. These rules ensure consistent, appropriately-sized work items that can be efficiently processed by specialist agents.

## Decomposition Principles

1. **Single Responsibility**: Each ticket addresses one concern
2. **Appropriate Size**: Tickets fit within agent token/context limits
3. **Clear Dependencies**: Dependencies explicit and minimal
4. **Testable Units**: Each ticket has verifiable outcomes
5. **Incremental Value**: Each ticket delivers incremental value

## Decomposition Strategies

### 1. Vertical Slicing

Decompose by user-facing feature:

```
Intent: "Add player inventory system"

Tickets:
├── TICKET-001: Inventory data model
├── TICKET-002: Inventory operations (add/remove)
├── TICKET-003: Inventory UI - display
├── TICKET-004: Inventory UI - interactions
└── TICKET-005: Inventory persistence
```

### 2. Horizontal Layering

Decompose by architectural layer:

```
Intent: "Add multiplayer lobby"

Tickets:
├── TICKET-001: Network protocol for lobby
├── TICKET-002: Server-side lobby management
├── TICKET-003: Client lobby interface
└── TICKET-004: Lobby UI components
```

### 3. CRUD Decomposition

For data management features:

```
Intent: "Manage game settings"

Tickets:
├── TICKET-001: Create settings schema
├── TICKET-002: Read settings from storage
├── TICKET-003: Update settings
├── TICKET-004: Delete/reset settings
└── TICKET-005: Settings UI
```

### 4. Workflow Decomposition

For multi-step processes:

```
Intent: "Player authentication flow"

Tickets:
├── TICKET-001: Login form UI
├── TICKET-002: Credential validation
├── TICKET-003: Session management
├── TICKET-004: Password reset flow
└── TICKET-005: Logout handling
```

## Decomposition Rules

### Rule 1: Maximum Ticket Size

```python
MAX_TICKET_SIZE = {
    "files": 10,           # Max files to modify
    "lines": 500,          # Max lines changed
    "complexity": "medium" # Max complexity
}

def validate_ticket_size(ticket: Ticket) -> bool:
    """Check if ticket is appropriately sized."""
    return (
        len(ticket.scope.target_files) <= MAX_TICKET_SIZE["files"]
        and ticket.complexity in ["simple", "medium"]
    )
```

### Rule 2: Dependency Minimization

```python
def minimize_dependencies(tickets: [Ticket]) -> [Ticket]:
    """Restructure tickets to minimize dependencies."""
    
    # Identify common dependencies
    common_deps = find_common_dependencies(tickets)
    
    # Extract common work into separate ticket
    if common_deps:
        common_ticket = create_common_ticket(common_deps)
        tickets.insert(0, common_ticket)
        
        # Update other tickets to depend on common ticket
        for ticket in tickets[1:]:
            ticket.scope.dependencies.append(common_ticket.id)
    
    return tickets
```

### Rule 3: Test Coverage Per Ticket

```python
def ensure_test_coverage(ticket: Ticket) -> Ticket:
    """Ensure ticket includes appropriate test requirements."""
    
    # Unit tests for logic changes
    if has_logic_changes(ticket):
        ticket.testing.unit_tests_required = True
        ticket.testing.coverage_target = 0.80
    
    # Integration tests for API changes
    if has_api_changes(ticket):
        ticket.testing.integration_tests_required = True
    
    # E2E tests for UI changes
    if has_ui_changes(ticket):
        ticket.testing.e2e_tests_required = True
    
    return ticket
```

### Rule 4: Clear Acceptance Criteria

```python
def generate_acceptance_criteria(ticket: Ticket) -> [str]:
    """Generate acceptance criteria from ticket description."""
    
    criteria = []
    
    # Extract from requirements
    for req in ticket.requirements.functional:
        criteria.append(f"{req} is implemented")
        criteria.append(f"{req} has tests")
    
    # Add quality criteria
    criteria.append("All tests pass")
    criteria.append("Code review approved")
    criteria.append("No lint errors")
    
    return criteria
```

## Decomposition Patterns

### Pattern: API + Implementation + Tests

```
Intent: "Add player stats API"

Tickets:
├── TICKET-001: Define stats API interface
│   └── Acceptance: API contract defined and reviewed
├── TICKET-002: Implement stats storage
│   └── Dependencies: [TICKET-001]
│   └── Acceptance: Stats stored and retrieved correctly
├── TICKET-003: Implement stats operations
│   └── Dependencies: [TICKET-002]
│   └── Acceptance: All CRUD operations work
└── TICKET-004: Add stats tests
    └── Dependencies: [TICKET-003]
    └── Acceptance: 90%+ coverage
```

### Pattern: UI + Backend Integration

```
Intent: "Add settings panel"

Tickets:
├── TICKET-001: Create settings backend
│   └── Acceptance: Settings API functional
├── TICKET-002: Design settings UI
│   └── Acceptance: UI mockups approved
├── TICKET-003: Implement settings UI
│   └── Dependencies: [TICKET-002]
│   └── Acceptance: UI matches design
└── TICKET-004: Integrate UI with backend
    └── Dependencies: [TICKET-001, TICKET-003]
    └── Acceptance: End-to-end flow works
```

### Pattern: Refactor + Migrate + Verify

```
Intent: "Extract rendering system"

Tickets:
├── TICKET-001: Create new render system module
│   └── Acceptance: Module compiles, tests pass
├── TICKET-002: Migrate rendering code (batch 1)
│   └── Dependencies: [TICKET-001]
│   └── Acceptance: Batch 1 migrated, tests pass
├── TICKET-003: Migrate rendering code (batch 2)
│   └── Dependencies: [TICKET-002]
│   └── Acceptance: Batch 2 migrated, tests pass
└── TICKET-004: Remove old rendering code
    └── Dependencies: [TICKET-003]
    └── Acceptance: Old code removed, all tests pass
```

## Decomposition Algorithm

```python
async def decompose_intent(intent: Intent) -> [Ticket]:
    """Decompose intent into executable tickets."""
    
    # 1. Analyze intent
    analysis = await analyze_intent(intent)
    
    # 2. Select decomposition strategy
    strategy = select_strategy(analysis)
    
    # 3. Generate initial tickets
    tickets = await generate_tickets(intent, strategy)
    
    # 4. Apply decomposition rules
    tickets = apply_rules(tickets)
    
    # 5. Validate tickets
    for ticket in tickets:
        validate_ticket(ticket)
    
    # 6. Optimize dependencies
    tickets = minimize_dependencies(tickets)
    
    # 7. Assign priorities
    tickets = assign_priorities(tickets, intent.priority)
    
    # 8. Generate metadata
    for i, ticket in enumerate(tickets):
        ticket.id = f"{intent.intent_id}-{i+1:03d}"
        ticket.source.intent_id = intent.intent_id
    
    return tickets
```

## Complexity Estimation

```python
def estimate_complexity(ticket: Ticket) -> Complexity:
    """Estimate ticket complexity."""
    
    score = 0
    
    # File count
    score += len(ticket.scope.target_files) * 2
    
    # Dependency count
    score += len(ticket.scope.dependencies) * 3
    
    # Requirement complexity
    score += len(ticket.requirements.functional) * 1
    score += len(ticket.requirements.non_functional) * 2
    
    # Map to complexity
    if score <= 5:
        return "simple"
    elif score <= 15:
        return "medium"
    elif score <= 30:
        return "complex"
    else:
        return "very_complex"
```

## Dependency Resolution

```python
def resolve_ticket_dependencies(tickets: [Ticket]) -> ExecutionOrder:
    """Resolve dependencies into execution order."""
    
    # Build dependency graph
    graph = nx.DiGraph()
    
    for ticket in tickets:
        graph.add_node(ticket.id, ticket=ticket)
        
        for dep_id in ticket.scope.dependencies:
            graph.add_edge(dep_id, ticket.id)
    
    # Check for cycles
    if not nx.is_directed_acyclic_graph(graph):
        cycles = list(nx.simple_cycles(graph))
        raise DependencyCycleError(cycles)
    
    # Topological sort
    execution_order = list(nx.topological_sort(graph))
    
    # Group parallelizable tickets
    parallel_groups = []
    current_group = []
    
    for ticket_id in execution_order:
        ticket = graph.nodes[ticket_id]["ticket"]
        
        # Check if can parallelize with current group
        if can_parallelize(ticket, current_group, graph):
            current_group.append(ticket)
        else:
            if current_group:
                parallel_groups.append(current_group)
            current_group = [ticket]
    
    if current_group:
        parallel_groups.append(current_group)
    
    return ExecutionOrder(
        sequential=execution_order,
        parallel=parallel_groups
    )
```

## Integration with Other Systems

### Intent Processing
Decomposition is part of [[Intent_Specification_Format|intent processing]]:

```python
tickets = await decompose_intent(intent)
```

### Ticket Creation
Decomposition creates [[Ticket_Template_Spec|tickets]]:

```python
for ticket in tickets:
    await create_ticket(ticket)
```

### Command Graph
Decomposition results feed into [[Command_Graph_Specification|command graphs]]:

```python
for ticket_group in execution_order.parallel:
    graph = build_parallel_graph(ticket_group)
```
