---
title: Command Graph Specification
type: system
layer: architecture
status: active
tags:
  - command-graph
  - orchestration
  - workflow
  - dependencies
  - execution
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Agent_Role_Definitions]"
used_by:
  - "[OpenClaw_Daily_Work_Loop]]"
  - "[[Implementation_Workflow]"
---

# Command Graph Specification

## Purpose

The Command Graph defines how OpenClaw sequences agent invocations, manages dependencies, and coordinates parallel execution. It is the execution engine of the orchestration system.

## Graph Structure

### Nodes
Each node represents an agent task:
```yaml
node:
  id: unique_identifier
  agent: agent_type
  input: input_specification
  output: output_specification
  timeout: duration
  retries: count
```

### Edges
Edges define execution flow:
```yaml
edge:
  from: source_node_id
  to: target_node_id
  type: sequential|parallel|conditional
  condition: expression (for conditional)
```

## Execution Patterns

### 1. Sequential Execution
```
[Node A] ──▶ [Node B] ──▶ [Node C]
```
- Node B waits for Node A completion
- Used when dependencies exist
- Default pattern for complex workflows

### 2. Parallel Execution
```
              ┌─▶ [Node B] ─┐
[Node A] ────┤             ├──▶ [Node D]
              └─▶ [Node C] ─┘
```
- Nodes B and C execute simultaneously
- Node D waits for both B and C
- Used for independent subtasks

### 3. Conditional Execution
```
              ┌─▶ [Node B] (if condition)
[Node A] ────┤
              └─▶ [Node C] (else)
```
- Path determined by previous output
- Enables adaptive workflows
- Conditions evaluated by OpenClaw

### 4. Fan-Out/Fan-In
```
              ┌─▶ [Node B] ─┐
[Node A] ────┼─▶ [Node C] ─┼──▶ [Node E]
              └─▶ [Node D] ─┘
```
- One task spawns many parallel tasks
- Results aggregated at fan-in point
- Used for batch operations

## Standard Graph Templates

### Feature Implementation Graph
```
[SpecDecomposer]
       │
       ▼
[ContextBuilder]
       │
       ▼
   ┌───────┐
   │ Split │
   └───┬───┘
       │
   ┌───┴───┐
   ▼       ▼
[CodeGen] [TestWriter]
   │       │
   └───┬───┘
       ▼
[Reviewer]
       │
       ▼
[GateExecutor]
       │
       ▼
[PatchBuilder]
```

### Bug Fix Graph
```
[ContextBuilder]
       │
       ▼
[CodeGenerator]
       │
       ▼
[TestWriter] (regression tests)
       │
       ▼
[GateExecutor]
       │
       ▼
[PatchBuilder]
```

### Refactoring Graph
```
[RefactorPlanner]
       │
       ▼
[ContextBuilder] (for each step)
       │
       ▼
[CodeGenerator]
       │
       ▼
[GateExecutor]
       │
       ▼
[Reviewer] (human for major changes)
```

## Dependency Resolution

### Static Dependencies
Defined at graph creation:
- Task B requires Task A output
- Parallel tasks must not conflict
- Resources must not be contended

### Dynamic Dependencies
Resolved during execution:
- File locks
- Test dependencies
- External service availability

### Conflict Detection
```python
def detect_conflicts(nodes):
    conflicts = []
    for i, node_a in enumerate(nodes):
        for node_b in nodes[i+1:]:
            if has_file_overlap(node_a, node_b):
                conflicts.append((node_a.id, node_b.id))
    return conflicts
```

## Message Routing

### Intra-Graph Communication
- Nodes communicate through OpenClaw
- No direct node-to-node messaging
- All state changes logged

### Inter-Graph Communication
- Completed graphs emit events
- Other graphs can subscribe to events
- Enables reactive workflows

## Execution State Machine

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│ Pending │────▶│ Running │────▶│Success  │
└─────────┘     └────┬────┘     └─────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐
   │  Retry  │  │ Failed  │  │Timeout  │
   └────┬────┘  └─────────┘  └────┬────┘
        │                          │
        └────────────┬─────────────┘
                     ▼
               ┌─────────┐
               │Rollback │
               └─────────┘
```

## Synchronization Primitives

### Barriers
Wait for all parallel tasks:
```yaml
barrier:
  name: "code_complete"
  waits_for: [code_gen, test_gen]
  timeout: 10m
```

### Semaphores
Limit concurrent resource access:
```yaml
semaphore:
  name: "test_runner"
  capacity: 4
```

### Locks
Exclusive file access:
```yaml
lock:
  resource: "src/player.rs"
  holder: node_id
  timeout: 5m
```

## Error Propagation

### Failure Types
1. **Recoverable**: Retry with backoff
2. **Partial**: Continue with degraded functionality
3. **Critical**: Stop graph, trigger rollback

### Escalation Path
```
Agent Failure → Node Retry → Graph Retry → Rollback → Human Escalation
```

## Monitoring & Observability

### Metrics
- Node execution time
- Graph completion rate
- Retry frequency
- Parallel efficiency

### Tracing
- Unique trace ID per graph
- Span per node execution
- Context propagation

### Logging
```json
{
  "trace_id": "uuid",
  "node_id": "code_gen_1",
  "agent": "CodeGenerator",
  "status": "completed",
  "duration_ms": 4500,
  "input_size": 10240,
  "output_size": 5120
}
```

## Performance Optimization

### Caching
- Cache context packs for repeated access
- Memoize agent outputs for identical inputs
- Pre-warm frequently used contexts

### Batching
- Batch similar operations
- Reduce context pack rebuilds
- Parallel where safe

### Resource Management
- Token budget per graph
- Memory limits per node
- CPU allocation for compute-heavy tasks
