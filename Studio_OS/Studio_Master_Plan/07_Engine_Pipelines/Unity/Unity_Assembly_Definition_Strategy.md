---
title: Unity Assembly Definition Strategy
type: rule
layer: architecture
status: active
tags:
  - unity
  - assembly-definition
  - asmdef
  - compilation
  - architecture
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Project_Layout_Conventions]"
used_by:
  - "[Unity_PlayMode_Test_Framework]]"
  - "[[Unity_EditMode_Test_Framework]]"
  - "[[Unity_Build_Automation]"
---

# Unity Assembly Definition Strategy

Assembly Definitions (asmdef) control compilation boundaries in Unity. Proper asmdef strategy reduces compile times, enforces architectural boundaries, and enables selective testing. This document defines the mandatory asmdef structure for all Studio OS Unity projects.

## Core Principles

1. **Compile-time isolation** - Changes in one assembly don't recompile others
2. **Dependency direction** - Dependencies flow inward to core
3. **Testability** - Each runtime assembly has a corresponding test assembly
4. **Minimal surface** - Public APIs are intentional and documented

## Assembly Hierarchy

```
                    ┌─────────────────┐
                    │   Tests.*.asmdef │  (Test assemblies)
                    └────────┬────────┘
                             │ references
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  Editor.*.asmdef│    │ Gameplay.asmdef│    │  Services.asmdef│
└───────┬───────┘    └───────┬───────┘    └───────┬───────┘
        │                    │                    │
        │ references         │ references         │ references
        │                    │                    │
        └────────────────────┼────────────────────┘
                             ▼
                    ┌───────────────┐
                    │   Core.asmdef  │
                    └───────────────┘
```

## Required Assembly Definitions

### 1. Core Assembly (`Core.asmdef`)

**Location**: `Assets/_Project/Scripts/Runtime/Core/Core.asmdef`

**Purpose**: Foundation systems with zero external dependencies (except Unity).

**Contents**:
- Event system
- Object pooling
- State machines
- Utilities and extensions
- Math helpers
- Logging abstractions

**Configuration**:
```json
{
    "name": "Core",
    "rootNamespace": "StudioOS.Core",
    "references": [],
    "includePlatforms": [],
    "excludePlatforms": [],
    "allowUnsafeCode": false,
    "overrideReferences": false,
    "precompiledReferences": [],
    "autoReferenced": true,
    "defineConstraints": [],
    "versionDefines": [],
    "noEngineReferences": false
}
```

**Rules**:
- NO references to other project assemblies
- NO gameplay-specific code
- NO Unity Editor APIs
- MUST be 100% unit testable

### 2. Gameplay Assembly (`Gameplay.asmdef`)

**Location**: `Assets/_Project/Scripts/Runtime/Gameplay/Gameplay.asmdef`

**Purpose**: Game-specific logic and systems.

**Contents**:
- Player controllers
- Enemy AI
- Item systems
- World generation
- Game rules

**Configuration**:
```json
{
    "name": "Gameplay",
    "rootNamespace": "StudioOS.Gameplay",
    "references": [
        "Core",
        "Unity.InputSystem"
    ],
    "includePlatforms": [],
    "excludePlatforms": [],
    "allowUnsafeCode": false,
    "overrideReferences": false,
    "precompiledReferences": [],
    "autoReferenced": true,
    "defineConstraints": [],
    "versionDefines": [],
    "noEngineReferences": false
}
```

### 3. UI Assembly (`UI.asmdef`)

**Location**: `Assets/_Project/Scripts/Runtime/UI/UI.asmdef`

**Purpose**: User interface systems.

**Contents**:
- HUD controllers
- Menu systems
- UI components
- Input handling for UI

**References**: `Core`, `Gameplay` (for data binding)

### 4. Services Assembly (`Services.asmdef`)

**Location**: `Assets/_Project/Scripts/Runtime/Services/Services.asmdef`

**Purpose**: External service integrations.

**Contents**:
- Save/load system
- Analytics
- Steam integration
- Cloud services

**References**: `Core`

### 5. Editor Assembly (`Editor.asmdef`)

**Location**: `Assets/_Project/Scripts/Editor/Editor.asmdef`

**Purpose**: Editor-only tools and extensions.

**Configuration**:
```json
{
    "name": "Editor",
    "rootNamespace": "StudioOS.Editor",
    "references": [
        "Core",
        "Gameplay",
        "UI",
        "Services"
    ],
    "includePlatforms": ["Editor"],
    "excludePlatforms": [],
    "allowUnsafeCode": false,
    "overrideReferences": false,
    "precompiledReferences": [],
    "autoReferenced": true,
    "defineConstraints": [],
    "versionDefines": [],
    "noEngineReferences": false
}
```

## Test Assembly Definitions

### Test Assembly Pattern

Every runtime assembly MUST have a corresponding test assembly:

| Runtime Assembly | Test Assembly | Location |
|-----------------|---------------|----------|
| `Core.asmdef` | `Tests.Core.asmdef` | `Assets/_Project/Tests/Runtime/Core/` |
| `Gameplay.asmdef` | `Tests.Gameplay.asmdef` | `Assets/_Project/Tests/Runtime/Gameplay/` |
| `UI.asmdef` | `Tests.UI.asmdef` | `Assets/_Project/Tests/Runtime/UI/` |
| `Services.asmdef` | `Tests.Services.asmdef` | `Assets/_Project/Tests/Runtime/Services/` |

### Test Assembly Configuration

```json
{
    "name": "Tests.Core",
    "rootNamespace": "StudioOS.Tests.Core",
    "references": [
        "Core",
        "UnityEngine.TestRunner",
        "UnityEditor.TestRunner"
    ],
    "includePlatforms": [],
    "excludePlatforms": [],
    "allowUnsafeCode": false,
    "overrideReferences": true,
    "precompiledReferences": [
        "nunit.framework.dll"
    ],
    "autoReferenced": false,
    "defineConstraints": [
        "UNITY_INCLUDE_TESTS"
    ],
    "versionDefines": [],
    "noEngineReferences": false
}
```

## Assembly Definition Rules

### DO
- Create asmdef for every logical module
- Reference only what you need
- Keep Core assembly dependency-free
- Use consistent naming: `[Module].asmdef`
- Add XML documentation for public APIs

### DON'T
- Create circular references
- Reference Editor from Runtime
- Put everything in one assembly
- Reference test assemblies from production code
- Use `autoReferenced: true` in test assemblies

## Dependency Validation

### Automated Checks
CI pipeline validates:
1. No circular dependencies
2. Editor-only code in Editor assemblies
3. Core has zero project references
4. Every runtime assembly has test assembly

### Dependency Graph Generation
```bash
# Generate dependency graph
dotnet tool install --global UnityAsmdefGraph
unity-asmdef-graph --project . --output deps.html
```

## Platform-Specific Assemblies

### Conditional Compilation

```json
{
    "name": "Platform.Steam",
    "references": ["Core", "Services"],
    "defineConstraints": ["STEAMWORKS_ENABLED"]
}
```

### Platform Defines
| Platform | Define |
|----------|--------|
| Steam | `STEAMWORKS_ENABLED` |
| Console | `UNITY_CONSOLE` |
| Mobile | `UNITY_MOBILE` |

## Enforcement

### CI Gates
- Assembly definition validation
- Circular dependency detection
- Missing test assembly detection
- Reference validation

### Editor Tools
- Assembly dependency visualizer
- Auto-generate test assemblies
- Refactoring assistance for asmdef changes

### Failure Modes
| Violation | Severity | Response |
|-----------|----------|----------|
| Missing asmdef | Error | CI block |
| Circular reference | Error | CI block |
| Editor reference in Runtime | Error | CI block |
| Missing test assembly | Warning | CI warning |
