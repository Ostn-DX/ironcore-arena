---
title: Batch Generation Workflow
type: pipeline
layer: execution
status: active
tags:
  - art
  - batch
  - generation
  - workflow
  - automation
depends_on:
  - "[Art_Pipeline_Overview]]"
  - "[[Prompt_Architecture_Templates]]"
  - "[[Style_Lock_Approval_Process]"
used_by:
  - "[Art_Validation_Gates]]"
  - "[[Import_Settings_Validation]"
---

# Batch Generation Workflow

## Purpose

Standardized workflow for generating art assets at scale. Transforms approved art direction into game-ready assets through automated generation, curation, and validation.

---

## Workflow Overview

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Style Lock     │───▶│   Generate   │───▶│   Curate    │───▶│   Validate  │
│  Parameters     │    │    Batch     │    │   Filter    │    │    Assets   │
└─────────────────┘    └──────────────┘    └─────────────┘    └─────────────┘
                                                                      │
                                                                      ▼
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│   Engine        │◀───│    Import    │◀───│   Human     │◀───│   Auto      │
│   Ready         │    │   Pipeline   │    │   Pick      │    │   Pass      │
└─────────────────┘    └──────────────┘    └─────────────┘    └─────────────┘
```

---

## Stage 1: Job Preparation (Automated)

**Input**: Approved Style Lock + Art Direction Intake Form

**Actions**:
1. Parse Style Lock parameters
2. Generate prompt variations using [[Prompt_Architecture_Templates]]
3. Calculate batch size based on acceptance rate targets
4. Queue generation job

**Batch Size Formula**:
```python
required_assets = intake_form.quantity_needed
historical_acceptance_rate = 0.30  # 30% typically pass auto-curation
safety_margin = 1.5

batch_size = (required_assets / historical_acceptance_rate) * safety_margin
# Example: Need 20 assets → Generate 100 (20/0.3*1.5)
```

**Job Configuration**:
```yaml
job_id: "GEN-2024-001"
style_lock_id: "SL-2024-001"
batch_size: 100
parallel_workers: 4
priority: high
estimated_duration: "2 hours"
output_directory: "/generated/forest_enemies/batch_001/"
```

---

## Stage 2: Generation (Automated)

**Tool**: Local ComfyUI/Flux instance

**Process**:
1. Load Style Lock parameters into generation pipeline
2. Generate images with varied seeds
3. Save raw outputs with metadata
4. Monitor generation health

**Generation Metadata (embedded in PNG)**:
```json
{
  "job_id": "GEN-2024-001",
  "style_lock_id": "SL-2024-001",
  "seed": 12345,
  "prompt": "pixel art forest monster...",
  "negative_prompt": "blurry, low quality...",
  "cfg_scale": 7,
  "steps": 25,
  "model": "pixel-art-xl-v1",
  "generated_at": "2024-01-15T10:30:00Z"
}
```

**Health Monitoring**:
- GPU temperature monitoring
- Generation time per image (alert if >30s)
- Failed generation retry (max 3 attempts)
- Disk space monitoring

---

## Stage 3: Auto-Curation (Automated)

**Purpose**: Filter out obvious failures before human review

**Filters Applied**:

| Filter | Threshold | Action |
|--------|-----------|--------|
| Resolution Check | Must match target | Reject if wrong size |
| Blur Detection | Laplacian variance < 100 | Reject if too blurry |
| Color Consistency | Palette distance > 50 from target | Flag for review |
| Content Detection | Subject not detected | Reject |
| Duplicate Detection | Perceptual hash similarity > 0.9 | Keep one, reject rest |
| File Integrity | PNG validation | Reject if corrupt |

**Curation Results**:
```yaml
batch_id: "GEN-2024-001"
total_generated: 100
auto_rejected: 45
auto_flagged: 15
auto_passed: 40
rejection_breakdown:
  blur: 20
  wrong_resolution: 5
  color_drift: 10
  duplicate: 8
  corrupt: 2
```

---

## Stage 4: Human Pick (Minimal Checkpoint)

**Input**: 40 auto-passed + 15 flagged images

**Process**:
1. Present images in comparison grid
2. Human selects required quantity (20)
3. Optional: Provide feedback on rejects for prompt refinement

**Time Budget**: 15 minutes for 20 assets

**Selection Interface**:
```
[Image 1] [Image 2] [Image 3] [Image 4]
   [✓]     [ ]      [✓]      [ ]

Selected: 12/20 required
```

---

## Stage 5: Post-Processing (Automated)

**Actions**:
1. Upscale if needed (Real-ESRGAN)
2. Background removal (if transparent required)
3. Color palette enforcement
4. Format conversion per [[Asset_Format_Specifications]]
5. Apply [[Asset_Naming_Conventions]]

**Post-Processing Pipeline**:
```bash
#!/bin/bash
for img in selected/*.png; do
  # Upscale 2x if needed
  realesrgan-ncnn-vulkan -i "$img" -o "upscaled/$(basename $img)" -n realesr-animevideov3 -s 2
  
  # Remove background if needed
  rembg i "upscaled/$(basename $img)" "nobg/$(basename $img)"
  
  # Convert to target format
  convert "nobg/$(basename $img)" -resize 64x64 "final/$(basename $img .png).png"
done
```

---

## Stage 6: Validation (Automated)

**Checks**:
- File size within limits
- Dimensions match spec
- Format correct
- No corruption
- Naming convention followed

**Validation Report**:
```yaml
validated_assets: 20
passed: 20
failed: 0
validation_time: "30 seconds"
ready_for_import: true
```

---

## Stage 7: Import Pipeline (Automated)

**Actions**:
1. Copy to engine assets folder
2. Generate/import metadata
3. Configure [[Import_Settings_Validation]]
4. Update asset registry

**Engine Integration**:
- Unity: Copy to Assets/ folder, trigger import
- Unreal: Copy to Content/ folder, run import script
- Godot: Copy to res://assets/, update .import files

---

## Metrics & Optimization

| Metric | Target | Current |
|--------|--------|---------|
| Generation Rate | >50/hour | ___ |
| Auto-Curation Pass Rate | >30% | ___ |
| Human Pick Time | <15 min/20 assets | ___ |
| End-to-End Time | <4 hours/100 assets | ___ |
| Cost per Asset | <$0.50 | ___ |

---

## Error Handling

| Issue | Response |
|-------|----------|
| Generation failure | Retry 3x, then alert |
| High rejection rate (>70%) | Pause, review prompts |
| Style drift detected | Alert, pause generation |
| Disk space low | Pause, alert ops |
| GPU overheat | Pause, cool down, resume |

---

## Related Systems

- [[Prompt_Architecture_Templates]] - Prompt generation
- [[Style_Lock_Approval_Process]] - Parameter source
- [[Art_Validation_Gates]] - Validation criteria
- [[Import_Settings_Validation]] - Engine import
- [[Asset_Naming_Conventions]] - Naming standards
