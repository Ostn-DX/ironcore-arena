#!/usr/bin/env python3
"""Add YAML frontmatter to vault files that are missing it."""

import os
import re
from pathlib import Path

# Files that need frontmatter
files_to_fix = [
    # Domain specs
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain01_claude_teams_spec.md", "D01: Claude Teams Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain02_codex_spec.md", "D02: Codex Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain03_local_llm_spec.md", "D03: Local LLM Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain04_throughput_spec.md", "D04: Throughput Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain05_autonomy_ladder_spec.md", "D05: Autonomy Ladder Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain06_risk_engine_spec.md", "D06: Risk Engine Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain07_cost_guardrail_spec.md", "D07: Cost Guardrail Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain08_openclaw_routing_spec.md", "D08: OpenClaw Routing Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain09_obsidian_vault_spec.md", "D09: Obsidian Vault Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain10_determinism_gate_spec.md", "D10: Determinism Gate Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain11_ci_infrastructure_spec.md", "D11: CI Infrastructure Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain12_auto_ticket_spec.md", "D12: Auto-Ticket Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain13_security_model_spec.md", "D13: Security Model Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain14_handoff_protocol_spec.md", "D14: Handoff Protocol Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain15_upgrade_roi_spec.md", "D15: Upgrade ROI Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain16_weekly_audit_spec.md", "D16: Weekly Audit Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain17_decision_tree_spec.md", "D17: Decision Tree Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain18_emergency_downgrade_spec.md", "D18: Emergency Downgrade Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain19_escalation_trigger_spec.md", "D19: Escalation Trigger Specification", "spec"),
    ("Studio_OS/13_Studio_OS_System/Domain_Specs/domain20_artifact_integrity_spec.md", "D20: Artifact Integrity Specification", "spec"),
    # QA Reports
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain01_qa_report.md", "D01: Claude Teams QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain02_qa_report.md", "D02: Codex QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain03_qa_report.md", "D03: Local LLM QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain04_qa_report.md", "D04: Throughput QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain05_qa_report.md", "D05: Autonomy Ladder QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain06_qa_report.md", "D06: Risk Engine QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain07_qa_report.md", "D07: Cost Guardrail QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain08_qa_report.md", "D08: OpenClaw Routing QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain09_qa_report.md", "D09: Obsidian Vault QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain10_qa_report.md", "D10: Determinism Gate QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain11_qa_report.md", "D11: CI Infrastructure QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain12_qa_report.md", "D12: Auto-Ticket QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain13_qa_report.md", "D13: Security Model QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain14_qa_report.md", "D14: Handoff Protocol QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain15_qa_report.md", "D15: Upgrade ROI QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain16_qa_report.md", "D16: Weekly Audit QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain17_qa_report.md", "D17: Decision Tree QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain18_qa_report.md", "D18: Emergency Downgrade QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain19_qa_report.md", "D19: Escalation Trigger QA Report", "qa"),
    ("Studio_OS/13_Studio_OS_System/QA_Reports/domain20_qa_report.md", "D20: Artifact Integrity QA Report", "qa"),
    # Core docs
    ("Studio_OS/13_Studio_OS_System/MASTER_BLUEPRINT.md", "AI-Native Game Studio OS - Master Blueprint", "architecture"),
    ("Studio_OS/13_Studio_OS_System/IMPLEMENTATION_COMPLETE.md", "AI-Native Game Studio OS - Implementation Complete", "reference"),
    ("Studio_OS/13_Studio_OS_System/WORKFLOW_IMPLEMENTATION.md", "AI-Native Game Studio OS - Workflow Implementation", "guide"),
    ("Studio_OS/13_Studio_OS_System/TROUBLESHOOTING_MANUAL.md", "AI-Native Game Studio OS - Troubleshooting Manual", "guide"),
    ("Studio_OS/13_Studio_OS_System/QUICKSTART.md", "AI-Native Game Studio OS - Quick Start", "guide"),
    ("Studio_OS/13_Studio_OS_System/_Index.md", "Studio OS System Index", "index"),
    # VAULT docs
    ("Studio_OS/13_Studio_OS_System/autonomy_ladder.md", "Autonomy Ladder", "reference"),
    ("Studio_OS/13_Studio_OS_System/conventions.md", "Coding Conventions", "reference"),
    ("Studio_OS/13_Studio_OS_System/cost_model.md", "Cost Model", "reference"),
    ("Studio_OS/13_Studio_OS_System/determinism_gates.md", "Determinism Gates", "reference"),
    ("Studio_OS/13_Studio_OS_System/escalation_matrix.md", "Escalation Matrix", "reference"),
    ("Studio_OS/13_Studio_OS_System/executor_prompts.md", "Executor Prompts", "reference"),
    ("Studio_OS/13_Studio_OS_System/failure_atlas.md", "Failure Atlas", "reference"),
    ("Studio_OS/13_Studio_OS_System/invariants.md", "System Invariants", "reference"),
    ("Studio_OS/13_Studio_OS_System/risk_engine.md", "Risk Engine", "reference"),
    ("Studio_OS/13_Studio_OS_System/routing_policy.md", "Routing Policy", "reference"),
    ("Studio_OS/13_Studio_OS_System/system_map.md", "System Map", "reference"),
    ("Studio_OS/13_Studio_OS_System/weekly_audit.md", "Weekly Audit", "reference"),
    # Analytics
    ("Studio_OS/13_Studio_OS_System/Autonomy_Promotion_Table.md", "Autonomy Promotion Table", "analytics"),
    ("Studio_OS/13_Studio_OS_System/Throughput_Simulation.md", "Throughput Simulation", "analytics"),
    ("Studio_OS/13_Studio_OS_System/Upgrade_ROI_Model.md", "Upgrade ROI Model", "analytics"),
    # Reports
    ("Studio_OS/13_Studio_OS_System/consistency_audit_report.md", "Consistency Audit Report", "report"),
    ("Studio_OS/13_Studio_OS_System/structural_integration_report.md", "Structural Integration Report", "report"),
]

def add_frontmatter(filepath, title, doc_type):
    """Add YAML frontmatter to a markdown file."""
    base_path = Path("/home/node/.openclaw/workspace/ironcore-work")
    full_path = base_path / filepath
    
    if not full_path.exists():
        print(f"⚠️  File not found: {filepath}")
        return False
    
    # Read existing content
    content = full_path.read_text(encoding='utf-8')
    
    # Skip if already has frontmatter
    if content.startswith('---'):
        print(f"✓ Already has frontmatter: {filepath}")
        return True
    
    # Build frontmatter based on type
    if doc_type == "spec":
        frontmatter = f"""---
title: {title}
type: specification
layer: system
status: active
domain: studio_os
tags:
  - specification
  - domain
  - studio_os
depends_on: []
used_by: []
---

"""
    elif doc_type == "qa":
        frontmatter = f"""---
title: {title}
type: qa_report
layer: validation
status: active
domain: studio_os
tags:
  - qa
  - validation
  - studio_os
depends_on: []
used_by: []
---

"""
    elif doc_type == "architecture":
        frontmatter = f"""---
title: {title}
type: architecture
layer: system
status: active
domain: studio_os
tags:
  - architecture
  - blueprint
  - studio_os
depends_on: []
used_by: []
---

"""
    elif doc_type == "guide":
        frontmatter = f"""---
title: {title}
type: guide
layer: operations
status: active
domain: studio_os
tags:
  - guide
  - operations
  - studio_os
depends_on: []
used_by: []
---

"""
    elif doc_type == "index":
        frontmatter = f"""---
title: {title}
type: index
layer: navigation
status: active
domain: studio_os
tags:
  - index
  - navigation
  - studio_os
depends_on: []
used_by: []
---

"""
    elif doc_type == "reference":
        frontmatter = f"""---
title: {title}
type: reference
layer: system
status: active
domain: studio_os
tags:
  - reference
  - studio_os
depends_on: []
used_by: []
---

"""
    elif doc_type == "analytics":
        frontmatter = f"""---
title: {title}
type: analytics
layer: analysis
status: active
domain: studio_os
tags:
  - analytics
  - modeling
  - studio_os
depends_on: []
used_by: []
---

"""
    elif doc_type == "report":
        frontmatter = f"""---
title: {title}
type: report
layer: validation
status: active
domain: studio_os
tags:
  - report
  - audit
  - studio_os
depends_on: []
used_by: []
---

"""
    else:
        frontmatter = f"""---
title: {title}
type: document
status: active
domain: studio_os
tags:
  - studio_os
---

"""
    
    # Write back with frontmatter
    full_path.write_text(frontmatter + content, encoding='utf-8')
    print(f"✅ Added frontmatter: {filepath}")
    return True

def main():
    fixed = 0
    skipped = 0
    errors = 0
    
    for filepath, title, doc_type in files_to_fix:
        result = add_frontmatter(filepath, title, doc_type)
        if result is True:
            if "Already has" in str(result):
                skipped += 1
            else:
                fixed += 1
        elif result is False:
            errors += 1
    
    print(f"\n{'='*50}")
    print(f"Summary: Fixed {fixed}, Skipped {skipped}, Errors {errors}")

if __name__ == "__main__":
    main()
