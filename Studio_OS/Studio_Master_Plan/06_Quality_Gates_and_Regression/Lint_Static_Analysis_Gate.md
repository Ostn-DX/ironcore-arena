---
title: Lint Static Analysis Gate
type: gate
layer: enforcement
status: active
tags:
  - lint
  - static-analysis
  - code-quality
  - gate
  - style
  - roslyn
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Build_Gate]"
used_by:
  - "[Release_Certification_Checklist]]"
  - "[[Architecture_Decay_Controls]"
---

# Lint Static Analysis Gate

## Purpose

The Lint Static Analysis Gate enforces code quality standards through automated static analysis. It catches potential bugs, style violations, and architectural issues before code review.

## Tool/Script

**Primary**: `scripts/gates/lint_gate.py`
**C# Analyzer**: Roslyn analyzers + StyleCop
**Unity Specific**: Unity Code Analysis package
**Additional**: SonarQube for deeper analysis

## Local Run

```bash
# Run all lint checks
python scripts/gates/lint_gate.py

# Check specific file
python scripts/gates/lint_gate.py --file Assets/Scripts/Gameplay/Player.cs

# Auto-fix where possible
python scripts/gates/lint_gate.py --fix

# Check specific rules
python scripts/gates/lint_gate.py --rules style,naming

# Quick mode (critical rules only)
python scripts/gates/lint_gate.py --quick

# Via dotnet
dotnet format --verify-no-changes
```

## CI Run

```yaml
# .github/workflows/lint-gate.yml
name: Lint Static Analysis Gate
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint Gate
        run: python scripts/gates/lint_gate.py
      - name: Check Formatting
        run: dotnet format --verify-no-changes
      - name: Upload Sarif
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: reports/lint/results.sarif
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| Critical Issues | 0 | Errors that will cause bugs |
| Compiler Warnings | < 50 | CS#### warnings |
| Style Violations | < 20 | Naming, formatting issues |
| Code Complexity | < 15 | Cyclomatic complexity per method |
| Duplicate Code | < 5% | Code duplication percentage |
| Documentation | > 60% | Public API documentation coverage |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| Critical Issue | >= 1 | HARD FAIL - potential bug |
| Null Reference Risk | >= 1 | HARD FAIL - runtime error risk |
| Memory Leak Risk | >= 1 | HARD FAIL - resource leak risk |
| Security Issue | >= 1 | HARD FAIL - security vulnerability |
| Style Violations | >= 50 | SOFT FAIL - excessive style debt |
| Complexity > 20 | >= 1 | SOFT FAIL - refactor required |

## Rule Categories

| Category | Severity | Examples |
|----------|----------|----------|
| Critical | Error | Null dereference, infinite loop |
| Security | Error | SQL injection, path traversal |
| Reliability | Warning | Unused variables, unreachable code |
| Performance | Warning | Boxing, LINQ in hot path |
| Style | Info | Naming, spacing, braces |
| Documentation | Info | Missing XML docs |

## Critical Rules (Hard Fail)

| Rule ID | Description | Why Critical |
|---------|-------------|--------------|
| CS8600 | Null literal to non-nullable | Runtime null ref |
| CS8602 | Dereference of possibly null | Runtime null ref |
| CS8603 | Possible null return | Contract violation |
| CA2000 | Dispose objects before losing scope | Memory leak |
| CA1065 | Exceptions in unexpected locations | Crash |
| S3011 | Reflection on private fields | Security risk |

## Style Configuration

```xml
<!-- .editorconfig -->
root = true

[*.cs]
# Indentation
indent_style = space
indent_size = 4

# Naming
dotnet_naming_rule.constants_rule.severity = warning
dotnet_naming_rule.constants_rule.symbols = constants
dotnet_naming_rule.constants_rule.style = pascal_case_style

# Formatting
csharp_new_line_before_open_brace = all
csharp_new_line_before_else = true
csharp_indent_case_contents = true

# Quality
dotnet_code_quality.CA1822.api_surface = private, internal
```

## Failure Modes

### Null Reference Risk

**Symptoms**: Analyzer detects possible null dereference
**Example**:
```csharp
// ❌ VIOLATION - possible null ref
string name = GetPlayerName();
int length = name.Length; // Could throw

// ✅ FIXED - null check
string name = GetPlayerName();
int length = name?.Length ?? 0;
```

### Memory Leak Risk

**Symptoms**: IDisposable not properly disposed
**Example**:
```csharp
// ❌ VIOLATION - resource leak
var stream = new FileStream("data.txt", FileMode.Open);
return stream.ReadByte();

// ✅ FIXED - proper disposal
using var stream = new FileStream("data.txt", FileMode.Open);
return stream.ReadByte();
```

### High Complexity

**Symptoms**: Method cyclomatic complexity > 15
**Remediation**: Extract methods, use strategy pattern

## Remediation Steps

### Fix Critical Issues

1. Run lint gate locally
2. Identify critical issues from output
3. Fix each issue with appropriate pattern
4. Re-run gate to verify
5. Commit fixes

### Fix Style Issues

```bash
# Auto-fix style issues where possible
python scripts/gates/lint_gate.py --fix

# Or use dotnet format
dotnet format

# Verify fixes
python scripts/gates/lint_gate.py
```

### Reduce Complexity

1. Identify complex methods from report
2. Extract helper methods
3. Simplify conditionals
4. Consider state machine for complex logic
5. Re-run gate

### Suppress False Positives

```csharp
// Only suppress when you're certain
#pragma warning disable CS8602 // Dereference of possibly null
// Reason: Validated by previous check
var result = definitelyNotNull.Property;
#pragma warning restore CS8602
```

## Custom Analyzers

```csharp
// Assets/Editor/Analyzers/GameSpecificAnalyzer.cs
[DiagnosticAnalyzer(LanguageNames.CSharp)]
public class GameSpecificAnalyzer : DiagnosticAnalyzer
{
    public const string DiagnosticId = "GAME001";
    
    private static readonly DiagnosticDescriptor Rule = new(
        DiagnosticId,
        "Don't use DateTime.Now in game logic",
        "Use GameTime.Now for deterministic time",
        "Correctness",
        DiagnosticSeverity.Error,
        isEnabledByDefault: true);
    
    public override void Initialize(AnalysisContext context)
    {
        context.RegisterSyntaxNodeAction(AnalyzeInvocation, SyntaxKind.InvocationExpression);
    }
    
    private void AnalyzeInvocation(SyntaxNodeAnalysisContext context)
    {
        var invocation = (InvocationExpressionSyntax)context.Node;
        if (invocation.ToString().Contains("DateTime.Now"))
        {
            context.ReportDiagnostic(Diagnostic.Create(Rule, invocation.GetLocation()));
        }
    }
}
```

## Integration with Other Gates

- **Requires**: [[Build_Gate]] must pass
- **Runs before**: [[Unit_Tests_Gate]]
- **Required by**: [[Release_Certification_Checklist]]
- **Feeds**: [[Architecture_Decay_Controls]] (complexity trends)

## IDE Integration

| IDE | Setup |
|-----|-------|
| VS Code | Install C# Dev Kit, .editorconfig respected |
| Visual Studio | Enable full solution analysis |
| Rider | Built-in, respects .editorconfig |

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| False positives on Unity lifecycle | Suppress with pragma | LINT-123 |
| Slow analysis on large files | Incremental analysis | LINT-456 |
| Style conflicts between tools | Standardize on .editorconfig | LINT-789 |
