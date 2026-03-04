---
title: Unity EditMode Test Framework
type: system
layer: execution
status: active
tags:
  - unity
  - testing
  - editmode
  - editor
  - nunit
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Assembly_Definition_Strategy]"
used_by:
  - "[Unity_CI_Template]]"
  - "[[Unity_Analyzers_Setup]"
---

# Unity EditMode Test Framework

EditMode tests execute in the Unity Editor environment without entering PlayMode. They provide fast feedback for editor tools, asset validation, and code structure verification. This framework defines the mandatory structure for editor testing in Studio OS Unity projects.

## Test Framework Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    EDITMODE TEST ARCHITECTURE                │
├─────────────────────────────────────────────────────────────┤
│  Test Runner → Test Assembly → Editor Assembly → Editor API │
├─────────────────────────────────────────────────────────────┤
│  Execution Context: EditMode (Editor Only)                   │
│  Framework: Unity Test Framework + NUnit                     │
│  Location: Assets/_Project/Tests/Editor/                     │
│  Speed: Fast (no scene load, no PlayMode)                    │
└─────────────────────────────────────────────────────────────┘
```

## Test Assembly Setup

### Test Assembly Definition

**Location**: `Assets/_Project/Tests/Editor/Tests.Editor.asmdef`

```json
{
    "name": "Tests.Editor",
    "rootNamespace": "StudioOS.Tests.Editor",
    "references": [
        "Core",
        "Gameplay",
        "UI",
        "Services",
        "Editor",
        "UnityEngine.TestRunner",
        "UnityEditor.TestRunner"
    ],
    "includePlatforms": ["Editor"],
    "excludePlatforms": [],
    "allowUnsafeCode": false,
    "overrideReferences": true,
    "precompiledReferences": [
        "nunit.framework.dll"
    ],
    "autoReferenced": false,
    "defineConstraints": [
        "UNITY_INCLUDE_TESTS"
    ],
    "versionDefines": [],
    "noEngineReferences": false
}
```

## Test Categories

### 1. Asset Validation Tests

Validate asset integrity and conventions:

```csharp
using NUnit.Framework;
using UnityEditor;
using UnityEngine;

namespace StudioOS.Tests.Editor.Validation
{
    public class AssetValidationTests
    {
        [Test]
        public void AllPrefabs_HaveRequiredComponents()
        {
            // Arrange
            string[] prefabGuids = AssetDatabase.FindAssets("t:Prefab", 
                new[] { "Assets/_Project/Prefabs" });
            
            // Act & Assert
            foreach (string guid in prefabGuids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                
                // Validate required components
                Assert.IsNotNull(prefab.GetComponent<EntityID>(), 
                    $"Prefab {path} missing EntityID");
            }
        }

        [Test]
        public void AllMaterials_UseCorrectShader()
        {
            string[] materialGuids = AssetDatabase.FindAssets("t:Material");
            
            foreach (string guid in materialGuids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                Material material = AssetDatabase.LoadAssetAtPath<Material>(path);
                
                Assert.IsTrue(
                    material.shader.name.StartsWith("StudioOS/"),
                    $"Material {path} uses non-project shader: {material.shader.name}"
                );
            }
        }

        [Test]
        public void AllTextures_HaveCorrectImportSettings()
        {
            string[] textureGuids = AssetDatabase.FindAssets("t:Texture2D",
                new[] { "Assets/_Project/Art/Textures" });
            
            foreach (string guid in textureGuids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
                
                Assert.IsNotNull(importer);
                Assert.AreEqual(TextureImporterType.Sprite, importer.textureType,
                    $"Texture {path} should be Sprite type");
            }
        }
    }
}
```

### 2. Code Structure Tests

Validate code organization:

```csharp
public class CodeStructureTests
{
    [Test]
    public void AllScripts_InCorrectNamespace()
    {
        string[] scriptGuids = AssetDatabase.FindAssets("t:MonoScript",
            new[] { "Assets/_Project/Scripts" });
        
        foreach (string guid in scriptGuids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            MonoScript script = AssetDatabase.LoadAssetAtPath<MonoScript>(path);
            
            string ns = script.GetClass()?.Namespace ?? "";
            Assert.IsTrue(ns.StartsWith("StudioOS."),
                $"Script {path} has incorrect namespace: {ns}");
        }
    }

    [Test]
    public void RuntimeScripts_DontReferenceEditor()
    {
        // Use reflection or assembly scanning
        var runtimeAssembly = typeof(Core.Systems.EventSystem).Assembly;
        var editorTypes = GetEditorTypes();
        
        foreach (var type in runtimeAssembly.GetTypes())
        {
            foreach (var reference in type.GetReferencedTypes())
            {
                Assert.IsFalse(editorTypes.Contains(reference),
                    $"Runtime type {type} references Editor type {reference}");
            }
        }
    }
}
```

### 3. Assembly Definition Tests

Validate asmdef structure:

```csharp
public class AssemblyDefinitionTests
{
    [Test]
    public void AllRuntimeAssemblies_HaveTestCounterparts()
    {
        string[] asmdefGuids = AssetDatabase.FindAssets("t:AssemblyDefinitionAsset",
            new[] { "Assets/_Project/Scripts/Runtime" });
        
        foreach (string guid in asmdefGuids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            string name = Path.GetFileNameWithoutExtension(path);
            string testPath = $"Assets/_Project/Tests/Runtime/Tests.{name}.asmdef";
            
            Assert.IsTrue(File.Exists(testPath),
                $"Assembly {name} missing test counterpart at {testPath}");
        }
    }

    [Test]
    public void CoreAssembly_HasNoProjectReferences()
    {
        string corePath = "Assets/_Project/Scripts/Runtime/Core/Core.asmdef";
        string json = File.ReadAllText(corePath);
        var asmdef = JsonUtility.FromJson<AssemblyDefinition>(json);
        
        foreach (string reference in asmdef.references)
        {
            Assert.IsFalse(reference.StartsWith("StudioOS."),
                "Core assembly should not reference other project assemblies");
        }
    }
}
```

### 4. Project Structure Tests

Validate folder organization:

```csharp
public class ProjectStructureTests
{
    [Test]
    public void Scripts_FollowNamingConventions()
    {
        string[] scriptGuids = AssetDatabase.FindAssets("t:MonoScript");
        
        foreach (string guid in scriptGuids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            string fileName = Path.GetFileNameWithoutExtension(path);
            
            // PascalCase check
            Assert.AreEqual(fileName, ToPascalCase(fileName),
                $"Script {path} should use PascalCase");
        }
    }

    [Test]
    public void Scenes_FollowNamingConvention()
    {
        string[] sceneGuids = AssetDatabase.FindAssets("t:Scene",
            new[] { "Assets/_Project/Scenes" });
        
        foreach (string guid in sceneGuids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            string fileName = Path.GetFileNameWithoutExtension(path);
            
            // Pattern: [Type]_[Name]_[Variant]
            Assert.IsTrue(
                Regex.IsMatch(fileName, @"^(Boot|Menu|Level|Test)_\w+"),
                $"Scene {path} does not follow naming convention"
            );
        }
    }

    [Test]
    public void NoScripts_InRootScriptsFolder()
    {
        var scriptsInRoot = Directory.GetFiles("Assets/_Project/Scripts", "*.cs");
        Assert.IsEmpty(scriptsInRoot,
            "Scripts should be in subfolders, not root Scripts folder");
    }
}
```

### 5. Configuration Tests

Validate project settings:

```csharp
public class ConfigurationTests
{
    [Test]
    public void PlayerSettings_HaveCorrectCompanyName()
    {
        Assert.AreEqual("StudioOS", PlayerSettings.companyName);
    }

    [Test]
    public void GraphicsSettings_UseCorrectPipeline()
    {
        var pipeline = GraphicsSettings.defaultRenderPipeline;
        Assert.IsNotNull(pipeline);
        Assert.AreEqual("UniversalRenderPipelineAsset", pipeline.name);
    }

    [Test]
    public void TagManager_HasRequiredTags()
    {
        string[] requiredTags = { "Player", "Enemy", "Item", "Interactable" };
        
        foreach (string tag in requiredTags)
        {
            Assert.IsTrue(TagManager.ContainsTag(tag),
                $"Required tag '{tag}' not found in TagManager");
        }
    }
}
```

## Fast Feedback Pattern

EditMode tests should complete quickly:

```csharp
public class FastFeedbackTests
{
    [Test]
    [Category("PreCommit")]
    public void CriticalValidation_Passes()
    {
        // Quick checks that run on every commit
        ValidateProjectStructure();
        ValidateNamingConventions();
        ValidateAssemblyReferences();
    }
}
```

## CI Integration

### Command Line Execution

```bash
# Run EditMode tests
/Applications/Unity/Unity.app/Contents/MacOS/Unity \
  -batchmode \
  -nographics \
  -runTests \
  -testPlatform EditMode \
  -testResults "editmode-results.xml" \
  -projectPath "$(pwd)"
```

### Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run fast EditMode tests
unity -batchmode -runTests -testPlatform EditMode \
  -testCategory "PreCommit" \
  -testResults "precommit-results.xml"

if [ $? -ne 0 ]; then
    echo "EditMode tests failed. Commit blocked."
    exit 1
fi
```

## Test Organization

### Folder Structure
```
Assets/_Project/Tests/Editor/
├── Validation/           # Asset validation
│   ├── AssetValidationTests.cs
│   ├── NamingConventionTests.cs
│   └── ImportSettingsTests.cs
├── Structure/            # Code structure
│   ├── AssemblyTests.cs
│   ├── NamespaceTests.cs
│   └── ReferenceTests.cs
├── Configuration/        # Project settings
│   ├── PlayerSettingsTests.cs
│   ├── GraphicsSettingsTests.cs
│   └── InputSystemTests.cs
└── Tools/               # Editor tool tests
    ├── LevelEditorTests.cs
    └── BatchProcessorTests.cs
```

## Enforcement

### CI Gates
- All EditMode tests must pass
- Fast execution (<2 minutes for pre-commit)
- No validation failures

### Pre-Commit Checks
- Run `PreCommit` category tests
- Validate asset naming
- Check assembly structure

### Failure Modes
| Failure | Severity | Response |
|---------|----------|----------|
| Test failure | Error | Block commit |
| Naming violation | Warning | Warning + suggest fix |
| Missing test coverage | Warning | Review required |
| Slow test | Warning | Optimize or move to PlayMode |
