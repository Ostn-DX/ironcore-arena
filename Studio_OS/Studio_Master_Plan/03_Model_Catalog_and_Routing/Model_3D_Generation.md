---
title: 3D Generation
type: agent
layer: execution
status: active
tags:
  - 3d
  - generation
  - mesh
  - model
  - warning
  - roi
  - assets
depends_on:
  - "[Model_Catalog_Overview]]"
  - "[[Image_Diffusion_Local]]"
  - "[[Image_Diffusion_API]"
used_by:
  - "[Asset_Integration_Routing]"
---

# 3D Generation

## Model Class: 3D Mesh and Model Generation Tools

**WARNING: This capability is rapidly evolving but currently has significant limitations for production game asset workflows. Careful ROI analysis required before adoption.**

### Supported Tools

| Tool | Type | Output | Quality | Cost |
|------|------|--------|---------|------|
| Meshy | API | Mesh + Texture | Moderate | $20-100/mo |
| Rodin | API | Mesh + Texture | Moderate | API credits |
| Tripo3D | API | Mesh + Texture | Good | API credits |
| CSG | Local | Mesh only | Basic | Hardware |
| Point-E | Local | Point cloud | Low | Hardware |
| Shap-E | Local | Mesh | Low | Hardware |
| Stable Fast 3D | Local | Mesh | Moderate | Hardware |

### Capability Profile

**Current Strengths:**
- Rapid prototyping of simple shapes
- Concept mesh generation
- Basic prop creation
- Texture generation from images
- Some character mesh generation

**Current Weaknesses:**
- Topology usually poor (non-game-ready)
- UV unwrapping often broken
- Polygon count uncontrolled
- Rigging not supported
- Animation incompatible
- Detail level inconsistent
- Requires significant cleanup

### ROI Warning

**Current State (2024-2025):**

3D generation for games is **NOT production-ready** for most use cases. The time saved in generation is often lost in cleanup and rework.

| Factor | Status | Impact |
|--------|--------|--------|
| Topology | Poor | Requires retopology |
| UVs | Often broken | Requires redo |
| Polygon count | Uncontrolled | Requires optimization |
| Rigging | Not supported | Manual required |
| Animation | Incompatible | Manual required |
| LODs | Not generated | Manual required |
| Collision | Not generated | Manual required |

### When 3D Generation Makes Sense

**Currently Viable:**
1. **Concept prototyping** - Quick mesh for scale reference
2. **Background props** - Distant, low-detail objects
3. **Blockout meshes** - Starting point for manual work
4. **Texture generation** - Good results from image prompts
5. **Rapid iteration** - Early design exploration

**NOT Currently Viable:**
1. Hero character models
2. Animated characters
3. Complex mechanical models
4. Anything requiring rigging
5. Performance-critical assets
6. Final production assets

### Cost-Benefit Analysis

| Approach | Time | Cost | Quality | Recommendation |
|----------|------|------|---------|----------------|
| 3D Generation + Cleanup | 8-16h | $20-50 | Moderate | Only for prototypes |
| Manual Modeling | 4-8h | $200-400 | High | Recommended |
| Kitbash + Manual | 2-4h | $50-100 | High | Best for production |

**Conclusion**: Manual modeling or kitbashing is currently more efficient for production assets.

### Workflow (If Used)

```
1. Generate concept images (2D)
2. Generate 3D mesh from image
3. Evaluate topology quality
4. If acceptable:
   a. Retopologize (if needed)
   b. Fix UVs
   c. Optimize polygon count
   d. Generate textures
5. If unacceptable:
   a. Use as blockout reference
   b. Manual modeling
6. Rig and animate manually
7. Generate LODs manually
8. Test in-engine
```

### Technical Specifications

**Output Formats:**
- Mesh: OBJ, FBX, GLB
- Textures: PNG (diffuse, normal, roughness)
- Polycount: Often 50K-500K (needs reduction)

**Generation Parameters:**
```yaml
3d_generation:
  input: "image_path.jpg"  # or text prompt
  output_format: "obj"
  
  # Quality settings
  detail_level: "high|medium|low"
  texture_resolution: 1024  # or 2048
  
  # Post-processing required
  retopology: true
  uv_unwrap: true
  polygon_reduction: 0.5  # target 50%
```

### Future Outlook

**Expected Improvements (2025-2026):**
- Better topology generation
- Automatic UV unwrapping
- Polygon count control
- Basic rigging support
- Animation compatibility

**When to Re-evaluate:**
- Q2 2025: Check for topology improvements
- Q4 2025: Check for rigging support
- 2026: Full production viability possible

### Risk Mitigation

**If Using 3D Generation:**
1. Budget 50-100% time for cleanup
2. Have manual modeling fallback
3. Start with non-critical assets
4. Validate pipeline end-to-end
5. Track actual time savings
6. Maintain traditional skills

### Cost Governance

**Recommended Budget:**
- Maximum 5% of art budget for 3D generation
- Focus on 2D generation (better ROI)
- Invest in traditional modeling tools
- Train team on kitbash workflows

### Best Practices (Current)

1. Use for concept/prototype only
2. Always plan for cleanup time
3. Validate topology before proceeding
4. Consider generated mesh as reference
5. Maintain manual modeling capability
6. Track actual vs expected time
7. Re-evaluate quarterly

### Integration

Used primarily by:
- [[Asset_Integration_Routing]]: Experimental 3D pipeline (with warnings)

### Decision Tree

```
Need 3D asset?
├── Is it for prototype/concept only?
│   └── Yes → Try 3D generation
├── Is it animated?
│   └── Yes → Manual modeling
├── Is it hero/important?
│   └── Yes → Manual modeling
├── Is performance critical?
│   └── Yes → Manual modeling
└── No to all → Consider kitbash first
```
