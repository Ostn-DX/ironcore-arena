---
title: Gate Protocol
type: system
layer: enforcement
status: active
tags:
  - gate
  - validation
  - check
  - quality
  - enforcement
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Patch_Protocol]"
used_by:
  - "[Implementation_Workflow]]"
  - "[[Review_Gate_Workflow]"
---

# Gate Protocol

## Purpose

The Gate Protocol defines automated quality checks that must pass before changes can proceed to the next stage. Gates enforce code quality, test coverage, and system integrity.

## Gate Types

### 1. Build Gate

Ensures code compiles without errors:

```yaml
BuildGate:
  name: "build"
  description: "Verify code compiles"
  
  checks:
    - name: "cargo_build"
      command: "cargo build --release"
      timeout: 300
      
    - name: "cargo_check"
      command: "cargo check --all-targets"
      timeout: 120
      
  failure_modes:
    - error_pattern: "error\[E\d+\]"
      severity: critical
    - error_pattern: "warning:"
      severity: warning
```

### 2. Test Gate

Ensures all tests pass:

```yaml
TestGate:
  name: "test"
  description: "Run test suite"
  
  checks:
    - name: "unit_tests"
      command: "cargo test --lib"
      timeout: 300
      required: true
      
    - name: "integration_tests"
      command: "cargo test --test integration"
      timeout: 600
      required: true
      
    - name: "doc_tests"
      command: "cargo test --doc"
      timeout: 120
      required: false
      
  coverage:
    target: 0.80
    fail_if_below: true
```

### 3. Lint Gate

Ensures code follows style guidelines:

```yaml
LintGate:
  name: "lint"
  description: "Code style and quality checks"
  
  checks:
    - name: "clippy"
      command: "cargo clippy -- -D warnings"
      timeout: 120
      
    - name: "rustfmt"
      command: "cargo fmt -- --check"
      timeout: 60
      
    - name: "dead_code"
      command: "cargo clippy -- -W dead_code"
      timeout: 120
```

### 4. Security Gate

Scans for security issues:

```yaml
SecurityGate:
  name: "security"
  description: "Security vulnerability scan"
  
  checks:
    - name: "cargo_audit"
      command: "cargo audit"
      timeout: 120
      
    - name: "secret_scan"
      command: "detect-secrets scan"
      timeout: 60
      
  severity_threshold: high
```

### 5. Performance Gate

Checks for performance regressions:

```yaml
PerformanceGate:
  name: "performance"
  description: "Performance regression check"
  
  checks:
    - name: "benchmarks"
      command: "cargo bench"
      timeout: 600
      
  thresholds:
    regression_threshold: 0.10  # 10% regression allowed
    fail_if_exceeded: true
```

## Gate Configuration

### Gate Suite

```yaml
GateSuite:
  version: "1.0"
  name: "standard"
  
  gates:
    - name: "build"
      required: true
      parallel: false
      
    - name: "test"
      required: true
      parallel: false
      depends_on: ["build"]
      
    - name: "lint"
      required: true
      parallel: true
      depends_on: ["build"]
      
    - name: "security"
      required: true
      parallel: true
      depends_on: ["build"]
      
    - name: "performance"
      required: false
      parallel: false
      depends_on: ["test"]
```

### Gate Execution Order

```
┌─────────┐
│  Build  │
└────┬────┘
     │
     ▼
┌─────────┐     ┌─────────┐     ┌─────────┐
│  Test   │────▶│  Lint   │     │Security │
└────┬────┘     └─────────┘     └─────────┘
     │
     ▼
┌─────────┐
│Performance│ (optional)
└─────────┘
```

## Gate Execution

### Execution Engine

```python
class GateExecutor:
    async def execute_suite(
        self,
        suite: GateSuite,
        context: ExecutionContext
    ) -> GateResult:
        """Execute a gate suite."""
        
        results = {}
        
        # Build execution graph
        execution_order = self.build_execution_graph(suite.gates)
        
        for gate_group in execution_order:
            # Execute parallel gates
            group_results = await asyncio.gather(*[
                self.execute_gate(gate, context)
                for gate in gate_group
            ])
            
            for gate, result in zip(gate_group, group_results):
                results[gate.name] = result
                
                # Stop on required gate failure
                if gate.required and not result.passed:
                    return GateResult(
                        status="failed",
                        failed_gate=gate.name,
                        results=results
                    )
        
        return GateResult(
            status="passed",
            results=results
        )
    
    async def execute_gate(
        self,
        gate: Gate,
        context: ExecutionContext
    ) -> GateCheckResult:
        """Execute a single gate."""
        
        start_time = time.time()
        
        try:
            # Run gate command
            process = await asyncio.create_subprocess_shell(
                gate.command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                timeout=gate.timeout
            )
            
            stdout, stderr = await process.communicate()
            
            # Parse results
            result = self.parse_gate_output(
                gate,
                stdout.decode(),
                stderr.decode(),
                process.returncode
            )
            
            return GateCheckResult(
                gate_name=gate.name,
                passed=result.passed,
                duration_ms=int((time.time() - start_time) * 1000),
                details=result.details
            )
            
        except asyncio.TimeoutError:
            return GateCheckResult(
                gate_name=gate.name,
                passed=False,
                error=f"Timeout after {gate.timeout}s"
            )
```

### Gate Result Parsing

```python
def parse_test_output(output: str) -> ParsedResult:
    """Parse test command output."""
    
    # Count test results
    passed = len(re.findall(r"test .* \.\.\. ok", output))
    failed = len(re.findall(r"test .* \.\.\. FAILED", output))
    
    # Extract failures
    failures = []
    failure_pattern = r"failures:\n(.*?)(?=\ntest result)"
    matches = re.findall(failure_pattern, output, re.DOTALL)
    for match in matches:
        failures.extend(parse_failures(match))
    
    # Extract coverage
    coverage_match = re.search(r"coverage: ([\d.]+)%", output)
    coverage = float(coverage_match.group(1)) if coverage_match else None
    
    return ParsedResult(
        passed=failed == 0,
        tests_passed=passed,
        tests_failed=failed,
        failures=failures,
        coverage=coverage
    )
```

## Gate Results

### Result Format

```yaml
GateResult:
  suite_name: string
  status: passed|failed|partial
  timestamp: ISO8601
  duration_ms: integer
  
  results:
    - gate_name: string
      passed: boolean
      duration_ms: integer
      
      details:
        tests_passed: integer
        tests_failed: integer
        coverage: float
        warnings: [string]
        errors: [string]
        
  summary:
    total_gates: integer
    passed_gates: integer
    failed_gates: integer
    total_duration_ms: integer
```

### Failure Handling

```python
async def handle_gate_failure(
    result: GateResult,
    patch: Patch
) -> FailureAction:
    """Handle gate failure."""
    
    failed_gate = result.failed_gate
    
    # Determine failure type
    if is_transient_failure(result):
        # Retry
        return FailureAction(
            type="retry",
            delay_ms=5000
        )
    
    elif is_fixable_failure(result):
        # Route to failure fixer
        return FailureAction(
            type="fix",
            fixer="GateFailureFixer",
            context={
                "gate": failed_gate,
                "error": result.results[failed_gate].errors
            }
        )
    
    else:
        # Escalate
        return FailureAction(
            type="escalate",
            reason="Unrecoverable gate failure"
        )
```

## Gate Caching

### Cache Strategy

```python
class GateCache:
    def __init__(self):
        self.cache = {}
    
    def get_cache_key(
        self,
        gate: Gate,
        files: [str]
    ) -> str:
        """Generate cache key for gate execution."""
        file_hashes = [hash_file(f) for f in sorted(files)]
        return hashlib.sha256(
            f"{gate.name}:{':'.join(file_hashes)}".encode()
        ).hexdigest()
    
    async def get_cached_result(
        self,
        gate: Gate,
        files: [str]
    ) -> Optional[GateCheckResult]:
        """Get cached gate result if available."""
        key = self.get_cache_key(gate, files)
        
        if key in self.cache:
            cached = self.cache[key]
            if cached.timestamp > get_file_mtime(files):
                return cached.result
        
        return None
```

## Integration with Other Systems

### Patch Protocol
Gates validate [[Patch_Protocol|patches]]:

```python
async def validate_patch_with_gates(patch: Patch) -> GateResult:
    """Validate patch through gate suite."""
    return await gate_executor.execute_suite(
        suite=load_gate_suite("standard"),
        context=PatchContext(patch)
    )
```

### Review Workflow
Gate results feed into [[Review_Gate_Workflow|review]]:

```python
async def submit_for_review_with_gates(patch: Patch):
    """Submit patch with gate results for review."""
    gate_result = await validate_patch_with_gates(patch)
    
    await review_queue.submit(
        patch=patch,
        gate_result=gate_result
    )
```

### Failure Fixer
Gate failures trigger [[Prompt_Gate_Failure_Fixer|failure fixer]]:

```python
async def route_to_failure_fixer(gate_result: GateResult):
    """Route gate failure to appropriate fixer."""
    fixer = GateFailureFixer()
    
    return await fixer.fix(
        gate=gate_result.failed_gate,
        errors=gate_result.errors
    )
```
