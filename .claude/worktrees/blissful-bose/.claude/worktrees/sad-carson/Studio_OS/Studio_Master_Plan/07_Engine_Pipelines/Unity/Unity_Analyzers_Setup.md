---
title: Unity Analyzers Setup
type: system
layer: enforcement
status: active
tags:
  - unity
  - analyzers
  - roslyn
  - static-analysis
  - code-quality
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_CSharp_Style_Guide]"
used_by:
  - "[Unity_CI_Template]]"
  - "[[Unity_Build_Automation]"
---

# Unity Analyzers Setup

Roslyn analyzers provide static code analysis to catch potential issues at compile time. This document defines the mandatory analyzer configuration for Studio OS Unity projects, including Unity-specific analyzers and custom rules.

## Analyzer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ANALYZER ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Source Code → Roslyn Compiler → Analyzers → Diagnostics    │
│       │                              │            │         │
│       │                              ▼            ▼         │
│       │                      ┌──────────┐   ┌──────────┐   │
│       │                      │ Built-in │   │  Custom  │   │
│       │                      │ Analyzers│   │ Analyzers│   │
│       │                      └──────────┘   └──────────┘   │
│       │                              │            │         │
│       └──────────────────────────────┴────────────┘         │
│                                        │                    │
│                                        ▼                    │
│                              ┌──────────────────┐          │
│                              │  .editorconfig   │          │
│                              │  Rule severity   │          │
│                              └──────────────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Required Analyzers

### Package Installation

```json
// Packages/manifest.json
{
  "dependencies": {
    "com.unity.entities": "1.0.0"
  },
  "testables": [
    "com.unity.entities"
  ]
}
```

### NuGet Analyzers

Create `Assets/csc.rsp`:

```
-r:Packages/com.unity.entities/Unity.Entities.Analyzer.dll
```

### Required Analyzer Packages

| Analyzer | Purpose | Severity |
|----------|---------|----------|
| Unity.Entities.Analyzer | DOTS best practices | Error |
| Microsoft.CodeAnalysis.NetAnalyzers | .NET best practices | Warning |
| Microsoft.CodeQuality.Analyzers | Code quality | Warning |
| StyleCop.Analyzers | Style enforcement | Info |

## EditorConfig Configuration

```ini
# .editorconfig in project root
root = true

# All files
[*]
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

# C# files
[*.cs]
indent_style = space
indent_size = 4
max_line_length = 120

# Analyzer rules
dotnet_diagnostic.IDE0001.severity = warning  # Simplify name
dotnet_diagnostic.IDE0002.severity = warning  # Simplify member access
dotnet_diagnostic.IDE0005.severity = warning  # Remove unnecessary usings
dotnet_diagnostic.IDE0011.severity = warning  # Add braces
dotnet_diagnostic.IDE0040.severity = warning  # Add accessibility modifiers
dotnet_diagnostic.IDE0051.severity = warning  # Remove unused private members
dotnet_diagnostic.IDE0052.severity = warning  # Remove unread private members
dotnet_diagnostic.IDE0055.severity = warning  # Fix formatting
dotnet_diagnostic.IDE0060.severity = suggestion  # Remove unused parameter
dotnet_diagnostic.IDE1006.severity = warning  # Naming styles

# Unity specific
dotnet_diagnostic.UNT0001.severity = error    # Empty Unity message
dotnet_diagnostic.UNT0002.severity = error    # Inefficient tag comparison
dotnet_diagnostic.UNT0003.severity = warning  # Unused Unity message
dotnet_diagnostic.UNT0004.severity = error    # Inefficient camera main
dotnet_diagnostic.UNT0005.severity = warning  # Suspicious null check
dotnet_diagnostic.UNT0006.severity = error    # Incorrect message signature
dotnet_diagnostic.UNT0007.severity = warning  # Unity object null check
dotnet_diagnostic.UNT0008.severity = error    # Null propagation on Unity object
dotnet_diagnostic.UNT0009.severity = warning  # Class with only static members
dotnet_diagnostic.UNT0010.severity = warning  # MonoBehaviour with constructor
dotnet_diagnostic.UNT0011.severity = error    # ScriptableObject with constructor
dotnet_diagnostic.UNT0012.severity = warning  # Unused coroutine return value
dotnet_diagnostic.UNT0013.severity = error    # Invalid SerializeField
dotnet_diagnostic.UNT0014.severity = warning  # Invalid UnityNull check
dotnet_diagnostic.UNT0015.severity = error    # Object.Instantiate with incorrect parent

# Performance
dotnet_diagnostic.CA1806.severity = warning   # Do not ignore method results
dotnet_diagnostic.CA1822.severity = suggestion # Mark members as static
dotnet_diagnostic.CA1825.severity = warning   # Avoid zero-length array allocations
dotnet_diagnostic.CA1836.severity = warning   # Prefer IsEmpty over Count
dotnet_diagnostic.CA1847.severity = warning   # Use string.Char for single char lookup

# Reliability
dotnet_diagnostic.CA2000.severity = error     # Dispose objects before losing scope
dotnet_diagnostic.CA2007.severity = none      # Do not directly await a Task

# Security
dotnet_diagnostic.CA2100.severity = error     # Review SQL queries for security
dotnet_diagnostic.CA5364.severity = warning   # Do not use deprecated security protocols
```

## Custom Analyzers

### Creating Custom Analyzers

```csharp
// Assets/Editor/Analyzers/StudioOSAnalyzers.cs
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Diagnostics;
using System.Collections.Immutable;

namespace StudioOS.Analyzers
{
    [DiagnosticAnalyzer(LanguageNames.CSharp)]
    public class FindObjectOfTypeAnalyzer : DiagnosticAnalyzer
    {
        public const string DiagnosticId = "STUDIOOS001";
        
        private static readonly DiagnosticDescriptor Rule = new(
            DiagnosticId,
            "Avoid FindObjectOfType in Update",
            "FindObjectOfType is expensive and should not be called in Update. Cache the reference in Awake or Start.",
            "Performance",
            DiagnosticSeverity.Warning,
            isEnabledByDefault: true);

        public override ImmutableArray<DiagnosticDescriptor> SupportedDiagnostics 
            => ImmutableArray.Create(Rule);

        public override void Initialize(AnalysisContext context)
        {
            context.ConfigureGeneratedCodeAnalysis(GeneratedCodeAnalysisFlags.None);
            context.EnableConcurrentExecution();
            context.RegisterSyntaxNodeAction(AnalyzeNode, SyntaxKind.InvocationExpression);
        }

        private void AnalyzeNode(SyntaxNodeAnalysisContext context)
        {
            var invocation = (InvocationExpressionSyntax)context.Node;
            var methodName = invocation.Expression.ToString();
            
            if (methodName.Contains("FindObjectOfType"))
            {
                // Check if inside Update method
                var method = invocation.Ancestors().OfType<MethodDeclarationSyntax>().FirstOrDefault();
                if (method?.Identifier.Text == "Update")
                {
                    var diagnostic = Diagnostic.Create(Rule, invocation.GetLocation());
                    context.ReportDiagnostic(diagnostic);
                }
            }
        }
    }
}
```

### Custom Analyzer Rules

| Rule ID | Description | Severity |
|---------|-------------|----------|
| STUDIOOS001 | No FindObjectOfType in Update | Warning |
| STUDIOOS002 | No GetComponent in Update | Warning |
| STUDIOOS003 | Require XML documentation on public APIs | Warning |
| STUDIOOS004 | Use Addressables instead of Resources | Error |
| STUDIOOS005 | No Unity null check with == | Error |

## Suppression

### When to Suppress

```csharp
// Suppress with justification
#pragma warning disable UNT0002 // Inefficient tag comparison
// Justification: Using custom tag system
if (gameObject.CompareTag("CustomTag"))
#pragma warning restore UNT0002
```

### Global Suppression

```csharp
// GlobalSuppressions.cs
using System.Diagnostics.CodeAnalysis;

[assembly: SuppressMessage(
    "Performance",
    "CA1822:Mark members as static",
    Justification = "Unity requires instance methods for MonoBehaviour",
    Scope = "namespaceanddescendants",
    Target = "StudioOS")]
```

## CI Integration

### Build with Analyzers

```bash
# Run analyzers as part of build
dotnet build -p:TreatWarningsAsErrors=true
```

### Analyzer Report Generation

```yaml
# GitHub Actions
- name: Run Analyzers
  run: |
    dotnet build --verbosity normal 2>&1 | tee analyzer-output.log
    
- name: Upload Analyzer Results
  uses: actions/upload-artifact@v3
  with:
    name: analyzer-results
    path: analyzer-output.log
```

## IDE Integration

### Visual Studio
- Install .NET Compiler Platform SDK
- Enable full solution analysis

### VS Code
```json
// .vscode/settings.json
{
  "omnisharp.enableRoslynAnalyzers": true,
  "omnisharp.enableEditorConfigSupport": true
}
```

### Rider
- Enable Roslyn analyzers in settings
- Configure inspection severity

## Enforcement

### CI Gates
- No analyzer errors
- Maximum 10 warnings per PR
- All custom rules pass

### Pre-Commit
- Run analyzers on changed files
- Block commit on errors

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Analyzer error | Error | Block build |
| Warning threshold exceeded | Warning | Review required |
| New analyzer rule violation | Info | Suggest fix |
