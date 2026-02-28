---
title: Unity Asset Import Pipeline
type: pipeline
layer: execution
status: active
tags:
  - unity
  - assets
  - import
  - pipeline
  - constraints
  - automation
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Project_Layout_Conventions]"
used_by:
  - "[Unity_Addressables_Strategy]]"
  - "[[Unity_Build_Automation]"
---

# Unity Asset Import Pipeline

The Asset Import Pipeline controls how external assets (models, textures, audio) are processed and imported into Unity. Proper configuration ensures consistent asset quality, optimal build sizes, and fast iteration times. This document defines import settings and constraints for Studio OS Unity projects.

## Import Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  ASSET IMPORT PIPELINE                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Source Asset → Importer → Processed Asset → Library Cache  │
│       │            │              │              │           │
│       ▼            ▼              ▼              ▼           │
│    (.fbx)    (Settings)    (.asset)      (Artifacts)        │
│    (.png)    (Presets)     (.prefab)     (Hash-based)       │
│    (.wav)    (Rules)       (.mat)                           │
│                                                              │
│  Triggers: Import, Reimport, Asset Change                   │
└─────────────────────────────────────────────────────────────┘
```

## Texture Import Settings

### Default Texture Preset

```csharp
// Assets/Editor/TextureImportPreset.preset
public class TextureImportRules : AssetPostprocessor
{
    void OnPreprocessTexture()
    {
        TextureImporter importer = assetImporter as TextureImporter;
        
        // Apply based on path
        if (assetPath.Contains("/UI/"))
        {
            ConfigureForUI(importer);
        }
        else if (assetPath.Contains("/Sprites/"))
        {
            ConfigureForSprite(importer);
        }
        else if (assetPath.Contains("/Environment/"))
        {
            ConfigureForEnvironment(importer);
        }
        else if (assetPath.Contains("/Characters/"))
        {
            ConfigureForCharacter(importer);
        }
    }

    private void ConfigureForUI(TextureImporter importer)
    {
        importer.textureType = TextureImporterType.Sprite;
        importer.spritePixelsPerUnit = 100;
        importer.filterMode = FilterMode.Point; // Pixel-perfect UI
        importer.textureCompression = TextureImporterCompression.Uncompressed;
        importer.mipmapEnabled = false;
        importer.maxTextureSize = 1024;
    }

    private void ConfigureForSprite(TextureImporter importer)
    {
        importer.textureType = TextureImporterType.Sprite;
        importer.spriteImportMode = SpriteImportMode.Single;
        importer.filterMode = FilterMode.Bilinear;
        importer.textureCompression = TextureImporterCompression.Compressed;
        importer.compressionQuality = 100;
        importer.mipmapEnabled = true;
        importer.maxTextureSize = 2048;
    }

    private void ConfigureForEnvironment(TextureImporter importer)
    {
        importer.textureType = TextureImporterType.Default;
        importer.filterMode = FilterMode.Trilinear;
        importer.textureCompression = TextureImporterCompression.Compressed;
        importer.compressionQuality = 75;
        importer.mipmapEnabled = true;
        importer.maxTextureSize = 4096;
    }

    private void ConfigureForCharacter(TextureImporter importer)
    {
        importer.textureType = TextureImporterType.Default;
        importer.filterMode = FilterMode.Bilinear;
        importer.textureCompression = TextureImporterCompression.Compressed;
        importer.compressionQuality = 100;
        importer.mipmapEnabled = true;
        importer.maxTextureSize = 2048;
    }
}
```

### Platform Overrides

```csharp
private void ApplyPlatformSettings(TextureImporter importer)
{
    // PC/Console - high quality
    var pcSettings = new TextureImporterPlatformSettings
    {
        name = "Standalone",
        overridden = true,
        maxTextureSize = 4096,
        format = TextureImporterFormat.DXT5,
        compressionQuality = 100
    };
    importer.SetPlatformTextureSettings(pcSettings);

    // WebGL - optimized
    var webglSettings = new TextureImporterPlatformSettings
    {
        name = "WebGL",
        overridden = true,
        maxTextureSize = 2048,
        format = TextureImporterFormat.DXT5,
        compressionQuality = 75
    };
    importer.SetPlatformTextureSettings(webglSettings);
}
```

## Model Import Settings

### FBX Import Rules

```csharp
public class ModelImportRules : AssetPostprocessor
{
    void OnPreprocessModel()
    {
        ModelImporter importer = assetImporter as ModelImporter;
        
        // Default settings
        importer.materialImportMode = ModelImporterMaterialImportMode.None;
        importer.animationType = ModelImporterAnimationType.Generic;
        importer.avatarSetup = ModelImporterAvatarSetup.NoAvatar;
        
        // Optimize mesh
        importer.meshOptimizationFlags = MeshOptimizationFlags.Everything;
        
        // Apply based on path
        if (assetPath.Contains("/Characters/"))
        {
            ConfigureForCharacter(importer);
        }
        else if (assetPath.Contains("/Environment/"))
        {
            ConfigureForEnvironment(importer);
        }
        else if (assetPath.Contains("/Props/"))
        {
            ConfigureForProp(importer);
        }
    }

    private void ConfigureForCharacter(ModelImporter importer)
    {
        importer.animationType = ModelImporterAnimationType.Human;
        importer.avatarSetup = ModelImporterAvatarSetup.CreateFromThisModel;
        importer.optimizeGameObjects = true;
        importer.importBlendShapes = true;
        importer.importCameras = false;
        importer.importLights = false;
    }

    private void ConfigureForEnvironment(ModelImporter importer)
    {
        importer.animationType = ModelImporterAnimationType.None;
        importer.generateColliders = true;
        importer.importCameras = false;
        importer.importLights = false;
    }

    private void ConfigureForProp(ModelImporter importer)
    {
        importer.animationType = ModelImporterAnimationType.None;
        importer.generateColliders = true;
        importer.importCameras = false;
        importer.importLights = false;
    }

    void OnPostprocessModel(GameObject go)
    {
        // Validate mesh
        var meshFilter = go.GetComponentInChildren<MeshFilter>();
        if (meshFilter != null)
        {
            var mesh = meshFilter.sharedMesh;
            ValidateMesh(mesh, assetPath);
        }
    }

    private void ValidateMesh(Mesh mesh, string path)
    {
        // Check vertex count
        if (mesh.vertexCount > 65535)
        {
            Debug.LogWarning($"Mesh {path} exceeds 65k vertices: {mesh.vertexCount}");
        }

        // Check for missing normals
        if (mesh.normals.Length == 0)
        {
            Debug.LogWarning($"Mesh {path} missing normals");
        }

        // Check for missing UVs
        if (mesh.uv.Length == 0)
        {
            Debug.LogWarning($"Mesh {path} missing UVs");
        }
    }
}
```

## Audio Import Settings

### Audio Import Rules

```csharp
public class AudioImportRules : AssetPostprocessor
{
    void OnPreprocessAudio()
    {
        AudioImporter importer = assetImporter as AudioImporter;
        
        if (assetPath.Contains("/Music/"))
        {
            ConfigureForMusic(importer);
        }
        else if (assetPath.Contains("/SFX/"))
        {
            ConfigureForSFX(importer);
        }
        else if (assetPath.Contains("/Ambient/"))
        {
            ConfigureForAmbient(importer);
        }
    }

    private void ConfigureForMusic(AudioImporter importer)
    {
        importer.forceToMono = false;
        importer.loadInBackground = true;
        importer.preloadAudioData = false;
        importer.ambisonic = false;
        
        var settings = new AudioImporterSampleSettings
        {
            loadType = AudioClipLoadType.Streaming,
            compressionFormat = AudioCompressionFormat.Vorbis,
            quality = 0.7f,
            sampleRateSetting = AudioSampleRateSetting.OptimizeSampleRate
        };
        importer.defaultSampleSettings = settings;
    }

    private void ConfigureForSFX(AudioImporter importer)
    {
        importer.forceToMono = true;
        importer.loadInBackground = false;
        importer.preloadAudioData = true;
        
        var settings = new AudioImporterSampleSettings
        {
            loadType = AudioClipLoadType.DecompressOnLoad,
            compressionFormat = AudioCompressionFormat.ADPCM,
            sampleRateSetting = AudioSampleRateSetting.OptimizeSampleRate
        };
        importer.defaultSampleSettings = settings;
    }

    private void ConfigureForAmbient(AudioImporter importer)
    {
        importer.forceToMono = false;
        importer.loadInBackground = true;
        importer.preloadAudioData = false;
        
        var settings = new AudioImporterSampleSettings
        {
            loadType = AudioClipLoadType.CompressedInMemory,
            compressionFormat = AudioCompressionFormat.Vorbis,
            quality = 0.5f,
            sampleRateSetting = AudioSampleRateSetting.OptimizeSampleRate
        };
        importer.defaultSampleSettings = settings;
    }
}
```

## Import Constraints

### Size Limits

| Asset Type | Max Size | Action on Exceed |
|------------|----------|-----------------|
| Texture | 4096x4096 | Warning + downscale |
| Mesh vertices | 65,535 | Error + block |
| Mesh submeshes | 1 | Warning |
| Audio length (SFX) | 10s | Warning |
| Audio length (Music) | 600s | Warning |

### Validation Rules

```csharp
public class AssetValidation
{
    public static bool ValidateTexture(Texture2D texture, string path)
    {
        bool valid = true;

        // Check power of 2
        if (!Mathf.IsPowerOfTwo(texture.width) || !Mathf.IsPowerOfTwo(texture.height))
        {
            Debug.LogWarning($"Texture {path} not power of 2: {texture.width}x{texture.height}");
            valid = false;
        }

        // Check max size
        if (texture.width > 4096 || texture.height > 4096)
        {
            Debug.LogError($"Texture {path} exceeds max size: {texture.width}x{texture.height}");
            valid = false;
        }

        return valid;
    }

    public static bool ValidateMesh(Mesh mesh, string path)
    {
        bool valid = true;

        // Check vertex count
        if (mesh.vertexCount > 65535)
        {
            Debug.LogError($"Mesh {path} exceeds vertex limit: {mesh.vertexCount}");
            valid = false;
        }

        // Check for degenerate triangles
        // ... validation logic

        return valid;
    }
}
```

## Preset System

### Creating Import Presets

```csharp
// Create preset from configured importer
[MenuItem("Assets/Create/Preset/Texture Preset")]
static void CreateTexturePreset()
{
    var preset = new TextureImporter();
    ConfigureTexturePreset(preset);
    
    Preset presetAsset = new Preset(preset);
    AssetDatabase.CreateAsset(presetAsset, "Assets/Editor/Presets/Texture_Default.preset");
}
```

### Applying Presets

```csharp
public class PresetApplier : AssetPostprocessor
{
    void OnPreprocessAsset()
    {
        // Load preset based on asset type
        Preset preset = LoadPresetForAsset(assetPath);
        if (preset != null)
        {
            preset.ApplyTo(assetImporter);
        }
    }

    private Preset LoadPresetForAsset(string path)
    {
        if (path.EndsWith(".png") || path.EndsWith(".jpg"))
        {
            return AssetDatabase.LoadAssetAtPath<Preset>(
                "Assets/Editor/Presets/Texture_Default.preset");
        }
        // ... other types
        return null;
    }
}
```

## Batch Processing

### Reimport All Assets

```csharp
public class BatchAssetProcessor
{
    [MenuItem("Tools/Assets/Reimport All with Rules")]
    static void ReimportAll()
    {
        string[] assetGuids = AssetDatabase.FindAssets("t:Texture2D t:Model t:AudioClip",
            new[] { "Assets/_Project" });

        foreach (string guid in assetGuids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
        }

        Debug.Log($"Reimported {assetGuids.Length} assets");
    }
}
```

## CI Integration

### Import Validation

```bash
# Validate all assets in CI
unity -batchmode -executeMethod AssetValidation.ValidateAllAssets
```

```csharp
public class AssetValidation
{
    public static void ValidateAllAssets()
    {
        bool hasErrors = false;

        // Validate textures
        string[] textureGuids = AssetDatabase.FindAssets("t:Texture2D");
        foreach (string guid in textureGuids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
            if (!ValidateTexture(texture, path))
            {
                hasErrors = true;
            }
        }

        // Validate meshes
        // ... similar for other types

        if (hasErrors)
        {
            EditorApplication.Exit(1);
        }
    }
}
```

## Enforcement

### CI Gates
- Import validation passes
- No oversized assets
- All assets have proper settings

### Editor Warnings
- Real-time validation on import
- Warnings for suboptimal settings

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Asset exceeds size limit | Error | Block commit |
| Missing import settings | Warning | Auto-apply preset |
| Suboptimal compression | Warning | Suggest optimization |
