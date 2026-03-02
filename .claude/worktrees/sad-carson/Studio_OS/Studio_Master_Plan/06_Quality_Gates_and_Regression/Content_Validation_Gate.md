---
title: Content Validation Gate
type: gate
layer: enforcement
status: active
tags:
  - content
  - validation
  - json
  - schema
  - assets
  - gate
  - data-integrity
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Build_Gate]"
used_by:
  - "[Release_Certification_Checklist]]"
  - "[[Packaging_Gate]"
---

# Content Validation Gate

## Purpose

The Content Validation Gate ensures that all game content (JSON data, assets, configurations) is valid, complete, and correctly referenced. It catches data integrity issues before they cause runtime failures.

## Tool/Script

**Primary**: `scripts/gates/content_validation_gate.py`
**JSON Validator**: `jsonschema` + custom validators
**Asset Validator**: `Assets/Editor/ContentValidation/AssetValidator.cs`
**Reference Checker**: `scripts/tools/check_references.py`

## Local Run

```bash
# Run all content validation
python scripts/gates/content_validation_gate.py

# Validate specific content type
python scripts/gates/content_validation_gate.py --type json
python scripts/gates/content_validation_gate.py --type assets
python scripts/gates/content_validation_gate.py --type prefabs

# Check references only
python scripts/gates/content_validation_gate.py --check-refs

# Validate specific file
python scripts/gates/content_validation_gate.py --file Assets/Data/units.json

# Quick mode (skip heavy checks)
python scripts/gates/content_validation_gate.py --quick
```

## CI Run

```yaml
# .github/workflows/content-validation-gate.yml
name: Content Validation Gate
on: [push, pull_request]
jobs:
  content-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Content Validation Gate
        run: python scripts/gates/content_validation_gate.py
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| JSON Validity | 100% | All JSON files parse correctly |
| Schema Compliance | 100% | All JSON matches schema |
| Asset References | 100% | No missing asset references |
| Prefab Integrity | 100% | All prefabs load correctly |
| GUID Uniqueness | 100% | No duplicate GUIDs |
| Naming Conventions | > 95% | Files follow naming rules |
| Orphaned Assets | < 10 | Unused assets (warning only) |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| JSON Parse Error | >= 1 | HARD FAIL - syntax error |
| Schema Violation | >= 1 | HARD FAIL - data invalid |
| Missing Reference | >= 1 | HARD FAIL - broken link |
| Prefab Load Fail | >= 1 | HARD FAIL - prefab corrupt |
| Duplicate GUID | >= 1 | HARD FAIL - merge conflict |
| Critical Asset Missing | >= 1 | HARD FAIL - required file |

## Content Types Validated

| Type | Validation | Schema Location |
|------|------------|-----------------|
| Units | JSON schema | `schemas/units.schema.json` |
| Items | JSON schema | `schemas/items.schema.json` |
| Levels | JSON schema | `schemas/levels.schema.json` |
| Quests | JSON schema | `schemas/quests.schema.json` |
| Localization | JSON schema | `schemas/localization.schema.json` |
| Config | JSON schema | `schemas/config.schema.json` |
| Prefabs | Unity load test | N/A |
| Scenes | Scene load test | N/A |
| Materials | Shader validation | N/A |
| Audio | Format validation | N/A |

## JSON Schema Example

```json
// schemas/units.schema.json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["id", "name", "health", "damage"],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^unit_[a-z_]+$"
    },
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 50
    },
    "health": {
      "type": "integer",
      "minimum": 1,
      "maximum": 10000
    },
    "damage": {
      "type": "integer",
      "minimum": 0,
      "maximum": 1000
    },
    "abilities": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["attack", "defend", "heal", "special"]
      }
    }
  }
}
```

## Failure Modes

### JSON Parse Error

**Symptoms**: JSON file cannot be parsed
**Root Causes**:
- Trailing commas
- Unclosed quotes/brackets
- Invalid escape sequences
- Encoding issues

### Schema Violation

**Symptoms**: JSON parses but doesn't match schema
**Root Causes**:
- Missing required fields
- Wrong data types
- Values out of range
- Invalid enum values

### Missing Asset Reference

**Symptoms**: Reference points to non-existent asset
**Root Causes**:
- Asset deleted but reference not updated
- GUID changed during merge
- Asset moved without updating references

## Remediation Steps

### Fix JSON Parse Error

1. Run validation with verbose output
2. Identify file and line number
3. Fix syntax error in JSON file
4. Validate locally: `python scripts/gates/content_validation_gate.py --file <path>`
5. Commit fix

### Fix Schema Violation

1. Check validation output for specific error
2. Compare data against schema requirements
3. Fix data or update schema if change is intentional
4. Re-run validation

### Fix Missing References

1. Run reference check: `python scripts/tools/check_references.py`
2. Identify broken references
3. Either:
   - Restore missing asset
   - Update reference to correct asset
   - Remove invalid reference
4. Re-run gate

### Fix Duplicate GUIDs

```bash
# Find and fix duplicate GUIDs
python scripts/tools/fix_duplicate_guids.py

# Manual fix if needed:
# 1. Open Unity
# 2. Select conflicting assets
# 3. Unity will regenerate GUIDs
# 4. Update any hardcoded GUID references
```

## Content Validation Script

```python
# scripts/gates/content_validation_gate.py
class ContentValidationGate:
    """Validates all game content for integrity and correctness."""
    
    def validate_json(self, file_path: Path) -> ValidationResult:
        """Validate JSON file parses and matches schema."""
        try:
            data = json.loads(file_path.read_text())
            schema = self.load_schema(file_path)
            jsonschema.validate(data, schema)
            return ValidationResult.passed()
        except json.JSONDecodeError as e:
            return ValidationResult.failed(f"Parse error: {e}")
        except jsonschema.ValidationError as e:
            return ValidationResult.failed(f"Schema error: {e.message}")
    
    def validate_asset_references(self) -> ValidationResult:
        """Check all asset references resolve correctly."""
        broken_refs = []
        for scene in self.get_all_scenes():
            for ref in scene.get_references():
                if not ref.exists():
                    broken_refs.append(ref)
        
        if broken_refs:
            return ValidationResult.failed(
                f"{len(broken_refs)} broken references",
                details=broken_refs
            )
        return ValidationResult.passed()
```

## Naming Conventions

| Asset Type | Convention | Example |
|------------|------------|---------|
| Scripts | PascalCase | `PlayerController.cs` |
| Prefabs | PascalCase | `PlayerCharacter.prefab` |
| Materials | PascalCase + _Mat | `WoodPlanks_Mat.mat` |
| Textures | lowercase_underscore | `wood_planks_diffuse.png` |
| Scenes | PascalCase | `MainMenu.unity` |
| JSON Data | snake_case | `unit_stats.json` |

## Integration with Other Gates

- **Requires**: [[Build_Gate]] must pass
- **Blocks**: [[Packaging_Gate]] (invalid content breaks packages)
- **Required by**: [[Release_Certification_Checklist]]
- **Orphan report**: Sent to content team weekly

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| Large JSON files slow validation | Cache validation results | CONT-123 |
| GUID conflicts after merge | Run fix_duplicate_guids.py | CONT-456 |
| Asset dependencies circular | Refactor to remove cycles | CONT-789 |
