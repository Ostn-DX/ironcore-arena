---
title: Unity CI Template
type: template
layer: execution
status: active
tags:
  - unity
  - ci-cd
  - github-actions
  - gitlab-ci
  - automation
depends_on:
  - "[Unity_Pipeline_Overview]]"
  - "[[Unity_Build_Automation]]"
  - "[[Unity_PlayMode_Test_Framework]]"
  - "[[Unity_EditMode_Test_Framework]"
used_by: []
---

# Unity CI Template

This document provides ready-to-use CI/CD templates for Unity projects in the Studio OS ecosystem. Templates are provided for GitHub Actions and GitLab CI.

## GitHub Actions Template

### Main Workflow (.github/workflows/main.yml)

```yaml
name: Unity CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
  UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}
  UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}

jobs:
  # ============================================
  # CHECK - Code quality and validation
  # ============================================
  check:
    name: Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      - name: Check Code Style
        uses: game-ci/unity-builder@v4
        with:
          targetPlatform: StandaloneLinux64
          buildMethod: StudioOS.Editor.Checks.RunStyleCheck

      - name: Validate Project Structure
        run: |
          # Check folder naming conventions
          find Assets/_Project -type d -name "* *" -o -name "*[A-Z]*" 2>/dev/null | \
            grep -v "^[A-Z]" && exit 1 || echo "Folder naming OK"

  # ============================================
  # TEST - Run all tests
  # ============================================
  test:
    name: Test
    runs-on: ubuntu-latest
    needs: check
    strategy:
      fail-fast: false
      matrix:
        testMode:
          - EditMode
          - PlayMode
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      - name: Cache Library
        uses: actions/cache@v3
        with:
          path: Library
          key: Library-${{ hashFiles('Assets/**', 'Packages/**', 'ProjectSettings/**') }}
          restore-keys: |
            Library-

      - name: Run Tests
        uses: game-ci/unity-test-runner@v4
        with:
          testMode: ${{ matrix.testMode }}
          artifactsPath: ${{ matrix.testMode }}-artifacts
          githubToken: ${{ secrets.GITHUB_TOKEN }}
          checkName: ${{ matrix.testMode }} Tests

      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: Test results for ${{ matrix.testMode }}
          path: ${{ matrix.testMode }}-artifacts

  # ============================================
  # BUILD - Build for all platforms
  # ============================================
  build:
    name: Build for ${{ matrix.targetPlatform }}
    runs-on: ubuntu-latest
    needs: test
    strategy:
      fail-fast: false
      matrix:
        targetPlatform:
          - StandaloneWindows64
          - StandaloneOSX
          - StandaloneLinux64
          - WebGL
        include:
          - targetPlatform: StandaloneWindows64
            buildMethod: StudioOS.Editor.Build.BuildAutomation.BuildWindowsProduction
          - targetPlatform: StandaloneOSX
            buildMethod: StudioOS.Editor.Build.BuildAutomation.BuildMacOSProduction
          - targetPlatform: StandaloneLinux64
            buildMethod: StudioOS.Editor.Build.BuildAutomation.BuildLinuxProduction
          - targetPlatform: WebGL
            buildMethod: StudioOS.Editor.Build.BuildAutomation.BuildWebGLProduction
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      - name: Cache Library
        uses: actions/cache@v3
        with:
          path: Library
          key: Library-${{ hashFiles('Assets/**', 'Packages/**', 'ProjectSettings/**') }}
          restore-keys: |
            Library-

      - name: Build Addressables
        uses: game-ci/unity-builder@v4
        with:
          targetPlatform: ${{ matrix.targetPlatform }}
          buildMethod: UnityEditor.AddressableAssets.BuildScriptPackedMode.BuildScriptPackedMode.Build

      - name: Build Project
        uses: game-ci/unity-builder@v4
        with:
          targetPlatform: ${{ matrix.targetPlatform }}
          buildMethod: ${{ matrix.buildMethod }}
          buildsPath: Builds/${{ matrix.targetPlatform }}

      - name: Upload Build
        uses: actions/upload-artifact@v3
        with:
          name: Build-${{ matrix.targetPlatform }}
          path: Builds/${{ matrix.targetPlatform }}

  # ============================================
  # EXPORT - Package for distribution
  # ============================================
  export:
    name: Export
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download All Builds
        uses: actions/download-artifact@v3
        with:
          path: Builds

      - name: Create Release Packages
        run: |
          mkdir -p Exports
          
          # Package Windows
          cd Builds/Build-StandaloneWindows64
          zip -r ../../Exports/Game-Windows-${{ github.run_number }}.zip .
          cd ../..
          
          # Package macOS
          cd Builds/Build-StandaloneOSX
          zip -r ../../Exports/Game-macOS-${{ github.run_number }}.zip .
          cd ../..
          
          # Package Linux
          cd Builds/Build-StandaloneLinux64
          zip -r ../../Exports/Game-Linux-${{ github.run_number }}.zip .
          cd ../..

      - name: Generate Checksums
        run: |
          cd Exports
          sha256sum *.zip > checksums.txt
          cat checksums.txt

      - name: Upload Packages
        uses: actions/upload-artifact@v3
        with:
          name: Release-Packages
          path: Exports/

  # ============================================
  # PERFORMANCE - Run performance tests
  # ============================================
  performance:
    name: Performance Tests
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main' || contains(github.event.head_commit.message, '[perf]')
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true

      - name: Cache Library
        uses: actions/cache@v3
        with:
          path: Library
          key: Library-${{ hashFiles('Assets/**', 'Packages/**', 'ProjectSettings/**') }}

      - name: Run Performance Tests
        uses: game-ci/unity-test-runner@v4
        with:
          testMode: playmode
          testFilter: 'Performance'
          artifactsPath: performance-artifacts

      - name: Upload Performance Results
        uses: actions/upload-artifact@v3
        with:
          name: Performance-Results
          path: performance-artifacts

  # ============================================
  # DEPLOY - Deploy to staging
  # ============================================
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: export
    if: github.ref == 'refs/heads/main'
    environment: staging
    steps:
      - name: Download Packages
        uses: actions/download-artifact@v3
        with:
          name: Release-Packages
          path: Exports/

      - name: Deploy to Staging CDN
        run: |
          # Upload to staging CDN
          echo "Deploying to staging..."
          # aws s3 sync Exports/ s3://studioos-staging/builds/${{ github.run_number }}/

  # ============================================
  # NOTIFY - Send notifications
  # ============================================
  notify:
    name: Notify
    runs-on: ubuntu-latest
    needs: [check, test, build]
    if: always()
    steps:
      - name: Notify Discord
        uses: sarisia/actions-status-discord@v1
        if: always()
        with:
          webhook: ${{ secrets.DISCORD_WEBHOOK }}
          status: ${{ job.status }}
          title: "Unity CI Build"
          description: "Build ${{ github.run_number }} completed"
```

### Release Workflow (.github/workflows/release.yml)

```yaml
name: Release

on:
  release:
    types: [published]

env:
  UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
  UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}
  UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}

jobs:
  build-release:
    name: Build Release
    runs-on: ubuntu-latest
    strategy:
      matrix:
        targetPlatform:
          - StandaloneWindows64
          - StandaloneOSX
          - StandaloneLinux64
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          lfs: true
          ref: ${{ github.event.release.tag_name }}

      - name: Cache Library
        uses: actions/cache@v3
        with:
          path: Library
          key: Library-${{ hashFiles('Assets/**', 'Packages/**', 'ProjectSettings/**') }}

      - name: Build
        uses: game-ci/unity-builder@v4
        with:
          targetPlatform: ${{ matrix.targetPlatform }}
          versioning: Semantic
          buildName: Game-${{ github.event.release.tag_name }}-${{ matrix.targetPlatform }}

      - name: Package
        run: |
          cd build/${{ matrix.targetPlatform }}
          zip -r ../../Game-${{ github.event.release.tag_name }}-${{ matrix.targetPlatform }}.zip .

      - name: Upload to Release
        uses: softprops/action-gh-release@v1
        with:
          files: Game-${{ github.event.release.tag_name }}-${{ matrix.targetPlatform }}.zip
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## GitLab CI Template

### .gitlab-ci.yml

```yaml
# Unity GitLab CI Pipeline
# Requires: Unity Docker image, Git LFS

variables:
  UNITY_VERSION: "2022.3.20f1"
  UNITY_IMAGE: "unityci/editor:ubuntu-${UNITY_VERSION}-linux-il2cpp-3"
  GIT_LFS_SKIP_SMUDGE: "0"

stages:
  - check
  - test
  - build
  - export
  - deploy

# ============================================
# CHECK STAGE
# ============================================
code_style:
  stage: check
  image: $UNITY_IMAGE
  script:
    - unity-editor -batchmode -nographics -quit -projectPath $(pwd) -executeMethod StudioOS.Editor.Checks.RunStyleCheck -logFile -
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"

# ============================================
# TEST STAGE
# ============================================
.test_template: &test_definition
  stage: test
  image: $UNITY_IMAGE
  before_script:
    - mkdir -p artifacts
  artifacts:
    when: always
    paths:
      - artifacts/
    reports:
      junit: artifacts/results.xml

test_editmode:
  <<: *test_definition
  script:
    - unity-editor -batchmode -nographics -quit -projectPath $(pwd) -runTests -testPlatform EditMode -testResults artifacts/editmode-results.xml -logFile -
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"

test_playmode:
  <<: *test_definition
  script:
    - unity-editor -batchmode -nographics -quit -projectPath $(pwd) -runTests -testPlatform PlayMode -testResults artifacts/playmode-results.xml -logFile -
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"

# ============================================
# BUILD STAGE
# ============================================
.build_template: &build_definition
  stage: build
  image: $UNITY_IMAGE
  cache:
    key: "${CI_JOB_NAME}"
    paths:
      - Library/
  artifacts:
    paths:
      - Builds/
    expire_in: 1 week

build_windows:
  <<: *build_definition
  script:
    - unity-editor -batchmode -nographics -quit -projectPath $(pwd) -executeMethod StudioOS.Editor.Build.BuildAutomation.BuildWindowsProduction -logFile -
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

build_macos:
  <<: *build_definition
  script:
    - unity-editor -batchmode -nographics -quit -projectPath $(pwd) -executeMethod StudioOS.Editor.Build.BuildAutomation.BuildMacOSProduction -logFile -
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

build_linux:
  <<: *build_definition
  script:
    - unity-editor -batchmode -nographics -quit -projectPath $(pwd) -executeMethod StudioOS.Editor.Build.BuildAutomation.BuildLinuxProduction -logFile -
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

# ============================================
# EXPORT STAGE
# ============================================
export_packages:
  stage: export
  image: alpine
  dependencies:
    - build_windows
    - build_macos
    - build_linux
  script:
    - apk add --no-cache zip
    - mkdir -p Exports
    - cd Builds/Windows && zip -r ../../Exports/Game-Windows-$CI_COMMIT_SHORT_SHA.zip . && cd ../..
    - cd Builds/macOS && zip -r ../../Exports/Game-macOS-$CI_COMMIT_SHORT_SHA.zip . && cd ../..
    - cd Builds/Linux && zip -r ../../Exports/Game-Linux-$CI_COMMIT_SHORT_SHA.zip . && cd ../..
  artifacts:
    paths:
      - Exports/
    expire_in: 30 days
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

# ============================================
# DEPLOY STAGE
# ============================================
deploy_staging:
  stage: deploy
  image: amazon/aws-cli
  dependencies:
    - export_packages
  script:
    - aws s3 sync Exports/ s3://studioos-staging/builds/$CI_COMMIT_SHORT_SHA/
  environment:
    name: staging
    url: https://staging.studioos.com/builds/$CI_COMMIT_SHORT_SHA/
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

## Required Secrets

### GitHub Secrets

| Secret | Description |
|--------|-------------|
| `UNITY_LICENSE` | Unity license file content |
| `UNITY_EMAIL` | Unity account email |
| `UNITY_PASSWORD` | Unity account password |
| `DISCORD_WEBHOOK` | Discord webhook URL |
| `STEAM_USERNAME` | Steam build account |
| `STEAM_PASSWORD` | Steam build password |

### GitLab CI/CD Variables

| Variable | Description |
|----------|-------------|
| `UNITY_LICENSE` | Unity license file content |
| `UNITY_EMAIL` | Unity account email |
| `UNITY_PASSWORD` | Unity account password |
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |

## Pipeline Triggers

| Event | Stages Run |
|-------|-----------|
| PR to main | check, test |
| Push to main | check, test, build, export, deploy-staging |
| Tag release | build, export, deploy-production |
| Scheduled (daily) | performance tests |

## Enforcement

### Required Checks
- All tests must pass
- Build must succeed
- No style violations
- Performance within thresholds

### Failure Modes
| Failure | Response |
|---------|----------|
| Test failure | Block merge |
| Build failure | Block merge |
| Performance regression | Warning |
| Style violation | Auto-fix or block |
