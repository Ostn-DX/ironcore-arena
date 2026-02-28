---
title: Import Settings Validation
type: gate
layer: enforcement
status: active
tags:
  - art
  - import
  - validation
  - engine
  - settings
depends_on:
  - "[Asset_Naming_Conventions]]"
  - "[[Asset_Resolution_Standards]]"
  - "[[Asset_Format_Specifications]"
used_by:
  - "[Batch_Generation_Workflow]]"
  - "[[Art_Audio_Integration_Workflow]"
---

# Import Settings Validation

## Purpose

Ensure all imported art assets have correct engine settings for optimal performance and visual quality. Incorrect import settings cause performance issues, visual artifacts, and platform incompatibility.

---

## Validation Philosophy

**Every asset imported into the engine must be validated for:**
1. Correct texture format and compression
2. Appropriate mipmapping settings
3. Proper filtering mode
4. Platform-specific optimizations
5. Naming convention compliance

---

## Unity Import Settings

### Texture Importer Settings

#### Sprites (2D)

```yaml
Texture Type: Sprite (2D and UI)
Sprite Mode: Single (or Multiple for atlases)
Packing Tag: [atlas_group_name]
Pixels Per Unit: 100
Mesh Type: Full Rect
Wrap Mode: Clamp
Filter Mode: Point (pixel art) or Bilinear (smooth)
```

**Compression by Platform**:
| Platform | Format | Compression |
|----------|--------|-------------|
| PC | RGBA32 | None |
| Mobile | RGBA16 | High |
| Web | DXT5 | Normal |

#### 3D Textures

```yaml
Texture Type: Default
Wrap Mode: Repeat
Filter Mode: Trilinear
Aniso Level: 4-8
```

**Compression by Type**:
| Texture Type | Format | Notes |
|--------------|--------|-------|
| Diffuse/Albedo | DXT5 (BC3) | With alpha, or DXT1 without |
| Normal Map | DXT5 (BC3) | Or BC5 for better quality |
| Mask/Roughness | DXT1 (BC1) | Single channel, pack if possible |
| Emission | DXT5 (BC3) | HDR if needed |

### Validation Rules (Unity)

```python
UNITY_VALIDATION_RULES = {
    'sprite': {
        'texture_type': 'Sprite (2D and UI)',
        'filter_mode': ['Point', 'Bilinear'],
        'max_size_1024': 1024,
        'compression': 'Platform appropriate',
    },
    'texture_3d': {
        'texture_type': 'Default',
        'filter_mode': ['Bilinear', 'Trilinear'],
        'mipmaps': True,
        'aniso_level': '>= 4',
    },
    'normal_map': {
        'texture_type': 'Normal Map',
        'filter_mode': 'Trilinear',
        'compression': 'DXT5 or BC5',
    }
}
```

---

## Unreal Engine Import Settings

### Texture Properties

#### 2D Sprites (Paper2D)

```yaml
Texture Group: 2D Pixels (unfiltered)
Compression Settings: UserInterface2D (RGBA)
Filter: Nearest (pixel art) or Default (smooth)
Mip Gen Settings: NoMipmaps
```

#### 3D Textures

```yaml
Texture Group: World
Compression Settings: 
  - Diffuse: Default (DXT5)
  - Normal: Normalmap (BC5)
  - Mask: Grayscale (BC4)
Filter: Default
Mip Gen Settings: FromTextureGroup
LODBias: 0
```

### Validation Rules (Unreal)

```python
UNREAL_VALIDATION_RULES = {
    'sprite_2d': {
        'texture_group': '2D Pixels (unfiltered)',
        'compression': 'UserInterface2D',
        'filter': ['Nearest', 'Default'],
        'mip_gen': 'NoMipmaps',
    },
    'texture_3d': {
        'texture_group': 'World',
        'compression': 'Type appropriate',
        'filter': 'Default',
        'mip_gen': 'FromTextureGroup',
    },
    'normal_map': {
        'compression': 'Normalmap',
        'filter': 'Default',
        'sRGB': False,
    }
}
```

---

## Godot Import Settings

### Texture Import

```yaml
2D Pixel Art:
  Filter: Nearest
  Repeat: Disabled
  Mipmaps: Disabled

2D Smooth:
  Filter: Linear
  Repeat: Disabled
  Mipmaps: Enabled

3D Textures:
  Filter: Linear with Mipmaps
  Repeat: Enabled
  Mipmaps: Enabled
```

---

## Automated Validation Pipeline

### Pre-Import Checks

```python
def pre_import_validation(file_path):
    """Validate asset before engine import"""
    
    checks = {
        'naming': validate_naming(file_path),
        'resolution': validate_resolution(file_path),
        'format': validate_format(file_path),
        'file_size': validate_file_size(file_path),
        'corruption': validate_not_corrupt(file_path),
    }
    
    return all(checks.values()), checks
```

### Post-Import Checks

```python
def post_import_validation(asset_path, engine='unity'):
    """Validate asset settings after import"""
    
    if engine == 'unity':
        importer = get_unity_importer(asset_path)
        rules = UNITY_VALIDATION_RULES
    elif engine == 'unreal':
        importer = get_unreal_texture(asset_path)
        rules = UNREAL_VALIDATION_RULES
    
    checks = {
        'texture_type': importer.texture_type == rules['texture_type'],
        'filter_mode': importer.filter_mode in rules['filter_mode'],
        'compression': validate_compression(importer, rules),
        'mipmaps': importer.mipmaps == rules.get('mipmaps', True),
    }
    
    return all(checks.values()), checks
```

---

## Common Import Issues

### Issue: Blurry Pixel Art

**Cause**: Filter mode set to Bilinear/Trilinear
**Fix**: Set Filter Mode to Point (Nearest)

### Issue: Texture Bleeding

**Cause**: No padding in atlas, Wrap Mode set to Repeat
**Fix**: Add 2px padding, set Wrap Mode to Clamp

### Issue: Large Build Size

**Cause**: No compression, full-size textures
**Fix**: Enable platform-appropriate compression, use max size limits

### Issue: Slow Loading

**Cause**: No mipmaps on 3D textures
**Fix**: Enable mipmaps for 3D textures

### Issue: Normal Map Looks Wrong

**Cause**: sRGB enabled on normal map
**Fix**: Disable sRGB for normal maps

---

## Platform-Specific Settings

### Mobile Optimization

```yaml
Max Texture Size: 1024
Compression: PVRTC (iOS), ETC2 (Android)
Format: 16-bit if possible
Mipmaps: Enabled
```

### Web Optimization

```yaml
Max Texture Size: 1024
Compression: DXT5 (if supported), else uncompressed
Format: RGBA32
Power-of-Two: Required
```

### Console/PC

```yaml
Max Texture Size: 2048-4096
Compression: BC1-BC7
Format: Full quality
Mipmaps: Enabled
```

---

## Validation Report Format

```yaml
validation_report:
  timestamp: "2024-01-15T10:30:00Z"
  asset_path: "Assets/Characters/char_hero.png"
  engine: "unity"
  
  pre_import:
    naming: { passed: true }
    resolution: { passed: true }
    format: { passed: true }
    file_size: { passed: true, size_kb: 45 }
    corruption: { passed: true }
  
  post_import:
    texture_type: { passed: true, value: "Sprite (2D and UI)" }
    filter_mode: { passed: true, value: "Point" }
    compression: { passed: true, format: "RGBA32" }
    mipmaps: { passed: true, enabled: false }
    max_size: { passed: true, value: 1024 }
  
  overall: PASSED
  warnings: []
  errors: []
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  IMPORT SETTINGS QUICK REFERENCE                       │
├────────────────────────────────────────────────────────┤
│  UNITY:                                                │
│  • Sprites: Type=Sprite, Filter=Point/Bilinear         │
│  • 3D: Type=Default, Filter=Trilinear, Mipmaps=ON      │
│  • Normal: Type=Normal Map, sRGB=OFF                   │
├────────────────────────────────────────────────────────┤
│  UNREAL:                                               │
│  • Sprites: Group=2D Pixels, Filter=Nearest            │
│  • 3D: Group=World, Compression=Type-specific          │
│  • Normal: Compression=Normalmap, sRGB=OFF             │
├────────────────────────────────────────────────────────┤
│  GODOT:                                                │
│  • Pixel: Filter=Nearest, Mipmaps=OFF                  │
│  • 3D: Filter=Linear Mipmaps, Mipmaps=ON               │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Asset_Naming_Conventions]] - Naming validation
- [[Asset_Resolution_Standards]] - Resolution validation
- [[Asset_Format_Specifications]] - Format validation
- [[Batch_Generation_Workflow]] - Import step
- [[Art_Audio_Integration_Workflow]] - Full integration
