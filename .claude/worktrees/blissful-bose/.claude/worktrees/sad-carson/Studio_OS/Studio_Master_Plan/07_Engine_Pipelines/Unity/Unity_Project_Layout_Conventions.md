---
title: Unity Project Layout Conventions
type: rule
layer: architecture
status: active
tags:
  - unity
  - project-structure
  - folders
  - organization
  - conventions
depends_on:
  - "[Unity_Pipeline_Overview]"
used_by:
  - "[Unity_Assembly_Definition_Strategy]]"
  - "[[Unity_Asset_Import_Pipeline]]"
  - "[[Unity_Build_Automation]"
---

# Unity Project Layout Conventions

Standardized project structure ensures AI agents and human developers can navigate any Studio OS Unity project without relearning organization patterns. These conventions enforce separation of concerns and enable automated tooling.

## Root Directory Structure

```
MyProject/
├── Assets/                    # Unity-managed content
├── Packages/                  # Package manifest and lock
├── ProjectSettings/          # Unity project configuration
├── UserSettings/             # User-specific settings (gitignored)
├── Build/                    # Build outputs (gitignored)
├── Logs/                     # Unity logs (gitignored)
├── Tests/                    # Test configuration
├── Tools/                    # Custom build/editor tools
├── .github/                  # GitHub Actions workflows
├── .gitignore               # Git ignore rules
└── README.md                # Project documentation
```

## Assets Folder Structure

```
Assets/
├── _Project/                 # All project-specific content
│   ├── Scripts/             # C# source code
│   │   ├── Runtime/        # Runtime scripts
│   │   │   ├── Core/       # Core systems (no external deps)
│   │   │   ├── Gameplay/   # Game-specific logic
│   │   │   ├── UI/         # User interface
│   │   │   └── Services/   # External service integrations
│   │   └── Editor/         # Editor-only scripts
│   │       ├── Tools/      # Custom editor tools
│   │       └── Importers/  # Asset importers
│   ├── Prefabs/            # Prefab assets
│   │   ├── Characters/     # Character prefabs
│   │   ├── Environment/    # Environment prefabs
│   │   ├── UI/             # UI prefabs
│   │   └── Systems/        # System prefabs
│   ├── Scenes/             # Scene files
│   │   ├── Boot/           # Initial load scene
│   │   ├── MainMenu/       # Menu scenes
│   │   ├── Levels/         # Game levels
│   │   └── Tests/          # Test scenes
│   ├── ScriptableObjects/  # SO definitions
│   │   ├── Data/           # Data assets
│   │   ├── Config/         # Configuration
│   │   └── Events/         # Event channels
│   ├── Resources/          # Resources folder (minimize use)
│   ├── Audio/              # Audio assets
│   │   ├── Music/          # Music tracks
│   │   ├── SFX/            # Sound effects
│   │   └── Ambient/        # Ambient sounds
│   ├── Art/                # Visual assets
│   │   ├── Models/         # 3D models
│   │   ├── Materials/      # Materials
│   │   ├── Textures/       # Textures
│   │   ├── Animations/     # Animation clips
│   │   ├── Shaders/        # Custom shaders
│   │   └── VFX/            # Visual effects
│   └── StreamingAssets/    # Raw files for streaming
├── Plugins/                 # Third-party plugins
├── ThirdParty/             # Third-party assets (store-bought)
└── AddressableAssetsData/  # Addressables configuration
```

## Folder Naming Conventions

### Prefix System
| Prefix | Meaning | Example |
|--------|---------|---------|
| `_` | Private/Internal | `_Project`, `_Internal` |
| `~` | Ignored by Unity | `~Temp` (rarely used) |
| No prefix | Standard content | `Scripts`, `Prefabs` |

### Naming Rules
1. **PascalCase** for all folder names: `ScriptableObjects/`, `MyFolder/`
2. **Singular** preferred: `Script/` not `Scripts/`
3. **No spaces** in folder names
4. **No special characters** except underscore

## Script Organization

### Runtime Scripts (`Assets/_Project/Scripts/Runtime/`)

```
Runtime/
├── Core/                    # Foundation systems
│   ├── Events/             # Event system
│   ├── Pooling/            # Object pooling
│   ├── StateMachine/       # State machines
│   └── Utils/              # Utilities
├── Gameplay/               # Game-specific
│   ├── Player/             # Player systems
│   ├── Enemies/            # Enemy systems
│   ├── Items/              # Item systems
│   └── World/              # World systems
├── UI/                     # User interface
│   ├── HUD/                # Heads-up display
│   ├── Menus/              # Menu systems
│   └── Components/         # Reusable UI
└── Services/               # External integrations
    ├── Save/               # Save/load
    ├── Analytics/          # Analytics
    └── Steam/              # Steam integration
```

### Editor Scripts (`Assets/_Project/Scripts/Editor/`)

```
Editor/
├── Tools/                  # Custom tools
│   ├── LevelEditor/       # Level editing tools
│   ├── BatchProcessors/   # Batch operations
│   └── Validators/        # Validation tools
├── Importers/             # Custom importers
│   ├── TextureImporter/   # Texture processing
│   └── ModelImporter/     # Model processing
├── PropertyDrawers/       # Custom property drawers
└── Editors/               # Custom editors
```

## Scene Organization

### Scene Naming Convention
```
[Type]_[Name]_[Variant]

Examples:
- Boot_InitialLoad
- Menu_Main
- Level_Forest_01
- Level_Forest_01_Night
- Test_PlayerMovement
```

### Scene Types
| Type | Purpose | Example |
|------|---------|---------|
| `Boot` | Initial load, setup | `Boot_InitialLoad` |
| `Menu` | UI menus | `Menu_Main`, `Menu_Pause` |
| `Level` | Gameplay levels | `Level_City_01` |
| `Test` | Test scenes | `Test_Physics` |
| `Dev` | Development only | `Dev_Sandbox` |

## Asset Placement Rules

### Scripts
- Runtime scripts: `Assets/_Project/Scripts/Runtime/`
- Editor scripts: `Assets/_Project/Scripts/Editor/`
- Third-party: `Assets/ThirdParty/[Vendor]/`

### Prefabs
- Character prefabs: `Assets/_Project/Prefabs/Characters/`
- UI prefabs: `Assets/_Project/Prefabs/UI/`
- System prefabs: `Assets/_Project/Prefabs/Systems/`
- Level-specific: `Assets/_Project/Prefabs/Levels/[LevelName]/`

### Scenes
- Production scenes: `Assets/_Project/Scenes/`
- Test scenes: `Assets/_Project/Scenes/Tests/`
- Development: `Assets/_Project/Scenes/Dev/` (gitignored in production)

## Git LFS Configuration

```gitattributes
# Large files tracked by LFS
*.psd filter=lfs diff=lfs merge=lfs -text
*.fbx filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.asset filter=lfs diff=lfs merge=lfs -text
```

## Enforcement

### Automated Validation
- CI check for folder naming violations
- Pre-commit hook for structure validation
- Editor tool for structure maintenance

### Manual Review
- Code review checklist includes structure compliance
- Architecture review for major changes

### Failure Modes
| Violation | Severity | Response |
|-----------|----------|----------|
| Wrong folder naming | Warning | CI warning |
| Script in wrong location | Error | CI block |
| Missing asmdef | Error | CI block |
| Resources folder abuse | Warning | Review required |
