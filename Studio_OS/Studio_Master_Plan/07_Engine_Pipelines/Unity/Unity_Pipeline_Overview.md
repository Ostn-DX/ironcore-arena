---
title: Unity Pipeline Overview
type: pipeline
layer: architecture
status: active
tags:
  - unity
  - pipeline
  - architecture
  - overview
  - csharp
depends_on: []
used_by:
  - "[Unity_Project_Layout_Conventions]]"
  - "[[Unity_Assembly_Definition_Strategy]]"
  - "[[Unity_Build_Automation]]"
  - "[[Unity_CI_Template]"
---

# Unity Pipeline Overview

The Unity Pipeline defines the end-to-end workflow for AI-Native Game Studio OS projects using Unity with C#. This pipeline orchestrates code organization, testing, asset management, build automation, and deployment while maintaining deterministic behavior where possible and managing rollback when determinism fails.

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    UNITY PIPELINE ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 1: PROJECT STRUCTURE                                      │
│  ├── [[Unity_Project_Layout_Conventions]]                        │
│  └── [[Unity_Assembly_Definition_Strategy]]                      │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2: CODE QUALITY & TESTING                                 │
│  ├── [[Unity_CSharp_Style_Guide]]                                │
│  ├── [[Unity_Analyzers_Setup]]                                   │
│  ├── [[Unity_PlayMode_Test_Framework]]                           │
│  └── [[Unity_EditMode_Test_Framework]]                           │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 3: ASSET MANAGEMENT                                       │
│  ├── [[Unity_Asset_Import_Pipeline]]                             │
│  └── [[Unity_Addressables_Strategy]]                             │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 4: BUILD & DEPLOYMENT                                     │
│  ├── [[Unity_Build_Automation]]                                  │
│  ├── [[Unity_Export_Pipeline]]                                   │
│  ├── [[Unity_Steam_Build_Packaging]]                             │
│  └── [[Unity_CI_Template]]                                       │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 5: PERFORMANCE & DETERMINISM                              │
│  ├── [[Unity_Determinism_Strategy]]                              │
│  ├── [[Unity_Rollback_Strategy]]                                 │
│  └── [[Unity_Profiling_Perf_Gates]]                              │
└─────────────────────────────────────────────────────────────────┘
```

## Pipeline Gates

### Pre-Commit Gates
- Code style validation via analyzers
- EditMode test execution
- Static analysis pass

### CI Gates
- Full PlayMode test suite
- Build verification for all targets
- Performance baseline comparison
- Asset bundle validation

### Release Gates
- Determinism verification (where applicable)
- Performance profiling against thresholds
- Steam build packaging validation
- Final export pipeline execution

## Unity Version Policy

**Primary Version**: Unity 2022.3 LTS (Long Term Support)
- Stable API surface
- Extended support timeline
- Verified package compatibility

**Upgrade Policy**:
1. New LTS versions evaluated quarterly
2. Upgrade window: 30 days post-evaluation
3. Rollback plan required before upgrade
4. Full test suite execution mandatory

## Platform Targets

| Platform | Priority | Build Target | Notes |
|----------|----------|--------------|-------|
| Windows | P0 | StandaloneWindows64 | Primary development target |
| macOS | P1 | StandaloneOSX | Apple Silicon + Intel |
| Linux | P2 | StandaloneLinux64 | Steam Deck compatible |
| WebGL | P2 | WebGL | Demo/Prototype builds |

## Integration Points

### Studio OS Integration
- [[../Godot/Godot_Pipeline_Overview|Godot Pipeline]] - Alternative engine comparison
- [[../../04_CI_CD/CI_CD_Master_Pipeline|CI/CD Master Pipeline]] - Build orchestration
- [[../../05_Testing_Strategy/Test_Automation_Framework|Test Automation]] - Cross-engine testing

### External Integrations
- Steamworks SDK for distribution
- Git LFS for large asset storage
- Addressables for runtime asset loading

## Pipeline Metrics

Track these metrics for pipeline health:
- Build duration (target: <15 min for CI)
- Test execution time (target: <10 min)
- Asset import time (target: <5 min fresh import)
- Build size (tracked per platform)
- Determinism drift (measured via checksums)

## Failure Modes

| Failure | Detection | Response |
|---------|-----------|----------|
| Build failure | CI build step | Alert + block merge |
| Test failure | Test runner | Alert + block merge |
| Performance regression | Perf gates | Warning + review required |
| Determinism failure | Checksum mismatch | Alert + rollback trigger |
| Asset import error | Import pipeline | Alert + manual review |

## Enforcement

Pipeline enforcement is implemented through:
1. Pre-commit hooks for local validation
2. CI pipeline gates for merge blocking
3. Release checklist for deployment approval
4. Automated rollback on critical failures
