---
title: Godot CI Template
type: template
layer: execution
status: active
tags:
  - godot
  - ci
  - github-actions
  - gitlab
  - automation
  - pipeline
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_Export_Pipeline]]"
  - "[[Godot_Lint_Static_Checks]"
used_by:
  - "[Godot_Steam_Build_Packaging]"
---

# Godot CI Template

Complete CI/CD pipeline templates for Godot 4.x projects. Supports GitHub Actions and GitLab CI with local-first design that mirrors CI workflows.

## GitHub Actions Template

### Complete Workflow
```yaml
# .github/workflows/godot-ci.yml
name: Godot CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  GODOT_VERSION: 4.2.1
  EXPORT_NAME: GameName

jobs:
  # ==========================================
  # STAGE 1: Code Quality
  # ==========================================
  lint:
    name: Lint & Static Analysis
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install gdtoolkit
        run: pip install gdtoolkit

      - name: Run gdlint
        run: |
          gdlint --config .gdlintrc src/ 2>&1 | tee lint_results.txt
          if grep -q "error" lint_results.txt; then
            echo "Lint errors found!"
            exit 1
          fi

      - name: Run Custom Lint Rules
        run: python scripts/lint/run_all.py

      - name: Upload Lint Results
        uses: actions/upload-artifact@v4
        with:
          name: lint-results
          path: lint_results.txt

  # ==========================================
  # STAGE 2: Unit Tests
  # ==========================================
  unit-tests:
    name: Unit Tests (GUT)
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: ${{ env.GODOT_VERSION }}
          use-dotnet: false

      - name: Run GUT Tests
        run: |
          godot --headless --script addons/gut/gut_cmdln.gd \
            -gdir=res://src/tests/unit \
            -ginclude_subdirs \
            -gexit \
            -gjunit_xml=unit_tests.xml

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        with:
          name: unit-test-results
          path: unit_tests.xml

      - name: Publish Test Report
        uses: dorny/test-reporter@v1
        if: success() || failure()
        with:
          name: Unit Tests
          path: unit_tests.xml
          reporter: java-junit

  # ==========================================
  # STAGE 3: Headless Simulation Tests
  # ==========================================
  sim-tests:
    name: Simulation Tests
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: ${{ env.GODOT_VERSION }}

      - name: Run Headless Sim Tests
        run: |
          godot --headless --script src/tests/runners/headless_sim.gd \
            --config=src/tests/configs/ci_suite.json \
            --output=sim_results.json

      - name: Validate Results
        run: python scripts/validate_sim_results.py sim_results.json

      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: sim-test-results
          path: sim_results.json

  # ==========================================
  # STAGE 4: Build & Export
  # ==========================================
  build:
    name: Build (${{ matrix.platform }})
    runs-on: ubuntu-latest
    needs: [unit-tests, sim-tests]
    strategy:
      matrix:
        platform: [windows, linux, macos, web]
        include:
          - platform: windows
            preset: "Windows Desktop"
            ext: exe
          - platform: linux
            preset: "Linux/X11"
            ext: x86_64
          - platform: macos
            preset: "macOS"
            ext: zip
          - platform: web
            preset: "Web"
            ext: html
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: ${{ env.GODOT_VERSION }}

      - name: Install Export Templates
        run: |
          mkdir -p ~/.local/share/godot/export_templates
          godot --headless --quit

      - name: Build ${{ matrix.platform }}
        run: |
          mkdir -p builds/${{ matrix.platform }}
          godot --headless --export-release "${{ matrix.preset }}" \
            builds/${{ matrix.platform }}/${{ env.EXPORT_NAME }}.${{ matrix.ext }}

      - name: Validate Build
        run: |
          if [ ! -f "builds/${{ matrix.platform }}/${{ env.EXPORT_NAME }}.${{ matrix.ext }}" ]; then
            echo "Build failed - output not found"
            exit 1
          fi
          ls -la builds/${{ matrix.platform }}/

      - name: Upload Build
        uses: actions/upload-artifact@v4
        with:
          name: build-${{ matrix.platform }}
          path: builds/${{ matrix.platform }}/

  # ==========================================
  # STAGE 5: Performance Check
  # ==========================================
  performance:
    name: Performance Check
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: ${{ env.GODOT_VERSION }}

      - name: Run Performance Tests
        run: |
          godot --headless --script addons/gut/gut_cmdln.gd \
            -gdir=res://src/tests/performance \
            -gexit \
            -gjunit_xml=performance_tests.xml

      - name: Check Budgets
        run: python scripts/check_performance_budgets.py performance_tests.xml

  # ==========================================
  # STAGE 6: Release (tags only)
  # ==========================================
  release:
    name: Create Release
    runs-on: ubuntu-latest
    needs: [build, performance]
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - name: Download All Builds
        uses: actions/download-artifact@v4
        with:
          path: builds/

      - name: Package Builds
        run: |
          cd builds
          for dir in build-*/; do
            platform=$(echo $dir | sed 's/build-//' | sed 's/\///')
            zip -r "${{ env.EXPORT_NAME }}-${platform}.zip" "$dir"
          done

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: builds/*.zip
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## GitLab CI Template

```yaml
# .gitlab-ci.yml
variables:
  GODOT_VERSION: "4.2.1"
  EXPORT_NAME: "GameName"

stages:
  - lint
  - test
  - build
  - deploy

# ==========================================
# LINT STAGE
# ==========================================
lint:gdlint:
  stage: lint
  image: python:3.11-slim
  before_script:
    - pip install gdtoolkit
  script:
    - gdlint --config .gdlintrc src/
  only:
    - merge_requests
    - main
    - develop

lint:custom:
  stage: lint
  image: python:3.11-slim
  script:
    - python scripts/lint/run_all.py
  only:
    - merge_requests
    - main
    - develop

# ==========================================
# TEST STAGE
# ==========================================
test:unit:
  stage: test
  image: barichello/godot-ci:4.2.1
  script:
    - godot --headless --script addons/gut/gut_cmdln.gd
        -gdir=res://src/tests/unit
        -ginclude_subdirs
        -gexit
        -gjunit_xml=unit_tests.xml
  artifacts:
    reports:
      junit: unit_tests.xml
    paths:
      - unit_tests.xml
  only:
    - merge_requests
    - main
    - develop

test:simulation:
  stage: test
  image: barichello/godot-ci:4.2.1
  script:
    - godot --headless --script src/tests/runners/headless_sim.gd
        --config=src/tests/configs/ci_suite.json
        --output=sim_results.json
    - python scripts/validate_sim_results.py sim_results.json
  artifacts:
    paths:
      - sim_results.json
  only:
    - merge_requests
    - main
    - develop

# ==========================================
# BUILD STAGE
# ==========================================
.build_template: &build_definition
  stage: build
  image: barichello/godot-ci:4.2.1
  script:
    - mkdir -p builds/$PLATFORM
    - godot --headless --export-release "$PRESET" "builds/$PLATFORM/$EXPORT_NAME.$EXT"
  artifacts:
    paths:
      - builds/$PLATFORM/
    expire_in: 1 week
  only:
    - main
    - tags

build:windows:
  <<: *build_definition
  variables:
    PLATFORM: windows
    PRESET: "Windows Desktop"
    EXT: exe

build:linux:
  <<: *build_definition
  variables:
    PLATFORM: linux
    PRESET: "Linux/X11"
    EXT: x86_64

build:macos:
  <<: *build_definition
  variables:
    PLATFORM: macos
    PRESET: "macOS"
    EXT: zip

build:web:
  <<: *build_definition
  variables:
    PLATFORM: web
    PRESET: "Web"
    EXT: html

# ==========================================
# DEPLOY STAGE
# ==========================================
deploy:release:
  stage: deploy
  image: alpine:latest
  dependencies:
    - build:windows
    - build:linux
    - build:macos
    - build:web
  script:
    - apk add --no-cache zip
    - cd builds && zip -r ../release.zip */
  artifacts:
    paths:
      - release.zip
  only:
    - tags
```

## Local CI Simulation

### Local Test Script
```bash
#!/bin/bash
# scripts/ci_local.sh
# Run CI checks locally before pushing

set -e

echo "=== Local CI Simulation ==="

echo "1. Running linter..."
gdlint --config .gdlintrc src/ || exit 1

echo "2. Running custom lint rules..."
python scripts/lint/run_all.py || exit 1

echo "3. Running unit tests..."
godot --headless --script addons/gut/gut_cmdln.gd \
    -gdir=res://src/tests/unit \
    -ginclude_subdirs \
    -gexit || exit 1

echo "4. Running simulation tests..."
godot --headless --script src/tests/runners/headless_sim.gd \
    --config=src/tests/configs/ci_suite.json || exit 1

echo "5. Running performance tests..."
godot --headless --script addons/gut/gut_cmdln.gd \
    -gdir=res://src/tests/performance \
    -gexit || exit 1

echo "6. Testing export..."
mkdir -p builds/test
godot --headless --export-debug "Linux/X11" builds/test/game.x86_64 || exit 1

echo "=== All checks passed! ==="
```

## Pre-commit Hooks

### .pre-commit-config.yaml
```yaml
repos:
  - repo: local
    hooks:
      - id: gdlint
        name: GDScript Linter
        entry: gdlint
        language: system
        files: \.gd$
        args: ['--config', '.gdlintrc']
      
      - id: unit-tests
        name: Quick Unit Tests
        entry: godot
        language: system
        files: \.gd$
        pass_filenames: false
        args: ['--headless', '--script', 'addons/gut/gut_cmdln.gd', '-gexit']
      
      - id: import-check
        name: Check Import Files
        entry: scripts/hooks/check_imports.sh
        language: script
        files: \.(png|wav|ogg|fbx)$
```

## CI Optimization

### Caching Strategy
```yaml
# GitHub Actions caching
- name: Cache Godot
  uses: actions/cache@v4
  with:
    path: ~/.local/share/godot
    key: godot-${{ env.GODOT_VERSION }}

- name: Cache Export Templates
  uses: actions/cache@v4
  with:
    path: ~/.local/share/godot/export_templates
    key: templates-${{ env.GODOT_VERSION }}
```

### Parallel Job Strategy
```yaml
strategy:
  fail-fast: false  # Continue other jobs if one fails
  matrix:
    platform: [windows, linux, macos, web]
```

## Failure Notifications

### Slack Integration
```yaml
- name: Notify Slack on Failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    channel: '#game-dev'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## See Also

- [[Godot_Export_Pipeline]] - Export configuration
- [[Godot_Steam_Build_Packaging]] - Steam deployment
- [[Godot_Lint_Static_Checks]] - Lint configuration
