---
title: Godot Steam Build Packaging
type: pipeline
layer: execution
status: active
tags:
  - godot
  - steam
  - packaging
  - sdk
  - steamworks
  - distribution
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Export_Pipeline]"
used_by:
  - "[Godot_CI_Template]"
---

# Godot Steam Build Packaging

Steam distribution requires specific build configurations, SDK integration, and depot management. This specification defines the complete Steam packaging pipeline for Godot 4.x games.

## Steam SDK Integration

### SDK Download
```bash
# Download Steamworks SDK from partner site
# https://partner.steamgames.com/doc/sdk

# Extract to project
mkdir -p third_party/steamworks/sdk
unzip steamworks_sdk_159.zip -d third_party/steamworks/sdk/
```

### GodotSteam Plugin
```bash
# Install GodotSteam addon
git submodule add https://github.com/GodotSteam/GodotSteam.git addons/godotsteam

# Or download release matching Godot version
# https://github.com/GodotSteam/GodotSteam/releases
```

### Project Configuration
```gdscript
# project.godot
[application]
config/name="Game Name"
config/description="Game description for Steam"
config/version="1.0.0"

[autoload]
Steam="*res://src/autoload/steam_manager.gd"
```

## Steam Manager Autoload

```gdscript
# src/autoload/steam_manager.gd
extends Node

const APP_ID: int = 480  # Replace with your Steam App ID

var _is_initialized: bool = false
var _steam_id: int = 0
var _player_name: String = "Player"

signal steam_initialized
signal overlay_activated(active: bool)
signal user_stats_received

func _ready() -> void:
    _initialize_steam()

func _initialize_steam() -> void:
    if OS.has_feature("editor"):
        # Use test App ID in editor
        OS.set_environment("SteamAppId", str(APP_ID))
    
    var init_result := Steam.steamInitEx()
    _is_initialized = init_result.status == Steam.RESULT_OK
    
    if _is_initialized:
        _steam_id = Steam.getSteamID()
        _player_name = Steam.getPersonaName()
        steam_initialized.emit()
        print("Steam initialized: " + _player_name)
    else:
        push_warning("Steam initialization failed: " + str(init_result.status))

func _process(_delta: float) -> void:
    if _is_initialized:
        Steam.runCallbacks()

func is_initialized() -> bool:
    return _is_initialized

func get_player_name() -> String:
    return _player_name

func unlock_achievement(achievement_id: String) -> void:
    if _is_initialized:
        Steam.setAchievement(achievement_id)
        Steam.storeStats()

func set_stat(stat_name: String, value: int) -> void:
    if _is_initialized:
        Steam.setStatInt(stat_name, value)
        Steam.storeStats()
```

## Steam Features Integration

### Achievements
```gdscript
# Define achievements in Steamworks partner site
# Then unlock from game code

func _on_level_completed(level_id: String) -> void:
    match level_id:
        "level_1":
            SteamManager.unlock_achievement("ACH_FIRST_LEVEL")
        "level_10":
            SteamManager.unlock_achievement("ACH_TEN_LEVELS")
        "level_all":
            SteamManager.unlock_achievement("ACH_COMPLETE_GAME")
```

### Leaderboards
```gdscript
func submit_score(score: int) -> void:
    if SteamManager.is_initialized():
        Steam.uploadLeaderboardScore(
            leaderboard_handle,
            score,
            false,  # keep_best
            [],     # details
            Steam.LEADERBOARD_UPLOAD_SCORE_METHOD_KEEP_BEST
        )
```

### Cloud Save
```gdscript
# Steam cloud is automatic if configured in partner site
# Just use regular FileAccess in user:// directory

func save_game(slot: int) -> void:
    var path := "user://save_" + str(slot) + ".dat"
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_var(_get_save_data())
    # Steam syncs automatically
```

## Build Configuration

### Steam-Specific Export Preset
```ini
[preset.0]
name="Steam Windows"
platform="Windows Desktop"
export_path="builds/steam/windows/Game.exe"

[preset.0.options]
# Steam overlay compatibility
codesign/enable=false
binary_format/embed_pck=true  # Single file for Steam
```

### Build Script
```bash
#!/bin/bash
# scripts/build_steam.sh

set -e

VERSION=${1:-"1.0.0"}
BUILD_ID=${2:-"1"}

echo "Building Steam version $VERSION (Build ID: $BUILD_ID)"

# Clean and create directories
rm -rf builds/steam
mkdir -p builds/steam/{windows,linux,macos}

# Build for each platform
echo "Building Windows..."
godot --headless --export-release "Steam Windows" \
    "builds/steam/windows/Game.exe"

echo "Building Linux..."
godot --headless --export-release "Steam Linux" \
    "builds/steam/linux/game.x86_64"

echo "Building macOS..."
godot --headless --export-release "Steam macOS" \
    "builds/steam/macos/Game.zip"

# Create Steam depot manifests
echo "Creating depot manifests..."
python scripts/generate_depot_manifests.py --version "$VERSION" --build-id "$BUILD_ID"

echo "Steam build complete!"
```

## Depot Configuration

### app_build_480.vdf
```vdf
"AppBuild"
{
    "AppID" "480" // Your App ID
    "Desc" "Build v1.0.0"
    
    "ContentRoot" "builds/steam"
    "BuildOutput" "builds/steam/output"
    
    "Depots"
    {
        "481" // Windows depot
        {
            "FileMapping"
            {
                "LocalPath" "windows/*"
                "DepotPath" "."
                "recursive" "1"
            }
        }
        
        "482" // Linux depot
        {
            "FileMapping"
            {
                "LocalPath" "linux/*"
                "DepotPath" "."
                "recursive" "1"
            }
        }
        
        "483" // macOS depot
        {
            "FileMapping"
            {
                "LocalPath" "macos/*"
                "DepotPath" "."
                "recursive" "1"
            }
        }
    }
}
```

## Steam Upload

### Manual Upload
```bash
# Using SteamCMD
steamcmd +login username password \
    +run_app_build $(pwd)/scripts/steam/app_build_480.vdf \
    +quit
```

### Automated Upload (CI)
```bash
#!/bin/bash
# scripts/upload_steam.sh

set -e

STEAM_USERNAME=$1
STEAM_PASSWORD=$2
BUILD_ID=$3

# Create build config with dynamic build ID
sed "s/BUILD_ID/$BUILD_ID/g" scripts/steam/app_build_template.vdf > app_build.vdf

# Upload via SteamCMD
steamcmd +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
    +run_app_build $(pwd)/app_build.vdf \
    +quit

echo "Upload complete!"
```

### GitHub Actions
```yaml
name: Steam Upload

on:
  push:
    tags:
      - 'v*'

jobs:
  steam-upload:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.2.1
      
      - name: Build Steam Versions
        run: ./scripts/build_steam.sh ${{ github.ref_name }} ${{ github.run_number }}
      
      - name: Upload to Steam
        env:
          STEAM_USERNAME: ${{ secrets.STEAM_USERNAME }}
          STEAM_PASSWORD: ${{ secrets.STEAM_PASSWORD }}
        run: ./scripts/upload_steam.sh "$STEAM_USERNAME" "$STEAM_PASSWORD" ${{ github.run_number }}
```

## Steam Features Checklist

### Required
- [ ] Steam App ID configured
- [ ] Steam SDK integrated
- [ ] SteamManager autoload
- [ ] Initialization error handling
- [ ] Build uploaded to Steam

### Recommended
- [ ] Achievements implemented
- [ ] Cloud saves enabled
- [ ] Steam Input configured
- [ ] Rich presence
- [ ] Stats tracking

### Optional
- [ ] Leaderboards
- [ ] Multiplayer/Networking
- [ ] Steam Workshop
- [ ] Trading cards
- [ ] Controller support

## Testing Steam Integration

### Local Testing
```bash
# Launch with Steam in test mode
# 1. Add non-Steam game to library
# 2. Launch from Steam
# 3. Verify overlay works (Shift+Tab)
```

### Test App ID
```gdscript
# Use Spacewar (App ID 480) for testing
const APP_ID: int = 480

# Or create your own test app in Steamworks
```

## Common Issues

| Issue | Cause | Resolution |
|-------|-------|------------|
| Steam not initialized | Not launched via Steam | Launch from Steam client |
| Overlay not working | Graphics conflict | Disable other overlays |
| Achievements not unlocking | Wrong achievement ID | Verify in Steamworks |
| Cloud sync fails | Not configured | Enable in partner site |
| Build not visible | Not published | Set build live on Steamworks |

## Steamworks Configuration

### App Admin Settings
```
Steamworks → App Admin → Your App
├── General
│   └── Type: Game
├── Steamworks Settings
│   ├── Steam Cloud: Enabled
│   └── Steam Input: Enabled
├── Installation
│   └── Launch Options
│       ├── Executable: Game.exe
│       └── Working Dir: .
└── Steam Pipe
    └── Depots
        ├── Windows (481)
        ├── Linux (482)
        └── macOS (483)
```

## See Also

- [[Godot_Export_Pipeline]] - General export process
- [[Godot_CI_Template]] - CI/CD integration
- Steamworks Documentation: https://partner.steamgames.com/doc
