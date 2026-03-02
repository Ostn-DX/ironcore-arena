---
title: Unity Steam Build Packaging
type: pipeline
layer: execution
status: active
tags:
  - unity
  - steam
  - packaging
  - steamworks
  - distribution
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Build_Automation]]"
  - "[[Unity_Export_Pipeline]"
used_by:
  - "[Unity_CI_Template]"
---

# Unity Steam Build Packaging

Steam is a primary distribution platform for Studio OS Unity projects. This document defines the Steam-specific build packaging workflow, including Steamworks SDK integration, depot configuration, and build upload automation.

## Steam Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    STEAM BUILD ARCHITECTURE                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Unity Build → Steamworks Integration → SteamPipe → Steam   │
│       │              │                    │         │        │
│       ▼              ▼                    ▼         ▼        │
│  ┌────────┐   ┌──────────┐   ┌─────────┐  ┌──────────┐     │
│  │  Game  │   │  Steam   │   │  Depot  │  │  Steam   │     │
│  │ Build  │   │  Client  │   │ Config  │  │  Servers │     │
│  │        │   │  SDK     │   │         │  │          │     │
│  └────────┘   └──────────┘   └─────────┘  └──────────┘     │
│                                                              │
│  Steam Features: Achievements, Leaderboards, Cloud Save     │
│  Multiplayer: P2P, Dedicated Servers, Matchmaking           │
└─────────────────────────────────────────────────────────────┘
```

## Steamworks SDK Setup

### Package Installation

```json
// Packages/manifest.json
{
  "dependencies": {
    "com.rlabrecque.steamworks.net": "20.2.0"
  }
}
```

Or use the Steamworks.NET package from Package Manager:
- Window > Package Manager > Add package from git URL
- `https://github.com/rlabrecque/Steamworks.NET.git?path=/com.rlabrecque.steamworks.net`

### Steam Manager

```csharp
// Assets/_Project/Scripts/Runtime/Services/Steam/SteamManager.cs
using Steamworks;
using UnityEngine;

namespace StudioOS.Services.Steam
{
    public class SteamManager : MonoBehaviour
    {
        public static SteamManager Instance { get; private set; }
        
        [SerializeField] private uint _appId = 480; // Replace with your App ID
        
        private bool _initialized;
        
        public bool IsInitialized => _initialized;
        public string PlayerName => SteamClient.Name;
        public SteamId PlayerId => SteamClient.SteamId;
        
        private void Awake()
        {
            if (Instance != null)
            {
                Destroy(gameObject);
                return;
            }
            
            Instance = this;
            DontDestroyOnLoad(gameObject);
            
            InitializeSteam();
        }
        
        private void InitializeSteam()
        {
            try
            {
                SteamClient.Init(_appId);
                _initialized = true;
                
                Debug.Log($"Steam initialized: {PlayerName} ({PlayerId})");
                
                // Set rich presence
                SteamFriends.SetRichPresence("status", "In Main Menu");
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"Steam initialization failed: {ex.Message}");
                _initialized = false;
            }
        }
        
        private void Update()
        {
            if (_initialized)
            {
                SteamClient.RunCallbacks();
            }
        }
        
        private void OnDestroy()
        {
            if (_initialized)
            {
                SteamClient.Shutdown();
            }
        }
    }
}
```

## Steam Features Integration

### Achievements

```csharp
// Assets/_Project/Scripts/Runtime/Services/Steam/SteamAchievements.cs
using Steamworks;
using UnityEngine;

namespace StudioOS.Services.Steam
{
    public static class SteamAchievements
    {
        public static class AchievementIds
        {
            public const string FirstWin = "ACH_FIRST_WIN";
            public const string CompleteTutorial = "ACH_COMPLETE_TUTORIAL";
            public const string ReachLevel10 = "ACH_LEVEL_10";
            public const string CollectAllItems = "ACH_COLLECT_ALL";
        }
        
        public static void Unlock(string achievementId)
        {
            if (!SteamManager.Instance.IsInitialized)
                return;
                
            var achievement = new Achievement(achievementId);
            if (!achievement.State)
            {
                achievement.Trigger();
                Debug.Log($"Achievement unlocked: {achievementId}");
            }
        }
        
        public static void SetProgress(string achievementId, int current, int max)
        {
            if (!SteamManager.Instance.IsInitialized)
                return;
                
            var achievement = new Achievement(achievementId);
            achievement.IndicateProgress(current, max);
        }
        
        public static void ResetAll()
        {
            if (!SteamManager.Instance.IsInitialized)
                return;
                
            SteamUserStats.ResetAll(true);
            SteamUserStats.StoreStats();
        }
    }
}
```

### Cloud Save

```csharp
// Assets/_Project/Scripts/Runtime/Services/Steam/SteamCloudSave.cs
using Steamworks;
using UnityEngine;
using System.IO;

namespace StudioOS.Services.Steam
{
    public static class SteamCloudSave
    {
        private const string SAVE_FILE_NAME = "savegame.dat";
        
        public static void Save(byte[] data)
        {
            if (!SteamManager.Instance.IsInitialized)
                return;
                
            try
            {
                var remoteStorage = SteamRemoteStorage;
                remoteStorage.FileWrite(SAVE_FILE_NAME, data);
                Debug.Log("Game saved to Steam Cloud");
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"Steam Cloud save failed: {ex.Message}");
            }
        }
        
        public static byte[] Load()
        {
            if (!SteamManager.Instance.IsInitialized)
                return null;
                
            try
            {
                var remoteStorage = SteamRemoteStorage;
                if (remoteStorage.FileExists(SAVE_FILE_NAME))
                {
                    var data = remoteStorage.FileRead(SAVE_FILE_NAME);
                    Debug.Log("Game loaded from Steam Cloud");
                    return data;
                }
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"Steam Cloud load failed: {ex.Message}");
            }
            
            return null;
        }
        
        public static void Delete()
        {
            if (!SteamManager.Instance.IsInitialized)
                return;
                
            SteamRemoteStorage.FileDelete(SAVE_FILE_NAME);
        }
        
        public static bool HasSaveFile()
        {
            if (!SteamManager.Instance.IsInitialized)
                return false;
                
            return SteamRemoteStorage.FileExists(SAVE_FILE_NAME);
        }
    }
}
```

### Leaderboards

```csharp
// Assets/_Project/Scripts/Runtime/Services/Steam/SteamLeaderboards.cs
using Steamworks;
using UnityEngine;
using System.Threading.Tasks;

namespace StudioOS.Services.Steam
{
    public static class SteamLeaderboards
    {
        private const string HIGH_SCORE_BOARD = "HighScores";
        
        public static async Task UploadScore(int score)
        {
            if (!SteamManager.Instance.IsInitialized)
                return;
                
            var leaderboard = await SteamUserStats.FindLeaderboardAsync(HIGH_SCORE_BOARD);
            if (leaderboard.HasValue)
            {
                await leaderboard.Value.SubmitScoreAsync(score);
                Debug.Log($"Score uploaded: {score}");
            }
        }
        
        public static async Task<LeaderboardEntry[]> GetTopScores(int count = 10)
        {
            if (!SteamManager.Instance.IsInitialized)
                return null;
                
            var leaderboard = await SteamUserStats.FindLeaderboardAsync(HIGH_SCORE_BOARD);
            if (leaderboard.HasValue)
            {
                var entries = await leaderboard.Value.GetScoresAsync(count);
                return entries;
            }
            
            return null;
        }
        
        public static async Task<LeaderboardEntry?> GetPlayerScore()
        {
            if (!SteamManager.Instance.IsInitialized)
                return null;
                
            var leaderboard = await SteamUserStats.FindLeaderboardAsync(HIGH_SCORE_BOARD);
            if (leaderboard.HasValue)
            {
                var entry = await leaderboard.Value.GetScoreAsync();
                return entry;
            }
            
            return null;
        }
    }
}
```

## Steam Build Configuration

### App ID Configuration

```csharp
// Assets/StreamingAssets/steam_appid.txt
// Content: 480 (replace with your App ID)
```

### Build Script

```csharp
// Assets/Editor/Steam/SteamBuild.cs
using UnityEditor;
using UnityEngine;
using System.Diagnostics;
using System.IO;

namespace StudioOS.Editor.Steam
{
    public static class SteamBuild
    {
        private const string STEAMCMD_PATH = "C:/steamcmd/steamcmd.exe";
        private const string BUILD_SCRIPT_PATH = "BuildScripts/app_build.vdf";
        
        [MenuItem("Steam/Build and Upload")]
        public static void BuildAndUpload()
        {
            // Build for all platforms
            BuildAutomation.BuildAllPlatforms();
            
            // Create Steam build
            CreateSteamBuild();
            
            // Upload to Steam
            UploadToSteam();
        }
        
        [MenuItem("Steam/Upload Only")]
        public static void UploadOnly()
        {
            UploadToSteam();
        }
        
        private static void CreateSteamBuild()
        {
            // Copy builds to Steam content folder
            string contentPath = "SteamContent";
            Directory.CreateDirectory(contentPath);
            
            // Windows
            CopyBuildFiles("Builds/Windows/Production", $"{contentPath}/win64");
            
            // macOS
            CopyBuildFiles("Builds/macOS/Production", $"{contentPath}/osx");
            
            // Linux
            CopyBuildFiles("Builds/Linux/Production", $"{contentPath}/linux");
        }
        
        private static void UploadToSteam()
        {
            var process = new Process();
            process.StartInfo.FileName = STEAMCMD_PATH;
            process.StartInfo.Arguments = $"+login {GetUsername()} {GetPassword()} +run_app_build {BUILD_SCRIPT_PATH} +quit";
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;
            
            process.Start();
            string output = process.StandardOutput.ReadToEnd();
            string error = process.StandardError.ReadToEnd();
            process.WaitForExit();
            
            if (process.ExitCode != 0)
            {
                UnityEngine.Debug.LogError($"Steam upload failed: {error}");
            }
            else
            {
                UnityEngine.Debug.Log("Steam upload complete");
            }
        }
        
        private static void CopyBuildFiles(string source, string destination)
        {
            if (Directory.Exists(source))
            {
                Directory.CreateDirectory(destination);
                
                foreach (string file in Directory.GetFiles(source, "*", SearchOption.AllDirectories))
                {
                    string relativePath = file.Substring(source.Length + 1);
                    string destPath = Path.Combine(destination, relativePath);
                    Directory.CreateDirectory(Path.GetDirectoryName(destPath));
                    File.Copy(file, destPath, true);
                }
            }
        }
        
        private static string GetUsername()
        {
            // Get from environment variable or secure storage
            return System.Environment.GetEnvironmentVariable("STEAM_USERNAME");
        }
        
        private static string GetPassword()
        {
            // Get from environment variable or secure storage
            return System.Environment.GetEnvironmentVariable("STEAM_PASSWORD");
        }
    }
}
```

## SteamPipe Configuration

### App Build Script (app_build.vdf)

```vdf
"AppBuild"
{
    "AppID" "480" // Your App ID
    "Desc" "Your build description here"
    
    "ContentRoot" "..\SteamContent\" 
    "BuildOutput" "..\SteamBuildOutput\" 
    "Depots"
    {
        "1001" // Windows Depot
        {
            "FileMapping"
            {
                "LocalPath" "win64\*"
                "DepotPath" "."
                "recursive" "1"
            }
        }
        "1002" // macOS Depot
        {
            "FileMapping"
            {
                "LocalPath" "osx\*"
                "DepotPath" "."
                "recursive" "1"
            }
        }
        "1003" // Linux Depot
        {
            "FileMapping"
            {
                "LocalPath" "linux\*"
                "DepotPath" "."
                "recursive" "1"
            }
        }
    }
}
```

### Depot Configuration

| Depot ID | Platform | Content |
|----------|----------|---------|
| 1001 | Windows | `SteamContent/win64/*` |
| 1002 | macOS | `SteamContent/osx/*` |
| 1003 | Linux | `SteamContent/linux/*` |
| 1004 | Shared | Cross-platform content |

## CI Integration

### GitHub Actions for Steam

```yaml
# .github/workflows/steam.yml
name: Steam Build

on:
  release:
    types: [published]

jobs:
  steam-build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Cache Library
        uses: actions/cache@v3
        with:
          path: Library
          key: Library-${{ hashFiles('Assets/**', 'Packages/**', 'ProjectSettings/**') }}
      
      - name: Build Unity Project
        uses: game-ci/unity-builder@v3
        with:
          targetPlatform: StandaloneWindows64
          buildMethod: BuildAutomation.BuildWindowsProduction
      
      - name: Setup SteamCMD
        uses: CyberAndrii/setup-steamcmd@v1
      
      - name: Upload to Steam
        env:
          STEAM_USERNAME: ${{ secrets.STEAM_USERNAME }}
          STEAM_PASSWORD: ${{ secrets.STEAM_PASSWORD }}
        run: |
          steamcmd +login $env:STEAM_USERNAME $env:STEAM_PASSWORD `
            +run_app_build BuildScripts/app_build.vdf `
            +quit
```

## Steam Deck Support

### Steam Input Configuration

```csharp
// Enable Steam Input for controller support
public static class SteamInputConfig
{
    public static void Initialize()
    {
        if (!SteamManager.Instance.IsInitialized)
            return;
            
        // Enable Steam Input
        SteamInput.Init();
        
        // Set action set
        var actionSet = SteamInput.GetActionSet("GameControls");
        actionSet.Activate();
    }
}
```

### Steam Deck Optimization

```csharp
// Detect Steam Deck
public static bool IsSteamDeck()
{
    if (!SteamManager.Instance.IsInitialized)
        return false;
        
    // Check for Steam Deck hardware
    return SteamUtils.IsSteamRunningOnSteamDeck();
}

// Adjust settings for Steam Deck
public static void ConfigureForSteamDeck()
{
    if (IsSteamDeck())
    {
        // Lower quality settings
        QualitySettings.SetQualityLevel(2); // Medium
        
        // Adjust resolution
        Screen.SetResolution(1280, 800, true);
        
        // Enable controller UI
        InputSystem.EnableDevice(Gamepad.current);
    }
}
```

## Enforcement

### CI Gates
- Steam build succeeds
- Steamworks integration tests pass
- Build uploaded to Steam

### Testing Requirements
- Test achievements in development
- Verify cloud save functionality
- Test on Steam Deck if applicable

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Steam build failure | Error | Block release |
| Steamworks init failure | Warning | Graceful degradation |
| Upload failure | Error | Retry + alert |
