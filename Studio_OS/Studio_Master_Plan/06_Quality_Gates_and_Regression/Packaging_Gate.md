---
title: Packaging Gate
type: gate
layer: enforcement
status: active
tags:
  - packaging
  - steam
  - build
  - gate
  - distribution
  - release
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Build_Gate]]"
  - "[[Content_Validation_Gate]"
used_by:
  - "[Release_Certification_Checklist]"
---

# Packaging Gate

## Purpose

The Packaging Gate validates that the game build is correctly packaged for distribution on Steam and other platforms. It ensures all required files are present, configurations are correct, and the package meets platform requirements.

## Tool/Script

**Primary**: `scripts/gates/packaging_gate.py`
**Steam SDK**: `steamcmd` for Steam-specific validation
**Package Builder**: `Assets/Editor/BuildPipeline/PackageBuilder.cs`
**Manifest Validator**: `scripts/tools/validate_manifest.py`

## Local Run

```bash
# Validate local build package
python scripts/gates/packaging_gate.py --build-path Build/Windows

# Full packaging validation
python scripts/gates/packaging_gate.py --full

# Steam-specific validation
python scripts/gates/packaging_gate.py --platform steam

# Validate specific depot
python scripts/gates/packaging_gate.py --depot 123456

# Generate package manifest
python scripts/gates/packaging_gate.py --generate-manifest
```

## CI Run

```yaml
# .github/workflows/packaging-gate.yml
name: Packaging Gate
on:
  push:
    tags:
      - 'v*'
jobs:
  packaging:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: python scripts/gates/build_gate.py --platform all
      - name: Packaging Gate
        run: python scripts/gates/packaging_gate.py --full
      - name: Upload Package
        uses: actions/upload-artifact@v3
        with:
          name: game-package
          path: Build/Package/
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| Executable Present | Yes | Game executable exists |
| Required DLLs | 100% | All dependencies present |
| Steam API | Valid | steam_api64.dll valid |
| Manifest Complete | 100% | All files in manifest |
| Size Limits | Within budget | Per-platform size limits |
| Icon Resources | All sizes | 16x16 to 256x256 icons |
| EULA Present | Yes | License file included |
| Version Info | Correct | Assembly version matches |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| Missing Executable | N/A | HARD FAIL - unplayable |
| Missing DLL | >= 1 | HARD FAIL - crash on launch |
| Steam API Invalid | N/A | HARD FAIL - Steam integration broken |
| Manifest Mismatch | >= 1 | HARD FAIL - packaging error |
| Size Exceeded | N/A | SOFT FAIL - may affect distribution |
| Missing Icon | >= 1 | SOFT FAIL - UX issue |

## Steam Package Requirements

| Requirement | Description | Validation |
|-------------|-------------|------------|
| steam_appid.txt | App ID file | Present with correct ID |
| steam_api64.dll | Steam API library | Valid signature |
| Executable | Game .exe | Named correctly, signed |
| Redistributables | VC++ runtime | Included or installer |
| Steam Input | Action manifests | If using Steam Input |
| Cloud Saves | Auto-cloud config | If using cloud saves |
| Achievements | Schema match | Achievement count matches |

## Package Structure

```
Build/Package/StandaloneWindows64/
├── GameName.exe              # Main executable
├── GameName_Data/            # Unity data folder
│   ├── Managed/              # .NET assemblies
│   ├── Plugins/              # Native plugins
│   ├── Resources/            # Unity resources
│   └── StreamingAssets/      # Raw asset files
├── steam_api64.dll           # Steam API
├── steam_appid.txt           # Steam App ID
├── Redist/                   # Redistributables
│   ├── vc_redist.x64.exe
│   └── DirectX/
└── __Installer/              # Optional installer
```

## Failure Modes

### Missing Executable

**Symptoms**: Game.exe not found in package
**Root Causes**:
- Build failed silently
- Wrong build path
- Build output moved

### Missing Dependencies

**Symptoms**: DLL files missing from package
**Root Causes**:
- Plugin not copied
- Dependency not in build output
- Platform-specific DLL missing

### Steam API Issues

**Symptoms**: Steam integration not working
**Root Causes**:
- Wrong steam_api64.dll version
- steam_appid.txt missing or wrong
- Steam not initialized properly

## Remediation Steps

### Fix Missing Executable

1. Verify build completed successfully
2. Check build output path
3. Ensure BuildTarget is correct
4. Re-run build and packaging

### Fix Missing Dependencies

1. Identify missing DLL from error log
2. Check Plugin Inspector settings in Unity
3. Ensure "Select platforms for plugin" is correct
4. Re-build and verify DLL is copied

### Fix Steam API Issues

1. Verify steam_appid.txt contains correct App ID
2. Check steam_api64.dll version matches SDK
3. Ensure Steam is running during testing
4. Verify SteamManager initialization

### Generate Correct Manifest

```python
# scripts/tools/generate_manifest.py
manifest = {
    "version": "1.0.0",
    "files": [
        {"path": "GameName.exe", "size": 12345678, "hash": "abc123..."},
        {"path": "steam_api64.dll", "size": 234567, "hash": "def456..."},
        # ... all files
    ],
    "depots": {
        "windows": {"files": [...], "size": 1234567890},
        "linux": {"files": [...], "size": 1234567890},
        "macos": {"files": [...], "size": 1234567890}
    }
}
```

## Platform-Specific Packaging

| Platform | Special Requirements |
|----------|---------------------|
| Steam (Windows) | steam_api64.dll, steam_appid.txt |
| Steam (Linux) | steam_api.so, executable permissions |
| Steam (macOS) | .app bundle structure, signed |
| Epic | Epic Online Services SDK |
| GOG | Galaxy SDK integration |
| Xbox | GDK packaging, certification |
| PlayStation | SDK packaging, certification |
| Switch | SDK packaging, certification |

## Packaging Script Reference

```python
# scripts/gates/packaging_gate.py
class PackagingGate:
    """Validates game package for distribution."""
    
    REQUIRED_FILES = [
        "GameName.exe",
        "GameName_Data/Managed/Assembly-CSharp.dll",
        "steam_api64.dll",
        "steam_appid.txt"
    ]
    
    PLATFORM_SIZE_LIMITS = {
        "windows": 2 * 1024 * 1024 * 1024,  # 2GB
        "linux": 2 * 1024 * 1024 * 1024,
        "macos": 2 * 1024 * 1024 * 1024
    }
    
    def validate_package(self, package_path: Path) -> ValidationResult:
        """Validate complete package structure."""
        errors = []
        
        # Check required files
        for file in self.REQUIRED_FILES:
            if not (package_path / file).exists():
                errors.append(f"Missing required file: {file}")
        
        # Check size limits
        total_size = sum(f.stat().st_size for f in package_path.rglob('*') if f.is_file())
        if total_size > self.PLATFORM_SIZE_LIMITS["windows"]:
            errors.append(f"Package size {total_size} exceeds limit")
        
        # Validate Steam integration
        steam_result = self.validate_steam_integration(package_path)
        errors.extend(steam_result.errors)
        
        return ValidationResult(len(errors) == 0, errors)
```

## Integration with Other Gates

- **Requires**: [[Build_Gate]], [[Content_Validation_Gate]]
- **Final gate before**: [[Release_Certification_Checklist]]
- **Produces**: Package for Steam upload
- **Validates**: Steam depot configuration

## Steam Upload Integration

```bash
# Upload to Steam (after packaging gate passes)
steamcmd +login $STEAM_USERNAME $STEAM_PASSWORD \
  +app_update $APP_ID validate \
  +run_app_build $BUILD_SCRIPT \
  +quit
```

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| Steam API version mismatch | Use Steam SDK matching partner site | PKG-123 |
| macOS signing complex | Use CI with signing certificates | PKG-456 |
| Console packaging requires SDK | Manual packaging on dev kit | PKG-789 |
