---
title: OpenClaw Core System
type: system
layer: architecture
status: active
tags:
  - openclaw
  - core
  - system
  - architecture
  - agents
depends_on:
  - "[Studio_OS_Overview]]"
  - "[[Intent_to_Release_Pipeline]]"
  - "[[Autonomy_Ladder_L0_L5]]"
  - "[[Studio_Priorities_Manifesto]"
used_by:
  - "[Decision_Making_Protocols]]"
  - "[[Governance_and_Authority_Boundaries]]"
  - "[[Autonomy_Upgrade_Path]"
---

# OpenClaw Core System

## System Purpose

OpenClaw is the autonomous build and execution engine at the heart of the Studio OS. It transforms human intent (tickets) into shipped builds through a deterministic pipeline of parsing, planning, execution, and validation.

## Core Responsibilities

1. **Parse**: Interpret human intent from tickets into machine-executable plans
2. **Plan**: Sequence work items, allocate resources, position gates
3. **Execute**: Run agents and tools to complete work
4. **Validate**: Verify output against acceptance criteria
5. **Integrate**: Package and ship validated output
6. **Monitor**: Track progress, costs, and quality metrics

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     OPENCLAW CORE SYSTEM                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │   PARSER    │───▶│  SCHEDULER  │───▶│  EXECUTION ENGINE   │  │
│  │             │    │             │    │                     │  │
│  │ - Ticket    │    │ - Sequencing│    │ - Agent dispatch    │  │
│  │   reader    │    │ - Resource  │    │ - Tool invocation   │  │
│  │ - Context   │    │   alloc     │    │ - State management  │  │
│  │   loader    │    │ - Checkpoint│    │ - Error handling    │  │
│  │ - Plan      │    │   definition│    │ - Progress tracking │  │
│  │   generator │    │ - Gate      │    │                     │  │
│  │             │    │   placement │    │                     │  │
│  └─────────────┘    └─────────────┘    └─────────────────────┘  │
│         │                  │                    │                │
│         └──────────────────┴────────────────────┘                │
│                            │                                     │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              CONTEXT & STATE MANAGER                     │    │
│  │  - Ticket state tracking    - Checkpoint storage         │    │
│  │  - Dependency graph         - History & metrics          │    │
│  │  - Spec references          - Cost tracking              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            │                                     │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              AGENT & TOOL REGISTRY                       │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │    │
│  │  │ CodeGen  │ │  Asset   │ │  Test    │ │  Build   │   │    │
│  │  │  Agent   │ │  Agent   │ │  Agent   │ │  Agent   │   │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │    │
│  │  │ Godot    │ │  Unity   │ │  Git     │ │  Deploy  │   │    │
│  │  │  Tool    │ │  Tool    │ │  Tool    │ │  Tool    │   │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Specifications

### Parser Module

**Purpose**: Transform tickets into executable plans

**Inputs**:
- Ticket (Markdown with YAML frontmatter)
- Linked specifications
- Current codebase state
- Historical context

**Outputs**:
- Parsed ticket structure
- Work item list
- Dependency graph
- Autonomy level recommendation

**Capabilities**:
- Parse YAML frontmatter for metadata
- Extract acceptance criteria
- Identify work type (code, asset, config, etc.)
- Load and link specifications
- Determine required tools/agents
- Estimate effort and cost

**Failure Modes**:
- Missing acceptance criteria → Escalate for clarification
- Ambiguous requirements → Request specification
- Unknown work type → Escalate to human

### Scheduler Module

**Purpose**: Create optimal execution sequence

**Inputs**:
- Parsed ticket with work items
- Dependency graph
- Available resources
- Cost constraints

**Outputs**:
- Execution plan (ordered steps)
- Resource allocation
- Checkpoint definitions
- Gate positioning

**Capabilities**:
- Topological sort of dependencies
- Parallel execution identification
- Resource conflict resolution
- Timeout assignment per step
- Fallback path definition

**Optimization Goals** (in priority order):
1. Minimize total cost
2. Minimize wall-clock time
3. Maximize checkpoint frequency
4. Minimize API calls

**Failure Modes**:
- Circular dependency → Escalate for architectural review
- Resource unavailable → Queue with ETA
- Cost exceeds budget → Require authorization

### Execution Engine

**Purpose**: Execute planned work

**Inputs**:
- Execution plan
- Context and state
- Agent/tool registry

**Outputs**:
- Execution results
- State changes
- Progress updates
- Error reports

**Capabilities**:
- Agent dispatch and monitoring
- Tool invocation
- State checkpointing
- Error handling and retry
- Progress reporting
- Cost tracking

**Execution Modes**:
- **Sequential**: Steps execute in order, one at a time
- **Parallel**: Independent steps execute concurrently
- **Hybrid**: Mix based on dependencies and resources

**Failure Handling**:
- Step failure → Execute fallback (retry/alternate/escalate)
- Timeout → Checkpoint and escalate
- Crash → Restore from last checkpoint
- Cost threshold → Pause and notify

### Context & State Manager

**Purpose**: Maintain system state across operations

**Responsibilities**:
- Ticket state tracking (PENDING → PARSING → ... → SHIPPED)
- Checkpoint storage and recovery
- Dependency graph maintenance
- Historical data and metrics
- Spec reference resolution
- Cost accumulation and reporting

**Storage**:
- Primary: Obsidian vault (canonical)
- Cache: Local filesystem (performance)
- Backup: Version control (recovery)

### Agent & Tool Registry

**Purpose**: Provide capabilities for execution

#### Agents
Agents are AI-powered components that perform complex tasks:

| Agent | Purpose | Target |
|-------|---------|--------|
| CodeGen | Generate code from specifications | Godot GDScript, Unity C# |
| Asset | Generate/modify game assets | Images, audio, models |
| Test | Generate and run tests | Unit, integration, play mode |
| Build | Execute build pipelines | Export, package, deploy |
| Review | Analyze code for issues | Quality, security, style |

#### Tools
Tools are deterministic utilities for specific operations:

| Tool | Purpose | Interface |
|------|---------|-----------|
| Godot | Engine operations | CLI, GDScript |
| Unity | Engine operations | CLI, C# |
| Git | Version control | CLI |
| Deploy | Deployment operations | CLI, APIs |

## Interfaces

### Human Interface (Obsidian)
- Tickets created as Markdown files
- Gates defined in YAML frontmatter
- Results written back to vault
- Status updates via file modifications

### Engine Interfaces
- **Godot 4.x**: CLI for builds, GDScript for scripting
- **Unity**: CLI for builds, C# for scripting

### API Interfaces
- LLM APIs (used sparingly, cached aggressively)
- Cloud services (when local insufficient)
- External tools (via CLI wrappers)

## Configuration

```yaml
openclaw:
  # Cost controls
  max_cost_per_ticket: 10.0  # USD
  max_cost_per_day: 100.0    # USD
  api_call_budget: 1000      # calls per day
  
  # Time controls
  default_step_timeout: 300  # seconds
  max_ticket_duration: 86400 # seconds (24 hours)
  
  # Autonomy
  default_autonomy: L2
  min_autonomy_for_auto_gate: L3
  
  # Paths
  vault_path: /path/to/obsidian/vault
  cache_path: /path/to/cache
  checkpoint_path: /path/to/checkpoints
  
  # Engine configs
  godot:
    path: /path/to/godot
    export_templates: /path/to/templates
  
  unity:
    path: /path/to/unity
    build_target: StandaloneWindows64
```

## Monitoring & Metrics

### Tracked Metrics
- Tickets processed (total, by status, by autonomy level)
- Gate pass rate (overall, by gate type)
- Cost per ticket (actual vs. estimated)
- Cycle time (intent to shipped)
- Human escalations (count, reasons)
- Agent performance (success rate, duration)

### Alert Conditions
- Cost exceeds 80% of budget
- Gate pass rate drops below 90%
- Escalation rate exceeds 20%
- Cycle time exceeds target by 50%

## Failure Modes & Recovery

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Parse error | Parser validation | Escalate with context |
| Plan error | Scheduler validation | Escalate for review |
| Execution error | Step failure | Retry → Fallback → Escalate |
| State corruption | Validation check | Restore from checkpoint |
| Cost overrun | Monitor alert | Pause, require authorization |
| Timeout | Timer expiration | Checkpoint, escalate |

## Security Considerations

- All file operations within sandboxed paths
- No execution of untrusted code
- API keys in environment, not config
- All changes logged immutably
- Human override always available
