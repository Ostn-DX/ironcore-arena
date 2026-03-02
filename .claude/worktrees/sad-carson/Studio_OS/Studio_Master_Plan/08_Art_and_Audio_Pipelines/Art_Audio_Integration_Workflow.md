---
title: Art Audio Integration Workflow
type: pipeline
layer: execution
status: active
tags:
  - art
  - audio
  - integration
  - workflow
  - engine
depends_on:
  - "[Art_Pipeline_Overview]]"
  - "[[Audio_Pipeline_Overview]]"
  - "[[Import_Settings_Validation]]"
  - "[[Audio_Validation_Gates]"
used_by:
  - "[Human_Checkpoint_Minimization]"
---

# Art Audio Integration Workflow

## Purpose

Standardized workflow for importing validated art and audio assets into the game engine, ensuring proper configuration and immediate usability.

---

## Integration Philosophy

**Assets should flow from generation → validation → engine with minimal friction.**

```
Validated Assets → Import Pipeline → Engine Config → In-Game Test
```

---

## Integration Pipeline Overview

### Stage 1: Asset Collection

**Input**: Validated assets from art/audio pipelines

**Actions**:
1. Collect all assets passing validation gates
2. Organize by category (characters, UI, SFX, music)
3. Generate import manifest

**Manifest Format**:
```yaml
import_manifest:
  timestamp: "2024-01-15T10:30:00Z"
  batch_id: "BATCH-2024-001"
  
  assets:
    art:
      - path: "validated/char_hero_idle_01.png"
        type: "character"
        settings: "sprite_64x64"
      - path: "validated/ui_button_primary.png"
        type: "ui"
        settings: "ui_element"
    
    audio:
      - path: "validated/audio_ui_button_click.ogg"
        type: "sfx"
        settings: "ui_sfx"
      - path: "validated/audio_music_forest.ogg"
        type: "music"
        settings: "bgm_loop"
```

### Stage 2: Engine Import (Automated)

#### Unity Import

```python
import unity_editor

def import_to_unity(asset_path, settings):
    """Import asset to Unity with correct settings"""
    
    # Import asset
    asset = unity_editor.import_asset(asset_path)
    
    # Apply settings based on type
    if settings['type'] == 'character':
        importer = asset.GetImporter()
        importer.textureType = 'Sprite (2D and UI)'
        importer.spritePixelsPerUnit = 100
        importer.filterMode = 'Point'  # For pixel art
        importer.SaveAndReimport()
    
    elif settings['type'] == 'sfx':
        importer = asset.GetImporter()
        importer.forceToMono = True
        importer.loadInBackground = True
        importer.preloadAudioData = False
        importer.SaveAndReimport()
    
    return asset
```

#### Unreal Import

```python
import unreal

def import_to_unreal(asset_path, settings):
    """Import asset to Unreal with correct settings"""
    
    # Import task
    task = unreal.AssetImportTask()
    task.filename = asset_path
    task.destination_path = f"/Game/{settings['type']}s/"
    task.automated = True
    
    # Apply settings
    if settings['type'] == 'sprite':
        task.options = unreal.PaperSpriteImportOptions()
    elif settings['type'] == 'sfx':
        task.options = unreal.SoundImportOptions()
    
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    
    return task.imported_object_paths
```

#### Godot Import

```python
def import_to_godot(asset_path, settings):
    """Import asset to Godot"""
    
    # Copy to project
    import shutil
    dest = f"res://assets/{settings['type']}s/"
    shutil.copy(asset_path, dest)
    
    # Godot auto-imports on next launch
    # .import files are auto-generated
```

### Stage 3: Configuration Application

#### Art Configuration

| Asset Type | Unity Settings | Unreal Settings |
|------------|----------------|-----------------|
| Sprite | Sprite (2D), Point filter | Paper2D, Nearest |
| Texture 3D | Default, Trilinear | World, Default |
| UI | Sprite (2D), Bilinear | UI, Default |
| Normal Map | Normal Map | Normalmap |

#### Audio Configuration

| Asset Type | Unity Settings | Unreal Settings |
|------------|----------------|-----------------|
| SFX | Force Mono, Load in BG | 2D, Stream |
| Music | Stereo, Stream | 2D, Stream |
| Voice | Mono, Decompress | 2D, Stream |

### Stage 4: Registry Update

```yaml
asset_registry:
  assets:
    - id: "char_hero_idle_01"
      type: "character"
      source: "generated"
      import_date: "2024-01-15"
      engine_path: "Assets/Characters/char_hero_idle_01.png"
      status: "active"
      
    - id: "audio_ui_button_click"
      type: "sfx"
      source: "generated"
      import_date: "2024-01-15"
      engine_path: "Assets/Audio/SFX/ui_button_click.ogg"
      status: "active"
```

---

## Integration Scripts

### Full Integration Pipeline

```python
#!/usr/bin/env python3
"""
Art/Audio Integration Pipeline
Imports validated assets to game engine
"""

import os
import yaml
import shutil
from pathlib import Path

class AssetIntegrator:
    def __init__(self, engine='unity', project_path='.'):
        self.engine = engine
        self.project_path = Path(project_path)
        self.manifest = None
    
    def load_manifest(self, manifest_path):
        """Load import manifest"""
        with open(manifest_path) as f:
            self.manifest = yaml.safe_load(f)
    
    def integrate_art(self):
        """Integrate art assets"""
        for asset in self.manifest['assets']['art']:
            print(f"Integrating art: {asset['path']}")
            
            if self.engine == 'unity':
                self._import_unity_art(asset)
            elif self.engine == 'unreal':
                self._import_unreal_art(asset)
            elif self.engine == 'godot':
                self._import_godot_art(asset)
    
    def integrate_audio(self):
        """Integrate audio assets"""
        for asset in self.manifest['assets']['audio']:
            print(f"Integrating audio: {asset['path']}")
            
            if self.engine == 'unity':
                self._import_unity_audio(asset)
            elif self.engine == 'unreal':
                self._import_unreal_audio(asset)
            elif self.engine == 'godot':
                self._import_godot_audio(asset)
    
    def _import_unity_art(self, asset):
        """Import art to Unity"""
        dest = self.project_path / 'Assets' / 'Art' / asset['type']
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copy(asset['path'], dest)
        # Unity will auto-import on focus
    
    def _import_unity_audio(self, asset):
        """Import audio to Unity"""
        dest = self.project_path / 'Assets' / 'Audio' / asset['type']
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copy(asset['path'], dest)
    
    def run(self, manifest_path):
        """Run full integration"""
        self.load_manifest(manifest_path)
        self.integrate_art()
        self.integrate_audio()
        print("Integration complete!")

# Usage
if __name__ == '__main__':
    integrator = AssetIntegrator(engine='unity', project_path='./MyGame')
    integrator.run('import_manifest.yaml')
```

---

## Validation Post-Import

### In-Engine Checks

| Check | Method | Pass Criteria |
|-------|--------|---------------|
| Asset loads | Try load | No errors |
| Visual correct | Visual check | Matches expected |
| Audio plays | Audio check | Plays correctly |
| Settings applied | Inspector check | Correct import settings |
| Performance OK | Profiler | Within budget |

### Automated Post-Import Test

```python
def post_import_validation(asset_path, engine='unity'):
    """Validate asset after import"""
    
    results = {
        'asset': asset_path,
        'checks': {}
    }
    
    # Try to load
    try:
        if engine == 'unity':
            loaded = unity_editor.load_asset(asset_path)
            results['checks']['load'] = {'passed': True}
        elif engine == 'unreal':
            loaded = unreal.load_asset(asset_path)
            results['checks']['load'] = {'passed': True}
    except Exception as e:
        results['checks']['load'] = {'passed': False, 'error': str(e)}
    
    # Check settings
    # (Engine-specific)
    
    return results
```

---

## Integration Checklist

### Pre-Integration

- [ ] All assets passed validation gates
- [ ] Import manifest generated
- [ ] Engine project open/ready
- [ ] Backup created

### During Integration

- [ ] Assets copied to correct folders
- [ ] Import settings applied
- [ ] No import errors
- [ ] Asset registry updated

### Post-Integration

- [ ] Assets visible in engine
- [ ] Preview shows correctly
- [ ] Audio plays in preview
- [ ] Settings match specification
- [ ] Scene can use assets

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  INTEGRATION QUICK REFERENCE                           │
├────────────────────────────────────────────────────────┤
│  STAGES:                                               │
│  1. Collect validated assets                           │
│  2. Generate import manifest                           │
│  3. Import to engine                                   │
│  4. Apply settings                                     │
│  5. Update registry                                    │
│  6. Post-import validation                             │
├────────────────────────────────────────────────────────┤
│  FOLDER STRUCTURE:                                     │
│  Unity: Assets/{Art,Audio}/{Category}/                 │
│  Unreal: Content/{Art,Audio}/{Category}/               │
│  Godot: res://assets/{art,audio}/{category}/           │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Art_Pipeline_Overview]] - Art pipeline
- [[Audio_Pipeline_Overview]] - Audio pipeline
- [[Import_Settings_Validation]] - Import settings
- [[Audio_Validation_Gates]] - Audio validation
- [[Human_Checkpoint_Minimization]] - Reducing approval overhead
