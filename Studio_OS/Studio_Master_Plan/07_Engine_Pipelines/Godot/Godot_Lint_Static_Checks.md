---
title: Godot Lint Static Checks
type: system
layer: enforcement
status: active
tags:
  - godot
  - lint
  - static-analysis
  - gdlint
  - ci
  - code-quality
depends_on:
  - "[Godot_Pipeline_Overview]]"
  - "[[Godot_GDScript_Style_Guide]"
used_by:
  - "[Godot_CI_Template]]"
  - "[[Godot_GUT_Test_Framework]"
---

# Godot Lint Static Checks

Static analysis catches style violations, potential bugs, and maintainability issues before runtime. This specification defines the linting toolchain and rules for GDScript in the AI-Native Game Studio OS pipeline.

## Toolchain

### Primary: gdlint
[gdlint](https://github.com/Scony/godot-gdscript-toolkit) is the standard GDScript linter.

```bash
# Installation
pip install gdtoolkit

# Basic usage
gdlint src/

# Specific file
gdlint src/entities/player/player.gd

# With config
gdlint --config .gdlintrc src/
```

### Secondary: godot-lint
Additional Godot-specific checks via custom scripts.

## Configuration

### .gdlintrc
```yaml
# Disable rules that conflict with studio conventions
disable:
  - max-public-methods  # We use signals extensively
  - max-returns  # Early returns preferred

# Rule-specific settings
max-line-length: 100
max-file-lines: 500
max-function-lines: 100
max-function-parameters: 6

# Naming conventions
class-name: "([A-Z][a-z0-9]*)+"
class-variable-name: "_?[a-z][a-z0-9]*(_[a-z0-9]+)*"
constant-name: "[A-Z][A-Z0-9]*(_[A-Z0-9]+)*"
enum-element-name: "[A-Z][A-Z0-9]*(_[A-Z0-9]+)*"
function-name: "_?[a-z][a-z0-9]*(_[a-z0-9]+)*"
function-variable-name: "_?[a-z][a-z0-9]*(_[a-z0-9]+)*"
signal-name: "[a-z][a-z0-9]*(_[a-z0-9]+)*"
```

## Rule Categories

### Style Rules
| Rule | Description | Severity |
|------|-------------|----------|
| `max-line-length` | Lines must not exceed 100 chars | Error |
| `max-file-lines` | Files must not exceed 500 lines | Warning |
| `trailing-whitespace` | No trailing whitespace | Error |
| `mixed-tabs-spaces` | Consistent indentation | Error |
| `max-blank-lines` | Max 2 consecutive blank lines | Warning |

### Naming Rules
| Rule | Pattern | Example |
|------|---------|---------|
| `class-name` | PascalCase | `PlayerController` |
| `function-name` | snake_case | `take_damage` |
| `class-variable-name` | snake_case | `player_health` |
| `constant-name` | UPPER_SNAKE_CASE | `MAX_HEALTH` |
| `signal-name` | snake_case | `health_changed` |

### Complexity Rules
| Rule | Limit | Purpose |
|------|-------|---------|
| `max-function-lines` | 100 | Keep functions focused |
| `max-function-parameters` | 6 | Avoid parameter bloat |
| `max-public-methods` | 20 | Class size control |
| `max-nested-blocks` | 4 | Prevent deep nesting |
| `max-returns` | 6 | Control flow clarity |

### Godot-Specific Rules
| Rule | Description |
|------|-------------|
| `unused-variable` | Variables must be used |
| `unused-argument` | Function args must be used |
| `unused-signal` | Signals should be connected |
| `shadowed-variable` | Don't shadow outer scope |
| `private-method-call` | Respect _prefix privacy |

## Custom Studio Rules

### Determinism Rules
```python
# scripts/lint/determinism_rules.py

BANNED_FUNCTIONS = [
    "randf",
    "randi", 
    "randfn",
    "randomize",
    "OS.get_time",
    "Time.get_time_dict_from_system",
    "Time.get_unix_time_from_system"
]

def check_determinism(file_path: str, content: str) -> List[LintError]:
    errors = []
    for banned in BANNED_FUNCTIONS:
        if banned in content:
            errors.append(LintError(
                file=file_path,
                line=find_line(content, banned),
                message=f"Non-deterministic function '{banned}' found. "
                        f"Use DeterministicRNG instead.",
                rule="determinism/banned-function"
            ))
    return errors
```

### Project Structure Rules
```python
# scripts/lint/structure_rules.py

def check_script_location(file_path: str) -> List[LintError]:
    """Ensure .gd files are in src/ directory"""
    if file_path.endswith(".gd") and not file_path.startswith("src/"):
        return [LintError(
            file=file_path,
            line=0,
            message="Scripts must be in src/ directory",
            rule="structure/script-location"
        )]
    return []

def check_scene_naming(file_path: str, content: str) -> List[LintError]:
    """Ensure scene root name matches filename"""
    # Parse .tscn file and validate
    pass
```

### Autoload Rules
```python
# scripts/lint/autoload_rules.py

MAX_AUTOLOADS = 8

def check_autoload_count(project_file: str) -> List[LintError]:
    """Enforce 8-autoload limit"""
    content = read_file(project_file)
    autoload_count = content.count("autoload/")
    
    if autoload_count > MAX_AUTOLOADS:
        return [LintError(
            file=project_file,
            line=0,
            message=f"Too many autoloads: {autoload_count}. Maximum is {MAX_AUTOLOADS}.",
            rule="autoload/count-limit"
        )]
    return []
```

## CI Integration

### GitHub Actions
```yaml
name: Lint

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install gdtoolkit
        run: pip install gdtoolkit
      
      - name: Run gdlint
        run: |
          gdlint --config .gdlintrc src/ > lint_results.txt 2>&1 || true
          cat lint_results.txt
      
      - name: Run custom lint rules
        run: python scripts/lint/run_all.py
      
      - name: Check for errors
        run: |
          if grep -q "error" lint_results.txt; then
            echo "Lint errors found!"
            exit 1
          fi
```

### Local Lint Script
```bash
#!/bin/bash
# scripts/lint.sh

echo "Running GDScript linter..."
gdlint --config .gdlintrc src/ 2>&1 | tee builds/lint/gdlint.txt
GDLINT_EXIT=${PIPESTATUS[0]}

echo "Running custom studio rules..."
python scripts/lint/run_all.py 2>&1 | tee builds/lint/custom.txt
CUSTOM_EXIT=${PIPESTATUS[0]}

# Generate combined report
echo "=== LINT SUMMARY ===" > builds/lint/summary.txt
echo "gdlint: $GDLINT_EXIT" >> builds/lint/summary.txt
echo "custom: $CUSTOM_EXIT" >> builds/lint/summary.txt

if [ $GDLINT_EXIT -ne 0 ] || [ $CUSTOM_EXIT -ne 0 ]; then
    echo "Lint failed!"
    exit 1
fi

echo "Lint passed!"
exit 0
```

## Pre-commit Integration

### .pre-commit-config.yaml
```yaml
repos:
  - repo: local
    hooks:
      - id: gdlint
        name: gdlint
        entry: gdlint
        language: system
        files: \.gd$
        args: ['--config', '.gdlintrc']
      
      - id: custom-lint
        name: studio-lint-rules
        entry: python scripts/lint/run_all.py
        language: system
        files: \.(gd|tscn|tres)$
```

## Editor Integration

### VS Code
```json
// .vscode/settings.json
{
  "godotTools.editorPath": "/path/to/godot",
  "[gdscript]": {
    "editor.defaultFormatter": "EddieDover.gdscript-formatter-linter",
    "editor.formatOnSave": true
  },
  "gdscript_formatter.line_length": 100
}
```

### Godot Editor
Use Editor → Editor Settings → Text Editor → Behavior:
- Trim trailing whitespace: On
- Indent type: Spaces
- Indent size: 4

## Lint Suppression

### Inline Suppression
```gdscript
# gdlint: ignore=max-line-length
var very_long_variable_name_that_exceeds_the_limit_but_is_descriptive = some_value

# gdlint: ignore=unused-variable
var _reserved_for_future_use: int = 0
```

### File-Level Suppression
```gdscript
# gdlint: disable=max-public-methods
class_name EventBus
# Many public methods justified for event system
```

## Error Severity Levels

| Level | Action | Examples |
|-------|--------|----------|
| Error | Block CI | Style violations, determinism issues |
| Warning | Report only | File length, complexity |
| Info | Log only | Suggestions, best practices |

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Line too long | Break into multiple lines |
| Unused variable | Remove or use the variable |
| Function too long | Extract helper functions |
| Too many parameters | Use config object pattern |
| Mixed indentation | Run formatter |

## See Also

- [[Godot_GDScript_Style_Guide]] - Style conventions
- [[Godot_CI_Template]] - CI pipeline integration
- [[Godot_Deterministic_Fixed_Timestep]] - Determinism requirements
