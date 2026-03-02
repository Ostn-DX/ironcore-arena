---
title: Implementation Workflow
type: pipeline
layer: execution
status: active
tags:
  - implementation
  - workflow
  - code
  - test
  - execution
depends_on:
  - "[Ticket_Template_Spec]]"
  - "[[Patch_Protocol]]"
  - "[[Gate_Protocol]"
used_by:
  - "[OpenClaw_Daily_Work_Loop]]"
  - "[[Review_Gate_Workflow]"
---

# Implementation Workflow

## Purpose

The Implementation Workflow defines the end-to-end process for executing tickets—from context building through code generation, testing, and gate validation.

## Workflow Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Ticket    │───▶│   Context   │───▶│    Code     │
│   Intake    │    │   Builder   │    │  Generator  │
└─────────────┘    └─────────────┘    └──────┬──────┘
                                             │
┌─────────────┐    ┌─────────────┐    ┌─────┴─────┐
│    Gate     │◀───│   Output    │◀───│   Test    │
│  Validator  │    │  Normalizer │    │  Writer   │
└──────┬──────┘    └─────────────┘    └───────────┘
       │
       ▼
┌─────────────┐
│   Result    │
│  (Pass/Fail)│
└─────────────┘
```

## Phase 1: Ticket Intake

### Ticket Validation

```python
async def intake_ticket(ticket: Ticket) -> IntakeResult:
    """Validate and prepare ticket for execution."""
    
    # 1. Validate ticket format
    validation = validate_ticket(ticket)
    if not validation.valid:
        return IntakeResult(
            status="rejected",
            reason="Validation failed",
            errors=validation.errors
        )
    
    # 2. Check dependencies
    deps_satisfied = await check_dependencies(ticket)
    if not deps_satisfied:
        return IntakeResult(
            status="blocked",
            reason="Dependencies not satisfied"
        )
    
    # 3. Check for conflicts
    conflicts = await check_conflicts(ticket)
    if conflicts:
        return IntakeResult(
            status="blocked",
            reason="Conflicts detected",
            conflicts=conflicts
        )
    
    # 4. Reserve resources
    await reserve_resources(ticket)
    
    return IntakeResult(status="accepted", ticket=ticket)
```

## Phase 2: Context Building

### Build Execution Context

```python
async def build_execution_context(ticket: Ticket) -> ExecutionContext:
    """Build complete context for ticket execution."""
    
    # 1. Build context pack
    context_pack = await context_builder.build(
        target_files=ticket.scope.target_files,
        agent_type="CodeGenerator",
        options=ContextOptions(
            include_dependencies=True,
            include_tests=ticket.testing.unit_tests_required,
            depth=3
        )
    )
    
    # 2. Load coding standards
    standards = await load_coding_standards(
        languages=context_pack.languages
    )
    
    # 3. Load relevant examples
    examples = await load_examples(
        pattern=ticket.type,
        limit=5
    )
    
    # 4. Build execution context
    return ExecutionContext(
        ticket=ticket,
        context_pack=context_pack,
        coding_standards=standards,
        examples=examples,
        constraints=ticket.constraints
    )
```

## Phase 3: Code Generation

### Generate Implementation

```python
async def generate_code(context: ExecutionContext) -> CodeResult:
    """Generate code implementation."""
    
    # 1. Prepare prompt
    prompt = build_code_generation_prompt(context)
    
    # 2. Invoke CodeGenerator agent
    result = await agent_executor.invoke(
        agent="CodeGenerator",
        prompt=prompt,
        context=context.context_pack,
        timeout=600
    )
    
    # 3. Parse and normalize output
    normalized = output_normalizer.normalize(
        agent_output=result,
        agent_type="CodeGenerator"
    )
    
    # 4. Validate output
    validation = validate_code_output(normalized)
    if not validation.valid:
        raise CodeGenerationError(validation.errors)
    
    return CodeResult(
        normalized_output=normalized,
        files_created=len(normalized.NEW_FILES),
        files_modified=len(normalized.MODIFICATIONS)
    )
```

## Phase 4: Test Generation

### Generate Tests

```python
async def generate_tests(
    context: ExecutionContext,
    code_result: CodeResult
) -> TestResult:
    """Generate tests for implementation."""
    
    if not context.ticket.testing.unit_tests_required:
        return TestResult(tests_generated=0)
    
    # 1. Build test context
    test_context = await build_test_context(
        code_result=code_result,
        coverage_target=context.ticket.testing.coverage_target
    )
    
    # 2. Prepare test prompt
    prompt = build_test_generation_prompt(test_context)
    
    # 3. Invoke TestWriter agent
    result = await agent_executor.invoke(
        agent="TestWriter",
        prompt=prompt,
        context=test_context,
        timeout=300
    )
    
    # 4. Normalize and validate
    normalized = output_normalizer.normalize(
        agent_output=result,
        agent_type="TestWriter"
    )
    
    return TestResult(
        tests=normalized.TESTS,
        test_count=len(normalized.TESTS),
        coverage_estimate=estimate_coverage(normalized.TESTS)
    )
```

## Phase 5: Output Normalization

### Normalize Agent Outputs

```python
async def normalize_outputs(
    code_result: CodeResult,
    test_result: TestResult
) -> NormalizedOutput:
    """Combine and normalize all agent outputs."""
    
    # 1. Merge outputs
    merged = NormalizedOutput(
        NEW_FILES=code_result.normalized_output.NEW_FILES,
        MODIFICATIONS=code_result.normalized_output.MODIFICATIONS,
        TESTS=test_result.tests,
        INTEGRATION_GUIDE=generate_integration_guide(
            code_result=code_result,
            test_result=test_result
        )
    )
    
    # 2. Validate complete output
    validation = validate_normalized_output(merged)
    if not validation.valid:
        raise NormalizationError(validation.errors)
    
    # 3. Save output
    await save_normalized_output(
        ticket_id=context.ticket.id,
        output=merged
    )
    
    return merged
```

## Phase 6: Gate Validation

### Run Gate Suite

```python
async def validate_with_gates(
    normalized_output: NormalizedOutput,
    ticket: Ticket
) -> GateResult:
    """Run gate validation on changes."""
    
    # 1. Create patch from output
    patch = create_patch_from_output(normalized_output)
    
    # 2. Apply patch to temporary branch
    temp_branch = f"gate-check/{ticket.id}"
    await apply_patch_to_branch(patch, temp_branch)
    
    # 3. Run gate suite
    gate_result = await gate_executor.execute_suite(
        suite=load_gate_suite("standard"),
        context=GateContext(
            branch=temp_branch,
            ticket=ticket
        )
    )
    
    # 4. Cleanup temporary branch
    await delete_branch(temp_branch)
    
    return gate_result
```

## Phase 7: Result Handling

### Handle Gate Result

```python
async def handle_gate_result(
    gate_result: GateResult,
    ticket: Ticket,
    normalized_output: NormalizedOutput
) -> WorkflowResult:
    """Handle gate validation result."""
    
    if gate_result.status == "passed":
        # Success - submit for review
        await submit_for_review(
            ticket=ticket,
            output=normalized_output,
            gate_result=gate_result
        )
        
        return WorkflowResult(
            status="success",
            ticket_id=ticket.id,
            next_step="review"
        )
    
    elif gate_result.status == "partial":
        # Some non-critical gates failed
        # Submit with warnings
        await submit_for_review(
            ticket=ticket,
            output=normalized_output,
            gate_result=gate_result,
            warnings=gate_result.warnings
        )
        
        return WorkflowResult(
            status="partial",
            ticket_id=ticket.id,
            warnings=gate_result.warnings,
            next_step="review"
        )
    
    else:  # failed
        # Critical gate failed
        # Route to failure fixer
        fix_result = await route_to_failure_fixer(
            ticket=ticket,
            gate_result=gate_result,
            output=normalized_output
        )
        
        if fix_result.fixed:
            # Retry with fixes
            return WorkflowResult(
                status="retry",
                ticket_id=ticket.id,
                next_step="implementation"
            )
        else:
            # Could not fix - escalate
            return WorkflowResult(
                status="failed",
                ticket_id=ticket.id,
                error=gate_result.error,
                next_step="escalate"
            )
```

## Complete Workflow Execution

```python
async def execute_implementation_workflow(ticket: Ticket) -> WorkflowResult:
    """Execute complete implementation workflow."""
    
    try:
        # Phase 1: Intake
        intake = await intake_ticket(ticket)
        if intake.status != "accepted":
            return WorkflowResult(
                status="rejected",
                reason=intake.reason
            )
        
        # Phase 2: Build Context
        context = await build_execution_context(ticket)
        
        # Phase 3: Generate Code
        code_result = await generate_code(context)
        
        # Phase 4: Generate Tests
        test_result = await generate_tests(context, code_result)
        
        # Phase 5: Normalize Output
        normalized = await normalize_outputs(code_result, test_result)
        
        # Phase 6: Gate Validation
        gate_result = await validate_with_gates(normalized, ticket)
        
        # Phase 7: Handle Result
        return await handle_gate_result(gate_result, ticket, normalized)
        
    except Exception as e:
        # Handle unexpected errors
        logger.error(f"Workflow failed: {e}")
        
        # Attempt rollback
        await rollback_workflow(ticket)
        
        return WorkflowResult(
            status="error",
            ticket_id=ticket.id,
            error=str(e)
        )
```

## Retry Logic

```python
async def execute_with_retry(
    ticket: Ticket,
    max_retries: int = 3
) -> WorkflowResult:
    """Execute workflow with retry logic."""
    
    for attempt in range(max_retries + 1):
        result = await execute_implementation_workflow(ticket)
        
        if result.status in ["success", "partial"]:
            return result
        
        if result.status == "retry" and attempt < max_retries:
            logger.info(f"Retrying ticket {ticket.id}, attempt {attempt + 1}")
            await asyncio.sleep(calculate_backoff(attempt))
            continue
        
        if result.status in ["failed", "error"]:
            return result
    
    return WorkflowResult(
        status="max_retries_exceeded",
        ticket_id=ticket.id
    )
```

## Monitoring

### Workflow Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| Success Rate | % of successful workflows | > 90% |
| Avg Duration | Mean workflow time | < 15 min |
| Retry Rate | % requiring retry | < 20% |
| Gate Pass Rate | % passing gates on first try | > 80% |

### Workflow Logging

```json
{
  "event": "workflow_complete",
  "ticket_id": "TICKET-001",
  "status": "success",
  "duration_ms": 450000,
  "phases": {
    "intake": {"duration_ms": 100},
    "context_build": {"duration_ms": 5000},
    "code_gen": {"duration_ms": 120000},
    "test_gen": {"duration_ms": 60000},
    "normalization": {"duration_ms": 5000},
    "gate_validation": {"duration_ms": 180000}
  },
  "files_changed": 5,
  "tests_added": 12
}
```
