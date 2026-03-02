---
title: Godot Asset Import Pipeline
type: pipeline
layer: execution
status: active
tags:
  - godot
  - assets
  - import
  - pipeline
  - optimization
  - git-lfs
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Project_Layout_Conventions]"
used_by:
  - "[Godot_Export_Pipeline]]"
  - "[[Godot_Performance_Budgets]"
---

# Godot Asset Import Pipeline

The asset import pipeline manages how source assets (PNG, WAV, FBX, etc.) are transformed into engine-ready resources. Proper import settings ensure consistent performance, quality, and build sizes across all team members and CI environments.

## Pipeline Overview

```
Source Asset → Import Settings → Imported Resource → Version Control
     ↓              ↓                  ↓                  ↓
   .png/.wav    .import file      .godot/import/    Git LFS
```

## Directory Structure

```
assets/              # Source assets (Git LFS)
├── images/
│   ├── sprites/     # 2D sprite sheets
│   ├── textures/    # 3D textures
│   └── ui/          # UI elements
├── audio/
│   ├── music/       # BGM (streaming)
│   └── sfx/         # Sound effects
├── models/
│   ├── characters/  # Character models
│   └── environment/ # Environment assets
└── fonts/
    └── ...

src/resources/       # Godot resources (.tres, .tscn)
└── imported/        # References to imported assets
```

## Import Settings by Asset Type

### 2D Sprites (PNG)

#### Default Settings (project.godot)
```ini
[importer_defaults]

texture={
"compress/bptc_ldr": 0,
"compress/hdr_mode": 0,
"compress/lossy_quality": 0.7,
"compress/mode": 0,  # Lossless
"compress/normal_map": 0,
"detect_3d/compress_to": 1,
"mipmaps/generate": false,
"process/fix_alpha_border": true,
"process/hdr_as_srgb": false,
"process/normal_map_invert_y": false,
"process/premult_alpha": false,
"process/size_limit": 0,
"roughness/mode": 0,
"roughness/src_normal": ""
}
```

#### Sprite-Specific (.import file)
```ini
[remap]
importer="texture"
type="CompressedTexture2D"

[deps]
source_file="res://assets/images/sprites/player.png"
dest_files=["res://.godot/imported/player.png-xxx.ctex"]

[params]
compress/mode=0  # 0=lossless, 1=lossy, 2=VRAM, 3=basis
compress/lossy_quality=0.7
mipmaps/generate=false
process/fix_alpha_border=true
process/premult_alpha=false
```

### 3D Textures
```ini
[params]
compress/mode=2  # VRAM compressed
mipmaps/generate=true
roughness/mode=0
```

### Audio (WAV/OGG)

#### Sound Effects (WAV)
```ini
[remap]
importer="wav"
type="AudioStreamWAV"

[params]
force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=0  # 0=disabled, 1=forward, 2=ping-pong, 3=backward
compress/mode=0   # 0=PCM, 1=ADPCM, 2=QOA
```

#### Music (OGG)
```ini
[remap]
importer="oggvorbisstr"
type="AudioStreamOggVorbis"

[params]
loop=false
```

### 3D Models (GLTF/FBX)
```ini
[remap]
importer="scene"
type="PackedScene"

[params]
nodes/apply_root_scale=true
nodes/root_scale=1.0
meshes/ensure_tangents=true
meshes/generate_lods=true
meshes/create_shadow_meshes=true
skins/use_named_skins=true
animation/import=true
animation/fps=30
```

## Import Presets

### Create Reusable Presets
```gdscript
# In Godot Editor: Import tab → Preset → Save

# presets/sprite_pixel_art.preset
[params]
compress/mode=0
mipmaps/generate=false
process/fix_alpha_border=true
```

### Apply Presets in Batch
```bash
# Apply preset to all files in directory
for file in assets/images/sprites/*.png; do
    godot --headless --script scripts/apply_import_preset.gd \
        --file="$file" \
        --preset="sprite_pixel_art"
done
```

## Git LFS Configuration

### .gitattributes
```gitattributes
# Images
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.webp filter=lfs diff=lfs merge=lfs -text
*.tga filter=lfs diff=lfs merge=lfs -text
*.psd filter=lfs diff=lfs merge=lfs -text

# Audio
*.wav filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.flac filter=lfs diff=lfs merge=lfs -text

# 3D
*.fbx filter=lfs diff=lfs merge=lfs -text
*.gltf filter=lfs diff=lfs merge=lfs -text
*.glb filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text
*.obj filter=lfs diff=lfs merge=lfs -text

# Fonts
*.ttf filter=lfs diff=lfs merge=lfs -text
*.otf filter=lfs diff=lfs merge=lfs -text

# Video
*.ogv filter=lfs diff=lfs merge=lfs -text
*.webm filter=lfs diff=lfs merge=lfs -text
```

## Import Validation

### Pre-commit Hook
```bash
#!/bin/bash
# scripts/hooks/pre-commit-assets

# Check for missing .import files
for asset in $(git diff --cached --name-only | grep -E '\.(png|wav|ogg|fbx)$'); do
    if [ ! -f "${asset}.import" ]; then
        echo "ERROR: Missing import file for $asset"
        echo "Run 'godot --editor --quit' to generate import files"
        exit 1
    fi
done

# Validate import settings
python scripts/validate_import_settings.py
```

### CI Validation
```bash
#!/bin/bash
# scripts/ci/validate_assets.sh

# Check all assets have import files
find assets/ -type f \( -name "*.png" -o -name "*.wav" -o -name "*.ogg" \) | while read file; do
    if [ ! -f "${file}.import" ]; then
        echo "Missing import: $file"
        exit 1
    fi
done

# Check texture sizes
python scripts/check_texture_sizes.py --max-size 2048

# Check audio sample rates
python scripts/check_audio_settings.py --required-rate 44100
```

## Performance Budgets

### Texture Budgets
| Type | Max Size | Format | Mipmaps |
|------|----------|--------|---------|
| UI elements | 512x512 | Lossless | No |
| 2D sprites | 1024x1024 | Lossless | No |
| 3D textures | 2048x2048 | VRAM | Yes |
| Environment | 4096x4096 | VRAM | Yes |

### Audio Budgets
| Type | Format | Max Length | Sample Rate |
|------|--------|------------|-------------|
| SFX | QOA/ADPCM | 5 sec | 44100 Hz |
| Music | OGG Vorbis | Unlimited | 44100 Hz |
| Ambient | OGG Vorbis | 30 sec loop | 44100 Hz |

## Import Pipeline Script

### Automated Import
```gdscript
# scripts/batch_import.gd
@tool
extends EditorScript

func _run() -> void:
    var import_dir := "res://assets"
    _import_directory(import_dir)
    print("Import complete!")

func _import_directory(path: String) -> void:
    var dir := DirAccess.open(path)
    if dir == null:
        return
    
    dir.list_dir_begin()
    var file := dir.get_next()
    
    while file != "":
        var full_path := path.path_join(file)
        
        if dir.current_is_dir():
            _import_directory(full_path)
        elif file.ends_with(".png") or file.ends_with(".wav"):
            _reimport_asset(full_path)
        
        file = dir.get_next()

func _reimport_asset(path: String) -> void:
    var importer := EditorInterface.get_resource_filesystem()
    importer.reimport_files([path])
```

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Missing textures in build | Import files not committed | Add .import files to git |
| Large build size | Wrong compression settings | Use VRAM compression for 3D |
| Audio pops/clicks | Wrong import format | Use PCM for short SFX |
| Slow load times | No texture streaming | Enable mipmaps, use smaller sizes |
| Git bloat | Raw assets not in LFS | Configure .gitattributes |

## Optimization Checklist

- [ ] All textures have appropriate compression
- [ ] 3D textures use VRAM compression with mipmaps
- [ ] Audio files use correct format (QOA for SFX, OGG for music)
- [ ] Import files committed to version control
- [ ] Source assets in Git LFS
- [ ] Texture sizes within budget
- [ ] No duplicate assets
- [ ] Unused assets removed

## See Also

- [[Godot_Export_Pipeline]] - Build export process
- [[Godot_Performance_Budgets]] - Performance targets
- [[Godot_Project_Layout_Conventions]] - Directory structure
