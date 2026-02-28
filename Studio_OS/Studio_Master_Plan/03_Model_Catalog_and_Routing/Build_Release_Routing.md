---
title: Build Release Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - build
  - release
  - packaging
  - ci
  - cd
  - deployment
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Local_LLM_Coder_Small]]"
  - "[[Local_LLM_Coder_Medium]"
used_by: []
---

# Build Release Routing

## Build and Release Pipeline Routing

Build and release tasks involve packaging, testing, and deploying the game. Routing depends on build type, target platform, and release stage.

### Build Type Classification

| Type | Description | Frequency | Routing |
|------|-------------|-----------|---------|
| Dev Build | Local development | Continuous | Automated |
| CI Build | Continuous integration | Per commit | Automated |
| Test Build | QA testing | Daily | Automated |
| Staging Build | Pre-release | Weekly | Automated + Review |
| Release Build | Production | Per release | Automated + Approval |
| Hotfix Build | Emergency fix | As needed | Automated + Approval |

### Routing Decision Tree

```
Build Request
│
├── Type = Dev Build
│   └── Route: Automated CI
│       └── Trigger on save/commit
│       └── Fast build (incremental)
│       └── Basic validation
│       └── Report results
│
├── Type = CI Build
│   └── Route: Automated CI
│       └── Trigger on PR/commit
│       └── Full build
│       └── Run test suite
│       └── Report results
│
├── Type = Test Build
│   └── Route: Automated CI
│       └── Scheduled daily
│       └── Full build
│       └── Run full test suite
│       └── Generate build artifacts
│       └── Deploy to test environment
│
├── Type = Staging Build
│   └── Route: Automated + Review
│       └── Full optimized build
│       └── Run full test suite
│       └── Performance validation
│       └── Security scan
│       └── Human review required
│       └── Deploy to staging
│
├── Type = Release Build
│   └── Route: Automated + Approval
│       └── Full optimized build
│       └── Run certification tests
│       └── Platform compliance check
│       └── Final security scan
│       └── Human approval required
│       └── Deploy to production
│
└── Type = Hotfix Build
    └── Route: Automated + Approval (expedited)
        └── Minimal change build
        └── Targeted test suite
        └── Risk assessment
        └── Human approval required
        └── Deploy to production
```

### Owner Agent: Build Agent

The Build Agent owns build and release coordination.

**Responsibilities:**
- Classify build type
- Coordinate build pipeline
- Execute build steps
- Run validation gates
- Handle failures
- Coordinate deployment

### Permitted Models by Build Type

| Build Type | Script Gen | Error Analysis | Review |
|------------|------------|----------------|--------|
| Dev | Local Small | Local Small | - |
| CI | Local Small | Local Medium | - |
| Test | Local Small | Local Medium | - |
| Staging | Local Medium | Local Medium | Human |
| Release | Local Medium | Frontier | Human |
| Hotfix | Local Medium | Frontier | Human |

### Context Pack Contents

**Build Script Generation:**
```yaml
context_pack:
  # Build configuration
  build_config: 1  # Build configuration files
  platform_configs: 3  # Platform-specific configs
  
  # Project context
  project_structure: "Project layout"
  dependency_files: 2  # Package manifests
  
  # Previous builds
  build_history: "Recent build logs"
  known_issues: "Known build issues"
  
  total_tokens_budget: 8000
```

**Build Failure Analysis:**
```yaml
context_pack:
  # Error context
  error_logs: "Build error output"
  stack_traces: "Error traces"
  
  # Code context
  changed_files: 10  # Recently changed files
  dependency_changes: "Dependency updates"
  
  # Build context
  build_config: 1  # Build configuration
  environment_info: "Build environment"
  
  total_tokens_budget: 12000
```

### Build Pipeline Stages

```
1. Pre-Build
   a. Clean workspace
   b. Checkout code
   c. Install dependencies
   
2. Build
   a. Compile code
   b. Process assets
   c. Link/Package
   
3. Validation
   a. Run unit tests
   b. Run integration tests
   c. Static analysis
   d. Security scan
   
4. Packaging
   a. Create installer/package
   b. Sign binaries
   c. Generate metadata
   
5. Deployment
   a. Upload to distribution
   b. Update CDN
   c. Notify stakeholders
```

### Gates Required

**Pre-Build Gates:**
1. **Code Freeze**: No changes during build (release only)
2. **Dependency Check**: All dependencies available
3. **Environment Check**: Build environment ready

**Build Gates:**
1. **Compilation**: Zero errors
2. **Warnings**: Logged, reviewed

**Validation Gates:**
1. **Unit Tests**: 100% pass
2. **Integration Tests**: 100% pass
3. **Static Analysis**: No new errors
4. **Security Scan**: No critical issues

**Release Gates:**
1. **Performance**: Within budget
2. **Size**: Within budget
3. **Compliance**: Platform requirements met
4. **Approval**: Human sign-off

### Confidence Thresholds

| Build Type | Min Confidence | Review Required |
|------------|----------------|-----------------|
| Dev | 0.70 | - |
| CI | 0.80 | - |
| Test | 0.85 | - |
| Staging | 0.90 | Human |
| Release | 0.95 | Human mandatory |
| Hotfix | 0.90 | Human mandatory |

### Build Failure Handling

```
Build Failure Detected
│
├── Type = Compilation Error
│   └── Route: Local Medium Analysis
│       └── Analyze error message
│       └── Identify cause
│       └── Propose fix
│       └── Confidence >= 0.80 → Auto-fix
│       └── Confidence < 0.80 → Human
│
├── Type = Test Failure
│   └── Route: See [[Bug_Triage_Routing]]
│
├── Type = Dependency Issue
│   └── Route: Local Medium
│       └── Analyze dependency conflict
│       └── Propose resolution
│
└── Type = Environment Issue
    └── Route: Human
        └── Requires infrastructure access
```

### Cost Estimates

| Build Type | Automation | Analysis | Human | Total |
|------------|------------|----------|-------|-------|
| Dev | $0.01 | $0.001 | - | $0.01 |
| CI | $0.05 | $0.01 | - | $0.06 |
| Test | $0.10 | $0.02 | - | $0.12 |
| Staging | $0.50 | $0.05 | $50 | $50+ |
| Release | $1.00 | $0.10 | $100 | $100+ |
| Hotfix | $0.50 | $0.10 | $200 | $200+ |

*Human time cost

### Best Practices

1. Maintain consistent build environments
2. Version control all build scripts
3. Automate as much as possible
4. Fast feedback for developers
5. Comprehensive testing for releases
6. Document all build steps
7. Have rollback plan ready

### Build Monitoring

```yaml
build_monitoring:
  metrics:
    - build_duration
    - success_rate
    - test_pass_rate
    - artifact_size
    
  alerts:
    - build_duration > threshold
    - success_rate < 0.95
    - test_pass_rate < 1.0
```

### Integration

Uses:
- [[Bug_Triage_Routing]]: For test failures
- [[Code_Implementation_Routing]]: For build script changes
