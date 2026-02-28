---
title: Agent Role Definitions
type: agent
layer: architecture
status: active
tags:
  - agents
  - roles
  - responsibilities
  - specialist
  - openclaw
depends_on:
  - "[Orchestration_Architecture_Overview]"
used_by:
  - "[Command_Graph_Specification]]"
  - "[[OpenClaw_Daily_Work_Loop]]"
  - "[[Prompt_Ticket_Executor]"
---

# Agent Role Definitions

## Overview

Each agent in the OpenClaw ecosystem is a specialized AI with a narrow, well-defined responsibility. Agents are stateless and receive complete context for each task invocation.

## Agent Taxonomy

### 1. SpecDecomposer Agent

**Purpose**: Transform human intent into executable tickets

**Responsibilities**:
- Parse [[Intent_Specification_Format|intent specifications]]
- Identify dependencies and execution order
- Estimate complexity and effort
- Generate [[Ticket_Template_Spec|ticket specifications]]

**Inputs**:
- Intent specification (YAML)
- Project context (relevant files)
- Existing ticket backlog

**Outputs**:
- List of tickets with dependencies
- Complexity estimates
- Risk assessments

**Constraints**:
- Single-threaded (no parallel decomposition)
- Must complete before any implementation

---

### 2. CodeGenerator Agent

**Purpose**: Implement features and fix bugs

**Responsibilities**:
- Generate code from ticket specifications
- Follow project coding standards
- Include inline documentation
- Ensure type safety

**Inputs**:
- Ticket specification
- Context pack (relevant files)
- Coding standards document
- Test requirements

**Outputs**:
- NEW_FILES: Created source files
- MODIFICATIONS: Changed files with diffs
- INTEGRATION_GUIDE: How to integrate

**Constraints**:
- Parallel execution per module
- Max 500 lines changed per ticket
- Must not break existing tests

---

### 3. TestWriter Agent

**Purpose**: Create comprehensive test coverage

**Responsibilities**:
- Write unit tests for new code
- Create integration tests
- Generate edge case tests
- Ensure coverage thresholds

**Inputs**:
- Code changes (from CodeGenerator)
- Test requirements from ticket
- Existing test patterns

**Outputs**:
- TESTS: Test files and cases
- Coverage report
- Test data (if needed)

**Constraints**:
- Parallel with CodeGenerator
- Min 80% coverage for new code
- Tests must be deterministic

---

### 4. Reviewer Agent

**Purpose**: Validate code quality and correctness

**Responsibilities**:
- Static analysis
- Logic verification
- Security review
- Performance check
- Style compliance

**Inputs**:
- Code changes
- Original ticket specification
- Review checklist

**Outputs**:
- Review report (pass/fail/partial)
- List of issues (if any)
- Suggested fixes

**Constraints**:
- Parallel execution
- Must complete before merge
- Cannot approve own changes

---

### 5. RefactorPlanner Agent

**Purpose**: Plan safe refactoring operations

**Responsibilities**:
- Analyze code for refactoring opportunities
- Plan incremental refactoring steps
- Identify risk areas
- Create rollback strategy

**Inputs**:
- Code to refactor
- Refactoring goals
- Dependency graph

**Outputs**:
- Refactoring plan (step-by-step)
- Risk assessment
- Test impact analysis

**Constraints**:
- Single-threaded
- Must preserve behavior
- Requires human approval for major changes

---

### 6. DocGenerator Agent

**Purpose**: Create and update documentation

**Responsibilities**:
- API documentation
- Code comments
- User guides
- Architecture docs

**Inputs**:
- Code changes
- Existing documentation
- Documentation standards

**Outputs**:
- Updated documentation files
- CHANGELOG entries
- Migration guides (if needed)

**Constraints**:
- Parallel execution
- Must sync with code changes

---

### 7. GateExecutor Agent

**Purpose**: Execute [[Gate_Protocol|gate checks]]

**Responsibilities**:
- Run automated tests
- Check code coverage
- Validate formatting
- Verify dependencies

**Inputs**:
- Code changes
- Gate configuration
- Test suite

**Outputs**:
- Gate result (pass/fail)
- Detailed report
- Failure reasons (if applicable)

**Constraints**:
- Blocking operation
- Must run in isolated environment

---

### 8. PatchBuilder Agent

**Purpose**: Create [[Patch_Protocol|patches]] from changes

**Responsibilities**:
- Generate clean diffs
- Ensure patch applicability
- Create rollback patches
- Validate patch integrity

**Inputs**:
- File changes
- Base commit
- Target branch

**Outputs**:
- Patch file
- Rollback patch
- Application instructions

**Constraints**:
- Must be reversible
- Must apply cleanly

## Agent Communication Rules

1. **No Direct Communication**: Agents never talk to each other
2. **OpenClaw Mediates**: All coordination through orchestrator
3. **Context Packs Only**: Agents receive only what they need
4. **Normalized Outputs**: All agents produce same output format
5. **Failure Propagation**: Failures bubble up to OpenClaw

## Agent Lifecycle

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  Idle   │───▶│Invoked  │───▶│Executing│───▶│Complete │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
                                    │
                                    ▼
                              ┌─────────┐
                              │ Failed  │
                              └─────────┘
```

## Resource Limits

| Agent | Max Tokens | Timeout | Parallel |
|-------|-----------|---------|----------|
| SpecDecomposer | 8K | 5 min | No |
| CodeGenerator | 16K | 10 min | Yes |
| TestWriter | 8K | 5 min | Yes |
| Reviewer | 8K | 5 min | Yes |
| RefactorPlanner | 8K | 5 min | No |
| DocGenerator | 8K | 3 min | Yes |
| GateExecutor | 4K | 15 min | No |
| PatchBuilder | 4K | 2 min | Yes |

## Failure Modes

- **Timeout**: Agent exceeded time limit → Retry with smaller context
- **Context Overflow**: Input too large → Split task, rebuild context
- **Output Parse Error**: Invalid format → Retry with clearer instructions
- **Execution Error**: Code failed → Log and escalate
- **Quality Gate Fail**: Review found issues → Route to [[Prompt_Gate_Failure_Fixer|failure fixer]]
