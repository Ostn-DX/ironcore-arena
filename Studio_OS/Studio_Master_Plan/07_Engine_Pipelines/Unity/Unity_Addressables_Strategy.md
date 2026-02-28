---
title: Unity Addressables Strategy
type: rule
layer: architecture
status: active
tags:
  - unity
  - addressables
  - asset-bundles
  - loading
  - memory
  - dlc
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Asset_Import_Pipeline]"
used_by:
  - "[Unity_Build_Automation]]"
  - "[[Unity_Export_Pipeline]"
---

# Unity Addressables Strategy

Addressables is Unity's modern asset management system, replacing the legacy AssetBundle workflow. It provides runtime asset loading, memory management, and content delivery capabilities. This document defines the mandatory Addressables strategy for Studio OS Unity projects.

## Addressables Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  ADDRESSABLES ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Groups    │    │   Labels    │    │  Profiles   │     │
│  │             │    │             │    │             │     │
│  │ • Default   │    │ • Level_01  │    │ • Dev       │     │
│  │ • Characters│    │ • Level_02  │    │ • Staging   │     │
│  │ • UI        │    │ • Shared    │    │ • Production│     │
│  │ • Audio     │    │ • DLC       │    │             │     │
│  └──────┬──────┘    └─────────────┘    └─────────────┘     │
│         │                                                    │
│         ▼                                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Addressables Build Pipeline             │    │
│  │                                                      │    │
│  │  Assets → Catalog → Bundles → CDN/Local Storage     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  Runtime: Addressables.LoadAssetAsync<T>("key")             │
└─────────────────────────────────────────────────────────────┘
```

## Group Organization

### Required Groups

| Group | Purpose | Update Strategy |
|-------|---------|-----------------|
| `Default` | Core assets, always loaded | Cannot Change Post Release |
| `Characters` | Character prefabs, models | Can Change Post Release |
| `UI` | UI prefabs, sprites | Can Change Post Release |
| `Audio` | Music, SFX | Can Change Post Release |
| `Levels` | Level scenes, chunks | Can Change Post Release |
| `DLC` | Downloadable content | Can Change Post Release |

### Group Configuration

```
// Default Group Settings
Build Path: [UnityEngine.Application.streamingAssetsPath]/aa
Load Path: {UnityEngine.Application.streamingAssetsPath}/aa
Bundle Mode: Pack Together
Compression: LZ4
```

```
// Characters Group Settings
Build Path: [UnityEngine.Application.streamingAssetsPath]/aa/characters
Load Path: {UnityEngine.Application.streamingAssetsPath}/aa/characters
Bundle Mode: Pack Separately (one bundle per asset)
Compression: LZ4
```

## Addressable Keys

### Key Naming Convention

```
[Category]_[Name]_[Variant]

Examples:
- Character_Player_Default
- Character_Enemy_Goblin
- UI_MainMenu_Panel
- Audio_Music_MainTheme
- Level_Forest_01
- Level_Dungeon_BossRoom
```

### Key Constants

```csharp
public static class AddressableKeys
{
    // Characters
    public const string CharacterPlayer = "Character_Player_Default";
    public const string CharacterEnemyGoblin = "Character_Enemy_Goblin";
    
    // UI
    public const string UIMainMenu = "UI_MainMenu_Panel";
    public const string UIPauseMenu = "UI_PauseMenu_Panel";
    public const string UIHUD = "UI_HUD_Default";
    
    // Audio
    public const string AudioMusicMain = "Audio_Music_MainTheme";
    public const string AudioSFXClick = "Audio_SFX_UI_Click";
    
    // Levels
    public const string LevelForest01 = "Level_Forest_01";
    public const string LevelDungeonBoss = "Level_Dungeon_BossRoom";
}
```

## Loading Patterns

### Async Loading

```csharp
public class AssetLoader : MonoBehaviour
{
    private Dictionary<string, AsyncOperationHandle> _loadedAssets = new();

    public async Task<T> LoadAssetAsync<T>(string key) where T : Object
    {
        // Check if already loaded
        if (_loadedAssets.TryGetValue(key, out var existingHandle))
        {
            if (existingHandle.IsValid())
            {
                return existingHandle.Result as T;
            }
        }

        // Load asset
        var handle = Addressables.LoadAssetAsync<T>(key);
        var asset = await handle.Task;

        if (asset == null)
        {
            Debug.LogError($"Failed to load asset: {key}");
            return null;
        }

        _loadedAssets[key] = handle;
        return asset;
    }

    public void ReleaseAsset(string key)
    {
        if (_loadedAssets.TryGetValue(key, out var handle))
        {
            Addressables.Release(handle);
            _loadedAssets.Remove(key);
        }
    }

    public void ReleaseAll()
    {
        foreach (var handle in _loadedAssets.Values)
        {
            if (handle.IsValid())
            {
                Addressables.Release(handle);
            }
        }
        _loadedAssets.Clear();
    }
}
```

### Scene Loading

```csharp
public class SceneLoader : MonoBehaviour
{
    public async Task LoadSceneAsync(string sceneKey, LoadSceneMode mode = LoadSceneMode.Single)
    {
        var handle = Addressables.LoadSceneAsync(sceneKey, mode);
        await handle.Task;

        if (handle.Status != AsyncOperationStatus.Succeeded)
        {
            Debug.LogError($"Failed to load scene: {sceneKey}");
        }
    }
}
```

### Preloading

```csharp
public class PreloadManager : MonoBehaviour
{
    [SerializeField] private List<string> _preloadKeys = new();

    public async Task PreloadAssetsAsync(IProgress<float> progress = null)
    {
        int total = _preloadKeys.Count;
        int completed = 0;

        foreach (string key in _preloadKeys)
        {
            await AssetLoader.Instance.LoadAssetAsync<Object>(key);
            completed++;
            progress?.Report((float)completed / total);
        }
    }
}
```

## Memory Management

### Reference Counting

```csharp
public class ReferenceCountedAsset<T> where T : Object
{
    private T _asset;
    private AsyncOperationHandle _handle;
    private int _referenceCount;

    public ReferenceCountedAsset(T asset, AsyncOperationHandle handle)
    {
        _asset = asset;
        _handle = handle;
        _referenceCount = 1;
    }

    public T Asset => _asset;

    public void AddReference() => _referenceCount++;

    public void RemoveReference()
    {
        _referenceCount--;
        if (_referenceCount <= 0)
        {
            Addressables.Release(_handle);
        }
    }
}
```

### Memory Budget

```csharp
public class MemoryBudget
{
    // Maximum memory for addressable assets (MB)
    public const long MAX_MEMORY_MB = 512;

    public static bool CanLoadAsset(long estimatedSizeMB)
    {
        long currentUsage = GetCurrentMemoryUsage();
        return (currentUsage + estimatedSizeMB) <= MAX_MEMORY_MB;
    }

    private static long GetCurrentMemoryUsage()
    {
        return GC.GetTotalMemory(false) / (1024 * 1024);
    }
}
```

## Build Configuration

### Build Script

```csharp
public static class AddressablesBuild
{
    [MenuItem("Window/Asset Management/Addressables/Build All")]
    public static void BuildAll()
    {
        // Build player content
        AddressableAssetSettings.BuildPlayerContent();
        
        Debug.Log("Addressables build complete");
    }

    [MenuItem("Window/Asset Management/Addressables/Build for Platform")]
    public static void BuildForPlatform()
    {
        var settings = AddressableAssetSettingsDefaultObject.Settings;
        
        // Configure for current platform
        string buildPath = Path.Combine(
            Application.streamingAssetsPath, 
            "aa", 
            EditorUserBuildSettings.activeBuildTarget.ToString()
        );
        
        settings.BuildPath = buildPath;
        
        BuildAll();
    }
}
```

### Profile Configuration

| Profile | Build Path | Load Path | Use Case |
|---------|-----------|-----------|----------|
| `Dev` | `Library/com.unity.addressables/aa` | `{UnityEngine.Application.streamingAssetsPath}/aa` | Development |
| `Staging` | `ServerData/[BuildTarget]` | `https://cdn-staging.studioos.com/[BuildTarget]` | Testing |
| `Production` | `ServerData/[BuildTarget]` | `https://cdn.studioos.com/[BuildTarget]` | Live |

## Update Strategy

### Content Updates

```csharp
public class ContentUpdater : MonoBehaviour
{
    public async Task CheckForUpdates()
    {
        // Initialize Addressables
        await Addressables.InitializeAsync().Task;

        // Check for catalog update
        var checkHandle = Addressables.CheckForCatalogUpdates(false);
        var catalogs = await checkHandle.Task;

        if (catalogs.Count > 0)
        {
            Debug.Log($"Found {catalogs.Count} catalog updates");
            
            // Update catalogs
            var updateHandle = Addressables.UpdateCatalogs(catalogs, false);
            await updateHandle.Task;
            
            Debug.Log("Catalogs updated");
        }

        Addressables.Release(checkHandle);
    }
}
```

## CI Integration

### Build Pipeline

```yaml
# GitHub Actions step
- name: Build Addressables
  run: |
    /Applications/Unity/Unity.app/Contents/MacOS/Unity \
      -batchmode \
      -nographics \
      -executeMethod AddressablesBuild.BuildAll \
      -projectPath $(pwd)
```

### Validation

```csharp
public class AddressablesValidation
{
    [MenuItem("Tools/Addressables/Validate")]
    public static void Validate()
    {
        var settings = AddressableAssetSettingsDefaultObject.Settings;
        bool hasErrors = false;

        // Check for duplicate keys
        var keyCounts = new Dictionary<string, int>();
        foreach (var group in settings.groups)
        {
            foreach (var entry in group.entries)
            {
                string key = entry.address;
                if (keyCounts.ContainsKey(key))
                {
                    Debug.LogError($"Duplicate addressable key: {key}");
                    hasErrors = true;
                }
                keyCounts[key] = keyCounts.GetValueOrDefault(key) + 1;
            }
        }

        // Check for missing labels
        foreach (var group in settings.groups)
        {
            foreach (var entry in group.entries)
            {
                if (entry.labels.Count == 0)
                {
                    Debug.LogWarning($"Asset {entry.address} has no labels");
                }
            }
        }

        if (hasErrors)
        {
            throw new System.Exception("Addressables validation failed");
        }
    }
}
```

## Enforcement

### CI Gates
- Addressables build succeeds
- No duplicate keys
- All assets properly labeled
- Bundle size within limits

### Runtime Monitoring
- Track loaded assets
- Memory usage logging
- Load time metrics

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Duplicate key | Error | Block build |
| Missing label | Warning | Review required |
| Bundle >100MB | Warning | Split bundle |
| Load failure | Error | Fallback asset |
