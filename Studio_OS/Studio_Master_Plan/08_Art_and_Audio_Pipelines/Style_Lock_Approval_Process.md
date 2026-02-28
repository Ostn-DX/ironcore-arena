---
title: Style Lock Approval Process
type: gate
layer: enforcement
status: active
tags:
  - art
  - style
  - approval
  - gate
  - quality-control
depends_on:
  - "[Art_Direction_Intake_Format]]"
  - "[[Art_Pipeline_Overview]"
used_by:
  - "[Batch_Generation_Workflow]]"
  - "[[Art_Validation_Gates]"
---

# Style Lock Approval Process

## Purpose

Prevent expensive style drift by establishing a **single source of truth** for visual style before any batch generation begins. Style Lock is a formal checkpoint that freezes all generation parameters.

## The Cost of Style Drift

| Stage of Discovery | Cost to Fix |
|-------------------|-------------|
| After 10 assets generated | 2 hours (re-prompt) |
| After 100 assets generated | 2 days (re-generate batch) |
| After 500 assets in production | 2 weeks (full art pass) |
| After release | Impossible (live with inconsistency) |

**Rule**: Style Lock must be completed before any batch generation exceeding 20 assets.

---

## Style Lock Process

### Phase 1: Style Proposal (Automated)

**Trigger**: Art Direction Intake Form submitted

**System Actions**:
1. Parse intake form for style parameters
2. Query existing style library for matches
3. Generate 5-10 style sample images using proposed parameters
4. Create style proposal document

**Output**: Style Proposal Package containing:
- Sample generations (5-10 images)
- Parameter summary (model, LoRA, prompts, settings)
- Consistency analysis vs. existing assets
- Cost estimate for full batch

### Phase 2: Style Review (Human Checkpoint)

**Required Approvers**:
- Art Lead (aesthetic consistency)
- Technical Lead (feasibility, performance)
- Design Lead (gameplay clarity)

**Review Criteria**:

| Criterion | Pass Threshold | Auto-Check |
|-----------|---------------|------------|
| Visual Appeal | 3/3 approvers agree | No |
| Consistency | Matches existing style guide | Yes (perceptual hash) |
| Clarity | Readable at target resolution | Yes (edge detection) |
| Performance | Fits memory budget | Yes (file size check) |
| Generation Stability | <20% variance across samples | Yes (statistical analysis) |

**Decision Options**:
- **Approve**: Proceed to Phase 3
- **Revise**: Return to Phase 1 with feedback
- **Reject**: Explore alternative approaches (asset pack, manual art)

### Phase 3: Style Lock (Automated)

**Upon Approval**:
1. Parameters written to Style Lock Registry
2. Generation job queued with locked parameters
3. Style Lock ID assigned and logged
4. All future generation for this asset type uses locked parameters

**Style Lock Registry Entry**:
```yaml
style_lock_id: "SL-2024-001"
asset_type: "forest_enemy"
created: "2024-01-15T10:30:00Z"
approvers: ["art_lead", "tech_lead", "design_lead"]
parameters:
  base_model: "pixel-art-xl-v1"
  lora: "forest-creatures-lora-v2"
  positive_prompt_template: "pixel art {subject}, 64x64, game asset, {mood}"
  negative_prompt: "blurry, low quality, photorealistic, 3d render"
  cfg_scale: 7
  steps: 25
  sampler: "DPM++ 2M Karras"
  seed_range: [1000, 999999]
resolution: "64x64"
color_palette: ["#1a1a2e", "#e94560", "#0f3460"]
status: locked
```

### Phase 4: Generation & Monitoring

**During Generation**:
- System monitors output consistency against Style Lock
- Variance alerts triggered if generation drifts
- Automatic pause if drift exceeds threshold

**Drift Detection**:
```python
# Pseudocode for drift detection
def detect_style_drift(new_image, style_lock):
    perceptual_hash_diff = compare_phash(new_image, style_lock.reference)
    color_distance = compare_palette(new_image, style_lock.palette)
    
    if perceptual_hash_diff > 0.3 or color_distance > 50:
        return ALERT_DRIFT_DETECTED
    return OK
```

---

## Exception Handling

### Emergency Style Unlock

**When**: Critical gameplay issue discovered, style prevents readability
**Process**:
1. File Style Unlock Request with justification
2. Fast-track review (24-hour SLA)
3. If approved, create new Style Lock version
4. Re-generate affected assets

### Style Evolution

**When**: Intentional style update for new content
**Process**:
1. Create Style Lock v2 with updated parameters
2. Maintain v1 for existing content
3. Document migration path for existing assets

---

## Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Style Lock Approval Time | <48 hours | Time from proposal to lock |
| Post-Lock Revision Rate | <5% | Percentage requiring unlock |
| Style Consistency Score | >90% | Perceptual hash similarity |
| Approver Agreement | >95% | All three approvers concur |

---

## Automation Level

| Phase | Automation | Human Role |
|-------|-----------|------------|
| Proposal | 90% | Review auto-generated samples |
| Review | 0% | Make approval decision |
| Lock | 100% | None - system executes |
| Monitoring | 95% | Respond to drift alerts |

---

## Related Systems

- [[Art_Direction_Intake_Format]] - Triggers Style Lock process
- [[Batch_Generation_Workflow]] - Uses locked parameters
- [[Art_Validation_Gates]] - Includes style consistency checks
- [[Prompt_Architecture_Templates]] - Templates enforce locked style
