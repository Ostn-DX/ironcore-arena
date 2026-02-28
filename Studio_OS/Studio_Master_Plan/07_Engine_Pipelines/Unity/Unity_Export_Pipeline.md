---
title: Unity Export Pipeline
type: pipeline
layer: execution
status: active
tags:
  - unity
  - export
  - deployment
  - distribution
  - packaging
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Build_Automation]"
used_by:
  - "[Unity_Steam_Build_Packaging]]"
  - "[[Unity_CI_Template]"
---

# Unity Export Pipeline

The export pipeline handles the final packaging and distribution of Unity builds. This document defines the export workflow for Studio OS Unity projects, including artifact generation, versioning, and deployment preparation.

## Export Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    EXPORT PIPELINE ARCHITECTURE              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Build Output → Process → Package → Validate → Distribute   │
│       │            │          │         │           │        │
│       ▼            ▼          ▼         ▼           ▼        │
│  ┌────────┐   ┌────────┐  ┌────────┐ ┌────────┐ ┌────────┐ │
│  │  Raw   │   │ Strip  │  │  ZIP   │ │ Check  │ │ Upload │ │
│  │ Build  │   │ Debug  │  │ Installer││  Sum   │ │  CDN   │ │
│  │        │   │ Symbols│  │  Steam │ │  Test  │ │ Store  │ │
│  └────────┘   └────────┘  └────────┘ └────────┘ └────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Export Script

```csharp
// Assets/Editor/Export/ExportPipeline.cs
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;

namespace StudioOS.Editor.Export
{
    public static class ExportPipeline
    {
        public const string EXPORT_BASE_PATH = "Exports";
        
        [MenuItem("Export/Windows/Full Package")]
        public static void ExportWindowsFullPackage()
        {
            var config = new ExportConfig
            {
                Platform = BuildTarget.StandaloneWindows64,
                SourcePath = "Builds/Windows/Production",
                ExportName = $"Game-Windows-{GetVersionString()}",
                IncludePDB = false,
                CreateInstaller = false
            };
            
            ExportPackage(config);
        }

        [MenuItem("Export/Windows/With Symbols")]
        public static void ExportWindowsWithSymbols()
        {
            var config = new ExportConfig
            {
                Platform = BuildTarget.StandaloneWindows64,
                SourcePath = "Builds/Windows/Production",
                ExportName = $"Game-Windows-{GetVersionString()}-WithSymbols",
                IncludePDB = true,
                CreateInstaller = false
            };
            
            ExportPackage(config);
        }

        [MenuItem("Export/macOS/Full Package")]
        public static void ExportMacOSFullPackage()
        {
            var config = new ExportConfig
            {
                Platform = BuildTarget.StandaloneOSX,
                SourcePath = "Builds/macOS/Production/Game.app",
                ExportName = $"Game-macOS-{GetVersionString()}",
                IncludePDB = false,
                CreateInstaller = true
            };
            
            ExportPackage(config);
        }

        [MenuItem("Export/Linux/Full Package")]
        public static void ExportLinuxFullPackage()
        {
            var config = new ExportConfig
            {
                Platform = BuildTarget.StandaloneLinux64,
                SourcePath = "Builds/Linux/Production",
                ExportName = $"Game-Linux-{GetVersionString()}",
                IncludePDB = false,
                CreateInstaller = false
            };
            
            ExportPackage(config);
        }

        [MenuItem("Export/WebGL/Full Package")]
        public static void ExportWebGLFullPackage()
        {
            var config = new ExportConfig
            {
                Platform = BuildTarget.WebGL,
                SourcePath = "Builds/WebGL/Production",
                ExportName = $"Game-WebGL-{GetVersionString()}",
                IncludePDB = false,
                CreateInstaller = false
            };
            
            ExportPackage(config);
        }

        [MenuItem("Export/All Platforms")]
        public static void ExportAllPlatforms()
        {
            ExportWindowsFullPackage();
            ExportMacOSFullPackage();
            ExportLinuxFullPackage();
        }

        public static void ExportPackage(ExportConfig config)
        {
            try
            {
                Debug.Log($"Starting export: {config.ExportName}");

                // Validate source
                if (!Directory.Exists(config.SourcePath))
                {
                    throw new DirectoryNotFoundException(
                        $"Source path not found: {config.SourcePath}");
                }

                // Create export directory
                string exportDir = Path.Combine(EXPORT_BASE_PATH, config.ExportName);
                Directory.CreateDirectory(exportDir);

                // Copy build files
                CopyBuildFiles(config, exportDir);

                // Process files
                ProcessFiles(config, exportDir);

                // Create package
                string packagePath = CreatePackage(config, exportDir);

                // Generate checksums
                GenerateChecksums(packagePath);

                // Create manifest
                CreateExportManifest(config, packagePath);

                // Cleanup temp directory
                Directory.Delete(exportDir, true);

                Debug.Log($"Export complete: {packagePath}");
            }
            catch (Exception ex)
            {
                Debug.LogError($"Export failed: {ex.Message}");
                throw;
            }
        }

        private static void CopyBuildFiles(ExportConfig config, string exportDir)
        {
            Debug.Log("Copying build files...");

            if (config.Platform == BuildTarget.StandaloneOSX)
            {
                // macOS .app bundle - copy entire directory
                CopyDirectory(config.SourcePath, exportDir);
            }
            else
            {
                // Copy all files from source
                foreach (string file in Directory.GetFiles(config.SourcePath, "*", SearchOption.AllDirectories))
                {
                    string relativePath = file.Substring(config.SourcePath.Length + 1);
                    string destPath = Path.Combine(exportDir, relativePath);
                    
                    Directory.CreateDirectory(Path.GetDirectoryName(destPath));
                    File.Copy(file, destPath, true);
                }
            }
        }

        private static void ProcessFiles(ExportConfig config, string exportDir)
        {
            Debug.Log("Processing files...");

            // Remove debug files if not included
            if (!config.IncludePDB)
            {
                RemoveDebugFiles(exportDir);
            }

            // Remove development files
            RemoveDevelopmentFiles(exportDir);

            // Platform-specific processing
            switch (config.Platform)
            {
                case BuildTarget.StandaloneWindows64:
                    ProcessWindowsFiles(exportDir);
                    break;
                case BuildTarget.StandaloneOSX:
                    ProcessMacOSFiles(exportDir);
                    break;
                case BuildTarget.StandaloneLinux64:
                    ProcessLinuxFiles(exportDir);
                    break;
            }
        }

        private static void RemoveDebugFiles(string exportDir)
        {
            // Remove PDB files
            foreach (string pdb in Directory.GetFiles(exportDir, "*.pdb", SearchOption.AllDirectories))
            {
                File.Delete(pdb);
            }

            // Remove MDB files
            foreach (string mdb in Directory.GetFiles(exportDir, "*.mdb", SearchOption.AllDirectories))
            {
                File.Delete(mdb);
            }
        }

        private static void RemoveDevelopmentFiles(string exportDir)
        {
            // Remove empty directories
            RemoveEmptyDirectories(exportDir);
        }

        private static void ProcessWindowsFiles(string exportDir)
        {
            // Windows-specific processing
            // Ensure .exe has proper naming
            string exePath = Directory.GetFiles(exportDir, "*.exe").FirstOrDefault();
            if (exePath != null)
            {
                string newExePath = Path.Combine(exportDir, "Game.exe");
                if (exePath != newExePath)
                {
                    File.Move(exePath, newExePath);
                }
            }
        }

        private static void ProcessMacOSFiles(string exportDir)
        {
            // macOS-specific processing
            // Set executable permissions
            string macOSDir = Path.Combine(exportDir, "Contents", "MacOS");
            if (Directory.Exists(macOSDir))
            {
                foreach (string file in Directory.GetFiles(macOSDir))
                {
                    // In CI, use chmod
                    Debug.Log($"Setting executable permissions for: {file}");
                }
            }
        }

        private static void ProcessLinuxFiles(string exportDir)
        {
            // Linux-specific processing
            // Set executable permissions
            string exePath = Directory.GetFiles(exportDir).FirstOrDefault();
            if (exePath != null)
            {
                Debug.Log($"Setting executable permissions for: {exePath}");
            }
        }

        private static string CreatePackage(ExportConfig config, string exportDir)
        {
            Debug.Log("Creating package...");

            string packagePath = Path.Combine(EXPORT_BASE_PATH, $"{config.ExportName}.zip");

            if (File.Exists(packagePath))
            {
                File.Delete(packagePath);
            }

            ZipFile.CreateFromDirectory(exportDir, packagePath, CompressionLevel.Optimal, false);

            return packagePath;
        }

        private static void GenerateChecksums(string packagePath)
        {
            Debug.Log("Generating checksums...");

            string checksumPath = packagePath + ".sha256";
            
            using (var sha256 = SHA256.Create())
            using (var stream = File.OpenRead(packagePath))
            {
                byte[] hash = sha256.ComputeHash(stream);
                string hashString = BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
                File.WriteAllText(checksumPath, hashString);
            }
        }

        private static void CreateExportManifest(ExportConfig config, string packagePath)
        {
            Debug.Log("Creating export manifest...");

            var manifest = new ExportManifest
            {
                ExportName = config.ExportName,
                Platform = config.Platform.ToString(),
                Version = GetVersionString(),
                ExportTime = DateTime.UtcNow.ToString("O"),
                PackageSize = new FileInfo(packagePath).Length,
                PackageName = Path.GetFileName(packagePath),
                Checksum = File.ReadAllText(packagePath + ".sha256")
            };

            string manifestPath = packagePath + ".json";
            string json = JsonUtility.ToJson(manifest, true);
            File.WriteAllText(manifestPath, json);
        }

        private static void CopyDirectory(string sourceDir, string destDir)
        {
            Directory.CreateDirectory(destDir);

            foreach (string file in Directory.GetFiles(sourceDir))
            {
                string destFile = Path.Combine(destDir, Path.GetFileName(file));
                File.Copy(file, destFile, true);
            }

            foreach (string subDir in Directory.GetDirectories(sourceDir))
            {
                string destSubDir = Path.Combine(destDir, Path.GetFileName(subDir));
                CopyDirectory(subDir, destSubDir);
            }
        }

        private static void RemoveEmptyDirectories(string directory)
        {
            foreach (string subDir in Directory.GetDirectories(directory))
            {
                RemoveEmptyDirectories(subDir);
                if (Directory.GetFiles(subDir).Length == 0 && 
                    Directory.GetDirectories(subDir).Length == 0)
                {
                    Directory.Delete(subDir);
                }
            }
        }

        private static string GetVersionString()
        {
            return PlayerSettings.bundleVersion.Replace(".", "-");
        }
    }

    public class ExportConfig
    {
        public BuildTarget Platform;
        public string SourcePath;
        public string ExportName;
        public bool IncludePDB;
        public bool CreateInstaller;
    }

    [Serializable]
    public class ExportManifest
    {
        public string ExportName;
        public string Platform;
        public string Version;
        public string ExportTime;
        public long PackageSize;
        public string PackageName;
        public string Checksum;
    }
}
```

## Deployment Preparation

### Upload Script

```csharp
public static class DeploymentUpload
{
    [MenuItem("Export/Upload to Staging")]
    public static void UploadToStaging()
    {
        string exportDir = ExportPipeline.EXPORT_BASE_PATH;
        // Upload to staging CDN
        Debug.Log($"Uploading from {exportDir} to staging...");
    }

    [MenuItem("Export/Upload to Production")]
    public static void UploadToProduction()
    {
        // Confirm production upload
        bool confirm = EditorUtility.DisplayDialog(
            "Upload to Production",
            "Are you sure you want to upload to production?",
            "Upload",
            "Cancel"
        );

        if (confirm)
        {
            string exportDir = ExportPipeline.EXPORT_BASE_PATH;
            Debug.Log($"Uploading from {exportDir} to production...");
        }
    }
}
```

## CI Integration

### Export in CI

```yaml
# .github/workflows/export.yml
name: Export

on:
  release:
    types: [published]

jobs:
  export:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Download Build Artifacts
        uses: actions/download-artifact@v3
        with:
          path: Builds
      
      - name: Export Windows
        run: |
          /Applications/Unity/Unity.app/Contents/MacOS/Unity \
            -batchmode \
            -executeMethod StudioOS.Editor.Export.ExportPipeline.ExportWindowsFullPackage
      
      - name: Upload to CDN
        run: |
          aws s3 sync Exports/ s3://studioos-cdn/releases/${{ github.ref_name }}/
```

## Enforcement

### CI Gates
- Export package created successfully
- Checksum generated
- Manifest complete
- Package size within limits

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Export failure | Error | Block release |
| Missing checksum | Error | Block release |
| Package >500MB | Warning | Review required |
