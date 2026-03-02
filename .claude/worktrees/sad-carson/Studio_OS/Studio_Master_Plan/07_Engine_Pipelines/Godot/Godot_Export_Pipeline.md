---
title: Godot Export Pipeline
type: pipeline
layer: execution
status: active
tags:
  - godot
  - export
  - build
  - release
  - deployment
  - automation
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Asset_Import_Pipeline]"
used_by:
  - "[Godot_Steam_Build_Packaging]]"
  - "[[Godot_CI_Template]"
---

# Godot Export Pipeline

The export pipeline transforms Godot projects into platform-specific distributables. This specification defines export configurations, build automation, and release workflows for Windows, macOS, Linux, Web, and mobile platforms.

## Export Presets Configuration

### export_presets.cfg Structure
```ini
[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
 runnable=true
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="builds/release/windows/game.exe"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]
custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/embed_pck=false
texture_format/s3tc=true
texture_format/etc2=false
```

### Platform Presets

#### Windows Desktop
```ini
[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
export_path="builds/release/windows/Game.exe"

[preset.0.options]
binary_format/embed_pck=false
texture_format/s3tc=true
 codesign/enable=false
```

#### macOS
```ini
[preset.1]
name="macOS"
platform="macOS"
export_path="builds/release/macos/Game.zip"

[preset.1.options]
binary_format/app_bundle=true
application/icon="res://assets/icons/mac_icon.icns"
application/bundle_identifier="com.studio.gamename"
application/signature=""
application/short_version="1.0.0"
application/version="1.0.0"
```

#### Linux
```ini
[preset.2]
name="Linux/X11"
platform="Linux/X11"
export_path="builds/release/linux/game.x86_64"

[preset.2.options]
binary_format/embed_pck=false
texture_format/s3tc=true
texture_format/etc2=false
```

#### Web
```ini
[preset.3]
name="Web"
platform="Web"
export_path="builds/release/web/index.html"

[preset.3.options]
custom_template/debug=""
custom_template/release=""
variant/size_type=0  # Regular
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
```

## Build Scripts

### Local Build Script
```bash
#!/bin/bash
# scripts/build.sh

set -e

VERSION=${1:-"1.0.0"}
BUILD_TYPE=${2:-"release"}
PLATFORMS=${3:-"windows linux macos"}

echo "Building version $VERSION ($BUILD_TYPE) for: $PLATFORMS"

# Clean build directory
rm -rf builds/$BUILD_TYPE
mkdir -p builds/$BUILD_TYPE

# Update version in project
sed -i "s/config_version=.*/config_version=$VERSION/" project.godot

for platform in $PLATFORMS; do
    echo "Building for $platform..."
    
    case $platform in
        windows)
            godot --headless --export-release "Windows Desktop" \
                "builds/$BUILD_TYPE/windows/Game.exe"
            ;;
        linux)
            godot --headless --export-release "Linux/X11" \
                "builds/$BUILD_TYPE/linux/game.x86_64"
            ;;
        macos)
            godot --headless --export-release "macOS" \
                "builds/$BUILD_TYPE/macos/Game.zip"
            ;;
        web)
            godot --headless --export-release "Web" \
                "builds/$BUILD_TYPE/web/index.html"
            ;;
    esac
done

echo "Build complete!"
```

### Export Validation
```bash
#!/bin/bash
# scripts/validate_build.sh

BUILD_DIR=${1:-"builds/release"}

echo "Validating build in $BUILD_DIR..."

# Check Windows build
if [ -f "$BUILD_DIR/windows/Game.exe" ]; then
    echo "✓ Windows executable exists"
    # Check file size is reasonable (> 10MB)
    size=$(stat -f%z "$BUILD_DIR/windows/Game.exe" 2>/dev/null || stat -c%s "$BUILD_DIR/windows/Game.exe")
    if [ $size -gt 10485760 ]; then
        echo "✓ Windows executable size OK ($(($size / 1024 / 1024)) MB)"
    else
        echo "✗ Windows executable suspiciously small"
        exit 1
    fi
else
    echo "✗ Windows executable missing"
    exit 1
fi

# Check for required files
for file in "$BUILD_DIR/windows/Game.pck"; do
    if [ -f "$file" ]; then
        echo "✓ $(basename $file) exists"
    else
        echo "✗ $(basename $file) missing"
        exit 1
    fi
done

echo "Build validation passed!"
```

## Export Templates

### Installing Templates
```bash
# Via Godot editor
# Editor → Manage Export Templates → Download and Install

# Via command line (CI)
wget https://downloads.tuxfamily.org/godotengine/4.2.1/Godot_v4.2.1-stable_export_templates.tpz
mkdir -p ~/.local/share/godot/export_templates/4.2.1.stable
unzip Godot_v4.2.1-stable_export_templates.tpz -d ~/.local/share/godot/export_templates/4.2.1.stable/
```

### Custom Templates
```bash
# Build custom export template from Godot source
# For performance optimizations or engine modifications

git clone https://github.com/godotengine/godot.git
cd godot
git checkout 4.2.1-stable

# Build release template
scons platform=windows target=template_release -j$(nproc)

# Copy to templates directory
cp bin/godot.windows.template_release.x86_64.exe \
   ~/.local/share/godot/export_templates/4.2.1.stable/windows_release_x86_64.exe
```

## Build Configurations

### Debug Build
```bash
# Development build with console, debug symbols
godot --headless --export-debug "Windows Desktop" \
    --export-pck \
    builds/debug/game_debug.exe
```

### Release Build
```bash
# Optimized build for distribution
godot --headless --export-release "Windows Desktop" \
    builds/release/game.exe
```

### Export PCK Only
```bash
# Export just the PCK file (for patches/DLC)
godot --headless --export-pack "Windows Desktop" \
    builds/patch/patch_v1_1.pck
```

## Version Management

### Auto-Versioning Script
```gdscript
# scripts/auto_version.gd
@tool
extends EditorScript

func _run() -> void:
    var version := _generate_version()
    ProjectSettings.set_setting("application/config/version", version)
    ProjectSettings.save()
    print("Version set to: " + version)

func _generate_version() -> String:
    var git_hash := _get_git_short_hash()
    var build_num := _get_build_number()
    var base_version := "1.0.0"
    return "%s+%s.%s" % [base_version, build_num, git_hash]

func _get_git_short_hash() -> String:
    var output := []
    OS.execute("git", ["rev-parse", "--short", "HEAD"], output)
    return output[0].strip_edges()

func _get_build_number() -> String:
    var output := []
    OS.execute("git", ["rev-list", "--count", "HEAD"], output)
    return output[0].strip_edges()
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Build and Export

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        platform: [windows, linux, macos, web]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.2.1
          use-dotnet: false
      
      - name: Install Export Templates
        run: |
          mkdir -p ~/.local/share/godot/export_templates
          godot --headless --quit
      
      - name: Build ${{ matrix.platform }}
        run: |
          chmod +x scripts/build.sh
          ./scripts/build.sh ${{ github.ref_name }} release ${{ matrix.platform }}
      
      - name: Upload Artifact
        uses: actions/upload-artifact@v3
        with:
          name: game-${{ matrix.platform }}
          path: builds/release/${{ matrix.platform }}/
```

## Build Optimization

### Size Optimization
```ini
# export_presets.cfg - exclude unused resources
[preset.0]
export_filter="exclude"
export_files=PoolStringArray("res://src/tests/", "res://docs/", "res://scripts/")
```

### Performance Optimization
```bash
# Strip debug symbols (Linux)
strip builds/release/linux/game.x86_64

# UPX compression (optional)
upx --best builds/release/windows/Game.exe
```

## Distribution Packaging

### Windows Installer (NSIS)
```nsis
; installer.nsi
Name "Game Name"
OutFile "Game_Installer.exe"
InstallDir "$PROGRAMFILES64\Game Name"

Section "Install"
    SetOutPath $INSTDIR
    File /r "builds\release\windows\*"
    CreateShortcut "$DESKTOP\Game.lnk" "$INSTDIR\Game.exe"
SectionEnd
```

### macOS DMG
```bash
# Create DMG
create-dmg \
    --volname "Game Name" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --app-drop-link 600 185 \
    "builds/release/macos/Game.dmg" \
    "builds/release/macos/Game.app/"
```

## Failure Modes

| Failure | Detection | Resolution |
|---------|-----------|------------|
| Missing export template | "No export template found" | Install templates |
| Missing presets | "No export presets configured" | Create export_presets.cfg |
| Resource not found | Export warnings | Check resource paths |
| Large build size | Size > 500MB | Exclude unused resources |
| Export crash | Godot exits non-zero | Check project for errors |

## See Also

- [[Godot_Steam_Build_Packaging]] - Steam-specific packaging
- [[Godot_CI_Template]] - Complete CI configuration
- [[Godot_Asset_Import_Pipeline]] - Asset optimization
