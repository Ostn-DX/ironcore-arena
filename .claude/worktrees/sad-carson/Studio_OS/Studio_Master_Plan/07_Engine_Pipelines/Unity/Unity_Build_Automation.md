---
title: Unity Build Automation
type: pipeline
layer: execution
status: active
tags:
  - unity
  - build
  - automation
  - scripting
  - ci-cd
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Assembly_Definition_Strategy]"
used_by:
  - "[Unity_CI_Template]]"
  - "[[Unity_Export_Pipeline]"
---

# Unity Build Automation

Automated builds ensure consistent, reproducible outputs across environments. This document defines the build automation strategy for Studio OS Unity projects, including build scripts, versioning, and platform-specific configurations.

## Build Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   BUILD AUTOMATION ARCHITECTURE              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Trigger   │───▶│   Prepare   │───▶│   Compile   │     │
│  │             │    │             │    │             │     │
│  │ • Manual    │    │ • Version   │    │ • Scripts   │     │
│  │ • Scheduled │    │ • Clean     │    │ • Assets    │     │
│  │ • CI Hook   │    │ • Address.  │    │ • Bundles   │     │
│  └─────────────┘    └─────────────┘    └──────┬──────┘     │
│                                                │             │
│                       ┌────────────────────────┘             │
│                       ▼                                      │
│              ┌─────────────────┐                            │
│              │     Package     │                            │
│              │                 │                            │
│              │ • Windows (.exe)│                            │
│              │ • macOS (.app)  │                            │
│              │ • Linux         │                            │
│              │ • WebGL         │                            │
│              └─────────────────┘                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Build Scripts

### Main Build Script

```csharp
// Assets/Editor/Build/BuildAutomation.cs
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;
using System;
using System.IO;
using System.Linq;

namespace StudioOS.Editor.Build
{
    public static class BuildAutomation
    {
        // Build configurations
        public const string DEVELOPMENT_BUILD = "DEVELOPMENT_BUILD";
        public const string PRODUCTION_BUILD = "PRODUCTION_BUILD";
        
        // Exit codes
        public const int EXIT_SUCCESS = 0;
        public const int EXIT_FAILURE = 1;

        [MenuItem("Build/Windows/Development")]
        public static void BuildWindowsDevelopment()
        {
            var options = new BuildOptions
            {
                target = BuildTarget.StandaloneWindows64,
                locationPathName = "Builds/Windows/Dev/Game.exe",
                developmentBuild = true,
                scriptingDefines = new[] { DEVELOPMENT_BUILD, "DEBUG", "UNITY_ASSERTIONS" }
            };
            
            PerformBuild(options);
        }

        [MenuItem("Build/Windows/Production")]
        public static void BuildWindowsProduction()
        {
            var options = new BuildOptions
            {
                target = BuildTarget.StandaloneWindows64,
                locationPathName = "Builds/Windows/Production/Game.exe",
                developmentBuild = false,
                scriptingDefines = new[] { PRODUCTION_BUILD }
            };
            
            PerformBuild(options);
        }

        [MenuItem("Build/macOS/Development")]
        public static void BuildMacOSDevelopment()
        {
            var options = new BuildOptions
            {
                target = BuildTarget.StandaloneOSX,
                locationPathName = "Builds/macOS/Dev/Game.app",
                developmentBuild = true,
                scriptingDefines = new[] { DEVELOPMENT_BUILD }
            };
            
            PerformBuild(options);
        }

        [MenuItem("Build/Linux/Production")]
        public static void BuildLinuxProduction()
        {
            var options = new BuildOptions
            {
                target = BuildTarget.StandaloneLinux64,
                locationPathName = "Builds/Linux/Production/Game",
                developmentBuild = false,
                scriptingDefines = new[] { PRODUCTION_BUILD }
            };
            
            PerformBuild(options);
        }

        [MenuItem("Build/WebGL/Production")]
        public static void BuildWebGLProduction()
        {
            var options = new BuildOptions
            {
                target = BuildTarget.WebGL,
                locationPathName = "Builds/WebGL/Production",
                developmentBuild = false,
                scriptingDefines = new[] { PRODUCTION_BUILD }
            };
            
            PerformBuild(options);
        }

        [MenuItem("Build/All Platforms")]
        public static void BuildAllPlatforms()
        {
            BuildWindowsProduction();
            BuildMacOSDevelopment();
            BuildLinuxProduction();
        }

        private static void PerformBuild(BuildOptions options)
        {
            try
            {
                // Pre-build steps
                PreBuild(options);

                // Configure build player options
                var buildPlayerOptions = new BuildPlayerOptions
                {
                    scenes = GetEnabledScenes(),
                    locationPathName = options.locationPathName,
                    target = options.target,
                    options = options.developmentBuild 
                        ? BuildOptions.Development 
                        : BuildOptions.None
                };

                // Set scripting defines
                PlayerSettings.SetScriptingDefineSymbolsForGroup(
                    GetBuildTargetGroup(options.target),
                    string.Join(";", options.scriptingDefines)
                );

                // Perform build
                BuildReport report = BuildPipeline.BuildPlayer(buildPlayerOptions);
                BuildSummary summary = report.summary;

                // Report results
                if (summary.result == BuildResult.Succeeded)
                {
                    Debug.Log($"Build succeeded: {summary.totalSize / 1024 / 1024} MB");
                    PostBuild(options, report);
                }
                else
                {
                    Debug.LogError($"Build failed: {summary.result}");
                    EditorApplication.Exit(EXIT_FAILURE);
                }
            }
            catch (Exception ex)
            {
                Debug.LogError($"Build error: {ex.Message}");
                EditorApplication.Exit(EXIT_FAILURE);
            }
        }

        private static void PreBuild(BuildOptions options)
        {
            // Update version
            VersionManager.UpdateBuildVersion();
            
            // Build Addressables
            BuildAddressables();
            
            // Run tests
            if (!options.developmentBuild)
            {
                RunTests();
            }
            
            // Clean build directory
            CleanBuildDirectory(options.locationPathName);
        }

        private static void PostBuild(BuildOptions options, BuildReport report)
        {
            // Copy additional files
            CopyAdditionalFiles(options);
            
            // Generate build manifest
            GenerateBuildManifest(report);
            
            // Create archive
            CreateBuildArchive(options);
        }

        private static string[] GetEnabledScenes()
        {
            return EditorBuildSettings.scenes
                .Where(s => s.enabled)
                .Select(s => s.path)
                .ToArray();
        }

        private static BuildTargetGroup GetBuildTargetGroup(BuildTarget target)
        {
            return BuildPipeline.GetBuildTargetGroup(target);
        }

        private static void BuildAddressables()
        {
            Debug.Log("Building Addressables...");
            UnityEditor.AddressableAssets.BuildScriptPackedMode.BuildScriptPackedMode.Build();
        }

        private static void RunTests()
        {
            // Tests are run separately in CI
            Debug.Log("Skipping tests in build script (run in CI)");
        }

        private static void CleanBuildDirectory(string path)
        {
            string directory = Path.GetDirectoryName(path);
            if (Directory.Exists(directory))
            {
                Directory.Delete(directory, true);
            }
            Directory.CreateDirectory(directory);
        }

        private static void CopyAdditionalFiles(BuildOptions options)
        {
            // Copy README, LICENSE, etc.
            string buildDir = Path.GetDirectoryName(options.locationPathName);
            
            if (File.Exists("README.md"))
            {
                File.Copy("README.md", Path.Combine(buildDir, "README.txt"), true);
            }
        }

        private static void GenerateBuildManifest(BuildReport report)
        {
            var manifest = new BuildManifest
            {
                BuildTime = DateTime.UtcNow.ToString("O"),
                UnityVersion = Application.unityVersion,
                Platform = report.summary.platform.ToString(),
                TotalSize = report.summary.totalSize,
                Scenes = GetEnabledScenes()
            };

            string json = JsonUtility.ToJson(manifest, true);
            string manifestPath = Path.Combine(
                Path.GetDirectoryName(report.summary.outputPath),
                "build-manifest.json"
            );
            File.WriteAllText(manifestPath, json);
        }

        private static void CreateBuildArchive(BuildOptions options)
        {
            // Create ZIP archive for distribution
            string buildDir = Path.GetDirectoryName(options.locationPathName);
            string archiveName = $"Game-{options.target}-{DateTime.Now:yyyyMMdd-HHmmss}.zip";
            string archivePath = Path.Combine("Builds", archiveName);
            
            // Use system zip command or SharpZipLib
            System.Diagnostics.Process.Start("zip", $"-r \"{archivePath}\" \"{buildDir}\"");
        }
    }

    public class BuildOptions
    {
        public BuildTarget target;
        public string locationPathName;
        public bool developmentBuild;
        public string[] scriptingDefines;
    }

    [Serializable]
    public class BuildManifest
    {
        public string BuildTime;
        public string UnityVersion;
        public string Platform;
        public long TotalSize;
        public string[] Scenes;
    }
}
```

## Version Management

```csharp
// Assets/Editor/Build/VersionManager.cs
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Text.RegularExpressions;

namespace StudioOS.Editor.Build
{
    public static class VersionManager
    {
        private const string VERSION_FILE = "Assets/Resources/version.txt";
        
        [MenuItem("Build/Version/Update Build Number")]
        public static void UpdateBuildVersion()
        {
            // Parse current version
            Version currentVersion = ParseVersion(PlayerSettings.bundleVersion);
            
            // Increment build number
            Version newVersion = new Version(
                currentVersion.Major,
                currentVersion.Minor,
                currentVersion.Build + 1
            );
            
            // Update PlayerSettings
            PlayerSettings.bundleVersion = newVersion.ToString();
            PlayerSettings.Android.bundleVersionCode = newVersion.Build;
            PlayerSettings.iOS.buildNumber = newVersion.Build.ToString();
            
            // Save version file for runtime access
            SaveVersionFile(newVersion);
            
            Debug.Log($"Version updated: {currentVersion} -> {newVersion}");
        }

        [MenuItem("Build/Version/Set Version...")]
        public static void SetVersion()
        {
            string input = EditorUtility.DisplayDialog(
                "Set Version",
                $"Current version: {PlayerSettings.bundleVersion}\nEnter new version (MAJOR.MINOR.BUILD):",
                "Set",
                "Cancel"
            );
            
            if (input != null && Version.TryParse(input, out Version newVersion))
            {
                PlayerSettings.bundleVersion = newVersion.ToString();
                SaveVersionFile(newVersion);
                Debug.Log($"Version set to: {newVersion}");
            }
        }

        private static Version ParseVersion(string versionString)
        {
            if (Version.TryParse(versionString, out Version version))
            {
                return version;
            }
            return new Version(0, 0, 1);
        }

        private static void SaveVersionFile(Version version)
        {
            string directory = Path.GetDirectoryName(VERSION_FILE);
            if (!Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }
            
            File.WriteAllText(VERSION_FILE, version.ToString());
            AssetDatabase.Refresh();
        }

        public static string GetVersion()
        {
            return PlayerSettings.bundleVersion;
        }
    }
}
```

## Platform-Specific Settings

### Windows Build Settings

```csharp
public static class WindowsBuildSettings
{
    public static void Apply()
    {
        PlayerSettings.SetScriptingBackend(
            BuildTargetGroup.Standalone, 
            ScriptingImplementation.IL2CPP
        );
        PlayerSettings.SetArchitecture(BuildTargetGroup.Standalone, 1); // x86_64
        
        // Icon settings
        PlayerSettings.SetIconsForTargetGroup(
            BuildTargetGroup.Standalone,
            new[] { AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Art/Icons/icon.png") }
        );
    }
}
```

### macOS Build Settings

```csharp
public static class MacOSBuildSettings
{
    public static void Apply()
    {
        PlayerSettings.SetScriptingBackend(
            BuildTargetGroup.Standalone,
            ScriptingImplementation.IL2CPP
        );
        
        // Apple Silicon + Intel
        PlayerSettings.SetArchitecture(BuildTargetGroup.Standalone, 2); // ARM64 + x86_64
        
        // Signing (for distribution)
        PlayerSettings.macOS.buildNumber = VersionManager.GetVersion();
    }
}
```

## CI Integration

### Command Line Build

```bash
#!/bin/bash
# build.sh

UNITY_PATH="/Applications/Unity/Unity.app/Contents/MacOS/Unity"
PROJECT_PATH="$(pwd)"
BUILD_METHOD="StudioOS.Editor.Build.BuildAutomation.BuildWindowsProduction"

$UNITY_PATH \
  -batchmode \
  -nographics \
  -quit \
  -projectPath "$PROJECT_PATH" \
  -executeMethod "$BUILD_METHOD" \
  -logFile "build.log"

exit $?
```

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Cache Library
        uses: actions/cache@v3
        with:
          path: Library
          key: Library-${{ hashFiles('Assets/**', 'Packages/**', 'ProjectSettings/**') }}
      
      - name: Build Windows
        uses: game-ci/unity-builder@v3
        with:
          targetPlatform: StandaloneWindows64
          buildMethod: StudioOS.Editor.Build.BuildAutomation.BuildWindowsProduction
      
      - name: Upload Build
        uses: actions/upload-artifact@v3
        with:
          name: Windows-Build
          path: Builds/Windows
```

## Enforcement

### CI Gates
- Build succeeds for all platforms
- Build size within limits
- No build warnings (treated as errors)

### Build Metrics
- Track build duration
- Monitor build size trends
- Alert on significant increases

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Build failure | Error | Block merge |
| Build warning | Warning | Review required |
| Size increase >10% | Warning | Optimization required |
| Build time >30min | Warning | Investigate |
