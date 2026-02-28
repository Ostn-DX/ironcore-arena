---
title: Versioning Changelog Rules
type: rule
layer: enforcement
status: active
tags:
  - versioning
  - changelog
  - semver
  - release
  - documentation
  - git
depends_on:
  - "[Quality_Gates_Overview]"
used_by:
  - "[Release_Certification_Checklist]"
---

# Versioning Changelog Rules

## Version Numbering (Semantic Versioning)

We follow [Semantic Versioning 2.0.0](https://semver.org/):

```
VERSION = MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]

Example: 1.2.3-beta.2+build.456
```

| Component | When to Increment | Example |
|-----------|-------------------|---------|
| MAJOR | Breaking changes, save incompatibility | 1.x.x → 2.0.0 |
| MINOR | New features, backward compatible | x.2.x → x.3.0 |
| PATCH | Bug fixes, backward compatible | x.x.2 → x.x.3 |
| PRERELEASE | Pre-release versions | -alpha, -beta, -rc |
| BUILD | Build metadata | +build.123 |

## Version Increment Rules

### MAJOR Version (X.0.0)

Increment when:
- [ ] Save game format changes (incompatible)
- [ ] Network protocol changes (incompatible)
- [ ] Public API changes (for modding)
- [ ] Significant architectural changes
- [ ] Content reset required

### MINOR Version (x.X.0)

Increment when:
- [ ] New features added
- [ ] New content added (levels, items, etc.)
- [ ] UI/UX improvements
- [ ] Performance improvements
- [ ] New platforms supported

### PATCH Version (x.x.X)

Increment when:
- [ ] Bug fixes
- [ ] Balance adjustments
- [ ] Text/localization fixes
- [ ] Crash fixes
- [ ] Minor optimizations

### Prerelease Tags

| Tag | Meaning | Use Case |
|-----|---------|----------|
| -alpha | Internal testing | Not feature complete |
| -beta | External testing | Feature complete, testing |
| -rc | Release candidate | Ready for release pending final QA |

## Version in Code

### Unity Project Settings

```csharp
// Assets/Scripts/Core/VersionInfo.cs
public static class VersionInfo
{
    public const string VERSION = "1.2.3";
    public const string BUILD_NUMBER = "456";
    public const string FULL_VERSION = "1.2.3+build.456";
    
    public static bool IsPrerelease => VERSION.Contains("-");
    public static bool IsDevelopment => Application.isEditor;
}
```

### Assembly Info

```csharp
// Properties/AssemblyInfo.cs
[assembly: AssemblyVersion("1.2.3.0")]
[assembly: AssemblyFileVersion("1.2.3.456")]
[assembly: AssemblyInformationalVersion("1.2.3-beta.2+build.456")]
```

## Changelog Format

We follow [Keep a Changelog](https://keepachangelog.com/):

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature X
- New level Y

### Changed
- Improved performance of Z

### Fixed
- Bug where players could...

## [1.2.3] - 2024-01-15

### Added
- New weapon: Plasma Rifle
- Steam achievements

### Changed
- Reduced loading time by 30%
- Rebalanced enemy health

### Fixed
- Crash when opening inventory
- Multiplayer desync issue

### Deprecated
- Old save format (will be removed in 2.0)

### Removed
- Legacy multiplayer mode

### Security
- Fixed potential exploit in...

## [1.2.2] - 2024-01-01

### Fixed
- Memory leak in particle system
```

## Changelog Categories

| Category | Description | Example |
|----------|-------------|---------|
| Added | New features | New weapon, level, mode |
| Changed | Changes to existing | Balance, performance |
| Deprecated | Soon-to-be removed | Old API, feature |
| Removed | Removed features | Legacy systems |
| Fixed | Bug fixes | Crash, exploit fix |
| Security | Security fixes | Vulnerability patch |

## Release Notes Template

```markdown
# Release Notes - Version X.Y.Z

**Release Date**: YYYY-MM-DD

## Highlights
[Bullet points of major changes]

## New Features
- Feature 1: Description
- Feature 2: Description

## Improvements
- Improvement 1: Description

## Bug Fixes
- Fixed: Issue description

## Known Issues
- Issue 1: Workaround if available

## Compatibility
- Save games from X.Y.Z are compatible
- Multiplayer requires all players on X.Y.Z

## Download
- Steam: Auto-updates
- Standalone: [Download link]
```

## Git Tagging

```bash
# Tag a release
git tag -a v1.2.3 -m "Release version 1.2.3"

# Push tag
git push origin v1.2.3

# List tags
git tag -l

# Delete tag (if needed)
git tag -d v1.2.3
git push origin --delete v1.2.3
```

## CI/CD Integration

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*'
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Extract Version
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
      
      - name: Build
        run: python scripts/gates/build_gate.py --version ${{ steps.version.outputs.VERSION }}
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          body_path: CHANGELOG.md
          files: Build/Package/*
```

## Version Validation

```python
# scripts/tools/validate_version.py
import re

def validate_version(version: str) -> bool:
    """Validate version follows semver."""
    pattern = r'^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)' \
              r'(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)' \
              r'(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?' \
              r'(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
    return re.match(pattern, version) is not None

def validate_changelog(version: str) -> bool:
    """Validate changelog has entry for version."""
    with open('CHANGELOG.md') as f:
        content = f.read()
    return f'## [{version}]' in content
```

## Integration with Other Gates

- **Required by**: [[Release_Certification_Checklist]]
- **Validated by**: Content validation gate
- **Used by**: CI/CD for release naming
