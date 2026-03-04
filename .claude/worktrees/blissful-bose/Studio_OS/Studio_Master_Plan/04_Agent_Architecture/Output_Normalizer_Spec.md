---
title: Output Normalizer Specification
type: system
layer: architecture
status: active
tags:
  - output
  - normalizer
  - format
  - files
  - modifications
  - tests
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Message_Contracts]"
used_by:
  - "[Agent_Role_Definitions]]"
  - "[[Patch_Protocol]]"
  - "[[Gate_Protocol]"
---

# Output Normalizer Specification

## Purpose

The Output Normalizer ensures all agents produce consistent, structured output that can be reliably processed by downstream systems. It defines the standard format for agent deliverables.

## Core Principle

**All agent outputs MUST conform to the normalized format.** This enables:
- Uniform processing across agent types
- Reliable patch generation
- Consistent review workflows
- Automated integration

## Normalized Output Structure

```yaml
NormalizedOutput:
  version: "1.0"
  agent_type: AgentType
  task_id: string
  timestamp: ISO8601
  
  sections:
    NEW_FILES: [NewFile]
    MODIFICATIONS: [FileModification]
    TESTS: [TestCase]
    INTEGRATION_GUIDE: IntegrationGuide
    
  metadata:
    total_files: integer
    lines_added: integer
    lines_removed: integer
    test_count: integer
```

## Section Specifications

### 1. NEW_FILES

New files created by the agent:

```yaml
NEW_FILES:
  - path: "src/new_module.rs"
    description: "New player inventory system"
    content: |
      use std::collections::HashMap;
      
      pub struct Inventory {
          items: HashMap<String, u32>,
      }
      // ... full content
    language: rust
    size_bytes: 2048
    line_count: 85
```

**Requirements:**
- Complete file content
- Valid file path (relative to project root)
- Language identifier for syntax highlighting
- Description of purpose

### 2. MODIFICATIONS

Changes to existing files:

```yaml
MODIFICATIONS:
  - path: "src/player.rs"
    operation: modify
    description: "Add inventory field to Player struct"
    
    original:
      hash: "abc123..."
      preview: "pub struct Player { name: String }"
      
    modified:
      hash: "def456..."
      content: |
        pub struct Player {
            name: String,
            inventory: Inventory,
        }
      diff: |
        --- a/src/player.rs
        +++ b/src/player.rs
        @@ -1,5 +1,6 @@
         pub struct Player {
        -    name: String
        +    name: String,
        +    inventory: Inventory,
         }
    
    lines_changed: 3
    lines_added: 2
    lines_removed: 1
```

**Requirements:**
- Unified diff format
- Original content hash for verification
- Line change counts
- Clear description of change

### 3. TESTS

Test cases created or modified:

```yaml
TESTS:
  - name: "test_inventory_add_item"
    type: unit
    target_file: "src/inventory.rs"
    description: "Test adding items to inventory"
    
    code: |
      #[test]
      fn test_inventory_add_item() {
          let mut inv = Inventory::new();
          inv.add("sword", 1);
          assert_eq!(inv.get("sword"), Some(1));
      }
    
    coverage:
      target_file: "src/inventory.rs"
      expected_coverage: 0.85
      
    metadata:
      priority: high
      tags: ["inventory", "core"]
```

**Requirements:**
- Complete test code
- Target file reference
- Coverage expectations
- Priority and tags

### 4. INTEGRATION_GUIDE

Instructions for integrating changes:

```yaml
INTEGRATION_GUIDE:
  summary: "Add inventory system to player"
  
  prerequisites:
    - "Rust 1.70+"
    - "Existing Player module"
    
  steps:
    - order: 1
      action: "Add new files"
      files: ["src/inventory.rs"]
      
    - order: 2
      action: "Modify existing files"
      files: ["src/player.rs", "src/lib.rs"]
      notes: "Add inventory field and import"
      
    - order: 3
      action: "Run tests"
      command: "cargo test inventory"
      
    - order: 4
      action: "Verify integration"
      command: "cargo build"
      
  breaking_changes:
    - description: "Player::new() signature changed"
      migration: "Update calls to include inventory parameter"
      
  rollback:
    command: "git checkout -- src/player.rs src/inventory.rs"
    notes: "Removes inventory changes"
```

**Requirements:**
- Step-by-step integration instructions
- Prerequisites clearly stated
- Breaking changes documented
- Rollback procedure provided

## Normalization Rules

### File Path Normalization

```python
def normalize_path(path: str) -> str:
    """Ensure consistent path format."""
    # Remove leading ./
    path = path.lstrip("./")
    # Use forward slashes
    path = path.replace("\\", "/")
    # Remove duplicate slashes
    path = path.replace("//", "/")
    return path
```

### Diff Normalization

```python
def normalize_diff(diff: str) -> str:
    """Ensure consistent diff format."""
    lines = diff.split("\n")
    normalized = []
    
    for line in lines:
        # Ensure proper prefix
        if line.startswith("+") and not line.startswith("+++"):
            normalized.append(line)
        elif line.startswith("-") and not line.startswith("---"):
            normalized.append(line)
        elif line.startswith("@"):
            normalized.append(line)
        elif line.startswith(" "):
            normalized.append(line)
        elif line.startswith("diff"):
            normalized.append(line)
        elif line.startswith("index"):
            normalized.append(line)
        elif line.startswith("---"):
            normalized.append(line)
        elif line.startswith("+++"):
            normalized.append(line)
    
    return "\n".join(normalized)
```

### Content Normalization

```python
def normalize_content(content: str, language: str) -> str:
    """Normalize code content."""
    # Ensure trailing newline
    if not content.endswith("\n"):
        content += "\n"
    
    # Remove trailing whitespace per line
    lines = [line.rstrip() for line in content.split("\n")]
    
    # Apply language-specific formatting
    if language == "rust":
        lines = normalize_rust(lines)
    elif language == "typescript":
        lines = normalize_typescript(lines)
    
    return "\n".join(lines)
```

## Validation

### Schema Validation

```python
def validate_output(output: NormalizedOutput) -> ValidationResult:
    errors = []
    
    # Check required sections
    if not output.NEW_FILES and not output.MODIFICATIONS:
        errors.append("At least one of NEW_FILES or MODIFICATIONS required")
    
    # Validate file paths
    for file in output.NEW_FILES:
        if not is_valid_path(file.path):
            errors.append(f"Invalid path: {file.path}")
    
    # Validate diffs
    for mod in output.MODIFICATIONS:
        if not is_valid_diff(mod.diff):
            errors.append(f"Invalid diff in {mod.path}")
    
    # Validate tests
    for test in output.TESTS:
        if not test.code:
            errors.append(f"Test {test.name} missing code")
    
    return ValidationResult(valid=len(errors) == 0, errors=errors)
```

## Conversion from Agent-Specific Formats

### Generic Converter Interface

```python
class OutputConverter:
    def convert(self, agent_output: Any) -> NormalizedOutput:
        raise NotImplementedError
```

### Example: CodeGenerator Converter

```python
class CodeGeneratorConverter(OutputConverter):
    def convert(self, agent_output: dict) -> NormalizedOutput:
        return NormalizedOutput(
            NEW_FILES=[
                NewFile(
                    path=f["path"],
                    content=f["content"],
                    language=f.get("language", "text")
                )
                for f in agent_output.get("files", [])
            ],
            MODIFICATIONS=[
                FileModification(
                    path=m["path"],
                    diff=m["diff"],
                    description=m.get("description", "")
                )
                for m in agent_output.get("modifications", [])
            ],
            INTEGRATION_GUIDE=IntegrationGuide(
                summary=agent_output.get("summary", ""),
                steps=agent_output.get("steps", [])
            )
        )
```

## Output Storage

### File Organization

```
outputs/
  {task_id}/
    normalized_output.yaml
    new_files/
      {file_path}
    diffs/
      {file_path}.diff
    tests/
      {test_name}.rs
```

### Persistence

```python
def save_output(output: NormalizedOutput, task_id: str):
    """Save normalized output to storage."""
    base_path = f"outputs/{task_id}"
    os.makedirs(base_path, exist_ok=True)
    
    # Save main output
    with open(f"{base_path}/normalized_output.yaml", "w") as f:
        yaml.dump(output, f)
    
    # Save new files
    for file in output.NEW_FILES:
        path = f"{base_path}/new_files/{file.path}"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(file.content)
    
    # Save diffs
    for mod in output.MODIFICATIONS:
        path = f"{base_path}/diffs/{mod.path}.diff"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(mod.diff)
```

## Integration with Downstream Systems

### Patch Generation
Normalized outputs feed into [[Patch_Protocol|patch generation]]:
- NEW_FILES → create file patches
- MODIFICATIONS → apply diff patches
- INTEGRATION_GUIDE → patch metadata

### Gate Execution
[[Gate_Protocol|Gate checks]] use normalized outputs:
- TESTS → test execution
- MODIFICATIONS → static analysis
- NEW_FILES → compilation check

### Review Workflow
Reviewers receive normalized outputs:
- Structured format for consistent review
- Clear change descriptions
- Test coverage visibility
