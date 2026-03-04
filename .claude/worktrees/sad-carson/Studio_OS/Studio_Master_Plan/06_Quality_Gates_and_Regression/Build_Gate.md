---
title: Build Gate
type: gate
layer: enforcement
status: active
tags:
  - build
  - compilation
  - gate
  - ci-cd
  - unity
  - enforcement
depends_on:
  - "[Quality_Gates_Overview]"
used_by:
  - "[Unit_Tests_Gate]]"
  - "[[Packaging_Gate]]"
  - "[[Release_Certification_Checklist]"
---

# Build Gate

## Purpose

The Build Gate ensures that the project compiles successfully across all target platforms. A build failure blocks all downstream gates and prevents broken code from entering the main branch.

## Tool/Script

**Primary**: `scripts/gates/build_gate.py`
**Unity Integration**: `Assets/Editor/BuildGate.cs`

## Local Run

```bash
# Quick local build check (current platform only)
python scripts/gates/build_gate.py --platform local --config Development

# Full platform build (mimics CI)
python scripts/gates/build_gate.py --platform all --config Release

# Specific platform
python scripts/gates/build_gate.py --platform StandaloneWindows64 --config Release
```

## CI Run

```yaml
# .github/workflows/build-gate.yml
name: Build Gate
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Gate
        run: python scripts/gates/build_gate.py --platform all --config Release
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| Compilation | 0 errors | Unity console error count |
| Warnings | < 50 | Unity console warning count |
| Build Output | Exists | Build artifact file exists |
| Build Size | < 2GB | Final build size |
| Build Time | < 10 min | Wall clock build duration |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| Compilation Errors | >= 1 | HARD FAIL - immediate block |
| Critical Warnings | >= 1 | HARD FAIL - e.g., missing script refs |
| Build Output Missing | N/A | HARD FAIL - build system error |
| Build Size | >= 2GB | SOFT FAIL - requires approval |
| Build Time | >= 10 min | SOFT FAIL - performance regression |

## Platform Matrix

| Platform | Required | Configs | Max Size |
|----------|----------|---------|----------|
| StandaloneWindows64 | Yes | Release, Development | 2GB |
| StandaloneLinux64 | Yes | Release, Development | 2GB |
| StandaloneOSX | Yes | Release, Development | 2GB |
| WebGL | Optional | Release | 500MB |

## Failure Modes

### Compilation Error

**Symptoms**: Unity reports CS#### errors in console
**Immediate Action**: Build gate fails, PR blocked

### Missing Script Reference

**Symptoms**: Warnings about missing MonoBehaviour scripts
**Immediate Action**: Build gate fails, assets must be fixed

### Build Size Exceeded

**Symptoms**: Build artifact exceeds 2GB threshold
**Immediate Action**: SOFT FAIL - requires Tech Lead approval

## Remediation Steps

### Fix Compilation Errors

1. Open Unity Editor
2. Check Console for CS#### errors
3. Fix all errors in order (top to bottom)
4. Re-run local build gate: `python scripts/gates/build_gate.py`
5. Verify zero errors before pushing

### Fix Missing Script References

1. In Unity, search for "Missing" in Hierarchy
2. Identify prefabs/scenes with missing scripts
3. Re-assign correct scripts or remove broken references
4. Save all modified assets
5. Re-run build gate

### Reduce Build Size

1. Analyze build size: `python scripts/tools/analyze_build_size.py`
2. Identify largest contributors:
   - Unused assets in Resources folder
   - Uncompressed textures/audio
   - Duplicate assets
3. Move unused assets out of Resources
4. Compress textures (ASTC/ETC2 for mobile, DXT for desktop)
5. Re-run build gate

### Build Time Regression

1. Check incremental build status
2. Verify Library folder is cached in CI
3. Review recent changes to Editor scripts
4. Profile build process: `python scripts/tools/profile_build.py`

## Build Gate Script Reference

```python
# scripts/gates/build_gate.py
class BuildGate:
    """
    Enforces compilation success across all target platforms.
    """
    
    PLATFORMS = ['StandaloneWindows64', 'StandaloneLinux64', 'StandaloneOSX']
    MAX_WARNINGS = 50
    MAX_BUILD_SIZE_MB = 2048
    MAX_BUILD_TIME_SECONDS = 600
    
    def run(self, platform: str, config: str) -> GateResult:
        """
        Execute build for specified platform and configuration.
        
        Returns:
            GateResult with status, errors, warnings, metrics
        """
        pass
    
    def validate_artifacts(self, build_path: str) -> bool:
        """
        Verify build artifacts exist and meet size requirements.
        """
        pass
```

## Integration with Other Gates

- **Blocks**: [[Unit_Tests_Gate]], [[Determinism_Replay_Gate]], all downstream gates
- **Required by**: [[Release_Certification_Checklist]] - no release without successful build
- **Metrics feed**: [[Regression_Harness_Spec]] - build time trends

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| Unity License timeout on CI | Use floating license server | OPS-1234 |
| macOS build requires Xcode | Use GitHub Actions macOS runner | N/A |
| Incremental build sometimes fails | Clean build on failure, retry | UNITY-567 |
