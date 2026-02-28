---
title: Vault Maintenance Guide
type: system
layer: enforcement
status: active
tags:
  - maintenance
  - vault
  - drift
  - updates
  - governance
depends_on:
  - "[System_Map]]"
  - "[[Dependency_Graph]]"
  - "[[Top_Risks_and_Mitigations]"
used_by:
  - "[30_Day_Enablement_Plan]"
---

# Vault Maintenance Guide

## Purpose

This guide ensures the Studio OS vault remains accurate, consistent, and useful over time. Vault drift—where documentation diverges from reality—is a critical risk that requires active management.

## Maintenance Philosophy

**Documentation is Code**: The vault is a living system that requires the same care as production code:
- Version controlled
- Regularly tested
- Peer reviewed
- Continuously improved

## Maintenance Schedule

### Daily (Automated)
- [ ] Orphan note detection
- [ ] Broken link checking
- [ ] YAML validation
- [ ] Dependency graph consistency

### Weekly (15 minutes)
- [ ] Review new notes for completeness
- [ ] Check for duplicate content
- [ ] Verify tag consistency
- [ ] Update stale metrics

### Monthly (1 hour)
- [ ] Full dependency audit
- [ ] Review and update templates
- [ ] Archive obsolete notes
- [ ] Update glossary

### Quarterly (4 hours)
- [ ] Major structure review
- [ ] Retire deprecated patterns
- [ ] Update all cross-references
- [ ] Full vault health report

## Automated Maintenance Scripts

### Orphan Detection
```bash
#!/bin/bash
# scripts/check_orphans.py

# Find notes with no inbound links
python3 << 'EOF'
import os
import re
import yaml

vault_path = "~/Studio_Master_Plan"
notes = {}

# Collect all notes and their links
for root, dirs, files in os.walk(vault_path):
    for file in files:
        if file.endswith('.md'):
            path = os.path.join(root, file)
            with open(path, 'r') as f:
                content = f.read()
                # Extract wiki-links
                links = re.findall(r'\[\[([^\]]+)\]\]', content)
                notes[file] = links

# Find orphans (notes never linked to)
all_links = set()
for links in notes.values():
    all_links.update(links)

orphans = []
for note in notes.keys():
    note_name = note.replace('.md', '')
    if note_name not in all_links and note_name not in ['System_Map', 'Studio_OS_Overview']:
        orphans.append(note)

if orphans:
    print("ORPHAN NOTES DETECTED:")
    for orphan in orphans:
        print(f"  - {orphan}")
else:
    print("No orphan notes found.")
EOF
```

### YAML Validation
```bash
#!/bin/bash
# scripts/validate_yaml.py

python3 << 'EOF'
import os
import yaml

required_fields = ['title', 'type', 'layer', 'status', 'tags', 'depends_on', 'used_by']
vault_path = "~/Studio_Master_Plan"
errors = []

for root, dirs, files in os.walk(vault_path):
    for file in files:
        if file.endswith('.md'):
            path = os.path.join(root, file)
            with open(path, 'r') as f:
                content = f.read()
                if content.startswith('---'):
                    try:
                        # Extract frontmatter
                        _, frontmatter, _ = content.split('---', 2)
                        data = yaml.safe_load(frontmatter)
                        
                        # Check required fields
                        for field in required_fields:
                            if field not in data:
                                errors.append(f"{file}: Missing '{field}'")
                    except Exception as e:
                        errors.append(f"{file}: YAML parse error - {e}")

if errors:
    print("YAML VALIDATION ERRORS:")
    for error in errors:
        print(f"  - {error}")
else:
    print("All notes have valid YAML frontmatter.")
EOF
```

### Link Checking
```bash
#!/bin/bash
# scripts/check_links.py

python3 << 'EOF'
import os
import re

vault_path = "~/Studio_Master_Plan"
all_notes = set()
broken_links = []

# Collect all note names
for root, dirs, files in os.walk(vault_path):
    for file in files:
        if file.endswith('.md'):
            all_notes.add(file.replace('.md', ''))

# Check all links
for root, dirs, files in os.walk(vault_path):
    for file in files:
        if file.endswith('.md'):
            path = os.path.join(root, file)
            with open(path, 'r') as f:
                content = f.read()
                links = re.findall(r'\[\[([^\]]+)\]\]', content)
                for link in links:
                    link_target = link.split('|')[0].split('#')[0]  # Remove aliases and anchors
                    if link_target not in all_notes:
                        broken_links.append(f"{file} -> {link_target}")

if broken_links:
    print("BROKEN LINKS DETECTED:")
    for link in broken_links:
        print(f"  - {link}")
else:
    print("All links are valid.")
EOF
```

## Manual Maintenance Tasks

### Adding a New Note

1. **Create from template**:
```markdown
---
title: Note Title
type: [system|intent|pitfall|rule|agent|decision|mechanic|pipeline|template|gate]
layer: [design|architecture|enforcement|execution]
status: active
tags: [tag1, tag2]
depends_on: [[Prerequisite_Note]]
used_by: []
---
```

2. **Add to dependency graph**:
   - Update `depends_on` in new note
   - Update `used_by` in prerequisite notes

3. **Verify**:
   ```bash
   python scripts/check_orphans.py
   python scripts/validate_yaml.py
   python scripts/check_links.py
   ```

### Updating an Existing Note

1. **Edit content** while preserving YAML
2. **Update `used_by`** if adding new dependencies
3. **Update related notes** if changing interfaces
4. **Verify no orphans created**

### Retiring a Note

1. **Mark deprecated** in YAML:
```yaml
status: deprecated
replaced_by: [[New_Note_Name]]
```

2. **Update all links** pointing to retired note
3. **Move to archive folder** after 30 days
4. **Remove from dependency graph**

### Merging Duplicate Notes

1. **Identify duplicates** (similar titles/content)
2. **Choose canonical note** (usually the more complete one)
3. **Merge content** into canonical note
4. **Update all links** from duplicate to canonical
5. **Delete duplicate** after verification

## Drift Detection

### Signs of Vault Drift

| Symptom | Cause | Action |
|---------|-------|--------|
| Orphan notes created | Missing links | Run orphan check |
| Broken links | Renamed/deleted notes | Run link check |
| Outdated metrics | Stale data | Update monthly |
| Contradictory info | Multiple sources | Merge/consolidate |
| Unused templates | Process changed | Review quarterly |

### Drift Metrics

Track these metrics weekly:

```yaml
drift_metrics:
  orphan_count: 0
  broken_link_count: 0
  yaml_error_count: 0
  stale_note_count: 0  # Not updated in 90 days
  duplicate_risk_count: 0
  
  targets:
    orphan_count: 0
    broken_link_count: 0
    yaml_error_count: 0
    stale_note_count: < 10
    duplicate_risk_count: 0
```

## Version Control

### Commit Guidelines

```
Type: [add|update|fix|archive|merge]
Scope: [folder-name]
Description: Brief change description

Examples:
- add: 06_Quality_Gates/New_Gate_Spec.md
- update: 01_Studio_Strategy/Cost_Models.md
- fix: Broken links in 04_Agent_Architecture
- archive: Deprecated 03_Model_Catalog/Old_Model.md
- merge: Consolidated duplicate routing docs
```

### Branch Strategy

- `main`: Production vault state
- `draft/[note-name]`: New note development
- `update/[note-name]`: Note updates
- `cleanup/[description]`: Maintenance work

### Review Requirements

| Change Type | Reviewer | Required |
|-------------|----------|----------|
| New system note | Tech Lead | Yes |
| New gate | Tech Lead + QA | Yes |
| Template update | Team | Yes |
| Typo fix | Any | No |
| Link fix | Any | No |

## Governance

### Vault Owner

**Tech Lead** owns vault integrity:
- Approves structural changes
- Resolves conflicts
- Enforces standards
- Quarterly reviews

### Note Owners

Each folder has an owner:

| Folder | Owner |
|--------|-------|
| 00_Master_Index | Tech Lead |
| 01_Studio_Strategy | Producer |
| 02_Autonomy_Framework | AI Engineer |
| 03_Model_Catalog_and_Routing | AI Engineer |
| 04_Agent_Architecture | AI Engineer |
| 05_Execution_Flow_and_Tickets | Tech Lead |
| 06_Quality_Gates_and_Regression | QA Lead |
| 07_Engine_Pipelines | Engine Lead |
| 08_Art_and_Audio_Pipelines | Art Director |
| 09_Economic_Model_and_Budgets | Producer |
| 10_Templates_and_Checklists | Tech Lead |
| 11_Risk_Postmortems_and_Drift_Control | Tech Lead |

## Maintenance Checklist

### Weekly (Every Monday)
- [ ] Run orphan detection
- [ ] Run YAML validation
- [ ] Run link checking
- [ ] Review drift metrics
- [ ] Address any issues found

### Monthly (First Monday)
- [ ] Full dependency audit
- [ ] Review stale notes
- [ ] Update glossary
- [ ] Check for duplicates
- [ ] Update templates if needed
- [ ] Generate health report

### Quarterly
- [ ] Major structure review
- [ ] Retire deprecated notes
- [ ] Update all cross-references
- [ ] Team vault review meeting
- [ ] Update maintenance guide

---

*This guide is itself a note that requires maintenance. Update as practices evolve.*
